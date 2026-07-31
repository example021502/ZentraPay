package com.zentrapay_application.zentrapay_spring_boot_layer.modules.history.dtos;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.model.TransactionModel;

import java.util.List;

public record HistoryResponseDTO(
        List<TransactionModel> history
) {
}
