package com.zentrapay.backend.service.mobilemoney;

import com.zentrapay.backend.entity.MobileMoneyGatewayMappingsModel;
import com.zentrapay.backend.entity.MobileMoneyProvidersModel;
import com.zentrapay.backend.repository.MobileMoneyGatewayMappingsRepository;
import com.zentrapay.backend.repository.MobileMoneyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

/**
 * Finds a mobile-money network in our catalogue and translates it to the code a given gateway uses
 * (the same network has a different code on each gateway; see {@code momo_gateway_mappings}).
 */
@Service
@RequiredArgsConstructor
public class MobileMoneyCatalogService {

    private final MobileMoneyRepository mobileMoneyRepository;
    private final MobileMoneyGatewayMappingsRepository mappingsRepository;

    /** The network the app picked: by id, else by code + country. */
    public Optional<MobileMoneyProvidersModel> findProvider(UUID providerId, String code, String countryCode) {
        if (providerId != null) {
            Optional<MobileMoneyProvidersModel> byId = mobileMoneyRepository.findById(providerId);
            if (byId.isPresent()) {
                return byId;
            }
        }
        if (code == null || code.isBlank() || countryCode == null || countryCode.isBlank()) {
            return Optional.empty();
        }
        return mobileMoneyRepository.findByGlobalCodeAndCountryCode(code.trim(), countryCode.trim().toUpperCase());
    }

    /** The code of this network on the given gateway, or null when that gateway does not list it. */
    public String codeOnGateway(MobileMoneyProvidersModel provider, String gatewayName) {
        return mappingsRepository.findByProviderIdAndGateway(provider.getProviderId(), gatewayName.toLowerCase())
                .map(MobileMoneyGatewayMappingsModel::getGatewayCode)
                .orElse(null);
    }
}
