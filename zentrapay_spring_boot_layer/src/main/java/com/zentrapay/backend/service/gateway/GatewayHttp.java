package com.zentrapay.backend.service.gateway;

import com.zentrapay.backend.exception.PaymentGatewayException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.ConnectException;
import java.net.UnknownHostException;

/**
 * The single place every gateway API call goes through, so Paystack, Flutterwave
 * and Onafriq all fail the same way.
 *
 * <p>Every failure becomes a {@link PaymentGatewayException} that says whether the
 * outcome is known:
 * <ul>
 *   <li>4xx answer, or the server could not even be reached -> the gateway did NOT act
 *       (safe to refund / try another gateway)</li>
 *   <li>5xx answer, read timeout, unreadable reply -> the gateway MAY have acted
 *       ({@code outcomeUnknown = true}, wait for the webhook)</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class GatewayHttp {

    private final RestClient restClient;
    private final ObjectMapper objectMapper;

    /** POST a JSON body with a bearer secret key. */
    public <T> T post(String gateway, String url, String secretKey, Object body, Class<T> responseType) {
        return send(gateway, HttpMethod.POST, url, secretKey, body, responseType);
    }

    /** GET with a bearer secret key. */
    public <T> T get(String gateway, String url, String secretKey, Class<T> responseType) {
        return send(gateway, HttpMethod.GET, url, secretKey, null, responseType);
    }

    private <T> T send(String gateway, HttpMethod method, String url, String secretKey, Object body, Class<T> responseType) {
        log.info("{} {} {}", gateway, method, url);
        try {
            RestClient.RequestBodySpec request = restClient.method(method)
                    .uri(url)
                    .header("Authorization", "Bearer " + secretKey)
                    .accept(MediaType.APPLICATION_JSON);
            if (body != null) {
                // Sent as a ready-made string so the request carries a Content-Length (some gateways/proxies reject chunked bodies)
                request = request.contentType(MediaType.APPLICATION_JSON).body(objectMapper.writeValueAsString(body));
            }
            return request.retrieve().body(responseType);

        } catch (HttpClientErrorException e) {
            // 4xx - the gateway looked at the request and said no
            String reason = readMessage(e.getResponseBodyAsString());
            log.warn("{} rejected {} [{}]: {}", gateway, url, e.getStatusCode().value(), reason);
            throw new PaymentGatewayException(gateway + " rejected the request: " + reason, e);

        } catch (HttpServerErrorException e) {
            // 5xx - the gateway failed, we cannot know if it processed the request
            log.error("{} server error on {} [{}]: {}", gateway, url, e.getStatusCode().value(), e.getResponseBodyAsString());
            throw PaymentGatewayException.unknownOutcome(gateway + " is having problems, please try again", e);

        } catch (ResourceAccessException e) {
            if (neverReachedGateway(e)) {
                log.error("{} unreachable on {}: {}", gateway, url, e.getMessage());
                throw new PaymentGatewayException(gateway + " is unreachable, please try again", e);
            }
            // e.g. read timeout: the request was sent but no answer came back
            log.error("{} did not answer on {}: {}", gateway, url, e.getMessage());
            throw PaymentGatewayException.unknownOutcome(gateway + " did not respond in time", e);

        } catch (Exception e) {
            // 2xx with a body we could not read
            log.error("{} reply could not be processed on {}: {}", gateway, url, e.getMessage(), e);
            throw PaymentGatewayException.unknownOutcome(gateway + " returned an unreadable response", e);
        }
    }

    // True when the connection was never established, so nothing was sent
    private boolean neverReachedGateway(ResourceAccessException e) {
        Throwable cause = e.getCause();
        while (cause != null) {
            if (cause instanceof ConnectException || cause instanceof UnknownHostException) {
                return true;
            }
            String text = cause.getMessage();
            if (text != null && text.toLowerCase().contains("connect timed out")) {
                return true;
            }
            cause = cause.getCause();
        }
        return false;
    }

    // Gateways put the human reason in {"message": "..."}
    private String readMessage(String responseBody) {
        try {
            JsonNode message = objectMapper.readTree(responseBody).path("message");
            return message.isMissingNode() || message.isNull() ? "unknown error" : message.asString();
        } catch (Exception ignored) {
            return "unknown error";
        }
    }
}
