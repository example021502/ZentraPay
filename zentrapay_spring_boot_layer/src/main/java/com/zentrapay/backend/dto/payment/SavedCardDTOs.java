package com.zentrapay.backend.dto.payment;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/** Request / response shapes of the saved-card endpoints. The gateway token is never sent to the app. */
public final class SavedCardDTOs {

    private SavedCardDTOs() {
    }

    /**
     * A saved card as the app shows it ("Visa ending 4242, expires 09/28").
     *
     * @param expired true once the expiry month has passed: such a card cannot be charged
     */
    public record SavedCardDTO(UUID id, String gateway, String brand, String cardType, String last4, String bank,
                               Integer expMonth, Integer expYear, boolean isDefault, boolean expired,
                               LocalDateTime createdAt, LocalDateTime lastUsedAt) {
    }

    /** POST /api/topup/card - top up the wallet by charging a saved card. */
    public record ChargeCardRequest(
            @NotNull(message = "Choose a card") UUID cardId,
            @NotNull(message = "Amount is required")
            @DecimalMin(value = "1.00", message = "Amount must be at least 1.00") BigDecimal amount,
            @NotBlank(message = "Currency code is required") String currencyCode,
            @NotBlank(message = "Enter your transaction PIN") String pin) {
    }
}
