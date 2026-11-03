package com.zentrapay.backend.service.bank;

import com.zentrapay.backend.dto.bank.LinkNewBankRequestDTO;
import com.zentrapay.backend.dto.payment.AfriLinkAccountDTO;
import com.zentrapay.backend.exception.PaymentGatewayException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Turns what the AfriLink Connect widget gave the app into a verified linked account.
 *
 * <p>The app never sends an account number or credentials. It sends what the widget returned:
 * <ul>
 *   <li>a session id + auth token: the link is completed here by submitting them (with the institution and
 *       AfriLink user id) to AfriLink's linking endpoint using the PUBLIC key; or</li>
 *   <li>the account id of a link the widget already completed: it is read back with the SECRET key.</li>
 * </ul>
 * Either way AfriLink rejects anything it did not issue, so a client cannot link an account that was not
 * genuinely connected. Paystack / Flutterwave / Onafriq are settlement rails and are never called from here.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BankAccountLinkService {

    public static final String PROVIDER_AFRILINK = "AFRILINK";

    private static final String LINK_FAILED = "We couldn't link this account. Please try connecting your bank again.";

    private final AfriLinkClient afriLinkClient;

    /**
     * When true the account must have been connected under THIS ZentraPay user's id (the app passes
     * it to the widget as the customer id). Off by default until it has been confirmed against a real
     * AfriLink test account that {@code userId} in the account payload echoes the id we sent.
     */
    @Value("${afrilink.require-owner-match:false}")
    private boolean requireOwnerMatch;

    /**
     * @param request what the widget returned (token + session, or the account id)
     * @param userId  the signed-in ZentraPay user (as a string)
     * @return the account as AfriLink reports it - never {@code null}
     * @throws IllegalArgumentException when the request carries neither a token nor an account id
     * @throws PaymentGatewayException  when AfriLink does not recognise the link or is unreachable
     */
    public AfriLinkAccountDTO link(LinkNewBankRequestDTO request, String userId) {
        final AfriLinkAccountDTO account;
        try {
            if (request.hasToken()) {
                if (request.sessionId() == null || request.sessionId().isBlank()) {
                    throw new IllegalArgumentException("The bank connection is incomplete. Please try connecting your bank again.");
                }
                log.info("Completing an AfriLink link for user {} (session {})", userId, request.sessionId());
                AfriLinkAccountDTO completed = afriLinkClient.completeLink(
                        request.sessionId().trim(),
                        firstNonBlank(request.afriLinkUserId(), userId),
                        request.institutionName(),
                        request.publicToken().trim());
                account = readBack(completed);
            } else if (request.hasAccountId()) {
                log.info("Confirming AfriLink account {} for user {}", request.accountId(), userId);
                account = afriLinkClient.fetchAccount(request.accountId().trim());
            } else {
                throw new IllegalArgumentException("Linked account missing. Please try connecting your bank again.");
            }
        } catch (PaymentGatewayException e) {
            log.error("AfriLink could not link the account: {}", e.getMessage());
            // Customer-facing: never name the provider or the failure details.
            throw new PaymentGatewayException(LINK_FAILED);
        }

        if (account.ownerUserId() != null && !account.ownerUserId().equalsIgnoreCase(userId)) {
            log.debug("AfriLink account {} belongs to userId '{}' at AfriLink, not '{}'", account.accountId(), account.ownerUserId(), userId);
            if (requireOwnerMatch) {
                throw new PaymentGatewayException(LINK_FAILED);
            }
        }
        return account;
    }

    // The completion reply can be sparse: read the account again for balance, currency and type.
    // If that read fails the link is still valid, so keep what the completion returned.
    private AfriLinkAccountDTO readBack(AfriLinkAccountDTO completed) {
        try {
            return afriLinkClient.fetchAccount(completed.accountId());
        } catch (PaymentGatewayException e) {
            log.info("AfriLink account {} could not be read back, using the completion reply: {}", completed.accountId(), e.getMessage());
            return completed;
        }
    }

    private static String firstNonBlank(String a, String b) {
        return a != null && !a.isBlank() ? a.trim() : b;
    }
}
