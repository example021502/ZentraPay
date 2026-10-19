package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Wire response for AfriqLink {@code POST /accounts/link} — the OPEN BANKING
 * account-linking call used by the ZBank Lite "link a bank" sheet.
 * <p>
 * NOTE: the AfriqLink account is not provisioned yet (base URL / keys in
 * application.properties are placeholders), so the response shape is
 * deliberately tolerant — unknown fields are ignored and {@code status} is
 * parsed from either a JSON boolean or a string. Confirm against the live
 * AfriqLink documentation before going to production.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record AfriqLinkAccountResponseDTO(
        String status,
        String message,
        LinkData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record LinkData(
            @JsonProperty("link_id") String linkId,
            @JsonProperty("account_reference") String accountReference,
            @JsonProperty("bank_code") String bankCode,
            @JsonProperty("account_number") String accountNumber
    ) {}

    /** Tolerant status check: "true" (boolean wire form), "success", "linked" or "1". */
    public boolean accepted() {
        if (status == null) {
            return false;
        }
        String value = status.trim();
        return "true".equalsIgnoreCase(value)
                || "success".equalsIgnoreCase(value)
                || "linked".equalsIgnoreCase(value)
                || "1".equals(value);
    }

    /**
     * Best reference for the link row's {@code connectionId}: the provider's
     * link id, else its account reference, else {@code null} (caller falls
     * back to a local {@code bankCode:lastDigits} id).
     */
    public String reference() {
        if (data == null) {
            return null;
        }
        if (data.linkId() != null && !data.linkId().isBlank()) {
            return data.linkId();
        }
        if (data.accountReference() != null && !data.accountReference().isBlank()) {
            return data.accountReference();
        }
        return null;
    }
}
