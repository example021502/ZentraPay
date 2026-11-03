package com.zentrapay.backend.dto.payment;

import java.math.BigDecimal;

/**
 * A bank account the user connected through the AfriLink Connect widget, as AfriLink reports it
 * ({@code GET /api/data/accounts/:id}). Normalised here because the field names AfriLink uses for
 * the institution / number differ between account types; see {@code AfriLinkClient#parse}.
 *
 * <p>Deliberately holds only what the app needs: the full account number is reduced to its last
 * digits at parse time and never kept.
 *
 * @param accountId       AfriLink's opaque account id (the {@code data.id} the widget returns)
 * @param ownerUserId     the {@code userId} the account was connected under at AfriLink (may be null)
 * @param institutionId   AfriLink's id/code for the bank (may be null)
 * @param institutionName bank name
 * @param accountType     savings / current ... (may be null)
 * @param currencyCode    ISO 4217 code (may be null)
 * @param lastDigits      last 4 digits of the account number ("" when AfriLink did not share it)
 * @param balance         balance AfriLink reports (zero when not shared)
 */
public record AfriLinkAccountDTO(
        String accountId,
        String ownerUserId,
        String institutionId,
        String institutionName,
        String accountType,
        String currencyCode,
        String lastDigits,
        BigDecimal balance
) {
}
