package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.model.RemittanceModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.repository.RemittanceRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Service for ZRemit: instant cross-border transfers, smart currency conversion.
 */
@Service
@Transactional
public class RemittanceServices {

    private static final Logger log = LoggerFactory.getLogger(RemittanceServices.class);

    private final RemittanceRepository remittanceRepository;

    public RemittanceServices(RemittanceRepository remittanceRepository) {
        this.remittanceRepository = remittanceRepository;
    }

    /**
     * Creates a new cross-border remittance.
     */
    public RemittanceModel createRemittance(UUID senderId, UUID receiverId, BigDecimal amount,
                                           String sourceCurrency, String destinationCurrency,
                                           String channel, String recipientPhoneNumber, String recipientName) {
        log.info("[ZREMIT] Creating remittance: sender={}, receiver={}, amount={} {} -> {}",
                senderId, receiverId, amount, sourceCurrency, destinationCurrency);

        RemittanceModel remittance = new RemittanceModel();
        remittance.setSenderId(senderId);
        remittance.setReceiverId(receiverId);
        remittance.setAmount(amount);
        remittance.setSourceCurrency(sourceCurrency);
        remittance.setDestinationCurrency(destinationCurrency);
        remittance.setExchangeRate(BigDecimal.ONE); // TODO: Get from forex API
        remittance.setFee(BigDecimal.ZERO); // TODO: Calculate fee
        remittance.setStatus("PENDING");
        remittance.setChannel(channel);
        remittance.setRecipientPhoneNumber(recipientPhoneNumber);
        remittance.setRecipientName(recipientName);
        remittance.setReference("REM-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());

        return remittanceRepository.save(remittance);
    }

    /**
     * Retrieves all remittances for a user.
     */
    @Transactional(readOnly = true)
    public List<RemittanceModel> getUserRemittances(UUID userId) {
        log.info("[ZREMIT] Fetching remittances for userId={}", userId);
        return remittanceRepository.findBySenderId(userId);
    }

    /**
     * Updates remittance status.
     */
    public RemittanceModel updateStatus(UUID remittanceId, String status) {
        log.info("[ZREMIT] Updating remittance {} to status={}", remittanceId, status);

        RemittanceModel remittance = remittanceRepository.findById(remittanceId)
                .orElseThrow(() -> new RuntimeException("Remittance not found"));

        remittance.setStatus(status);
        return remittanceRepository.save(remittance);
    }
}