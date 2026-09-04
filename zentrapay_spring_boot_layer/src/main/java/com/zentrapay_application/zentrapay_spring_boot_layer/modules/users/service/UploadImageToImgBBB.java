package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.Map;

/**
 * Uploads an image to ImgBB and hands back its public URL — the image
 * host for profile/KYC document pictures (see {@link DocumentsService}).
 * Local-disk saving under {@code app.uploads.dir} is unrelated and untouched
 * by this class; this only produces the hosted URL that gets saved alongside
 * it on {@code UserProfileModel}.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UploadImageToImgBBB {

    private final RestClient restClient;

    @Value("${imgbb.api-key}")
    private String apiKey;

    @Value("${imgbb.base-url:https://api.imgbb.com/1/upload}")
    private String baseUrl;

    /** The hosted image's public URL and its ImgBB delete link. */
    public record ImgBBResult(String url, String deleteUrl) {}

    /**
     * Uploads the given image bytes to ImgBB.
     *
     * @return the hosted URLs, or {@code null} if the upload failed for any
     * reason (bad response, network error, missing API key) — callers decide
     * whether that's fatal.
     */
    public ImgBBResult upload(String filename, byte[] imageBytes) {
        if (imageBytes == null || imageBytes.length == 0) {
            return null;
        }
        if (apiKey == null || apiKey.isBlank() || apiKey.startsWith("YOUR_")) {
            log.error("ImgBB upload skipped: imgbb.api-key is not configured");
            return null;
        }

        try {
            ByteArrayResource fileResource = new ByteArrayResource(imageBytes) {
                @Override
                public String getFilename() {
                    return filename != null && !filename.isBlank() ? filename : "upload";
                }
            };

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("image", fileResource);

            Map<?, ?> response = restClient.post()
                    .uri(baseUrl + "?key={key}", apiKey)
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(body)
                    .retrieve()
                    .body(Map.class);

            if (response == null || !Boolean.TRUE.equals(response.get("success"))) {
                log.warn("ImgBB upload did not report success: {}", response);
                return null;
            }

            Object dataObj = response.get("data");
            if (!(dataObj instanceof Map<?, ?> data)) {
                log.warn("ImgBB response had no 'data' object: {}", response);
                return null;
            }

            Object urlObj = data.get("url");
            if (urlObj == null) {
                log.warn("ImgBB response had no 'url': {}", response);
                return null;
            }

            Object deleteUrlObj = data.get("delete_url");
            return new ImgBBResult(urlObj.toString(), deleteUrlObj == null ? null : deleteUrlObj.toString());
        } catch (RestClientException e) {
            log.error("ImgBB upload failed: {}", e.getMessage());
            return null;
        }
    }
}
