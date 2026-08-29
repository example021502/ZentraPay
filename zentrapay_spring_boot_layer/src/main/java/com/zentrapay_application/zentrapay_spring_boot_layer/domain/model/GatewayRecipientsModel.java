package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "banks")
public class GatewayRecipientsModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "bank_id", nullable = false)
    private UUID bankId;

    @Column(name = "code", nullable = false, unique = true)
    private String code;

    @Column(name = "bank_name", nullable = false)
    private String bankName;

    @Column(name = "gateway", nullable = false)
    private String gateway;

    @Column(name = "iban")
    private String iban;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "pay_with_bank")
    private Boolean payWithBank;

    @Column(name = "swift_bic")
    private String swiftBic;

    @Column(name = "country_code", length = 3)
    private String countryCode;

    @Column(name = "country")
    private String country;

    @Column(name = "status", nullable = false)
    private String status;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @CreationTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "max_daily_value")
    private String maxDailyValue;

    @Column(name = "max_monthly_value")
    private String maxMonthlyValue;

    @Column(name = "min_txn_limit")
    private String minTxnLimit;

    @Column(name = "max_txn_limit")
    private String maxTxnLimit;

    @Column(name = "maxWeeklyValue")
    private String maxWeeklyValue;

}
