package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto;

<<<<<<< HEAD
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.CryptoBalancesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.FiatBalancesModel;

import java.util.List;

=======
>>>>>>> update
/**
 * DTO representing the data returned upon successful authentication.
 * We use a Java record here for immutability and conciseness.
 */
<<<<<<< HEAD
public record ResponseDTO(

        List<FiatBalancesModel> fiatBalances,
        List<CryptoBalancesModel> cryptoBalances
=======
public record WalletBalancesResponseDTO(
        List balances,
        String fullName,
        String email,
        String zentag
>>>>>>> update
) {}
