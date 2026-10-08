package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BanksModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BillProviderModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SearchContactsService {

    private final UserRepository userRepository;
    private final BillProviderRepository billProviderRepository;
    private final BanksRepository banksRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;


    public SearchResponseDTO searchContacts(@Valid SearchRequestDTO req, UUID userId) {
        int limit = req.limit() > 0 ? req.limit() : 20;
//      searching sender details
        UserModel sender = userRepository.getUserByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

//  GETTING ALL THE MATCHED USER ACCOUNTS
        List<UserSearchDTO> appUsers = userRepository.searchByQueryAndCountryCode(req.query().toLowerCase(), sender.getCountryCode().toLowerCase(),  sender.getUserId())
                .stream()
                .limit(limit)
                .toList();

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
                p.getUserType(),
                p.getCreatedAt()
        );
    }

    private static BankSearchDTO toBanksSearchDTO(BanksModel b) {
        return new BankSearchDTO(
                b.getBankId(),
                b.getBankName(),
                b.getCode(),
                b.getCountryCode(),
                b.getType()
        );
    }

//    SEARCHING FOR A SINGLE CONTACT
    public ContactResponseDTO getContact(UUID userId, String query) {

                UserModel user = userRepository.getUserByUserId(userId)
                        .orElseThrow(() -> new ResourceNotFoundException("User not found"));
//                SPLITTING THE QUERY TO GET THE RECEIVER ID AND THE TRANSACTION TYPE
        String[] queryParts = StringUtils.split(query, "+");
        if(queryParts == null) throw new RuntimeException("Query missing or invalid!");
        UUID receiverId = UUID.fromString(queryParts[0]);
        Datatypes.TransactionType transactionType = Datatypes.TransactionType.valueOf(queryParts[1]);

        if(transactionType.equals(Datatypes.TransactionType.INTERNAL)){
            Optional<UserSearchDTO> userContact = userRepository.getContactByQueryAndCountryCode(
                    receiverId,
                    user.getCountryCode().toLowerCase(),
                    Datatypes.UserStatus.ACTIVE
            );
            if(userContact.isPresent()){
                return new ContactResponseDTO(userContact);
            }
                throw  new ResourceNotFoundException("Contact not found!");

        }else{
            Optional<BankSearchDTO> bank = banksRepository.getContactByQueryAndCountryCode(receiverId, user.getCountryCode().toLowerCase()).map(bnk-> new BankSearchDTO(
                    bnk.getBankId(),
                    bnk.getBankName(),
                    bnk.getCode(),
                    bnk.getCountryCode(),
                    bnk.getType()
            ));
            if(bank.isPresent())
                return new ContactResponseDTO(bank);

            Optional<BillProviderSearchDTO> billProvider = billProviderRepository.getContactByQueryAndCountryCode(receiverId, user.getCountryCode().toLowerCase()).map(b-> new BillProviderSearchDTO(
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
                    b.getUserType(),
                    b.getCreatedAt()
            ));
            if(billProvider.isPresent())
                return new ContactResponseDTO(billProvider);

            throw new ResourceNotFoundException("Receiver not found!");
        }

    }

}

