package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.services;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.gateway.PaymentGatewayFactory;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.paystack.PaystackService;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dto.TransactionResponseDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

@Service
@Transactional
@RequiredArgsConstructor
public class PaymentsServices {

    private static final Logger log = LoggerFactory.getLogger(PaymentsServices.class);
    private static final BigDecimal LARGE_TRANSFER_RATIO = new BigDecimal("0.5");

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final FraudAlertRepository fraudAlertRepository;
    private final PaymentChannelRepository paymentChannelRepository;
    private final PaymentGatewayFactory paymentGatewayFactory;
    private final PaystackService paystackService;
    private final PasswordEncoder passwordEncoder;
    private final ObjectMapper objectMapper;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    public TransactionResponseDTO makeInternalPayment(UUID senderId, @Valid InternalPaymentRequestDTO request) {
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found"));
        verifyPin(sender, request.pin());

        String phoneNumber = request.recipientDetails().phoneNumber();
        String zentag = request.recipientDetails().zentag();
        if ((phoneNumber == null || phoneNumber.isBlank()) && (zentag == null || zentag.isBlank())) {
            throw new RuntimeException("Receiver identifier missing: provide phoneNumber or zentag");
        }

        User receiver = (zentag != null && !zentag.isBlank()
                ? userRepository.findByZentag(zentag)
                : userRepository.findByPhoneNumber(phoneNumber))
                .orElseThrow(() -> new RuntimeException("Receiver not found"));

        if (sender.getUserId().equals(receiver.getUserId())) {
            throw new RuntimeException("Cannot transfer money to your own wallet");
        }

        String currencyCode = request.amountDetails().currencyCode();
        Wallet senderWallet = walletRepository.findByUserIdAndCurrencyCode(sender.getUserId(), currencyCode)
                .orElseThrow(() -> new RuntimeException("Sender wallet not found for currency: " + currencyCode));
        Wallet receiverWallet = walletRepository.findByUserIdAndCurrencyCode(receiver.getUserId(), currencyCode)
                .orElseThrow(() -> new RuntimeException("Receiver wallet not found for currency: " + currencyCode));

        BigDecimal balanceBeforeDebit = senderWallet.getBalance();
        int debited = walletRepository.debit(senderWallet.getWalletId(), request.amountDetails().amount());
        if (debited == 0) {
            throw new RuntimeException("Insufficient balance");
        }

        int credited = walletRepository.credit(receiverWallet.getWalletId(), request.amountDetails().amount());
        if (credited == 0) {
            walletRepository.credit(senderWallet.getWalletId(), request.amountDetails().amount());
            throw new RuntimeException("Failed to credit receiver wallet - transfer reversed");
        }

        String counterpartyIdentifier = zentag != null && !zentag.isBlank() ? zentag : phoneNumber;

        Transaction transaction = new Transaction();
        transaction.setUserId(sender.getUserId());
        transaction.setWalletId(senderWallet.getWalletId());
        transaction.setTypeCode("TRANSFER_INTERNAL");
        transaction.setAmount(request.amountDetails().amount());
        transaction.setCurrencyCode(currencyCode);
        transaction.setStatus("SUCCESS");
        transaction.setGateway("ZentraPayInternal");
        transaction.setReference("INT-" + UUID.randomUUID());
        transaction.setCounterpartyUserId(receiver.getUserId());
        transaction.setCounterpartyName(receiver.getFullName());
        transaction.setCounterpartyIdentifier(counterpartyIdentifier);
        transaction.setDescription("Transfer to " + receiver.getFullName());
        transaction = transactionRepository.save(transaction);

        flagIfAnomalous(sender.getUserId(), request.amountDetails().amount(), balanceBeforeDebit, receiver.getUserId(), transaction.getTransactionId());

        log.info("[PAYMENT_SERVICE] Internal transfer successful: ref={}, sender={}, receiver={}, amount={} {}",
                transaction.getReference(), sender.getUserId(), receiver.getUserId(), request.amountDetails().amount(), currencyCode);

        return TransactionResponseDTO.from(transaction);
    }

