package com.zentrapay.backend.service.schedule.sync;

import lombok.extern.slf4j.Slf4j;
import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.entity.BillProviderModel;
import com.zentrapay.backend.entity.MobileMoneyGatewayMappingsModel;
import com.zentrapay.backend.entity.MobileMoneyProvidersModel;
import com.zentrapay.backend.repository.BanksRepository;
import com.zentrapay.backend.repository.BillProviderRepository;
import com.zentrapay.backend.repository.MobileMoneyGatewayMappingsRepository;
import com.zentrapay.backend.repository.MobileMoneyRepository;
import com.zentrapay.backend.dto.schedules.FlutterwaveBankResponseDTO;
import com.zentrapay.backend.dto.schedules.FlutterwaveBillCategoryResponseDTO;
import com.zentrapay.backend.dto.schedules.OnafriqBankResponseDTO;
import com.zentrapay.backend.dto.schedules.PaystackBankResponseDTO;
import com.zentrapay.backend.service.schedule.mapper.FlutterwaveBankMapper;
import com.zentrapay.backend.service.schedule.mapper.FlutterwaveBillProviderMapper;
import com.zentrapay.backend.service.schedule.mapper.FlutterwaveMobileMoneyMapper;
import com.zentrapay.backend.service.schedule.mapper.OnafriqBankMapper;
import com.zentrapay.backend.service.schedule.mapper.PaystackBankMapper;
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
@Slf4j
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
            log.info("--------------------------------------------------");
            log.info("Starting data sync loop for country code: " + countryCode);

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

            if (response.getBody() != null && Boolean.TRUE.equals(response.getBody().status())) {
                List<BanksModel> banks = paystackBankMapper.mapToEntities(response.getBody(), countryCode);
                persistBanks(banks);
                log.info("Paystack Banks Response [" + countryCode + "]: Success. Upserted " + banks.size() + " banks.");
            }
        } catch (Exception e) {
            log.error("Failed to fetch Paystack banks for [" + countryCode + "]: " + e.getMessage());
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
                log.info("Flutterwave Banks Response [" + countryCode + "]: Success. Upserted " + banks.size() + " banks.");
            }
        } catch (Exception e) {
            log.error("Failed to fetch Flutterwave banks for [" + countryCode + "]: " + e.getMessage());
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
                log.info("Onafriq Institutions Response [" + countryCode + "]: Success. Upserted " + banks.size() + " institutions.");
            }
        } catch (Exception e) {
            log.error("Failed to fetch Onafriq institutions for [" + countryCode + "]: " + e.getMessage());
        }
    }

    // Comment: Fetches bill providers exclusively from Flutterwave as Paystack doesn't support this
    private void fetchAndSaveBillProviders(String countryCode) {
        log.info("Fetching bill categories & providers from Flutterwave for [" + countryCode + "]...");

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
                log.info("Flutterwave Bill Categories Response [" + countryCode + "]: Success. Upserted "
                        + providers.size() + " bill providers.");
            } else {
                log.error("Flutterwave Bill Categories Response [" + countryCode + "]: returned no data.");
            }
        } catch (Exception e) {
            log.error("Failed to fetch bill providers from Flutterwave for [" + countryCode + "]: " + e.getMessage());
        }
    }

    // Comment: Fetches mobile money networks from supported gateways
    private void fetchAndSaveMobileMoneyNetworks(String countryCode) {
        log.info("Fetching mobile money operators from Flutterwave for [" + countryCode + "]...");

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
                log.info("Mobile Money Networks Response [" + countryCode + "]: Success. Upserted "
                        + providers.size() + " networks.");
            } else {
                log.error("Mobile Money Networks Response [" + countryCode + "]: returned no data.");
            }
        } catch (Exception e) {
            log.error("Failed to fetch mobile money networks for [" + countryCode + "]: " + e.getMessage());
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
                        existing.setType(bank.getType());
                        existing.setIban(bank.getIban());
                        existing.setRoutingNumber(bank.getRoutingNumber());
                        existing.setPayWithBank(bank.getPayWithBank());
                        existing.setSwiftBic(bank.getSwiftBic());
                        existing.setCountry(bank.getCountry());
                        existing.setCurrencyCode(bank.getCurrencyCode());
                        existing.setActive(bank.getActive());
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
            // biller_code is no longer unique (same biller can come from
            // several gateways), so match on (biller_code, gateway) first
            // and only fall back to any row with that biller code.
            billProviderRepository.findByBillerCodeAndGateway(
                            provider.getBillerCode(), provider.getGateway())
                    .or(() -> billProviderRepository
                            .findByBillerCode(provider.getBillerCode())
                            .stream()
                            .findFirst())
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