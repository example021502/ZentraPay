package com.zentrapay_application.zentrapay_spring_boot_layer.modules.serviceProviders.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.serviceProviders.models.ServiceProviderModel;
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
