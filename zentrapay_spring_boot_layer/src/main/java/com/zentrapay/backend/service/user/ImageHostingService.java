package com.zentrapay.backend.service.user;

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
 * Posts a KYC document image to the external image-hosting platform and hands
 * back the public URL it returns. The image itself is never stored in our
 * database or on our disk — only that URL is saved (see {@link DocumentsService}).
 * <p>
 * PLACEHOLDER: the hosting platform has not been chosen yet. This is a real
 * HTTP call driven entirely by {@code imagehost.*} properties, so switching to
 * the real provider means changing those properties (and, if its response shape
 * differs, {@link #extractUrl}) — nothing else.
 * <p>
 * The request is {@code multipart/form-data} with:
 * <ul>
 *   <li>{@code file} — the image; its file name is the original document name
 *       with the document type appended (e.g. {@code passport_id-front.jpg}),</li>
 *   <li>{@code document_type} — {@code id-front | id-back | selfie},</li>
 *   <li>{@code file_name} — the same typed name, for providers that read a field,</li>
 * </ul>
 * and the API key in the {@code imagehost.api-key-header} header.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImageHostingService {

    private final RestClient restClient;

    @Value("${imagehost.upload-url}")
    private String uploadUrl;

    @Value("${imagehost.api-key}")
    private String apiKey;

    @Value("${imagehost.api-key-header:X-API-Key}")
    private String apiKeyHeader;

    /** The hosted image's public URL (and the provider's delete link, when it gives one). */
    public record HostedImage(String url, String deleteUrl) {}

    /**
     * Builds the name the image is posted under: the submitted document name
     * with the document type appended, e.g. {@code scan.jpg} + {@code selfie}
     * becomes {@code scan_selfie.jpg}.
     */
    public static String typedFileName(String originalFilename, String documentType) {
        String name = originalFilename == null || originalFilename.isBlank() ? "document" : originalFilename;
        // Never let a client-supplied path or odd characters into the posted name.
        name = name.replace('\\', '/');
        name = name.substring(name.lastIndexOf('/') + 1).replaceAll("[^A-Za-z0-9._-]", "_");
        int dot = name.lastIndexOf('.');
        String base = dot > 0 ? name.substring(0, dot) : name;
        String ext = dot > 0 && name.length() - dot <= 6 ? name.substring(dot) : "";
        return base + "_" + documentType + ext;
    }

    /**
     * Uploads one document image.
     *
     * @return the hosted image, or {@code null} when the upload failed for any
     * reason (not configured, network error, no URL in the response). The caller
     * decides how to report that.
     */
    public HostedImage upload(String originalFilename, String documentType, byte[] imageBytes) {
        if (imageBytes == null || imageBytes.length == 0) {
            return null;
        }
        if (uploadUrl == null || uploadUrl.isBlank() || uploadUrl.contains("your-image-host")
                || apiKey == null || apiKey.isBlank() || apiKey.startsWith("YOUR_")) {
            log.error("Image upload skipped: imagehost.upload-url / imagehost.api-key are still placeholders");
            return null;
        }

        String typedName = typedFileName(originalFilename, documentType);
        log.info("Posting {} ({} bytes) to the image host", typedName, imageBytes.length);

        try {
            ByteArrayResource fileResource = new ByteArrayResource(imageBytes) {
                @Override
                public String getFilename() {
                    return typedName;
                }
            };

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", fileResource);
            body.add("document_type", documentType);
            body.add("file_name", typedName);

            Map<?, ?> response = restClient.post()
                    .uri(uploadUrl)
                    .header(apiKeyHeader, apiKey)
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(body)
                    .retrieve()
                    .body(Map.class);

            String url = extractUrl(response);
            if (url == null) {
                log.warn("Image host response carried no usable url: {}", response);
                return null;
            }
            return new HostedImage(url, deleteUrlOf(response));
        } catch (RestClientException e) {
            log.error("Image upload failed: {}", e.getMessage());
            return null;
        }
    }

    /** Accepts {@code {url}}, {@code {data:{url}}} and {@code {secure_url}}/{@code display_url} variants. */
    private static String extractUrl(Map<?, ?> response) {
        if (response == null) return null;
        for (Map<?, ?> source : new Map<?, ?>[]{response, nested(response)}) {
            if (source == null) continue;
            for (String key : new String[]{"url", "secure_url", "display_url"}) {
                Object value = source.get(key);
                if (value != null && !value.toString().isBlank()) return value.toString();
            }
        }
        return null;
    }

    private static String deleteUrlOf(Map<?, ?> response) {
        Map<?, ?> data = nested(response);
        Object value = data != null ? data.get("delete_url") : response.get("delete_url");
        return value == null ? null : value.toString();
    }

    private static Map<?, ?> nested(Map<?, ?> response) {
        return response.get("data") instanceof Map<?, ?> data ? data : null;
    }
}
