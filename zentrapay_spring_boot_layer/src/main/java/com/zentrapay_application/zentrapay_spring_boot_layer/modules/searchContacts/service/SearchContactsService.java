package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.service;

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
//      searching sender details
        UserSearchDTO sender = userRepository.getUserById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
//      getting a list of searched users
        List<UserSearchDTO> appUsers = userRepository.searchByQueryAndCountryCode(req.query().toLowerCase(), sender.countryCode()).stream()
                .limit(limit).toList();


        List<UUID> billProviderIds = userBillProvidersRepository.getUserBillProvidersIdsByUserId(userId);
        List<BillProviderSearchDTO> billProviders = billProviderRepository.getBillProvidersByQueryCountryCodeAndProviderIds(req.query().toLowerCase(), sender.countryCode(), billProviderIds).stream().limit(limit).toList();

        List<UUID> fundingSourcesIds = userFundingSourcesRepository.getFundingSourcesIdsByUserId(userId);
        List<FundingSourceSearchDTO> fundingSources = fundingSourceRepository.searchByQueryCountryCodeAndSourceIds(req.query().toLowerCase(), sender.countryCode(), fundingSourcesIds).stream().limit(limit).toList();


        return new SearchResponseDTO(sender, appUsers, billProviders, fundingSources);
    }

}

