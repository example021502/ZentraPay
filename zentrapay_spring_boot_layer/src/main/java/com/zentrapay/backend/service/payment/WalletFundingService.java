package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.dto.payment.GatewayCheckoutResult;
import com.zentrapay.backend.dto.payment.GatewayCustomerDTO;
import com.zentrapay.backend.dto.payment.CheckoutResponseDTO;
import com.zentrapay.backend.entity.FiatAccountModel;
import com.zentrapay.backend.entity.FiatWalletModel;
import com.zentrapay.backend.entity.GatewayCustomerModel;
import com.zentrapay.backend.entity.GatewayModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.FiatAccountRepository;
import com.zentrapay.backend.repository.FiatWalletRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import com.zentrapay.backend.service.gateway.GatewayServices;
import com.zentrapay.backend.service.gateway.PaystackServices;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.UUID;

/**
 * Money coming IN: the user tops up their wallet through a hosted gateway checkout.
 *
 * <p>Flow: we save a PENDING CASH_IN_CARD transaction, ask the gateway (Paystack first,
 * Flutterwave as failover) for a checkout, and hand the checkout details to the app.
 * Nothing is credited here. When the customer pays, the gateway webhook (or the reconciliation
 * job) calls LedgerOperations.creditFunding, which verifies the amount and credits the wallet.
 *
 * <p>This class also exposes "get or create my customer on gateway X", used by the app's
 * /paystack/customer and /flutterwave/customer calls.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class WalletFundingService {

    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final LedgerOperations ledgerOperations;
    private final GatewayServices gatewayServices;
    private final PaystackServices paystackServices;
    private final FlutterwaveServices flutterwaveServices;

    /**
     * Starts a wallet top-up. The user must already have an account in this currency.
     *
     * @return the checkout details the app needs (access code for the Paystack SDK, or a pay-page link)
     */
    public CheckoutResponseDTO startCheckout(UUID userId, BigDecimal amount, String currencyCode) {
        log.info("Funding: user {} wants to add {} {}", userId, amount, currencyCode);
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        String currency = currencyCode.toUpperCase();
        BigDecimal money = amount.setScale(2, RoundingMode.HALF_UP);
        if (money.signum() <= 0) {
            throw new IllegalArgumentException("Amount must be greater than zero");
        }

        // The money will be credited to this account, so it has to exist and be usable
        FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("No wallet found"));
        FiatAccountModel account = fiatAccountRepository.findByWalletIdAndCurrencyCode(wallet.getWalletId(), currency)
                .orElseThrow(() -> new IllegalArgumentException("You do not have a " + currency + " account yet. Please create one first."));
        if (!"ACTIVE".equalsIgnoreCase(account.getStatus())) {
            throw new IllegalArgumentException("Your " + currency + " account is " + account.getStatus() + " at the moment");
        }

        // Save the attempt first: the webhook finds it again through the reference we send the gateway
        TransactionModel draft = new TransactionModel();
        draft.setInternalReferenceId("FUND-" + UUID.randomUUID());
        draft.setTransactionType(Datatypes.TransactionType.CASH_IN_CARD);
        draft.setAmount(money);
        draft.setSourceCurrencyCode(currency);
        draft.setDestinationCurrencyCode(currency);
        draft.setDestinationAmount(money);
        draft.setPurpose("Wallet funding");
        draft.setReceiverId(userId);
        draft.setReceiverName(user.getFirstName() + " " + user.getLastName());
        draft.setReceiverEmail(user.getEmail());
        draft.setReceiverPhoneNumber(user.getPhoneNumber());
        draft.setDestinationIdentifier(account.getZentag());
        TransactionModel txn = ledgerOperations.recordFundingAttempt(draft);
        String reference = LedgerOperations.gatewayReference(txn);

        PaymentGatewayException lastError = null;
        for (GatewayModel gateway : gatewayServices.gatewaysFor(false)) {
            try {
                ledgerOperations.assignGateway(txn.getTransactionId(), gateway.getProviderId());
                GatewayCheckoutResult checkout = switch (gatewayServices.nameOf(gateway)) {
                    case PAYSTACK -> paystackServices.initializeCheckout(user.getEmail(), money, currency, reference);
                    case FLUTTERWAVE -> flutterwaveServices.initializeCheckout(user.getEmail(),
                            user.getFirstName() + " " + user.getLastName(), user.getPhoneNumber(), money, currency, reference);
                    default -> throw new PaymentGatewayException("Checkout is not available on " + gateway.getProviderName());
                };
                return new CheckoutResponseDTO(checkout.accessCode(), reference, checkout.checkoutUrl(), gateway.getProviderName());
            } catch (PaymentGatewayException e) {
                log.warn("Funding: {} could not start the checkout: {}", gateway.getProviderName(), e.getMessage());
                lastError = e;
                if (e.isOutcomeUnknown()) {
                    // A checkout might exist on that gateway; the reconciliation job will sort it out
                    break;
                }
            }
        }

        ledgerOperations.failFunding(txn.getTransactionId(), lastError == null ? "No gateway available" : lastError.getMessage());
        throw new PaymentGatewayException("We could not start the payment right now. Please try again in a moment.");
    }

    /**
     * Returns the signed-in user's customer on the given gateway, creating it on the gateway
     * the first time. The identity always comes from the logged-in user, never from the request.
     */
    public GatewayCustomerDTO customerOn(UUID userId, Datatypes.PaymentGateway gatewayName) {
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        GatewayModel gateway = gatewayServices.gatewayByName(gatewayName);
        GatewayCustomerModel customer = gatewayServices.getOrCreateCustomer(user, gateway);
        return new GatewayCustomerDTO(customer.getId(), customer.getGatewayCustomerId(), customer.getEmail(),
                user.getFirstName(), user.getLastName(), user.getPhoneNumber());
    }
}
