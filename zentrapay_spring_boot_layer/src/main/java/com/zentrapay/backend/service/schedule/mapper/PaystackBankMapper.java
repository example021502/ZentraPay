package com.zentrapay.backend.service.schedule.mapper;

import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.dto.schedules.PaystackBankResponseDTO;
import org.springframework.stereotype.Component;
import java.util.Collections;
import java.util.List;

@Component
public class PaystackBankMapper implements BankMapper<PaystackBankResponseDTO> {

    @Override
    public List<BanksModel> mapToEntities(PaystackBankResponseDTO response, String countryCode) {
        if (response == null || response.data() == null) {
            return Collections.emptyList();
        }

        return response.data().stream()
                // a missing "active" flag means the bank is usable; only an explicit false hides it
                .filter(item -> !Boolean.FALSE.equals(item.active()))
                .filter(item -> item.code() != null && !item.code().isBlank() && item.name() != null)
                .map(item -> {
                    BanksModel bank = new BanksModel();
                    bank.setBankName(item.name());
                    bank.setCode(item.code());
                    bank.setType(item.type());
                    bank.setGateway("paystack");
                    bank.setCountry(item.country());
                    bank.setCountryCode(countryCode);
                    bank.setPayWithBank(item.pay_with_bank());
                    bank.setCurrencyCode(item.currency());
                    bank.setActive(true);
                    return bank;
                })
                .toList();
    }
}