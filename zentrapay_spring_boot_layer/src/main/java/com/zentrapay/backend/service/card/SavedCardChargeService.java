package com.zentrapay.backend.service.card;

import com.zentrapay.backend.dto.payment.GatewayChargeStatus;
import com.zentrapay.backend.dto.payment.TopupVerifyDTO;
import com.zentrapay.backend.entity.GatewayModel;
import com.zentrapay.backend.entity.SavedCardModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import com.zentrapay.backend.service.gateway.GatewayServices;
import com.zentrapay.backend.service.gateway.PaystackServices;
import com.zentrapay.backend.service.payment.LedgerOperations;
import com.zentrapay.backend.service.payment.PaymentWebhookService;
import com.zentrapay.backend.service.payment.TransactionRecorder;
import com.zentrapay.backend.service.payment.WalletFundingService;
import com.zentrapay.backend.service.user.PinService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.UUID;

/**
 * Tops up the wallet by charging a card the user saved earlier - no checkout page, so the user's
 * transaction PIN is what authorises it.
 *
 * <p>The card itself is the source of the money (unlike a checkout top-up, no linked bank is needed).
 * Like every funding, nothing is credited until the amount the gateway reports has been checked against
 * the request ({@link PaymentWebhookService#checkoutPaid}); a charge the gateway has not settled yet stays
 * PENDING and is finished by the webhook or by the app's verify call. Every refusal or failure is saved as
 * a FAILED transaction so it shows in the user's history.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SavedCardChargeService {

    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final PinService pinService;
    private final CardVaultService cardVaultService;
    private final GatewayServices gatewayServices;
    private final PaystackServices paystackServices;
    private final FlutterwaveServices flutterwaveServices;
    private final LedgerOperations ledgerOperations;
    private final PaymentWebhookService paymentWebhookService;
    private final TransactionRecorder transactionRecorder;
    private final WalletFundingService walletFundingService;

    /**
     * @return where the top-up stands right after the charge (SUCCESS, PENDING or FAILED)
     */
    public TopupVerifyDTO chargeCard(UUID userId, UUID cardId, BigDecimal amount, String currencyCode, String pin) {
        log.info("Card charge: user {} tops up {} {} from a saved card", userId, amount, currencyCode);
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        String currency = currencyCode.toUpperCase();
        BigDecimal money = amount.setScale(2, RoundingMode.HALF_UP);

        TransactionModel draft = new TransactionModel();
        draft.setInternalReferenceId("FUND-" + UUID.randomUUID());
        draft.setTransactionType(Datatypes.TransactionType.CASH_IN_CARD);
        draft.setAmount(money);
        draft.setSourceCurrencyCode(currency);
        draft.setDestinationCurrencyCode(currency);
        draft.setDestinationAmount(money);
        draft.setPurpose("Wallet top-up from a saved card");
        draft.setReceiverId(userId);
        draft.setReceiverName(user.getFirstName() + " " + user.getLastName());
        draft.setReceiverEmail(user.getEmail());
        draft.setReceiverPhoneNumber(user.getPhoneNumber());

        SavedCardModel card;
        GatewayModel gateway;
        try {
            card = cardVaultService.activeCard(userId, cardId);
            draft.setSenderName(CardVaultService.label(card));
            draft.setPurpose("Wallet top-up from " + CardVaultService.label(card));

            if (money.signum() <= 0) {
                throw new IllegalArgumentException("Amount must be greater than zero");
            }
            if (user.getStatus() != Datatypes.UserStatus.ACTIVE) {
                throw new IllegalArgumentException("Your account is " + user.getStatus() + " at the moment");
            }
            pinService.requireValid(user, pin);
            if (CardVaultService.isExpired(card)) {
                throw new IllegalArgumentException("This card has expired. Please pay with a new card.");
            }

            FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(userId)
                    .orElseThrow(() -> new IllegalArgumentException("No wallet found"));
            FiatAccountModel account = fiatAccountRepository.findByWalletIdAndCurrencyCode(wallet.getWalletId(), currency)
                    .orElseThrow(() -> new IllegalArgumentException("You do not have a " + currency + " account yet. Please create one first."));
            if (!"ACTIVE".equalsIgnoreCase(account.getStatus())) {
                throw new IllegalArgumentException("Your " + currency + " account is " + account.getStatus() + " at the moment");
            }
            draft.setDestinationIdentifier(account.getZentag());

            // A token only works on the gateway that issued it
            gateway = gatewayServices.gatewayByName(Datatypes.PaymentGateway.valueOf(card.getGateway()));
        } catch (RuntimeException e) {
            transactionRecorder.recordFailure(draft, e.getMessage());
            throw e;
        }

        TransactionModel txn = ledgerOperations.recordFundingAttempt(draft);
        String reference = LedgerOperations.gatewayReference(txn);
        ledgerOperations.assignGateway(txn.getTransactionId(), gateway.getProviderId());

        GatewayChargeStatus result;
        try {
            String token = cardVaultService.tokenOf(card);
            result = switch (gatewayServices.nameOf(gateway)) {
                case PAYSTACK -> paystackServices.chargeSavedCard(token, user.getEmail(), money, currency, reference);
                case FLUTTERWAVE -> flutterwaveServices.chargeSavedCard(token, user.getEmail(),
                        user.getCountryCode() == null ? "NG" : user.getCountryCode().toUpperCase(), money, currency, reference);
                default -> throw new PaymentGatewayException("Cards cannot be charged on " + gateway.getProviderName());
            };
        } catch (PaymentGatewayException e) {
            if (e.isOutcomeUnknown()) {
                // The charge may have gone through: leave it PENDING, the webhook / verify call settles it
                log.warn("Card charge {}: outcome unknown ({})", reference, e.getMessage());
                return walletFundingService.verifyTopup(userId, reference);
            }
            ledgerOperations.failFunding(txn.getTransactionId(), "Card charge refused: " + e.getMessage());
            throw new PaymentGatewayException("Your card could not be charged. Please try another way to pay.");
        }

        if (result.successful()) {
            paymentWebhookService.checkoutPaid(reference, result.amount(), result.currency());
            cardVaultService.markUsed(card.getId());
        } else if (result.finalFailure()) {
            ledgerOperations.failFunding(txn.getTransactionId(), "Your card was declined");
        }
        // otherwise the gateway has not settled it yet: still PENDING

        return walletFundingService.verifyTopup(userId, reference);
    }
}
