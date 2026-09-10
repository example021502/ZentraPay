package com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.services;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.dtos.AccountsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.dtos.AccountsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dtos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BankAccountsServices {

    private final BanksRepository banksRepository;
    private final UserBankRepository userBankRepository;

    /*
    * GETTING ALL THE LINKED BANK ACCOUNTS
    * */
    @Transactional(readOnly = true)
    public AccountsResponseDTO getUserAccounts(UUID userId) {
        // Reuse the canonical implementation below (the previous inline body was
        // left half-written and referenced undefined variables, so it would not
        // compile). Both methods return the user's linked bank accounts.
        return getAccounts(userId);
    }
    /*
    * GETTING ALL THE LINKED BANK ACCOUNTS
    * */
    @Transactional(readOnly = true)
    public AccountsResponseDTO getAccounts(UUID userId) {
        List<UUID> bankIds = userBankRepository.getBankIdsByUserId(userId);
        List<AccountsDTO> accounts = banksRepository.getAccountsByBanksIds(bankIds)
                .stream()
                .map(b -> new AccountsDTO(
                        b.getBankId(),
                        b.getCode(),
                        b.getBankName(),
                        b.getGateway(),
                        b.getIban(),
                        b.getCurrencyCode(),
                        b.getPayWithBank(),
                        b.getSwiftBic(),
                        b.getCountryCode(),
                        b.getCountry(),
                        b.getStatus(),
                        b.getCreatedAt(),
                        b.getUpdatedAt(),
                        b.getMaxDailyValue(),
                        b.getMaxMonthlyValue(),
                        b.getMinTxnLimit(),
                        b.getMaxTxnLimit(),
                        b.getMaxWeeklyValue()
                ))
                .toList();
        return new AccountsResponseDTO(accounts);
    }

/*
*   LINK A NEW BANK ACCOUNT
* */
    @Transactional(readOnly = true)
    public AccountsResponseDTO newBank(UUID userId) {
        List<UUID> bankIds = userBankRepository.getBankIdsByUserId(userId);
        List<AccountsDTO> accounts = banksRepository.getAccountsByBanksIds(bankIds)
                .stream()
                .map(b -> new AccountsDTO(
                        b.getBankId(),
                        b.getCode(),
                        b.getBankName(),
                        b.getGateway(),
                        b.getIban(),
                        b.getCurrencyCode(),
                        b.getPayWithBank(),
                        b.getSwiftBic(),
                        b.getCountryCode(),
                        b.getCountry(),
                        b.getStatus(),
                        b.getCreatedAt(),
                        b.getUpdatedAt(),
                        b.getMaxDailyValue(),
                        b.getMaxMonthlyValue(),
                        b.getMinTxnLimit(),
                        b.getMaxTxnLimit(),
                        b.getMaxWeeklyValue()
                ))
                .toList();
        return new AccountsResponseDTO(accounts);
    }


}
