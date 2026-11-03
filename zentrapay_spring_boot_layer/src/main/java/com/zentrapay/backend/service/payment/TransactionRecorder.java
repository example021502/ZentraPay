package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.repository.TransactionRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.NanoIdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Makes sure a payment attempt is NEVER lost: when something stops a payment before (or instead of)
 * the normal ledger flow - wrong PIN, not enough money, no gateway available, a rule that said no -
 * the attempt is still saved as a FAILED transaction with the reason, so the user's history and the
 * reports show every attempt, whatever its status.
 *
 * <p>No money moves for a recorded failure, so there are deliberately no ledger entries. Recording
 * is best effort and idempotent: it never throws (the caller is already handling a real error) and a
 * reference that already has a transaction is left alone (that transaction carries its own status).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TransactionRecorder {

    private final TransactionRepository transactionRepository;

    /**
     * Saves {@code draft} as FAILED. Missing mandatory fields get safe defaults, so an attempt that
     * failed on bad input is still recorded.
     */
    public void recordFailure(TransactionModel draft, String reason) {
        try {
            // A draft that was saved and then rolled back still carries its old id; this is a brand new row
            draft.setTransactionId(null);
            if (draft.getInternalReferenceId() == null || draft.getInternalReferenceId().isBlank()) {
                draft.setInternalReferenceId("FAIL-" + UUID.randomUUID());
            } else if (transactionRepository.findByInternalReferenceId(draft.getInternalReferenceId()).isPresent()) {
                return;
            }
            if (draft.getAmount() == null || draft.getAmount().signum() < 0) {
                draft.setAmount(BigDecimal.ZERO);
            }
            if (draft.getSourceCurrencyCode() == null || draft.getSourceCurrencyCode().isBlank()) {
                draft.setSourceCurrencyCode(draft.getDestinationCurrencyCode() == null ? "GHS" : draft.getDestinationCurrencyCode());
            }
            if (draft.getDestinationCurrencyCode() == null || draft.getDestinationCurrencyCode().isBlank()) {
                draft.setDestinationCurrencyCode(draft.getSourceCurrencyCode());
            }
            if (draft.getDestinationAmount() == null) {
                draft.setDestinationAmount(draft.getAmount());
            }
            if (draft.getPurpose() == null || draft.getPurpose().isBlank()) {
                draft.setPurpose("Payment");
            }
            draft.setEntryId(NanoIdGenerator.generate("ENT_"));
            draft.setStatus(Datatypes.TransactionStatus.FAILED);
            draft.setFailureReason(truncate(reason == null || reason.isBlank() ? "The payment could not be completed" : reason));
            transactionRepository.save(draft);
            log.info("Recorded failed {} {} ({}): {}", draft.getTransactionType(), draft.getInternalReferenceId(),
                    draft.getAmount(), draft.getFailureReason());
        } catch (RuntimeException e) {
            // Never hide the original problem behind a recording problem
            log.error("Could not record the failed attempt {}: {}", draft.getInternalReferenceId(), e.getMessage());
        }
    }

    private static String truncate(String text) {
        return text.length() > 250 ? text.substring(0, 250) : text;
    }
}
