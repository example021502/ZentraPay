import io

PATH = r"C:\Users\Desire\Desktop\Zentrapay_Workspace\zentrapay_spring_boot_layer\src\main\java\com\zentrapay\backend\repository\GatewayRepository.java"

NEW = '''package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.GatewayModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

/**
 * Data access for {@code gateway_providers} — one row per connected
 * gateway (Paystack / Flutterwave / Onafriq).
 *
 * <p>The table carries no {@code primary} / {@code secondary} discriminator
 * columns — V9__gateway_directory_consolidation.sql dropped them — so the
 * primary/secondary roles are resolved by provider name instead.
 */
public interface GatewayRepository extends JpaRepository<GatewayModel, UUID> {

    /** The Paystack provider row — the primary gateway for national payments. */
    @Query("SELECT g FROM GatewayModel g WHERE LOWER(g.providerName) = 'paystack'")
    Optional<GatewayModel> getPrimaryGateway();

    /** The Flutterwave provider row — the failover gateway. */
    @Query("SELECT g FROM GatewayModel g WHERE LOWER(g.providerName) = 'flutterwave'")
    Optional<GatewayModel> getSecondaryGateway();

    @Query("SELECT g FROM GatewayModel g WHERE LOWER(g.providerName) = LOWER(:name)")
    Optional<GatewayModel> findGatewayProviderIgnoreCase(@Param("name") String name);
}
'''

with io.open(PATH, "w", encoding="utf-8", newline="\n") as fh:
    fh.write(NEW)
print("written")
