package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BanksModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BillProviderModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SearchContactsService {

    private final UserRepository userRepository;
    private final BillProviderRepository billProviderRepository;
    private final BanksRepository banksRepository;


    public SearchResponseDTO searchContacts(@Valid SearchRequestDTO req, UUID userId) {
        int limit = req.limit() > 0 ? req.limit() : 20;
//      searching sender details
        UserModel sender = userRepository.getUserById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

//  GETTING ALL THE MATCHED USER ACCOUNTS
        List<UserSearchDTO> appUsers = userRepository.searchByQueryAndCountryCode(req.query().toLowerCase(), sender.getCountryCode().toLowerCase(),  sender.getUserId())
                .stream()
                .map(u -> new UserSearchDTO(
                        u.getCountryCode(),
                        u.getEmail(),
                        u.getFirstName(),
                        u.getLastName(),
                        u.getPhoneNumber(),
                        u.getStatus(),
                        u.getUserType()
                )).toList();
//  GETTING ALL THE MATCHED BILL PROVIDERS HERE
        List<BillProviderSearchDTO> billProviders = billProviderRepository.getMatchedBillProviders(req.query().toLowerCase(), sender.getCountryCode().toLowerCase()).stream()
                .map(SearchContactsService::toBillProviderSearchDTO)
                .limit(limit).toList();
//  GETTING ALL THE MATCHED BANK ACCOUNTS SUPPORTED
        List<BankSearchDTO> banks = banksRepository.getMatchedBanks(req.query().toLowerCase(), sender.getCountryCode().toLowerCase()).stream()
                .map(SearchContactsService::toBanksSearchDTO)
                .limit(limit).toList();


        return new SearchResponseDTO(appUsers, billProviders, banks);
    }

    private static BillProviderSearchDTO toBillProviderSearchDTO(BillProviderModel p) {
        return new BillProviderSearchDTO(
                p.getProviderId(),
                p.getBillerCode(),
                p.getBillerName(),
                p.getCategoryCode(),
                p.getCountryCode(),
                p.getFetchRequirement(),
                p.getCustomerParamsSchema(),
                p.getLogoUrl(),
                p.getUpdatedAt(),
                p.getChannelCode(),
                p.getIsCrossBorderAllowed(),
                p.getActive(),
                p.getCreatedAt()
        );
    }

    private static BankSearchDTO toBanksSearchDTO(BanksModel b) {
        return new BankSearchDTO(
                b.getBankId(),
                b.getBankName(),
                b.getCode(),
                b.getCountryCode()
        );
    }

//    SEARCHING FOR A SINGLE CONTACT
    public ContactResponseDTO getContact(UUID userId, SearchContactRequestDTO req) {

                UserModel user = userRepository.getUserById(userId)
                        .orElseThrow(() -> new ResourceNotFoundException("User not found"));

                Optional<UserSearchDTO> userContact = userRepository.getContactByQueryAndCountryCode(req.query(), user.getCountryCode().toLowerCase()).map(u-> new UserSearchDTO(
                        u.getCountryCode(),
                        u.getEmail(),
                        u.getFirstName(),
                        u.getLastName(),
                        u.getPhoneNumber(),
                        u.getStatus(),
                        u.getUserType()
                ));
                if(userContact.isPresent()){
                    return new ContactResponseDTO(userContact);
                }

                Optional<BillProviderSearchDTO> billProvider = billProviderRepository.getContactByQueryAndCountryCode(req.query(), user.getCountryCode().toLowerCase()).map(b-> new BillProviderSearchDTO(
                        b.getProviderId(),
                        b.getBillerCode(),
                        b.getBillerName(),
                        b.getCategoryCode(),
                        b.getCountryCode(),
                        b.getFetchRequirement(),
                        b.getCustomerParamsSchema(),
                        b.getLogoUrl(),
                        b.getUpdatedAt(),
                        b.getChannelCode(),
                        b.getIsCrossBorderAllowed(),
                        b.getActive(),
                        b.getCreatedAt()
                ));
                if(billProvider.isPresent())
                {
                    return new ContactResponseDTO(billProvider);
                }
                Optional<BankSearchDTO> bank = banksRepository.getContactByQueryAndCountryCode(req.query(), user.getCountryCode().toLowerCase()).map(bnk-> new BankSearchDTO(
                        bnk.getBankId(),
                        bnk.getBankName(),
                        bnk.getCode(),
                        bnk.getCountryCode()
                ));
                    return new ContactResponseDTO(bank);

    }



}

