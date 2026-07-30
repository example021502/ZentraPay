package com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.cardsController;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.CardsServices.CardsServices;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dtos.CardsRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dtos.CardsResponseDTO;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/cards")
@RequiredArgsConstructor
public class CardsController {

    private final CardsServices cardsServices;
    private static final Logger log = LoggerFactory.getLogger(CardsController.class);

    @GetMapping("/allCards")
    public ResponseEntity<ApiResponse<CardsResponseDTO>> internalPayment(
            @RequestParam("userId") UUID userId) {
        CardsRequestDTO request = new CardsRequestDTO(userId);
        log.info("[SPRING_CTRL] Cards endpoint hit by userId={}",
                request.userId());
        CardsResponseDTO cards = cardsServices.allCards(request);
        return ResponseEntity.ok(ApiResponse.success(cards, "Fetch successful"));
    }

}
