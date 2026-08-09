package com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.model.ExchangeRate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ExchangeRateRepository extends JpaRepository<ExchangeRate, java.util.UUID> {
    Optional<ExchangeRate> findFirstByBaseCurrencyCodeAndQuoteCurrencyCodeOrderByEffectiveAtDesc(
            String baseCurrencyCode, String quoteCurrencyCode);
}
