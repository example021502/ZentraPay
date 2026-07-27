package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.paystack;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.Collections;

/**
 * HTTP client for interacting with the Paystack API.
 * <p>
 * Handles authentication via Bearer token and provides typed methods for:
 * <ul>
 *   <li>Creating transfer recipients ({@code POST /transferrecipient})</li>
 *   <li>Initiating transfers ({@code POST /transfer})</li>
 *   <li>Fetching transfer status ({@code GET /transfer/{id}})</li>
 *   <li>Checking balance ({@code GET /balance})</li>
 * </ul>
 * <p>
 * All API calls use the configured secret key from {@link PaystackConfig}.
 * Uses Spring's {@link RestTemplate} with built-in Jackson 3.x message converters.
 */
@Component
public class PaystackClient {

    private static final Logger log = LoggerFactory.getLogger(PaystackClient.class);

    private final PaystackConfig config;
    private final RestTemplate restTemplate;

    public PaystackClient(PaystackConfig config, RestTemplate restTemplate) {
        this.config = config;
        this.restTemplate = restTemplate;
    }

    /**
     * Creates an Authorization header with the Paystack secret key.
     */
    private HttpHeaders createHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(config.getSecretKey());
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));
        return headers;
    }

    /**
     * POSTs to Paystack to create a transfer recipient.
     *
     * @param request The recipient details (type, name, account number, bank code, currency)
     * @return Parsed response containing the recipient code
     */
    public PaystackTransferResponse<PaystackTransferResponse.TransferRecipientData> createTransferRecipient(
            PaystackTransferRecipientRequest request) {
        String url = config.getBaseUrl() + "/transferrecipient";
        log.info("[PAYSTACK] Creating transfer recipient: type={}, currency={}", request.type(), request.currency());
        return post(url, request, new ParameterizedTypeReference<PaystackTransferResponse<PaystackTransferResponse.TransferRecipientData>>() {});
    }

    /**
     * POSTs to Paystack to initiate a transfer (disbursement).
     *
     * @param request The transfer details (source, amount, reference, recipient code, reason, currency)
     * @return Parsed response containing transfer status
     */
    public PaystackTransferResponse<PaystackTransferResponse.TransferData> initiateTransfer(
            PaystackTransferRequest request) {
        String url = config.getBaseUrl() + "/transfer";
        log.info("[PAYSTACK] Initiating transfer: ref={}, amount={}, currency={}",
                request.reference(), request.amount(), request.currency());
        return post(url, request, new ParameterizedTypeReference<PaystackTransferResponse<PaystackTransferResponse.TransferData>>() {});
    }

    /**
     * GETs the status of a transfer by its ID or reference.
     *
     * @param idOrReference The Paystack transfer ID or reference code
     * @return Parsed response with current transfer status
     */
    public PaystackTransferResponse<PaystackTransferResponse.TransferStatusData> fetchTransferStatus(
            String idOrReference) {
        String url = config.getBaseUrl() + "/transfer/" + idOrReference;
        log.info("[PAYSTACK] Fetching transfer status for: {}", idOrReference);
        return get(url, new ParameterizedTypeReference<PaystackTransferResponse<PaystackTransferResponse.TransferStatusData>>() {});
    }

    /**
     * GETs the Paystack balance for a specific currency.
     *
     * @param currency Currency code (NGN, GHS, ZAR, USD)
     * @return Parsed response with balance information
     */
    public PaystackTransferResponse<PaystackTransferResponse.BalanceData[]> checkBalance(String currency) {
        String url = config.getBaseUrl() + "/balance?currency=" + currency;
        log.info("[PAYSTACK] Checking balance for currency: {}", currency);
        return get(url, new ParameterizedTypeReference<PaystackTransferResponse<PaystackTransferResponse.BalanceData[]>>() {});
    }

    // --- Internal HTTP helpers ---

    private <T, R> R post(String url, T requestBody, ParameterizedTypeReference<R> responseType) {
        try {
            HttpEntity<T> entity = new HttpEntity<>(requestBody, createHeaders());
            ResponseEntity<R> response = restTemplate.exchange(
                    url, HttpMethod.POST, entity, responseType);
            return handleResponse(response, "POST " + url);
        } catch (Exception e) {
            log.error("[PAYSTACK] POST request failed for {}: {}", url, e.getMessage());
            throw new RuntimeException("Paystack API call failed: " + e.getMessage(), e);
        }
    }

    private <R> R get(String url, ParameterizedTypeReference<R> responseType) {
        try {
            HttpEntity<Void> entity = new HttpEntity<>(createHeaders());
            ResponseEntity<R> response = restTemplate.exchange(
                    url, HttpMethod.GET, entity, responseType);
            return handleResponse(response, "GET " + url);
        } catch (Exception e) {
            log.error("[PAYSTACK] GET request failed for {}: {}", url, e.getMessage());
            throw new RuntimeException("Paystack API call failed: " + e.getMessage(), e);
        }
    }

    private <R> R handleResponse(ResponseEntity<R> response, String operation) {
        if (!response.getStatusCode().is2xxSuccessful()) {
            log.error("[PAYSTACK] HTTP {} on {}", response.getStatusCode(), operation);
            throw new RuntimeException("Paystack API error: " + response.getStatusCode());
        }

        R body = response.getBody();
        if (body == null) {
            log.error("[PAYSTACK] Empty response body from {}", operation);
            throw new RuntimeException("Paystack returned empty response");
        }

        log.info("[PAYSTACK] {} succeeded", operation);
        return body;
    }
}