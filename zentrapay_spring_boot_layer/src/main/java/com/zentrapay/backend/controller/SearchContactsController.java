package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.search.ContactResponseDTO;
import com.zentrapay.backend.dto.search.SearchRequestDTO;
import com.zentrapay.backend.dto.search.SearchResponseDTO;
import com.zentrapay.backend.service.search.SearchContactsService;
import com.zentrapay.backend.security.AuthenticatedUser;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * API_CONTRACT.md §10 — path corrected from the old /api/searchContacts to the
 * contract's /api/search-contacts.
 */
@RestController
@RequestMapping("/api/search")
@RequiredArgsConstructor
public class SearchContactsController {
    private final SearchContactsService searchContactsService;

    // Endpoint handles contact searches while automatically pulling the authenticated user's ID from the token
    @GetMapping("/search-contacts/{query}")
    public ResponseEntity<ApiResponse<SearchResponseDTO>> searchContacts(
            @PathVariable("query") String query,
            @AuthenticationPrincipal AuthenticatedUser user // Captures the authenticated principal set by your JWT filter
    ) {
        // Extract the user UUID from the principal name (assuming your JWT subject stores the user UUID string)
        UUID userId = user.getUserId();
        // Alternatively, if your SecurityContext stores the UUID directly as the principal object, use:
        // UUID userId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        // Build the request DTO using the query and the authenticated user's ID
        SearchRequestDTO request = new SearchRequestDTO(query, 20);

        // Perform the search operation
        SearchResponseDTO contacts = searchContactsService.searchContacts(request, userId);

        // Return the success response
        return ResponseEntity.ok(ApiResponse.success(contacts, "Search Successful"));
    }

    @GetMapping("/search-contact/{query}")
    public ResponseEntity<ApiResponse<ContactResponseDTO>> searchContact(
            @PathVariable("query")
            @NotBlank(message = "Query missing")
            String query,
            @AuthenticationPrincipal AuthenticatedUser user // Captures the authenticated principal set by your JWT filter
    ) {
        final UUID userId = user.getUserId();
        ContactResponseDTO contact = searchContactsService.getContact(userId, query);
        return ResponseEntity.ok(ApiResponse.success(contact, "Search Successful"));
    }
}