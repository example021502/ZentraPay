package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

/** GET /api/payment-channels — one selectable bank/mobile-money destination. */
public record PaymentChannelDTO(
        String channelCode,
        String channelName,
        String channelType,
        String countryCode,
        String gateway
) {
}
