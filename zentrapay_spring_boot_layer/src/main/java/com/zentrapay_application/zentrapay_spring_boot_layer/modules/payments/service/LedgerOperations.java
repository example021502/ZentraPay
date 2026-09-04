package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.NotificationModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FiatAccountRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.NotificationRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Individually-committing ledger writes for {@link PaymentsService}.
 * <p>
 * {@code processBankTransfer} spans slow external gateway HTTP calls between
 * ledger writes and, on total failure, needs to both compensate (credit
 * back) an earlier debit AND persist a "failed" audit row — while still
 * throwing so the caller sees the failure. Wrapping the whole flow in one
 * {@code @Transactional} method would roll every one of those writes back
 * the moment that exception is thrown. Each method here is a separate,
 * independently-committing transaction ({@code REQUIRES_NEW}) on a
 * different bean, so it survives regardless of what the caller does
 * afterward — the correct shape for compensating ledger entries anyway.
 * <p>
 * {@code debit}/{@code credit} specifically also need SOME active
 * transaction to run at all — they're {@code @Modifying} queries, which the
 * JPA spec requires to execute inside a transaction.
 */
@Service
@RequiredArgsConstructor
public class LedgerOperations {

    private final FiatAccountRepository fiatAccountRepository;
    private final TransactionRepository transactionRepository;
    private final NotificationRepository notificationRepository;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int debit(UUID walletId, BigDecimal amount, String currencyCode) {
        return fiatAccountRepository.debit(walletId, amount, currencyCode);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int credit(UUID walletId, BigDecimal amount, String currencyCode) {
        return fiatAccountRepository.credit(walletId, amount, currencyCode);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public TransactionModel saveTransaction(TransactionModel transaction) {
        return transactionRepository.save(transaction);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void saveNotification(NotificationModel notification) {
        notificationRepository.save(notification);
    }
}
