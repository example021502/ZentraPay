package com.zentrapay.backend.dto.gateway;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.math.BigDecimal;

// Wire response DTO for Flutterwave bill payment requests
@JsonIgnoreProperties(ignoreUnknown = true)
public record FlutterwaveBillPaymentResponseDTO(
        String status,
        String message,
        BillPaymentData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record BillPaymentData(
            String reference,
            @JsonProperty("tx_ref") String txRef,
            @JsonProperty("flw_ref") String flwRef,
            @JsonProperty("phone_number") String phoneNumber,
            String network,
            String code,
            BigDecimal amount,
            BigDecimal fee,
            @JsonProperty("recharge_token") @JsonAlias("token") String rechargeToken
    ) {
    }
}