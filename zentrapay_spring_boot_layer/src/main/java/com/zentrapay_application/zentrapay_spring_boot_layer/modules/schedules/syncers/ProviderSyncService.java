package com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.syncers;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BanksModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BillProviderModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.MobileMoneyGatewayMappingsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.MobileMoneyProvidersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.BanksRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.BillProviderRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.MobileMoneyGatewayMappingsRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.MobileMoneyRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos.FlutterwaveBankResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos.FlutterwaveBillCategoryResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos.OnafriqBankResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos.PaystackBankResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.mappers.FlutterwaveBankMapper;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.mappers.FlutterwaveBillProviderMapper;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.mappers.FlutterwaveMobileMoneyMapper;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.mappers.OnafriqBankMapper;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.mappers.PaystackBankMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Optional;

// Comment: Marks this class as a service layer component for business logic execution
@Service
@RequiredArgsConstructor
public class ProviderSyncService {

    private final RestTemplate restTemplate = new RestTemplate();
    private final BanksRepository banksRepository;
    private final BillProviderRepository billProviderRepository;
    private final MobileMoneyRepository mobileMoneyRepository;
    private final MobileMoneyGatewayMappingsRepository mobileMoneyGatewayMappingsRepository;

    // Comment: Injecting our unified gateway mappers
    private final PaystackBankMapper paystackBankMapper;
    private final FlutterwaveBankMapper flutterwaveBankMapper;
    private final OnafriqBankMapper onafriqBankMapper;
    private final FlutterwaveBillProviderMapper flutterwaveBillProviderMapper;
    private final FlutterwaveMobileMoneyMapper flutterwaveMobileMoneyMapper;

    // Comment: Injecting base configuration URLs and secret keys from application properties
    @Value("${paystack.base-url}")
    String paystackBaseUrl;

    @Value("${flutterwave.base-url}")
    String flutterwaveBaseUrl;

    @Value("${onafriq.base-url}")
    String onafriqBaseUrl;

    @Value("${paystack.secret-key}")
    String paystackSk;

    @Value("${flutterwave.secret-key}")
    String flutterwaveSk;

    @Value("${onafriq.secret-key}")
    String onafriqSk;

    // Comment: Orchestrates fetching data from each specific provider per country in the list
    public void syncAllProvidersData(List<String> countryCodes) {
        for (String countryCode : countryCodes) {
            System.out.println("--------------------------------------------------");
            System.out.println("Starting data sync loop for country code: " + countryCode);

            fetchAndSaveBanks(countryCode);
            fetchAndSaveBillProviders(countryCode);
            fetchAndSaveMobileMoneyNetworks(countryCode);
        }
    }

