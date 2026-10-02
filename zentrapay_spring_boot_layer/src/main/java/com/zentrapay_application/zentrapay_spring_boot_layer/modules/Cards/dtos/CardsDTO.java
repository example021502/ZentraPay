package com.zentrapay_application.zentrapay_spring_boot_layer.modules.Cards.dtos;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A single crypto wallet entry — maps to the frontend {@code CryptoWalletSummary}
 * model. {@code balance} is a decimal {@link String}.
 */
public record CardsDTO(
      UUID cardId,
      String name,
      String brand,
      String cardType,
      String description,
      Boolean active,
      LocalDateTime createdAt,
      LocalDateTime updatedAt
      ){}
