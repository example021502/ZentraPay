package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.NanoIdGenerator;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.*;
import jakarta.persistence.Column;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Service orchestrating wallet-to-wallet and outbound bank transfers.
 * Internal wallet-to-wallet transfers never touch gateway APIs; outbound
 * bank/mobile-money payouts resolve gateway customers and recipients
 * (local-first check, then Paystack / Flutterwave API registration using
 */
@Service
@RequiredArgsConstructor
public class PaymentsService {

    // Comment: Constants for transaction types and payment gateways
    private static final String TYPE_DEBIT = "debit";
    private static final String TYPE_CREDIT = "credit";
    private static final String GATEWAY_INTERNAL = "internal";
    private static final String GATEWAY_NAME_INTERNAL = "internal_zentrapay";
    private static final String GATEWAY_PAYSTACK = "paystack";
    private static final String GATEWAY_FLUTTERWAVE = "flutterwave";

    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final TransactionRepository transactionRepository;
    private final PasswordEncoder passwordEncoder;
    private final NotificationRepository notificationRepository;
    private final SecureRandom random = new SecureRandom();
    private final FlutterwaveClient flutterwaveClient;
    private final GatewayRecipientsRepository gatewayRecipientsRepository;
    private final GatewayCustomerReposittory gatewayCustomerReposittory;
    private final GatewayRepository gatewayRepository;
    private final PaystackServices paystackServices;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    @Transactional
    public Optional<TransactionDTO> sendMoney(UUID senderId, @Valid PaymentRequestDTO req) {
        // Comment: Fetch and validate sender user
        UserModel sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        // Comment: Verify security PIN against stored hash with pepper
        if (!passwordEncoder.matches(req.pin() + pinPepper, sender.getTransactionPinHash())) {
            throw new IllegalArgumentException("Invalid PIN");
        }

        // Comment: Validate domestic transfer corridor rules
        String recipientCountryCode = req.destination().countryCode();
        boolean sameCountry = recipientCountryCode == null
                || recipientCountryCode.isBlank()
                || recipientCountryCode.equalsIgnoreCase(sender.getCountryCode());

        if (!sameCountry) {
            throw new IllegalArgumentException("Cross border transfers are not supported at the moment");
        }

        if (req.transfer().currencyType().equalsIgnoreCase("crypto")) {
            throw new IllegalArgumentException("Crypto currencies are not supported at the moment");
        }

        if (!req.destination().currencyCode().equalsIgnoreCase(req.transfer().currencyCode())) {
            throw new IllegalArgumentException("Currency conversion is not supported at the moment");
        }

        // Comment: Resolve and validate sender wallet and account status
        FiatWalletModel senderWallet = fiatWalletRepository.getWalletByUserId(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("User wallet not found"));

        FiatAccountModel senderAccount = fiatAccountRepository.getWalletByWalletIdAndCurrencyCode(
                        senderWallet.getWalletId(), req.transfer().currencyCode())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "You currently don't have a " + req.transfer().currencyCode() + " account. Please create one or choose another currency"));

        if (!senderAccount.getStatus().equalsIgnoreCase("active")) {
            throw new IllegalArgumentException("Your account is " + senderAccount.getStatus() + " at the moment");
        }

        // Comment: Route execution based on destination target
        if (userRepository.existsByEmailOrPhoneNumber(req.recipient().email(), req.recipient().phoneNumber())) {
            if(req.destination().channelCode().equalsIgnoreCase("zentrapay_app")){
            return processInternalWalletTransfer(sender, senderWallet, req);
            }else{
//                TODO : COMING SOON
            }
        } else if (req.destination().channelCode().equalsIgnoreCase("bank")) {
            return processBankTransfer(sender, senderWallet, req);
        }
         else if (req.destination().channelCode().equalsIgnoreCase("mobile_money")) {
//                TODO : COMING SOON
        }

        throw new IllegalArgumentException("Unsupported destination source type");
    }

    /**
     * Executes internal P2P wallet-to-wallet transfers without external recipient creation.
     */
    private Optional<TransactionDTO> processInternalWalletTransfer(UserModel sender, FiatWalletModel senderWallet, PaymentRequestDTO req) {
        // Comment: Resolve receiver and receiver account details
        UserModel receiver = userRepository.findByEmailOrPhoneNumber(req.recipient().email(), req.recipient().phoneNumber())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver account cannot be resolved, please check receiver details"));

        FiatWalletModel receiverWallet = fiatWalletRepository.findByUserId(receiver.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver wallet cannot be resolved"));

        FiatAccountModel receiverAccount = fiatAccountRepository.getWalletByWalletIdAndCurrencyCode(
                        receiverWallet.getWalletId(), req.transfer().currencyCode())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver currency account cannot be resolved"));

        if (!receiverAccount.getStatus().equalsIgnoreCase("active")) {
            throw new IllegalArgumentException("Receiver account is " + receiverAccount.getStatus() + " at the moment");
        }

        // Comment: Internal tracking reference for the sender (no gateway customer
        // row is created — internal transactions never call gateway APIs)
        String senderCustomerRef = "zp_cust_" + sender.getUserId();

        // Comment: Perform double-entry debit/credit ledger updates
        int debited = fiatAccountRepository.debit(senderWallet.getWalletId(), req.transfer().amount(), req.transfer().currencyCode());
        if (debited == 0) {
            throw new IllegalArgumentException("Insufficient balance");
        }

        int credited = fiatAccountRepository.credit(receiverWallet.getWalletId(), req.transfer().amount(), req.transfer().currencyCode());
        if (credited == 0) {
            throw new IllegalArgumentException("Something went wrong during crediting, try again");
        }

        String entryRef = generateReference();
        String destinationIdentifier = req.destination().accountIdentifier();
        boolean isPurposeExist = req.transfer().purpose() != null && !req.transfer().purpose().isBlank();
        String purpose = isPurposeExist
                ? req.transfer().purpose()
                : "Sending " + req.transfer().currencyCode() + " " + req.transfer().amount() + " to " + req.recipient().fullName();

        // Comment: Persist debit and credit transaction legs
        TransactionModel debitLeg = buildTransactionModel(
                sender, receiver, req, entryRef, destinationIdentifier, purpose, TYPE_DEBIT, senderCustomerRef, null
        );
        debitLeg = transactionRepository.save(debitLeg);

        TransactionModel creditLeg = buildTransactionModel(
                sender, receiver, req, entryRef, destinationIdentifier, purpose, TYPE_CREDIT, senderCustomerRef, null
        );
        transactionRepository.save(creditLeg);

        return toDTO(debitLeg);
    }

    /**
     * Executes outbound bank transfer payouts via external payment providers.
     */




    private Optional<TransactionDTO> processBankTransfer(UserModel sender, FiatWalletModel senderWallet, PaymentRequestDTO req) {

//        GETTING THE GATEWAY PROVIDER
        GatewayModel gateway;
        gateway = gatewayRepository.getGatewayProvider("paystack");
        if(gateway == null || !gateway.getIsActive()){
            gateway = gatewayRepository.getGatewayProvider("flutterwave");
            if(gateway == null || !gateway.getIsActive()){
                throw new IllegalStateException("Your request could not be performed");
            }
        }

//GETTING OR CREATING THE CUSTOMER
        Optional<GatewayCustomerModel> paystack_customer = gatewayCustomerReposittory.getByUserIdAndGatewayId(sender.getUserId(), gateway.getProviderId());
        if(paystack_customer.isEmpty()){
            PaystackCustomerResponseDTO g_customer = paystackServices.createCustomer(sender, req);
            GatewayCustomerModel newCustomer = new GatewayCustomerModel();
            newCustomer.setUserId(sender.getUserId());
            newCustomer.setGatewayId(gateway.getProviderId());
            newCustomer.setGatewayName(gateway.getProviderName());
            newCustomer.setEmail(sender.getEmail());
            newCustomer.setGatewayCustomerId(g_customer.data().customerCode());
            paystack_customer = Optional.of(gatewayCustomerReposittory.save(newCustomer));
        }

//GETTING OR CREATING THE RECIPIENT
        Optional<GatewayRecipientsModel> paystack_recipient = gatewayRecipientsRepository.getByUserIdAndGatewayId(sender.getUserId(), gateway.getProviderId());
        if(paystack_recipient.isEmpty()){
            PaystackRecipientResponseDTO g_recipient = paystackServices.createRecipient(req);
            GatewayRecipientsModel newRecipient = new GatewayRecipientsModel();
            if(!g_recipient.status()){
                throw new PaymentGatewayException("Something went wrong, all transfer trials where undone");
            }
            newRecipient.setUserId(sender.getUserId());
            newRecipient.setGatewayId(gateway.getProviderId());
            newRecipient.setGatewayName(gateway.getProviderName());
            newRecipient.setGatewayRecipientId(g_recipient.data().recipientCode());
            newRecipient.setCheckoutType(req.destination().checkoutType());
            newRecipient.setChannelCode(req.destination().channelCode());
            newRecipient.setAccountIdentifier(req.destination().accountIdentifier());
            newRecipient.setAccountName(req.destination().accountName());
            paystack_recipient = Optional.of(gatewayRecipientsRepository.save(newRecipient));
        }

    int debited = fiatAccountRepository.debit(senderWallet.getWalletId(), req.transfer().amount(), req.transfer().currencyCode());
        if (debited == 0) {
        throw new IllegalArgumentException("Insufficient balance");
    }
        initiateBankTransfer



/** Builds the {@code transactions} row for an outbound gateway payout. */
private TransactionModel buildBankTransferTransaction(
        UserModel sender, TransferRecipientModel recipient, PaymentRequestDTO req,
        String entryRef, String purpose, String gateway, String status,
        String gatewayTransferCode, String customerId, String recipientId) {

    TransactionModel tx = new TransactionModel();
    tx.setEntryId(entryRef);
    tx.setAmount(req.transfer().amount());
    tx.setGateway(gateway);
    tx.setStatus(status);
    tx.setTransactionType(TYPE_DEBIT);
    tx.setSenderId(sender.getUserId());
    tx.setReceiverId(sender.getUserId());
    tx.setSenderName(sender.getFirstName() + " " + sender.getLastName());
    tx.setReceiverName(recipient.getRecipientName());
    tx.setSourceCurrencyCode(recipient.getCurrencyCode());
    tx.setDestinationCurrencyCode(recipient.getCurrencyCode());
    tx.setPurpose(purpose);
    tx.setSenderEmail(sender.getEmail());
    tx.setSenderPhoneNumber(sender.getPhoneNumber());
    tx.setReceiverEmail("");
    tx.setReceiverPhoneNumber("");
    tx.setInternalReferenceId(entryRef);
    tx.setExternalReferenceId(gatewayTransferCode == null ? "" : gatewayTransferCode);
    tx.setDestinationIdentifier(recipient.getAccountIdentifier());
    tx.setFailureReason("failed".equalsIgnoreCase(status) ? "Gateway rejected the transfer" : "");
    String metadata = "{\"channel\":\"bank_transfer\",\"gateway\":\"" + gateway
            + "\",\"customerId\":\"" + (customerId == null ? "" : customerId)
            + "\",\"destinationType\":\"" + recipient.getDestinationType() + "\""
            + (recipientId != null && !recipientId.isBlank() ? ",\"recipientId\":\"" + recipientId + "\"" : "")
            + "}";
    tx.setMetadata(metadata);
    return tx;
}

/** Persists an in-app notification row for the transfer outcome. */
private NotificationModel saveNotification(
        UserModel sender, String entryRef, String title, String message) {

    NotificationModel notification = new NotificationModel();
    notification.setUserId(sender.getUserId());
    notification.setTitle(title);
    notification.setMessage(message);
    notification.setType("TRANSFER");
    notification.setReferenceId(entryRef);
    notification.setIsRead(false);
    return notificationRepository.save(notification);
}

/**
 * Helper to assemble TransactionModel entities.
 */
private TransactionModel buildTransactionModel(
        UserModel sender,
        UserModel receiver,
        PaymentRequestDTO req,
        String entryRef,
        String destinationIdentifier,
        String purpose,
        String type,
        String customerId,
        String recipientId) {

    TransactionModel tx = new TransactionModel();
    tx.setAmount(req.transfer().amount());
    tx.setGateway(GATEWAY_INTERNAL);
    tx.setStatus("success");
    tx.setTransactionType(type);
    tx.setSenderId(sender.getUserId());
    tx.setReceiverId(receiver != null ? receiver.getUserId() : null);
    tx.setSenderName(sender.getFirstName() + " " + sender.getLastName());
    tx.setReceiverName(receiver != null ? receiver.getFirstName() + " " + receiver.getLastName() : req.recipient().fullName());
    tx.setSourceCurrencyCode(req.transfer().currencyCode());
    tx.setDestinationCurrencyCode(req.destination().currencyCode());
    tx.setPurpose(purpose);
    tx.setSenderEmail(sender.getEmail());
    tx.setSenderPhoneNumber(sender.getPhoneNumber());
    tx.setReceiverEmail(req.recipient().email());
    tx.setReceiverPhoneNumber(req.recipient().phoneNumber());
    tx.setInternalReferenceId(req.transfer().referenceId());
    tx.setExternalReferenceId(entryRef);
    tx.setEntryId(entryRef);
    tx.setDestinationIdentifier(destinationIdentifier);
    tx.setFailureReason("");
    tx.setMetadata("customerId=" + customerId + (recipientId != null ? ",recipientId=" + recipientId : ""));
    return tx;
}

private String generateReference() {
    String timestamp = LocalDateTime.now().toString().replaceAll("[^0-9]", "");
    String suffix = String.format("%04d", random.nextInt(10000));
    return "zp_" + timestamp + "_" + suffix;
}

public static Optional<TransactionDTO> toDTO(TransactionModel t) {
    return toDTO(t, null);
}

public static Optional<TransactionDTO> toDTO(TransactionModel t, String notification) {
    String sign = t.getTransactionType().equalsIgnoreCase("credit") ? "+" : "-";
    return Optional.of(new TransactionDTO(
            t.getTransactionId(),
            t.getReceiverId(),
            t.getReceiverEmail(),
            t.getReceiverPhoneNumber(),
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
            t.getExternalReferenceId(),
            t.getDestinationIdentifier(),
            notification
    ));
};
