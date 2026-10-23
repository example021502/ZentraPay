package com.zentrapay.backend.service.provider;

import com.zentrapay.backend.dto.provider.ServiceProviderDTO;
import com.zentrapay.backend.entity.ServiceProviderModel;
import com.zentrapay.backend.repository.ServiceProvidersRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ServiceProvidersServices {

    private final ServiceProvidersRepository serviceProvidersRepository;

    public List<ServiceProviderDTO> getProviders(String countryCode, String categoryCode) {
        List<ServiceProviderModel> providers;
        boolean hasCountry = countryCode != null && !countryCode.isBlank();
        boolean hasCategory = categoryCode != null && !categoryCode.isBlank();
        if (hasCountry && hasCategory) {
            providers = serviceProvidersRepository.findByCountryCodeAndCategoryCode(countryCode.toUpperCase(), categoryCode.toUpperCase());
        } else if (hasCountry) {
            providers = serviceProvidersRepository.findByCountryCode(countryCode.toUpperCase());
        } else if (hasCategory) {
            providers = serviceProvidersRepository.findByCategoryCode(categoryCode.toUpperCase());
        } else {
            providers = serviceProvidersRepository.findAll();
        }
        return providers.stream()
                .filter(ServiceProviderModel::isActive)
                .map(p -> new ServiceProviderDTO(p.getProviderId(), p.getProviderName(), p.getCategoryCode(),
                        p.getLogoUrl(), p.getMinAmount(), p.getMaxAmount(), p.getCountryCode()))
                .toList();
    }
}
