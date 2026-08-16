package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BillProviderModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.LinkedFundingSource;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Search across app users, bill providers, linked funding sources, and gateway-synced
 * banks — API_CONTRACT.md §10. Every result is scoped to the searching user's own
 * country: their {@code countryCode} is resolved first (see {@link #searchContacts}),
 * then every downstream query is restricted to that country — a provider, contact, or
 * bank only relevant to a different market isn't useful to show here.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SearchContactsService {

    private final UserRepository userRepository;
    private final BillProviderRepository billProviderRepository;
    private final FundingSourceRepository fundingSourceRepository;
    private final UserBillProvidersRepository userBillProvidersRepository;
    private final UserFundingSourcesRepository userFundingSourcesRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;


    public SearchResponseDTO searchContacts(@Valid SearchRequestDTO req, UUID userId) {
        int limit = req.limit() > 0 ? req.limit() : 20;
//      searching sender details
        UserModel senderUser = userRepository.getUserById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        UserSearchDTO sender = toUserSearchDTO(senderUser, getZentagAccounts(userId));

//      getting a list of searched users by name/phone/email, then merging in
//      anyone whose zentag (on one of their currency accounts) matches too —
//      lets a sender paste a zentag straight into the search box. The sender
//      themselves is excluded — you can't send money to yourself.
        Map<UUID, UserModel> matchedUsers = new LinkedHashMap<>();
        userRepository.searchByQueryAndCountryCode(req.query().toLowerCase(), sender.countryCode())
                .stream()
                .filter(u -> !u.getUserId().equals(userId))
                .forEach(u -> matchedUsers.put(u.getUserId(), u));

        fiatAccountRepository.findByZentagContainingIgnoreCase(req.query()).stream()
                .map(account -> fiatWalletRepository.findById(account.getWalletId()).orElse(null))
                .filter(Objects::nonNull)
                .filter(wallet -> sender.countryCode().equalsIgnoreCase(wallet.getCountryCode()))
                .filter(wallet -> !wallet.getUserId().equals(userId))
                .map(wallet -> userRepository.findById(wallet.getUserId()).orElse(null))
                .filter(Objects::nonNull)
                .forEach(u -> matchedUsers.putIfAbsent(u.getUserId(), u));

        List<UserSearchDTO> appUsers = matchedUsers.values().stream()
                .map(u -> toUserSearchDTO(u, getZentagAccounts(u.getUserId())))
                .limit(limit).toList();


        List<UUID> billProviderIds = userBillProvidersRepository.getUserBillProvidersIdsByUserId(userId);
        List<BillProviderSearchDTO> billProviders = billProviderRepository.getBillProvidersByQueryCountryCodeAndProviderIds(req.query().toLowerCase(), sender.countryCode(), billProviderIds).stream()
                .map(SearchContactsService::toBillProviderSearchDTO)
                .limit(limit).toList();

        List<UUID> fundingSourcesIds = userFundingSourcesRepository.getFundingSourcesIdsByUserId(userId);
        List<FundingSourceSearchDTO> fundingSources = fundingSourceRepository.searchByQueryCountryCodeAndSourceIds(req.query().toLowerCase(), sender.countryCode(), fundingSourcesIds).stream()
                .map(SearchContactsService::toFundingSourceSearchDTO)
                .limit(limit).toList();


        return new SearchResponseDTO(sender, appUsers, billProviders, fundingSources);
    }

    private static UserSearchDTO toUserSearchDTO(UserModel u, List<AccountZentagDTO> fiatAccounts) {
        return new UserSearchDTO(
                u.getUserId(),
                u.getCountryCode(),
                u.getEmail(),
                u.getFirstName(),
                u.getLastName(),
                u.getPhoneNumber(),
                u.getStatus(),
                u.getUserType(),
                fiatAccounts,
                u.getUpdatedAt(),
                u.getCreatedAt()
        );
    }

    // Comment: each user has exactly one fiat wallet — see FiatWalletRepository.
    // Active accounts only; empty (never null) if the wallet has none yet.
    private List<AccountZentagDTO> getZentagAccounts(UUID userId) {
        return fiatWalletRepository.findByUserId(userId)
                .map(wallet -> fiatAccountRepository.findByWalletId(wallet.getWalletId()).stream()
                        .filter(a -> "active".equals(a.getStatus()))
                        .map(a -> new AccountZentagDTO(
                                a.getAccountId(),
                                a.getAccountName(),
                                a.getCurrencyCode(),
                                a.getZentag(),
                                a.isDefault()
                        ))
                        .toList())
                .orElse(List.of());
    }

    private static BillProviderSearchDTO toBillProviderSearchDTO(BillProviderModel p) {
        return new BillProviderSearchDTO(
                p.getProviderId(),
                p.getBillerCode(),
                p.getBillerName(),
                p.getCategoryCode(),
                p.getCountryCode(),
                p.getFetchRequirement(),
                p.getCustomerParamsSchema(),
                p.getLogoUrl(),
                p.getUpdatedAt(),
                p.getChannelCode(),
                p.getIsCrossBorderAllowed(),
                p.getActive(),
                p.getCreatedAt()
        );
    }

    private static FundingSourceSearchDTO toFundingSourceSearchDTO(LinkedFundingSource f) {
        return new FundingSourceSearchDTO(
                f.getSourceId(),
                f.getAccountIdentifier(),
                f.getChannelCode(),
                f.getCountryCode(),
                f.getIsVerified(),
                f.getSourceName(),
                f.getSourceType(),
                f.getAccountName(),
                f.getFundingSourceCode(),
                f.getCurrency(),
                f.getFundingType(),
                f.getIsPrimary(),
                f.getCreatedAt()
        );
    }

}

