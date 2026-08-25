package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.ContactResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.SearchContactRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.SearchRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.SearchResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.service.SearchContactsService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
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
        System.out.println("THE USER ID:: userId::" + userId);
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
            @PathVariable("query") UUID query,
            @AuthenticationPrincipal AuthenticatedUser user // Captures the authenticated principal set by your JWT filter
    ) {
        SearchContactRequestDTO req = new SearchContactRequestDTO(query);
        final UUID userId = user.getUserId();
        ContactResponseDTO contact = searchContactsService.getContact(userId, req);
        return ResponseEntity.ok(ApiResponse.success(contact, "Search Successful"));
    }
}