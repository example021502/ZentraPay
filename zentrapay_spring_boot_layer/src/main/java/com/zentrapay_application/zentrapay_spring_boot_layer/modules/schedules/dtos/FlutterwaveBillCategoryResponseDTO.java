package com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Flutterwave {@code GET /v3/bill-categories} response. The same shape serves
 * the full bill-provider directory ({@code ?country=NG}) and the mobile-money
 * subset ({@code ?category=momo&country=NG}), distinguished by
 * {@code is_mobile_money} / the fetched category.
 */
public record FlutterwaveBillCategoryResponseDTO(
        String status,
        String message,
        List<BillCategoryItemDTO> data
) {
    public record BillCategoryItemDTO(
            Long id,
            @JsonProperty("biller_code") String billerCode,
            @JsonProperty("biller_name") String billerName,
            String name,
            @JsonProperty("short_name") String shortName,
            @JsonProperty("item_code") String itemCode,
            String country,
            String currency,
            String gateway,
            @JsonProperty("category_name") String categoryName,
            @JsonProperty("is_airtime") Boolean isAirtime,
            @JsonProperty("is_mobile_money") Boolean isMobileMoney,
            @JsonProperty("default_commission") Double defaultCommission,
            String fee,
            @JsonProperty("date_added") String dateAdded
    ) {}
}