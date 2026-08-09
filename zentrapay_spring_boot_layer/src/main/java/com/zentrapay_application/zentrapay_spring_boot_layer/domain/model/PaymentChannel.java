package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Data
@Table(name = "payment_channels")
public class PaymentChannel {
    @Id
    @Column(name = "channel_code", nullable = false, length = 30)
    private String channelCode;

    @Column(name = "channel_name", nullable = false, length = 120)
    private String channelName;

    @Column(name = "channel_type", nullable = false, length = 20)
    private String channelType; // BANK, MOBILE_MONEY

    @Column(name = "country_code", nullable = false, length = 2)
    private String countryCode;

    @Column(nullable = false, length = 30)
    private String gateway;

    @Column(name = "is_active", nullable = false)
    private boolean isActive;
}