    public TransactionResponseDTO makeBankTransfer(UUID senderId, @Valid ExternalPaymentRequestDTO request) {
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found"));
        verifyPin(sender, request.pin());

        ExternalRecipientDTO recipient = request.recipientDetails();
        ExternalAmountDTO amountDetails = request.amountDetails();

        String currencyCode = amountDetails.currencyCode();
        Wallet senderWallet = walletRepository.findByUserIdAndCurrencyCode(sender.getUserId(), currencyCode)
                .orElseThrow(() -> new RuntimeException("Sender wallet not found for currency: " + currencyCode));

        BigDecimal balanceBeforeDebit = senderWallet.getBalance();
        int debited = walletRepository.debit(senderWallet.getWalletId(), amountDetails.amount());
        if (debited == 0) {
            throw new RuntimeException("Insufficient balance");
        }

        Optional<PaymentChannel> channel = paymentChannelRepository.findById(recipient.channelCode());
        boolean isInternational = channel.map(c -> !c.getCountryCode().equalsIgnoreCase(sender.getCountryCode())).orElse(false);
        String destinationType = channel.map(PaymentChannel::getChannelType).orElse("BANK");
        String reference = "EXT-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        RecipientRequestDetailsDTO gatewayRecipient = new RecipientRequestDetailsDTO(
                recipient.recipientName(),
                recipient.accountNumber(),
                recipient.channelCode(),
                channel.map(PaymentChannel::getChannelName).orElse(null),
                channel.map(PaymentChannel::getCountryCode).orElse(sender.getCountryCode()),
                sender.getEmail()
        );

        PaymentRequestDetailsDTO paymentDetails = new PaymentRequestDetailsDTO(
                amountDetails.amount(), currencyCode, currencyCode, isInternational, destinationType,
                amountDetails.description() != null ? amountDetails.description() : "ZentraPay Bank Transfer", reference
        );

        DisbursementRequestDTO gatewayRequest = new DisbursementRequestDTO(
                sender.getUserId(), sender.getEmail(), request.pin(), gatewayRecipient, paymentDetails);

        PaymentsResponseDTO gatewayResponse;
        try {
            gatewayResponse = paymentGatewayFactory.processDisbursement(gatewayRequest);
        } catch (Exception e) {
            walletRepository.credit(senderWallet.getWalletId(), amountDetails.amount());
            log.error("[PAYMENT_SERVICE] All gateways failed, re-crediting sender: userId={}, error={}", senderId, e.getMessage());
            throw new RuntimeException("Bank transfer failed: " + e.getMessage());
        }

        String effectiveReference = gatewayResponse.transactionReference() != null ? gatewayResponse.transactionReference() : reference;
        String actualGatewayName = gatewayResponse.gatewayName() != null
                ? gatewayResponse.gatewayName()
                : paymentGatewayFactory.getPrimaryGatewayName(isInternational, currencyCode);

        Transaction transaction = new Transaction();
        transaction.setUserId(sender.getUserId());
        transaction.setWalletId(senderWallet.getWalletId());
        transaction.setTypeCode("TRANSFER_EXTERNAL");
        transaction.setAmount(amountDetails.amount());
        transaction.setCurrencyCode(currencyCode);
        transaction.setStatus(gatewayResponse.status() != null ? gatewayResponse.status() : "PENDING");
        transaction.setGateway(actualGatewayName);
        transaction.setReference(effectiveReference);
        transaction.setCounterpartyName(recipient.recipientName());
        transaction.setCounterpartyIdentifier(recipient.accountNumber());
        transaction.setDescription(paymentDetails.narration());
        transaction = transactionRepository.save(transaction);

        flagIfAnomalous(sender.getUserId(), amountDetails.amount(), balanceBeforeDebit, null, transaction.getTransactionId());

        log.info("[PAYMENT_SERVICE] Bank transfer processed: ref={}, status={}, gateway={}",
                effectiveReference, transaction.getStatus(), actualGatewayName);

