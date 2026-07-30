package com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dtos;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.models.CardsModel;

import java.util.List;

public record CardsResponseDTO(
        List<CardsModel> cards
) {
}
