package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.ServiceProviderModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ServiceProvidersRepository extends JpaRepository<ServiceProviderModel, UUID> {
    List<ServiceProviderModel> findByCountryCode(String countryCode);
    List<ServiceProviderModel> findByCategoryCode(String categoryCode);
    List<ServiceProviderModel> findByCountryCodeAndCategoryCode(String countryCode, String categoryCode);
}
