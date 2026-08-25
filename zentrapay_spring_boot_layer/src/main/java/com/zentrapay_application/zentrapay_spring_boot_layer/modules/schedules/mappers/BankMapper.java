package com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.mappers;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BanksModel;
import java.util.List;

public interface BankMapper<T> {
    // Converts a gateway-specific response into a list of your database model
    List<BanksModel> mapToEntities(T apiResponse, String countryCode);
}