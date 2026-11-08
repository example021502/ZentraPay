package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.util.Locale;

/**
 * Stores {@link Datatypes.AntiMoneyStatuses} in {@code user_profiles.anti_money_laundering_status}
 * as text ({@code CLEAR}, {@code IN_REVIEW}, {@code FLAGGED}), which is what the
 * {@code user_profiles_aml_status_check} constraint expects. Without this, Hibernate writes the
 * enum's ordinal number and every new profile row is rejected. Rows written as
 * {@code PENDING_REVIEW} (the spelling in migration V1) are read back as {@code IN_REVIEW}.
 */
@Converter
public class AmlStatusConverter implements AttributeConverter<Datatypes.AntiMoneyStatuses, String> {

    @Override
    public String convertToDatabaseColumn(Datatypes.AntiMoneyStatuses status) {
        if (status == null) {
            return null;
        }
        return switch (status) {
            case CLEAR -> "CLEAR";
            case IN_REVIEW -> "IN_REVIEW";
            case FLAGGED -> "FLAGGED";
        };
    }

    @Override
    public Datatypes.AntiMoneyStatuses convertToEntityAttribute(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return switch (value.trim().toUpperCase(Locale.ROOT)) {
            case "CLEAR" -> Datatypes.AntiMoneyStatuses.CLEAR;
            case "PENDING_REVIEW", "IN_REVIEW" -> Datatypes.AntiMoneyStatuses.IN_REVIEW;
            case "FLAGGED" -> Datatypes.AntiMoneyStatuses.FLAGGED;
            default -> throw new IllegalArgumentException("Unknown anti-money-laundering status: " + value);
        };
    }
}