        return TransactionResponseDTO.from(transaction);
    }

    public TransactionResponseDTO makeMobileMoneyTransfer(UUID senderId, @Valid ExternalPaymentRequestDTO request) {
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found"));
        verifyPin(sender, request.pin());

        ExternalRecipientDTO recipient = request.recipientDetails();
        ExternalAmountDTO amountDetails = request.amountDetails();

        String currencyCode = amountDetails.currencyCode();
        Wallet senderWallet = walletRepository.findByUserIdAndCurrencyCode(sender.getUserId(), currencyCode)
                .orElseThrow(() -> new RuntimeException("Sender wallet not found for currency: " + currencyCode));

        BigDecimal balanceBeforeDebit = senderWallet.getBalance();
        int debited = walletRepository.debit(senderWallet.getWalletId(), amountDetails.amount());
        if (debited == 0) {
            throw new RuntimeException("Insufficient balance");
        }

        Optional<PaymentChannel> channel = paymentChannelRepository.findById(recipient.channelCode());
        boolean isInternational = channel.map(c -> !c.getCountryCode().equalsIgnoreCase(sender.getCountryCode())).orElse(false);
        String reference = "MM-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        RecipientRequestDetailsDTO gatewayRecipient = new RecipientRequestDetailsDTO(
                recipient.recipientName(), recipient.accountNumber(), recipient.channelCode(),
                channel.map(PaymentChannel::getChannelName).orElse(null),
                channel.map(PaymentChannel::getCountryCode).orElse(sender.getCountryCode()),
                sender.getEmail()
        );

        PaymentRequestDetailsDTO paymentDetails = new PaymentRequestDetailsDTO(
                amountDetails.amount(), currencyCode, currencyCode, isInternational, "MOBILE_MONEY",
                amountDetails.description() != null ? amountDetails.description() : "ZentraPay Mobile Money Transfer", reference
        );

        DisbursementRequestDTO gatewayRequest = new DisbursementRequestDTO(
                sender.getUserId(), sender.getEmail(), request.pin(), gatewayRecipient, paymentDetails);

        PaymentsResponseDTO gatewayResponse;
        try {
            gatewayResponse = paymentGatewayFactory.processDisbursement(gatewayRequest);
        } catch (Exception e) {
            walletRepository.credit(senderWallet.getWalletId(), amountDetails.amount());
            log.error("[PAYMENT_SERVICE] Mobile money transfer failed, re-crediting sender: userId={}, error={}",
                    senderId, e.getMessage());
            throw new RuntimeException("Mobile money transfer failed: " + e.getMessage());
        }

        String effectiveReference = gatewayResponse.transactionReference() != null ? gatewayResponse.transactionReference() : reference;
        String actualGatewayName = gatewayResponse.gatewayName() != null
                ? gatewayResponse.gatewayName()
                : paymentGatewayFactory.getPrimaryGatewayName(isInternational, currencyCode);

        Transaction transaction = new Transaction();
        transaction.setUserId(sender.getUserId());
        transaction.setWalletId(senderWallet.getWalletId());
        transaction.setTypeCode("TRANSFER_MOBILE_MONEY");
        transaction.setAmount(amountDetails.amount());
        transaction.setCurrencyCode(currencyCode);
        transaction.setStatus(gatewayResponse.status() != null ? gatewayResponse.status() : "PENDING");
        transaction.setGateway(actualGatewayName);
        transaction.setReference(effectiveReference);
        transaction.setCounterpartyName(recipient.recipientName());
        transaction.setCounterpartyIdentifier(recipient.accountNumber());
        transaction.setDescription(paymentDetails.narration());
        transaction = transactionRepository.save(transaction);

        flagIfAnomalous(sender.getUserId(), amountDetails.amount(), balanceBeforeDebit, null, transaction.getTransactionId());

        log.info("[PAYMENT_SERVICE] Mobile money transfer processed: ref={}, status={}, gateway={}",
                effectiveReference, transaction.getStatus(), actualGatewayName);

        return TransactionResponseDTO.from(transaction);
    }

    public TransactionResponseDTO makeExternalPayment(UUID senderId, @Valid ExternalPaymentRequestDTO request) {
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found"));
        verifyPin(sender, request.pin());

        ExternalRecipientDTO recipient = request.recipientDetails();
        ExternalAmountDTO amountDetails = request.amountDetails();

        String currencyCode = amountDetails.currencyCode();
        Wallet senderWallet = walletRepository.findByUserIdAndCurrencyCode(sender.getUserId(), currencyCode)
                .orElseThrow(() -> new RuntimeException("Sender wallet not found for currency: " + currencyCode));

        BigDecimal balanceBeforeDebit = senderWallet.getBalance();
        int debited = walletRepository.debit(senderWallet.getWalletId(), amountDetails.amount());
        if (debited == 0) {
            throw new RuntimeException("Insufficient balance");
        }

        RecipientRequestDetailsDTO gatewayRecipient = new RecipientRequestDetailsDTO(
                recipient.recipientName(), recipient.accountNumber(), recipient.channelCode(),
                null, sender.getCountryCode(), sender.getEmail()
        );

        String reference = "EXT-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        PaymentRequestDetailsDTO paymentDetails = new PaymentRequestDetailsDTO(
                amountDetails.amount(), currencyCode, currencyCode, false, "EXTERNAL_PROVIDER",
                amountDetails.description() != null ? amountDetails.description() : "ZentraPay External Payment", reference
        );

        DisbursementRequestDTO gatewayRequest = new DisbursementRequestDTO(
                sender.getUserId(), sender.getEmail(), request.pin(), gatewayRecipient, paymentDetails);

        PaymentsResponseDTO gatewayResponse;
        try {
            gatewayResponse = paymentGatewayFactory.processDisbursement(gatewayRequest);
        } catch (Exception e) {
            walletRepository.credit(senderWallet.getWalletId(), amountDetails.amount());
            log.error("[PAYMENT_SERVICE] External payment failed, re-crediting sender: userId={}, error={}", senderId, e.getMessage());
            throw new RuntimeException("External payment failed: " + e.getMessage());
        }

        String effectiveReference = gatewayResponse.transactionReference() != null ? gatewayResponse.transactionReference() : reference;
        String actualGatewayName = gatewayResponse.gatewayName() != null
                ? gatewayResponse.gatewayName()
                : paymentGatewayFactory.getPrimaryGatewayName(false, currencyCode);

        Transaction transaction = new Transaction();
        transaction.setUserId(sender.getUserId());
        transaction.setWalletId(senderWallet.getWalletId());
        transaction.setTypeCode("TRANSFER_EXTERNAL");
        transaction.setAmount(amountDetails.amount());
        transaction.setCurrencyCode(currencyCode);
        transaction.setStatus(gatewayResponse.status() != null ? gatewayResponse.status() : "PENDING");
        transaction.setGateway(actualGatewayName);
        transaction.setReference(effectiveReference);
        transaction.setCounterpartyName(recipient.recipientName());
        transaction.setCounterpartyIdentifier(recipient.accountNumber());
        transaction.setDescription("External payment to " + recipient.recipientName());
        transaction = transactionRepository.save(transaction);

        flagIfAnomalous(sender.getUserId(), amountDetails.amount(), balanceBeforeDebit, null, transaction.getTransactionId());

        log.info("[PAYMENT_SERVICE] External payment processed: ref={}, status={}", effectiveReference, transaction.getStatus());

        return TransactionResponseDTO.from(transaction);
    }

    public PaystackAccessCodeResponseDTO getPaystackAccessCode(UUID userId, BigDecimal amount, String currencyCode) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Wallet wallet = walletRepository.findByUserIdAndCurrencyCode(userId, currencyCode)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No wallet in currency " + currencyCode + " — create one via POST /api/wallets/fiat first"));

        String reference = "FUND-" + UUID.randomUUID().toString().substring(0, 12).toUpperCase();
        PaystackAccessCodeResponseDTO accessCode = paystackService.initializeTransaction(user.getEmail(), amount, currencyCode, reference);

        Transaction transaction = new Transaction();
        transaction.setUserId(userId);
        transaction.setWalletId(wallet.getWalletId());
        transaction.setTypeCode("WALLET_FUNDING");
        transaction.setAmount(amount);
        transaction.setCurrencyCode(currencyCode);
        transaction.setStatus("PENDING");
        transaction.setGateway("Paystack");
        transaction.setReference(accessCode.reference() != null ? accessCode.reference() : reference);
        transaction.setDescription("Wallet funding via Paystack");
        transactionRepository.save(transaction);

        log.info("[PAYMENT_SERVICE] Paystack access code issued: ref={}, userId={}, amount={} {}",
                transaction.getReference(), userId, amount, currencyCode);

        return accessCode;
    }

    public void handlePaystackWebhook(String rawBody, String signatureHeader) {
        if (!paystackService.verifyWebhookSignature(rawBody, signatureHeader)) {
            log.warn("[PAYMENT_SERVICE] Rejected Paystack webhook: invalid signature");
            throw new SecurityException("Invalid Paystack webhook signature");
        }

        JsonNode root;
        try {
            root = objectMapper.readTree(rawBody);
        } catch (Exception e) {
            log.error("[PAYMENT_SERVICE] Could not parse Paystack webhook payload: {}", e.getMessage());
            throw new RuntimeException("Malformed webhook payload");
        }

        String event = root.path("event").asText(null);
        JsonNode data = root.path("data");
        String reference = data.path("reference").asText(null);
        String paystackStatus = data.path("status").asText(null);

        if (reference == null) {
            log.warn("[PAYMENT_SERVICE] Paystack webhook missing reference, ignoring: event={}", event);
            return;
        }

        Optional<Transaction> maybeTransaction = transactionRepository.findByReference(reference);
        if (maybeTransaction.isEmpty()) {
            log.warn("[PAYMENT_SERVICE] Paystack webhook for unknown reference={}, ignoring", reference);
            return;
        }

        Transaction transaction = maybeTransaction.get();
        if (!"PENDING".equals(transaction.getStatus())) {
            log.info("[PAYMENT_SERVICE] Paystack webhook for already-settled transaction ref={}, status={}, ignoring",
                    reference, transaction.getStatus());
            return;
        }

        boolean success = "charge.success".equals(event) || "success".equalsIgnoreCase(paystackStatus);
        if (success) {
            transaction.setStatus("SUCCESS");
            if (transaction.getWalletId() != null) {
                walletRepository.credit(transaction.getWalletId(), transaction.getAmount());
            }
            log.info("[PAYMENT_SERVICE] Paystack webhook: wallet funding succeeded, ref={}", reference);
        } else {
            transaction.setStatus("FAILED");
            transaction.setFailureReason(paystackStatus != null ? paystackStatus : event);
            log.info("[PAYMENT_SERVICE] Paystack webhook: wallet funding failed, ref={}, status={}", reference, paystackStatus);
        }
        transactionRepository.save(transaction);
    }

    private void verifyPin(User user, String pin) {
        if (!passwordEncoder.matches(pin + pinPepper, user.getTransactionPinHash())) {
            throw new RuntimeException("Wrong PIN");
        }
    }

    private void flagIfAnomalous(UUID senderId, BigDecimal amount, BigDecimal balanceBeforeDebit,
                                 UUID counterpartyUserId, UUID relatedTransactionId) {
        if (balanceBeforeDebit != null && balanceBeforeDebit.compareTo(BigDecimal.ZERO) > 0
                && amount.compareTo(balanceBeforeDebit.multiply(LARGE_TRANSFER_RATIO)) > 0) {
            saveFraudAlert(senderId, "LARGE_TRANSFER",
                    "Transfer of " + amount + " is over half of the pre-transfer wallet balance (" + balanceBeforeDebit + ")",
                    "MEDIUM", relatedTransactionId);
        }

        if (counterpartyUserId != null) {
            boolean seenBefore = transactionRepository.findByUserIdOrderByCreatedAtDesc(senderId).stream()
                    .anyMatch(t -> counterpartyUserId.equals(t.getCounterpartyUserId())
                            && !t.getTransactionId().equals(relatedTransactionId));
            if (!seenBefore) {
                saveFraudAlert(senderId, "NEW_RECIPIENT",
                        "First transfer to this recipient", "LOW", relatedTransactionId);
            }
        }
    }

    private void saveFraudAlert(UUID userId, String alertType, String message, String severity, UUID relatedTransactionId) {
        FraudAlert alert = new FraudAlert();
        alert.setUserId(userId);
        alert.setAlertType(alertType);
        alert.setMessage(message);
        alert.setSeverity(severity);
        alert.setRelatedTransactionId(relatedTransactionId);
        fraudAlertRepository.save(alert);
        log.info("[PAYMENT_SERVICE] Fraud alert raised: userId={}, type={}, severity={}", userId, alertType, severity);
    }
}