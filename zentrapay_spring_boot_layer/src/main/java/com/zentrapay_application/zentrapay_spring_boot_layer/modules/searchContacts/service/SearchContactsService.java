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

//        GET SENDER DETAILS
        // Comment: Retrieve and map the user entity to a SenderDTO safely using Optional
        SenderDTO sender = userRepository.getUserById(userId)
                .map(user -> new SenderDTO(
                        user.getUserId(),
                        user.getCountryCode()
                ))
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        List<UserSearchDTO> appUsers = userRepository.searchByQueryAndCountryCodeExcludingCurrentUser(req.query(), sender.countryCode(), userId)
                .stream().map(user -> new UserSearchDTO(
                        user.getUserId(),
                        user.getCountryCode(),
                        user.getEmail(),
                        user.getFirstName(),
                        user.getLastName(),
                        user.getPhoneNumber(),
                        user.getUserType()
                )).limit(limit).toList();


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

