package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.dto.payment.GatewayCheckoutResult;
import com.zentrapay.backend.dto.payment.GatewayCustomerDTO;
import com.zentrapay.backend.dto.payment.CheckoutResponseDTO;
import com.zentrapay.backend.dto.payment.GatewayChargeStatus;
import com.zentrapay.backend.dto.payment.TopupVerifyDTO;
import com.zentrapay.backend.entity.GatewayCustomerModel;
import com.zentrapay.backend.entity.GatewayModel;
import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserBankModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.BanksRepository;
import com.zentrapay.backend.repository.UserBankRepository;
import com.zentrapay.backend.repository.TransactionRepository;
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
    private final TransactionRepository transactionRepository;
    private final PaymentWebhookService paymentWebhookService;
    private final UserBankRepository userBankRepository;
    private final BanksRepository banksRepository;
    private final TransactionRecorder transactionRecorder;
    private final tools.jackson.databind.ObjectMapper objectMapper;

    /**
     * Starts a wallet top-up. Two things must be true first: the user has a wallet account in this currency
     * (that is what gets credited) and a linked bank account that holds the same currency (that is where the
     * money comes from). If either is missing the top-up is refused - and the refused attempt is still saved
     * as a FAILED transaction so it shows in the user's history.
     *
     * @return the checkout details the app needs (access code for the Paystack SDK, or a pay-page link)
     */
    public CheckoutResponseDTO startCheckout(UUID userId, BigDecimal amount, String currencyCode) {
        return startCheckout(userId, amount, currencyCode, null);
    }

    /**
     * Same as above, but when {@code only} is given just that gateway is tried (no failover) - the
     * app's top-up screen runs its own Paystack-then-Flutterwave failover.
     */
    public CheckoutResponseDTO startCheckout(UUID userId, BigDecimal amount, String currencyCode, Datatypes.PaymentGateway only) {
        return startCheckout(userId, amount, currencyCode, only, false);
    }

    /**
     * Same as above; with {@code saveCard} the user also asked to keep the card they pay with, so it can be
     * charged next time without a checkout (the card is stored only after this top-up has been credited).
     */
    public CheckoutResponseDTO startCheckout(UUID userId, BigDecimal amount, String currencyCode, Datatypes.PaymentGateway only,
                                             boolean saveCard) {
        log.info("Funding: user {} wants to add {} {}", userId, amount, currencyCode);
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        String currency = currencyCode.toUpperCase();
        BigDecimal money = amount.setScale(2, RoundingMode.HALF_UP);

        // Built up front: if any check below refuses the top-up, this is what gets saved as the FAILED attempt
        TransactionModel draft = new TransactionModel();
        draft.setInternalReferenceId("FUND-" + UUID.randomUUID());
        draft.setTransactionType(Datatypes.TransactionType.CASH_IN_CARD);
        draft.setAmount(money);
        draft.setSourceCurrencyCode(currency);
        draft.setDestinationCurrencyCode(currency);
        draft.setDestinationAmount(money);
        draft.setPurpose("Wallet funding");
        if (saveCard) {
            draft.setMetadata(objectMapper.createObjectNode().put("saveCard", true));
        }
        draft.setReceiverId(userId);
        draft.setReceiverName(user.getFirstName() + " " + user.getLastName());
        draft.setReceiverEmail(user.getEmail());
        draft.setReceiverPhoneNumber(user.getPhoneNumber());

        try {
            if (money.signum() <= 0) {
                throw new IllegalArgumentException("Amount must be greater than zero");
            }
            if (user.getStatus() != Datatypes.UserStatus.ACTIVE) {
                throw new IllegalArgumentException("Your account is " + user.getStatus() + " at the moment");
            }

            // The money will be credited to this account, so it has to exist and be usable
            FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(userId)
                    .orElseThrow(() -> new IllegalArgumentException("No wallet found"));
            FiatAccountModel account = fiatAccountRepository.findByWalletIdAndCurrencyCode(wallet.getWalletId(), currency)
                    .orElseThrow(() -> new IllegalArgumentException("You do not have a " + currency + " account yet. Please create one first."));
            if (!"ACTIVE".equalsIgnoreCase(account.getStatus())) {
                throw new IllegalArgumentException("Your " + currency + " account is " + account.getStatus() + " at the moment");
            }
            draft.setDestinationIdentifier(account.getZentag());

            // ...and the money has to come from one of the user's linked bank accounts in the SAME currency
            UserBankModel bank = fundingBank(userId, currency);
            String bankLabel = bankLabel(bank);
            draft.setSenderName(bankLabel);
            draft.setPurpose("Wallet top-up from " + bankLabel);
        } catch (RuntimeException e) {
            transactionRecorder.recordFailure(draft, e.getMessage());
            throw e;
        }

        // Save the attempt first: the webhook finds it again through the reference we send the gateway
        TransactionModel txn = ledgerOperations.recordFundingAttempt(draft);
        String reference = LedgerOperations.gatewayReference(txn);

        PaymentGatewayException lastError = null;
        for (GatewayModel gateway : gatewaysToTry(only)) {
            try {
                ledgerOperations.assignGateway(txn.getTransactionId(), gateway.getProviderId());
                GatewayCheckoutResult checkout = switch (gatewayServices.nameOf(gateway)) {
                    case PAYSTACK -> paystackServices.initializeCheckout(user.getEmail(), money, currency, reference);
                    case FLUTTERWAVE -> flutterwaveServices.initializeCheckout(user.getEmail(),
                            user.getFirstName() + " " + user.getLastName(), user.getPhoneNumber(), money, currency, reference);
                    default ->
                            throw new PaymentGatewayException("Checkout is not available on " + gateway.getProviderName());
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

    /**
     * The linked bank account a top-up is drawn from: an active link whose currency is the requested one
     * (the primary link first). A link's currency is what the bank reported, else the catalogue bank's
     * currency. No match = the top-up is refused.
     */
    private UserBankModel fundingBank(UUID userId, String currency) {
        return userBankRepository.findByUserId(userId).stream()
                .filter(b -> b.getConnectionStatus() == null || "active".equalsIgnoreCase(b.getConnectionStatus()))
                .filter(b -> currency.equalsIgnoreCase(bankCurrency(b)))
                .min(java.util.Comparator.comparing((UserBankModel b) -> !Boolean.TRUE.equals(b.getPrimary())))
                .orElseThrow(() -> new IllegalArgumentException(
                        "You have no linked bank account in " + currency + ". Link a " + currency
                                + " bank account first to top up your " + currency + " wallet."));
    }

    private String bankCurrency(UserBankModel b) {
        if (b.getCurrencyCode() != null && !b.getCurrencyCode().isBlank()) {
            return b.getCurrencyCode();
        }
        return b.getBankId() == null ? null : banksRepository.findById(b.getBankId()).map(BanksModel::getCurrencyCode).orElse(null);
    }

    // "GTBank ••1234" - what the history shows as the source of the top-up
    private String bankLabel(UserBankModel b) {
        String name = b.getInstitutionName();
        if ((name == null || name.isBlank()) && b.getBankId() != null) {
            name = banksRepository.findById(b.getBankId()).map(BanksModel::getBankName).orElse(null);
        }
        if (name == null || name.isBlank()) {
            name = "Linked bank";
        }
        String digits = b.getLastDigits();
        return digits == null || digits.isBlank() ? name : name + " \u2022\u2022" + digits;
    }

    // The gateways to try for a checkout: all in routing order, or just the one the app asked for
    private java.util.List<GatewayModel> gatewaysToTry(Datatypes.PaymentGateway only) {
        if (only == null) {
            return gatewayServices.gatewaysFor(false);
        }
        return java.util.List.of(gatewayServices.gatewayByName(only));
    }

    /**
     * Where a top-up stands. If the customer has paid but our webhook has not arrived yet, the gateway is
     * asked directly and the result applied exactly as the webhook would have (amount/currency verified,
     * wallet credited once). Only the user who started the top-up can ask.
     */
    public TopupVerifyDTO verifyTopup(UUID userId, String reference) {
        UUID txnId = LedgerOperations.transactionIdFromReference(reference);
        TransactionModel txn = txnId == null ? null : transactionRepository.findById(txnId).orElse(null);
        // Same answer for "does not exist" and "not yours" so references cannot be probed
        if (txn == null || !userId.equals(txn.getReceiverId())
                || txn.getTransactionType() != Datatypes.TransactionType.CASH_IN_CARD) {
            throw new ResourceNotFoundException("Top-up not found");
        }

        if (txn.getStatus() == Datatypes.TransactionStatus.PENDING || txn.getStatus() == Datatypes.TransactionStatus.INITIATED) {
            refreshFromGateway(txn, reference);
            txn = transactionRepository.findById(txnId).orElse(txn);
        }

        String status = switch (txn.getStatus()) {
            case SUCCESS -> "SUCCESS";
            case FAILED, EXPIRED, REVERSED -> "FAILED";
            default -> "PENDING";
        };
        String message = switch (status) {
            case "SUCCESS" -> "Your wallet has been topped up";
            case "FAILED" -> "The payment was not completed";
            default -> "We are waiting for the payment to be confirmed";
        };
        return new TopupVerifyDTO(reference, status, txn.getDestinationAmount() != null ? txn.getDestinationAmount() : txn.getAmount(),
                txn.getDestinationCurrencyCode(), message);
    }

    // Ask the gateway that holds this checkout what happened and apply it like a webhook would
    private void refreshFromGateway(TransactionModel txn, String reference) {
        if (txn.getGatewayId() == null) {
            return;
        }
        try {
            GatewayModel gateway = gatewayServices.gatewayById(txn.getGatewayId());
            GatewayChargeStatus charge = switch (gatewayServices.nameOf(gateway)) {
                case PAYSTACK -> paystackServices.chargeStatus(reference);
                case FLUTTERWAVE -> flutterwaveServices.chargeStatus(reference);
                default -> null;
            };
            if (charge == null) {
                return;
            }
            if (charge.successful()) {
                paymentWebhookService.checkoutPaid(reference, charge.amount(), charge.currency());
            } else if (charge.finalFailure()) {
                paymentWebhookService.checkoutFailed(reference, gateway.getProviderName() + ": checkout not completed");
            }
        } catch (PaymentGatewayException e) {
            // Gateway has no record yet (customer has not got as far as paying) or is unreachable: still pending
            log.info("Funding: could not confirm {} with the gateway yet: {}", reference, e.getMessage());
        }
    }
}
