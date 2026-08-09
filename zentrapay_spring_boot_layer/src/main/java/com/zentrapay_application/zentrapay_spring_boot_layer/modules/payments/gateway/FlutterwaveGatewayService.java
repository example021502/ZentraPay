package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.gateway;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.DisbursementRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.RecipientRequestDetailsDTO;
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
 * Flutterwave gateway implementation — SECONDARY/FAILOVER gateway for both national and international transactions.
 * <p>
 * Flutterwave serves as the backup gateway when:
 * <ul>
 *   <li>Paystack is unavailable or experiencing downtime</li>
 *   <li>Onafriq (international gateway) fails to process a transaction</li>
 *   <li>Specific currency or destination type is not supported by primary gateways</li>
 * </ul>
 * <p>
 * Flutterwave supports a comprehensive set of currencies and payment methods across Africa,
 * making it an ideal failover option with broad coverage.
 */
@Service
public class FlutterwaveGatewayService implements PaymentGatewayService {

    private static final Logger log = LoggerFactory.getLogger(FlutterwaveGatewayService.class);

    private final RestTemplate restTemplate;

    @Value("${flutterwave.secret-key}")
    private String secretKey;

    @Value("${flutterwave.base-url:https://api.flutterwave.com/v3}")
    private String baseUrl;

    public FlutterwaveGatewayService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    /**
     * Processes a disbursement through Flutterwave.
     * <p>
     * Flow:
     * <ol>
     *   <li>Authenticate with Flutterwave API using secret key</li>
     *   <li>Create transfer recipient (virtual account or wallet)</li>
     *   <li>Initiate money transfer</li>
     *   <li>Map Flutterwave response to standard {@link PaymentsResponseDTO}</li>
     * </ol>
     *
     * @param request The validated disbursement request
     * @return Standardized payment response with Flutterwave-specific details
     */
    @Override
    public PaymentsResponseDTO processDisbursement(DisbursementRequestDTO request) {
        String reference = "FLW-" + java.util.UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        log.info("[FLUTTERWAVE_GATEWAY] Processing disbursement: ref={}, userId={}, amount={} {}",
                reference, request.userId(), request.paymentDetails().amount(), request.paymentDetails().sourceCurrency());

        try {
            // ====================================================================
            // STEP 1: Create transfer recipient on Flutterwave
            // Actual API call:
            // restClient.post()
            //     .uri("https://api.flutterwave.com/v3/transfers/recipients")
            //     .header("Authorization", "Bearer " + secretKey)
            //     .body(payload)
            //     .retrieve()
            //     .body(RecipientResponse.class);
            // ====================================================================
            String recipientCode = createTransferRecipient(request.recipient());
            log.info("[FLUTTERWAVE_GATEWAY] Recipient created: code={}", recipientCode);

            // ====================================================================
            // STEP 2: Initiate money transfer
            // Actual API call:
            // restClient.post()
            //     .uri("https://api.flutterwave.com/v3/transfers")
            //     .header("Authorization", "Bearer " + secretKey)
            //     .body(payload)
            //     .retrieve()
            //     .body(TransferResponse.class);
            // ====================================================================
            Map<String, Object> transferResponse = initiateTransfer(request, recipientCode, reference);

            String status = mapFlutterwaveStatus((String) transferResponse.get("status"));
            String flutterwaveId = String.valueOf(transferResponse.get("id"));

            log.info("[FLUTTERWAVE_GATEWAY] Transfer successful: ref={}, flutterwaveId={}, status={}",
                    reference, flutterwaveId, status);

            BigDecimal fee = BigDecimal.ZERO;
            BigDecimal totalCharged = request.paymentDetails().amount().add(fee);

            return new PaymentsResponseDTO(
                    reference,
                    "Flutterwave",
                    request.paymentDetails().amount(),
                    request.paymentDetails().sourceCurrency(),
                    fee,
                    totalCharged,
                    status,
                    request.paymentDetails().destinationType(),
                    null,
                    null,
                    Instant.now()
            );

        } catch (Exception e) {
            log.error("[FLUTTERWAVE_GATEWAY] Transfer failed: ref={}, error={}", reference, e.getMessage(), e);
            throw new RuntimeException("Flutterwave disbursement failed: " + e.getMessage(), e);
        }
    }

