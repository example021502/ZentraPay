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

import java.util.List;
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


    public SearchResponseDTO searchContacts(@Valid SearchRequestDTO req, UUID userId) {
        int limit = req.limit() > 0 ? req.limit() : 20;

        UserModel sender = userRepository.getUserById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        List<UserSearchDTO> appUsers = userRepository.searchByQueryAndCountryCode(req.query().toLowerCase(), sender.getCountryCode()).stream()
                .limit(limit).map(this::toUserSearchDTO).toList();


        List<UUID> billProviderIds = userBillProvidersRepository.getUserBillProvidersIdsByUserId(userId);
        List<BillProviderSearchDTO> billProviders = billProviderRepository.getBillProvidersByQueryCountryCodeAndProviderIds(req.query().toLowerCase(), sender.getCountryCode(), billProviderIds).stream().limit(limit)
                .map(this::toBillProviderSearchDTO).toList();

        List<UUID> fundingSourcesIds = userFundingSourcesRepository.getFundingSourcesIdsByUserId(userId);
        List<FundingSourceSearchDTO> fundingSources = fundingSourceRepository.searchByQueryCountryCodeAndSourceIds(req.query().toLowerCase(), sender.getCountryCode(), fundingSourcesIds).stream().limit(limit)
                .map(this::toFundingSourceSearchDTO).toList();


        return new SearchResponseDTO(toUserSearchDTO(sender), appUsers, billProviders, fundingSources);
    }

    private UserSearchDTO toUserSearchDTO(UserModel u) {
        return new UserSearchDTO(
                u.getUserId(),
                u.getCountryCode(),
                null, // no country-name source on UserModel
                u.getEmail(),
                u.getFirstName(),
                u.getLastName(),
                u.getPhoneNumber(),
                u.getStatus(),
                u.getUserType(),
                u.getZentag(),
                u.getUpdatedAt(),
                u.getCreatedAt()
        );
    }

    private BillProviderSearchDTO toBillProviderSearchDTO(BillProviderModel p) {
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

    private FundingSourceSearchDTO toFundingSourceSearchDTO(LinkedFundingSource f) {
        return new FundingSourceSearchDTO(
                f.getSourceId(),
                f.getAccountIdentifier(),
                f.getChannelCode(),
                f.getCountryCode(),
                f.isVerified(),
                f.getSourceName(),
                f.getSourceType(),
                null, // accountName not modelled on LinkedFundingSource
                null, // fundingSourceCode
                null, // currency
                null, // fundingType
                null, // isPrimary
                f.getCreatedAt(),
                f.getUpdatedAt()
        );
    }
}

