package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatAccountModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatWalletModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FiatAccountRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FiatWalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.TransactionDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PaymentsService {

    private static final String TYPE_DEBIT = "debit";
    private static final String TYPE_CREDIT = "credit";

    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final TransactionRepository transactionRepository;
    private final PasswordEncoder passwordEncoder;

    private final SecureRandom random = new SecureRandom();

    @Value("${app.pin.pepper}")
    private String pinPepper;
    @Value("${app.pin.pepper}")
    private String paystackBaseUrl;
    @Value("${app.pin.pepper}")
    private String paystackSecretKey;
    @Value("${app.pin.pepper}")
    private String flutterwaveBaseUrl;
    @Value("${app.pin.pepper}")
    private String flutterwveSecretKey;

    @Transactional
    public TransactionDTO sendMoney(UUID senderId, @Valid PaymentRequestDTO req) {
        UserModel sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (!passwordEncoder.matches(req.pin() + pinPepper, sender.getTransactionPinHash())) {
            throw new IllegalArgumentException("Invalid PIN");
        }

        if(req.recipient().countryCode().equalsIgnoreCase(sender.getCountryCode())){
            if(!req.transfer().currencyType().equalsIgnoreCase("crypto")){
                if(req.destination().currencyCode().equalsIgnoreCase(req.transfer().currencyCode())){
                    final FiatWalletModel senderWallet = fiatWalletRepository.getWalletByUserId(senderId)
                            .orElseThrow(() -> new ResourceNotFoundException("User wallet not found"));

                    final FiatAccountModel senderAccount = fiatAccountRepository.getWalletByWalletIdAndCurrencyCode(senderWallet.getWalletId(), req.transfer().currencyCode())
                            .orElseThrow(() -> new ResourceNotFoundException("You currently don't have a " + req.transfer().currencyCode() + "account. Please create one or choose another currency"));

                    if(req.destination().destinationSourceType().equalsIgnoreCase("zentrapay-wallet")){

                    }else{
//                        TODO:: TO BE IMPLEMENTED LATER

                    }

                }else{
//            TODO:: CROSS BORDER PAYMENTS TO BE IMPLEMENTED LATER
            throw new IllegalArgumentException("Currency conversion is not supported at the moment");

                }
            }else{
//            TODO:: CROSS BORDER PAYMENTS TO BE IMPLEMENTED LATER
            throw new IllegalArgumentException("Crypto currencies are not supported at the moment");
            }
        }else{
//            TODO:: CROSS BORDER PAYMENTS TO BE IMPLEMENTED LATER
            throw new IllegalArgumentException("Cross border transfers are not supported at the moment");
        }

        FiatAccountModel destinationAccount = fiatAccountRepository.findById(req.destination().accountId())
                .orElseThrow(() -> new ResourceNotFoundException("Destination account not found"));
        if (!"active".equals(destinationAccount.getStatus())) {
            throw new IllegalArgumentException("Destination account is not active");
        }

        FiatWalletModel destinationWallet = fiatWalletRepository.findById(destinationAccount.getWalletId())
                .orElseThrow(() -> new ResourceNotFoundException("Destination wallet not found"));

        if (destinationWallet.getUserId().equals(senderId)) {
            throw new IllegalArgumentException("You can't send money to yourself");
        }

        FiatWalletModel senderWallet = fiatWalletRepository.findByUserId(senderId)
                .orElseThrow(() -> new IllegalArgumentException("Something went wrong. Wallet missing!"));

        if (!senderWallet.getCountryCode().equalsIgnoreCase(destinationWallet.getCountryCode())) {
            throw new IllegalArgumentException(
                    "Cross-border transfers aren't supported yet — this recipient is in a different country");
        }

        // Ground truth for the currency being moved is the destination account
        // itself, not the client-supplied destination.currencyCode (that field
        // is only echoed back for display/consistency, never trusted for money
        // movement).
        final String currencyCode = destinationAccount.getCurrencyCode();
        final BigDecimal amount = req.destination().amount().setScale(4, RoundingMode.HALF_UP);

        FiatAccountModel senderAccount = fiatAccountRepository.findByWalletId(senderWallet.getWalletId()).stream()
                .filter(a -> currencyCode.equals(a.getCurrencyCode()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "You don't have a " + currencyCode + " account to send from"));

        int debited = fiatAccountRepository.debit(senderWallet.getWalletId(), amount, currencyCode);
        if (debited == 0) {
            throw new IllegalArgumentException("Insufficient balance");
        }
        fiatAccountRepository.credit(destinationWallet.getWalletId(), amount, currencyCode);

        UserModel recipient = userRepository.findById(destinationWallet.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Recipient not found"));

        final String reference = generateReference();
        final String recipientName = (recipient.getFirstName() + " " + recipient.getLastName()).trim();
        final String senderName = (sender.getFirstName() + " " + sender.getLastName()).trim();

        Transaction debitLeg = new Transaction();
        debitLeg.setUserId(senderId);
        debitLeg.setWalletId(senderWallet.getWalletId());
        debitLeg.setTypeCode(TYPE_DEBIT);
        debitLeg.setAmount(amount);
        debitLeg.setCurrencyCode(currencyCode);
        debitLeg.setCurrency(currencyCode);
        debitLeg.setTransactionType(TYPE_DEBIT);
        debitLeg.setStatus("SUCCESS");
        debitLeg.setReference(reference);
        debitLeg.setCounterpartyUserId(recipient.getUserId());
        debitLeg.setCounterpartyName(recipientName);
        debitLeg.setCounterpartyIdentifier(destinationAccount.getZentag());
        debitLeg.setDescription("Sent to " + recipientName);
        debitLeg = transactionRepository.save(debitLeg);

        Transaction creditLeg = new Transaction();
        creditLeg.setUserId(recipient.getUserId());
        creditLeg.setWalletId(destinationWallet.getWalletId());
        creditLeg.setTypeCode(TYPE_CREDIT);
        creditLeg.setAmount(amount);
        creditLeg.setCurrencyCode(currencyCode);
        creditLeg.setCurrency(currencyCode);
        creditLeg.setTransactionType(TYPE_CREDIT);
        creditLeg.setStatus("SUCCESS");
        // reference must be unique per row — the credit leg mirrors the debit
        // leg's reference with a suffix so both sides of one transfer can
        // still be correlated.
        creditLeg.setReference(reference + "-C");
        creditLeg.setCounterpartyUserId(senderId);
        creditLeg.setCounterpartyName(senderName);
        creditLeg.setCounterpartyIdentifier(senderAccount.getZentag());
        creditLeg.setDescription("Received from " + senderName);
        transactionRepository.save(creditLeg);

        return toDTO(debitLeg);
    }

    private String generateReference() {
        String timestamp = LocalDateTime.now().toString().replaceAll("[^0-9]", "");
        String suffix = String.format("%04d", random.nextInt(10000));
        return "ZP_" + timestamp + "_" + suffix;
    }

    private static boolean isCreditType(String typeCode) {
        return typeCode != null && typeCode.endsWith("_CREDIT");
    }

    public static TransactionDTO toDTO(Transaction t) {
        String sign = isCreditType(t.getTypeCode()) ? "+" : "-";
        return new TransactionDTO(
                t.getTransactionId(),
                t.getTypeCode(),
                sign + t.getAmount().toPlainString(),
                t.getCurrencyCode(),
                t.getStatus(),
                t.getGateway(),
                t.getReference(),
                t.getCounterpartyName(),
                t.getCounterpartyIdentifier(),
                t.getDescription(),
                t.getCreatedAt()
        );
    }
}
