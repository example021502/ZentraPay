package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.TransactionModel;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<TransactionModel, UUID> {

    // History for the home / transactions screens (money sent or received)
    @Query("SELECT t FROM TransactionModel t WHERE t.senderId = :userId OR t.receiverId = :userId ORDER BY t.createdAt DESC")
    Page<TransactionModel> findUserHistory(@Param("userId") UUID userId, Pageable pageable);

    // Idempotency: the app sends the same TXN_Ref when it retries a payment
    Optional<TransactionModel> findByInternalReferenceId(String internalReferenceId);

    // Webhooks: the gateway's own code for the transfer / charge
    Optional<TransactionModel> findByExternalReferenceId(String externalReferenceId);

    // Reconciliation job: payments still open (INITIATED / PENDING) since before the cutoff, oldest first
    @Query("SELECT t FROM TransactionModel t WHERE t.status IN :statuses AND t.updatedAt < :cutoff ORDER BY t.updatedAt")
    List<TransactionModel> findOpenBefore(@Param("statuses") Collection<com.zentrapay.backend.service.common.Datatypes.TransactionStatus> statuses,
                                          @Param("cutoff") LocalDateTime cutoff, Pageable pageable);

    // Webhooks and refunds read the row WITH a database lock, so two deliveries of
    // the same event (or a webhook racing a refund) are handled one after the other.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT t FROM TransactionModel t WHERE t.transactionId = :id")
    Optional<TransactionModel> findByIdForUpdate(@Param("id") UUID id);
}
