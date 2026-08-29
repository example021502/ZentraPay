package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayRecipientsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransferRecipientModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.GatewayRecipientsRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransferRecipientRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.CreateRecipientRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaystackRecipientResponseDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

/**
 * Recipient architecture: tier-1 ({@code transfer_recipients}) is the
 * gateway-agnostic address book; gateway recipient codes are cached lazily
 * per (user, gateway, account, provider) tuple in {@code gateway_recipients}
 * the first time a payout to this destination goes through that gateway.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TransferRecipientService {

    public static final String DESTINATION_BANK = "BANK";
    public static final String DESTINATION_MOBILE_MONEY = "MOBILE_MONEY";

    private final TransferRecipientRepository transferRecipientRepository;
    private final GatewayRecipientsRepository gatewayRecipientsRepository;
    private final PaystackClient paystackClient;

    /**
     * Creates the tier-1 local recipient, reusing an existing row when the
     * same owner already saved this exact destination (same type + account
     * number) so tokens from previous payouts keep applying.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public TransferRecipientModel createOrReuse(UUID userId, CreateRecipientRequestDTO req) {
        String destinationType = normalizeDestinationType(req.destinationType());
        if (req.accountIdentifier() == null || req.accountIdentifier().isBlank()) {
            throw new IllegalArgumentException("Account number is required");
        }

        Optional<TransferRecipientModel> existing = transferRecipientRepository
                .findByUserIdAndDestinationTypeAndAccountIdentifier(userId, destinationType, req.accountIdentifier());
        if (existing.isPresent()) {
            // Keep the mutable display fields fresh but never touch the
            // financial identity (type + account number) of the cached row.
            TransferRecipientModel recipient = existing.get();
            recipient.setRecipientName(req.recipientName());
            recipient.setProviderCode(req.providerCode());
            recipient.setProviderName(req.providerName());
            recipient.setCountryCode(req.countryCode().toUpperCase(Locale.ROOT));
            recipient.setCurrencyCode(req.currencyCode().toUpperCase(Locale.ROOT));
            return transferRecipientRepository.save(recipient);
        }

        TransferRecipientModel recipient = new TransferRecipientModel();
        recipient.setUserId(userId);
        recipient.setRecipientName(req.recipientName());
        recipient.setDestinationType(destinationType);
        recipient.setAccountIdentifier(req.accountIdentifier());
        recipient.setProviderCode(req.providerCode());
        recipient.setProviderName(req.providerName());
        recipient.setCountryCode(req.countryCode().toUpperCase(Locale.ROOT));
        recipient.setCurrencyCode(req.currencyCode().toUpperCase(Locale.ROOT));
        return transferRecipientRepository.save(recipient);
    }

    /**
     * Business rule 3 (a)/(c): look the gateway recipient code up locally
     * first ({@code gateway_recipients} by user + gateway + account +
     * provider). Only call Paystack's /transferrecipient when it is missing,
     * then persist the returned recipient_code. Flutterwave takes
     * destination details inline so it never needs a cached code; Onafriq's
     * contract is pending keys.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public String getOrCreateGatewayRecipientCode(TransferRecipientModel recipient, String gatewayName) {
        String gateway = GatewayCustomerService.normalizeGateway(gatewayName);

        Optional<GatewayRecipientsModel> existing = gatewayRecipientsRepository
                .findByUserIdAndGatewayNameAndAccountIdentifierAndProviderCode(
                        recipient.getUserId().toString(), gateway,
                        recipient.getAccountIdentifier(), recipient.getProviderCode());
        if (existing.isPresent() && !existing.get().getGatewayRecipientCode().isBlank()) {
            return existing.get().getGatewayRecipientCode();
        }

        String gatewayType = paystackRecipientType(recipient.getDestinationType());
        if (!GatewayCustomerService.GATEWAY_PAYSTACK.equals(gateway)) {
            throw new IllegalArgumentException(
                    "No cached recipient code for gateway " + gateway
                            + " and inline registration is not supported for it");
        }

        // Business rule 3 (c): register with the corresponding payload
        // (type "nuban" or "mobile_money"), save the recipient_code.
        PaystackRecipientResponseDTO response = paystackClient.createTransferRecipient(
                gatewayType,
                recipient.getRecipientName(),
                recipient.getAccountIdentifier(),
                recipient.getProviderCode(),
                recipient.getCurrencyCode());

        GatewayRecipientsModel record = existing.orElseGet(GatewayRecipientsModel::new);
        record.setUserId(recipient.getUserId().toString());
        record.setGatewayName(gateway);
        record.setGatewayRecipientCode(response.data().recipientCode());
        record.setChannelType(recipient.getDestinationType());
        record.setGatewayType(gatewayType);
        record.setAccountIdentifier(recipient.getAccountIdentifier());
        record.setProviderCode(recipient.getProviderCode());
        record.setAccountName(recipient.getRecipientName());
        gatewayRecipientsRepository.save(record);
        log.info("Registered recipient {} at {} as {}",
                recipient.getAccountIdentifier(), gateway, record.getGatewayRecipientCode());
        return record.getGatewayRecipientCode();
    }

    /** Maps the neutral destination type to Paystack's native recipient type. */
    public static String paystackRecipientType(String destinationType) {
        return DESTINATION_MOBILE_MONEY.equalsIgnoreCase(destinationType)
                ? "mobile_money"
                : "nuban";
    }

    public static String normalizeDestinationType(String destinationType) {
        if (destinationType == null || destinationType.isBlank()) {
            throw new IllegalArgumentException("Destination type is required (BANK or MOBILE_MONEY)");
        }
        String normalized = destinationType.trim().toUpperCase(Locale.ROOT);
        if (!DESTINATION_BANK.equals(normalized) && !DESTINATION_MOBILE_MONEY.equals(normalized)) {
            throw new IllegalArgumentException(
                    "Destination type must be BANK or MOBILE_MONEY, got: " + destinationType);
        }
        return normalized;
    }
}