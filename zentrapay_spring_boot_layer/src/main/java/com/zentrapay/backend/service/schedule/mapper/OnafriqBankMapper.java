package com.zentrapay.backend.service.schedule.mapper;

import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.dto.schedules.OnafriqBankResponseDTO;
import org.springframework.stereotype.Component;
import java.util.Collections;
import java.util.List;

@Component
public class OnafriqBankMapper implements BankMapper<OnafriqBankResponseDTO> {

    @Override
    public List<BanksModel> mapToEntities(OnafriqBankResponseDTO response, String countryCode) {
        if (response == null || response.results() == null) {
            return Collections.emptyList();
        }

        return response.results().stream().map(item -> {
            BanksModel bank = new BanksModel();
            bank.setBankName(item.bankName());
            bank.setGateway("onafriq");
            bank.setCode(item.bank_code());
            bank.setSwiftBic(item.bic());
            bank.setCountryCode(countryCode);
            bank.setCurrencyCode(item.currencyCode());
            bank.setIban(item.iban());
            bank.setMaxDailyValue(item.maxDailyValue());
            bank.setMaxMonthlyValue(item.maxMonthlyValue());
            bank.setMaxTxnLimit(item.maxPerTxLimit());
            bank.setMinTxnLimit(item.minPerTxLimit());
            bank.setMaxWeeklyValue(item.maxWeeklyValue());
            bank.setActive(true);
            return bank;
        }).toList();
    }
}