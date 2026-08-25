package com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.services;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserBankModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.dtos.AccountsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.dtos.AccountsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dtos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
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
    public AccountsResponseDTO accounts(UUID userId) {
        List<UUID> bankIds = userBankRepository.getBankIdsByUserId(userId);
        List<AccountsDTO> accounts = banksRepository.getAccountsByBanksIds(bankIds)
                .stream()
                .map(b -> {
                    final UserBankModel balance = userBankRepository.getBalanceByUserIdAndBankId(userId, b.getBankId());

                    return new AccountsDTO(
                        b.getBankId(),
                        b.getBankName(),
                        b.getCode(),
                        balance.getLastDigits(),
                        balance.getBalance(),
                        b.getCountryCode(),
                        b.getCurrencyCode(),
                        b.getCreatedAt()
                );
                }).toList();
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
                .map(b -> {
                    final UserBankModel balance = userBankRepository.getBalanceByUserIdAndBankId(userId, b.getBankId());

                    return new AccountsDTO(
                        b.getBankId(),
                        b.getBankName(),
                        b.getCode(),
                        balance.getLastDigits(),
                        balance.getBalance(),
                        b.getCountryCode(),
                        b.getCurrencyCode(),
                        b.getCreatedAt()
                );
                }).toList();
    return new AccountsResponseDTO(accounts);
    }


}
