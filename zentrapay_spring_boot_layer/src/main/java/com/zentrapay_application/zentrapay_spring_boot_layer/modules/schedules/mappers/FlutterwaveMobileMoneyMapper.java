package com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.mappers;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.MobileMoneyProvidersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos.FlutterwaveBillCategoryResponseDTO;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;

/**
 * Maps Flutterwave's {@code /bill-categories?category=momo} items into the
 * canonical {@code momo_providers} entity (MobileMoneyProvidersModel).
 * Gateway-level codes are kept in {@code momo_gateway_mappings} by the
 * calling sync service after the provider row is persisted.
 */
@Component
public class FlutterwaveMobileMoneyMapper {

    public List<MobileMoneyProvidersModel> mapToEntities(FlutterwaveBillCategoryResponseDTO response, String countryCode) {
        if (response == null || response.data() == null || !"success".equalsIgnoreCase(response.status())) {
            return Collections.emptyList();
        }

        return response.data().stream()
                .filter(item -> {
                    String name = firstNonBlank(item.billerName(), item.name(), item.shortName());
                    return name != null && item.billerCode() != null && !item.billerCode().isBlank();
                })
                .map(item -> {
                    MobileMoneyProvidersModel provider = new MobileMoneyProvidersModel();
                    provider.setName(firstNonBlank(item.billerName(), item.name(), item.shortName()));
                    provider.setGlobalCode(item.billerCode());
                    provider.setCountryCode(firstNonBlank(item.country(), countryCode));
                    provider.setActive(Boolean.TRUE);
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
}