    /**
     * Creates a transfer recipient on Flutterwave.
     * <p>
     * API Endpoint: POST https://api.flutterwave.com/v3/transfers/recipients
     * Authentication: Bearer {secretKey}
     *
     * @param recipient Recipient details from request
     * @return Flutterwave recipient code for use in transfers
     */
    private String createTransferRecipient(RecipientRequestDetailsDTO recipient) {
        String recipientType = mapDestinationType(recipient);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("type", recipientType);
        requestBody.put("name", recipient.accountName());
        requestBody.put("account_number", recipient.accountNumber());
        requestBody.put("bank_code", recipient.bankCode());
        requestBody.put("currency", recipient.bankCode() != null && recipient.bankCode().startsWith("0") ? "NGN" : "GHS");

        log.info("[FLUTTERWAVE_GATEWAY] Creating recipient: type={}, name={}, account={}, bank={}",
                recipientType, recipient.accountName(), recipient.accountNumber(), recipient.bankCode());

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + secretKey);
        headers.set("Content-Type", "application/json");

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/transfers/recipients",
                HttpMethod.POST,
                entity,
                Map.class
        );

        Map<String, Object> body = response.getBody();
        if (body == null || !Boolean.TRUE.equals(body.get("status"))) {
            String errorMsg = body != null ? (String) body.get("message") : "No response";
            log.error("[FLUTTERWAVE_GATEWAY] Failed to create recipient: {}", errorMsg);
            throw new RuntimeException("Failed to create Flutterwave transfer recipient: " + errorMsg);
        }

        Map<String, Object> data = (Map<String, Object>) body.get("data");
        String recipientCode = (String) data.get("recipient_code");
        log.info("[FLUTTERWAVE_GATEWAY] Recipient created successfully: code={}", recipientCode);
        return recipientCode;
    }

    /**
     * Initiates a money transfer via Flutterwave.
     * <p>
     * API Endpoint: POST https://api.flutterwave.com/v3/transfers
     * Authentication: Bearer {secretKey}
     * <p>
     * This endpoint creates a transfer to a previously created recipient.
     * Flutterwave handles the routing to the appropriate bank/mobile money network.
     *
     * @param request       The disbursement request
     * @param recipientCode Flutterwave recipient code from createTransferRecipient()
     * @param reference      Unique transaction reference
     * @return Transfer response data from Flutterwave
     */
    private Map<String, Object> initiateTransfer(DisbursementRequestDTO request, String recipientCode, String reference) {
        int amountInSmallestUnit = request.paymentDetails().amount().multiply(BigDecimal.valueOf(100)).intValue();

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("amount", amountInSmallestUnit);
        requestBody.put("reference", reference);
        requestBody.put("recipient", recipientCode);
        requestBody.put("reason", request.paymentDetails().narration() != null
                ? request.paymentDetails().narration()
                : "ZentraPay Disbursement");
        requestBody.put("currency", request.paymentDetails().sourceCurrency());

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + secretKey);
        headers.set("Content-Type", "application/json");

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/transfers",
                HttpMethod.POST,
                entity,
                Map.class
        );

        Map<String, Object> body = response.getBody();
        if (body == null || !Boolean.TRUE.equals(body.get("status"))) {
            String errorMsg = body != null ? (String) body.get("message") : "No response";
            log.error("[FLUTTERWAVE_GATEWAY] Transfer request failed: {}", errorMsg);
            throw new RuntimeException("Failed to initiate Flutterwave transfer: " + errorMsg);
        }

        return (Map<String, Object>) body.get("data");
    }

    private String mapDestinationType(RecipientRequestDetailsDTO recipient) {
        String bankCode = recipient.bankCode();
        if (bankCode != null && bankCode.startsWith("0")) {
            return "nuban";
        }
        return "nuban";
    }

    private String mapFlutterwaveStatus(String flutterwaveStatus) {
        if (flutterwaveStatus == null) return "PENDING";
        return switch (flutterwaveStatus.toLowerCase()) {
            case "success", "completed" -> "SUCCESSFUL";
            case "pending", "processing" -> "PENDING";
            case "failed", "cancelled" -> "FAILED";
            default -> "PENDING";
        };
    }

    @Override
    public String getGatewayName() {
        return "Flutterwave";
    }

    @Override
    public boolean supportsCurrency(String currencyCode) {
        if (currencyCode == null || currencyCode.isBlank()) {
            return false;
        }
        return switch (currencyCode.toUpperCase()) {
            case "NGN", "GHS", "KES", "USD", "EUR", "GBP", "ZAR", "UGX", "TZS" -> true;
            default -> false;
        };
    }

    @Override
    public boolean isOperational() {
        return secretKey != null && !secretKey.isBlank();
    }
}