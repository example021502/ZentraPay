package com.zentrapay.backend.dto.payment;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Wire response for AfriqLink {@code POST /accounts/verify} — the OPEN BANKING
 * account-name lookup used by the send-money UI before a payout is confirmed
 * (replaces the Paystack / Flutterwave resolve calls, which are settlement
 * endpoints, not open banking).
 * <p>
 * Same tolerance caveats as {@link AfriqLinkAccountResponseDTO}: keys and
 * shape are placeholders until the AfriqLink account is provisioned.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record AfriqLinkVerifyResponseDTO(
        String status,
        String message,
        ResolveData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ResolveData(
            @JsonProperty("account_number") String accountNumber,
            @JsonProperty("account_name") String accountName
    ) {}

    /** Tolerant status check: "true" (boolean wire form), "success" or "1". */
    public boolean accepted() {
        if (status == null) {
            return false;
        }
        String value = status.trim();
        return "true".equalsIgnoreCase(value)
                || "success".equalsIgnoreCase(value)
                || "1".equals(value);
    }
}
