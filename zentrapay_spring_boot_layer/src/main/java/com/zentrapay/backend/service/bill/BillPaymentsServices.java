// Always add inline comments for code readability and maintenance
package com.zentrapay.backend.service.bill;

import com.zentrapay.backend.entity.BillPaymentModel;
import com.zentrapay.backend.repository.BillPaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class BillPaymentsServices {

    private final BillPaymentRepository billPaymentRepository;

    // ==================================================================
    // Directory
    // ==================================================================

    @Transactional(readOnly = true)
    public BillPaymentModel addNew(
            UUID userId,
            UUID providerId,
            String idempotencyKey,
            UUID transactionId,
            String customerReference,
            BigDecimal amount,
            String currencyCode
    ) {
        BillPaymentModel p = new BillPaymentModel();
        p.setUserId(userId);
        p.setProviderId(providerId);
        p.setIdempotencyKey(idempotencyKey);
        p.setTransactionId(transactionId);
        p.setCustomerReference(customerReference);
        p.setAmount(amount);
        p.setCurrencyCode(currencyCode);
        return billPaymentRepository.save(p);

    }

}