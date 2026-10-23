package com.zentrapay.backend.service.schedule.mapper;

import com.zentrapay.backend.entity.BanksModel;
import java.util.List;

public interface BankMapper<T> {
    // Converts a gateway-specific response into a list of your database model
    List<BanksModel> mapToEntities(T apiResponse, String countryCode);
}