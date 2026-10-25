package com.zentrapay.backend.service.bank;

import lombok.extern.slf4j.Slf4j;
import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.entity.UserBankModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.repository.BanksRepository;
import com.zentrapay.backend.repository.UserBankRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.dto.bank.AccountsDTO;
import com.zentrapay.backend.dto.bank.AccountsResponseDTO;
import com.zentrapay.backend.dto.bank.LinkNewBankRequestDTO;
import com.zentrapay.backend.dto.bank.UserAccountsDTO;
import com.zentrapay.backend.dto.bank.UserAccountsResponseDTO;
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
 *
 * <p>Two read shapes exist and both are still served:
 * <ul>
 *   <li>{@link #getAccounts} → the legacy catalog-only {@code AccountsResponseDTO}
 *       (kept so the older {@code /accounts} contract does not break).</li>
 *   <li>{@link #getUserAccounts} → the real per-user
 *       {@code UserAccountsResponseDTO} (primary + every linked account) used by
 *       the ZBank header and the horizontal strip of bank cards.</li>
 * </ul>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BankAccountsServices {

    private final BanksRepository banksRepository;
    private final UserBankRepository userBankRepository;
    private final UserRepository userRepository;
    private final BankAccountLinkService bankAccountLinkService;

    /* ---------------------------------------------------------------- reads */

    /**
     * Legacy read: the {@code banks} catalog rows the user has linked. Kept for
     * the older {@code GET /api/zbanking/accounts} contract.
     */
    @Transactional(readOnly = true)
    public AccountsResponseDTO getAccounts(UUID userId) {
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
     * with the per-link display fields (last digits, balance, label, primary).
     *
     * @return {@code primary} is the single primary account (or {@code null}
     *         when the user has none yet); {@code accounts} holds every linked
     *         account, primary first, so the strip renders a stable order.
     */
    @Transactional(readOnly = true)
    public UserAccountsResponseDTO getUserAccounts(UUID userId) {
        // Reads the primary account and every linked account for the ZBank screen
        log.info("Loading linked bank accounts for user {}", userId);
        List<UUID> bankIds = userBankRepository.getBankIdsByUserId(userId);
        List<UserAccountsDTO> accounts = buildUserAccounts(userId);

        UserAccountsDTO primary = null;
        for (UserAccountsDTO account : accounts) {
            if (Boolean.TRUE.equals(account.primary())) {
                primary = account;
                break;
            }
        }
        // No explicit primary yet (e.g. rows linked before V35): fall back to the
        // earliest link so the header never renders blank on existing data.
        if (primary == null && !accounts.isEmpty()) {
            primary = accounts.get(0);
        }
        return new UserAccountsResponseDTO(primary, accounts);
    }
    /* --------------------------------------------------------------- writes */

    /**
     * Links a bank to the user (ZBank Lite "link a bank" sheet).
     *
     * <p>The first bank a user links becomes primary automatically, so the
     * header is never empty after a fresh link. Linking the same bank twice is
     * rejected rather than duplicated.
     *
     * <p>Before anything is persisted the account is pushed through the
     * open-banking linking request to <b>AfriqLink</b> — the settlement
     * gateways (Paystack/Flutterwave/Onafriq) only move money and are never
     * used for account linking. The holder's first/last name from the request
     * are part of that provider payload; if AfriqLink declines, the link fails
     * with the provider's reason and nothing is saved.
     *
     * @return the newly linked account.
     */
    @Transactional
    public UserAccountsDTO linkBank(UUID userId, LinkNewBankRequestDTO request) {
        // Links a bank: validate the account number, ask AfriqLink to confirm it, then save the link (first link becomes primary)
        log.info("Linking a bank for user {}", userId);
        final UUID bankId;
        try {
            bankId = UUID.fromString(request.bankId());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Target bank is not a valid bank id");
        }

        final String accountNumber = request.accountNumber() == null
                ? ""
                : request.accountNumber().trim();
        if (accountNumber.isEmpty()) {
            throw new IllegalArgumentException("Target account number is required");
        }
        // Keep only digits so spaces/dashes typed by the user are normalised.
        final String digits = accountNumber.replaceAll("[^0-9]", "");
        if (digits.length() < 4) {
            throw new IllegalArgumentException("Target account number is too short");
        }
        final String lastDigits = digits.substring(digits.length() - 4);

        UserModel user = userRepository.getUserByUserId(userId)
                .orElseThrow(()-> new RuntimeException("Error:: User not found!"));

        final BanksModel bank = banksRepository.findById(bankId)
                .orElseThrow(() -> new ResourceNotFoundException("Target bank not found"));

        if (userBankRepository.findByUserIdAndBankId(userId, bankId).isPresent()) {
            throw new IllegalArgumentException("You have already linked this bank");
        }

        // Send the real open-banking linking request (AfriqLink) BEFORE writing
        // anything: if the provider declines this throws (and rolls back
        // nothing — no row exists yet), so a link AfriqLink did not confirm
        // can never reach the database.
        final BankAccountLinkService.BankLinkOutcome outcome =
                bankAccountLinkService.link(bank, digits, request.firstName().trim(), request.lastName().trim());

        // A user's first linked bank is automatically primary.
        final boolean makePrimary = Boolean.TRUE.equals(request.primary())
                || userBankRepository.getBankIdsByUserId(userId).isEmpty();
        if (makePrimary) {
            userBankRepository.clearPrimaryForUser(userId);
        }

        final UserBankModel row = new UserBankModel();
        row.setUserId(userId);
        row.setBankId(bankId);
        row.setBalance(BigDecimal.ZERO);
        row.setLastDigits(lastDigits);
        row.setConnectionStatus("active");
        // Records which provider confirmed the link, e.g. "afriqlink:LNK_1a2b3c".
        row.setConnectionId(outcome.connectionId());
        row.setPrimary(makePrimary);
        final String label = request.linkLabel() == null || request.linkLabel().isBlank()
                ? null
                : request.linkLabel().trim();
        row.setLinkLabel(label);

        final UserBankModel saved = userBankRepository.save(row);
        return toUserAccount(saved, bank);
    }

    /**
     * Promotes an already-linked account to be the user's primary (the one shown
     * in the ZBank header). Any previous primary is demoted in the same
     * transaction so the partial unique index can never be violated.
     *
     * @param userBankId id of the user's link row — NOT the catalog bank id.
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

        final BanksModel bank = banksRepository.findById(saved.getBankId())
                .orElseThrow(() -> new ResourceNotFoundException("Bank not found"));
        return toUserAccount(saved, bank);
    }

    /** Unlinks one of the user's banks. */
    @Transactional
    public void unlinkBank(UUID userId, UUID userBankId) {
        // Unlinks a bank; if it was the primary one, the oldest remaining link becomes primary
        log.info("Unlinking bank account {} for user {}", userBankId, userId);
        final UserBankModel row = userBankRepository.findById(userBankId)
                .orElseThrow(() -> new ResourceNotFoundException("Bank account not found"));
        if (!row.getUserId().equals(userId)) {
            throw new ResourceNotFoundException("Bank account not found");
        }

        final boolean wasPrimary = Boolean.TRUE.equals(row.getPrimary());
        userBankRepository.delete(row);

        // Promote another account so the header keeps showing a primary.
        if (wasPrimary) {
            List<UserBankModel> remaining = userBankRepository.findByUserId(userId);
            if (!remaining.isEmpty()) {
                remaining.sort(Comparator.comparing(
                        UserBankModel::getLinkedAt,
                        Comparator.nullsLast(Comparator.naturalOrder())));
                UserBankModel next = remaining.get(0);
                next.setPrimary(true);
                userBankRepository.save(next);
            }
        }
    }
    /* ------------------------------------------------------------- internals */

    /** Maps a catalog row to the legacy accounts DTO. */
    private static AccountsDTO toAccountsDTO(BanksModel b) {
        return new AccountsDTO(
                b.getBankId(),
                b.getCode(),
                b.getBankName(),
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

    /**
     * Joins the user's link rows with the catalog, one entry per linked bank,
     * primary first then oldest link first. A missing catalog row is still
     * surfaced (with null display fields) so the user can unlink it rather than
     * it silently vanishing from the screen.
     */
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
            Optional<BanksModel> bank = banksRepository.findById(row.getBankId());
            result.add(toUserAccount(row, bank.orElse(null)));
        }
        result.sort(Comparator.comparing(
                (UserAccountsDTO a) -> !Boolean.TRUE.equals(a.primary())));
        return result;
    }

    /** Maps a link row (+ its catalog bank, possibly {@code null}) to the DTO. */
    private static UserAccountsDTO toUserAccount(UserBankModel row, BanksModel bank) {
        return new UserAccountsDTO(
                row.getUserBankId(),
                row.getUserId(),
                row.getBalance(),
                row.getBankId(),
                row.getLastDigits(),
                row.getConnectionStatus(),
                row.getConnectionId(),
                row.getLinkedAt(),
                row.getUpdatedAt(),
                bank == null ? null : bank.getBankName(),
                bank == null ? null : bank.getCode(),
                bank == null ? null : bank.getCountryCode(),
                bank == null ? null : bank.getCurrencyCode(),
                row.getLinkLabel(),
                Boolean.TRUE.equals(row.getPrimary())
        );
    }
}
