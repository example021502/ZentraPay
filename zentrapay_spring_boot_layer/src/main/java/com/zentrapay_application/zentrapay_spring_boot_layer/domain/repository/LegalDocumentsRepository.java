package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.LegalDocumentsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.UUID;

public interface LegalDocumentsRepository extends JpaRepository<LegalDocumentsModel, UUID> {
//    checking if the privacy policy document exist
    @Query("Select d FROM LegalDocumentsModel d WHERE d.documentId = :privacyPolicyId")
    boolean privacyPolicyDocumentExists(@Param("privacyPolicyId") UUID privacyPolicyId);

//    checking if the terms of use document exist
    @Query("Select d FROM LegalDocumentsModel d WHERE d.documentId = :termsOfUseId")
    boolean termsOfServiceDocumentExists(@Param("termsOfUseId") UUID termsOfUseId);
}
