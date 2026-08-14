package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "login_history")
public class LoginHistoryModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "login_id", nullable = false)
    private UUID loginId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "device_info", length = 200)
    private String deviceInfo;

    @Column(length = 120)
    private String location;

    @Column(nullable = false)
    private boolean success = true;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    /**
     * Canonical mapping of {@code bill_payments} (V1__init_schema.sql). Owned entirely by
     * this module — bill payments aren't a cross-module concept the way users/wallets/
     * transactions are.
     */
    @Entity
    @Data
    @Table(name = "bill_payments")
    public static class BillPaymentModel {
        @Id
        @GeneratedValue(strategy = GenerationType.UUID)
        @Column(name = "payment_id", nullable = false)
        private UUID paymentId;

        @Column(name = "user_id", nullable = false)
        private UUID userId;

        @Column(name = "provider_id", nullable = false)
        private UUID providerId;

        @Column(name = "transaction_id", nullable = false, unique = true)
        private UUID transactionId;

        @Column(name = "customer_reference", nullable = false, length = 60)
        private String customerReference;

        @Column(nullable = false, precision = 19, scale = 4)
        private BigDecimal amount;

        @Column(name = "currency_code", nullable = false, length = 3)
        private String currencyCode;

        @Column(nullable = false, length = 20)
        private String status = "PENDING";

        @CreationTimestamp
        @Column(name = "created_at", nullable = false)
        private LocalDateTime createdAt;
    }
}
