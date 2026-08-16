package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record UserSearchDTO(
UUID userId,
String countryCode,
String email,
String firstName,
String lastName,
String phoneNumber,
String status,
String userType,
LocalDateTime updatedAt,
LocalDateTime createdAt
) {
}