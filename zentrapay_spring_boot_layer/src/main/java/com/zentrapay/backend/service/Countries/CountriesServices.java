package com.zentrapay.backend.service.Countries;

import com.zentrapay.backend.repository.CountriesRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Sending money out of a user's wallet. Two kinds of payment:
 * <ul>
 *   <li><b>P2P_TRANSFER</b>  - to another ZentraPay user (same currency or cross currency).
 *       Stays inside our own ledger, so it is one all-or-nothing database transaction.</li>
 *   <li><b>CASH_OUT_BANK</b> - to a bank account through a payment gateway (same currency or
 *       cross currency). Money is debited first, then the gateway is called; if the gateway
 *       refuses, the money is refunded. See BankTransferServices.</li>
 *   <li><b>CASH_OUT_MOMO</b> - to a mobile-money wallet, same engine as the bank payout.</li>
 * </ul>
 *
 * <p>Every payment here is DOMESTIC: the sender, the bank / network and the receiver are in the
 * same, supported country. Cross-border sends belong to ZRemit. Before a bank or mobile-money
 * payment is debited, the providers are asked who owns the account (AccountVerificationService).
 *
 * <p>This class is deliberately NOT one big database transaction: the slow gateway calls must
 * not hold a database connection open, and the debit has to be committed before the gateway
 * is called. Each step that moves money is its own transaction inside LedgerOperations.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CountriesServices {

    private final CountriesRepository countriesRepository;

    // ==================================================================
    // GETTING COUNTRY CODES USING A CURRENCY CODE
    // ==================================================================


}
