package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransferRecipientModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransferRecipientRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Outbound payout orchestration (business rule 3): Paystack is PRIMARY for
 * national payments (chosen by the sender's registration country), Onafriq
 * is PRIMARY for international payments, and Flutterwave is the failover for
 * both corridors. Recipient codes are cached in the gateway_recipients table.
 * Every attempt is journaled as a {@code transactions} row
 * (status "processing"/"failed") so payout history survives gateway outages.
 * Gateway recipient codes are cached in {@code gateway_recipients}.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaystackServices {

    // NOTE: recipient gateway codes are cached in gateway_recipients so a
    // repeat payout to the same (user, gateway, account, provider) never
    // re-registers the recipient with the gateway.

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final OnafriqClient onafriqClient;
    private final FlutterwaveClient flutterwaveClient;
    private final PasswordEncoder passwordEncoder;
    private final RestClient restClient;

    @Value("${app.pin.pepper}")
    private String pinPepper;
    @Value("${zentrapay.primary-national-gateway}")
    private String primaryNationalGateway;
    @Value("${zentrapay.primary-international-gateway}")
    private String primaryInternationalGateway;
    @Value("${zentrapay.secondary-gateway}")
    private String failoverGateway;
    @Value("${paystack.secret-key}")
    private String paystackSecretKey;
    @Value("${paystack.base-url}")
    private String paystackBaseUrl;


    //  INITIATING A BANK TRANSFER
    //  Calls Paystack POST /transfer with a previously-provisioned recipient code.
    //  Amount is in major units (e.g. NGN); Paystack expects minor units (kobo).
    @Transactional
    public PaystackTransferResponseDTO initiateBankTransfer(
            BigDecimal amount,
            String recipientCode,
            String currencyCode,
            String reason,
            String reference) {

        long amountInMinorUnits = amount.multiply(new BigDecimal("100")).longValueExact();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("source", "balance");
        payload.put("amount", amountInMinorUnits);
        payload.put("recipient", recipientCode);
        payload.put("reason", reason == null || reason.isBlank() ? "Bank Transfer" : reason);
        payload.put("reference", reference);
        payload.put("currency", currencyCode);

        log.info("Initiating Paystack transfer ref={} amount={} recipient={}", reference, amount, recipientCode);

        try {
            return restClient.post()
                    .uri(paystackBaseUrl + "/transfer")
                    .header("Authorization", "Bearer " + paystackSecretKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .accept(MediaType.APPLICATION_JSON)
                    .body(payload)
                    .retrieve()
                    .onStatus(HttpStatusCode::is4xxClientError, (request, response) -> {
                        log.warn("Paystack transfer client error: status={} ref={}", response.getStatusCode(), reference);
                    })
                    .onStatus(HttpStatusCode::is5xxServerError, (request, response) -> {
                        log.warn("Paystack transfer server error: status={} ref={}", response.getStatusCode(), reference);
                    })
                    .body(PaystackTransferResponseDTO.class);
        } catch (Exception e) {
            log.error("Paystack transfer failed for ref {}: {}", reference, e.getMessage());
            return null;
        }
    }

    //  INITIALIZING AN INBOUND CHECKOUT (customer wallet funding)
    //  Calls Paystack POST /transaction/initialize. Amount is in major units;
    //  Paystack expects minor units (kobo/pesewas).
    @Transactional
    public PaystackInitializeResponseDTO initializeTransaction(
            String email,
            BigDecimal amountMajor,
            String currencyCode,
            String reference) {

        long amountInMinorUnits = amountMajor.multiply(new BigDecimal("100")).longValueExact();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("email", email);
        payload.put("amount", amountInMinorUnits);
        payload.put("currency", currencyCode);
        payload.put("reference", reference);

        log.info("Initializing Paystack checkout ref={} amount={} email={}", reference, amountMajor, email);

        try {
            return restClient.post()
                    .uri(paystackBaseUrl + "/transaction/initialize")
                    .header("Authorization", "Bearer " + paystackSecretKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .accept(MediaType.APPLICATION_JSON)
                    .body(payload)
                    .retrieve()
                    .onStatus(HttpStatusCode::is4xxClientError, (request, response) -> {
                        log.warn("Paystack initialize client error: status={} ref={}", response.getStatusCode(), reference);
                    })
                    .onStatus(HttpStatusCode::is5xxServerError, (request, response) -> {
                        log.warn("Paystack initialize server error: status={} ref={}", response.getStatusCode(), reference);
                    })
                    .body(PaystackInitializeResponseDTO.class);
        } catch (Exception e) {
            log.error("Paystack checkout initialization failed for ref {}: {}", reference, e.getMessage());
            return null;
        }
    }

    //  RESOLVING AN ACCOUNT NUMBER TO ITS ACCOUNT NAME
    //  Calls Paystack GET /bank/resolve — used by the bank-transfer UI to
    //  show the real account holder's name before the user confirms a send.
    public PaystackAccountResolveResponseDTO resolveAccount(String accountNumber, String bankCode) {
        try {
            return restClient.get()
                    .uri(paystackBaseUrl + "/bank/resolve?account_number={accountNumber}&bank_code={bankCode}",
                            accountNumber, bankCode)
                    .header("Authorization", "Bearer " + paystackSecretKey)
                    .accept(MediaType.APPLICATION_JSON)
                    .retrieve()
                    .onStatus(HttpStatusCode::is4xxClientError, (request, response) -> {
                        log.warn("Paystack account resolve client error: status={} account={}", response.getStatusCode(), accountNumber);
                    })
                    .onStatus(HttpStatusCode::is5xxServerError, (request, response) -> {
                        log.warn("Paystack account resolve server error: status={} account={}", response.getStatusCode(), accountNumber);
                    })
                    .body(PaystackAccountResolveResponseDTO.class);
        } catch (Exception e) {
            log.error("Paystack account resolve failed for account {}: {}", accountNumber, e.getMessage());
            return null;
        }
    }

//  CREATING A NEW CUSTOMER
    @Transactional
    public PaystackCustomerResponseDTO createCustomer(UserModel sender, PaymentRequestDTO req) {
        // Resolve customer parameters with fallback handling
        String email = (req.recipient() != null && req.recipient().email() != null && !req.recipient().email().isBlank())
                ? req.recipient().email()
                : sender.getEmail();
        String firstName = sender.getFirstName();
        String lastName = sender.getLastName();
        String phone = sender.getPhoneNumber();

        // Construct HTTP JSON Request Payload
        PaystackNewCustomerDTO payload = new PaystackNewCustomerDTO(
                email,
                firstName,
                lastName,
                phone
        );

        log.info("Sending HTTP request to Paystack to create customer for user ID: {}", sender.getUserId());

        try {
            // Execute outbound HTTP POST call via RestClient HTTP template
            return restClient.post()
                    .uri(paystackBaseUrl + "/customer")
                    .header("Authorization", "Bearer " + paystackSecretKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .accept(MediaType.APPLICATION_JSON)
                    .body(payload)
                    .retrieve()
                    // Handle client-side HTTP errors (4xx) without throwing an exception
                    .onStatus(HttpStatusCode::is4xxClientError, (request, response) -> {
                        log.warn("Paystack API client error response status: {} for user ID: {}",
                                response.getStatusCode(), sender.getUserId());
                    })
                    // Handle server-side HTTP errors (5xx) without throwing an exception
                    .onStatus(HttpStatusCode::is5xxServerError, (request, response) -> {
                        log.warn("Paystack API server error response status: {} for user ID: {}",
                                response.getStatusCode(), sender.getUserId());
                    })
                    .body(PaystackCustomerResponseDTO.class);

        } catch (Exception exception) {
            // Log failure and return null to initiate failover downstream
            log.error("Paystack customer creation failed for user ID {}: {}. Triggering failover eligibility.",
                    sender.getUserId(), exception.getMessage());
            return null;
        }
    }

//  CREATING A NEW RECIPIENT
    @Transactional
    public PaystackRecipientResponseDTO createRecipient(PaymentRequestDTO req) {

        final String type = resolveType(req.destination().countryCode());
        // Construct HTTP JSON Request Payload
        PaystackNewRecipientDTO payload = new PaystackNewRecipientDTO(
                type,
                req.recipient().fullName(),
                req.destination().accountIdentifier(),
                req.destination().channelCode(),
                req.destination().currencyCode()
        );

        log.info("Sending HTTP request to Paystack to create recipient for recipient: {}", req.recipient().fullName());

        try {
            // Execute outbound HTTP POST call via RestClient HTTP template
            return restClient.post()
                    .uri(paystackBaseUrl + "/transferrecipient")
                    .header("Authorization", "Bearer " + paystackSecretKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .accept(MediaType.APPLICATION_JSON)
                    .body(payload)
                    .retrieve()
                    // Handle client-side HTTP errors (4xx) without throwing an exception
                    .onStatus(HttpStatusCode::is4xxClientError, (request, response) -> {
                        log.warn("Paystack API client error response status: {} for recipient: {}",
                                response.getStatusCode(), req.recipient().fullName());
                    })
                    // Handle server-side HTTP errors (5xx) without throwing an exception
                    .onStatus(HttpStatusCode::is5xxServerError, (request, response) -> {
                        log.warn("Paystack API server error response status: {} for recipient: {}",
                                response.getStatusCode(), req.recipient().fullName());
                    })
                    .body(PaystackRecipientResponseDTO.class);

        } catch (Exception exception) {
            // Log failure and return null to initiate failover downstream
            log.error("Paystack recipient creation failed for recipient {}: {}. Triggering failover eligibility.",
                    req.recipient().fullName(), exception.getMessage());
            return null;
        }
    }

    String resolveType(String countryCode){
        return switch (countryCode == null ? "" : countryCode.toLowerCase()) {
            case "ng", "nga" -> "nuban";
            default -> "ghipss";
        };
    }
}
