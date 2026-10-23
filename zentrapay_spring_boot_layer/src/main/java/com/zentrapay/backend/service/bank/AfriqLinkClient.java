package com.zentrapay.backend.service.bank;

import com.zentrapay.backend.dto.payment.AfriqLinkAccountResponseDTO;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.dto.payment.AfriqLinkVerifyResponseDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.RestTemplate;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Thin wrapper over the <b>AfriqLink OPEN BANKING API</b> — the project's
 * single provider for bank-data services:
 * <ul>
 *   <li>account linking (ZBank Lite "link a bank" sheet),</li>
 *   <li>account-name verification (send-money confirmation).</li>
 * </ul>
 *
 * <p>Paystack / Flutterwave / Onafriq are payment SETTLEMENT orchestrators and
 * offer no open-banking capabilities, so they are deliberately NOT called from
 * this client — they remain wired to the payout, checkout and webhook flows
 * only.
 *
 * <p>NOTE: the AfriqLink account has not been created yet. The base URL and
 * keys in {@code application.properties} are placeholders and the endpoint
 * paths below mirror this project's partner-style clients — confirm both
 * against the live AfriqLink documentation before going to production.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AfriqLinkClient {

    private final RestTemplate restTemplate;

    @Value("${afriqlink.base-url}")
    private String baseUrl;
    @Value("${afriqlink.secret-key}")
    private String secretKey;
    @Value("${afriqlink.client-id}")
    private String clientId;

    // ------------------------------------------------------------------
    // Account linking (ZBank Lite) — replaces the old Paystack → Flutterwave
    // → Onafriq "linking" chain, which was settlement-side, not open banking.
    // ------------------------------------------------------------------

    /**
     * Posts the account + its holder's first/last name to AfriqLink as the
     * open-banking linking request.
     *
     * @throws PaymentGatewayException when AfriqLink rejects the request or is
     *                                 unreachable — nothing is linked
     */
    public AfriqLinkAccountResponseDTO linkAccount(
            String bankCode,
            String accountNumber,
            String currencyCode,
            String countryCode,
            String firstName,
            String lastName) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("client_id", clientId);
        body.put("bank_code", bankCode);
        body.put("account_number", accountNumber);
        body.put("first_name", firstName);
        body.put("last_name", lastName);
        if (currencyCode != null && !currencyCode.isBlank()) {
            body.put("currency", currencyCode);
        }
        if (countryCode != null && !countryCode.isBlank()) {
            body.put("country_code", countryCode);
        }
        AfriqLinkAccountResponseDTO response =
                post("/accounts/link", body, AfriqLinkAccountResponseDTO.class);
        if (response == null || !response.accepted()) {
            throw new PaymentGatewayException("AfriqLink linking request rejected: "
                    + (response == null || response.message() == null
                            ? "unknown error"
                            : response.message()));
        }
        return response;
    }


    // ------------------------------------------------------------------
    // Account-name verification (send-money confirmation screen)
    // ------------------------------------------------------------------

    /**
     * Resolves an account number + bank code to its holder name via AfriqLink.
     *
     * @throws PaymentGatewayException when the account cannot be verified
     */
    public AfriqLinkVerifyResponseDTO verifyAccount(String accountNumber, String bankCode) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("client_id", clientId);
        body.put("bank_code", bankCode);
        body.put("account_number", accountNumber);
        AfriqLinkVerifyResponseDTO response =
                post("/accounts/verify", body, AfriqLinkVerifyResponseDTO.class);
        if (response == null || !response.accepted()) {
            throw new PaymentGatewayException(
                    "Could not verify that account number, please check and try again");
        }
        return response;
    }

    // ------------------------------------------------------------------
    // HTTP plumbing
    // ------------------------------------------------------------------

    private <T> T post(String path, Object body, Class<T> responseType) {
        String url = baseUrl + path;
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Accept", "application/json");
        headers.set("Authorization", "Bearer " + secretKey);
        headers.set("X-Client-Id", clientId);
        try {
            ResponseEntity<T> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>(body, headers), responseType);
            return response.getBody();
        } catch (RestClientResponseException e) {
            log.error("AfriqLink {} failed [{}]: {}", path, e.getStatusCode(),
                    e.getResponseBodyAsString());
            throw new PaymentGatewayException(
                    "AfriqLink request to " + path + " failed: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("AfriqLink {} unreachable: {}", path, e.getMessage());
            throw new PaymentGatewayException("AfriqLink is unreachable, please try again", e);
        }
    }
}

