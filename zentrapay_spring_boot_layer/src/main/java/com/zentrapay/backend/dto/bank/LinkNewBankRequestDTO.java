package com.zentrapay.backend.dto.bank;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.Size;

/**
 * POST /api/zbanking/link - what the AfriLink Connect widget returned to the app. No account number,
 * holder name or bank credential is ever sent: those stay inside AfriLink's widget.
 *
 * <p>Either of these is enough (the service refuses a request with neither):
 * <ul>
 *   <li>{@code publicToken} + {@code sessionId}: the link still has to be completed. The backend submits them,
 *       with the institution and AfriLink user id, to AfriLink's linking endpoint using the public key.</li>
 *   <li>{@code accountId}: the widget already completed the link and returned the linked account's id; the
 *       backend reads the account back from AfriLink to verify it.</li>
 * </ul>
 *
 * @param publicToken        the auth token / code the widget returned (also accepted as token, authCode, code)
 * @param sessionId          AfriLink connect session the token belongs to
 * @param afriLinkUserId     the user id AfriLink holds the connection under (the widget's {@code userId})
 * @param accountId          AfriLink's account id ({@code id} from the widget)
 * @param institutionName    bank name as shown by the widget
 * @param institutionId      bank id/code from the widget, if it gave one
 * @param institutionCountry ISO alpha-2 country the user was linking from, if known
 */
public record LinkNewBankRequestDTO(
        @JsonAlias({"token", "authCode", "code"}) @Size(max = 2048) String publicToken,
        @Size(max = 256) String sessionId,
        @Size(max = 128) String afriLinkUserId,
        @Size(max = 128) String accountId,
        @Size(max = 180) String institutionName,
        @Size(max = 128) String institutionId,
        @Size(max = 3) String institutionCountry
) {
    public boolean hasToken() {
        return publicToken != null && !publicToken.isBlank();
    }

    public boolean hasAccountId() {
        return accountId != null && !accountId.isBlank();
    }
}
