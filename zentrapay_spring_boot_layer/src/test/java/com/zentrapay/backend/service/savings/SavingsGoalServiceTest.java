package com.zentrapay.backend.service.savings;

import com.zentrapay.backend.entity.FiatAccountModel;
import com.zentrapay.backend.entity.SavingsGoalModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.repository.SavingsGoalRepository;
import com.zentrapay.backend.repository.TransactionRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.repository.UserSavingsRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.payment.LedgerOperations;
import com.zentrapay.backend.service.payment.TransactionRecorder;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.transaction.support.TransactionCallback;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Rules of the savings goal controls: the 7-day freeze limit, a frozen goal refusing deposits, an automatic
 * save being claimed exactly once, and a deleted goal giving its savings back.
 *
 * <p>Plain unit test - no database, no Spring: every collaborator is a mock and the transaction template just
 * runs its callback.
 */
class SavingsGoalServiceTest {

    private final UUID userId = UUID.randomUUID();
    private final UUID goalId = UUID.randomUUID();

    private SavingsGoalRepository goalRepository;
    private LedgerOperations ledger;
    private TransactionRecorder recorder;
    private UserSavingsRepository userSavings;
    private SavingsGoalService service;
    private SavingsGoalModel goal;

    @BeforeEach
    @SuppressWarnings("unchecked")
    void setUp() {
        goalRepository = mock(SavingsGoalRepository.class);
        ledger = mock(LedgerOperations.class);
        recorder = mock(TransactionRecorder.class);
        userSavings = mock(UserSavingsRepository.class);
        UserRepository users = mock(UserRepository.class);
        TransactionTemplate tx = mock(TransactionTemplate.class);
        when(tx.execute(any())).thenAnswer(inv -> ((TransactionCallback<Object>) inv.getArgument(0)).doInTransaction(null));

        service = new SavingsGoalService(goalRepository, mock(TransactionRepository.class), users, userSavings, ledger, recorder, tx);

        UserModel user = mock(UserModel.class);
        when(user.getStatus()).thenReturn(Datatypes.UserStatus.ACTIVE);
        when(users.findById(userId)).thenReturn(Optional.of(user));

        goal = new SavingsGoalModel();
        goal.setGoalId(goalId);
        goal.setUserId(userId);
        goal.setGoalName("Rent fund");
        goal.setCurrencyCode("GHS");
        goal.setSavedAmount(new BigDecimal("50.00"));
        when(goalRepository.findById(goalId)).thenReturn(Optional.of(goal));
        when(goalRepository.findOwnedForUpdate(goalId, userId)).thenReturn(Optional.of(goal));
        when(goalRepository.findByIdForUpdate(goalId)).thenReturn(Optional.of(goal));
        when(goalRepository.save(any(SavingsGoalModel.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    // ------------------------------------------------------------------ freeze

    @Test
    void aFreezeOfZeroOrMoreThanSevenDaysIsRefused() {
        assertThrows(IllegalArgumentException.class, () -> service.freeze(userId, goalId, 0));
        assertThrows(IllegalArgumentException.class, () -> service.freeze(userId, goalId, 8));
        assertNull(goal.getFrozenUntil());
    }

    @Test
    void aSevenDayFreezeEndsAboutAWeekFromNow() {
        service.freeze(userId, goalId, 7);
        LocalDateTime until = goal.getFrozenUntil();
        assertNotNull(until);
        assertTrue(until.isAfter(LocalDateTime.now().plusDays(7).minusMinutes(1)));
        assertFalse(until.isAfter(LocalDateTime.now().plusDays(7).plusMinutes(1)));
    }

    @Test
    void aGoalThatIsAlreadyFrozenCannotBeFrozenAgainToExtendIt() {
        goal.setFrozenUntil(LocalDateTime.now().plusDays(2));
        LocalDateTime before = goal.getFrozenUntil();
        assertThrows(IllegalArgumentException.class, () -> service.freeze(userId, goalId, 7));
        assertEquals(before, goal.getFrozenUntil());
    }

    @Test
    void unfreezingClearsTheFreeze() {
        goal.setFrozenUntil(LocalDateTime.now().plusDays(2));
        service.unfreeze(userId, goalId);
        assertNull(goal.getFrozenUntil());
    }

    @Test
    void aFrozenGoalRefusesMoneyAndTheRefusalIsRecorded() {
        goal.setFrozenUntil(LocalDateTime.now().plusDays(1));
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
                () -> service.deposit(userId, goalId, new BigDecimal("10.00")));
        assertTrue(e.getMessage().contains("frozen"));
        verify(ledger, never()).debitInternal(any(), any(), anyString(), anyString(), anyString());
        verify(recorder).recordFailure(any(TransactionModel.class), anyString());
        assertEquals(new BigDecimal("50.00"), goal.getSavedAmount());
    }

    @Test
    void aFreezeThatHasRunOutNoLongerBlocksSaving() {
        goal.setFrozenUntil(LocalDateTime.now().minusMinutes(5));
        stubWallet("100.00");
        service.deposit(userId, goalId, new BigDecimal("10.00"));
        assertEquals(new BigDecimal("60.00"), goal.getSavedAmount());
    }

    // --------------------------------------------------------------- auto-save

    @Test
    void autoSaveFrequencyMovesTheNextRunByOnePeriod() {
        LocalDateTime start = LocalDateTime.of(2026, 1, 31, 8, 0);
        assertEquals(start.plusDays(1), SavingsGoalService.Frequency.DAILY.next(start));
        assertEquals(start.plusWeeks(1), SavingsGoalService.Frequency.WEEKLY.next(start));
        assertEquals(LocalDateTime.of(2026, 2, 28, 8, 0), SavingsGoalService.Frequency.MONTHLY.next(start));
        assertThrows(IllegalArgumentException.class, () -> SavingsGoalService.Frequency.parse("hourly"));
        assertEquals(SavingsGoalService.Frequency.WEEKLY, SavingsGoalService.Frequency.parse(" weekly "));
    }

    @Test
    void turningAutoSaveOnSchedulesTheFirstSaveAFullPeriodAway() {
        stubWallet("100.00");
        service.setAutoSave(userId, goalId, new BigDecimal("5"), "WEEKLY");
        assertTrue(goal.isAutoEnabled());
        assertEquals(new BigDecimal("5.00"), goal.getAutoAmount().setScale(2));
        assertEquals("WEEKLY", goal.getAutoFrequency());
        assertTrue(goal.getAutoNextRun().isAfter(LocalDateTime.now().plusDays(7).minusMinutes(1)));
    }

    @Test
    void aDueAutoSaveIsClaimedOnceAndMovesTheMoneyAsAnAutoSave() {
        enableAutoSave(LocalDateTime.now().minusMinutes(1));
        stubWallet("100.00");
        when(goalRepository.findDueAutoSaveIds(any(), any())).thenReturn(List.of(goalId));

        assertEquals(1, service.processDueAutoSaves());

        // The run was moved forward (so it cannot be taken again) and the money moved
        assertTrue(goal.getAutoNextRun().isAfter(LocalDateTime.now().plusDays(6)));
        assertEquals(new BigDecimal("55.00"), goal.getSavedAmount());
        ArgumentCaptor<TransactionModel> draft = ArgumentCaptor.forClass(TransactionModel.class);
        verify(ledger).debitInternal(draft.capture(), any(FiatAccountModel.class), anyString(), anyString(), anyString());
        assertTrue(draft.getValue().getInternalReferenceId().startsWith("SAV-AUTO-"));

        // A second pass finds nothing due
        assertEquals(0, service.processDueAutoSaves());
    }

    @Test
    void aFrozenGoalKeepsItsDueRunAndNothingIsSaved() {
        LocalDateTime due = LocalDateTime.now().minusMinutes(1);
        enableAutoSave(due);
        goal.setFrozenUntil(LocalDateTime.now().plusDays(1));
        when(goalRepository.findDueAutoSaveIds(any(), any())).thenReturn(List.of(goalId));

        assertEquals(0, service.processDueAutoSaves());

        assertEquals(due, goal.getAutoNextRun());
        verify(ledger, never()).debitInternal(any(), any(), anyString(), anyString(), anyString());
    }

    @Test
    void aGoalThatReachedItsTargetStopsAutoSaving() {
        enableAutoSave(LocalDateTime.now().minusMinutes(1));
        goal.setStatus("COMPLETED");
        when(goalRepository.findDueAutoSaveIds(any(), any())).thenReturn(List.of(goalId));

        assertEquals(0, service.processDueAutoSaves());

        assertFalse(goal.isAutoEnabled());
        assertNull(goal.getAutoNextRun());
    }

    // ------------------------------------------------------------------ delete

    @Test
    void deletingAGoalReturnsEverythingSavedToTheWalletFirst() {
        stubWallet("0.00");
        when(ledger.creditInternal(any(), any(), anyString(), anyString(), anyString())).thenReturn(new TransactionModel());

        var result = service.delete(userId, goalId);

        assertEquals(new BigDecimal("50.00"), result.returnedAmount());
        ArgumentCaptor<TransactionModel> draft = ArgumentCaptor.forClass(TransactionModel.class);
        verify(ledger).creditInternal(draft.capture(), any(FiatAccountModel.class), anyString(), anyString(), anyString());
        assertEquals(new BigDecimal("50.00"), draft.getValue().getAmount());
        assertEquals(Datatypes.TransactionType.SAVINGS_WITHDRAWAL, draft.getValue().getTransactionType());
        verify(goalRepository).delete(goal);
    }

    @Test
    void anEmptyGoalIsDeletedWithoutMovingAnyMoney() {
        goal.setSavedAmount(BigDecimal.ZERO);

        var result = service.delete(userId, goalId);

        assertEquals(BigDecimal.ZERO, result.returnedAmount());
        verify(goalRepository).delete(goal);
        verify(ledger, never()).creditInternal(any(), any(), anyString(), anyString(), anyString());
    }

    @Test
    void ifTheWalletCannotTakeTheMoneyBackTheGoalIsKept() {
        when(ledger.walletAccount(eq(userId), eq("GHS"))).thenThrow(new com.zentrapay.backend.exception.ResourceNotFoundException("no account"));

        assertThrows(IllegalArgumentException.class, () -> service.delete(userId, goalId));

        verify(goalRepository, never()).delete(any(SavingsGoalModel.class));
        verify(recorder).recordFailure(any(TransactionModel.class), anyString());
    }

    // ----------------------------------------------------------------- helpers

    private void enableAutoSave(LocalDateTime nextRun) {
        goal.setAutoEnabled(true);
        goal.setAutoAmount(new BigDecimal("5.00"));
        goal.setAutoFrequency("WEEKLY");
        goal.setAutoNextRun(nextRun);
    }

    private void stubWallet(String balance) {
        FiatAccountModel account = mock(FiatAccountModel.class);
        when(account.getStatus()).thenReturn("ACTIVE");
        when(account.getBalance()).thenReturn(new BigDecimal(balance));
        when(ledger.walletAccount(userId, "GHS")).thenReturn(account);
        when(ledger.debitInternal(any(), any(), anyString(), anyString(), anyString())).thenReturn(new TransactionModel());
    }
}
