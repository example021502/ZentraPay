package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Data
@Table(name = "transaction_types")
public class TransactionType {
    @Id
    @Column(name = "type_code", nullable = false, length = 30)
    private String typeCode;

    @Column(nullable = false, length = 120)
    private String description;

    @Column(name = "is_credit", nullable = false)
    private boolean isCredit;
}
