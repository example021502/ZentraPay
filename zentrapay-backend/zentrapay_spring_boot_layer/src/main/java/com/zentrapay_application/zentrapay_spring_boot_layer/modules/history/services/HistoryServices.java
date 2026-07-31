package com.zentrapay_application.zentrapay_spring_boot_layer.modules.history.services;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.history.dtos.HistoryResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HistoryServices {
    private final TransactionRepository transactionRepository;

    public HistoryResponseDTO getPaymentsHistory(UUID userId) {
        List<TransactionModel> history = transactionRepository.findByUserIdOrderByCreatedAtDesc(userId);
        return new HistoryResponseDTO(history);
    }
}