    // Comment: Fetches banks across Paystack, Flutterwave, and Onafriq for a given country and saves them
    private void fetchAndSaveBanks(String countryCode) {
        // Comment: 1. FETCHING AND PARSING BANKS FROM PAYSTACK
        String paystackUrl = paystackBaseUrl + "/bank?country=" + countryCode;
        HttpHeaders paystackHeaders = new HttpHeaders();
        paystackHeaders.set("Authorization", "Bearer " + paystackSk);

        try {
            ResponseEntity<PaystackBankResponseDTO> response = restTemplate.exchange(
                    paystackUrl, HttpMethod.GET, new HttpEntity<>(paystackHeaders), PaystackBankResponseDTO.class
            );

            if (response.getBody() != null && response.getBody().status()) {
                List<BanksModel> banks = paystackBankMapper.mapToEntities(response.getBody(), countryCode);
                persistBanks(banks);
                System.out.println("Paystack Banks Response [" + countryCode + "]: Success. Upserted " + banks.size() + " banks.");
            }
        } catch (Exception e) {
            System.err.println("Failed to fetch Paystack banks for [" + countryCode + "]: " + e.getMessage());
        }

        // Comment: 2. FETCHING AND PARSING BANKS FROM FLUTTERWAVE
        String flutterWaveUrl = flutterwaveBaseUrl + "/banks/" + countryCode;
        HttpHeaders flutterwaveHeaders = new HttpHeaders();
        flutterwaveHeaders.set("Authorization", "Bearer " + flutterwaveSk);

        try {
            ResponseEntity<FlutterwaveBankResponseDTO> response = restTemplate.exchange(
                    flutterWaveUrl, HttpMethod.GET, new HttpEntity<>(flutterwaveHeaders), FlutterwaveBankResponseDTO.class
            );

            if (response.getBody() != null && "success".equalsIgnoreCase(response.getBody().status())) {
                List<BanksModel> banks = flutterwaveBankMapper.mapToEntities(response.getBody(), countryCode);
                persistBanks(banks);
                System.out.println("Flutterwave Banks Response [" + countryCode + "]: Success. Upserted " + banks.size() + " banks.");
            }
        } catch (Exception e) {
            System.err.println("Failed to fetch Flutterwave banks for [" + countryCode + "]: " + e.getMessage());
        }

        // Comment: 3. FETCHING AND PARSING BANKS FROM ONAFRIQ
        String onAfriqUrl = onafriqBaseUrl + "/api/financial-institutions?country=" + countryCode;
        HttpHeaders onafriqHeaders = new HttpHeaders();
        onafriqHeaders.set("Authorization", "Bearer " + onafriqSk);
        onafriqHeaders.set("Accept", "application/json");

        try {
            ResponseEntity<OnafriqBankResponseDTO> response = restTemplate.exchange(
                    onAfriqUrl, HttpMethod.GET, new HttpEntity<>(onafriqHeaders), OnafriqBankResponseDTO.class
            );

            if (response.getBody() != null) {
                List<BanksModel> banks = onafriqBankMapper.mapToEntities(response.getBody(), countryCode);
                persistBanks(banks);
                System.out.println("Onafriq Institutions Response [" + countryCode + "]: Success. Upserted " + banks.size() + " institutions.");
            }
        } catch (Exception e) {
            System.err.println("Failed to fetch Onafriq institutions for [" + countryCode + "]: " + e.getMessage());
        }
    }

    // Comment: Fetches bill providers exclusively from Flutterwave as Paystack doesn't support this
    private void fetchAndSaveBillProviders(String countryCode) {
        System.out.println("Fetching bill categories & providers from Flutterwave for [" + countryCode + "]...");

        String url = flutterwaveBaseUrl + "/bill-categories?country=" + countryCode;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + flutterwaveSk);

