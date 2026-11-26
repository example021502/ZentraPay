package com.zentrapay.backend.service.bank;

import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.service.CountriesServices;
import com.zentrapay.backend.service.DigitalAccounts.CurrenciesServices;
import com.zentrapay.backend.service.common.Datatypes;
import lombok.extern.slf4j.Slf4j;
import com.zentrapay.backend.repository.BanksRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.repository.UserBankRepository;
import com.zentrapay.backend.dto.bank.AccountsDTO;
import com.zentrapay.backend.dto.bank.AccountsResponseDTO;
import com.zentrapay.backend.dto.bank.LinkNewBankRequestDTO;
import com.zentrapay.backend.dto.bank.UserAccountsDTO;
import com.zentrapay.backend.dto.bank.UserAccountsResponseDTO;
import com.zentrapay.backend.dto.payment.AfriLinkAccountDTO;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * ZBank Lite bank accounts — linking a bank, promoting a primary account and
 * reading back the linked accounts for the ZBank screen.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BankAccountsServices {

    private final BanksRepository banksRepository;
    private final UserBankRepository userBankRepository;
    private final BankAccountLinkService bankAccountLinkService;
    private final UserRepository userRepository;
    private final CurrenciesServices currenciesServices;

    /* ---------------------------------------------------------------- reads */

    /**
     * Legacy read: the {@code banks} catalog rows the user has linked. Kept for
     * the older {@code GET /api/zbanking/accounts} contract.
     */
    @Transactional(readOnly = true)
    public AccountsResponseDTO getAccounts(UUID userId) {
        // Comment: Fetch linked bank IDs for the given user
        List<UUID> bankIds = userBankRepository.getBankIdsByUserId(userId);
        if (bankIds.isEmpty()) {
            return new AccountsResponseDTO(List.of());
        }
        return new AccountsResponseDTO(
                banksRepository.getAccountsByBanksIds(bankIds)
                        .stream()
                        .map(BankAccountsServices::toAccountsDTO)
                        .toList()
        );
    }

    /**
     * Canonical read for the ZBank screen: the user's linked accounts enriched
     * with per-link display fields.
     */
    @Transactional(readOnly = true)
    public UserAccountsResponseDTO getUserAccounts(UUID userId) {
        log.info("Loading linked bank accounts for user {}", userId);
        List<UserAccountsDTO> accounts = buildUserAccounts(userId);

        UserAccountsDTO primary = null;
        for (UserAccountsDTO account : accounts) {
            if (Boolean.TRUE.equals(account.primary())) {
                primary = account;
                break;
            }
        }
        if (primary == null && !accounts.isEmpty()) {
            primary = accounts.getFirst();
        }
        return new UserAccountsResponseDTO(primary, accounts);
    }

    /* --------------------------------------------------------------- writes */

    /**
     * Links a bank the user connected through the AfriLink Connect widget.
     *
     * <p>The app sends what the widget returned: a session id + auth token (the backend submits them to
     * AfriLink's linking endpoint with the public key) or the id of an account the widget already
     * completed (read back from AfriLink). Either way AfriLink must confirm the link, so a made-up value
     * is rejected. Accounts already linked to anyone are refused, and one row is saved holding AfriLink's
     * account id, the institution, currency and the last digits - never an account number
     * credentials. The first bank a user links becomes primary.
     */
    @Transactional
    public UserAccountsDTO linkBank(UUID userId, LinkNewBankRequestDTO request) {
        log.info("Linking an AfriLink account for user {}", userId);

        // 1. Cheap early check when the app already knows the account id (also stops a replayed id)
        if (request.hasAccountId() && accountAlreadyLinked(request.accountId().trim())) {
            throw new IllegalArgumentException("This bank account is already linked");
        }

        // 2. AfriLink confirms the link: completes it with the token, or reads the account back
        final AfriLinkAccountDTO account = bankAccountLinkService.link(request, userId.toString());
        final String accountId = account.accountId();

        // 3. A token link only reveals its account id now: an AfriLink account belongs to one user only
        if (accountAlreadyLinked(accountId)) {
            throw new IllegalArgumentException("This bank account is already linked");
        }

        final String institutionName = firstNonBlank(account.institutionName(), request.institutionName(), "Bank account");
        final String countryCode = request.institutionCountry() == null || request.institutionCountry().isBlank()
                ? null : request.institutionCountry().trim().toUpperCase();

        // 3. Best-effort match into the payout catalogue (informational; linking does not need it)
        final Optional<BanksModel> catalogBank = banksRepository.findFirstByBankNameIgnoreCase(institutionName);

        // 4. The first linked bank becomes primary
        final boolean makePrimary = userBankRepository.findByUserId(userId).isEmpty();
        if (makePrimary) {
            userBankRepository.clearPrimaryForUser(userId);
        }

        final UserBankModel row = new UserBankModel();
        row.setUserId(userId);
        row.setBankId(catalogBank.map(BanksModel::getId).orElse(null));
        row.setBalance(account.balance() == null ? BigDecimal.ZERO : account.balance());
        row.setLastDigits(account.lastDigits() == null ? "" : account.lastDigits());
        row.setConnectionStatus(Datatypes.UserBankConnectionStatus.ACTIVE);
        row.setConnectionId(BankAccountLinkService.PROVIDER_AFRILINK + ":" + accountId);
        row.setProvider(BankAccountLinkService.PROVIDER_AFRILINK);
        row.setProviderAccountId(accountId);
        row.setInstitutionId(firstNonBlank(account.institutionId(), request.institutionId(), null));
        row.setInstitutionName(institutionName);
        row.setAccountType(account.accountType());
        final String linkCountry = countryCode != null ? countryCode
                : catalogBank.map(BanksModel::getCountryCode)
                .orElseGet(() -> userRepository.findById(userId).map(UserModel::getCountryCode).orElse(null));
        row.setCountryCode(linkCountry);
        // The currency decides which wallet this bank can fund: what the bank reports, else the catalogue
        // bank's currency, else the currency of the bank's country
        row.setCurrencyCode(firstNonBlank(account.currencyCode(),
                catalogBank.map(BanksModel::getCurrencyCode).orElse(null),
                linkCountry == null ? null : currenciesServices.getCurrency(linkCountry)));
        if (row.getCurrencyCode() != null) {
            row.setCurrencyCode(row.getCurrencyCode().toUpperCase());
        }
        row.setPrimary(makePrimary);

        final UserBankModel saved = userBankRepository.save(row);
        return toUserAccount(saved, catalogBank.orElse(null));
    }

    private boolean accountAlreadyLinked(String accountId) {
        return accountId != null
                && userBankRepository.findByProviderAndProviderAccountId(BankAccountLinkService.PROVIDER_AFRILINK, accountId).isPresent();
    }

    /**
     * Promotes an already-linked account to be the user's primary account.
     */
    @Transactional
    public UserAccountsDTO setPrimary(UUID userId, UUID userBankId) {
        final UserBankModel row = userBankRepository.findById(userBankId)
                .orElseThrow(() -> new ResourceNotFoundException("Bank account not found"));
        if (!row.getUserId().equals(userId)) {
            throw new ResourceNotFoundException("Bank account not found");
        }

        userBankRepository.clearPrimaryForUser(userId);
        row.setPrimary(true);
        final UserBankModel saved = userBankRepository.save(row);

        final BanksModel bank = saved.getBankId() == null ? null : banksRepository.findById(saved.getBankId()).orElse(null);
        return toUserAccount(saved, bank);
    }

    /**
     * Unlinks one of the user's banks.
     */
    @Transactional
    public void unlinkBank(UUID userId, UUID userBankId) {
        log.info("Unlinking bank account {} for user {}", userBankId, userId);
        final UserBankModel row = userBankRepository.findById(userBankId)
                .orElseThrow(() -> new ResourceNotFoundException("Bank account not found"));
        if (!row.getUserId().equals(userId)) {
            throw new ResourceNotFoundException("Bank account not found");
        }

        final boolean wasPrimary = Boolean.TRUE.equals(row.getPrimary());
        userBankRepository.delete(row);

        if (wasPrimary) {
            List<UserBankModel> remaining = userBankRepository.findByUserId(userId);
            if (!remaining.isEmpty()) {
                remaining.sort(Comparator.comparing(
                        UserBankModel::getLinkedAt,
                        Comparator.nullsLast(Comparator.naturalOrder())));
                UserBankModel next = remaining.getFirst();
                next.setPrimary(true);
                userBankRepository.save(next);
            }
        }
    }

    /* ------------------------------------------------------------- internals */

    private static AccountsDTO toAccountsDTO(BanksModel b) {
        return new AccountsDTO(
                b.getId(),
                b.getCode(),
                b.getName(),
                b.getGateway(),
                b.getIban(),
                b.getCurrencyCode(),
                b.getPayWithBank(),
                b.getSwiftBic(),
                b.getCountryCode(),
                b.getCountry(),
                b.getActive(),
                b.getCreatedAt(),
                b.getUpdatedAt(),
                b.getMaxDailyValue(),
                b.getMaxMonthlyValue(),
                b.getMinTxnLimit(),
                b.getMaxTxnLimit(),
                b.getMaxWeeklyValue()
        );
    }

    private List<UserAccountsDTO> buildUserAccounts(UUID userId) {
        List<UserBankModel> rows = userBankRepository.findByUserId(userId);
        if (rows.isEmpty()) {
            return List.of();
        }
        rows.sort(Comparator.comparing(
                UserBankModel::getLinkedAt,
                Comparator.nullsLast(Comparator.naturalOrder())));

        List<UserAccountsDTO> result = new ArrayList<>();
        for (UserBankModel row : rows) {
            Optional<BanksModel> bank = row.getBankId() == null ? Optional.empty() : banksRepository.findById(row.getBankId());
            result.add(toUserAccount(row, bank.orElse(null)));
        }
        result.sort(Comparator.comparing(
                (UserAccountsDTO a) -> !Boolean.TRUE.equals(a.primary())));
        return result;
    }

    private static UserAccountsDTO toUserAccount(UserBankModel row, BanksModel bank) {
        return new UserAccountsDTO(
                row.getId(),
                row.getUserId(),
                row.getBalance(),
                row.getBankId(),
                row.getLastDigits(),
                row.getConnectionStatus(),
                row.getConnectionId(),
                row.getLinkedAt(),
                row.getUpdatedAt(),
                firstNonBlank(row.getInstitutionName(), bank == null ? null : bank.getName(), null),
                bank == null ? row.getInstitutionId() : bank.getCode(),
                firstNonBlank(row.getCountryCode(), bank == null ? null : bank.getCountryCode(), null),
                firstNonBlank(row.getCurrencyCode(), bank == null ? null : bank.getCurrencyCode(), null),
                row.getLinkLabel(),
                Boolean.TRUE.equals(row.getPrimary())
        );
    }

    private static String firstNonBlank(String a, String b, String fallback) {
        if (a != null && !a.isBlank()) {
            return a.trim();
        }
        if (b != null && !b.isBlank()) {
            return b.trim();
        }
        return fallback;
    }
}
