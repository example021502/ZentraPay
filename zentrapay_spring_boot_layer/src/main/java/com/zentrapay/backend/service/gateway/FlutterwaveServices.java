package com.zentrapay.backend.service.gateway;

import com.zentrapay.backend.dto.bill.ValidateResponseDTO;
import com.zentrapay.backend.dto.payment.*;
import com.zentrapay.backend.exception.PaymentGatewayException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import tools.jackson.databind.JsonNode;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Flutterwave v3 API calls - the FAILOVER gateway (national and international).
 * This class only talks to Flutterwave; deciding WHEN to use it is done by
 * GatewayServices / BankTransferServices.
 *
 * <p>Flutterwave amounts are in major units (10.50 GHS = 10.50), unlike Paystack.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class FlutterwaveServices {

    private static final String GATEWAY = "Flutterwave";

    private final GatewayHttp http;

    @Value("${flutterwave.base-url}")
    private String baseUrl;
    @Value("${flutterwave.secret-key}")
    private String secretKey;
    @Value("${flutterwave.redirect-url:}")
    private String redirectUrl;

    // ------------------------------------------------------------------
    // Customers
    // ------------------------------------------------------------------

    /**
     * Creates the customer on Flutterwave and returns its id.
     *
     * <p>Flutterwave v3 identifies a payer by email, so if the customer endpoint
     * is not available for this account the email itself is used as the customer
     * reference ("local:email") instead of blocking the failover.
     */
    public String createCustomer(String email, String firstName, String lastName, String phoneNumber) {
        log.info("Flutterwave: creating customer for {}", email);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("email", email);
        body.put("name", (firstName + " " + lastName).trim());
        if (phoneNumber != null && !phoneNumber.isBlank()) {
            body.put("phonenumber", phoneNumber);
        }

        try {
            FlutterwaveCustomerResponseDTO response = http.post(GATEWAY, baseUrl + "/customers", secretKey, body, FlutterwaveCustomerResponseDTO.class);
            if (response != null && "success".equalsIgnoreCase(response.status()) && response.data() != null && response.data().id() != null) {
                return response.data().id();
            }
            log.warn("Flutterwave customer reply had no id ({}), using the email as reference", response == null ? "no response" : response.message());
        } catch (PaymentGatewayException e) {
            log.warn("Flutterwave customer create failed ({}), using the email as reference", e.getMessage());
        }
        return "local:" + email;
    }

    // ------------------------------------------------------------------
    // Beneficiaries (recipients)
    // ------------------------------------------------------------------

    /** Registers a bank account / mobile-money wallet and returns its beneficiary id. */
    public String createBeneficiary(String accountName, String accountNumber, String channelCode) {
        log.info("Flutterwave: creating beneficiary {} / {}", channelCode, accountNumber);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("account_number", accountNumber);
        body.put("account_bank", channelCode);
        body.put("beneficiary_name", accountName);

        FlutterwaveBeneficiaryResponseDTO response = http.post(GATEWAY, baseUrl + "/beneficiaries", secretKey, body, FlutterwaveBeneficiaryResponseDTO.class);
        if (response == null || !"success".equalsIgnoreCase(response.status()) || response.data() == null || response.data().id() == null) {
            throw new PaymentGatewayException("Flutterwave beneficiary request failed: " + (response == null ? "no response" : response.message()));
        }
        return response.data().id();
    }

    // ------------------------------------------------------------------
    // Transfers (payouts)
    // ------------------------------------------------------------------

    /**
     * Sends money from our Flutterwave balance. Flutterwave takes the destination
     * inline, so the recipient's bank code / account number / name are sent directly.
     */
    public GatewayTransferResult sendTransfer(BigDecimal amount, String channelCode, String accountNumber,
                                              String accountName, String currency, String narration, String reference) {
        log.info("Flutterwave: transfer ref={} amount={} {} to {} / {}", reference, amount, currency, channelCode, accountNumber);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("account_bank", channelCode);
        body.put("account_number", accountNumber);
        body.put("amount", amount);
        body.put("currency", currency);
        body.put("reference", reference);
        body.put("narration", narration == null || narration.isBlank() ? "Bank Transfer" : narration);
        body.put("beneficiary_name", accountName);

        FlutterwaveTransferResponseDTO response = http.post(GATEWAY, baseUrl + "/transfers", secretKey, body, FlutterwaveTransferResponseDTO.class);
        if (response == null || !"success".equalsIgnoreCase(response.status()) || response.data() == null) {
            throw new PaymentGatewayException("Flutterwave transfer rejected: " + (response == null ? "no response" : response.message()));
        }
        String status = String.valueOf(response.data().status()).toUpperCase();
        if ("FAILED".equals(status) || "REVERSED".equals(status)) {
            throw new PaymentGatewayException("Flutterwave transfer not accepted (status " + status + ")");
        }
        return new GatewayTransferResult(String.valueOf(response.data().id()), "SUCCESSFUL".equals(status));
    }

    /** Asks Flutterwave for the status of a transfer (SUCCESSFUL / PENDING / FAILED ...). */
    public String transferStatus(String reference) {
        JsonNode response = http.get(GATEWAY, baseUrl + "/transfers?reference=" + reference, secretKey, JsonNode.class);
        JsonNode first = response == null ? null : response.path("data").path(0);
        return first == null || first.path("status").isMissingNode() ? "unknown" : first.path("status").asString().toUpperCase();
    }

    // ------------------------------------------------------------------
    // Checkout (wallet funding)
    // ------------------------------------------------------------------

    /** Starts a hosted checkout the user pays on. */
    public GatewayCheckoutResult initializeCheckout(String email, String fullName, String phoneNumber,
                                                    BigDecimal amount, String currency, String reference) {
        log.info("Flutterwave: checkout ref={} amount={} {}", reference, amount, currency);
        Map<String, Object> customer = new LinkedHashMap<>();
        customer.put("email", email);
        customer.put("name", fullName);
        if (phoneNumber != null && !phoneNumber.isBlank()) {
            customer.put("phonenumber", phoneNumber);
        }

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("tx_ref", reference);
        body.put("amount", amount);
        body.put("currency", currency);
        body.put("customer", customer);
        if (redirectUrl != null && !redirectUrl.isBlank()) {
            body.put("redirect_url", redirectUrl);
        }

        FlutterwavePaymentResponseDTO response = http.post(GATEWAY, baseUrl + "/payments", secretKey, body, FlutterwavePaymentResponseDTO.class);
        if (response == null || !"success".equalsIgnoreCase(response.status()) || response.data() == null) {
            throw new PaymentGatewayException("Flutterwave checkout rejected: " + (response == null ? "no response" : response.message()));
        }
        return new GatewayCheckoutResult(response.data().link(), null);
    }

    /** Asks Flutterwave what happened to a checkout (used when the webhook never arrived). */
    public GatewayChargeStatus chargeStatus(String reference) {
        JsonNode data = http.get(GATEWAY, baseUrl + "/transactions/verify_by_reference?tx_ref=" + reference, secretKey, JsonNode.class).path("data");
        String status = data.path("status").asString("").toLowerCase();
        BigDecimal paid = data.path("amount").isNumber() ? data.path("amount").decimalValue() : null;
        return new GatewayChargeStatus("successful".equals(status), "failed".equals(status) || "cancelled".equals(status),
                paid, data.path("currency").asString(null));
    }

    // ------------------------------------------------------------------
    // Bill payments (electricity, TV, airtime ...)
    // NOTE: paths follow the Flutterwave v3 Bills API; confirm them with one sandbox call before go-live.
    // ------------------------------------------------------------------

    /** Checks that a meter / smartcard / phone number exists and returns the name on it. */
    public ValidateResponseDTO validateBillCustomer(String billerCode, String itemCode, String customer) {
        log.info("Flutterwave: validating bill customer for biller {}", billerCode);
        JsonNode response = http.get(GATEWAY,
                baseUrl + "/bills/" + itemCode + "/validate?code=" + billerCode + "&customer=" + customer,
                secretKey, JsonNode.class);
        boolean valid = response != null && "success".equalsIgnoreCase(response.path("status").asString(""));
        String name = response == null ? null : response.path("data").path("name").asString(null);
        return new ValidateResponseDTO(valid, name);
    }

    /** Pays the bill from our Flutterwave balance. The reference is our idempotency key. */
    public GatewayTransferResult payBill(String billerCode, String itemCode, String country, String customer,
                                         BigDecimal amount, String reference) {
        log.info("Flutterwave: paying bill ref={} biller={} amount={}", reference, billerCode, amount);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("country", country);
        body.put("customer", customer);
        body.put("amount", amount);
        body.put("recurrence", "ONCE");
        body.put("reference", reference);

        JsonNode response = http.post(GATEWAY, baseUrl + "/billers/" + billerCode + "/items/" + itemCode + "/payment",
                secretKey, body, JsonNode.class);
        if (response == null || !"success".equalsIgnoreCase(response.path("status").asString(""))) {
            throw new PaymentGatewayException("Flutterwave bill payment rejected: "
                    + (response == null ? "no response" : response.path("message").asString("unknown error")));
        }
        String status = response.path("data").path("status").asString("").toLowerCase();
        return new GatewayTransferResult(response.path("data").path("flw_ref").asString(reference),
                "success".equals(status) || "successful".equals(status));
    }

    // ------------------------------------------------------------------
    // Account name lookup
    // ------------------------------------------------------------------

    /** Returns the account holder's name for a bank account number. */
    public GatewayAccountResult resolveAccount(String accountNumber, String bankCode) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("account_number", accountNumber);
        body.put("account_bank", bankCode);

        FlutterwaveResolveResponseDTO response = http.post(GATEWAY, baseUrl + "/accounts/resolve", secretKey, body, FlutterwaveResolveResponseDTO.class);
        if (response == null || !"success".equalsIgnoreCase(response.status()) || response.data() == null || response.data().account_name() == null) {
            throw new PaymentGatewayException("Flutterwave could not resolve this account");
        }
        return new GatewayAccountResult(response.data().account_name(), response.data().account_number());
    }
}
