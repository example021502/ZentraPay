package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model.SearchAppUsersModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SearchAppUsersRepository extends JpaRepository<SearchAppUsersModel, Long>, JpaSpecificationExecutor<SearchAppUsersModel> {

    // Query to match substring across fullName, zentag, or phoneNumber case-insensitively
    @Query("SELECT u FROM SearchAppUsersModel u WHERE " +
            "LOWER(u.fullName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(u.zentag) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(u.phoneNumber) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<SearchAppUsersModel> searchByQuery(String query);

}