package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.FlutterwaveTransferResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.OnafriqTransferResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaystackTransferResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.TransferExecuteRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.TransferExecuteResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransferRecipientModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransferRecipientRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
public class TransfersService {

    // NOTE: recipient gateway codes are cached in gateway_recipients so a
    // repeat payout to the same (user, gateway, account, provider) never
    // re-registers the recipient with the gateway.

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final TransferRecipientRepository transferRecipientRepository;
    private final TransferRecipientService transferRecipientService;
    private final PaystackClient paystackClient;
    private final OnafriqClient onafriqClient;
    private final FlutterwaveClient flutterwaveClient;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.pin.pepper}")
    private String pinPepper;
    @Value("${zentrapay.primary-national-gateway}")
    private String primaryNationalGateway;
    @Value("${zentrapay.primary-international-gateway}")
    private String primaryInternationalGateway;
    @Value("${zentrapay.secondary-gateway}")
    private String failoverGateway;

    @Transactional
    public TransferExecuteResponseDTO execute(UUID senderId, TransferExecuteRequestDTO req) {
        UserModel sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (req.pin() == null || req.pin().isBlank()
                || !passwordEncoder.matches(req.pin() + pinPepper, sender.getTransactionPinHash())) {
            throw new IllegalArgumentException("Invalid PIN");
        }

        // Tier-1 recipient: reuse the saved row when recipientId is given,
        // otherwise create (or dedupe) it locally before any gateway call.
        TransferRecipientModel recipient = resolveRecipient(senderId, req);

        // International corridors are parked until the Onafriq integration
        // is completed — reject before any funds move.
        boolean international = !recipient.getCountryCode()
                .equalsIgnoreCase(sender.getCountryCode());
        if (international) {
            throw new IllegalArgumentException("Cross border transfers are not supported at the moment");
        }
        String primaryGateway = primaryNationalGateway;
        String reason = req.reason() == null ? "" : req.reason();

        try {
            return dispatch(primaryGateway, sender, recipient, req, reason, false, false);
        } catch (PaymentGatewayException primaryFailure) {
            log.warn("Primary gateway {} failed for sender {}: {}",
                    primaryGateway, senderId, primaryFailure.getMessage());
            try {
                return dispatch(failoverGateway, sender, recipient, req, reason, international, true);
            } catch (PaymentGatewayException failoverFailure) {
                log.error("Failover gateway {} also failed for sender {}: {}",
                        failoverGateway, senderId, failoverFailure.getMessage());
                throw new PaymentGatewayException(
                        "All payment gateways failed. The payment was not completed. Please try again later.",
                        failoverFailure);
            }
        }
    }

    private TransferRecipientModel resolveRecipient(UUID senderId, TransferExecuteRequestDTO req) {
        if (req.recipientId() != null) {
            TransferRecipientModel recipient = transferRecipientRepository.findById(req.recipientId())
                    .orElseThrow(() -> new ResourceNotFoundException("Recipient not found"));
            if (!senderId.equals(recipient.getUserId())) {
                // Never let a user pay out through another user's recipient.
                throw new IllegalArgumentException("Recipient does not belong to the authenticated user");
            }
            return recipient;
        }
        if (req.newRecipient() == null) {
            throw new IllegalArgumentException("Either recipientId or newRecipient details must be provided");
        }
        return transferRecipientService.createOrReuse(senderId, req.newRecipient());
    }

    // ------------------------------------------------------------------
    // Gateway dispatch
    // ------------------------------------------------------------------

    private TransferExecuteResponseDTO dispatch(
            String gatewayName,
            UserModel sender,
            TransferRecipientModel recipient,
            TransferExecuteRequestDTO req,
            String reason,
            boolean international,
            boolean isFailover) {
        String gateway = GatewayCustomerService.normalizeGateway(gatewayName);
        String reference = "ZPT_" + UUID.randomUUID().toString()
                .replace("-", "").substring(0, 20).toUpperCase();

        // Business rule 3 (a)/(b): an existing PAYSTACK tier-2 token means we
        // go straight to POST /transfer; a missing one registers first (rule c).
        String gatewayRecipientCode = null;
        if (GatewayCustomerService.GATEWAY_PAYSTACK.equals(gateway)) {
            gatewayRecipientCode = transferRecipientService
                    .getOrCreateGatewayRecipientCode(recipient, gateway);
        }

        try {
            return switch (gateway) {
                case GatewayCustomerService.GATEWAY_PAYSTACK -> {
                    PaystackTransferResponseDTO response = paystackClient.initiateTransfer(
                            req.amount(), gatewayRecipientCode, recipient.getCurrencyCode(), reason, reference);
                    String code = response.data() != null ? response.data().transferCode() : null;
                    String status = response.data() != null ? response.data().status() : "processing";
                    yield journal(sender, recipient, req.amount(), reason, gateway, reference,
                            code, status, international, isFailover);
                }
                case GatewayCustomerService.GATEWAY_ONAFRIQ -> {
                    OnafriqTransferResponseDTO response = onafriqClient.initiateTransfer(
                            recipient.getDestinationType(), recipient.getProviderCode(),
                            recipient.getAccountIdentifier(), recipient.getRecipientName(),
                            req.amount(), recipient.getCurrencyCode(), reason, reference);
                    String gatewayRef = response.data() != null ? response.data().reference() : null;
                    String status = response.data() != null && response.data().status() != null
                            ? response.data().status() : "processing";
                    yield journal(sender, recipient, req.amount(), reason, gateway, reference,
                            gatewayRef, status, international, isFailover);
                }
                case GatewayCustomerService.GATEWAY_FLUTTERWAVE -> {
                    FlutterwaveTransferResponseDTO response = flutterwaveClient.initiateTransfer(
                            recipient.getDestinationType(), recipient.getProviderCode(),
                            recipient.getAccountIdentifier(), recipient.getRecipientName(),
                            req.amount(), recipient.getCurrencyCode(), reason, reference);
                    String gatewayRef = response.data() != null ? response.data().reference() : null;
                    String status = response.data() != null && response.data().status() != null
                            ? response.data().status().toLowerCase() : "processing";
                    yield journal(sender, recipient, req.amount(), reason, gateway, reference,
                            gatewayRef, status, international, isFailover);
                }
                default -> throw new PaymentGatewayException("Unsupported gateway: " + gateway);
            };
        } catch (PaymentGatewayException failure) {
            // Journal the failed attempt so payout history shows what happened.
            journal(sender, recipient, req.amount(), reason, gateway, reference,
                    null, "failed", international, isFailover);
            throw failure;
        }
    }

    /** Persists the transaction leg and builds the API response. */
    private TransferExecuteResponseDTO journal(
            UserModel sender,
            TransferRecipientModel recipient,
            java.math.BigDecimal amount,
            String purpose,
            String gateway,
            String reference,
            String gatewayTransferCode,
            String status,
            boolean international,
            boolean isFailover) {
        TransactionModel leg = new TransactionModel();
        leg.setEntryId(reference);
        leg.setAmount(amount);
        leg.setGateway(gateway);
        leg.setStatus(status);
        leg.setTransactionType("debit");
        leg.setSenderId(sender.getUserId());
        leg.setReceiverId(sender.getUserId()); // external payout: no local receiver
        leg.setSenderName(sender.getFirstName() + " " + sender.getLastName());
        leg.setReceiverName(recipient.getRecipientName());
        leg.setSourceCurrencyCode(recipient.getCurrencyCode());
        leg.setDestinationCurrencyCode(recipient.getCurrencyCode());
        leg.setPurpose(purpose);
        leg.setSenderEmail(sender.getEmail());
        leg.setSenderPhoneNumber(sender.getPhoneNumber());
        leg.setReceiverEmail("");
        leg.setReceiverPhoneNumber("");
        leg.setInternalReferenceId(reference);
        leg.setExternalReferenceId(gatewayTransferCode == null ? "" : gatewayTransferCode);
        leg.setDestinationIdentifier(recipient.getAccountIdentifier());
        leg.setFailureReason("failed".equalsIgnoreCase(status) ? "Gateway rejected the transfer" : "");
        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("channel", "bank_transfer");
        metadata.put("gateway", gateway);
        metadata.put("failover", isFailover);
        metadata.put("recipientId", recipient.getRecipientId().toString());
        metadata.put("destinationType", recipient.getDestinationType());
        leg.setMetadata(metadata.toString());
        transactionRepository.save(leg);

        return new TransferExecuteResponseDTO(
                leg.getTransactionId(),
                gateway,
                reference,
                gatewayTransferCode,
                status,
                amount,
                recipient.getCurrencyCode(),
                recipient.getRecipientName(),
                recipient.getAccountIdentifier(),
                !international);
    }
}