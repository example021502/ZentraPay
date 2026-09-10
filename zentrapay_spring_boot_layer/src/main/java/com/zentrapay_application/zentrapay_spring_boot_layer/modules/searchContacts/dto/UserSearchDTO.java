package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

public record UserSearchDTO(
    String countryCode,
    String email,
    String firstName,
    String lastName,
    String phoneNumber,
    String status,
    String userType
) {}
