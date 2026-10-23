package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.MerchantProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface MerchantProfileRepository extends JpaRepository<MerchantProfile, UUID> {
}
