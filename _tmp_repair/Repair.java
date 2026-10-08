import org.flywaydb.core.Flyway;

/**
 * One-off helper (lives outside the repo, in a temp dir).
 *
 * The dev database's flyway_schema_history records V1 and V7 with checksums
 * that no longer match the local migration files, so Flyway refuses to start.
 * Spring Boot has no "repair on migrate" property -- the
 * `spring.flyway.repair-on-migrate=true` line in application.properties is
 * not a real binding and is silently ignored -- so repair() has to be
 * invoked explicitly. Doing it here uses Flyway's own checksum algorithm
 * instead of hand-editing the history table.
 */
public class Repair {
    public static void main(String[] args) {
        Flyway flyway = Flyway.configure()
                .dataSource("jdbc:postgresql://localhost:5432/zentrapay_app", "postgres", "myself")
                .schemas("public")
                .locations("filesystem:C:/Users/Desire/Desktop/Zentrapay_Workspace/zentrapay_spring_boot_layer/src/main/resources/db/migration")
                .load();

        var result = flyway.repair();
        System.out.println("Repair actions: " + result.repairActions.size());
        result.repairActions.forEach(a -> System.out.println("  - " + a));

        System.out.println("\nPending migrations after repair:");
        for (var i : flyway.info().pending()) {
            System.out.println("  - " + i.getVersion() + " " + i.getDescription());
        }
    }
}
