package com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.CardsServices;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.CardsRepository.CardsRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dtos.CardsRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dtos.CardsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.models.CardsModel;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CardsServices {
    private final CardsRepository cardsRepository;

    public CardsResponseDTO allCards(@Valid CardsRequestDTO req) {
        List<CardsModel> cards = cardsRepository.getByUserId(req.userId());

        return new CardsResponseDTO(cards);
    }

}