package com.zentrapay.backend.service.bank;

import com.zentrapay.backend.dto.payment.AfriLinkAccountDTO;
import com.zentrapay.backend.exception.PaymentGatewayException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * Server side of the AfriLink Connect flow (https://afrilink.io/docs).
 *
 * <p>How AfriLink linking works:
 * <ol>
 *   <li>The app opens the Connect widget with the PUBLIC key ({@code pk_...}). The widget handles
 *       bank selection, login and consent, so the user never types bank credentials or account
 *       numbers into ZentraPay.</li>
 *   <li>The widget hands the app what it got: a session id + auth token (when the link still has to
 *       be completed) and/or the linked account's {@code id} (when the widget already completed it).</li>
 *   <li><b>Token path</b> - {@link #completeLink}: the backend submits {@code sessionId}, {@code userId},
 *       {@code institution} and the token to {@code POST /api/connect/complete} with the PUBLIC key
 *       (header {@code x-public-key}). AfriLink answers with the linked account.</li>
 *   <li><b>Account-id path</b> - {@link #fetchAccount}: the backend reads the account back with the
 *       SECRET key ({@code sk_...}, header {@code x-api-key}) from {@code GET /api/data/accounts/:id}.
 *       An id the client invented simply returns "Account not found".</li>
 * </ol>
 * AfriLink has no account-name lookup or payout API; those stay with Paystack / Flutterwave.
 *
 * <p>Missing keys never stop the application from starting - linking just answers "not configured".
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AfriLinkClient {

    private final RestTemplate restTemplate;

    @Value("${afrilink.base-url:https://api.afrilink.io}")
    private String baseUrl;
    @Value("${afrilink.secret-key:}")
    private String secretKey;
    @Value("${afrilink.public-key:}")
    private String publicKey;

    /**
     * Completes a link: submits the widget's session, user, institution and auth token to AfriLink's
     * linking endpoint with the public key. Returns the account AfriLink created.
     *
     * @throws PaymentGatewayException when AfriLink refuses the token or cannot be reached
     */
    public AfriLinkAccountDTO completeLink(String sessionId, String afriLinkUserId, String institution, String publicToken) {
        if (publicKey == null || !publicKey.startsWith("pk_")) {
            throw new PaymentGatewayException("Bank linking is not configured on the server");
        }
        Map<String, Object> payload = new java.util.LinkedHashMap<>();
        payload.put("sessionId", sessionId);
        payload.put("userId", afriLinkUserId);
        payload.put("institution", institution == null ? "" : institution);
        payload.put("authCode", publicToken);

        HttpHeaders headers = new HttpHeaders();
        headers.set("x-public-key", publicKey);
        headers.set("Content-Type", "application/json");
        headers.set("Accept", "application/json");
        try {
            @SuppressWarnings("rawtypes")
            ResponseEntity<Map> response = restTemplate.exchange(root() + "/api/connect/complete", HttpMethod.POST,
                    new HttpEntity<>(payload, headers), Map.class);
            @SuppressWarnings("unchecked")
            Map<String, Object> body = response.getBody();
            if (body == null || Boolean.FALSE.equals(body.get("success"))) {
                throw new PaymentGatewayException("AfriLink did not complete the link");
            }
            Object account = body.get("account") != null ? body.get("account") : body.get("data");
            if (!(account instanceof Map<?, ?>)) {
                throw new PaymentGatewayException("AfriLink returned no account");
            }
            @SuppressWarnings("unchecked")
            AfriLinkAccountDTO linked = parse(null, (Map<String, Object>) account);
            if (linked.accountId() == null || linked.accountId().isBlank()) {
                throw new PaymentGatewayException("AfriLink returned an account without an id");
            }
            return linked;
        } catch (HttpClientErrorException e) {
            log.warn("AfriLink rejected the link completion [{}]: {}", e.getStatusCode().value(), e.getResponseBodyAsString());
            throw new PaymentGatewayException("AfriLink refused to complete the link (" + e.getStatusCode().value() + ")", e);
        } catch (PaymentGatewayException e) {
            throw e;
        } catch (Exception e) {
            log.error("AfriLink link completion unreachable: {}", e.getMessage());
            throw new PaymentGatewayException("AfriLink is unreachable, please try again", e);
        }
    }

    /**
     * Reads a connected account back from AfriLink.
     *
     * @throws PaymentGatewayException when AfriLink does not know the account or cannot be reached
     */
    public AfriLinkAccountDTO fetchAccount(String accountId) {
        if (secretKey == null || !secretKey.startsWith("sk_")) {
            // Fail loudly instead of sending a public key (or nothing) as the secret
            throw new PaymentGatewayException("Bank linking is not configured on the server");
        }
        String url = root() + "/api/data/accounts/" + URLEncoder.encode(accountId, StandardCharsets.UTF_8);
        HttpHeaders headers = new HttpHeaders();
        headers.set("x-api-key", secretKey);
        headers.set("Accept", "application/json");
        try {
            @SuppressWarnings("rawtypes")
            ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, new HttpEntity<>(headers), Map.class);
            @SuppressWarnings("unchecked")
            Map<String, Object> body = response.getBody();
            if (body == null) {
                throw new PaymentGatewayException("AfriLink returned an empty reply");
            }
            return parse(accountId, body);
        } catch (HttpClientErrorException e) {
            log.warn("AfriLink rejected account lookup {} [{}]: {}", accountId, e.getStatusCode().value(), e.getResponseBodyAsString());
            throw new PaymentGatewayException("AfriLink does not know this account (" + e.getStatusCode().value() + ")", e);
        } catch (PaymentGatewayException e) {
            throw e;
        } catch (Exception e) {
            log.error("AfriLink account lookup unreachable: {}", e.getMessage());
            throw new PaymentGatewayException("AfriLink is unreachable, please try again", e);
        }
    }

    // ------------------------------------------------------------------

    /** Base host without a trailing slash or a trailing "/api" (the paths above carry "/api"). */
    private String root() {
        String b = baseUrl == null ? "" : baseUrl.trim();
        while (b.endsWith("/")) {
            b = b.substring(0, b.length() - 1);
        }
        return b.endsWith("/api") ? b.substring(0, b.length() - 4) : b;
    }

    /**
     * Account JSON to {@link AfriLinkAccountDTO}. The docs do not publish the exact account schema,
     * so every field is read from a list of likely names and the account may sit at the top level or
     * under {@code data}/{@code account}.
     */
    @SuppressWarnings("unchecked")
    static AfriLinkAccountDTO parse(String requestedId, Map<String, Object> body) {
        Map<String, Object> account = body;
        for (String wrapper : new String[]{"data", "account"}) {
            if (account.get(wrapper) instanceof Map<?, ?> inner) {
                account = (Map<String, Object>) inner;
            }
        }

        String institutionName;
        String institutionId;
        Object institution = firstValue(account, "institution", "bank", "bankName", "institutionName");
        if (institution instanceof Map<?, ?> inst) {
            institutionName = text(firstValue((Map<String, Object>) inst, "name", "bankName"));
            institutionId = text(firstValue((Map<String, Object>) inst, "id", "code", "bankCode"));
        } else {
            institutionName = text(institution);
            institutionId = text(firstValue(account, "institutionId", "bankCode", "bank_code"));
        }

        String number = text(firstValue(account, "accountNumber", "account_number", "number", "mask", "lastDigits"));
        String digits = number == null ? "" : number.replaceAll("[^0-9]", "");
        String lastDigits = digits.length() >= 4 ? digits.substring(digits.length() - 4) : digits;

        String id = text(firstValue(account, "id", "_id", "accountId", "account_id"));
        return new AfriLinkAccountDTO(
                id == null ? requestedId : id,
                text(firstValue(account, "userId", "user_id", "customerId")),
                institutionId,
                institutionName,
                text(firstValue(account, "type", "accountType", "account_type")),
                text(firstValue(account, "currency", "currencyCode")),
                lastDigits,
                money(firstValue(account, "balance", "availableBalance", "currentBalance")));
    }

    private static Object firstValue(Map<String, Object> map, String... keys) {
        for (String key : keys) {
            Object v = map.get(key);
            if (v != null) {
                return v;
            }
        }
        return null;
    }

    private static String text(Object o) {
        if (o == null) {
            return null;
        }
        String s = o.toString().trim();
        return s.isEmpty() ? null : s;
    }

    private static BigDecimal money(Object o) {
        if (o instanceof Number n) {
            return new BigDecimal(n.toString());
        }
        if (o instanceof Map<?, ?> m && m.get("available") instanceof Number n) {
            return new BigDecimal(n.toString());
        }
        try {
            return o == null ? BigDecimal.ZERO : new BigDecimal(o.toString().trim());
        } catch (NumberFormatException e) {
            return BigDecimal.ZERO;
        }
    }
}
