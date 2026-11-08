package com.zentrapay.backend.service.savings;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Runs the automatic savings once a minute: every goal whose "save X every day / week / month" is due gets its
 * amount moved from the wallet. The work (claiming a run so it can never happen twice, refusing a frozen goal,
 * recording a refused save) is in {@link SavingsGoalService#processDueAutoSaves()}.
 *
 * <p>{@code fixedDelay} (not a fixed rate) so a slow run is never overlapped by the next one on this instance.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SavingsAutoSaveJob {

    private final SavingsGoalService savingsGoalService;

    @Scheduled(fixedDelayString = "${app.savings.auto-save-interval-ms:60000}",
            initialDelayString = "${app.savings.auto-save-initial-delay-ms:30000}")
    public void run() {
        try {
            int saved = savingsGoalService.processDueAutoSaves();
            if (saved > 0) {
                log.info("Auto-save: {} goal(s) funded", saved);
            }
        } catch (RuntimeException e) {
            // Never let one bad run kill the schedule
            log.error("Auto-save run failed: {}", e.getMessage(), e);
        }
    }
}
