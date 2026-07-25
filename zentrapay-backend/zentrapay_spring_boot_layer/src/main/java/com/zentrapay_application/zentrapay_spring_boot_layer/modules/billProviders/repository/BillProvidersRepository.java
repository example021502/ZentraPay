package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.model.BillProvidersModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BillProvidersRepository extends JpaRepository<BillProvidersModel, String> {

    @Query(value = "SELECT * FROM bill_providers", nativeQuery = true)
    List<BillProvidersModel> getAllProviders();

}