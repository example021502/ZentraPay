package com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.mappers;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BanksModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos.PaystackBankResponseDTO;
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
                .filter(PaystackBankResponseDTO.BankItemDTO::active)
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