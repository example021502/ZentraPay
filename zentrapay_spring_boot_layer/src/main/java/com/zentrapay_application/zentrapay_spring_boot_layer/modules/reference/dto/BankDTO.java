package com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.dto;

import java.util.UUID;

/**
 * Bank catalog row for {@code GET /api/reference/banks} — what the ZBank
 * "link a bank" sheet lets the user pick from.
 *
 * {@code bankId} is the catalog id the user then POSTs to
 * {@code /api/zbanking/link}; the catalog itself is read-only seed data.
 */
public record BankDTO(
    UUID bankId,
    String code,
    String bankName,
    String gateway,
    String currencyCode,
    String countryCode,
    String country,
    String swiftBic,
    String routingNumber,
    String type
) {
}
