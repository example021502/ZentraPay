package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model;

import jakarta.persistence.*;
import lombok.Data;

import java.util.UUID;

@Entity
@Table(name = "users")
@Data // Requires Lombok dependency
public class usersModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(nullable = false, name = "user_id", unique = true)
    private UUID userId;

    @Column(nullable = false, name = "email", unique = true)
    private String email;

    @Column(nullable = false, name = "country")
    private String country;

    @Column(unique = true, nullable = false, name = "phone_number")
    private String phoneNumber;

    @Column(nullable = false, name = "password_hash")
    private String password; // Stores bcrypt hash

    @Column(nullable = false, name = "transaction_pin_hash")
    private String pin;      // Stores bcrypt hash

    @Column(nullable = false, name = "status")
    private String status;

    @Column(nullable = false, name = "zentag")
    private String zentag;
}