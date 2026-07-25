package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model;

import jakarta.persistence.*;
import lombok.Data;

//CRYPTO CURRENCY DATA
@Entity
@Table(name = "users")
@Data // Requires Lombok dependency
public class SearchAppUsersModel {
    @Id
    @Column(nullable = false, name = "user_id", unique = true)
    private String userId;

    @Column(nullable = false, name = "full_name")
    private String fullName;

    private String userType = "app user";

    @Column(nullable = false, name = "phone_number")
    private String phoneNumber;

    @Column(nullable = false, name = "created_at")
    private String createdAt;

    @Column(nullable = false, name = "updated_at")
    private String updatedAt; // Stores bcrypt hash

    @Column(nullable = false, name = "email")
    private String email;      // Stores bcrypt hash

    @Column(nullable = false, name = "country")
    private String country;      // Stores bcrypt hash

    @Column(nullable = false, name = "zentag")
    private String zentag;      // Stores bcrypt hash

}
