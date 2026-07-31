package com.zentrapay_application.zentrapay_spring_boot_layer.modules.appusers.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Entity
@Table(name = "app_users")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AppUsersModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false, unique = true)
    private UUID userId;

    @Column(name = "first_name", nullable = false)
    private String firstName;

    @Column(name = "last_name", nullable = false)
    private String lastName;

    @Column(name = "zentag", nullable = false, unique = true)
    private String zentag;
}