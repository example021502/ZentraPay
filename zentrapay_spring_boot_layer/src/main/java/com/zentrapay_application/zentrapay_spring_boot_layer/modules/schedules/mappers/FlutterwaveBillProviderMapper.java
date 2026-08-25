package com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.mappers;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BillProviderModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos.FlutterwaveBillCategoryResponseDTO;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Maps Flutterwave bill-category items into the canonical {@code bill_providers}
 * entity. Flutterwave's {@code category_name} is free text, so it is normalised
 * onto the {@code provider_categories} lookup table codes (V2__seed_reference_data.sql).
 * The sync service upserts by {@code biller_code}, so this mapper always builds
 * fresh entities.
 */
@Component
public class FlutterwaveBillProviderMapper {

    public List<BillProviderModel> mapToEntities(FlutterwaveBillCategoryResponseDTO response, String countryCode) {
        if (response == null || response.data() == null || !"success".equalsIgnoreCase(response.status())) {
            return Collections.emptyList();
        }

        return response.data().stream()
                .filter(item -> {
                    String name = firstNonBlank(item.billerName(), item.name(), item.shortName());
                    return name != null && item.billerCode() != null && !item.billerCode().isBlank();
                })
                .map(item -> {
                    BillProviderModel provider = new BillProviderModel();
                    provider.setBillerCode(item.billerCode());
                    provider.setBillerName(firstNonBlank(item.billerName(), item.name(), item.shortName()));
                    provider.setCategoryCode(resolveCategoryCode(item.categoryName()));
                    // Flutterwave always returns an ISO alpha-2 country; fall back to the
                    // country code we asked for in case a payload omits it.
                    provider.setCountryCode(firstNonBlank(item.country(), countryCode));
                    provider.setChannelCode(item.billerCode());
                    provider.setIsCrossBorderAllowed(Boolean.FALSE);
                    provider.setActive(Boolean.TRUE);
                    provider.setLogoUrl(null);
                    provider.setCustomerParamsSchema(null);
                    provider.setGateway("flutterwave");
                    // Flutterwave does not expose fetch requirements in this endpoint;
                    // a small JSON payload is stored so reads never choke on a null JSONB.
                    provider.setFetchRequirement(List.of(
                            Map.of("field", "customer_account", "label", "Customer account number")
                    ));
                    return provider;
                })
                .toList();
    }

    private static String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value.trim();
            }
        }
        return null;
    }

    /**
     * Normalises Flutterwave's free-text {@code category_name} onto the seed
     * {@code provider_categories} codes; unknown categories default to OTHERS.
     */
    static String resolveCategoryCode(String categoryName) {
        if (categoryName == null || categoryName.isBlank()) {
            return "OTHER";
        }
        String c = categoryName.toLowerCase();
        if (c.contains("airtime") || c.contains("data") || c.contains("mobile")) {
            return "AIRTIME";
        }
        if (c.contains("internet") || c.contains("broadband") || c.contains("wifi")) {
            return "INTERNET";
        }
        if (c.contains("tv") || c.contains("cable") || c.contains("satellite") || c.contains("dstv") || c.contains("gotv")) {
            return "TV_SUBSCRIPTION";
        }
        if (c.contains("electricity") || c.contains("power") || c.contains("water") || c.contains("utility")) {
            return "UTILITY";
        }
        if (c.contains("insurance")) {
            return "INSURANCE";
        }
        if (c.contains("government") || c.contains("tax") || c.contains("levy") || c.contains("revenue")) {
            return "GOVERNMENT";
        }
        if (c.contains("transport") || c.contains("toll") || c.contains("fare")) {
            return "TRANSPORT";
        }
        if (c.contains("education") || c.contains("school") || c.contains("tuition") || c.contains("fees")) {
            return "EDUCATION";
        }
        if (c.contains("health") || c.contains("hospital") || c.contains("medical")) {
            return "HEALTH";
        }
        if (c.contains("entertainment") || c.contains("ticket") || c.contains("event") || c.contains("betting")) {
            return "ENTERTAINMENT";
        }
        return "OTHER";
    }
}