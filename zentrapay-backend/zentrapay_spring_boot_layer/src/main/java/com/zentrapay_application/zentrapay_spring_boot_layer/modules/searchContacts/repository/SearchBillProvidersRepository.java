package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model.SearchBillProvidersModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
    public interface SearchBillProvidersRepository extends JpaRepository<SearchBillProvidersModel, Long> {
    @Query("SELECT p FROM SearchBillProvidersModel p WHERE " +
            "LOWER(p.billerName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(p.category) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(p.status) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<SearchBillProvidersModel> searchByQuery(String query);
    }
