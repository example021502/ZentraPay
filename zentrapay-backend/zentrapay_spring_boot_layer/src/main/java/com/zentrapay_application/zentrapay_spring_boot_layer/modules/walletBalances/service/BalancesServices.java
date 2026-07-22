package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto.RequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto.ResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.WalletBalancesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository.FiatBalancesRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class WalletBalancesServices {
private final FiatBalancesRepository walletBalacesRepository;

    public ResponseDTO getAllCurrencyBalances(@Valid RequestDTO req) {

        WalletBalancesModel user = new WalletBalancesModel();
        user.(req.userId());
        user.setEmail(req.email());
        user.setPassword(hashedPassword);
        user.setZentag(req.zentag());
        user.setPin(hashedPin);
        user.setCountry(req.country());
        user.setPhoneNumber(req.phoneNumber());

        userRepository.save(user);

        String token = jwtService.generateToken(user.getEmail(), user.getUserId());
        return new usersAuthResponse(token, user.getFullName(), user.getEmail(), user.getZentag());
    }
}