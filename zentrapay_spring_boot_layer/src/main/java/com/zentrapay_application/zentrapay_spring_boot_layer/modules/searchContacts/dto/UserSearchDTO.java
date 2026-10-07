package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

import java.util.UUID;

public record UserSearchDTO(
        UUID userId,
        String countryCode,
        String email,
        String firstName,
        String lastName,
        String phoneNumber,
        String zentag,
        Datatypes.UserType type
) {}
