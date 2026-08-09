package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.PaymentChannel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PaymentChannelRepository extends JpaRepository<PaymentChannel, String> {
    List<PaymentChannel> findByCountryCodeAndChannelType(String countryCode, String channelType);
    List<PaymentChannel> findByCountryCode(String countryCode);
}
