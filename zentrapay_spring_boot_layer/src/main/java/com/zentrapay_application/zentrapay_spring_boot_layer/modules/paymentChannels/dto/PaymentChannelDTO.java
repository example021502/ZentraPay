package com.zentrapay_application.zentrapay_spring_boot_layer.modules.paymentChannels.dto;

public record PaymentChannelDTO(
        String channelCode,
        String channelName,
        String channelType,
        String countryCode,
        String gateway
) {
}
