// Always add inline comments for code readability and maintenance
package com.zentrapay.backend.service.bill;

import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class BillProvidersServices {

    private final UserBillProvidersRepository userBillProviders;

    // ==================================================================
    // Directory
    // ==================================================================

    @Transactional(readOnly = true)
    public UserBillProviderModel getAccount(UUID userId, UUID billProviderId) {
        // Ensure the requested country is supported by ZentraPay before querying billers
        UserBillProviderModel a = userBillProviders.getByUserIdAndProviderId(userId, billProviderId)
                .orElseThrow(() -> new RuntimeException("Your connection with this bill provider cannot be resolved, please, reconnect and try again."));
        if (!a.isActive()) {
            throw new RuntimeException("Your connection with this bill provider is currently inactive. Please, reconnect and try again.");
        }
        return a;
    }

    @Transactional(readOnly = true)
    public List<UserBillProviderModel> getAccounts(UUID userId) {
        return userBillProviders.getAllByUserId(userId);
    }
}