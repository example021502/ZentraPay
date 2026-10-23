package com.zentrapay.backend.service.schedule;

import lombok.extern.slf4j.Slf4j;
import com.zentrapay.backend.service.schedule.sync.GatewayDirectorySyncService;
import com.zentrapay.backend.service.schedule.sync.ProviderSyncService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;

// Comment: Marks this class as a Spring component to run scheduled background jobs
@Slf4j
@Component
public class Schedulers {
    // Comment: Inject the service that handles the actual API calls and database persistence
    @Autowired
    private ProviderSyncService providerSyncService;

    // Comment: gateway_countries/gateway_currencies syncer — unified onto this
    // same daily trigger (and country list) instead of running independently
    // on its own 02:00 cron, so the whole reference-data directory refreshes
    // together instead of drifting apart.
    @Autowired
    private GatewayDirectorySyncService gatewayDirectorySyncService;

    // Comment: Same property GatewayDirectorySyncService already reads — one
    // shared country list for every scheduled sync instead of this class's
    // own hardcoded GH/NG subset.
    @Value("${app.gateway.countries:GH,NG,KE,TZ,UG,RW,ZA,CI,SN,CM}")
    private String configuredCountries;

    // Comment: Runs every day at 00:00 UTC to sync provider data (banks,
    // bill providers, mobile-money providers) AND the gateway_countries /
    // gateway_currencies directory from Paystack / Flutterwave / Onafriq.
    // Each sync is idempotent (upsert by gateway code), so a missed run is
    // harmless and a manual re-run just refreshes the directory.
    @Scheduled(cron = "0 0 0 * * *", zone = "UTC")
    public void syncProvidersDaily() {
        log.info("Executing scheduled task: Starting provider data synchronization...");
        final List<String> countries = Arrays.stream(configuredCountries.split(","))
                .map(String::trim)
                .filter(c -> !c.isEmpty())
                .toList();
        try {
            // Comment: Execute the sync workflow for all providers based on their specific support
            providerSyncService.syncAllProvidersData(countries);
            log.info("Provider data synchronization completed successfully.");
        } catch (Exception e) {
            log.error("Error during provider data synchronization: " + e.getMessage());
        }

        try {
            // Comment: Same trigger, same country list — gateway_countries /
            // gateway_currencies now refresh alongside banks/bill-providers/momo.
            gatewayDirectorySyncService.refreshGatewayDirectory();
            log.info("Gateway directory synchronization completed successfully.");
        } catch (Exception e) {
            log.error("Error during gateway directory synchronization: " + e.getMessage());
        }
    }
}