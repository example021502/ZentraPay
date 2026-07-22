package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "users")
@Data // Requires Lombok dependency
public class usersModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(nullable = false, name = "user_id", unique = true)
    private String userId;

    @Column(nullable = false, name = "full_name")
    private String fullName;

    @Column(unique = true, nullable = false, name = "email")
    private String email;

    @Column(unique = true, nullable = false, name = "phone_number")
    private String phoneNumber;

    @Column(nullable = false, name = "password")
    private String password; // Stores bcrypt hash

    @Column(nullable = false, name = "pin")
    private String pin;      // Stores bcrypt hash

    @Column(nullable = false, name = "zentag")
    private String zentag;

    @Column(nullable = false, name = "country")
    private String country;
}