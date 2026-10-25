package com.zentrapay.backend.service.gateway;

import com.zentrapay.backend.dto.payment.*;
import com.zentrapay.backend.exception.PaymentGatewayException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Paystack API calls - the PRIMARY gateway for national payments.
 * This class only talks to Paystack; deciding WHEN to use it (and failing over
 * to Flutterwave) is done by GatewayServices / BankTransferServices.
 *
 * <p>Paystack wants amounts in minor units (pesewas / kobo), so every amount
 * is multiplied by 100 on the way out.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaystackServices {

    private static final String GATEWAY = "Paystack";

    private final GatewayHttp http;

    @Value("${paystack.secret-key}")
    private String secretKey;
    @Value("${paystack.base-url}")
    private String baseUrl;
    @Value("${paystack.callback-url:}")
    private String callbackUrl;

    // ------------------------------------------------------------------
    // Customers
    // ------------------------------------------------------------------

    /**
     * Creates the customer on Paystack and returns its customer code (CUS_xxx).
     * If Paystack refuses (for example the email already exists), the existing
     * customer is fetched instead.
     */
    public String createCustomer(String email, String firstName, String lastName, String phoneNumber) {
        log.info("Paystack: creating customer for {}", email);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("email", email);
        body.put("first_name", firstName);
        body.put("last_name", lastName);
        if (phoneNumber != null && !phoneNumber.isBlank()) {
            body.put("phone", phoneNumber);
        }

        try {
            PaystackCustomerResponseDTO response = http.post(GATEWAY, baseUrl + "/customer", secretKey, body, PaystackCustomerResponseDTO.class);
            return customerCode(response);
        } catch (PaymentGatewayException e) {
            if (e.isOutcomeUnknown()) {
                throw e;
            }
            log.info("Paystack customer create failed ({}), looking the email up instead", e.getMessage());
            return fetchCustomer(email);
        }
    }

    /** Finds an existing Paystack customer by email and returns its customer code. */
    public String fetchCustomer(String email) {
        PaystackCustomerResponseDTO response = http.get(GATEWAY, baseUrl + "/customer/" + email, secretKey, PaystackCustomerResponseDTO.class);
        return customerCode(response);
    }

    private String customerCode(PaystackCustomerResponseDTO response) {
        if (response == null || !Boolean.TRUE.equals(response.status()) || response.data() == null || response.data().customerCode() == null) {
            throw new PaymentGatewayException("Paystack customer request failed: " + (response == null ? "no response" : response.message()));
        }
        return response.data().customerCode();
    }

    // ------------------------------------------------------------------
    // Transfer recipients
    // ------------------------------------------------------------------

    /** Registers a bank account / mobile-money wallet and returns its recipient code (RCP_xxx). */
    public String createRecipient(String checkoutType, String countryCode, String accountName,
                                  String accountNumber, String channelCode, String currency) {
        log.info("Paystack: creating {} recipient {} / {}", checkoutType, channelCode, accountNumber);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("type", recipientType(checkoutType, countryCode));
        body.put("name", accountName);
        body.put("account_number", accountNumber);
        body.put("bank_code", channelCode);
        body.put("currency", currency);

        PaystackRecipientResponseDTO response = http.post(GATEWAY, baseUrl + "/transferrecipient", secretKey, body, PaystackRecipientResponseDTO.class);
        if (response == null || !Boolean.TRUE.equals(response.status()) || response.data() == null || response.data().recipientCode() == null) {
            throw new PaymentGatewayException("Paystack recipient request failed: " + (response == null ? "no response" : response.message()));
        }
        return response.data().recipientCode();
    }

    // Paystack recipient types: nuban (Nigeria), ghipss (Ghana banks), mobile_money
    private String recipientType(String checkoutType, String countryCode) {
        if ("MOBILE_MONEY".equalsIgnoreCase(checkoutType)) {
            return "mobile_money";
        }
        return "NG".equalsIgnoreCase(countryCode) ? "nuban" : "ghipss";
    }

    // ------------------------------------------------------------------
    // Transfers (payouts)
    // ------------------------------------------------------------------

    /** Sends money from our Paystack balance to a recipient. The reference is our idempotency key. */
    public GatewayTransferResult sendTransfer(BigDecimal amount, String recipientCode, String currency,
                                              String reason, String reference) {
        log.info("Paystack: transfer ref={} amount={} {} recipient={}", reference, amount, currency, recipientCode);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("source", "balance");
        body.put("amount", toMinorUnits(amount));
        body.put("recipient", recipientCode);
        body.put("reason", reason == null || reason.isBlank() ? "Bank Transfer" : reason);
        body.put("reference", reference);
        body.put("currency", currency);

        PaystackTransferResponseDTO response = http.post(GATEWAY, baseUrl + "/transfer", secretKey, body, PaystackTransferResponseDTO.class);
        if (response == null || !Boolean.TRUE.equals(response.status()) || response.data() == null) {
            throw new PaymentGatewayException("Paystack transfer rejected: " + (response == null ? "no response" : response.message()));
        }
        String status = String.valueOf(response.data().status()).toLowerCase();
        if ("failed".equals(status) || "reversed".equals(status) || "otp".equals(status)) {
            throw new PaymentGatewayException("Paystack transfer not accepted (status " + status + ")");
        }
        return new GatewayTransferResult(response.data().transferCode(), "success".equals(status));
    }

    /** Asks Paystack for the current status of a transfer (success / pending / failed / reversed). */
    public String transferStatus(String reference) {
        PaystackTransferResponseDTO response = http.get(GATEWAY, baseUrl + "/transfer/verify/" + reference, secretKey, PaystackTransferResponseDTO.class);
        return response == null || response.data() == null ? "unknown" : String.valueOf(response.data().status()).toLowerCase();
    }

    // ------------------------------------------------------------------
    // Checkout (wallet funding)
    // ------------------------------------------------------------------

    /** Starts a hosted checkout the user pays on. Returns the pay-page url and the SDK access code. */
    public GatewayCheckoutResult initializeCheckout(String email, BigDecimal amount, String currency, String reference) {
        log.info("Paystack: checkout ref={} amount={} {}", reference, amount, currency);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("email", email);
        body.put("amount", toMinorUnits(amount));
        body.put("currency", currency);
        body.put("reference", reference);
        if (callbackUrl != null && !callbackUrl.isBlank()) {
            body.put("callback_url", callbackUrl);
        }

        PaystackInitializeResponseDTO response = http.post(GATEWAY, baseUrl + "/transaction/initialize", secretKey, body, PaystackInitializeResponseDTO.class);
        if (response == null || !Boolean.TRUE.equals(response.status()) || response.data() == null) {
            throw new PaymentGatewayException("Paystack checkout rejected: " + (response == null ? "no response" : response.message()));
        }
        return new GatewayCheckoutResult(response.data().authorizationUrl(), response.data().accessCode());
    }

    /** Asks Paystack what happened to a checkout (used when the webhook never arrived). */
    public GatewayChargeStatus chargeStatus(String reference) {
        PaystackVerifyResponseDTO response = http.get(GATEWAY, baseUrl + "/transaction/verify/" + reference, secretKey, PaystackVerifyResponseDTO.class);
        if (response == null || response.data() == null) {
            return new GatewayChargeStatus(false, false, null, null);
        }
        String status = String.valueOf(response.data().status()).toLowerCase();
        BigDecimal paid = response.data().amount() == null ? null : BigDecimal.valueOf(response.data().amount()).movePointLeft(2);
        return new GatewayChargeStatus("success".equals(status),
                "failed".equals(status) || "abandoned".equals(status) || "reversed".equals(status),
                paid, response.data().currency());
    }

    // ------------------------------------------------------------------
    // Account name lookup
    // ------------------------------------------------------------------

    /** Returns the account holder's name for a bank account number. */
    public GatewayAccountResult resolveAccount(String accountNumber, String bankCode) {
        PaystackAccountResolveResponseDTO response = http.get(GATEWAY,
                baseUrl + "/bank/resolve?account_number=" + accountNumber + "&bank_code=" + bankCode,
                secretKey, PaystackAccountResolveResponseDTO.class);
        if (response == null || !Boolean.TRUE.equals(response.status()) || response.data() == null || response.data().accountName() == null) {
            throw new PaymentGatewayException("Paystack could not resolve this account");
        }
        return new GatewayAccountResult(response.data().accountName(), response.data().accountNumber());
    }

    // Paystack amounts are whole minor units: 10.50 GHS -> 1050
    static long toMinorUnits(BigDecimal amount) {
        return amount.movePointRight(2).longValueExact();
    }
}
