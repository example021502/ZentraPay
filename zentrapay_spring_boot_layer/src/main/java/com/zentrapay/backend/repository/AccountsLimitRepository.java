package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.AccountsLimitModel;
import com.zentrapay.backend.entity.CurrenciesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AccountsLimitRepository extends JpaRepository<AccountsLimitModel, UUID> {
    Optional<AccountsLimitModel> getLimitByKycTier(short tier);
}
