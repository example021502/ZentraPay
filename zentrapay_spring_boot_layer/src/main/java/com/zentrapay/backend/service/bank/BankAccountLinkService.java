package com.zentrapay.backend.service.bank;

import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.dto.payment.AfriqLinkAccountResponseDTO;
import com.zentrapay.backend.exception.PaymentGatewayException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Sends the open-banking *linking request* for the ZBank Lite "link a bank"
 * sheet to <b>AfriqLink</b> — the project's single open-banking provider.
 *
 * <p>Paystack / Flutterwave / Onafriq are payment SETTLEMENT orchestrators and
 * offer nothing on open banking, so they are deliberately NOT called from this
 * service — they remain wired to the payout, checkout and webhook flows only.
 *
 * <p>NOTE: the AfriqLink account has not been created yet (no API keys), so
 * {@code application.properties} carries clearly-marked placeholders that will
 * be replaced with the real values later.
 *
 * <p>The accepted provider reference comes back as the {@code connectionId}
 * persisted on the link row. If AfriqLink declines (or is unreachable) a
 * {@link PaymentGatewayException} is thrown, so a link the provider did not
 * confirm is never saved.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BankAccountLinkService {

    public static final String PROVIDER_AFRIQLINK = "afriqlink";

    private final AfriqLinkClient afriqLinkClient;

    /**
     * Which provider confirmed the linking request and the reference to persist
     * as {@code connectionId} (e.g. {@code afriqlink:LNK_1a2b3c}).
     */
    public record BankLinkOutcome(String gateway, String connectionId) {
    }

    /**
     * Runs the open-banking linking request through AfriqLink for one account.
     *
     * @param bank          catalog row supplying the bank code, currency and
     *                      country
     * @param accountNumber digits-only account number (already normalised)
     * @param firstName     holder's first name as typed in the sheet
     * @param lastName      holder's last name as typed in the sheet
     * @return the confirmed provider outcome — never {@code null}
     * @throws PaymentGatewayException when AfriqLink declines or is unreachable
     */
    public BankLinkOutcome link(BanksModel bank, String accountNumber,
                                 String firstName, String lastName) {
        log.info("Resolving the bank account and user information via AfriqLink");
        final String bankCode = bank.getCode();
        final String lastDigits = accountNumber.substring(accountNumber.length() - 4);

        // AfriqLink is the project's single open-banking provider — the
        // settlement gateways (Paystack / Flutterwave / Onafriq) are never
        // called here. Their account-linking methods were removed from the
        // settlement clients so they cannot be reused for open banking.
        AfriqLinkAccountResponseDTO linked;
        try {
            linked = afriqLinkClient.linkAccount(
                    bankCode,
                    accountNumber,
                    bank.getCurrencyCode(),
                    bank.getCountryCode(),
                    firstName,
                    lastName);
        } catch (PaymentGatewayException e) {
            log.error("AfriqLink linking request failed (bank {} account {}): {}",
                    bankCode, lastDigits, e.getMessage());
            throw new PaymentGatewayException(
                    "AfriqLink could not link this account right now. Please try again later.");
        }

        final String reference = linked.reference() != null
                ? linked.reference()
                : bankCode + ":" + lastDigits;
        log.info("Bank account linked via AfriqLink: {}", reference);
        return new BankLinkOutcome(
                PROVIDER_AFRIQLINK, PROVIDER_AFRIQLINK + ":" + reference);
    }
}


