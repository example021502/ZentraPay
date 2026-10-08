package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dto.InitializePaymentRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dto.TransferDataDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.InitializePaymentResponseDTO;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Inbound customer checkout (wallet funding) — POST /api/payments/initialize.
 * <p>
 * Paystack is the primary national gateway, with Flutterwave as the
 * universal failover. Before initializing, the caller is provisioned at the
 * selected gateway (local-first: an existing {@code gateway_customers} row
 * is reused, otherwise one is registered and cached), mirroring the same
 * initiated checkout is journaled as a pending "credit" transaction so the
 * record exists before the gateway webhook confirms it.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentsInitializeService {

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final FlutterwaveClient flutterwaveClient;
    private final PaystackServices paystackServices;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final GatewayRepository gatewayRepository;
    private final GatewayCustomerReposittory gatewayCustomerReposittory;
    private final ObjectMapper objectMapper;
    private final LedgerOperations ledgerOperations;
    private final LedgerEntryRepository ledgerEntryRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${zentrapay.id}")
    String zentrapayId;
    @Value("${app.pin.pepper}")
    String pinPepper;

    //    Receiver information results
    public record _receiverInformation(UUID walletId, UUID userId, String email, String phoneNumber){};

@Transactional
    public InitializePaymentResponseDTO initialize(UUID userId, InitializePaymentRequestDTO req) {
        UserModel sender = userRepository.getUserByUserId(userId)
                .orElseThrow(()-> new ResourceNotFoundException("Sender not found!"));
        BigDecimal amount=req.transfer().amount();
        String currencyCode=req.transfer().currencyCode();
        String TXN_Ref=req.TXN_Ref();
        String senderName = sender.getFirstName() + " " + sender.getLastName();

        // Comment: Verify security PIN against stored hash with pepper
        if (!passwordEncoder.matches(req.pin() + pinPepper, sender.getTransactionPinHash())) {
            throw new IllegalArgumentException("Invalid PIN");
        }

        if(req.channelType().equals(Datatypes.TransactionType.INTERNAL))
        {
        String receiverName = req.appUser().name();
        String purpose = req.transfer().purpose().isBlank() ? "Default: Payment from" + senderName + "to" + receiverName : req.transfer().purpose();
                log.info("================= PAYMENT ===================");
                log.info("================= PROCESSING... ===================");
                if(req.appUser().phoneNumber().isBlank() && req.appUser().zentag().isBlank())
                    throw new RuntimeException("Phone number or zentag is required to process the transaction!");

                UUID walletId = fiatWalletRepository.getWalletIdByUserId(userId)
                        .orElseThrow(()-> new ResourceNotFoundException("Wallet not found"));
                FiatAccountModel account = fiatAccountRepository.getWalletByWalletIdAndCurrencyCode(walletId, currencyCode)
                        .orElseThrow(()-> new ResourceNotFoundException("Account not found"));
                if(amount.compareTo(account.getBalance()) > 0){
                    throw new RuntimeException("Insufficient funds! Please top up your account proceed");
                }
                int debitLeg = ledgerOperations.debit(walletId, amount, currencyCode);
                if(debitLeg==0)
                    throw new RuntimeException("Error!, Something went wrong! Please try again.");
                _receiverInformation receiver = _resolverReceiver(req.appUser().zentag(), req.appUser().phoneNumber());
                int creditLeg = ledgerOperations.credit(receiver.walletId(), amount, currencyCode);
                if(creditLeg==0)
                    throw new RuntimeException("Insufficient funds! Please top up your account proceed");
                String entryId = _generateEntryId();
//                SETTING THE TRANSACTION VALUES
                TransactionModel t = new TransactionModel();
                t.setEntryId(entryId);
                t.setInternalReferenceId(TXN_Ref);
                t.setExternalReferenceId(null);
                t.setAmount(amount);
                t.setSourceCurrencyCode(currencyCode);
                t.setDestinationCurrencyCode(currencyCode);
                t.setStatus(Datatypes.TransactionStatus.SUCCESS);
                t.setTransactionType(Datatypes.TransactionType.INTERNAL);
                t.setGateway(null);
                t.setSenderId(userId);
                t.setSenderName(senderName);
                t.setSenderEmail(sender.getEmail());
                t.setSenderPhoneNumber(sender.getPhoneNumber());
                t.setReceiverId(receiver.userId());
                t.setReceiverName(receiverName);
                t.setReceiverEmail(receiver.email());
                t.setReceiverPhoneNumber(receiver.phoneNumber());
                t.setDestinationIdentifier(zentrapayId);
                t.setPurpose(purpose);
                t.setFailureReason(null);
                t.setMetadata(null);
//                SAVING THE TRANSACTION ===================
                TransactionModel transaction = ledgerOperations.saveTransaction(t);
                log.info("============== SAVED THE TRANSACTION ================");
//         SAVING DATA TO DOUBLE ENTRY LEDGER
                _resolveDoubleEntry(transaction, walletId, receiver.walletId());
            log.info("============== RESOLVED THE DOUBLE ENTRY LEDGER ================");

                //           SAVING THE NOTIFICATIONS
                NotificationModel notification1 = new NotificationModel();
//                SENDER NOTIFICATION ================
                notification1.setUserId(userId);
                notification1.setTitle("Money Send");
                notification1.setMessage("You sent " + req.transfer().currencyCode() + " " + req.transfer().amount() + " to " + receiverName);
                notification1.setType(transaction.getTransactionType());
                notification1.setReferenceId(TXN_Ref);
                notification1.setIsRead(Boolean.FALSE);
//                      RECEIVER NOTIFICATION ================
                NotificationModel notification2 = new NotificationModel();
                notification2.setUserId(userId);
                notification2.setTitle("Money Received");
                notification2.setMessage("You received " + req.transfer().currencyCode() + " " + req.transfer().amount() + " from " + senderName);
                notification2.setType(transaction.getTransactionType());
                notification2.setReferenceId(TXN_Ref);
                notification2.setIsRead(Boolean.FALSE);

                ledgerOperations.saveNotification(notification1, notification2);
            log.info("=============== SAVED THE NOTIFICATIONS ================");

//              SAVING THE TRANSACTION DETAILS IN THE TRANSFER RESPONSE ============
                    TransferDataDTO transferData = new TransferDataDTO(
                    transaction.getTransactionId(),
                    transaction.getReceiverId(),
                    transaction.getInternalReferenceId(),
                    transaction.getDestinationIdentifier(),
                    transaction.getAmount(),
                    transaction.getSourceCurrencyCode(),
                    transaction.getStatus(),
                    transaction.getReceiverName(),
                    transaction.getReceiverPhoneNumber(),
                    transaction.getCreatedAt(),
                    transaction.getTransactionType()
                );
            log.info("=============== CREATED THE TRANSFER DATA ================");

                return new InitializePaymentResponseDTO(
                    Boolean.TRUE,
                    "Payment Successful",
                    transferData
                );
        }

                throw new RuntimeException("This service is not yet supported yet!");
    }

    private _receiverInformation _resolverReceiver(String zentag, String phoneNumber){
        log.info("=============== RESOLVING THE RECEIVER ================");
        if(zentag.isBlank()){
            UserModel user = userRepository.findByPhoneNumber(phoneNumber)
                    .orElseThrow(()-> new ResourceNotFoundException("Recipient Not Found!"));
            UUID walletId = fiatWalletRepository.getWalletIdByUserId(user.getUserId())
                    .orElseThrow(()-> new ResourceNotFoundException("Recipient Wallet Not Found!"));
            return new _receiverInformation(walletId, user.getUserId(), user.getEmail(), user.getPhoneNumber());
        }
        UUID walletId = fiatAccountRepository.getWalletIdByZentag(zentag)
                    .orElseThrow(()-> new ResourceNotFoundException("Recipient Wallet Not Found!"));
        UUID userId = fiatWalletRepository.getUserIdByWalletId(walletId)
                    .orElseThrow(()-> new ResourceNotFoundException("Recipient Not Found!"));
        UserModel user = userRepository.getUserByUserId(userId)
                    .orElseThrow(()-> new ResourceNotFoundException("Recipient Not Found!"));

        return new _receiverInformation(walletId, userId, user.getEmail(), user.getPhoneNumber());
    }

    private void _resolveDoubleEntry(TransactionModel transaction, UUID senderWalletId, UUID receiverWalletId){
        log.info("=============== RESOLVING THE DOUBLE ENTRY ================");
        log.info("=============== SENDER_WALLET_ID::{} ================", senderWalletId);
        log.info("=============== RECEIVER_WALLET_ID::{} ================", receiverWalletId);

        BigDecimal senderBalance = fiatAccountRepository.getBalanceByWalletIdAndCurrencyCode(senderWalletId, transaction.getSourceCurrencyCode())
                .orElseThrow(()-> new RuntimeException("Balance not found!"));
        log.info("=============== RESOLVED SENDER BALANCE :: {} ================", senderBalance);
        BigDecimal receiverBalance = fiatAccountRepository.getBalanceByWalletIdAndCurrencyCode(receiverWalletId, transaction.getDestinationCurrencyCode())
                .orElseThrow(()-> new RuntimeException("Balance not found!"));
        log.info("=============== RESOLVED RECEIVER BALANCE :: {} ================", receiverBalance);

        LedgerEntryModel debit_entry = _createEntry(
                transaction.getTransactionId(),
                transaction.getEntryId() + "_DEBIT",
                senderWalletId,
                Datatypes.LedgerEntryType.DEBIT,
                transaction.getAmount(),
                senderBalance,
                transaction.getSourceCurrencyCode(),
                "Transfer to " + transaction.getReceiverName() + " " + transaction.getReceiverEmail()
        );

        LedgerEntryModel credit_entry = _createEntry(
                transaction.getTransactionId(),
                transaction.getEntryId() + "_CREDIT",
                receiverWalletId,
                Datatypes.LedgerEntryType.CREDIT,
                transaction.getAmount(),
                receiverBalance,
                transaction.getDestinationCurrencyCode(),
                "Transfer from " + transaction.getSenderName() + " " + transaction.getSenderEmail()
        );


// Save both lines atomically
        ledgerEntryRepository.saveAll(List.of(debit_entry, credit_entry));
    }


//    generating the transaction internal reference code
    private String _generateReference() {
        String timestamp = LocalDateTime.now().toString().replaceAll("[^0-9]", "");
        String suffix = String.format("%04d", new java.security.SecureRandom().nextInt(10000));
        return "ZPI_" + timestamp + "_" + suffix;
    }

//    generating the entry code for double entry ledger
    private String _generateEntryId() {
        String text = String.format("%04d", new java.security.SecureRandom().nextInt(10000));
        return "ENT_" + text;
    }

    //    generating the entry code for double entry ledger
    private LedgerEntryModel _createEntry(
            UUID txnId,
            String entryId,
            UUID accountId,
            Datatypes.LedgerEntryType type,
            BigDecimal amount,
            BigDecimal runningBalance,
            String currencyCode,
            String narration
    ) {
        LedgerEntryModel entry = new LedgerEntryModel();
        entry.setTransactionId(txnId);
        entry.setEntryId(entryId);
        entry.setAccountId(accountId);
        entry.setType(type);
        entry.setAmount(amount);
        entry.setRunningBalance(runningBalance);
        entry.setCurrencyCode(currencyCode);
        entry.setNarration(narration);

        return entry;
    }
}
