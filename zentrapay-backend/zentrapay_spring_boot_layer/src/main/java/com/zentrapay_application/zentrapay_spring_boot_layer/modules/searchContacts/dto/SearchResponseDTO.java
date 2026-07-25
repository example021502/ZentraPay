package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model.SearchAppUsersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model.SearchBillProvidersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model.SearchFundingSourcesModel;

import java.util.List;
/**
 * DTO representing the data returned upon successful authentication.
 * We use a Java record here for immutability and conciseness.
 */
public record SearchResponseDTO(

        List<SearchAppUsersModel> appUsers,
        List<SearchBillProvidersModel> billProviders,
        List<SearchFundingSourcesModel> fundingSources
) {}
