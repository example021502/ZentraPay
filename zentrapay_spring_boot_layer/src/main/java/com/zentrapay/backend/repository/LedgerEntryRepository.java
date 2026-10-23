package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.LedgerEntryModel;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface LedgerEntryRepository extends JpaRepository<LedgerEntryModel, UUID> {}
