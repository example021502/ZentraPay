package com.zentrapay.backend.dto.user;

/**
 * {@code GET/PUT /api/users/me/merchant-profile} (API contract §1) — maps to the
 * {@code merchant_profiles} table. {@code GET} returns {@code null} data if the
 * caller isn't a merchant. {@code PUT} upserts and sets {@code users.user_type=MERCHANT}.
 */
public record MerchantProfileDTO(
        String businessName,
        String businessRegistrationNumber,
        String taxIdentificationNumber,
        String businessCategoryCode,
        String businessCountryCode,
        String businessAddress
) {
}
