package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.services;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dtos.BillProvidersResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.repository.BillProvidersRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.model.BillProvidersModel;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BillProvidersServices {

    private final BillProvidersRepository billProvidersRepository;

    public BillProvidersResponseDTO getAllBillProviders() {
        List<BillProvidersModel> providers = billProvidersRepository.getAllProviders();

        return new BillProvidersResponseDTO(providers);
    }

    public BillProvidersResponseDTO getProvidersByCategory(String category) {
        List<BillProvidersModel> providers = billProvidersRepository.findByCategory(category);

        return new BillProvidersResponseDTO(providers);
    }
}