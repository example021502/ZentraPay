package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.SearchRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.SearchResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model.SearchAppUsersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model.SearchBillProvidersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model.SearchFundingSourcesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.repository.SearchAppUsersRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.repository.SearchBillProvidersRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.repository.SearchFundingSourcesRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class SearchContactsService {
private final SearchAppUsersRepository appUsersRepository;
private final SearchBillProvidersRepository billProvidersRespository;
private final SearchFundingSourcesRepository fundingSources;

//    GETTING ALL CONTACTS
    public SearchResponseDTO searchContacts(@Valid SearchRequestDTO req) {

        List<SearchAppUsersModel> users = appUsersRepository.searchByQuery(req.query());
        List<SearchBillProvidersModel> providers = billProvidersRespository.searchByQuery(req.query());
        List<SearchFundingSourcesModel> sources = fundingSources.searchByQuery(req.query());
        return new SearchResponseDTO(users, providers, sources);
    }
}