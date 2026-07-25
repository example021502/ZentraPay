package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto.RequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto.ResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.CryptoBalancesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.FiatBalancesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository.CryptoBalancesRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository.FiatBalancesRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BalancesServices {
private final FiatBalancesRepository fiatBalancesRepository;
private final CryptoBalancesRepository cryptoBalancesRepository;

//    GETTING ALL BALANCES
    public ResponseDTO getAllCurrencyBalances(@Valid RequestDTO req) {

        List<FiatBalancesModel> fiatBalances = fiatBalancesRepository.findByUserId(req.userId());
if(fiatBalances == null || fiatBalances.isEmpty()){
    throw new RuntimeException("No Fiat accounts found for this user.");
}
        List<CryptoBalancesModel> cryptoBalances = cryptoBalancesRepository.findByUserId(req.userId());
if(cryptoBalances == null || cryptoBalances.isEmpty()){
    throw new RuntimeException("No Crypto accounts found for this user.");
}
        return new ResponseDTO(fiatBalances, cryptoBalances);
    }

//    GETTING FIAT BALANCES
    public ResponseDTO getFiatCurrencyBalances(@Valid RequestDTO req) {

        List<FiatBalancesModel> fiatBalances = fiatBalancesRepository.findByUserId(req.userId());
if(fiatBalances == null || fiatBalances.isEmpty()){
    throw new RuntimeException("No Fiat accounts found for this user.");
}

        return new ResponseDTO(fiatBalances, null);
    }

//    GETTING CRYPTO BALANCES
    public ResponseDTO getCryptoCurrencyBalances(@Valid RequestDTO req) {
        List<CryptoBalancesModel> cryptoBalances = cryptoBalancesRepository.findByUserId(req.userId());
if(cryptoBalances == null || cryptoBalances.isEmpty()){
    throw new RuntimeException("No Crypto accounts found for this user.");
}
        return new ResponseDTO(null, cryptoBalances);
    }
}