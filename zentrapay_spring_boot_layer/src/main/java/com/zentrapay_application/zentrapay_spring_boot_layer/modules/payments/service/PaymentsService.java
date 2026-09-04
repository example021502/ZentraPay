package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.NanoIdGenerator;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.security.SecureRandom;
import java.util.Optional;
import java.util.UUID;

/**
 * Service orchestrating wallet-to-wallet and outbound bank transfers.
 * Internal wallet-to-wallet transfers never touch gateway APIs; outbound
 * bank/mobile-money payouts resolve gateway customers and recipients
 * (local-first check, then Paystack / Flutterwave API registration using
 * Paystack as the primary national gateway and Flutterwave as its failover).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentsService {

    // Comment: Constants for transaction types and payment gateways
    private static final String TYPE_DEBIT = "debit";
    private static final String TYPE_CREDIT = "credit";
    private static final String GATEWAY_PAYSTACK = "paystack";
    private static final String GATEWAY_FLUTTERWAVE = "flutterwave";
    private static final String STATUS_PROCESSING = "processing";
    private static final String STATUS_FAILED = "failed";
    private static final short MIN_TIER_TO_TRANSACT = 2;

    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final PasswordEncoder passwordEncoder;
    private final SecureRandom random = new SecureRandom();
    private final FlutterwaveClient flutterwaveClient;
    private final GatewayRecipientsRepository gatewayRecipientsRepository;
    private final GatewayCustomerReposittory gatewayCustomerReposittory;
    private final GatewayRepository gatewayRepository;
    private final PaystackServices paystackServices;
    private final LedgerOperations ledgerOperations;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    // Comment: Deliberately NOT @Transactional — this dispatches into
    // processBankTransfer, which makes slow external gateway HTTP calls
    // between ledger writes. Wrapping that in one DB transaction would (a)
    // hold a connection/lock across a network round trip, and (b) roll back
    // *every* write — including the "both gateways failed" refund and the
    // failed-transaction audit row — the moment an error is thrown at the
    // end to surface the failure to the caller. Each ledger write below
    // (debit/credit/save) is already its own atomic statement, and the
    // failure paths compensate explicitly rather than relying on rollback.
    public Optional<TransactionDTO> sendMoney(UUID senderId, @Valid PaymentRequestDTO req) {
        // Comment: Fetch and validate sender user
        UserModel sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        // Comment: Verify security PIN against stored hash with pepper
        if (!passwordEncoder.matches(req.pin() + pinPepper, sender.getTransactionPinHash())) {
            throw new IllegalArgumentException("Invalid PIN");
        }

        // Comment: Tier-2 KYC gate — sending money nationally (bank or
        // internal wallet-to-wallet) requires a complete profile + uploaded
        // ID documents (see UsersService#recomputeKycTier). This is enforced
        // here rather than in the controller so every entry point (internal
        // pay, bank-transfer) gets it for free.
        if (sender.getKycTier() < MIN_TIER_TO_TRANSACT) {
            throw new IllegalArgumentException(
                    "Complete your profile and verification (Tier 2) to send money — you're currently Tier " + sender.getKycTier());
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

        // Comment: Route execution based on the destination's coarse type
        // (checkoutType: zentrapay_app | bank | mobile_money). channelCode
        // carries the specific gateway code (bank code / momo provider code)
        // and must never be used for this routing decision.
        String destinationType = req.destination().checkoutType();

        if (destinationType.equalsIgnoreCase("zentrapay_app")) {
            if (!userRepository.existsByEmailOrPhoneNumber(req.recipient().email(), req.recipient().phoneNumber())) {
                throw new ResourceNotFoundException("Receiver account cannot be resolved, please check receiver details");
            }
            return processInternalWalletTransfer(sender, senderWallet, req);
        } else if (destinationType.equalsIgnoreCase("bank")) {
            return processBankTransfer(sender, senderWallet, req);
        } else if (destinationType.equalsIgnoreCase("mobile_money")) {
            // TODO : COMING SOON
            throw new IllegalArgumentException("Mobile money payouts are not supported at the moment");
        }

        throw new IllegalArgumentException("Unsupported destination source type");
    }

    /**
     * Adapts the flat {@link BankTransferRequestDTO} (matches the existing
     * Flutter {@code payBankTransfer()} call shape) into the canonical
     * {@link PaymentRequestDTO} and delegates to {@link #sendMoney}. National
     * bank transfers only — the destination's country is assumed to be the
     * sender's own registration country.
     */
    // Comment: not @Transactional — see sendMoney's note; this just reshapes
    // and delegates to it.
    public Optional<TransactionDTO> sendBankTransfer(UUID senderId, @Valid BankTransferRequestDTO req) {
        UserModel sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        BigDecimal amount;
        try {
            amount = new BigDecimal(req.amount());
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Invalid amount");
        }

        PaymentRecipientDTO recipient = new PaymentRecipientDTO(
                req.accountName(), "", "", sender.getCountryCode());
        PaymentDestinationDTO destination = new PaymentDestinationDTO(
                req.accountNumber(), req.accountName(), req.currencyCode(),
                sender.getCountryCode(), "bank", req.channelCode());
        PaymentTransferDTO transfer = new PaymentTransferDTO(
                generateReference(), amount, req.currencyCode(), "fiat", req.description());

        return sendMoney(senderId, new PaymentRequestDTO(req.pin(), recipient, destination, transfer));
    }

    /**
     * Executes internal P2P wallet-to-wallet transfers without external recipient creation.
     */
    private Optional<TransactionDTO> processInternalWalletTransfer(UserModel sender, FiatWalletModel senderWallet, PaymentRequestDTO req) {
        // Comment: Resolve receiver and receiver account details
        UserModel receiver = userRepository.findByEmailOrPhoneNumber(req.recipient().email(), req.recipient().phoneNumber())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver account cannot be resolved, please check receiver details"));

        // Comment: Tier-2 gate applies to receiving too — see sendMoney's
        // sender-side check.
        if (receiver.getKycTier() < MIN_TIER_TO_TRANSACT) {
            throw new IllegalArgumentException(
                    "The recipient needs to complete their profile and verification (Tier 2) before they can receive money");
        }

        FiatWalletModel receiverWallet = fiatWalletRepository.findByUserId(receiver.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver wallet cannot be resolved"));

        FiatAccountModel receiverAccount = fiatAccountRepository.getWalletByWalletIdAndCurrencyCode(
                        receiverWallet.getWalletId(), req.transfer().currencyCode())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver currency account cannot be resolved"));

        if (!receiverAccount.getStatus().equalsIgnoreCase("active")) {
            throw new IllegalArgumentException("Receiver account is " + receiverAccount.getStatus() + " at the moment");
        }

        String entryRef = generateReference();

        // Comment: Perform double-entry debit/credit ledger updates
        int debited = ledgerOperations.debit(senderWallet.getWalletId(), req.transfer().amount(), req.transfer().currencyCode());
        if (debited == 0) {
            throw new IllegalArgumentException("Insufficient balance");
        }

        int credited = ledgerOperations.credit(receiverWallet.getWalletId(), req.transfer().amount(), req.transfer().currencyCode());
        if (credited == 0) {
            // Comment: Undo the debit — the credit leg failed, money must not vanish
            ledgerOperations.credit(senderWallet.getWalletId(), req.transfer().amount(), req.transfer().currencyCode());
            throw new IllegalArgumentException("Something went wrong during crediting, try again");
        }

        String destinationIdentifier = req.destination().accountIdentifier();
        boolean isPurposeExist = req.transfer().purpose() != null && !req.transfer().purpose().isBlank();
        String purpose = isPurposeExist
                ? req.transfer().purpose()
                : "Sending " + req.transfer().currencyCode() + " " + req.transfer().amount() + " to " + req.recipient().fullName();

        // Comment: Persist debit and credit transaction legs (same entry, opposite sides)
        TransactionModel debitLeg = new TransactionModel();
        debitLeg.setEntryId(entryRef);
        debitLeg.setAmount(req.transfer().amount());
        debitLeg.setGateway("internal");
        debitLeg.setStatus("success");
        debitLeg.setTransactionType(TYPE_DEBIT);
        debitLeg.setSenderId(sender.getUserId());
        debitLeg.setReceiverId(receiver.getUserId());
        debitLeg.setSenderName(sender.getFirstName() + " " + sender.getLastName());
        debitLeg.setReceiverName(receiver.getFirstName() + " " + receiver.getLastName());
        debitLeg.setSourceCurrencyCode(req.transfer().currencyCode());
        debitLeg.setDestinationCurrencyCode(req.transfer().currencyCode());
        debitLeg.setPurpose(purpose);
        debitLeg.setSenderEmail(sender.getEmail());
        debitLeg.setSenderPhoneNumber(sender.getPhoneNumber());
        debitLeg.setReceiverEmail(receiver.getEmail());
        debitLeg.setReceiverPhoneNumber(receiver.getPhoneNumber());
        debitLeg.setInternalReferenceId(entryRef);
        debitLeg.setExternalReferenceId("");
        debitLeg.setDestinationIdentifier(destinationIdentifier);
        debitLeg.setFailureReason("");
        debitLeg.setMetadata(null);
        debitLeg = ledgerOperations.saveTransaction(debitLeg);

        TransactionModel creditLeg = new TransactionModel();
        creditLeg.setEntryId(NanoIdGenerator.generate("ZP_"));
        creditLeg.setAmount(req.transfer().amount());
        creditLeg.setGateway("internal");
        creditLeg.setStatus("success");
        creditLeg.setTransactionType(TYPE_CREDIT);
        creditLeg.setSenderId(sender.getUserId());
        creditLeg.setReceiverId(receiver.getUserId());
        creditLeg.setSenderName(sender.getFirstName() + " " + sender.getLastName());
        creditLeg.setReceiverName(receiver.getFirstName() + " " + receiver.getLastName());
        creditLeg.setSourceCurrencyCode(req.transfer().currencyCode());
        creditLeg.setDestinationCurrencyCode(req.transfer().currencyCode());
        creditLeg.setPurpose(purpose);
        creditLeg.setSenderEmail(sender.getEmail());
        creditLeg.setSenderPhoneNumber(sender.getPhoneNumber());
        creditLeg.setReceiverEmail(receiver.getEmail());
        creditLeg.setReceiverPhoneNumber(receiver.getPhoneNumber());
        creditLeg.setInternalReferenceId(entryRef);
        creditLeg.setExternalReferenceId("");
        creditLeg.setDestinationIdentifier(destinationIdentifier);
        creditLeg.setFailureReason("");
        creditLeg.setMetadata(null);
        ledgerOperations.saveTransaction(creditLeg);

        // Comment: Notify both parties in-app
        saveNotification(sender, entryRef, "Money Sent", "You sent " + req.transfer().currencyCode() + " " + req.transfer().amount() + " to " + receiver.getFirstName());
        saveNotification(receiver, entryRef, "Money Received", "You received " + req.transfer().currencyCode() + " " + req.transfer().amount() + " from " + sender.getFirstName());

        return Optional.of(toDTO(debitLeg));
    }

    /**
     * Executes outbound bank transfer payouts via external payment providers.
     * Paystack is attempted first (primary national gateway); if Paystack
     * can't even accept the recipient/transfer, Flutterwave (which needs no
     * recipient pre-registration) is tried as the failover. If both gateways
     * fail, the sender's debit is reversed so money never just vanishes.
     */
    private Optional<TransactionDTO> processBankTransfer(UserModel sender, FiatWalletModel senderWallet, PaymentRequestDTO req) {

        // GETTING THE PAYSTACK GATEWAY PROVIDER (primary national gateway)
        GatewayModel paystackGateway = gatewayRepository.getGatewayProvider(GATEWAY_PAYSTACK);
        boolean paystackAvailable = paystackGateway != null && Boolean.TRUE.equals(paystackGateway.getIsActive());

        GatewayCustomerModel paystackCustomer = null;
        GatewayRecipientsModel paystackRecipient = null;

        if (paystackAvailable) {
            // GETTING OR CREATING THE PAYSTACK CUSTOMER (local-first)
            Optional<GatewayCustomerModel> existingCustomer =
                    gatewayCustomerReposittory.getByUserIdAndGatewayId(sender.getUserId(), paystackGateway.getProviderId());
            if (existingCustomer.isPresent()) {
                paystackCustomer = existingCustomer.get();
            } else {
                PaystackCustomerResponseDTO g_customer = paystackServices.createCustomer(sender, req);
                if (g_customer != null && g_customer.data() != null) {
                    GatewayCustomerModel newCustomer = new GatewayCustomerModel();
                    newCustomer.setUserId(sender.getUserId());
                    newCustomer.setGatewayId(paystackGateway.getProviderId());
                    newCustomer.setGatewayName(paystackGateway.getProviderName());
                    newCustomer.setEmail(sender.getEmail());
                    newCustomer.setGatewayCustomerId(g_customer.data().customerCode());
                    paystackCustomer = gatewayCustomerReposittory.save(newCustomer);
                }
            }
        }

        if (paystackCustomer != null) {
            // GETTING OR CREATING THE PAYSTACK RECIPIENT (local-first)
            Optional<GatewayRecipientsModel> existingRecipient =
                    gatewayRecipientsRepository.getByUserIdAndGatewayId(sender.getUserId(), paystackGateway.getProviderId());
            if (existingRecipient.isPresent()) {
                paystackRecipient = existingRecipient.get();
            } else {
                PaystackRecipientResponseDTO g_recipient = paystackServices.createRecipient(req);
                if (g_recipient != null && g_recipient.status() && g_recipient.data() != null) {
                    GatewayRecipientsModel newRecipient = new GatewayRecipientsModel();
                    newRecipient.setUserId(sender.getUserId());
                    newRecipient.setGatewayId(paystackGateway.getProviderId());
                    newRecipient.setGatewayName(paystackGateway.getProviderName());
                    newRecipient.setGatewayRecipientId(g_recipient.data().recipientCode());
                    newRecipient.setCheckoutType(req.destination().checkoutType());
                    newRecipient.setChannelCode(req.destination().channelCode());
                    newRecipient.setAccountIdentifier(req.destination().accountIdentifier());
                    newRecipient.setAccountName(req.destination().accountName());
                    paystackRecipient = gatewayRecipientsRepository.save(newRecipient);
                }
            }
        }

        // Comment: Debit up-front — this is the "money is now locked/in-flight"
        // ledger state. If neither gateway accepts the transfer below, it is
        // credited back before returning.
        int debited = ledgerOperations.debit(senderWallet.getWalletId(), req.transfer().amount(), req.transfer().currencyCode());
        if (debited == 0) {
            throw new IllegalArgumentException("Insufficient balance");
        }

        String internalRef = generateReference();
        String reason = (req.transfer().purpose() != null && !req.transfer().purpose().isBlank())
                ? req.transfer().purpose()
                : "Bank Transfer to " + req.recipient().fullName();

        String gatewayUsed = null;
        String status = STATUS_FAILED;
        String externalRef = null;
        String metadata = null;

        // Comment: Attempt Paystack first (primary)
        if (paystackRecipient != null) {
            PaystackTransferResponseDTO transferResponse = paystackServices.initiateBankTransfer(
                    req.transfer().amount(),
                    paystackRecipient.getGatewayRecipientId(),
                    req.transfer().currencyCode(),
                    reason,
                    internalRef
            );
            if (transferResponse != null && transferResponse.status() && transferResponse.data() != null) {
                gatewayUsed = GATEWAY_PAYSTACK;
                status = STATUS_PROCESSING;
                externalRef = transferResponse.data().transferCode();
                // Comment: the `metadata` column is jsonb — must be real JSON,
                // not a bare "key=value" string (both IDs are our own
                // NanoId-generated codes, alphanumeric-only, safe to inline).
                metadata = "{\"customerId\":\"" + paystackCustomer.getGatewayCustomerId()
                        + "\",\"recipientId\":\"" + paystackRecipient.getGatewayRecipientId() + "\"}";
            }
        }

        // Comment: Fail over to Flutterwave — it needs no recipient
        // pre-registration, so this is a direct call using the destination
        // details already on the request.
        if (gatewayUsed == null) {
            log.warn("Paystack unavailable/rejected transfer ref={}, failing over to Flutterwave", internalRef);
            try {
                FlutterwaveTransferResponseDTO fwResponse = flutterwaveClient.initiateTransfer(
                        "BANK",
                        req.destination().channelCode(),
                        req.destination().accountIdentifier(),
                        req.recipient().fullName(),
                        req.transfer().amount(),
                        req.transfer().currencyCode(),
                        reason,
                        internalRef
                );
                if (fwResponse != null && "success".equalsIgnoreCase(fwResponse.status()) && fwResponse.data() != null) {
                    gatewayUsed = GATEWAY_FLUTTERWAVE;
                    status = STATUS_PROCESSING;
                    externalRef = fwResponse.data().id() == null ? null : String.valueOf(fwResponse.data().id());
                }
            } catch (PaymentGatewayException flutterwaveFailure) {
                log.error("Flutterwave failover also failed for ref {}: {}", internalRef, flutterwaveFailure.getMessage());
            }
        }

        // Comment: Both gateways failed to even accept the transfer — refund
        // the sender immediately, money must never just vanish from the ledger.
        if (gatewayUsed == null) {
            ledgerOperations.credit(senderWallet.getWalletId(), req.transfer().amount(), req.transfer().currencyCode());
        }

        // Comment: Construct and persist transaction record (kept even on
        // total failure, so the user sees why in their history)
        TransactionModel tx = new TransactionModel();
        tx.setEntryId(internalRef);
        tx.setAmount(req.transfer().amount());
        tx.setGateway(gatewayUsed == null ? GATEWAY_PAYSTACK : gatewayUsed);
        tx.setStatus(status);
        tx.setTransactionType(TYPE_DEBIT);
        tx.setSenderId(sender.getUserId());
        tx.setReceiverId(sender.getUserId());
        tx.setSenderName(sender.getFirstName() + " " + sender.getLastName());
        tx.setReceiverName(req.recipient().fullName());
        tx.setSourceCurrencyCode(req.transfer().currencyCode());
        tx.setDestinationCurrencyCode(req.destination().currencyCode());
        tx.setPurpose(reason);
        tx.setSenderEmail(sender.getEmail());
        tx.setSenderPhoneNumber(sender.getPhoneNumber());
        tx.setReceiverEmail(req.recipient().email());
        tx.setReceiverPhoneNumber(req.recipient().phoneNumber());
        tx.setInternalReferenceId(internalRef);
        tx.setExternalReferenceId(externalRef == null ? "" : externalRef);
        tx.setDestinationIdentifier(req.destination().accountIdentifier());
        tx.setFailureReason(gatewayUsed == null ? "Payment gateway failed to process transfer, amount refunded" : "");
        tx.setMetadata(metadata);

        tx = ledgerOperations.saveTransaction(tx);

        // Comment: Save in-app notification so the user sees the outcome immediately
        if (gatewayUsed == null) {
            saveNotification(sender, internalRef, "Transfer Failed", "Could not send " + req.transfer().currencyCode() + " " + req.transfer().amount() + " to " + req.recipient().fullName() + ". Your balance has been refunded.");
            throw new PaymentGatewayException("Could not process your transfer right now, please try again later. Your balance has not been affected.");
        }
        saveNotification(sender, internalRef, "Outbound Transfer", "Initiated " + req.transfer().currencyCode() + " " + req.transfer().amount() + " to " + req.recipient().fullName());

        return Optional.of(toDTO(tx));
    }

    // =====================================================================
    // Private helpers
    // =====================================================================

    /** Generates a unique internal reference for the transaction ledger. */
    private String generateReference() {
        return NanoIdGenerator.generate("ZPWT_");
    }

    /** Persists an in-app notification so the user sees the outcome. */
    private void saveNotification(UserModel user, String reference, String title, String message) {
        NotificationModel notification = new NotificationModel();
        notification.setUserId(user.getUserId());
        notification.setReferenceId(reference);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setType("TRANSFER");
        notification.setIsRead(false);
        ledgerOperations.saveNotification(notification);
    }

    /** Maps a persisted {@link TransactionModel} to the API {@link TransactionDTO}. */
    private TransactionDTO toDTO(TransactionModel t) {
        String sign = t.getTransactionType().equalsIgnoreCase(TYPE_CREDIT) ? "+" : "-";
        return new TransactionDTO(
                t.getTransactionId(),
                t.getReceiverId(),
                t.getReceiverEmail(),
                t.getReceiverPhoneNumber(),
                sign + t.getSourceCurrencyCode() + " " + t.getAmount().toPlainString(),
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
                t.getEntryId(),
                null
        );
    }
}
