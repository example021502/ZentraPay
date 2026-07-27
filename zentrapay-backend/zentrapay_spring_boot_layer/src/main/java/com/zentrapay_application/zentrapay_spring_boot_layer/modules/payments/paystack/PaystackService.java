package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.paystack;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.DisbursementRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.RecipientRequestDetailsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.gateway.PaymentGatewayService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

/**
 * Service layer for orchestrating Paystack disbursement operations.
 * <p>
 * Handles the full lifecycle of an outbound payment:
 * <ol>
 *   <li>Map the internal {@link DisbursementRequestDTO} to Paystack API DTOs</li>
 *   <li>Create a transfer recipient on Paystack (if not already cached)</li>
 *   <li>Initiate the transfer via Paystack</li>
 *   <li>Return a standardized {@link PaymentsResponseDTO}</li>
 * </ol>
 * <p>
 * Designed for the African market — supports NGN, GHS, ZAR, USD, and other
 * currencies supported by Paystack.
 */
@Service
public class PaystackService implements PaymentGatewayService {

    private static final Logger log = LoggerFactory.getLogger(PaystackService.class);

    private final RestTemplate restTemplate;

    @Value("${paystack.secret-key}")
    private String secretKey;

    @Value("${paystack.base-url:https://api.paystack.co}")
    private String baseUrl;

    public PaystackService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    /**
     * Processes a disbursement through Paystack.
     * <p>
     * Flow:
     * <ol>
     *   <li>Determine destination type (mobile_money, nuban, ghipss, etc.)</li>
     *   <li>Convert amount to smallest currency unit (kobo/pesewas/cents)</li>
     *   <li>Create transfer recipient on Paystack via POST /transferrecipient</li>
     *   <li>Initiate transfer via POST /transfer</li>
     *   <li>Map Paystack response to standardized format</li>
     * </ol>
     *
     * @param request The disbursement request from the Node.js layer
     * @return Standardized payment response
     */
    @Override
    public PaymentsResponseDTO processDisbursement(DisbursementRequestDTO request) {
        RecipientRequestDetailsDTO recipient = request.recipient();
        String sourceCurrency = request.paymentDetails().sourceCurrency();
        String destinationCurrency = request.paymentDetails().destinationCurrency() != null
                ? request.paymentDetails().destinationCurrency()
                : sourceCurrency;
        String destinationType = request.paymentDetails().destinationType() != null
                ? request.paymentDetails().destinationType()
                : "MOBILE_MONEY";
        String narration = request.paymentDetails().narration() != null
                ? request.paymentDetails().narration()
                : "ZentraPay Disbursement Payout";
        String reference = request.paymentDetails().reference() != null
                ? request.paymentDetails().reference()
                : "DISB-" + java.util.UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        log.info("[PAYSTACK_SERVICE] Processing disbursement: ref={}, amount={} {}, destType={}, destCurrency={}",
                reference, request.paymentDetails().amount(), sourceCurrency, destinationType, destinationCurrency);

        try {
            // ====================================================================
            // STEP 1: Map destination type to Paystack recipient type
            // ====================================================================
            String paystackRecipientType = mapDestinationType(destinationType);
            log.info("[PAYSTACK_SERVICE] Mapped destination type {} -> Paystack type {}", destinationType, paystackRecipientType);

            // ====================================================================
            // STEP 2: Create transfer recipient on Paystack
            // API Endpoint: POST https://api.paystack.co/transferrecipient
            // ====================================================================
            Map<String, Object> recipientPayload = new HashMap<>();
            recipientPayload.put("type", paystackRecipientType);
            recipientPayload.put("name", recipient.accountName());
            recipientPayload.put("account_number", recipient.accountNumber());
            recipientPayload.put("bank_code", recipient.bankCode());
            recipientPayload.put("currency", destinationCurrency);

            HttpHeaders recipientHeaders = new HttpHeaders();
            recipientHeaders.set("Authorization", "Bearer " + secretKey);
            recipientHeaders.set("Content-Type", "application/json");

            HttpEntity<Map<String, Object>> recipientEntity = new HttpEntity<>(recipientPayload, recipientHeaders);

            // Example of where the actual API call happens:
            // restClient.post()
            //     .uri("https://api.paystack.co/transferrecipient")
            //     .header("Authorization", "Bearer " + secretKey)
            //     .body(paystackPayload)
            //     .retrieve()
            //     .body(PaystackResponse.class);
            ResponseEntity<Map> recipientResponse = restTemplate.exchange(
                    baseUrl + "/transferrecipient",
                    HttpMethod.POST,
                    recipientEntity,
                    Map.class
            );

            Map<String, Object> recipientData = (Map<String, Object>) recipientResponse.getBody();
            String recipientCode = (String) ((Map<String, Object>) recipientData.get("data")).get("recipient_code");
            log.info("[PAYSTACK_SERVICE] Transfer recipient created: code={}", recipientCode);

            // ====================================================================
            // STEP 3: Convert amount to smallest currency unit (kobo/pesewas/cents)
            // ====================================================================
            int amountInSmallestUnit = convertToSmallestUnit(request.paymentDetails().amount(), destinationCurrency);
            log.info("[PAYSTACK_SERVICE] Amount converted: {} {} -> {} smallest units",
                    request.paymentDetails().amount(), destinationCurrency, amountInSmallestUnit);

            // ====================================================================
            // STEP 4: Initiate the transfer
            // API Endpoint: POST https://api.paystack.co/transfer
            // ====================================================================
            Map<String, Object> transferPayload = new HashMap<>();
            transferPayload.put("amount", amountInSmallestUnit);
            transferPayload.put("reference", reference);
            transferPayload.put("recipient", recipientCode);
            transferPayload.put("reason", narration);
            transferPayload.put("currency", destinationCurrency);

            HttpEntity<Map<String, Object>> transferEntity = new HttpEntity<>(transferPayload, recipientHeaders);

            // Example of where the actual API call happens:
            // restClient.post()
            //     .uri("https://api.paystack.co/transfer")
            //     .header("Authorization", "Bearer " + secretKey)
            //     .body(paystackPayload)
            //     .retrieve()
            //     .body(PaystackResponse.class);
            ResponseEntity<Map> transferResponse = restTemplate.exchange(
                    baseUrl + "/transfer",
                    HttpMethod.POST,
                    transferEntity,
                    Map.class
            );

            Map<String, Object> transferData = (Map<String, Object>) transferResponse.getBody();
            String status = mapPaystackStatus((String) ((Map<String, Object>) transferData.get("data")).get("status"));

            log.info("[PAYSTACK_SERVICE] Disbursement processed successfully: ref={}, status={}",
                    reference, status);

            // ====================================================================
            // STEP 5: Build and return standardized response
            // ====================================================================
            BigDecimal fee = BigDecimal.ZERO;
            BigDecimal totalCharged = request.paymentDetails().amount().add(fee);

            return new PaymentsResponseDTO(
                    reference,
                    "Paystack",
                    request.paymentDetails().amount(),
                    sourceCurrency,
                    fee,
                    totalCharged,
                    status,
                    destinationType,
                    null,
                    null,
                    Instant.now()
            );

        } catch (Exception e) {
            log.error("[PAYSTACK_SERVICE] Disbursement failed: ref={}, error={}", reference, e.getMessage(), e);
            throw new RuntimeException("Paystack disbursement failed: " + e.getMessage(), e);
        }
    }

