package com.zentrapay.backend.dto.user;

import com.zentrapay.backend.service.common.Datatypes;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Response shape for {@code GET/PATCH /api/users/me} (API contract §1):
 * {@code {userId,firstName,lastName,email,phoneNumber,countryCode,zentag,userType,status,kycTier}}.
 * <p>
 * {@code zentag} is the account-level tag minted on the caller's default fiat
 * account — it is NOT part of the JWT claims, so it is resolved server-side.
 * This record is what the receive-QR generator renders its payload from, so it
 * must carry every identity field a scanner needs to start a payment.
 */
public record UserQRInfo(
        UUID userId,
        String email,
        String firstName,
        String lastName,
        String phoneNumber,
        String countryCode,
        String zentag,
        Datatypes.UserType userType
) {
}
