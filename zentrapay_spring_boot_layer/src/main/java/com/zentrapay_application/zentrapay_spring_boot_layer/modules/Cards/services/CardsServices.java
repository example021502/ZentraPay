package com.zentrapay_application.zentrapay_spring_boot_layer.modules.Cards.services;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserCardsRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.Cards.dtos.UserCardsDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CardsServices {

    private final UserCardsRepository userCardsRepository;

    /*
    * GETTING ALL THE LINKED CARDS
    * */
    @Transactional(readOnly = true)
    public List<UserCardsDTO> userCards(UUID userId) {
        return userCardsRepository.findByUserId(userId).stream()
                .map(card -> new UserCardsDTO(
                        card.getId(),
                        card.getUserId(),
                        card.getCardId(),
                        card.getWalletId(),
                        card.getProviderId(),
                        card.getLast4(),
                        card.getExpiryMonth(),
                        card.getExpiryYear(),
                        card.getNfcEnabled(),
                        card.getQrEnabled(),
                        card.getStatus(),
                        card.getIssuedAt(),
                        card.getUpdatedAt()
                ))
                .toList();

    }
}