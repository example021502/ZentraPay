package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.dto.payment.RetryDTOs.RetryCheckDTO;
import com.zentrapay.backend.dto.payment.TransactionRequest;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.TransactionRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.user.PinService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Retry of a failed payment: both parties are checked again before the PIN is asked, an invalid party keeps
 * the payment failed with the reason, a wrong PIN does not use up the retry, and a payment is replayed once.
 */
class TransactionRetryServiceTest {

    private final UUID senderId = UUID.randomUUID();
    private final UUID receiverId = UUID.randomUUID();
    private final UUID failedId = UUID.randomUUID();

    private TransactionRepository transactions;
    private UserRepository users;
    private PaymentServices payments;
    private PinService pins;
    private TransactionRetryService service;
    private UserModel sender;
    private UserModel receiver;
    private TransactionModel failed;

    @BeforeEach
    void setUp() {
        transactions = mock(TransactionRepository.class);
        users = mock(UserRepository.class);
        payments = mock(PaymentServices.class);
        pins = mock(PinService.class);
        service = new TransactionRetryService(transactions, users, payments, pins);

        sender = user(senderId, "Ama", Datatypes.UserStatus.ACTIVE);
        receiver = user(receiverId, "Kofi", Datatypes.UserStatus.ACTIVE);
        failed = new TransactionModel();
        failed.setTransactionId(failedId);
        failed.setInternalReferenceId("REF-1");
        failed.setSenderId(senderId);
        failed.setReceiverId(receiverId);
        failed.setReceiverName("Kofi Mensah");
        failed.setDestinationIdentifier("kofi");
        failed.setAmount(new BigDecimal("25.00"));
        failed.setSourceCurrencyCode("GHS");
        failed.setDestinationCurrencyCode("GHS");
        failed.setPurpose("Lunch");
        failed.setTransactionType(Datatypes.TransactionType.P2P_TRANSFER);
        failed.setStatus(Datatypes.TransactionStatus.FAILED);

        when(transactions.findById(failedId)).thenReturn(Optional.of(failed));
        when(transactions.findByInternalReferenceId(anyString())).thenReturn(Optional.empty());
        when(users.findById(senderId)).thenReturn(Optional.of(sender));
        when(users.findById(receiverId)).thenReturn(Optional.of(receiver));
        when(payments.resolveReceiverAccount(any(), any(), any(), anyBoolean())).thenReturn(new FiatAccountModel());
    }

    private static UserModel user(UUID id, String first, Datatypes.UserStatus status) {
        UserModel u = new UserModel();
        u.setUserId(id);
        u.setFirstName(first);
        u.setLastName("Mensah");
        u.setCountryCode("GH");
        u.setStatus(status);
        return u;
    }

    @Test
    void bothPartiesValidMeansRetryable() {
        RetryCheckDTO check = service.check(senderId, failedId);
        assertTrue(check.retryable());
        assertEquals("Kofi Mensah", check.receiverName());
        assertEquals(new BigDecimal("25.00"), check.amount());
    }

    @Test
    void receiverGoneKeepsThePaymentFailedWithTheReason() {
        when(users.findById(receiverId)).thenReturn(Optional.empty());

        RetryCheckDTO check = service.check(senderId, failedId);

        assertFalse(check.retryable());
        assertEquals("The receiver no longer exists on ZentraPay.", failed.getFailureReason());
        verify(transactions).save(failed);
        verify(pins, never()).requireValid(any(), anyString());
    }

    @Test
    void receiverAccountGoneIsNotRetryable() {
        when(payments.resolveReceiverAccount(any(), any(), any(), anyBoolean()))
                .thenThrow(new ResourceNotFoundException("Recipient account not found"));

        RetryCheckDTO check = service.check(senderId, failedId);

        assertFalse(check.retryable());
        assertTrue(failed.getFailureReason().contains("no longer available"));
    }

    @Test
    void inactiveReceiverOrSenderIsNotRetryable() {
        receiver.setStatus(Datatypes.UserStatus.FROZEN);
        assertFalse(service.check(senderId, failedId).retryable());

        receiver.setStatus(Datatypes.UserStatus.ACTIVE);
        sender.setStatus(Datatypes.UserStatus.INACTIVE);
        assertFalse(service.check(senderId, failedId).retryable());
    }

    @Test
    void someoneElsesPaymentIsNotFound() {
        assertThrows(ResourceNotFoundException.class, () -> service.check(UUID.randomUUID(), failedId));
    }

    @Test
    void onlyFailedPaymentsCanBeRetried() {
        failed.setStatus(Datatypes.TransactionStatus.SUCCESS);
        assertThrows(IllegalArgumentException.class, () -> service.check(senderId, failedId));
    }

    @Test
    void bankPayoutsNeedANewVerifiedTransfer() {
        failed.setTransactionType(Datatypes.TransactionType.CASH_OUT_BANK);
        RetryCheckDTO check = service.check(senderId, failedId);
        assertFalse(check.retryable());
        assertTrue(check.message().contains("verify the account again"));
    }

    @Test
    void anAlreadyRetriedPaymentIsNotRetriedTwice() {
        TransactionModel earlier = new TransactionModel();
        earlier.setStatus(Datatypes.TransactionStatus.SUCCESS);
        when(transactions.findByInternalReferenceId("RTY-" + failedId)).thenReturn(Optional.of(earlier));

        RetryCheckDTO check = service.check(senderId, failedId);

        assertFalse(check.retryable());
        assertTrue(check.message().contains("already retried"));
    }

    @Test
    void retryChecksThePinFirstThenPaysWithAStableReference() {
        service.retry(senderId, failedId, "1234");

        verify(pins).requireValid(sender, "1234");
        ArgumentCaptor<TransactionRequest> sent = ArgumentCaptor.forClass(TransactionRequest.class);
        verify(payments).initialize(eq(senderId), sent.capture());
        TransactionRequest request = sent.getValue();
        assertEquals("RTY-" + failedId, request.TXN_Ref());
        assertEquals(Datatypes.TransactionType.P2P_TRANSFER, request.transactionType());
        assertEquals(receiverId, request.appUser().userId());
        assertEquals("kofi", request.appUser().zentag());
        assertEquals(new BigDecimal("25.00"), request.transfer().amount());
        assertEquals("GHS", request.transfer().currencyCode());
    }

    @Test
    void aWrongPinPaysNothingAndRecordsNothing() {
        doThrow(new IllegalArgumentException("Invalid PIN")).when(pins).requireValid(sender, "0000");

        assertThrows(IllegalArgumentException.class, () -> service.retry(senderId, failedId, "0000"));

        verify(payments, never()).initialize(any(), any());
    }

    @Test
    void retryRefusedWhenAPartyIsNoLongerValid() {
        when(users.findById(receiverId)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class, () -> service.retry(senderId, failedId, "1234"));

        verify(pins, never()).requireValid(any(), anyString());
        verify(payments, never()).initialize(any(), any());
    }
}
