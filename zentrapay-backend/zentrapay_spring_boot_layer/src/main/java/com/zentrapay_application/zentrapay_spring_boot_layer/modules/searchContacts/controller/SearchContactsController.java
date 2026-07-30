package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.SearchRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.SearchResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.service.SearchContactsService;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto.RequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto.ResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.service.BalancesServices;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/searchContacts")
@RequiredArgsConstructor
public class searchContactsController {
    private final SearchContactsService searchContactsService;

    @GetMapping("/")
    public ResponseEntity<ApiResponse<SearchResponseDTO>> searchContacts(@PathVariable("query") String query) {
        SearchRequestDTO request = new SearchRequestDTO(query, 20);
        System.out.println("[SPRING_CTRL] search contacts hit by " + request);
        SearchResponseDTO contacts = searchContactsService.searchContacts(request);
        return ResponseEntity.ok(ApiResponse.success(contacts, "Search Successful"));
    }
}