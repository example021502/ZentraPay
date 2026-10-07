package com.zentrapay_application.zentrapay_spring_boot_layer.modules.qrCodes.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatAccountModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FiatAccountRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FiatWalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.qrCodes.dto.qrCodeInformationResponseDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class qrService {

    private UserRepository userRepository;
    private FiatWalletRepository fiatWalletRepository;
    private FiatAccountRepository fiatAccountRepository;
//GETTING THE USER INFORMATION FOR THE QR CODE
    public qrCodeInformationResponseDTO getInfo(UUID userId){
log.warn("========================= RESOLVING THE USER INFORMATION =======================");
        UserModel user = userRepository.getUserByUserId(userId)
                .orElseThrow(()-> new ResourceNotFoundException("User not found!"));
log.warn("========================= RESOLVING THE WALLET AND ACCOUNT INFORMATION =======================");
        UUID walletId = fiatWalletRepository.getWalletIdByUserId(userId)
                .orElseThrow(()-> new ResourceNotFoundException("Wallet not found!"));
        FiatAccountModel account = fiatAccountRepository.getAccountByWalletId(walletId)
                .orElseThrow(()-> new ResourceNotFoundException("Account not found!"));

log.warn("========================= RESOLVING QR CODE INFORMATION RESPONSE =======================");
        String userName = user.getFirstName() + " " + user.getLastName();
        return new qrCodeInformationResponseDTO(
                user.getPhoneNumber(),
                user.getEmail(),
                account.getZentag(),
                account.getCurrencyCode(),
                account.getAccountName(),
                userName
        );
    }
}
