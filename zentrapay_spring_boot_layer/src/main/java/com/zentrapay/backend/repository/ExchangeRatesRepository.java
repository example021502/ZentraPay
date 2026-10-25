package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.ExchangeRateModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ExchangeRatesRepository extends JpaRepository<ExchangeRateModel, UUID> {

    // Latest published rate for a direct pair.
    Optional<ExchangeRateModel> findFirstByBaseCurrencyCodeIgnoreCaseAndQuoteCurrencyCodeIgnoreCaseOrderByEffectiveAtDesc(
            String baseCurrencyCode, String quoteCurrencyCode);

    // All latest rows involving one side — used for USD triangulation lookups.
    @Query("SELECT r FROM ExchangeRateModel r " +
            "WHERE LOWER(r.baseCurrencyCode) = :base AND LOWER(r.quoteCurrencyCode) = :quote " +
            "AND r.effectiveAt = (SELECT MAX(r2.effectiveAt) FROM ExchangeRateModel r2 " +
            "WHERE LOWER(r2.baseCurrencyCode) = :base AND LOWER(r2.quoteCurrencyCode) = :quote)")
    Optional<ExchangeRateModel> findLatest(@Param("base") String baseCurrencyCode,
                                           @Param("quote") String quoteCurrencyCode);
}