package com.zentrapay.backend.dto.search;

import com.zentrapay.backend.service.common.Datatypes;

import java.util.UUID;

public record UserSearchDTO(
        UUID userId,
        String countryCode,
        String firstName,
        String lastName,
        String phoneNumber,
        String zentag,
        Datatypes.UserType type
) {}
