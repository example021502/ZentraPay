package com.zentrapay.backend.service.schedule.mapper;

import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.dto.schedules.FlutterwaveBankResponseDTO;
import com.zentrapay.backend.service.common.CurrencyUtil;
import org.springframework.stereotype.Component;
import java.util.Collections;
import java.util.List;

@Component
public class FlutterwaveBankMapper implements BankMapper<FlutterwaveBankResponseDTO> {

    @Override
    public List<BanksModel> mapToEntities(FlutterwaveBankResponseDTO response, String countryCode) {
        if (response == null || response.data() == null) {
            return Collections.emptyList();
        }

        return response.data().stream().map(item -> {
            BanksModel bank = new BanksModel();
            bank.setBankName(item.name());
            bank.setCode(item.code());
            bank.setGateway("flutterwave");
            bank.setCountryCode(countryCode);
            // Flutterwave's /banks/{country} payload carries no per-bank
            // currency, so derive it from the country. Fall back to USD rather
            // than persisting null — banks.currency_code is NOT NULL.
            String currency = CurrencyUtil.getCurrencyCode(countryCode);
            bank.setCurrencyCode(currency != null ? currency : "USD");
            bank.setActive(true);
            return bank;
        }).toList();
    }
}