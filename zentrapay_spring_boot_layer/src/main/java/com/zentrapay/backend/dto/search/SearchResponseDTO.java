package com.zentrapay.backend.dto.search;


import java.util.List;

/**
 * DTO representing the data returned by a contacts search.
 *
 * <p>Two scopes (see SearchContactsService):
 * <ul>
 *   <li>DOMESTIC      - app users, bill providers, banks and mobile-money networks in the SAME
 *       country as the person searching (the Pay section).</li>
 *   <li>INTERNATIONAL - app users, banks and mobile-money networks in OTHER supported countries
 *       (ZRemit). Bill providers are domestic only, so that list is empty.</li>
 * </ul>
 * Banks and networks come from the catalogues the scheduler syncs from Paystack / Flutterwave /
 * Onafriq, so only ones the providers can actually pay are returned.
 */
public record SearchResponseDTO(
        List<UserSearchDTO> appUsers,
        List<BillProviderSearchDTO> billProviders,
        List<BankSearchDTO> banks,
        List<MobileMoneySearchDTO> mobileMoney
) {
}
