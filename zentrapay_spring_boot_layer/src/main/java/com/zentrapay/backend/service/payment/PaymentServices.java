package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.dto.payment.TransactionRequest;
import com.zentrapay.backend.dto.payment.VerifiedAccountDTO;
import com.zentrapay.backend.dto.payment.VerifyAccountRequestDTO;
import com.zentrapay.backend.dto.transaction.TransactionDTO;
import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.Utils;
import com.zentrapay.backend.service.fx.ExchangeRateService;
import com.zentrapay.backend.service.region.SupportedRegionService;
import com.zentrapay.backend.service.transaction.TransactionsQueryService;
import com.zentrapay.backend.service.user.PinService;
import com.zentrapay.backend.service.wallet.VirtualAccountServices;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.hibernate.Transaction;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentServices {

    private final UserRepository userRepository;
    private final VirtualAccountServices virtualAccountServices;
    private final TransactionRepository transactionRepository;
    private final LedgerOperations ledgerOperations;
    private final BankTransferServices bankTransferServices;
    private final ExchangeRateService exchangeRateService;
    private final TransactionsQueryService transactionsQueryService;
    private final PinService pinService;
    private final SupportedRegionService supportedRegionService;
    private final AccountVerificationService accountVerificationService;
    private final DestinationTokenService destinationTokenService;
    private final TransactionRecorder transactionRecorder;


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
    @Transactional
    public TransactionDTO initialize(UUID userId, TransactionRequest req) {
        String txnRef = Utils.getTxnRef();
        log.info("========== PAYMENT START: ref={} sender={} ==========", txnRef, userId);
        Datatypes.TransactionType type = req.resolvedType();
        if (transactionRepository.existsByIdempotency(req.idempotencyKey())) {
            return transactionsQueryService.getTransactionByIdempotencyKeyAndSenderId(req.idempotencyKey(), userId);
        }
        // Same txnRef again = the app retrying: return the first result, never pay twice
        Optional<TransactionModel> existing = transactionRepository.findByInternalReferenceId(txnRef);
        if (existing.isPresent()) {
            return replay(existing.get(), userId);
        }

        UserModel sender = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        try {
            if (sender.getStatus() != Datatypes.UserStatus.ACTIVE) {
                throw new IllegalArgumentException("Your account is " + sender.getStatus() + " at the moment");
            }
            pinService.requireValid(sender, req.pin());
            supportedRegionService.requireUserCountry(sender);
            // The sender can only pay in the default currency of the country they registered in
            supportedRegionService.currenciesFor(sender, null, req.transfer().currencyCode(), null);
            if (req.transfer().currencyType() != null && "crypto".equalsIgnoreCase(req.transfer().currencyType())) {
                throw new IllegalArgumentException("Crypto currencies are not supported at the moment!");
            }

            return switch (type) {
                case P2P_TRANSFER -> sendToWallet(sender, req);
                case CASH_OUT_BANK -> sendToBank(sender, req);
                case CASH_OUT_MOMO -> sendToMobileMoney(sender, req);
                default ->
                        throw new IllegalArgumentException("This payment type is not supported here. Use Top Up to add money to your wallet.");
            };
        } catch (RuntimeException e) {
            // Whatever stopped the payment, the attempt is kept in the user's history as FAILED
            // (a no-op when the payment already has its own transaction row, e.g. a gateway failure after the debit)
            recordFailedSend(sender, req, type, e, txnRef);
            throw e;
        }
    }

    /**
     * Saves a refused / failed send as a FAILED transaction (no money moved, so no ledger entries).
     * Everything is the best effort: reading the destination or the receiver must never hide the real error.
     */
    private void recordFailedSend(UserModel sender, TransactionRequest req, Datatypes.TransactionType type, RuntimeException cause, String txnRef) {
        try {
            TransactionRequest.TransferDetails transfer = req.transfer();
            String sourceCurrency = transfer.currencyCode() == null ? null : transfer.currencyCode().toUpperCase();
            String destinationCurrency = transfer.destinationCurrencyCode() == null || transfer.destinationCurrencyCode().isBlank()
                    ? sourceCurrency : transfer.destinationCurrencyCode().toUpperCase();
            TransactionModel draft = newDraft(sender, req, type, transfer.amount() == null ? BigDecimal.ZERO : money(transfer.amount()),
                    sourceCurrency, destinationCurrency, null);
            if (type == Datatypes.TransactionType.P2P_TRANSFER && req.appUser() != null && req.appUser().userId() != null) {
                userRepository.findById(req.appUser().userId()).ifPresent(r -> {
                    draft.setReceiverId(r.getUserId());
                    draft.setReceiverName(r.getFirstName() + " " + r.getLastName());
                    draft.setReceiverEmail(r.getEmail());
                    draft.setReceiverPhoneNumber(r.getPhoneNumber());
                });
                draft.setDestinationIdentifier(req.appUser().zentag());
            } else if (type == Datatypes.TransactionType.CASH_OUT_BANK && req.bank() != null) {
                applyDestinationForRecord(draft, sender, req.bank().verificationToken());
            } else if (type == Datatypes.TransactionType.CASH_OUT_MOMO && req.mobileMoney() != null) {
                applyDestinationForRecord(draft, sender, req.mobileMoney().verificationToken());
            }
            transactionRecorder.recordFailure(draft, cause.getMessage());
        } catch (RuntimeException e) {
            log.warn("Could not prepare the failed-attempt record for {}: {}", txnRef, e.getMessage());
        }
    }

    // Name and masked number of the verified destination, when the token is still readable
    private void applyDestinationForRecord(TransactionModel draft, UserModel sender, String token) {
        try {
            DestinationTokenService.Destination dest = destinationTokenService.open(sender.getUserId(), token);
            draft.setReceiverName(dest.accountName() == null || dest.accountName().isBlank() ? dest.destinationName() : dest.accountName());
            draft.setDestinationIdentifier(DestinationTokenService.mask(dest.accountNumber()));
        } catch (RuntimeException ignored) {
            // expired / invalid token: the attempt is still recorded, just without a destination
        }
    }

    // The app sent the same txnRef twice: hand back the original transaction (only to its own sender)
    private TransactionDTO replay(TransactionModel existing, UUID userId) {
        if (!userId.equals(existing.getSenderId())) {
            throw new IllegalArgumentException("This transaction reference has already been used");
        }
        log.info("Payment {} already exists ({}) - returning it instead of paying again", existing.getInternalReferenceId(), existing.getStatus());
        return transactionsQueryService.toDto(existing, userId);
    }

    // ==================================================================
    // P2P: ZentraPay wallet -> ZentraPay wallet
    // ==================================================================
    @Transactional
    private TransactionDTO sendToWallet(UserModel sender, TransactionRequest req) {
        log.info("STAGE 1: resolving the receiver wallet");
        if (req.appUser() == null) {
            throw new IllegalArgumentException("Recipient information missing");
        }
        TransactionRequest.TransferDetails transfer = req.transfer();
        BigDecimal amount = money(transfer.amount());
        String sourceCurrency = transfer.currencyCode().toUpperCase();
        String destinationCurrency = transfer.destinationCurrencyCode();
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
        if (!virtualAccountServices.accountExists(receiver.getUserId(), destinationCurrency)) {
            throw new RuntimeException("Receiver does not have an account of type " + destinationCurrency);
        }

        BigDecimal destinationAmount = convertIfNeeded(amount, sourceCurrency, destinationCurrency, transfer.rateId());

        // ==========================================================
        // CHECKING THE SENDER BALANCE
        // ==========================================================
        log.info("STAGE 2: checking the sender account, balance and limits");
        VirtualAccountModel senderAccount = virtualAccountServices.checkBalance(sender.getUserId(), sourceCurrency, amount);
        checkSendLimit(sender, amount);
        checkReceiveLimit(receiver, sender.getUserId(), req);

        // ==========================================================
        // MOVING THE MONEY
        // ==========================================================
        log.info("STAGE 3: moving the money (one database transaction)");
        virtualAccountServices.debit();
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
    public FiatAccountModel resolveReceiverAccount(UUID receiverId, String zentag, String destinationCurrencyCode, boolean checkActiveness) {
        FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(receiverId)
                .orElseThrow(() -> new ResourceNotFoundException("The recipient has no wallet"));

        FiatAccountModel account;
        if (zentag != null && !zentag.isBlank()) {
            account = fiatAccountRepository.findByZentag(zentag.trim())
                    .filter(a -> a.getWalletId().equals(wallet.getWalletId()))
                    .orElseThrow(() -> new ResourceNotFoundException("Recipient account not found"));
            if (!destinationCurrencyCode.equalsIgnoreCase(account.getCurrencyCode())) {
                throw new IllegalArgumentException("The recipient account is in " + account.getCurrencyCode() + ", not " + destinationCurrencyCode.toUpperCase());
            }
        } else {
            account = fiatAccountRepository.findByWalletIdAndCurrencyCode(wallet.getWalletId(), destinationCurrencyCode)
                    .or(() -> fiatAccountRepository.getDefaultAccountByWalletId(wallet.getWalletId()))
                    .orElseThrow(() -> new ResourceNotFoundException("The recipient has no account to receive this payment"));
        }
        if (checkActiveness && !"ACTIVE".equalsIgnoreCase(account.getStatus())) {
            throw new IllegalArgumentException("The recipient account cannot receive money at the moment");
        }
        return account;
    }

    // ==================================================================
    // CASH_OUT_BANK: ZentraPay wallet -> bank account (through a gateway)
    // ==================================================================

    private TransactionDTO sendToBank(UserModel sender, TransactionRequest req) {
        log.info("STAGE 1: reading the verified bank destination");
        TransactionRequest.BankDetails bank = req.bank();
        if (bank == null) {
            throw new IllegalArgumentException("Bank information missing");
        }
        // The destination comes from what the provider confirmed (encrypted token), never from the request body
        DestinationTokenService.Destination dest = destinationTokenService.open(sender.getUserId(), bank.verificationToken());
        if (!"BANK".equals(dest.type())) {
            throw new IllegalArgumentException("Please verify the account again before sending");
        }
        TransactionRequest.TransferDetails transfer = req.transfer();
        BigDecimal amount = money(transfer.amount());
        String sourceCurrency = transfer.currencyCode().toUpperCase();
        String bankCountry = (dest.countryCode() == null || dest.countryCode().isBlank() ? sender.getCountryCode() : dest.countryCode()).toUpperCase();
        requireDomestic(sender, bankCountry, "bank");
        String destinationCurrency = supportedRegionService
                .currenciesFor(sender, bankCountry, sourceCurrency, transfer.destinationCurrencyCode()).destination();
        BigDecimal destinationAmount = convertIfNeeded(amount, sourceCurrency, destinationCurrency, transfer.rateId());
        String purpose = purposeOf(transfer);
        String accountName = dest.accountName();

        log.info("STAGE 2: checking the sender account, balance and limits");
        FiatAccountModel senderAccount = requireSenderAccount(sender, sourceCurrency, amount, true);
        checkSendLimit(sender, amount);

        log.info("STAGE 3: finding a provider for {} / {} (nothing is debited yet)", dest.destinationName(), DestinationTokenService.mask(dest.accountNumber()));
        BankTransferServices.Payout payout = new BankTransferServices.Payout("BANK", sender,
                false, dest.destinationId(), dest.destinationCode(), bankCountry,
                destinationCurrency, dest.accountNumber(), accountName, destinationAmount, purpose,
                // The gateway that verified this account goes first; the payload's gatewayId wins, the token's is the fallback
                bank.gatewayId() != null ? bank.gatewayId() : dest.gatewayId());
        BankTransferServices.Prepared prepared = bankTransferServices.prepare(payout);

        log.info("STAGE 4: debiting the sender");
        TransactionModel draft = newDraft(sender, req, Datatypes.TransactionType.CASH_OUT_BANK, amount, sourceCurrency, destinationCurrency, destinationAmount);
        draft.setReceiverName(accountName);
        // Only the masked number is kept on the transaction; the full number lives with the gateway recipient only
        draft.setDestinationIdentifier(DestinationTokenService.mask(dest.accountNumber()));
        draft.setGatewayId(prepared.gateway().getProviderId());
        TransactionModel debited = ledgerOperations.debitForPayout(draft, senderAccount);

        log.info("STAGE 5: calling the gateway");
        TransactionModel result = bankTransferServices.send(debited, payout, prepared);
        log.info("========== PAYMENT DONE: {} {} ==========", result.getInternalReferenceId(), result.getStatus());
        return transactionsQueryService.toDto(result, sender.getUserId());
    }

    // ==================================================================
    // CASH_OUT_MOMO: ZentraPay wallet -> mobile-money wallet (through a gateway)
    // ==================================================================

    private TransactionDTO sendToMobileMoney(UserModel sender, TransactionRequest req) {
        log.info("STAGE 1: reading the verified mobile money destination");
        TransactionRequest.MobileMoneyDetails momo = req.mobileMoney();
        if (momo == null) {
            throw new IllegalArgumentException("Mobile money information missing");
        }
        DestinationTokenService.Destination dest = destinationTokenService.open(sender.getUserId(), momo.verificationToken());
        if (!"MOBILE_MONEY".equals(dest.type())) {
            throw new IllegalArgumentException("Please verify the wallet again before sending");
        }
        TransactionRequest.TransferDetails transfer = req.transfer();
        BigDecimal amount = money(transfer.amount());
        String sourceCurrency = transfer.currencyCode().toUpperCase();
        String country = (dest.countryCode() == null || dest.countryCode().isBlank() ? sender.getCountryCode() : dest.countryCode()).toUpperCase();
        requireDomestic(sender, country, "mobile money network");
        String destinationCurrency = supportedRegionService
                .currenciesFor(sender, country, sourceCurrency, transfer.destinationCurrencyCode()).destination();
        BigDecimal destinationAmount = convertIfNeeded(amount, sourceCurrency, destinationCurrency, transfer.rateId());
        String phone = dest.accountNumber();
        String accountName = dest.accountName() == null || dest.accountName().isBlank() ? phone : dest.accountName();

        log.info("STAGE 2: checking the sender account, balance and limits");
        FiatAccountModel senderAccount = requireSenderAccount(sender, sourceCurrency, amount, true);
        checkSendLimit(sender, amount);

        log.info("STAGE 3: finding a provider for {} / {} (nothing is debited yet)", dest.destinationName(), DestinationTokenService.mask(phone));
        BankTransferServices.Payout payout = new BankTransferServices.Payout("MOBILE_MONEY", sender,
                false, dest.destinationId(), dest.destinationCode(), country,
                destinationCurrency, phone, accountName, destinationAmount, purposeOf(transfer),
                // Set when a gateway confirmed the wallet name (payload first, then the token); null = normal routing
                momo.gatewayId() != null ? momo.gatewayId() : dest.gatewayId());
        BankTransferServices.Prepared prepared = bankTransferServices.prepare(payout);

        log.info("STAGE 4: debiting the sender");
        TransactionModel draft = newDraft(sender, req, Datatypes.TransactionType.CASH_OUT_MOMO, amount, sourceCurrency, destinationCurrency, destinationAmount);
        draft.setReceiverName(accountName);
        draft.setDestinationIdentifier(DestinationTokenService.mask(phone));
        draft.setGatewayId(prepared.gateway().getProviderId());
        TransactionModel debited = ledgerOperations.debitForPayout(draft, senderAccount);

        log.info("STAGE 5: calling the provider");
        TransactionModel result = bankTransferServices.send(debited, payout, prepared);
        log.info("========== PAYMENT DONE: {} {} ==========", result.getInternalReferenceId(), result.getStatus());
        return transactionsQueryService.toDto(result, sender.getUserId());
    }

    // ==================================================================
    // Account check (no money moves)
    // ==================================================================

    /**
     * Asks the providers who own a bank account / mobile-money wallet in the same country as the sender.
     */
    public VerifiedAccountDTO verifyAccount(UUID userId, VerifyAccountRequestDTO req) {
        UserModel sender = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        supportedRegionService.requireUserCountry(sender);
        String country = (req.countryCode() == null || req.countryCode().isBlank() ? sender.getCountryCode() : req.countryCode()).toUpperCase();
        supportedRegionService.requireCountry(country);
        String number = req.accountNumber().trim();

        if ("MOBILE_MONEY".equalsIgnoreCase(req.destinationType())) {
            Optional<AccountVerificationService.Verified> found =
                    accountVerificationService.verifyMobileMoney(req.destinationId(), req.destinationCode(), number, country);
            String destinationName = found.map(AccountVerificationService.Verified::destinationName)
                    .orElse(req.destinationCode() == null ? "Mobile money" : req.destinationCode());
            String name = found.map(AccountVerificationService.Verified::accountName).orElse(null);
            UUID gatewayId = found.map(AccountVerificationService.Verified::gatewayId).orElse(null);
            String token = destinationTokenService.issue(userId, new DestinationTokenService.Destination(
                    "MOBILE_MONEY", req.destinationId(), req.destinationCode(), country, number, name, destinationName, found.isPresent(), gatewayId));
            return new VerifiedAccountDTO(found.isPresent(), gatewayId, name, DestinationTokenService.mask(number), destinationName, country, token);
        }
        if ("BANK".equalsIgnoreCase(req.destinationType())) {
            AccountVerificationService.Verified v = accountVerificationService.verifyBank(
                    req.destinationId(), req.destinationCode(), number, country);
            String token = destinationTokenService.issue(userId, new DestinationTokenService.Destination(
                    "BANK", req.destinationId(), req.destinationCode(), country, number, v.accountName(), v.destinationName(), true, v.gatewayId()));
            return new VerifiedAccountDTO(true, v.gatewayId(), v.accountName(), DestinationTokenService.mask(number), v.destinationName(), country, token);
        }
        throw new IllegalArgumentException("Destination type must be BANK or MOBILE_MONEY");
    }

    // Payments are domestic: the bank / network must be in the same, supported country as the sender
    private void requireDomestic(UserModel sender, String destinationCountry, String what) {
        if (isCrossBorder(sender.getCountryCode(), destinationCountry)) {
            throw new IllegalArgumentException("That " + what + " is in another country. Please use ZRemit for cross-border transfers.");
        }
        supportedRegionService.requireCountry(destinationCountry);
    }

    // ==================================================================
    // Shared checks and helpers
    // ==================================================================

    // The sender's ACTIVE account in this currency, with enough money (the real guard is the debit itself)
    private FiatAccountModel requireSenderAccount(UserModel sender, String currency, BigDecimal amount, boolean checkBalance) {
        FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(sender.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("No wallet found"));
        FiatAccountModel account = fiatAccountRepository.findByWalletIdAndCurrencyCode(wallet.getWalletId(), currency)
                .orElseThrow(() -> new IllegalArgumentException("You do not have a " + currency + " account yet. Please create one first."));
        if (checkBalance && !"ACTIVE".equalsIgnoreCase(account.getStatus())) {
            throw new IllegalArgumentException("Your " + currency + " account is " + account.getStatus() + " at the moment");
        }
        if (checkBalance && account.getBalance().compareTo(amount) < 0) {
            throw new IllegalArgumentException("Insufficient balance. Please top up your " + currency + " account first");
        }
        return account;
    }

    // KYC send limit: tier 1 (or lower) and tier 2 have a cap, higher tiers do not
    private void checkSendLimit(UserModel sender, BigDecimal amount) {
        short tier = sender.getKycTier();
        BigDecimal limit = tier <= 1 ? tier1SendLimit : tier == 2 ? tier2SendLimit : null;
        if (limit != null && amount.compareTo(limit) > 0) {
            throw new IllegalArgumentException("Limit exceeded. Update your KYC level from tier level " + tier + " in profile settings to continue. Your current KYC level is "
                    + tier + " (" + kycGrade(tier) + ")");
        }
    }

    private void checkReceiveLimit(UserModel receiver, UUID senderId, TransactionRequest req) {
        short tier = receiver.getKycTier();
        BigDecimal limit = tier <= 1 ? tier1ReceiveLimit : tier == 2 ? tier2ReceiveLimit : null;
        if (limit != null && req.transfer().amount().compareTo(limit) > 0) {
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
        draft.setInternalReferenceId(req.txnRef());
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