    private String mapDestinationType(String destinationType) {
        if (destinationType == null) return "ghipss";
        return switch (destinationType.toUpperCase()) {
            case "MOBILE_MONEY" -> "mobile_money";
            case "NUBAN" -> "nuban";
            case "BASA" -> "basa";
            case "GHIPSS" -> "ghipss";
            case "ZAR_BANK", "BANK" -> "bank";
            default -> "ghipss";
        };
    }

    private int convertToSmallestUnit(BigDecimal amount, String currency) {
        return amount.multiply(BigDecimal.valueOf(100)).intValue();
    }

    private String mapPaystackStatus(String paystackStatus) {
        if (paystackStatus == null) return "PENDING";
        return switch (paystackStatus.toLowerCase()) {
            case "success" -> "SUCCESSFUL";
            case "pending", "otp" -> "PENDING";
            case "failed" -> "FAILED";
            case "reversed" -> "REVERSED";
            default -> "PENDING";
        };
    }

    @Override
    public String getGatewayName() {
        return "Paystack";
    }

    @Override
    public boolean supportsCurrency(String currencyCode) {
        if (currencyCode == null || currencyCode.isBlank()) {
            return false;
        }
        return switch (currencyCode.toUpperCase()) {
            case "GHS", "NGN", "KES", "USD", "EUR", "GBP", "ZAR", "UGX", "TZS" -> true;
            default -> false;
        };
    }

    @Override
    public boolean isOperational() {
        return secretKey != null && !secretKey.isBlank();
    }
}