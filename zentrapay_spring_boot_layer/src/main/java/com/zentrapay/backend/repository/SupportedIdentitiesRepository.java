package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.SupportedIdentityTypesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SupportedIdentitiesRepository extends JpaRepository<SupportedIdentityTypesModel, Integer> {
    @Query("SELECT t.identityTypeName FROM SupportedIdentityTypesModel t WHERE t.country = :countryCode")
    String getIdentityTypeByCountryCode(@Param("countryCode") String countryCode);
}
