package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.dto.payment.RetryDTOs.RetryCheckDTO;
import com.zentrapay.backend.dto.payment.TransactionRequest;
import com.zentrapay.backend.dto.transaction.TransactionTransactionDTO;
import com.zentrapay.backend.entity.FiatAccountModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.TransactionRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.user.PinService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

/**
 * "Retry" on a failed payment.
 *
 * <p>Step 1, {@link #check}: no PIN, nothing moves. It looks at BOTH parties again - the sender (the
 * signed-in user) and the receiver. If either is no longer valid, the payment stays failed and that
 * reason is written on it. Otherwise the app asks for the PIN.
 * <p>Step 2, {@link #retry}: checks again (things may have changed), verifies the PIN, then makes the
 * payment through the normal send flow with the reference {@code RTY-<failed transaction id>}, so one failed
 * payment can never be paid twice. If that retry fails too, the new failed row can be retried in turn.
 *
 * <p>Only wallet-to-wallet payments can be replayed: for a bank / mobile-money payout the full account number
 * is deliberately never stored (only a masked copy), so those need a new transfer with the account verified again.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TransactionRetryService {

    static final String REF_PREFIX = "RTY-";

    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final PaymentServices paymentServices;
    private final PinService pinService;

    /** Looks at both parties of a failed payment again. */
    public RetryCheckDTO check(UUID userId, UUID transactionId) {
        return evaluate(userId, transactionId).check();
    }

    /** Re-checks both parties, verifies the PIN and makes the payment again. */
    public TransactionTransactionDTO retry(UUID userId, UUID transactionId, String pin) {
        Evaluation e = evaluate(userId, transactionId);
        if (!e.check().retryable()) {
            throw new IllegalArgumentException(e.check().message());
        }
        // A wrong PIN must not use up the retry, so it is verified before anything is recorded
        pinService.requireValid(e.sender(), pin);

        TransactionModel failed = e.failed();
        TransactionRequest request = new TransactionRequest(
                pin,
                REF_PREFIX + failed.getTransactionId(),
                new TransactionRequest.TransferDetails(failed.getAmount(), failed.getSourceCurrencyCode(), null,
                        failed.getPurpose(), failed.getDestinationCurrencyCode(), null),
                new TransactionRequest.AppUserDetails(failed.getReceiverId(), failed.getDestinationIdentifier()),
                null, null, Datatypes.TransactionType.P2P_TRANSFER, null);
        log.info("Retrying failed payment {} for user {}", failed.getInternalReferenceId(), userId);
        return paymentServices.initialize(userId, request);
    }

    private record Evaluation(RetryCheckDTO check, TransactionModel failed, UserModel sender) {
    }

    private Evaluation evaluate(UUID userId, UUID transactionId) {
        TransactionModel failed = transactionRepository.findById(transactionId)
                .filter(t -> userId.equals(t.getSenderId()))
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found"));
        UserModel sender = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (failed.getStatus() != Datatypes.TransactionStatus.FAILED && failed.getStatus() != Datatypes.TransactionStatus.EXPIRED) {
            throw new IllegalArgumentException("Only a failed payment can be retried");
        }
        if (failed.getTransactionType() != Datatypes.TransactionType.P2P_TRANSFER) {
            boolean payout = failed.getTransactionType() == Datatypes.TransactionType.CASH_OUT_BANK
                    || failed.getTransactionType() == Datatypes.TransactionType.CASH_OUT_MOMO;
            return no(failed, sender, payout
                    ? "For your safety the full account number is not kept, so this payment cannot be repeated automatically. "
                    + "Start a new transfer and verify the account again."
                    : "This kind of payment cannot be retried.");
        }

        // Already retried?
        Optional<TransactionModel> earlier = transactionRepository.findByInternalReferenceId(REF_PREFIX + failed.getTransactionId());
        if (earlier.isPresent()) {
            TransactionModel r = earlier.get();
            boolean failedAgain = r.getStatus() == Datatypes.TransactionStatus.FAILED
                    || r.getStatus() == Datatypes.TransactionStatus.EXPIRED;
            return no(failed, sender, failedAgain
                    ? "This payment was retried and failed again (" + nz(r.getFailureReason(), "see the newest attempt")
                    + "). Retry the newest attempt in your history."
                    : "This payment was already retried and is " + r.getStatus().name().toLowerCase() + ".");
        }

        // The sender (the person asking)
        if (sender.getStatus() != Datatypes.UserStatus.ACTIVE) {
            return invalid(failed, sender, "Your account is " + sender.getStatus() + " at the moment, so this payment cannot be retried.");
        }

        // The receiver
        if (failed.getReceiverId() == null) {
            return invalid(failed, sender, "The receiver of this payment is unknown, so it cannot be retried.");
        }
        UserModel receiver = userRepository.findById(failed.getReceiverId()).orElse(null);
        if (receiver == null) {
            return invalid(failed, sender, "The receiver no longer exists on ZentraPay.");
        }
        if (receiver.getUserId().equals(sender.getUserId())) {
            return invalid(failed, sender, "You cannot send money to yourself.");
        }
        if (receiver.getStatus() != Datatypes.UserStatus.ACTIVE) {
            return invalid(failed, sender, "The receiver's account cannot receive money at the moment.");
        }
        if (!nz(sender.getCountryCode(), "").equalsIgnoreCase(nz(receiver.getCountryCode(), ""))) {
            return invalid(failed, sender, "The receiver is in another country. Use ZRemit to send them money.");
        }
        try {
            FiatAccountModel account = paymentServices.resolveReceiverAccount(
                    receiver.getUserId(), failed.getDestinationIdentifier(), failed.getDestinationCurrencyCode(), true);
            if (account == null) {
                return invalid(failed, sender, "The receiver has no account to receive this payment.");
            }
        } catch (RuntimeException e) {
            return invalid(failed, sender, "The receiver's account is no longer available: " + e.getMessage());
        }

        String name = nz(failed.getReceiverName(), receiver.getFirstName() + " " + receiver.getLastName());
        return new Evaluation(new RetryCheckDTO(true, "Both accounts are valid. Enter your PIN to try again.", name,
                failed.getAmount(), failed.getSourceCurrencyCode()), failed, sender);
    }

    // Not retryable for a fixed reason that says nothing new about the parties
    private Evaluation no(TransactionModel failed, UserModel sender, String message) {
        return new Evaluation(new RetryCheckDTO(false, message, failed.getReceiverName(), failed.getAmount(),
                failed.getSourceCurrencyCode()), failed, sender);
    }

    // A party is no longer valid: the payment stays failed and carries this reason
    private Evaluation invalid(TransactionModel failed, UserModel sender, String message) {
        if (!message.equals(failed.getFailureReason())) {
            failed.setFailureReason(message.length() > 250 ? message.substring(0, 250) : message);
            transactionRepository.save(failed);
        }
        return no(failed, sender, message);
    }

    private static String nz(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
