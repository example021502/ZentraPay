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
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.TransactionDTO;
import jakarta.persistence.Column;
import jakarta.transaction.Transaction;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
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

    private static final String type_debit = "debit";
    private static final String type_credit = "credit";

    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final TransactionRepository transactionRepository;
    private final PasswordEncoder passwordEncoder;

    private final SecureRandom random = new SecureRandom();

    @Value("${app.pin.pepper}")
    private String pinPepper;
    @Value("${paystack.base-url}")
    private String paystackBaseUrl;
    @Value("${paystack.secret-key}")
    private String paystackSecretKey;
    @Value("${flutterwave.base-url}")
    private String flutterwaveBaseUrl;
    @Value("${flutterwave.secret-key}")
    private String flutterwaveSecretKey;
    @Value("${zentrapay.id}")
    private String zentrapay_id;

    @Transactional
    public Optional<TransactionDTO> sendMoney(UUID senderId, @Valid PaymentRequestDTO req) {
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
                    if(!senderAccount.getStatus().equalsIgnoreCase("active")){
                        throw new IllegalArgumentException("Your account is " + senderAccount.getStatus() +  " at the moment");
                    }

                    if(req.destination().destinationSourceType().equalsIgnoreCase("zentrapay-wallet")){
                        final UserModel receiver = userRepository.findByEmailOrPhoneNumber(req.recipient().email(), req.recipient().phoneNumber())
                            .orElseThrow(() -> new ResourceNotFoundException("Receiver account cannot be resolved, please cross check the receiver information you provided and try again!"));
                        final FiatWalletModel receiverWallet = fiatWalletRepository.findByUserId(receiver.getUserId())
                            .orElseThrow(() -> new ResourceNotFoundException("Receiver wallet cannot be resolved, please cross check the receiver information you provided and try again!"));
                        final FiatAccountModel receiverAccount = fiatAccountRepository.getWalletByWalletIdAndCurrencyCode(receiverWallet.getWalletId(), req.transfer().currencyCode())
                            .orElseThrow(() -> new ResourceNotFoundException("Receiver currency account cannot be resolved, please cross check the receiver information you provided and try again!"));
                        if(!receiverAccount.getStatus().equalsIgnoreCase("active")){
                            throw new IllegalArgumentException("Receiver account is " + receiverAccount.getStatus() +  " at the moment");
                        }

                        int debited = fiatAccountRepository.debit(senderWallet.getWalletId(), req.transfer().amount(), req.transfer().currencyCode());
                        if (debited == 0) {
                            throw new IllegalArgumentException("Insufficient balance");
                        }
                        boolean isPurposeExist = !req.transfer().purpose().isBlank();
                        String purpose = isPurposeExist ? req.transfer().purpose() : "**Default::Sending " + req.transfer().currencyCode() + req.transfer().amount() + "to" + req.recipient().fullName();
                     int credited = fiatAccountRepository.credit(receiverWallet.getWalletId(), req.transfer().amount(), req.transfer().currencyCode());
                        if (credited == 0) {
                            throw new IllegalArgumentException("Something went wrong, try again");
                        }

                        TransactionModel debitLeg = new TransactionModel();
                        debitLeg.setAmount(req.transfer().amount());
                        debitLeg.setGateway("internal");
                        debitLeg.setStatus("success");
                        debitLeg.setTransactionType(type_debit);
                        debitLeg.setSenderId(sender.getUserId());
                        debitLeg.setReceiverId(receiver.getUserId());
                        debitLeg.setSenderName(sender.getFirstName()+sender.getLastName());
                        debitLeg.setReceiverName(receiver.getFirstName()+receiver.getLastName());
                        debitLeg.setSourceCurrencyCode(req.transfer().currencyCode());
                        debitLeg.setDestinationCurrencyCode(req.destination().currencyCode());
                        debitLeg.setPurpose(purpose);
                        debitLeg.setSenderEmail(sender.getEmail());
                        debitLeg.setSenderPhoneNumber(sender.getPhoneNumber());
                        debitLeg.setReceiverEmail(receiver.getEmail());
                        debitLeg.setReceiverPhoneNumber(receiver.getPhoneNumber());
                        debitLeg.setInternalReferenceId(req.transfer().referenceId());
                        debitLeg.setExternalReferenceId(generateReference());

                        debitLeg = transactionRepository.save(debitLeg);

                        TransactionModel creditLeg = new TransactionModel();
                        creditLeg.setAmount(req.transfer().amount());
                        creditLeg.setGateway("internal");
                        creditLeg.setStatus("success");
                        creditLeg.setTransactionType(type_credit);
                        creditLeg.setSenderId(sender.getUserId());
                        creditLeg.setReceiverId(receiver.getUserId());
                        creditLeg.setSenderName(sender.getFirstName()+sender.getLastName());
                        creditLeg.setReceiverName(receiver.getFirstName()+receiver.getLastName());
                        creditLeg.setSourceCurrencyCode(req.transfer().currencyCode());
                        creditLeg.setDestinationCurrencyCode(req.destination().currencyCode());
                        creditLeg.setPurpose(purpose);
                        creditLeg.setSenderEmail(sender.getEmail());
                        creditLeg.setSenderPhoneNumber(sender.getPhoneNumber());
                        creditLeg.setReceiverEmail(receiver.getEmail());
                        creditLeg.setReceiverPhoneNumber(receiver.getPhoneNumber());
                        creditLeg.setInternalReferenceId(req.transfer().referenceId());
                        creditLeg.setExternalReferenceId(generateReference());
                        transactionRepository.save(creditLeg);

                        return toDTO(debitLeg);

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
            throw new IllegalArgumentException("Something went wrong, try again");
    }

    private String generateReference() {
        String timestamp = LocalDateTime.now().toString().replaceAll("[^0-9]", "");
        String suffix = String.format("%04d", random.nextInt(10000));
        return "ZP_" + timestamp + "_" + suffix;
    }

    public static Optional<TransactionDTO> toDTO(TransactionModel t) {
        String sign = t.getTransactionType().equalsIgnoreCase("credit") ? "+" : "-";
        return Optional.of(new TransactionDTO(
                t.getTransactionId(),
                sign + t.getSourceCurrencyCode() + t.getAmount().toPlainString(),
                t.getCreatedAt(),
                t.getFailureReason(),
                t.getGateway(),
                t.getMetadata(),
                t.getStatus(),
                t.getUpdatedAt(),
                t.getTransactionType(),
                t.getReceiverName(),
                t.getPurpose(),
                t.getInternalReferenceId(),
                t.getDestinationIdentifier(),
                t.getDestinationIdentifier()
        ));
    }
}
