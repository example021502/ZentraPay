package com.zentrapay.backend.service.search;

import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.entity.BillProviderModel;
import com.zentrapay.backend.entity.MobileMoneyProvidersModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.dto.search.*;
import com.zentrapay.backend.service.region.SupportedRegionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SearchContactsService {
    private static final Logger log = LoggerFactory.getLogger(SearchContactsService.class);

    private final UserRepository userRepository;
    private final BillProviderRepository billProviderRepository;
    private final BanksRepository banksRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final MobileMoneyRepository mobileMoneyRepository;
    private final SupportedRegionService supportedRegionService;


    /** Which people / places a search looks in, relative to the country of the person searching. */
    public enum Scope {
        /** The searcher own country - the Pay section. */
        DOMESTIC,
        /** Every OTHER supported country - ZRemit. */
        INTERNATIONAL;

        public static Scope parse(String value) {
            return "INTERNATIONAL".equalsIgnoreCase(value) ? INTERNATIONAL : DOMESTIC;
        }
    }

    public SearchResponseDTO searchContacts(@Valid SearchRequestDTO req, UUID userId) {
        return searchContacts(req, userId, Scope.DOMESTIC);
    }

    public SearchResponseDTO searchContacts(@Valid SearchRequestDTO req, UUID userId, Scope scope) {
        // Searches app users, banks, mobile-money networks (and, at home, bill providers) that match the typed text
        log.info("Searching {} contacts for user {} with query '{}'", scope, userId, req.query());
        int limit = req.limit() > 0 ? req.limit() : 20;
        String query = req.query().trim().toLowerCase();
//      searching sender details
        UserModel sender = userRepository.getUserByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        String senderCountry = sender.getCountryCode().toLowerCase();

        if (scope == Scope.INTERNATIONAL) {
            return searchAbroad(query, sender, senderCountry, limit);
        }

//  GETTING ALL THE MATCHED USER ACCOUNTS
        List<UserSearchDTO> appUsers = userRepository.searchByQueryAndCountryCode(query, senderCountry, sender.getUserId())
                .stream()
                .limit(limit)
                .toList();

//  GETTING ALL THE MATCHED BILL PROVIDERS HERE
        List<BillProviderSearchDTO> billProviders = billProviderRepository.getMatchedBillProviders(query, senderCountry).stream()
                .map(SearchContactsService::toBillProviderSearchDTO)
                .limit(limit).toList();
//  GETTING ALL THE MATCHED BANK ACCOUNTS SUPPORTED
        List<BankSearchDTO> banks = distinctBanks(banksRepository.getMatchedBanks(query, senderCountry)).stream()
                .limit(limit).toList();
//  GETTING ALL THE MATCHED MOBILE MONEY NETWORKS
        List<MobileMoneySearchDTO> mobileMoney = mobileMoneyRepository
                .findByCountryCodeIgnoreCaseAndActiveTrueOrderByName(senderCountry).stream()
                .filter(m -> matches(m, query))
                .map(SearchContactsService::toMobileMoneySearchDTO)
                .limit(limit).toList();

        return new SearchResponseDTO(appUsers, billProviders, banks, mobileMoney);
    }

    // ZRemit: everything abroad - but only in countries ZentraPay (through its gateways) supports
    private SearchResponseDTO searchAbroad(String query, UserModel sender, String senderCountry, int limit) {
        List<String> supported = supportedRegionService.activeCountryCodes().stream()
                .filter(code -> !code.equalsIgnoreCase(senderCountry))
                .toList();
        if (supported.isEmpty()) {
            return new SearchResponseDTO(List.of(), List.of(), List.of(), List.of());
        }

        List<UserSearchDTO> appUsers = userRepository
                .searchByQueryOutsideCountry(query, senderCountry, supported, sender.getUserId()).stream()
                .limit(limit).toList();
        List<BankSearchDTO> banks = distinctBanks(banksRepository.getMatchedBanksOutsideCountry(query, senderCountry, supported)).stream()
                .limit(limit).toList();
        List<MobileMoneySearchDTO> mobileMoney = mobileMoneyRepository
                .findByCountryCodeNotIgnoreCaseAndActiveTrueOrderByName(senderCountry).stream()
                .filter(m -> supported.contains(m.getCountryCode().toUpperCase()))
                .filter(m -> matches(m, query))
                .map(SearchContactsService::toMobileMoneySearchDTO)
                .limit(limit).toList();
        return new SearchResponseDTO(appUsers, List.of(), banks, mobileMoney);
    }

    // The same bank is listed once per gateway (each with its own code); show it once. Paystack first, as it is the primary.
    private static List<BankSearchDTO> distinctBanks(List<BanksModel> rows) {
        Map<String, BanksModel> byName = new LinkedHashMap<>();
        rows.stream()
                .sorted(Comparator.comparing((BanksModel b) -> gatewayRank(b.getGateway()))
                        .thenComparing(b -> b.getBankName() == null ? "" : b.getBankName(), String.CASE_INSENSITIVE_ORDER))
                .forEach(b -> byName.putIfAbsent(
                        (b.getBankName() + "|" + b.getCountryCode()).toLowerCase(), b));
        return byName.values().stream()
                .sorted(Comparator.comparing(b -> b.getBankName() == null ? "" : b.getBankName(), String.CASE_INSENSITIVE_ORDER))
                .map(SearchContactsService::toBanksSearchDTO)
                .toList();
    }

    private static int gatewayRank(String gateway) {
        if ("paystack".equalsIgnoreCase(gateway)) return 0;
        if ("flutterwave".equalsIgnoreCase(gateway)) return 1;
        return 2;
    }

    private static boolean matches(MobileMoneyProvidersModel m, String query) {
        return m.getName().toLowerCase().contains(query)
                || m.getGlobalCode().toLowerCase().contains(query)
                || m.getCountryCode().toLowerCase().contains(query);
    }

    private static MobileMoneySearchDTO toMobileMoneySearchDTO(MobileMoneyProvidersModel m) {
        return new MobileMoneySearchDTO(m.getProviderId(), m.getName(), m.getGlobalCode(), m.getCountryCode());
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
        // Finds ONE contact (app user, bank or bill provider) from a scanned QR / pasted id
        log.info("Looking up a single contact for user {}", userId);
        log.info("=========== EXTRATING CONTACT... ===========");
        UserModel user = userRepository.getUserByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        log.info("=========== GETTING THE RECEIVER ID AND THE USER TYPE FROM THE QUERY... ===========");
        String[] queryParts = StringUtils.split(query, "+");
        if (queryParts == null) throw new RuntimeException("Query missing or invalid!");
        UUID receiverId = UUID.fromString(queryParts[0]);
        Datatypes.TransactionType transactionType = Datatypes.TransactionType.valueOf(queryParts[1]);

        log.info("=========== SEARCHING INTERNAL APP USERS... ===========");
        if (transactionType.equals(Datatypes.TransactionType.P2P_TRANSFER)) {
            Optional<UserSearchDTO> userContact = userRepository.getContactByQueryAndCountryCode(
                    receiverId,
                    user.getCountryCode().toLowerCase(),
                    Datatypes.UserStatus.ACTIVE
            );
            if (userContact.isPresent()) {
                log.info("=========== APP USER FOUND... ===========");
                return new ContactResponseDTO(userContact);
            }
            log.info("=========== APP USER NOT FOUND... ===========");
            throw new ResourceNotFoundException("Contact not found!");

        } else {
            log.info("=========== SEARCHING FROM BANKS... ===========");
            Optional<BankSearchDTO> bank = banksRepository.getContactByQueryAndCountryCode(receiverId, user.getCountryCode().toLowerCase()).map(bnk -> new BankSearchDTO(
                    bnk.getBankId(),
                    bnk.getBankName(),
                    bnk.getCode(),
                    bnk.getCountryCode(),
                    bnk.getType()
            ));

            if (bank.isPresent()) {
                log.info("=========== BANK FOUND... ===========");
                return new ContactResponseDTO(bank);
            }
            log.info("=========== SEARCHING IN BILL PROVIDERS... ===========");
            Optional<BillProviderSearchDTO> billProvider = billProviderRepository.getContactByQueryAndCountryCode(receiverId, user.getCountryCode().toLowerCase()).map(b -> new BillProviderSearchDTO(
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
            if (billProvider.isPresent()) {
                log.info("=========== PROVIDER FOUND... ===========");
                return new ContactResponseDTO(billProvider);
            }
            log.info("=========== TRANSACTION RECEIVER NOT FOUND... ===========");
            throw new ResourceNotFoundException("Receiver not found!");
        }

    }

}

