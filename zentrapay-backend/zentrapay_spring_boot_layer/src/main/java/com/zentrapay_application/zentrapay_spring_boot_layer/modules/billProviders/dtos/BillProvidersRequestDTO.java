package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dtos;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.model.BillProvidersModel;
import java.util.List;

public record BillProvidersResponseDTO(
        List<BillProvidersModel> providers
) {}