package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserSavingsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * ZGrow savings ledger. The hero total and its supporting metadata come
 * from the group-by aggregation below — never from client-side sums.
 */
public interface UserSavingsRepository extends JpaRepository<UserSavingsModel, UUID> {

    /** Projection of one currency bucket of the user's savings total. */
    interface CurrencyTotalProjection {
        String getCurrencyCode();
        BigDecimal getTotal();
        Long getEntryCount();
        LocalDateTime getLastSavedAt();
    }

    @Query("""
                SELECT s.currencyCode AS currencyCode,
                       SUM(s.amount) AS total,
                       COUNT(s) AS entryCount,
                       MAX(s.createdAt) AS lastSavedAt
                  FROM UserSavingsModel s
                 WHERE s.userId = :userId
                 GROUP BY s.currencyCode
                 ORDER BY s.currencyCode
            """)
    List<CurrencyTotalProjection> sumTotalsByCurrency(@Param("userId") UUID userId);
}
