package com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.mappers;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BanksModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos.FlutterwaveBankResponseDTO;
import org.springframework.stereotype.Component;
import java.util.Collections;
import java.util.List;

import static com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.CurrencyUtil.getCurrencyCode;

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
            String currency = getCurrencyCode(countryCode);
            bank.setCurrencyCode(currency != null ? currency : "USD");
            bank.setActive(true);
            return bank;
        }).toList();
    }
}