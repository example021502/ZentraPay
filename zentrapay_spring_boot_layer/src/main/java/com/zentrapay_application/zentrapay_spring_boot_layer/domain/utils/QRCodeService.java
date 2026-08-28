package com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FiatAccountRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.AccountDetailsDTO;
import io.nayuki.qrcodegen.QrCode; // Added missing Nayuki import
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import tools.jackson.databind.ObjectMapper;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor // Automatically creates constructor for both final fields
public class QRCodeService {

    private final ObjectMapper objectMapper;
    private final FiatAccountRepository fiatAccountRepository;

    // Removed the duplicate manual constructor to fix Lombok conflict

    /**
     * Resolves details for the account ID and returns QR image bytes.
     */
    public byte[] generateQRCodeForAccount(UUID accountId) throws IOException {

        // 1. Extract details from database or internal payment engine using ID
        // Assuming AccountDetailsDTO is a Java record (using component accessors)
        AccountDetailsDTO account = fiatAccountRepository.getAccountByAccountId(accountId)
                .map(a -> new AccountDetailsDTO(
                        a.getAccountId(),
                        a.getWalletId(),
                        a.getAccountName(),
                        a.getZentag(),
                        a.getCurrencyCode()
                ))
                .orElseThrow(() -> new ResourceNotFoundException("Account not found"));

        // 2. Build secure payment payload (e.g., checkout URL or structured JSON)
        String qrPayload = buildSecurePayload(account);

        // 3. Render payload into PNG using Nayuki library
        return renderNayukiQRCode(qrPayload, 8, 2);
    }

    private String buildSecurePayload(AccountDetailsDTO account) {
        try {
            // Put checkout parameters into payload map
            Map<String, String> payloadMap = new HashMap<>();

            // Assuming AccountDetailsDTO is a Java record (using record component accessors)
            payloadMap.put("identifier", account.zentag());
            payloadMap.put("accountName", account.accountName());
            payloadMap.put("currencyCode", account.currencyCode());
            payloadMap.put("walletId", String.valueOf(account.walletId()));
            payloadMap.put("accountId", String.valueOf(account.accountId()));

            // Convert map to JSON string format
            return objectMapper.writeValueAsString(payloadMap);
        } catch (Exception e) {
            throw new RuntimeException("Error constructing payload JSON", e);
        }
    }

    /**
     * Nayuki QR Code generator helper to convert String into PNG byte array.
     */
    private byte[] renderNayukiQRCode(String text, int scale, int border) throws IOException {
        // Encode text into QrCode matrix using Medium Error Correction
        QrCode qr = QrCode.encodeText(text, QrCode.Ecc.MEDIUM);

        // Convert matrix to BufferedImage
        int resultSize = (qr.size + border * 2) * scale;
        BufferedImage image = new BufferedImage(resultSize, resultSize, BufferedImage.TYPE_INT_RGB);

        int white = 0xFFFFFFFF;
        int black = 0xFF000000;

        // Draw background and modules
        for (int y = 0; y < resultSize; y++) {
            for (int x = 0; x < resultSize; x++) {
                image.setRGB(x, y, white);
            }
        }

        for (int y = 0; y < qr.size; y++) {
            for (int x = 0; x < qr.size; x++) {
                if (qr.getModule(x, y)) {
                    int startX = (x + border) * scale;
                    int startY = (y + border) * scale;
                    for (int dy = 0; dy < scale; dy++) {
                        for (int dx = 0; dx < scale; dx++) {
                            image.setRGB(startX + dx, startY + dy, black);
                        }
                    }
                }
            }
        }

        // Write output to byte stream
        try (ByteArrayOutputStream os = new ByteArrayOutputStream()) {
            ImageIO.write(image, "png", os);
            return os.toByteArray();
        }
    }
}