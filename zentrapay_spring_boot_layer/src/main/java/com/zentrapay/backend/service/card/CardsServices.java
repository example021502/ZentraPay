package com.zentrapay.backend.service.card;

import lombok.extern.slf4j.Slf4j;
import com.zentrapay.backend.entity.CardsModel;
import com.zentrapay.backend.entity.UserCardsModel;
import com.zentrapay.backend.repository.CardsRepository;
import com.zentrapay.backend.repository.UserCardsRepository;
import com.zentrapay.backend.dto.card.CardsDTO;
import com.zentrapay.backend.dto.card.UserCardsDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class CardsServices {

    private final UserCardsRepository userCardsRepository;
    private final CardsRepository cardsRepository;
    /*
    * GETTING ALL THE OTHER CARDS
    * */
    @Transactional(readOnly = true)
    public List<CardsDTO> otherCards() {
        return cardsRepository.findAll().stream()
                .map(card -> new CardsDTO(
                        card.getCardId(),
                        card.getName(),
                        card.getBrand(),
                        card.getCardType(),
                        card.getDescription(),
                        card.getActive(),
                        card.getCreatedAt(),
                        card.getUpdatedAt()
                ))
                .toList();
    }

    /*
    * GETTING ALL THE LINKED CARDS
    * */
    @Transactional(readOnly = true)
    public List<UserCardsDTO> userCards(UUID userId) {
        // Lists the user's own cards together with the card details
        log.info("Loading cards for user {}", userId);
        List<UserCardsModel> uCards = userCardsRepository.findByUserId(userId);
        if(uCards.isEmpty()){
            return Collections.emptyList();
        }
        return uCards.stream().map(card ->{
            CardsModel cInfo = cardsRepository.findByCardId(card.getCardId());
            return new UserCardsDTO(
                card.getId(),
                card.getUserId(),
                card.getCardId(),
                card.getWalletId(),
                card.getProviderId(),
                cInfo.getName(),
                cInfo.getBrand(),
                card.getLast4(),
                card.getBalance(),
                card.getCurrencyCode(),
                card.getExpiryMonth(),
                card.getExpiryYear(),
                card.getNfcEnabled(),
                card.getQrEnabled(),
                card.getStatus(),
                card.getIssuedAt(),
                card.getUpdatedAt()
            );
        }).toList();
    }
}