package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.services;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.WalletToWalletRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.model.PaymentsUsersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.model.UsersWalletsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.repository.UserWalletsRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Service
@Transactional
@RequiredArgsConstructor
public class PaymentsServices {
    private final UserWalletsRepository userWalletsRepository;
    private final TransactionRepository transactionRepository;

    public PaymentsResponseDTO makePaymentToAppUser(@Valid WalletToWalletRequestDTO request) {
        // 1. Validate sender user existence
        PaymentsUsersModel sender = userWalletsRepository.existsByUserIdOrPhoneNumber(request.userId(), null, null);
        if (sender == null) {
            throw new RuntimeException("Sender not found");
        }

        // 2. Validate receiver user existence
        PaymentsUsersModel receiver = userWalletsRepository.existsByUserIdOrPhoneNumber(null, request.phoneNumber(), request.zentag());
        if (receiver == null) {
            throw new RuntimeException("Receiver not found");
        }

        // Prevent self-transfer
        if (sender.getUserId().equals(receiver.getUserId())) {
            throw new RuntimeException("Cannot transfer money to your own wallet");
        }

        // 3. Validate sender and receiver wallets existence for the specified currency
        UsersWalletsModel senderWallet = userWalletsRepository.getWalletByUserIdAndCurrencyCode(sender.getUserId(), request.currencyCode());
        if (senderWallet == null) {
            throw new RuntimeException("Sender wallet not found for currency: " + request.currencyCode());
        }

        UsersWalletsModel receiverWallet = userWalletsRepository.getWalletByUserIdAndCurrencyCode(receiver.getUserId(), request.currencyCode());
        if (receiverWallet == null) {
            throw new RuntimeException("Receiver wallet not found for currency: " + request.currencyCode());
        }

        // 4. Check if sender has enough balance
        if (senderWallet.getBalance().compareTo(request.amount()) < 0) {
            throw new RuntimeException("Insufficient balance");
        }

        // 5. Perform the balance deduction and credit operations atomically
        int debitResult = userWalletsRepository.debit(request.userId(), request.currencyCode(), request.amount());
        if (debitResult == 0) {
            throw new RuntimeException("Failed to debit sender wallet");
        }

        int creditResult = userWalletsRepository.credit(receiver.getUserId(), request.currencyCode(), request.amount());
        if (creditResult == 0) {
            throw new RuntimeException("Failed to credit receiver wallet");
        }

        // 6. Generate transaction details
        String transactionReference = "W2W-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        String gatewayName = "ZentraPayInternal";
        BigDecimal fee = BigDecimal.ZERO;
        BigDecimal totalCharged = request.amount().add(fee);
        String status = "SUCCESSFUL";
        String paymentChannel = "WALLET_TRANSFER";
        Instant now = Instant.now();

        // 7. Save transaction log to the database with sender and receiver tracking
        TransactionModel transaction = new TransactionModel();
        transaction.setSenderId(sender.getUserId());
        transaction.setReceiverId(receiver.getUserId());
        transaction.setSenderWalletId(senderWallet.getWalletId());
        transaction.setReceiverId(receiverWallet.getWalletId());
        transaction.setGatewayAccountId(gatewayName);
        transaction.setAmount(request.amount());
        transaction.setCurrencyCode(request.currencyCode());
        transaction.setFeeAmount(fee);
        transaction.setStatus(status);
        transaction.setReferenceCode(transactionReference);
        transaction.setMetaData(paymentChannel);

        transactionRepository.save(transaction);

        // 8. Return the immutable response DTO matching the record constructor order
        return new PaymentsResponseDTO(
                transactionReference,
                gatewayName,
                request.amount(),
                request.currencyCode(),
                fee,
                totalCharged,
                status,
                paymentChannel,
                null,
                null,
                now
        );
    }
}