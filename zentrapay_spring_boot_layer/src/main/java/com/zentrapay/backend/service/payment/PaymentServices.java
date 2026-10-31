package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.dto.payment.GatewayCheckoutResult;
import com.zentrapay.backend.dto.payment.TransactionRequest;
import com.zentrapay.backend.dto.payment.VerifiedAccountDTO;
import com.zentrapay.backend.dto.payment.VerifyAccountRequestDTO;
import com.zentrapay.backend.dto.transaction.TransactionTransactionDTO;
import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.NanoIdGenerator;
import com.zentrapay.backend.service.fx.ExchangeRateService;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import com.zentrapay.backend.service.gateway.PaystackServices;
import com.zentrapay.backend.service.region.SupportedRegionService;
import com.zentrapay.backend.service.transaction.TransactionsQueryService;
import com.zentrapay.backend.service.user.PinService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.print.DocFlavor;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
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
 *   <li><b>CASH_OUT_MOMO</b> - to a mobile-money wallet, same engine as the bank payout.</li>
 * </ul>
 *
 * <p>Every payment here is DOMESTIC: the sender, the bank / network and the receiver are in the
 * same, supported country. Cross-border sends belong to ZRemit. Before a bank or mobile-money
 * payment is debited, the providers are asked who owns the account (AccountVerificationService).
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
    private final SupportedRegionService supportedRegionService;
    private final PaystackServices paystackServices;
    private final FlutterwaveServices flutterwaveServices;
    private final AccountVerificationService accountVerificationService;

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
        supportedRegionService.requireUserCountry(sender);
        supportedRegionService.requireCurrency(req, sender.getUserId());
        if (req.transfer().currencyType() != null && "crypto".equalsIgnoreCase(req.transfer().currencyType())) {
            throw new IllegalArgumentException("Crypto currencies are not supported at the moment!");
        }

        return switch (type) {
            case P2P_TRANSFER -> sendToWallet(sender, req);
            case CASH_OUT_BANK -> sendToBank(sender, req);
            case CASH_OUT_MOMO -> sendToMobileMoney(sender, req);
            case WALLET_FUNDING -> fundWallet(sender, req);
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
            FiatAccountModel receiverAccount = resolveReceiverAccount(receiver.getUserId(), req.appUser().zentag(), req.transfer().destinationCurrencyCode(), false);
            Map<String, Object> receiverInfo = draftFailedReceiverInfo(receiver.getFirstName() + " " + receiver.getLastName(), receiver.getEmail(), receiver.getPhoneNumber(), "Cross border payments are not allowed at the moment", receiver.getUserId(), receiverAccount.getAccountId(), receiverAccount.getZentag());
            Map<String, Object> failedTxn = draftFailed(sender.getUserId(), req, receiverInfo);
            saveFailedTransaction(failedTxn);
            throw new IllegalArgumentException("The recipient is in another country. Please use ZRemit for cross-border transfers.");
        }

        FiatAccountModel receiverAccount = resolveReceiverAccount(receiver.getUserId(), req.appUser().zentag(), transfer.destinationCurrencyCode(), true);
        String destinationCurrency = receiverAccount.getCurrencyCode();
        BigDecimal destinationAmount = convertIfNeeded(amount, sourceCurrency, destinationCurrency, transfer.rateId());

        log.info("STAGE 2: checking the sender account, balance and limits");
        FiatAccountModel senderAccount = requireSenderAccount(sender, sourceCurrency, amount, true);
        checkSendLimit(sender, amount);
        checkReceiveLimit(receiver, sender.getUserId(), req);

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
     * DRAFT FAILED RECEIVER INFORMATION AND BASE INFO
     */

    public Map<String, Object> draftFailedReceiverInfo(String name, String email, String phoneNumber, String failureReason, UUID receiverId, UUID receiverAccountId, String receiverIdentifier) {
        Map<String, Object> data = new HashMap<>();
        data.put("receiverName", name);
        data.put("receiverId", receiverId);
        data.put("receiverAccountId", receiverAccountId);
        data.put("receiverEmail", email);
        data.put("receiverPhoneNumber", phoneNumber);
        data.put("failureReason", failureReason);
        data.put("receiverIdentifier", receiverIdentifier);

        return data;
    }

    /**
     * Saving failed transactions
     */
    public void saveFailedTransaction(Map<String, Object> info) {
        // EXTRACTING THE MAPPED FAILED TRANSACTION INFORMATION ===========

        Datatypes.TransactionType t_type = (Datatypes.TransactionType) info.get("t_type");
        String senderName = (String) info.get("senderName");
        String entryId = NanoIdGenerator.generate("ENT_");
        String failureReason = (String) info.get("failureReason");
        String senderEmail = (String) info.get("senderEmail");
        String senderPhoneNumber = (String) info.get("senderPhoneNumber");
        UUID senderId = UUID.fromString(info.get("senderId").toString());
        UUID receiverId = UUID.fromString(info.get("receiverId").toString());
        String receiverIdentifier = (String) info.get("receiverIdentifier");
        String sourceCurrencyCode = (String) info.get("sourceCurrencyCode");
        String destinationCurrencyCode = (String) info.get("destinationCurrencyCode");
        String receiverName = (String) info.get("receiverName");
        String receiverEmail = (String) info.get("receiverEmail");
        String receiverPhoneNumber = (String) info.get("receiverPhoneNumber");
        BigDecimal amount = (BigDecimal) info.get("amount");
        BigDecimal destinationAmount = (BigDecimal) info.get("destinationAmount");
        String purpose = (String) info.get("purpose");
        String internalReferenceId = (String) info.get("internalReferenceId");
        UUID senderAccountId = UUID.fromString(info.get("senderAccountId").toString());
        UUID receiverAccountId = UUID.fromString(info.get("receiverAccountId").toString());

        // SAVING THE FAILED TRANSACTION ========

        TransactionModel t = new TransactionModel();
        t.setFailureReason(failureReason);
        t.setSenderName(senderName);
        t.setSenderId(senderId);
        t.setSenderPhoneNumber(senderPhoneNumber);
        t.setSenderEmail(senderEmail);
        t.setStatus(Datatypes.TransactionStatus.FAILED);
        t.setSourceCurrencyCode(sourceCurrencyCode);
        t.setDestinationCurrencyCode(destinationCurrencyCode);
        t.setTransactionType(t_type);
        t.setPurpose(purpose);
        t.setEntryId(entryId);
        t.setReceiverName(receiverName);
        t.setReceiverId(receiverId);
        t.setReceiverEmail(receiverEmail);
        t.setReceiverPhoneNumber(receiverPhoneNumber);
        t.setDestinationIdentifier(receiverIdentifier);
        t.setInternalReferenceId(internalReferenceId);
        t.setAmount(amount);
        t.setDestinationAmount(destinationAmount);
        TransactionModel t_saved = transactionRepository.save(t);

        // DEBIT ENTRY
        ledgerOperations.writeEntry(t_saved.getTransactionId(), entryId + "_DEBIT", senderAccountId, Datatypes.LedgerEntryType.DEBIT, amount, sourceCurrencyCode, purpose);
        // CREDIT ENTRY
        ledgerOperations.writeEntry(t_saved.getTransactionId(), entryId + "_CREDIT", receiverAccountId, Datatypes.LedgerEntryType.CREDIT, destinationAmount, destinationCurrencyCode, purpose);

    }

    /**
     * DRAFT FAILED TRANSACTION INFO
     */
    public Map<String, Object> draftFailed(UUID senderId, TransactionRequest req, Map<String, Object> receiverInfo) {

        UserModel sender = userRepository.getUserByUserId(senderId).orElseThrow(() -> new RuntimeException("User not found"));
        String senderName = sender.getFirstName() + " " + sender.getLastName();
        FiatAccountModel senderAccount = requireSenderAccount(sender, req.transfer().currencyCode(), req.transfer().amount(), false);
        receiverInfo.put("senderName", senderName);
        receiverInfo.put("t_type", req.transactionType());
        receiverInfo.put("senderEmail", sender.getEmail());
        receiverInfo.put("senderPhoneNumber", sender.getPhoneNumber());
        receiverInfo.put("senderId", sender.getUserId());
        receiverInfo.put("sourceCurrencyCode", req.transfer().currencyCode());
        receiverInfo.put("destinationCurrencyCode", req.transfer().destinationCurrencyCode());
        receiverInfo.put("amount", req.transfer().amount());
        receiverInfo.put("purpose", purposeOf(req.transfer()));
        receiverInfo.put("internalReferenceId", req.TXN_Ref());
        receiverInfo.put("senderAccountId", senderAccount.getAccountId());

        return receiverInfo;
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
        requireDomestic(sender, bankCountry, "bank");
        String destinationCurrency = destinationCurrencyForBank(transfer.destinationCurrencyCode(), bankCountry, sourceCurrency);
        supportedRegionService.requireCurrency(req, sender.getUserId());
        BigDecimal destinationAmount = convertIfNeeded(amount, sourceCurrency, destinationCurrency, transfer.rateId());
        String purpose = purposeOf(transfer);

        log.info("STAGE 2: checking the sender account, balance and limits");
        FiatAccountModel senderAccount = requireSenderAccount(sender, sourceCurrency, amount, true);
        checkSendLimit(sender, amount);

        log.info("STAGE 3: asking the payment providers who owns the bank account (nothing is debited yet)");
        AccountVerificationService.Verified verified = accountVerificationService.verifyBank(
                bank.bankId(), bank.bankCode(), bank.accountNumber().trim(), bankCountry);
        String accountName = verified.accountName();

        log.info("STAGE 3b: finding a provider for this bank (nothing is debited yet)");
        BankTransferServices.Payout payout = new BankTransferServices.Payout("BANK", sender,
                false, bank.bankId(), bank.bankCode(), bankCountry,
                destinationCurrency, bank.accountNumber().trim(), accountName, destinationAmount, purpose);
        BankTransferServices.Prepared prepared = bankTransferServices.prepare(payout);

        log.info("STAGE 4: debiting the sender");
        TransactionModel draft = newDraft(sender, req, Datatypes.TransactionType.CASH_OUT_BANK, amount, sourceCurrency, destinationCurrency, destinationAmount);
        draft.setReceiverName(accountName);
        draft.setDestinationIdentifier(bank.accountNumber().trim());
        draft.setGatewayId(prepared.gateway().getProviderId());
        TransactionModel debited = ledgerOperations.debitForPayout(draft, senderAccount);

        log.info("STAGE 5: calling the gateway");
        TransactionModel result = bankTransferServices.send(debited, payout, prepared);
        log.info("========== PAYMENT DONE: {} {} ==========", result.getInternalReferenceId(), result.getStatus());
        return transactionsQueryService.toDto(result, sender.getUserId());
    }

    // ==================================================================
    // CASH_IN - user funding the wallet account - from bank or other sources
    // ==================================================================

    private TransactionTransactionDTO fundWallet(UserModel sender, TransactionRequest req) {
        log.info("========== WALLET FUNDING START: sender={} ==========", sender.getUserId());

        // ────── 1. VALIDATION ──────
        TransactionRequest.TransferDetails transfer = req.transfer();
        BigDecimal amount = money(transfer.amount());
        String sourceCurrency = transfer.currencyCode().toUpperCase();

        if (amount.signum() <= 0) {
            throw new IllegalArgumentException("Amount must be greater than zero");
        }

        supportedRegionService.requireCurrency(req, sender.getUserId());

        if (transfer.currencyType() != null && "crypto".equalsIgnoreCase(transfer.currencyType())) {
            throw new IllegalArgumentException("Crypto currencies are not supported at the moment!");
        }

        // Resolve the sender user and basic account checks
        UserModel senderUser = userRepository.findById(sender.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (senderUser.getStatus() != Datatypes.UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Your account is " + senderUser.getStatus() + " at the moment");
        }

        pinService.requireValid(sender, req.pin());
        supportedRegionService.requireUserCountry(sender);

        // ────── 2. PERSIST PENDING TRANSACTION ──────
        // The user must have a wallet/account in the funding currency
        FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(sender.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("No wallet found"));

        FiatAccountModel account = fiatAccountRepository.findByWalletIdAndCurrencyCode(wallet.getWalletId(), sourceCurrency)
                .orElseThrow(() -> new ResourceNotFoundException("No " + sourceCurrency + " account found"));

        // Build a CASH_IN_CARD transaction draft and record it as PENDING
        TransactionModel draft = new TransactionModel();
        draft.setInternalReferenceId("FUND-" + UUID.randomUUID());
        draft.setTransactionType(Datatypes.TransactionType.CASH_IN_CARD);
        draft.setAmount(amount);
        draft.setSourceCurrencyCode(sourceCurrency);
        draft.setDestinationCurrencyCode(sourceCurrency);
        draft.setDestinationAmount(amount);
        draft.setPurpose("Wallet funding");
        draft.setReceiverId(sender.getUserId());
        draft.setReceiverName(senderUser.getFirstName() + " " + senderUser.getLastName());
        draft.setReceiverEmail(senderUser.getEmail());
        draft.setReceiverPhoneNumber(senderUser.getPhoneNumber());
        draft.setDestinationIdentifier(account.getZentag());

        TransactionModel txn = ledgerOperations.recordFundingAttempt(draft);
        String reference = LedgerOperations.gatewayReference(txn);

        // ────── 3. INITIATE GATEWAY CHECKOUT ──────
        // Try Paystack first, then Flutterwave as failover
        GatewayCheckoutResult checkout;
        try {
            checkout = paystackServices.initializeCheckout(
                    senderUser.getEmail(),
                    amount,
                    sourceCurrency,
                    reference
            );
        } catch (PaymentGatewayException paystackError) {
            log.warn("Paystack checkout init failed, falling back to Flutterwave: {}", paystackError.getMessage());
            checkout = flutterwaveServices.initializeCheckout(
                    senderUser.getEmail(),
                    senderUser.getFirstName() + " " + senderUser.getLastName(),
                    senderUser.getPhoneNumber(),
                    amount,
                    sourceCurrency,
                    reference
            );
        }

        // ────── 4. RETURN TRANSACTION DTO ──────
        // The transaction is now PENDING; webhook or reconciliation will update it to SUCCESS
        return transactionsQueryService.toDto(txn, sender.getUserId());
    }

    // ==================================================================
    // CASH_OUT_MOMO: ZentraPay wallet -> mobile-money wallet (through a gateway)
    // ==================================================================

    private TransactionTransactionDTO sendToMobileMoney(UserModel sender, TransactionRequest req) {
        log.info("STAGE 1: reading the mobile money details");
        TransactionRequest.MobileMoneyDetails momo = req.mobileMoney();
        if (momo == null) {
            throw new IllegalArgumentException("Mobile money information missing");
        }
        TransactionRequest.TransferDetails transfer = req.transfer();
        BigDecimal amount = money(transfer.amount());
        String sourceCurrency = transfer.currencyCode().toUpperCase();
        String country = (momo.countryCode() == null || momo.countryCode().isBlank() ? sender.getCountryCode() : momo.countryCode()).toUpperCase();
        requireDomestic(sender, country, "mobile money network");
        String destinationCurrency = destinationCurrencyForBank(transfer.destinationCurrencyCode(), country, sourceCurrency);
        supportedRegionService.requireCurrency(req, sender.getUserId());
        BigDecimal destinationAmount = convertIfNeeded(amount, sourceCurrency, destinationCurrency, transfer.rateId());
        String phone = momo.phoneNumber().trim();

        log.info("STAGE 2: checking the sender account, balance and limits");
        FiatAccountModel senderAccount = requireSenderAccount(sender, sourceCurrency, amount, true);
        checkSendLimit(sender, amount);

        log.info("STAGE 3: asking the payment providers about the wallet (nothing is debited yet)");
        String accountName = accountVerificationService
                .verifyMobileMoney(momo.providerId(), momo.providerCode(), phone, country)
                .map(AccountVerificationService.Verified::accountName)
                .orElseGet(() -> momo.accountName() == null || momo.accountName().isBlank() ? phone : momo.accountName().trim());

        log.info("STAGE 3b: finding a provider for this network (nothing is debited yet)");
        BankTransferServices.Payout payout = new BankTransferServices.Payout("MOBILE_MONEY", sender,
                false, momo.providerId(), momo.providerCode(), country,
                destinationCurrency, phone, accountName, destinationAmount, purposeOf(transfer));
        BankTransferServices.Prepared prepared = bankTransferServices.prepare(payout);

        log.info("STAGE 4: debiting the sender");
        TransactionModel draft = newDraft(sender, req, Datatypes.TransactionType.CASH_OUT_MOMO, amount, sourceCurrency, destinationCurrency, destinationAmount);
        draft.setReceiverName(accountName);
        draft.setReceiverPhoneNumber(phone);
        draft.setDestinationIdentifier(phone);
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
            return accountVerificationService.verifyMobileMoney(req.destinationId(), req.destinationCode(), number, country)
                    .map(v -> new VerifiedAccountDTO(true, v.accountName(), number, v.destinationName(), country))
                    .orElseGet(() -> new VerifiedAccountDTO(false, null, number, null, country));
        }
        if ("BANK".equalsIgnoreCase(req.destinationType())) {
            AccountVerificationService.Verified v = accountVerificationService.verifyBank(
                    req.destinationId(), req.destinationCode(), number, country);
            return new VerifiedAccountDTO(true, v.accountName(), number, v.destinationName(), country);
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

    // The currency the bank is paid in: what the app asked for, else the bank country's currency, else the sender's currency
    private String destinationCurrencyForBank(String requested, String bankCountry, String sourceCurrency) {
        if (requested != null && !requested.isBlank()) {
            return requested.toUpperCase();
        }
        return gatewayCountriesRepository.findFirstByCountryCode(bankCountry)
                .map(GatewayCountryModel::getCurrencyCode)
                .orElse(sourceCurrency);
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
            FiatAccountModel receiverAccount = resolveReceiverAccount(receiver.getUserId(), req.appUser().zentag(), req.transfer().destinationCurrencyCode(), false);
            Map<String, Object> receiverDraft = draftFailedReceiverInfo(receiver.getFirstName() + " " + receiver.getLastName(), receiver.getEmail(), receiver.getPhoneNumber(), "Receiver limit reached", receiver.getUserId(), receiverAccount.getAccountId(), receiverAccount.getZentag());
            Map<String, Object> failedTxn = draftFailed(senderId, req, receiverDraft);
            saveFailedTransaction(failedTxn);
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
