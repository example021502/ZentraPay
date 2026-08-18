package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatAccountModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatWalletModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FiatAccountRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FiatWalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NonNull;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PaymentsService {

    // Comment: Define transaction type constants
    private static final String TYPE_DEBIT = "debit";
    private static final String TYPE_CREDIT = "credit";

    // Comment: Inject necessary repositories and security components
    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final TransactionRepository transactionRepository;
    private final PasswordEncoder passwordEncoder;

    // Comment: Inject primary and secondary gateway properties
    @Value("${zentrapay.primary-national-gateway}")
    private String primary_national_gateway;

    @Value("${zentrapay.primary-international-gateway}")
    private String primary_cross_border_gateway;

    @Value("${zentrapay.secondary-gateway}")
    private String secondary_gateway;

    @Value("${zentrapay.id}")
    private String zentrapay_id;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    @Value("${paystack.secret-key}")
    private String paystackSecretKey;

    @Value("${paystack.base-url}")
    private String paystackBaseUrl;

    @Value("${onafriq.base-url}")
    private String onafriqBaseUrl;

    @Value("${onafriq.secret-key}")
    private String onafriqSecretKey;

    @Value("${flutterwave.secret-key}")
    private String flutterwaveSecretKey;

    @Value("${flutterwave.base-url}")
    private String flutterwaveBaseUrl;

    // Comment: Initialize RestClient for HTTP calls
    private final RestClient restClient = RestClient.create();

    @Transactional
    public Optional<TransactionDTO> sendMoney(UUID userId, @Valid PaymentRequestDTO req) {

        // Comment: Fetch sender user entity from database
        UserModel sender = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        // Comment: Validate the user transaction PIN against stored hash
        if (!passwordEncoder.matches(req.pin() + pinPepper, sender.getTransactionPinHash())) {
            throw new IllegalArgumentException("Invalid PIN");
        }

        // Comment: Check if transaction destination country matches the sender's country
        if (req.destination().countryCode().equalsIgnoreCase(sender.getCountryCode())) {

            // Comment: Process internal ZentraPay wallet transfers
            if (req.destination().sourceType().equalsIgnoreCase("zentrapay-wallet")) {

                final UserModel receiver = userRepository.findByEmailOrPhoneNumber(req.recipient().email(), req.recipient().phoneNumber())
                        .orElseThrow(() -> new ResourceNotFoundException("Recipient Not Found!"));

                if (!req.recipient().email().equalsIgnoreCase(receiver.getEmail()) || !req.recipient().phoneNumber().equalsIgnoreCase(receiver.getPhoneNumber())) {
                    throw new IllegalArgumentException("Receiver can not be resolved. Please cross check the receiver details.");
                }

                if (req.recipient().userType().equalsIgnoreCase("app-user")) {
                    if (!req.transfer().currencyType().equalsIgnoreCase("crypto")) {

                        final FiatWalletModel receiverWallet = fiatWalletRepository.findByUserId(receiver.getUserId())
                                .orElseThrow(() -> new ResourceNotFoundException("Receiver wallet missing"));

                        final FiatAccountModel receiverAccount = fiatAccountRepository.findByWalletIdAndCurrencyCode(receiverWallet.getWalletId(), req.destination().currencyCode())
                                .orElseThrow(() -> new ResourceNotFoundException("Receiver does not have an account for " + req.destination().currencyCode() + "."));

                        if (!receiverAccount.getStatus().equalsIgnoreCase("active")) {
                            throw new IllegalArgumentException("Receiver account is not active.");
                        }

                        final FiatWalletModel senderWallet = fiatWalletRepository.findByUserId(sender.getUserId())
                                .orElseThrow(() -> new ResourceNotFoundException("You don't have an account yet. Please get in touch with our customer support team!"));

                        final FiatAccountModel senderAccount = fiatAccountRepository.findByWalletIdAndCurrencyCode(senderWallet.getWalletId(), req.destination().currencyCode())
                                .orElseThrow(() -> new ResourceNotFoundException("You do not have an account for " + req.destination().currencyCode() + " yet."));

                        if (!senderAccount.getStatus().equalsIgnoreCase("active")) {
                            throw new IllegalArgumentException("This account is not active, please choose another account");
                        }

                        int debited = fiatAccountRepository.debit(senderWallet.getWalletId(), req.transfer().amount(), req.destination().currencyCode());
                        if (debited == 0) {
                            throw new IllegalArgumentException("Insufficient balance");
                        }

                        fiatAccountRepository.credit(receiverWallet.getWalletId(), req.transfer().amount(), req.destination().currencyCode());

                        TransactionModel debitLeg = createDebitLeg(req, sender, receiver, zentrapay_id);
                        debitLeg = transactionRepository.save(debitLeg);

                        TransactionModel creditLeg = createCreditLeg(req, sender, receiver, zentrapay_id);
                        transactionRepository.save(creditLeg);

                        return toDTO(debitLeg);
                    } else {
                        // Comment: TODO: Add crypto transaction implementation
                    }
                }

            }
            // Comment: Process external Bank Payout via Gateway
            else if (req.destination().sourceType().equalsIgnoreCase("bank")) {

                final FiatWalletModel senderWallet = fiatWalletRepository.findByUserId(sender.getUserId())
                        .orElseThrow(() -> new ResourceNotFoundException("You don't have an account yet."));

                final FiatAccountModel senderAccount = fiatAccountRepository.findByWalletIdAndCurrencyCode(senderWallet.getWalletId(), req.destination().currencyCode())
                        .orElseThrow(() -> new ResourceNotFoundException("You do not have an account for " + req.destination().currencyCode() + "."));

                if (!senderAccount.getStatus().equalsIgnoreCase("active")) {
                    throw new IllegalArgumentException("Sender account is not active.");
                }

                // Comment: Debit sender account before triggering gateway request
                int debited = fiatAccountRepository.debit(senderWallet.getWalletId(), req.transfer().amount(), req.destination().currencyCode());
                if (debited == 0) {
                    throw new IllegalArgumentException("Insufficient balance");
                }

                try {
                    // Comment: Create customer on Paystack
                    GatewayCreateCustomerDTO customerPayload = new GatewayCreateCustomerDTO(
                            sender.getEmail(), sender.getFirstName(), sender.getLastName(), sender.getPhoneNumber()
                    );

                   final PaystackCustomerResponseDTO customerResponse = restClient.post()
                            .uri(paystackBaseUrl + "/customer")
                            .header("Authorization", "Bearer " + paystackSecretKey)
                            .header("Content-Type", "application/json")
                            .body(customerPayload)
                            .retrieve()
                            .body(PaystackCustomerResponseDTO.class);

                    // Comment: Check if the response is null or if Paystack returned false status
                    if (customerResponse == null || !customerResponse.status()) {
                        String errorMessage = customerResponse != null ? customerResponse.message() : "Unknown error";
//                        CREATE A CUSTOMER IN FLUTTERWAVE
                        FlutterwaveCustomerResponseDTO response = restClient.post()
                                .uri(flutterwaveBaseUrl + "/customers")
                                .header("Authorization", "Bearer " + flutterwaveSecretKey)
                                .header("Content-Type", "application/json")
                                .body(customerPayload)
                                .retrieve()
                                .body(FlutterwaveCustomerResponseDTO.class);

// Comment: Validate the response status
                        if (response == null || !response.status()) {
                            throw new RuntimeException("Transaction Failed! try again");
                        }
                    }

                    // Comment: Initialize payment transaction on Paystack
                    PaymentInitRequestDTO requestPayload = new PaymentInitRequestDTO(
                            sender.getEmail(),
                            req.transfer().amount(),
                            req.transfer().currencyCode(),
                            req.transfer().referenceId(),
                            "https://zentrapay.com/payment/callback"
                    );

                    String response = restClient.post()
                            .uri(paystackBaseUrl + "/transaction/initialize")
                            .header("Authorization", "Bearer " + paystackSecretKey)
                            .header("Content-Type", "application/json")
                            .body(requestPayload)
                            .retrieve()
                            .body(String.class);

                    System.out.println("Paystack Response: " + response);

                    // Comment: Save bank payout transaction record using the reference ID
                    TransactionModel transaction = createBankOrMomoTransaction(req, sender, primary_national_gateway, req.transfer().referenceId(), "success");
                    transaction = transactionRepository.save(transaction);

                    return toDTO(transaction);

                } catch (Exception e) {
                    // Comment: Handle transaction failure and bubble exception
                    throw new RuntimeException("Bank payout failed: " + e.getMessage());
                }

            }
            // Comment: Process external Mobile Money Payout via Gateway
            else if (req.destination().sourceType().equalsIgnoreCase("mobile-money")) {

                final FiatWalletModel senderWallet = fiatWalletRepository.findByUserId(sender.getUserId())
                        .orElseThrow(() -> new ResourceNotFoundException("You don't have an account yet."));

                final FiatAccountModel senderAccount = fiatAccountRepository.findByWalletIdAndCurrencyCode(senderWallet.getWalletId(), req.destination().currencyCode())
                        .orElseThrow(() -> new ResourceNotFoundException("You do not have an account for " + req.destination().currencyCode() + "."));

                if (!senderAccount.getStatus().equalsIgnoreCase("active")) {
                    throw new IllegalArgumentException("Sender account is not active.");
                }

                // Comment: Debit sender account
                int debited = fiatAccountRepository.debit(senderWallet.getWalletId(), req.transfer().amount(), req.destination().currencyCode());
                if (debited == 0) {
                    throw new IllegalArgumentException("Insufficient balance");
                }

                try {
                    String externalReference = "MOMO_REF_" + UUID.randomUUID();

                    TransactionModel transaction = createBankOrMomoTransaction(req, sender, primary_national_gateway, externalReference, "success");
                    transaction = transactionRepository.save(transaction);

                    return toDTO(transaction);

                } catch (Exception e) {
                    throw new RuntimeException("Mobile money payout failed: " + e.getMessage());
                }

            } else {
                throw new IllegalArgumentException("Unsupported destination source type: " + req.destination().sourceType());
            }

        } else {
            // Comment: Throw exception for unsupported cross-border transfers
            throw new IllegalArgumentException("Cross-border transfers aren't supported yet — this recipient is in a different country");
        }

        // Comment: Fallback exception if execution escapes conditional logic
        throw new IllegalArgumentException("Something went wrong, transaction could not be processed");
    }

    private static @NonNull TransactionModel createCreditLeg(PaymentRequestDTO req, UserModel sender, UserModel receiver, String externalReference) {
        TransactionModel creditLeg = new TransactionModel();
        creditLeg.setInternalReferenceId(req.transfer().referenceId());
        creditLeg.setExternalReferenceId(externalReference);
        creditLeg.setSenderId(sender.getUserId());
        creditLeg.setReceiverId(receiver.getUserId());
        creditLeg.setSenderName(sender.getFirstName() + " " + sender.getLastName());
        creditLeg.setReceiverName(receiver.getFirstName() + " " + receiver.getLastName());
        creditLeg.setAmount(req.transfer().amount());
        creditLeg.setSourceCurrencyCode(req.transfer().currencyCode());
        creditLeg.setDestinationCurrencyCode(req.destination().currencyCode());
        creditLeg.setPurpose(req.transfer().purpose() == null || req.transfer().purpose().isBlank() ? "Sent to " + receiver.getFirstName() : req.transfer().purpose());
        creditLeg.setGateway("internal");
        creditLeg.setStatus("success");
        creditLeg.setTransactionType(TYPE_CREDIT);
        creditLeg.setSenderEmail(sender.getEmail());
        creditLeg.setSenderPhoneNumber(sender.getPhoneNumber());
        creditLeg.setReceiverEmail(receiver.getEmail());
        creditLeg.setReceiverPhoneNumber(receiver.getPhoneNumber());
        return creditLeg;
    }

    private static @NonNull TransactionModel createDebitLeg(PaymentRequestDTO req, UserModel sender, UserModel receiver, String externalReference) {
        TransactionModel debitLeg = new TransactionModel();
        debitLeg.setInternalReferenceId(req.transfer().referenceId());
        debitLeg.setExternalReferenceId(externalReference);
        debitLeg.setSenderId(sender.getUserId());
        debitLeg.setReceiverId(receiver.getUserId());
        debitLeg.setSenderName(sender.getFirstName() + " " + sender.getLastName());
        debitLeg.setReceiverName(receiver.getFirstName() + " " + receiver.getLastName());
        debitLeg.setAmount(req.transfer().amount());
        debitLeg.setSourceCurrencyCode(req.transfer().currencyCode());
        debitLeg.setDestinationCurrencyCode(req.destination().currencyCode());
        debitLeg.setPurpose(req.transfer().purpose() == null || req.transfer().purpose().isBlank() ? "Sent to " + receiver.getFirstName() : req.transfer().purpose());
        debitLeg.setGateway("internal");
        debitLeg.setStatus("success");
        debitLeg.setTransactionType(TYPE_DEBIT);
        debitLeg.setSenderEmail(sender.getEmail());
        debitLeg.setSenderPhoneNumber(sender.getPhoneNumber());
        debitLeg.setReceiverEmail(receiver.getEmail());
        debitLeg.setReceiverPhoneNumber(receiver.getPhoneNumber());
        return debitLeg;
    }

    private static @NonNull TransactionModel createBankOrMomoTransaction(PaymentRequestDTO req, UserModel sender, String gateway, String externalReference, String status) {
        TransactionModel tx = new TransactionModel();
        tx.setInternalReferenceId(req.transfer().referenceId());
        tx.setExternalReferenceId(externalReference);
        tx.setSenderId(sender.getUserId());
        tx.setReceiverId(null);
        tx.setSenderName(sender.getFirstName() + " " + sender.getLastName());
        tx.setReceiverName(req.recipient().fullName());
        tx.setAmount(req.transfer().amount());
        tx.setSourceCurrencyCode(req.transfer().currencyCode());
        tx.setDestinationCurrencyCode(req.destination().currencyCode());
        tx.setPurpose(req.transfer().purpose());
        tx.setGateway(gateway);
        tx.setStatus(status);
        tx.setTransactionType(TYPE_DEBIT);
        tx.setSenderEmail(sender.getEmail());
        tx.setSenderPhoneNumber(sender.getPhoneNumber());
        tx.setReceiverEmail(req.recipient().email());
        tx.setReceiverPhoneNumber(req.recipient().phoneNumber());
        return tx;
    }

    public static Optional<TransactionDTO> toDTO(TransactionModel t) {
        String sign = t.getTransactionType().equalsIgnoreCase("credit") ? "+" : "-";
        return Optional.of(new TransactionDTO(
                sign,
                t.getTransactionId(),
                t.getInternalReferenceId(),
                t.getExternalReferenceId(),
                t.getSenderId(),
                t.getReceiverId(),
                t.getSenderName(),
                t.getReceiverName(),
                t.getAmount(),
                t.getSourceCurrencyCode(),
                t.getDestinationCurrencyCode(),
                t.getPurpose(),
                t.getFailureReason(),
                t.getGateway(),
                t.getMetadata(),
                t.getStatus(),
                t.getTransactionType(),
                t.getSenderEmail(),
                t.getSenderPhoneNumber(),
                t.getReceiverEmail(),
                t.getReceiverPhoneNumber(),
                t.getCreatedAt(),
                t.getUpdatedAt()
        ));
    }
}