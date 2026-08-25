package com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.syncers.ProviderSyncService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

// Comment: Marks this class as a Spring component to run scheduled background jobs
@Component
public class schedulers {

    // Comment: Inject the service that handles the actual API calls and database persistence
    @Autowired
    private ProviderSyncService providerSyncService;


    // Comment: Runs every day at 01:00 to sync provider data (banks,
    // bill providers, mobile-money providers) from Paystack / Flutterwave / Onafriq.
    // Each sync is idempotent (upsert by gateway code), so a missed run is
    // harmless and a manual re-run just refreshes the directory.
    @Scheduled(cron = "0 0 0 * * *", zone = "UTC")
    public void syncProvidersDaily() {
        System.out.println("Executing scheduled task: Starting provider data synchronization...");
        final List<String> countries = List.of("GH","NG");
        try {
            // Comment: Execute the sync workflow for all providers based on their specific support
            providerSyncService.syncAllProvidersData(countries);
            System.out.println("Provider data synchronization completed successfully.");
        } catch (Exception e) {
            System.err.println("Error during provider data synchronization: " + e.getMessage());
        }
    }
}