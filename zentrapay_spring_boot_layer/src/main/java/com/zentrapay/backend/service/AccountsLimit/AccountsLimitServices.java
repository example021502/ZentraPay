// Always add inline comments for code readability and maintenance
package com.zentrapay.backend.service.AccountsLimit;

import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.repository.AccountsLimitRepository;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

/**
 * Bill providers (directory) and bill payments (electricity, TV, airtime, etc.).
 *
 * <p>Paying a bill follows a money-safe lifecycle: validate inputs and user/account eligibility,
 * create a draft transaction, debit the wallet (INITIATED), call {@link FlutterwaveServices#payBill},
 * mark SUCCESS/PENDING when accepted, refund on a definite refusal, or keep PENDING when the
 * upstream outcome is unknown pending reconciliation.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AccountsLimitServices {
    private final AccountsLimitRepository accountsLimitRepository;

    public void checkAccountLimit(short tier, BigDecimal amount, String currencyCode) {
        AccountsLimitModel limit = accountsLimitRepository.getLimitByKycTier(tier)
                .orElseThrow(() -> new RuntimeException("Invalid Tier level value."));
        if (amount.compareTo(limit.getLimit()) > 0) {
            throw new RuntimeException("Your account is currently limited to " + currencyCode + " " + limit.getLimit() + " per transactions.");
        }
    }
}