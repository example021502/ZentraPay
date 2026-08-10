package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.LinkedFundingSource;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.User;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.LinkedFundingSourceRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.model.BillProvider;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.repository.BillProviderRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.paymentChannels.service.PaymentChannelsService;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

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
    private final LinkedFundingSourceRepository linkedFundingSourceRepository;
    private final PaymentChannelsService paymentChannelsService;

    // ISO 3166-1 alpha-2 -> E.164 dial code, for the corridors this app serves. The
    // live `countries` table doesn't carry a dial-code column, so this stays a small
    // in-code map rather than a query — extend alongside PaymentChannelSyncService's
    // SYNC_COUNTRIES list when a new corridor is added.
    private static final Map<String, String> DIAL_CODES = Map.of(
            "GH", "+233",
            "NG", "+234",
            "KE", "+254",
            "US", "+1"
    );

    public SearchResponseDTO searchContacts(@Valid SearchRequestDTO req) {
        int limit = req.limit() > 0 ? req.limit() : 20;

        User searchingUser = userRepository.findById(req.userId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + req.userId()));
        String countryCode = searchingUser.getCountryCode();
        String dialCode = DIAL_CODES.getOrDefault(countryCode, "");

        AppUserSearchDTO senderDetails = userRepository.getByUserId(req.userId());

        var users = userRepository.searchByQuery(req.query(), req.userId(), countryCode, dialCode).stream()
                .limit(limit)
                .map(this::toAppUserDTO)
                .toList();

        var providers = billProviderRepository.searchByQuery(req.query(), req.userId(), countryCode).stream()
                .limit(limit)
                .map(this::toBillProviderDTO)
                .toList();

        var sources = linkedFundingSourceRepository.searchByQuery(req.query(), req.userId()).stream()
                .limit(limit)
                .map(this::toFundingSourceDTO)
                .toList();

        // Live directory read, not a gateway call per keystroke — payment_channels is
        // kept fresh by PaymentChannelSyncService's three per-gateway scheduled jobs.
        var banks = paymentChannelsService.listChannels(countryCode, "BANK").stream()
                .filter(c -> matchesQuery(c.channelName(), req.query()))
                .limit(limit)
                .toList();

        return new SearchResponseDTO(senderDetails, users, providers, sources, banks);
    }

    private boolean matchesQuery(String name, String query) {
        return name != null && query != null && name.toLowerCase().contains(query.toLowerCase());
    }

    private AppUserSearchDTO toAppUserDTO(User u) {
        return new AppUserSearchDTO(u.getUserId(), u.getFullName(), u.getFirstName(), u.getLastName(), u.getPhoneNumber(), u.getZentag(), u.getUserType(), u.getEmail());
    }

    private BillProviderSearchDTO toBillProviderDTO(BillProvider p) {
        return new BillProviderSearchDTO(p.getProviderId(), p.getBillerName(), p.getCategoryCode(), p.getLogoUrl(), p.getUserType());
    }

    private FundingSourceSearchDTO toFundingSourceDTO(LinkedFundingSource f) {
        return new FundingSourceSearchDTO(f.getSourceId(), f.getSourceName(), f.getAccountIdentifier(), f.isVerified(), f.getUserType());
    }
}
