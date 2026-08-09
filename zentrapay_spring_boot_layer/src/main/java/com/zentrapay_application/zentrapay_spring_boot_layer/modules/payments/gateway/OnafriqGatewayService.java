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
 * Onafriq gateway implementation — INTERNATIONAL transactions gateway.
 * <p>
 * Onafriq (formerly MFS Africa) is the dedicated gateway for:
 * <ul>
 *   <li>Cross-border remittances across Africa</li>
 *   <li>International money transfers</li>
 *   <li>Transactions involving multiple African countries</li>
 * </ul>
 * <p>
 * Onafriq provides a unified API for sending money across different African mobile money
 * networks and banking systems, making it ideal for international disbursements.
 */
@Service
public class OnafriqGatewayService implements PaymentGatewayService {

    private static final Logger log = LoggerFactory.getLogger(OnafriqGatewayService.class);

    private final RestTemplate restTemplate;

    @Value("${onafriq.secret-key}")
    private String apiKey;

    @Value("${onafriq.base-url:https://api.onafriq.com/v1}")
    private String baseUrl;

    @Value("${onafriq.partner-id}")
    private String partnerId;

    public OnafriqGatewayService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    /**
     * Processes an international disbursement through Onafriq.
     * <p>
     * Flow:
     * <ol>
     *   <li>Authenticate with Onafriq API using API key and partner ID</li>
     *   <li>Create or validate recipient on Onafriq network</li>
     *   <li>Initiate cross-border money transfer</li>
     *   <li>Map Onafriq response to standard {@link PaymentsResponseDTO}</li>
     * </ol>
     *
     * @param request The validated disbursement request
     * @return Standardized payment response with Onafriq-specific details
     */
    @Override
    public PaymentsResponseDTO processDisbursement(DisbursementRequestDTO request) {
        String reference = "ONF-" + java.util.UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        log.info("[ONAFRIQ_GATEWAY] Processing international disbursement: ref={}, userId={}, amount={} {}",
                reference, request.userId(), request.paymentDetails().amount(), request.paymentDetails().sourceCurrency());

        try {
            // Create recipient on Onafriq network
            Map<String, Object> recipientResponse = createOrValidateRecipient(request.recipient());

            // Safely extract recipient ID from response data to resolve unchecked cast warnings
            Object rawRecipientData = recipientResponse.get("data");
            String recipientId = null;
            if (rawRecipientData instanceof Map) {
                @SuppressWarnings("unchecked")
                Map<String, Object> recipientDataMap = (Map<String, Object>) rawRecipientData;
                recipientId = (String) recipientDataMap.get("recipientId");
            }

            if (recipientId == null) {
                throw new RuntimeException("Recipient ID not found in Onafriq response data");
            }

            log.info("[ONAFRIQ_GATEWAY] Recipient created: code={}", recipientId);

            // Initiate cross-border money transfer
            Map<String, Object> transferResponse = initiateCrossBorderTransfer(request, recipientId, reference);

            String status = mapOnafriqStatus((String) transferResponse.get("status"));
            String transferId = (String) transferResponse.get("id");

            log.info("[ONAFRIQ_GATEWAY] International transfer initiated: ref={}, onafriqTransferId={}, status={}",
                    reference, transferId, status);

            BigDecimal fee = BigDecimal.ZERO;
            BigDecimal totalCharged = request.paymentDetails().amount().add(fee);

            return new PaymentsResponseDTO(
                    reference,
                    "Onafriq",
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
            log.error("[ONAFRIQ_GATEWAY] International transfer failed: ref={}, error={}", reference, e.getMessage(), e);
            throw new RuntimeException("Onafriq international disbursement failed: " + e.getMessage(), e);
        }
    }

    /**
     * Creates or validates a recipient on the Onafriq network.
     * <p>
     * API Endpoint: POST https://api.onafriq.com/v1/recipients
     * Authentication: Bearer {apiKey}, X-Partner-Id: {partnerId}
     *
     * @param recipient Recipient details from request
     * @return Onafriq recipient ID for use in transfers
     */
    private Map<String, Object> createOrValidateRecipient(RecipientRequestDetailsDTO recipient) {
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("type", "mobile_money");
        requestBody.put("name", recipient.accountName());
        requestBody.put("phoneNumber", recipient.accountNumber());
        requestBody.put("countryCode", recipient.bankCode());
        requestBody.put("provider", mapOnafriqProvider(recipient));

        log.info("[ONAFRIQ_GATEWAY] Creating recipient: name={}, phone={}, country={}, provider={}",
                recipient.accountName(), recipient.accountNumber(), recipient.bankCode(), mapOnafriqProvider(recipient));

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + apiKey);
        headers.set("X-Partner-Id", partnerId);
        headers.set("Content-Type", "application/json");

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/recipients",
                HttpMethod.POST,
                entity,
                Map.class
        );

        Map body = response.getBody();
        if (body == null || !Boolean.TRUE.equals(body.get("success"))) {
            String errorMsg = body != null ? (String) body.get("message") : "No response";
            log.error("[ONAFRIQ_GATEWAY] Failed to create recipient: {}", errorMsg);
            throw new RuntimeException("Failed to create Onafriq recipient: " + errorMsg);
        }

