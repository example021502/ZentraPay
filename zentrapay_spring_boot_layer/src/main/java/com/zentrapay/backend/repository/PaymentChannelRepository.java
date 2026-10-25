package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.PaymentChannel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PaymentChannelRepository extends JpaRepository<PaymentChannel, String> {
    List<PaymentChannel> findByCountryCodeAndChannelType(String countryCode, String channelType);
    List<PaymentChannel> findByCountryCode(String countryCode);
}
