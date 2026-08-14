package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BillProviderModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.BillProviderRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto.BillProviderDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class BillProvidersService {

    private final BillProviderRepository billProviderRepository;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    @Transactional(readOnly = true)
    public List<BillProviderDTO> listProviders(String countryCode) {
        return billProviderRepository.getAllBillProviders(countryCode).stream()
                .map(this::toBillProviderDTO)
                .toList();
    }

    private BillProviderDTO toBillProviderDTO(BillProviderModel p) {
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