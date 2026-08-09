package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.LinkedFundingSource;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.User;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.LinkedFundingSourceRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.model.BillProvider;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.repository.BillProviderRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Search across app users, bill providers, and linked funding sources —
 * API_CONTRACT.md §10. Consolidated onto the canonical domain tables: the old
 * searchContacts.model.{SearchAppUsersModel,SearchFundingSourcesModel} duplicate
 *
 * @Entity mappings have been removed in favor of domain.User / domain.LinkedFundingSource,
 * and bill-provider search now reuses billProviders.model.BillProvider instead of its
 * own duplicate mapping.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SearchContactsService {

    private final UserRepository userRepository;
    private final BillProviderRepository billProviderRepository;
    private final LinkedFundingSourceRepository linkedFundingSourceRepository;

    public SearchResponseDTO searchContacts(@Valid SearchRequestDTO req) {
        int limit = req.limit() > 0 ? req.limit() : 20;

        AppUserSearchDTO senderDetails = userRepository.getByUserId(req.userId());
        var users = userRepository.searchByQuery(req.query(), req.userId()).stream()
                .limit(limit)
                .map(this::toAppUserDTO)
                .toList();

        var providers = billProviderRepository.searchByQuery(req.query(), req.userId()).stream()
                .limit(limit)
                .map(this::toBillProviderDTO)
                .toList();

        var sources = linkedFundingSourceRepository.searchByQuery(req.query(), req.userId()).stream()
                .limit(limit)
                .map(this::toFundingSourceDTO)
                .toList();

        return new SearchResponseDTO(senderDetails, users, providers, sources);
    }

    private AppUserSearchDTO toAppUserDTO(User u) {
        return new AppUserSearchDTO(u.getUserId(), u.getFullName(), u.getFirstName(), u.getLastName(), u.getPhoneNumber(), u.getZentag(), u.getUserType());
    }

    private BillProviderSearchDTO toBillProviderDTO(BillProvider p) {
        return new BillProviderSearchDTO(p.getProviderId(), p.getBillerName(), p.getCategoryCode(), p.getLogoUrl(), p.getUserType());
    }

    private FundingSourceSearchDTO toFundingSourceDTO(LinkedFundingSource f) {
        return new FundingSourceSearchDTO(f.getSourceId(), f.getSourceName(), f.getAccountIdentifier(), f.isVerified(), f.getUserType());
    }
}