        try {
            ResponseEntity<FlutterwaveBillCategoryResponseDTO> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), FlutterwaveBillCategoryResponseDTO.class
            );

            if (response.getBody() != null && "success".equalsIgnoreCase(response.getBody().status())
                    && response.getBody().data() != null) {
                List<BillProviderModel> providers =
                        flutterwaveBillProviderMapper.mapToEntities(response.getBody(), countryCode);
                persistBillProviders(providers);
                System.out.println("Flutterwave Bill Categories Response [" + countryCode + "]: Success. Upserted "
                        + providers.size() + " bill providers.");
            } else {
                System.err.println("Flutterwave Bill Categories Response [" + countryCode + "]: returned no data.");
            }
        } catch (Exception e) {
            System.err.println("Failed to fetch bill providers from Flutterwave for [" + countryCode + "]: " + e.getMessage());
        }
    }

    // Comment: Fetches mobile money networks from supported gateways
    private void fetchAndSaveMobileMoneyNetworks(String countryCode) {
        System.out.println("Fetching mobile money operators from Flutterwave for [" + countryCode + "]...");

        String url = flutterwaveBaseUrl + "/bill-categories?category=momo&country=" + countryCode;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + flutterwaveSk);

        try {
            ResponseEntity<FlutterwaveBillCategoryResponseDTO> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), FlutterwaveBillCategoryResponseDTO.class
            );

            if (response.getBody() != null && "success".equalsIgnoreCase(response.getBody().status())
                    && response.getBody().data() != null) {
                List<MobileMoneyProvidersModel> providers =
                        flutterwaveMobileMoneyMapper.mapToEntities(response.getBody(), countryCode);
                persistMobileMoneyNetworks(providers, countryCode);
                System.out.println("Mobile Money Networks Response [" + countryCode + "]: Success. Upserted "
                        + providers.size() + " networks.");
            } else {
                System.err.println("Mobile Money Networks Response [" + countryCode + "]: returned no data.");
            }
        } catch (Exception e) {
            System.err.println("Failed to fetch mobile money networks for [" + countryCode + "]: " + e.getMessage());
        }
    }

    // ============================================================
    // UPSERT HELPERS — every run is idempotent: rows are matched by
    // their natural gateway key and updated in place instead of being
    // duplicated on each scheduled execution.
    // ============================================================

    private void persistBanks(List<BanksModel> banks) {
        for (BanksModel bank : banks) {
            banksRepository.findByCodeAndGatewayAndCountryCode(
                            bank.getCode(), bank.getGateway(), bank.getCountryCode())
                    .ifPresentOrElse(existing -> {
                        // Keep the original bank_id; refresh the mutable catalog fields.
                        existing.setBankName(bank.getBankName());
                        existing.setIban(bank.getIban());
                        existing.setPayWithBank(bank.getPayWithBank());
                        existing.setSwiftBic(bank.getSwiftBic());
                        existing.setCountry(bank.getCountry());
                        existing.setCurrencyCode(bank.getCurrencyCode());
                        existing.setMaxDailyValue(bank.getMaxDailyValue());
                        existing.setMaxMonthlyValue(bank.getMaxMonthlyValue());
                        existing.setMinTxnLimit(bank.getMinTxnLimit());
                        existing.setMaxTxnLimit(bank.getMaxTxnLimit());
                        existing.setMaxWeeklyValue(bank.getMaxWeeklyValue());
                        banksRepository.save(existing);
                    }, () -> banksRepository.save(bank));
        }
    }

    private void persistBillProviders(List<BillProviderModel> providers) {
        for (BillProviderModel provider : providers) {
            billProviderRepository.findByBillerCode(provider.getBillerCode())
                    .ifPresentOrElse(existing -> {
                        // Keep the original provider_id; refresh the mutable catalog fields.
                        existing.setBillerName(provider.getBillerName());
                        existing.setCategoryCode(provider.getCategoryCode());
                        existing.setCountryCode(provider.getCountryCode());
                        existing.setLogoUrl(provider.getLogoUrl());
                        existing.setChannelCode(provider.getChannelCode());
                        existing.setIsCrossBorderAllowed(provider.getIsCrossBorderAllowed());
                        existing.setActive(provider.getActive());
                        existing.setFetchRequirement(provider.getFetchRequirement());
                        existing.setGateway(provider.getGateway());
                        existing.setCustomerParamsSchema(provider.getCustomerParamsSchema());
                        billProviderRepository.save(existing);
                    }, () -> billProviderRepository.save(provider));
        }
    }

    private void persistMobileMoneyNetworks(List<MobileMoneyProvidersModel> providers, String countryCode) {
        for (MobileMoneyProvidersModel provider : providers) {
            MobileMoneyProvidersModel saved = mobileMoneyRepository.findByGlobalCode(provider.getGlobalCode())
                    .map(existing -> {
                        existing.setName(provider.getName());
                        existing.setCountryCode(provider.getCountryCode());
                        existing.setActive(provider.getActive());
                        return mobileMoneyRepository.save(existing);
                    })
                    .orElseGet(() -> mobileMoneyRepository.save(provider));

            saveGatewayMapping(saved, countryCode);
        }
    }

    private void saveGatewayMapping(MobileMoneyProvidersModel provider, String countryCode) {
        Optional<MobileMoneyGatewayMappingsModel> existing = mobileMoneyGatewayMappingsRepository
                .findByProviderIdAndGateway(provider.getProviderId(), "flutterwave");
        if (existing.isPresent()) {
            return;
        }

        MobileMoneyGatewayMappingsModel mapping = new MobileMoneyGatewayMappingsModel();
        mapping.setProviderId(provider.getProviderId());
        mapping.setGateway("flutterwave");
        mapping.setGatewayCode(provider.getGlobalCode());
        mapping.setCountryCode(countryCode);
        mobileMoneyGatewayMappingsRepository.save(mapping);
    }
}