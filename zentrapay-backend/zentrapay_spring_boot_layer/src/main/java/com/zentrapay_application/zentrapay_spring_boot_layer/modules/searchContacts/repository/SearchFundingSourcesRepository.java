package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model.SearchFundingSourcesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
    public interface SearchFundingSourcesRepository extends JpaRepository<SearchFundingSourcesModel, String> {
    @Query("SELECT f FROM SearchFundingSourcesModel f WHERE " +
            "LOWER(f.fundingType) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(f.sourceName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(f.accountName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(f.bankCode) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(f.currency) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(f.isPrimary) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(f.accountIdentifier) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<SearchFundingSourcesModel> searchByQuery(String query);
    }
