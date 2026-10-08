package com.zentrapay_application.zentrapay_spring_boot_layer.modules.Cards.dtos;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A single crypto wallet entry — maps to the frontend {@code CryptoWalletSummary}
 * model. {@code balance} is a decimal {@link String}.
 */
public record UserCardsDTO(
      UUID id,
      UUID userId,
      UUID cardId,
      UUID walletId,
      UUID providerId,
      String cardName,
      String cardBrand,
      String last4,
      BigDecimal balance,
      String currencyCode,
      Integer expiryMonth,
      Integer expiryYear,
      Boolean nfcEnabled,
      Boolean qrEnabled,
      String status,
      LocalDateTime issuedAt,
      LocalDateTime updatedAt
      ){}
