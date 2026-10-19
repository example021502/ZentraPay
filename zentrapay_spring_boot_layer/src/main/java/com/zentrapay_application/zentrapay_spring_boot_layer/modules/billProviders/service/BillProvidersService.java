package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BillProviderModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.BillProviderRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto.BillProviderDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Transactional
public class BillProvidersService {

    private final BillProviderRepository billProviderRepository;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    /**
     * Country-filtered, deduplicated bill-provider directory.
     * <p>
     * The client sends no country — the authenticated caller's JWT country
     * decides the corridor (an explicit {@code countryCode} query param still
     * wins for internal/admin callers). Only {@code active} rows are returned,
     * and because the same biller can be offered by several gateway providers
     * (one table row per gateway), the result is collapsed to ONE record per
     * biller before it reaches the frontend — preferring rows that carry a
     * logo, since that is what the client renders first.
     */
    @Transactional(readOnly = true)
    public List<BillProviderDTO> listProviders(AuthenticatedUser user, String countryCode) {
        final String effectiveCountry = (countryCode == null || countryCode.isBlank())
                ? (user != null ? user.getCountryCode() : null)
                : countryCode;

        final List<BillProviderModel> providers =
                (effectiveCountry == null || effectiveCountry.isBlank())
                        ? billProviderRepository.findAll()
                        : billProviderRepository.findActiveByCountryCode(
                                effectiveCountry.trim().toLowerCase());

        return dedupeByBiller(providers).stream()
                .map(BillProvidersService::toDTO)
                .toList();
    }

    /**
     * Collapses multi-gateway duplicates down to a single record per biller.
     * Key is the biller code (falling back to the normalized biller name when
     * a row has none); when two rows describe the same biller, the one with a
     * logo wins — see the class doc.
     */
    private static List<BillProviderModel> dedupeByBiller(List<BillProviderModel> providers) {
        final Map<String, BillProviderModel> unique = new LinkedHashMap<>();
        for (BillProviderModel p : providers) {
            if (p.getActive() != null && !p.getActive()) continue; // active-only
            final String code = p.getBillerCode();
            final String key = (code == null || code.isBlank())
                    ? normalize(p.getBillerName())
                    : normalize(code);
            final BillProviderModel existing = unique.get(key);
            if (existing == null || prefers(p, existing)) {
                unique.put(key, p);
            }
        }
        return new ArrayList<>(unique.values());
    }

    private static String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase();
    }

    /** True when [candidate] should replace [current] for the same biller. */
    private static boolean prefers(BillProviderModel candidate, BillProviderModel current) {
        return hasLogo(candidate) && !hasLogo(current);
    }

    private static boolean hasLogo(BillProviderModel p) {
        return p.getLogoUrl() != null && !p.getLogoUrl().isBlank();
    }

    private static BillProviderDTO toDTO(BillProviderModel p) {
        return new BillProviderDTO(
                p.getProviderId(),
                p.getBillerCode(),
                p.getBillerName(),
                p.getCategoryCode(),
                p.getCountryCode(),
                p.getLogoUrl(),
                p.getCreatedAt(),
                p.getUpdatedAt(),
                p.getChannelCode(),
                p.getIsCrossBorderAllowed(),
                p.getActive(),
                p.getFetchRequirement()
        );
    }


}