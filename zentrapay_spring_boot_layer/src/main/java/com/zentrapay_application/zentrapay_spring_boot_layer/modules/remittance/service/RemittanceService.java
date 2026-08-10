package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FraudAlert;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Transaction;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.User;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Wallet;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FraudAlertRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.WalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.service.ConverterService;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.DisbursementRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentRequestDetailsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.RecipientRequestDetailsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.gateway.PaymentGatewayFactory;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.dtos.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.model.Remittance;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.repository.RemittanceRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.UUID;

/**
 * ZRemit: instant cross-border transfers with real FX quotes (via {@link ConverterService},
 * backed by the {@code exchange_rates} table) — API_CONTRACT.md §12.
 *
 * Now integrated with {@link PaymentGatewayFactory} for actual external transfer execution.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class RemittanceService {

    private static final Logger log = LoggerFactory.getLogger(RemittanceService.class);

    private static final BigDecimal FEE_RATE = new BigDecimal("0.015");
    private static final BigDecimal FEE_FLOOR = BigDecimal.ONE;
    private static final BigDecimal LARGE_AMOUNT_THRESHOLD = new BigDecimal("5000");

    private final RemittanceRepository remittanceRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final FraudAlertRepository fraudAlertRepository;
    private final ConverterService converterService;
    private final PaymentGatewayFactory paymentGatewayFactory;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    public SendResponseDTO send(UUID senderId, SendRequestDTO request) {
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (!passwordEncoder.matches(request.pin() + pinPepper, sender.getTransactionPinHash())) {
            throw new IllegalArgumentException("Invalid PIN");
        }

        RemittanceRecipientDTO recipient = request.recipientDetails();
        RemittanceAmountDTO amount = request.amountDetails();

        Wallet wallet = walletRepository.findByUserIdAndCurrencyCode(senderId, amount.sourceCurrencyCode())
                .orElseThrow(() -> new ResourceNotFoundException("No wallet found for currency " + amount.sourceCurrencyCode()));

        BigDecimal fee = amount.amount().multiply(FEE_RATE).setScale(2, RoundingMode.HALF_UP).max(FEE_FLOOR);
        BigDecimal totalDebit = amount.amount().add(fee);

        if (wallet.getBalance().compareTo(totalDebit) < 0) {
            throw new IllegalStateException("Insufficient balance to cover amount plus fee");
        }

        BigDecimal exchangeRate = converterService.getRate(amount.sourceCurrencyCode(), amount.destinationCurrencyCode());

        int debited = walletRepository.debit(wallet.getWalletId(), totalDebit);
        if (debited == 0) {
            throw new IllegalStateException("Insufficient balance to cover amount plus fee");
        }

        // Build gateway request for external transfer
        RecipientRequestDetailsDTO gatewayRecipient = new RecipientRequestDetailsDTO(
                recipient.recipientName(),
                recipient.recipientPhoneNumber(),
                amount.channel(),
                null,
                recipient.recipientCountryCode(),
                sender.getEmail()
        );

        String reference = "REM-" + UUID.randomUUID().toString().substring(0, 12).toUpperCase();
        PaymentRequestDetailsDTO paymentDetails = new PaymentRequestDetailsDTO(
                amount.amount(),
                amount.sourceCurrencyCode(),
                amount.destinationCurrencyCode(),
                true,
                "REMITTANCE",
                "Remittance to " + recipient.recipientName(),
                reference
        );

        DisbursementRequestDTO gatewayRequest = new DisbursementRequestDTO(
                senderId, sender.getEmail(), request.pin(), gatewayRecipient, paymentDetails);

        PaymentsResponseDTO gatewayResponse;
        try {
            gatewayResponse = paymentGatewayFactory.processDisbursement(gatewayRequest);
        } catch (Exception e) {
            walletRepository.credit(wallet.getWalletId(), totalDebit);
            log.error("[REMITTANCE] Gateway failed, re-crediting sender: userId={}, error={}", senderId, e.getMessage());
            throw new RuntimeException("Remittance failed: " + e.getMessage());
        }

        String effectiveReference = gatewayResponse.transactionReference() != null ? gatewayResponse.transactionReference() : reference;
        String actualGatewayName = gatewayResponse.gatewayName() != null
                ? gatewayResponse.gatewayName()
                : paymentGatewayFactory.getPrimaryGatewayName(true, amount.sourceCurrencyCode());

        Transaction transaction = new Transaction();
        transaction.setUserId(senderId);
        transaction.setWalletId(wallet.getWalletId());
        transaction.setTypeCode("REMITTANCE_SEND");
        transaction.setAmount(totalDebit);
        transaction.setCurrencyCode(amount.sourceCurrencyCode());
        transaction.setStatus(gatewayResponse.status() != null ? gatewayResponse.status() : "PENDING");
        transaction.setGateway(actualGatewayName);
        transaction.setReference(effectiveReference);
        transaction.setCounterpartyUserId(recipient.recipientUserId());
        transaction.setCounterpartyName(recipient.recipientName());
        transaction.setCounterpartyIdentifier(recipient.recipientPhoneNumber());
        transaction.setDescription("Remittance to " + recipient.recipientName() + " (" + recipient.recipientCountryCode() + ")");
        transaction = transactionRepository.save(transaction);

        Remittance remittance = new Remittance();
        remittance.setSenderId(senderId);
        remittance.setReceiverId(recipient.recipientUserId());
        remittance.setTransactionId(transaction.getTransactionId());
        remittance.setAmount(amount.amount());
        remittance.setSourceCurrencyCode(amount.sourceCurrencyCode());
        remittance.setDestinationCurrencyCode(amount.destinationCurrencyCode());
        remittance.setExchangeRate(exchangeRate);
        remittance.setFee(fee);
        remittance.setStatus(transaction.getStatus());
        remittance.setChannel(amount.channel());
        remittance.setRecipientName(recipient.recipientName());
        remittance.setRecipientPhoneNumber(recipient.recipientPhoneNumber());
        remittance.setRecipientCountryCode(recipient.recipientCountryCode());
        remittance.setReference(effectiveReference);
        remittance = remittanceRepository.save(remittance);

        flagIfSuspicious(senderId, request);

        log.info("[REMITTANCE] Remittance processed: ref={}, status={}, gateway={}, amount={} {}",
                effectiveReference, transaction.getStatus(), actualGatewayName, amount.amount(), amount.sourceCurrencyCode());

        return new SendResponseDTO(
                new RemittanceSummaryDTO(remittance.getRemittanceId(), remittance.getStatus(), exchangeRate, fee),
                toTransactionDTO(transaction));
    }

    @Transactional(readOnly = true)
    public List<RemittanceHistoryDTO> history(UUID senderId) {
        return remittanceRepository.findBySenderIdOrderByCreatedAtDesc(senderId).stream()
                .map(r -> new RemittanceHistoryDTO(r.getRemittanceId(), r.getAmount(), r.getSourceCurrencyCode(),
                        r.getDestinationCurrencyCode(), r.getRecipientName(), r.getStatus(), r.getCreatedAt()))
                .toList();
    }

    @Transactional(readOnly = true)
    public RemittanceRatesResponseDTO rates(String source, String destination) {
        BigDecimal rate = converterService.getRate(source, destination);
        return new RemittanceRatesResponseDTO(rate, FEE_FLOOR);
    }

    private void flagIfSuspicious(UUID senderId, SendRequestDTO request) {
        RemittanceRecipientDTO recipient = request.recipientDetails();
        RemittanceAmountDTO amount = request.amountDetails();

        boolean isLarge = amount.amount().compareTo(LARGE_AMOUNT_THRESHOLD) >= 0;
        boolean isNewRecipient = recipient.recipientPhoneNumber() != null
                && !remittanceRepository.existsBySenderIdAndRecipientPhoneNumber(senderId, recipient.recipientPhoneNumber());

        if (!isLarge && !isNewRecipient) {
            return;
        }

        FraudAlert alert = new FraudAlert();
        alert.setUserId(senderId);
        alert.setAlertType("REMITTANCE_ANOMALY");
        alert.setSeverity(isLarge ? "HIGH" : "MEDIUM");
        String reason = isLarge && isNewRecipient
                ? "Large remittance to a new recipient"
                : isLarge ? "Unusually large remittance amount" : "First-time remittance recipient";
        alert.setMessage(reason + ": " + amount.amount() + " " + amount.sourceCurrencyCode()
                + " to " + recipient.recipientName());
        fraudAlertRepository.save(alert);
        log.info("[REMITTANCE] Fraud alert raised for sender={}: {}", senderId, reason);
    }

    private TransactionDTO toTransactionDTO(Transaction t) {
        return new TransactionDTO(
                t.getTransactionId(), t.getTypeCode(), t.getAmount(), t.getCurrencyCode(), t.getStatus(),
                t.getGateway(), t.getReference(), t.getCounterpartyName(), t.getCounterpartyIdentifier(),
                t.getDescription(), t.getCreatedAt());
    }
}