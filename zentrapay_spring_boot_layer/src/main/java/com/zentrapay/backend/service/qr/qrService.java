package com.zentrapay.backend.service.qr;

import com.zentrapay.backend.entity.FiatAccountModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.repository.FiatAccountRepository;
import com.zentrapay.backend.repository.FiatWalletRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.dto.qr.qrCodeInformationResponseDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class qrService {

    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
//GETTING THE USER INFORMATION FOR THE QR CODE
    public qrCodeInformationResponseDTO getInfo(UUID userId){
log.warn("========================= RESOLVING THE USER INFORMATION =======================");
        UserModel user = userRepository.getUserByUserId(userId)
                .orElseThrow(()-> new ResourceNotFoundException("User not found!"));
log.warn("========================= RESOLVING THE WALLET AND ACCOUNT INFORMATION =======================");
        UUID walletId = fiatWalletRepository.getWalletIdByUserId(userId)
                .orElseThrow(()-> new ResourceNotFoundException("Wallet not found!"));
        FiatAccountModel account = fiatAccountRepository.getDefaultAccountByWalletId(walletId)
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
