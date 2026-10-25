package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.dto.payment.GatewayTransferResult;
import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.service.bank.BankCatalogService;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import com.zentrapay.backend.service.gateway.GatewayServices;
import com.zentrapay.backend.service.gateway.OnafriqServices;
import com.zentrapay.backend.service.gateway.PaystackServices;
import com.zentrapay.backend.service.mobilemoney.MobileMoneyCatalogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Sends money to a bank account through the payment gateways, with failover.
 *
 * <p>The payout happens in two steps around the debit (see PaymentServices):
 * <ol>
 *   <li>{@link #prepare} - BEFORE the sender is debited: find the first gateway that can
 *       take this bank account (customer + recipient created on that gateway). If no gateway
 *       can, the user gets an error and nothing has been debited.</li>
 *   <li>{@link #send} - AFTER the debit: call the gateway. If it definitely refuses, try the
 *       next gateway. If every gateway refuses, the sender is refunded.</li>
 * </ol>
 *
 * <p>A gateway that times out (outcome unknown) is NEVER retried elsewhere and the sender
 * is NOT refunded - the transfer may still go through. The payment stays PENDING until the
 * webhook (or the reconciliation job) tells us what happened.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BankTransferServices {

    private final GatewayServices gatewayServices;
    private final LedgerOperations ledgerOperations;
    private final BankCatalogService bankCatalogService;
    private final MobileMoneyCatalogService mobileMoneyCatalogService;
    private final PaystackServices paystackServices;
    private final FlutterwaveServices flutterwaveServices;
    private final OnafriqServices onafriqServices;

    /**
     * Everything a gateway needs to know about the payout. {@code destinationType} is BANK or
     * MOBILE_MONEY; {@code bankId}/{@code bankCode} then hold the bank or the mobile-money network
     * (id and code) and {@code accountNumber} the account number or the wallet phone number.
     */
    public record Payout(String destinationType, UserModel sender, boolean crossBorder, UUID bankId, String bankCode,
                         String countryCode, String currencyCode, String accountNumber, String accountName,
                         BigDecimal amount, String narration) {
        public boolean isMobileMoney() {
            return "MOBILE_MONEY".equalsIgnoreCase(destinationType);
        }
    }

    /**
     * The gateway chosen for the payout and the recipient registered on it.
     */
    public record Prepared(GatewayModel gateway, GatewayRecipientsModel recipient) {
    }

    // ------------------------------------------------------------------
    // Step 1 - before the debit
    // ------------------------------------------------------------------

    /**
     * Finds the first gateway (primary, then failover) on which the sender's customer
     * and this bank recipient can be created. Nothing has been debited yet, so a failure
     * here is a clean error for the user.
     */
    public Prepared prepare(Payout payout) {
        log.info("Bank payout: preparing gateways for {} / {}", payout.bankCode(), payout.accountNumber());
        Optional<BanksModel> bank = payout.isMobileMoney() ? Optional.empty() : findBank(payout);
        PaymentGatewayException lastError = null;

        for (GatewayModel gateway : gatewayServices.gatewaysFor(payout.crossBorder())) {
            try {
                Prepared prepared = prepareOn(gateway, payout, bank);
                if (prepared != null) {
                    return prepared;
                }
            } catch (PaymentGatewayException e) {
                log.warn("Bank payout: {} cannot take this recipient: {}", gateway.getProviderName(), e.getMessage());
                lastError = e;
            }
        }
        throw new PaymentGatewayException(lastError == null
                ? (payout.isMobileMoney() ? "This mobile money network is not supported for transfers right now"
                : "This bank is not supported for transfers right now")
                : "Bank transfers are unavailable right now: " + lastError.getMessage());
    }

    // Customer + recipient on ONE gateway (same gateway for both); null if the gateway has no code for this bank
    private Prepared prepareOn(GatewayModel gateway, Payout payout, Optional<BanksModel> bank) {
        String channelCode = channelCodeFor(gateway, payout, bank);
        if (channelCode == null) {
            log.info("Bank payout: {} has no code for this bank, skipping it", gateway.getProviderName());
            return null;
        }
        GatewayCustomerModel customer = gatewayServices.getOrCreateCustomer(payout.sender(), gateway);
        GatewayRecipientsModel recipient = gatewayServices.getOrCreateRecipient(customer,
                new GatewayServices.Destination(payout.isMobileMoney() ? "MOBILE_MONEY" : "BANK", payout.countryCode(), payout.currencyCode(),
                        channelCode, payout.accountNumber(), payout.accountName()));
        return new Prepared(gateway, recipient);
    }

    // ------------------------------------------------------------------
    // Step 2 - after the debit
    // ------------------------------------------------------------------

    /**
     * Sends the transfer. Returns the transaction as it stands afterward (PENDING or SUCCESS).
     * Throws a PaymentGatewayException after refunding the sender when no gateway could take it.
     */
    public TransactionModel send(TransactionModel txn, Payout payout, Prepared first) {
        log.info("Bank payout: sending {} {} for {}", payout.amount(), payout.currencyCode(), txn.getInternalReferenceId());
        Optional<BanksModel> bank = payout.isMobileMoney() ? Optional.empty() : findBank(payout);
        PaymentGatewayException lastError = null;

        // First the gateway we already prepared, then the others in routing order
        List<GatewayModel> gateways = gatewayServices.gatewaysFor(payout.crossBorder()).stream()
                .filter(g -> !g.getProviderId().equals(first.gateway().getProviderId()))
                .collect(java.util.stream.Collectors.toCollection(java.util.ArrayList::new));
        gateways.add(0, first.gateway());

        for (GatewayModel gateway : gateways) {
            // Customer + recipient on this gateway (any problem here means the transfer was never sent)
            Prepared prepared;
            try {
                prepared = gateway.getProviderId().equals(first.gateway().getProviderId())
                        ? first
                        : prepareOn(gateway, payout, bank);
            } catch (PaymentGatewayException e) {
                log.warn("Bank payout: {} cannot take this recipient: {}", gateway.getProviderName(), e.getMessage());
                lastError = e;
                continue;
            }
            if (prepared == null) {
                continue;
            }

            // The transfer itself
            try {
                ledgerOperations.assignGateway(txn.getTransactionId(), gateway.getProviderId());
                log.info("=================== MAKING THE TRANSFER ON GATEWAY :: {} ===============", gateway.getProviderName());
                GatewayTransferResult result = transferVia(gateway, prepared.recipient(), payout, LedgerOperations.gatewayReference(txn));
                log.info("THE GATEWAY RESULTS ARE:: {}", result);
                log.info("Bank payout: {} accepted {} (code {}, settled {})", gateway.getProviderName(),
                        txn.getInternalReferenceId(), result.gatewayCode(), result.settled());
                return ledgerOperations.markSubmitted(txn.getTransactionId(), gateway.getProviderId(), result.settled());

            } catch (PaymentGatewayException e) {
                if (e.isOutcomeUnknown()) {
                    // The gateway may have sent the money. Do not refund, do not try another gateway.
                    log.warn("Bank payout: {} outcome UNKNOWN for {} - keeping it PENDING: {}",
                            gateway.getProviderName(), txn.getInternalReferenceId(), e.getMessage());
                    return ledgerOperations.markSubmitted(txn.getTransactionId(), gateway.getProviderId(), false);
                }
                log.warn("Bank payout: {} refused {}: {}", gateway.getProviderName(), txn.getInternalReferenceId(), e.getMessage());
                lastError = e;
            }
        }

        // Every gateway refused: give the money back
        ledgerOperations.refund(txn.getTransactionId(), false, lastError == null ? "No gateway could take this transfer" : lastError.getMessage());
        throw new PaymentGatewayException("The transfer could not be completed and your money has been returned to your wallet.");
    }

    // Calls the right gateway's transfer API
    private GatewayTransferResult transferVia(GatewayModel gateway, GatewayRecipientsModel recipient, Payout payout, String reference) {
        return switch (gatewayServices.nameOf(gateway)) {
            case PAYSTACK -> paystackServices.sendTransfer(payout.amount(), recipient.getGatewayRecipientCode(),
                    payout.currencyCode(), payout.narration(), reference);
            case FLUTTERWAVE -> flutterwaveServices.sendTransfer(payout.amount(), recipient.getChannelCode(),
                    recipient.getAccountIdentifier(), recipient.getAccountName(), payout.currencyCode(), payout.narration(), reference);
            case ONAFRIQ -> onafriqServices.sendTransfer(payout.amount(), recipient.getGatewayRecipientCode(),
                    payout.currencyCode(), payout.narration(), reference);
        };
    }

    // ------------------------------------------------------------------
    // Bank code per gateway
    // ------------------------------------------------------------------

    // The bank the app picked, from our bank catalogue
    private Optional<BanksModel> findBank(Payout payout) {
        return bankCatalogService.findBank(payout.bankId(), payout.bankCode(), payout.countryCode());
    }

    /**
     * The same bank has a different code on each gateway, so every gateway gets ITS code for the
     * bank. Returns null when that gateway has no matching bank (the gateway is then skipped).
     */
    private String channelCodeFor(GatewayModel gateway, Payout payout, Optional<BanksModel> bank) {
        if (payout.isMobileMoney()) {
            return mobileMoneyCode(gateway, payout);
        }
        if (bank.isEmpty()) {
            // Not in our catalogue: trust the code the app sent, but only on the primary gateway
            boolean isPrimary = gatewayServices.gatewaysFor(payout.crossBorder()).get(0).getProviderId().equals(gateway.getProviderId());
            return isPrimary ? payout.bankCode() : null;
        }
        return bankCatalogService.codeOnGateway(bank.get(), gateway.getProviderName(), payout.countryCode());
    }

    // The mobile-money network's code on this gateway (null when the gateway does not list it)
    private String mobileMoneyCode(GatewayModel gateway, Payout payout) {
        return mobileMoneyCatalogService.findProvider(payout.bankId(), payout.bankCode(), payout.countryCode())
                .map(network -> mobileMoneyCatalogService.codeOnGateway(network, gateway.getProviderName()))
                .orElse(null);
    }
}
