package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.KYCDocumentModel;
import com.zentrapay.backend.entity.UserProfileModel;
import com.zentrapay.backend.service.common.Datatypes;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.awt.print.Pageable;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface KYCDocumentRepository extends JpaRepository<KYCDocumentModel, UUID> {
    Optional<KYCDocumentModel> getKycDocumentByUserId(@Param("userId") UUID userId);

    List<KYCDocumentModel> getQueuedDocuments(Datatypes.KYCDocumentVerificationStatus status, PageRequest page);
}
