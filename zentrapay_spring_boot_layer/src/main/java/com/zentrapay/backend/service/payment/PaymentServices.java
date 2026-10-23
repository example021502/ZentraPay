package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.dto.payment.TransactionRequest;
import com.zentrapay.backend.dto.transaction.TransactionTransactionDTO;
import com.zentrapay.backend.entity.FiatAccountModel;
import com.zentrapay.backend.entity.FiatWalletModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.fx.ExchangeRateService;
import com.zentrapay.backend.service.transaction.TransactionsQueryService;
import com.zentrapay.backend.service.user.PinService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

/**
 * Sending money out of a user's wallet. Two kinds of payment:
 * <ul>
 *   <li><b>P2P_TRANSFER</b>  - to another ZentraPay user (same currency or cross currency).
 *       Stays inside our own ledger, so it is one all-or-nothing database transaction.</li>
 *   <li><b>CASH_OUT_BANK</b> - to a bank account through a payment gateway (same currency or
 *       cross currency). Money is debited first, then the gateway is called; if the gateway
 *       refuses, the money is refunded. See BankTransferServices.</li>
 * </ul>
 *
 * <p>This class is deliberately NOT one big database transaction: the slow gateway calls must
 * not hold a database connection open, and the debit has to be committed before the gateway
 * is called. Each step that moves money is its own transaction inside LedgerOperations.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentServices {

    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final TransactionRepository transactionRepository;
    private final GatewayCountriesRepository gatewayCountriesRepository;
    private final LedgerOperations ledgerOperations;
    private final BankTransferServices bankTransferServices;
    private final ExchangeRateService exchangeRateService;
    private final TransactionsQueryService transactionsQueryService;
    private final PinService pinService;

    @Value("${zentrapay.limits.send.tier1}")
    private BigDecimal tier1SendLimit;
    @Value("${zentrapay.limits.send.tier2}")
    private BigDecimal tier2SendLimit;
    @Value("${zentrapay.limits.receive.tier1}")
    private BigDecimal tier1ReceiveLimit;
    @Value("${zentrapay.limits.receive.tier2}")
    private BigDecimal tier2ReceiveLimit;

    // ==================================================================
    // Entry point
    // ==================================================================

    /**
     * Validates a payment request and routes it to the P2P or the bank flow.
     * The signed-in user is always the sender.
     */
    public TransactionTransactionDTO initialize(UUID userId, TransactionRequest req) {
        log.info("========== PAYMENT START: ref={} sender={} ==========", req.TXN_Ref(), userId);
        Datatypes.TransactionType type = req.resolvedType();

        // Same TXN_Ref again = the app retrying: return the first result, never pay twice
        Optional<TransactionModel> existing = transactionRepository.findByInternalReferenceId(req.TXN_Ref());
        if (existing.isPresent()) {
            return replay(existing.get(), userId);
        }

        UserModel sender = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (sender.getStatus() != Datatypes.UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Your account is " + sender.getStatus() + " at the moment");
        }
        pinService.requireValid(sender, req.pin());
        if (req.transfer().currencyType() != null && "crypto".equalsIgnoreCase(req.transfer().currencyType())) {
            throw new IllegalArgumentException("Crypto currencies are not supported at the moment!");
        }

        return switch (type) {
            case P2P_TRANSFER -> sendToWallet(sender, req);
            case CASH_OUT_BANK -> sendToBank(sender, req);
            default -> throw new IllegalArgumentException("This payment type is not supported yet");
        };
    }

    // The app sent the same TXN_Ref twice: hand back the original transaction (only to its own sender)
    private TransactionTransactionDTO replay(TransactionModel existing, UUID userId) {
        if (!userId.equals(existing.getSenderId())) {
            throw new IllegalArgumentException("This transaction reference has already been used");
        }
        log.info("Payment {} already exists ({}) - returning it instead of paying again", existing.getInternalReferenceId(), existing.getStatus());
        return transactionsQueryService.toDto(existing, userId);
    }

    // ==================================================================
    // P2P: ZentraPay wallet -> ZentraPay wallet
    // ==================================================================

    private TransactionTransactionDTO sendToWallet(UserModel sender, TransactionRequest req) {
        log.info("STAGE 1: resolving the receiver wallet");
        if (req.appUser() == null) {
            throw new IllegalArgumentException("Recipient information missing");
        }
        TransactionRequest.TransferDetails transfer = req.transfer();
        BigDecimal amount = money(transfer.amount());
        String sourceCurrency = transfer.currencyCode().toUpperCase();

        UserModel receiver = userRepository.findById(req.appUser().userId())
                .orElseThrow(() -> new ResourceNotFoundException("Recipient not found"));
        if (receiver.getUserId().equals(sender.getUserId())) {
            throw new IllegalArgumentException("You cannot send money to yourself");
        }
        if (receiver.getStatus() != Datatypes.UserStatus.ACTIVE) {
            throw new IllegalArgumentException("The recipient's account cannot receive money at the moment");
        }
        if (isCrossBorder(sender.getCountryCode(), receiver.getCountryCode())) {
            throw new IllegalArgumentException("The recipient is in another country. Please use ZRemit for cross-border transfers.");
        }

        FiatAccountModel receiverAccount = resolveReceiverAccount(receiver, req.appUser().zentag(), sourceCurrency, transfer.destinationCurrencyCode());
        String destinationCurrency = receiverAccount.getCurrencyCode();
        BigDecimal destinationAmount = convertIfNeeded(amount, sourceCurrency, destinationCurrency, transfer.rateId());

        log.info("STAGE 2: checking the sender account, balance and limits");
        FiatAccountModel senderAccount = requireSenderAccount(sender, sourceCurrency, amount);
        checkSendLimit(sender, amount);
        checkReceiveLimit(receiver, destinationAmount);

        log.info("STAGE 3: moving the money (one database transaction)");
        TransactionModel draft = newDraft(sender, req, Datatypes.TransactionType.P2P_TRANSFER, amount, sourceCurrency, destinationCurrency, destinationAmount);
        draft.setReceiverId(receiver.getUserId());
        draft.setReceiverName(receiver.getFirstName() + " " + receiver.getLastName());
        draft.setReceiverEmail(receiver.getEmail());
        draft.setReceiverPhoneNumber(receiver.getPhoneNumber());
        draft.setDestinationIdentifier(receiverAccount.getZentag());

        TransactionModel saved = ledgerOperations.transferBetweenWallets(draft, senderAccount, receiverAccount);
        log.info("========== PAYMENT DONE: {} SUCCESS ==========", saved.getInternalReferenceId());
        return transactionsQueryService.toDto(saved, sender.getUserId());
    }

    /**
     * Finds the receiver's account. If the app gave a zentag, that exact account is used
     * (and must belong to the receiver). Otherwise: the receiver's account in the wanted
     * currency, else their default account.
     */
    private FiatAccountModel resolveReceiverAccount(UserModel receiver, String zentag, String sourceCurrency, String wantedCurrency) {
        FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(receiver.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("The recipient has no wallet"));

        FiatAccountModel account;
        if (zentag != null && !zentag.isBlank()) {
            account = fiatAccountRepository.findByZentag(zentag.trim())
                    .filter(a -> a.getWalletId().equals(wallet.getWalletId()))
                    .orElseThrow(() -> new ResourceNotFoundException("Recipient account not found"));
            if (wantedCurrency != null && !wantedCurrency.isBlank() && !wantedCurrency.equalsIgnoreCase(account.getCurrencyCode())) {
                throw new IllegalArgumentException("The recipient account is in " + account.getCurrencyCode() + ", not " + wantedCurrency.toUpperCase());
            }
        } else {
            String currency = wantedCurrency == null || wantedCurrency.isBlank() ? sourceCurrency : wantedCurrency.toUpperCase();
            account = fiatAccountRepository.findByWalletIdAndCurrencyCode(wallet.getWalletId(), currency)
                    .or(() -> fiatAccountRepository.getDefaultAccountByWalletId(wallet.getWalletId()))
                    .orElseThrow(() -> new ResourceNotFoundException("The recipient has no account to receive this payment"));
        }
        if (!"ACTIVE".equalsIgnoreCase(account.getStatus())) {
            throw new IllegalArgumentException("The recipient account cannot receive money at the moment");
        }
        return account;
    }

    // ==================================================================
    // CASH_OUT_BANK: ZentraPay wallet -> bank account (through a gateway)
    // ==================================================================

    private TransactionTransactionDTO sendToBank(UserModel sender, TransactionRequest req) {
        log.info("STAGE 1: reading the bank details");
        TransactionRequest.BankDetails bank = req.bank();
        if (bank == null) {
            throw new IllegalArgumentException("Bank information missing");
        }
        TransactionRequest.TransferDetails transfer = req.transfer();
        BigDecimal amount = money(transfer.amount());
        String sourceCurrency = transfer.currencyCode().toUpperCase();
        String bankCountry = (bank.countryCode() == null || bank.countryCode().isBlank() ? sender.getCountryCode() : bank.countryCode()).toUpperCase();
        String destinationCurrency = destinationCurrencyForBank(transfer.destinationCurrencyCode(), bankCountry, sourceCurrency);
        BigDecimal destinationAmount = convertIfNeeded(amount, sourceCurrency, destinationCurrency, transfer.rateId());
        String purpose = purposeOf(transfer);

        log.info("STAGE 2: checking the sender account, balance and limits");
        FiatAccountModel senderAccount = requireSenderAccount(sender, sourceCurrency, amount);
        checkSendLimit(sender, amount);

        log.info("STAGE 3: finding a gateway for this bank (nothing is debited yet)");
        BankTransferServices.Payout payout = new BankTransferServices.Payout(sender,
                isCrossBorder(sender.getCountryCode(), bankCountry), bank.bankId(), bank.bankCode(), bankCountry,
                destinationCurrency, bank.accountNumber().trim(), bank.accountName().trim(), destinationAmount, purpose);
        BankTransferServices.Prepared prepared = bankTransferServices.prepare(payout);

        log.info("STAGE 4: debiting the sender");
        TransactionModel draft = newDraft(sender, req, Datatypes.TransactionType.CASH_OUT_BANK, amount, sourceCurrency, destinationCurrency, destinationAmount);
        draft.setReceiverName(bank.accountName().trim());
        draft.setDestinationIdentifier(bank.accountNumber().trim());
        draft.setGatewayId(prepared.gateway().getProviderId());
        TransactionModel debited = ledgerOperations.debitForPayout(draft, senderAccount);

        log.info("STAGE 5: calling the gateway");
        TransactionModel result = bankTransferServices.send(debited, payout, prepared);
        log.info("========== PAYMENT DONE: {} {} ==========", result.getInternalReferenceId(), result.getStatus());
        return transactionsQueryService.toDto(result, sender.getUserId());
    }

    // The currency the bank is paid in: what the app asked for, else the bank country's currency, else the sender's currency
    private String destinationCurrencyForBank(String requested, String bankCountry, String sourceCurrency) {
        if (requested != null && !requested.isBlank()) {
            return requested.toUpperCase();
        }
        return gatewayCountriesRepository.findFirstByCountryCode(bankCountry)
                .map(country -> country.getCurrencyCode())
                .orElse(sourceCurrency);
    }

    // ==================================================================
    // Shared checks and helpers
    // ==================================================================

    // The sender's ACTIVE account in this currency, with enough money (the real guard is the debit itself)
    private FiatAccountModel requireSenderAccount(UserModel sender, String currency, BigDecimal amount) {
        FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(sender.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("No wallet found"));
        FiatAccountModel account = fiatAccountRepository.findByWalletIdAndCurrencyCode(wallet.getWalletId(), currency)
                .orElseThrow(() -> new IllegalArgumentException("You do not have a " + currency + " account yet. Please create one first."));
        if (!"ACTIVE".equalsIgnoreCase(account.getStatus())) {
            throw new IllegalArgumentException("Your " + currency + " account is " + account.getStatus() + " at the moment");
        }
        if (account.getBalance().compareTo(amount) < 0) {
            throw new IllegalArgumentException("Insufficient balance. Please top up your " + currency + " account first");
        }
        return account;
    }

    // KYC send limit: tier 1 (or lower) and tier 2 have a cap, higher tiers do not
    private void checkSendLimit(UserModel sender, BigDecimal amount) {
        short tier = sender.getKycTier();
        BigDecimal limit = tier <= 1 ? tier1SendLimit : tier == 2 ? tier2SendLimit : null;
        if (limit != null && amount.compareTo(limit) > 0) {
            throw new IllegalArgumentException("Limit exceeded. Update your KYC level in profile settings to continue. Your current KYC level is "
                    + tier + " (" + kycGrade(tier) + ")");
        }
    }

    private void checkReceiveLimit(UserModel receiver, BigDecimal amount) {
        short tier = receiver.getKycTier();
        BigDecimal limit = tier <= 1 ? tier1ReceiveLimit : tier == 2 ? tier2ReceiveLimit : null;
        if (limit != null && amount.compareTo(limit) > 0) {
            throw new IllegalArgumentException("The recipient cannot receive this amount yet because of their KYC level (" + kycGrade(tier) + ")");
        }
    }

    private String kycGrade(short tier) {
        return tier <= 1 ? "Low" : tier == 2 ? "Medium" : "High";
    }

    // Cross currency: the amount is converted with the live rate. If the app sent the rate it showed the user, it must still be current.
    private BigDecimal convertIfNeeded(BigDecimal amount, String from, String to, UUID rateId) {
        if (from.equalsIgnoreCase(to)) {
            return amount;
        }
        if (rateId != null) {
            exchangeRateService.assertRateStillCurrent(rateId, from, to);
        }
        return exchangeRateService.convert(amount, from, to);
    }

    // True when the two countries differ
    private boolean isCrossBorder(String senderCountry, String receiverCountry) {
        return !senderCountry.equalsIgnoreCase(receiverCountry);
    }

    // Money is kept to 2 decimals everywhere
    private BigDecimal money(BigDecimal amount) {
        return amount.setScale(2, java.math.RoundingMode.HALF_UP);
    }

    private String purposeOf(TransactionRequest.TransferDetails transfer) {
        return transfer.purpose() == null || transfer.purpose().isBlank() ? "General account transfer" : transfer.purpose().trim();
    }

    // A new, not-yet-saved transaction with the sender and the amounts filled in
    private TransactionModel newDraft(UserModel sender, TransactionRequest req, Datatypes.TransactionType type,
                                      BigDecimal amount, String sourceCurrency, String destinationCurrency, BigDecimal destinationAmount) {
        TransactionModel draft = new TransactionModel();
        draft.setInternalReferenceId(req.TXN_Ref());
        draft.setTransactionType(type);
        draft.setAmount(amount);
        draft.setSourceCurrencyCode(sourceCurrency);
        draft.setDestinationCurrencyCode(destinationCurrency);
        draft.setDestinationAmount(destinationAmount);
        draft.setPurpose(purposeOf(req.transfer()));
        draft.setSenderId(sender.getUserId());
        draft.setSenderName(sender.getFirstName() + " " + sender.getLastName());
        draft.setSenderEmail(sender.getEmail());
        draft.setSenderPhoneNumber(sender.getPhoneNumber());
        return draft;
    }
}