        // Safely extract response body map with type safety and suppression
        @SuppressWarnings("unchecked")
        Map<String, Object> responseBodyMap = (Map<String, Object>) body;

        Object rawData = responseBodyMap.get("data");
        if (rawData instanceof Map) {
            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) rawData;
            String recipientId = (String) data.get("recipientId");
            log.info("[ONAFRIQ_GATEWAY] Recipient created successfully: id={}", recipientId);
        }

        return responseBodyMap;
    }

    /**
     * Initiates a cross-border money transfer via Onafriq.
     * <p>
     * API Endpoint: POST https://api.onafriq.com/v1/transfers
     * Authentication: Bearer {apiKey}, X-Partner-Id: {partnerId}
     * <p>
     * This endpoint creates an international transfer from Ghana to the recipient's
     * country. Onafriq handles routing through their network of mobile money operators.
     *
     * @param request     The disbursement request
     * @param recipientId Onafriq recipient ID from createOrValidateRecipient()
     * @param reference   Unique transaction reference
     * @return Transfer response data from Onafriq
     */
    private Map<String, Object> initiateCrossBorderTransfer(DisbursementRequestDTO request, String recipientId, String reference) {
        int amountInSmallestUnit = request.paymentDetails().amount().multiply(BigDecimal.valueOf(100)).intValue();

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("amount", amountInSmallestUnit);
        requestBody.put("reference", reference);
        requestBody.put("recipientId", recipientId);
        requestBody.put("sourceCurrency", request.paymentDetails().sourceCurrency());
        requestBody.put("destinationCurrency", request.paymentDetails().destinationCurrency() != null
                ? request.paymentDetails().destinationCurrency()
                : request.paymentDetails().sourceCurrency());
        requestBody.put("narration", request.paymentDetails().narration() != null
                ? request.paymentDetails().narration()
                : "ZentraPay International Transfer");

        log.info("[ONAFRIQ_GATEWAY] Initiating transfer: amount={}, ref={}, recipient={}, srcCurrency={}, dstCurrency={}",
                amountInSmallestUnit, reference, recipientId,
                request.paymentDetails().sourceCurrency(),
                request.paymentDetails().destinationCurrency() != null ? request.paymentDetails().destinationCurrency() : request.paymentDetails().sourceCurrency());

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + apiKey);
        headers.set("X-Partner-Id", partnerId);
        headers.set("Content-Type", "application/json");

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/transfers",
                HttpMethod.POST,
                entity,
                Map.class
        );

        Map body = response.getBody();
        if (body == null || !Boolean.TRUE.equals(body.get("success"))) {
            String errorMsg = body != null ? (String) body.get("message") : "No response";
            log.error("[ONAFRIQ_GATEWAY] Transfer initiation failed: {}", errorMsg);
            throw new RuntimeException("Failed to initiate Onafriq cross-border transfer: " + errorMsg);
        }

        // Safely extract transfer data map with type safety and suppression
        @SuppressWarnings("unchecked")
        Map<String, Object> responseBodyMap = (Map<String, Object>) body;

        Object rawData = responseBodyMap.get("data");
        Map<String, Object> data = new HashMap<>();
        if (rawData instanceof Map) {
            @SuppressWarnings("unchecked")
            Map<String, Object> castedData = (Map<String, Object>) rawData;
            data = castedData;
        }

        log.info("[ONAFRIQ_GATEWAY] Transfer initiated successfully: transferId={}", data.get("id"));
        return data;
    }

    private String mapOnafriqProvider(RecipientRequestDetailsDTO recipient) {
        String bankCode = recipient.bankCode();
        if (bankCode == null) return "MOMO";

        return switch (bankCode.toUpperCase()) {
            case "GH" -> "MTN";
            case "NG" -> "MPESA";
            case "KE" -> "MTN";
            case "TZ" -> "MPESA";
            case "UG" -> "MTN";
            default -> "MOMO";
        };
    }

    private String mapOnafriqStatus(String onafriqStatus) {
        if (onafriqStatus == null) return "PENDING";
        return switch (onafriqStatus.toUpperCase()) {
            case "COMPLETED", "SUCCESS" -> "SUCCESSFUL";
            case "PENDING", "PROCESSING" -> "PENDING";
            case "FAILED", "CANCELLED", "REJECTED" -> "FAILED";
            default -> "PENDING";
        };
    }

    @Override
    public String getGatewayName() {
        return "Onafriq";
    }

    @Override
    public boolean supportsCurrency(String currencyCode) {
        if (currencyCode == null || currencyCode.isBlank()) {
            return false;
        }
        return switch (currencyCode.toUpperCase()) {
            case "GHS", "NGN", "KES", "UGX", "TZS", "XOF", "XAF", "USD", "EUR", "GBP" -> true;
            default -> false;
        };
    }

    @Override
    public boolean isOperational() {
        return apiKey != null && !apiKey.isBlank() &&
                partnerId != null && !partnerId.isBlank();
    }
}