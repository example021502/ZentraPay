package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.DocumentModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.UUID;

public interface LegalDocumentsRepository extends JpaRepository<DocumentModel, UUID> {
    //    checking if the privacy policy document exist
    @Query("Select d FROM DocumentModel d WHERE d.documentId = :privacyPolicyId")
    boolean privacyPolicyDocumentExists(@Param("privacyPolicyId") UUID privacyPolicyId);

    //    checking if the terms of use document exist
    @Query("Select d FROM DocumentModel d WHERE d.documentId = :termsOfUseId")
    boolean termsOfServiceDocumentExists(@Param("termsOfUseId") UUID termsOfUseId);
}
