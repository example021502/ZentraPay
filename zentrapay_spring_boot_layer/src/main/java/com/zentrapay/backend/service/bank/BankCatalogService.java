package com.zentrapay.backend.service.bank;

import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.entity.PaymentChannel;
import com.zentrapay.backend.repository.BanksRepository;
import com.zentrapay.backend.repository.PaymentChannelRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

/**
 * Finds a bank in our catalogue and translates it to the code a given gateway uses.
 *
 * <p>Two catalogues exist: {@code banks} (real per-gateway codes, filled by the directory sync) and
 * {@code payment_channels} (the picker list, with our own codes such as GH_GCB). The same bank has
 * a DIFFERENT code on every gateway, so a payout or a name lookup must always use the code of the
 * gateway it is sent to.
 */
@Service
@RequiredArgsConstructor
public class BankCatalogService {

    private final BanksRepository banksRepository;
    private final PaymentChannelRepository paymentChannelRepository;

    /**
     * Finds the bank the app picked: by id, else by code + country, else (for a picker code
     * like GH_GCB) through its payment channel name.
     */
    public Optional<BanksModel> findBank(UUID bankId, String code, String countryCode) {
        if (bankId != null) {
            Optional<BanksModel> byId = banksRepository.findById(bankId);
            if (byId.isPresent()) {
                return byId;
            }
        }
        if (code == null || code.isBlank()) {
            return Optional.empty();
        }
        Optional<BanksModel> byCode = banksRepository.findFirstByCodeIgnoreCaseAndCountryCodeIgnoreCase(code, countryCode);
        if (byCode.isPresent()) {
            return byCode;
        }
        Optional<PaymentChannel> channel = paymentChannelRepository.findById(code);
        return channel.flatMap(c -> banksRepository.findFirstByGatewayIgnoreCaseAndCountryCodeIgnoreCaseAndBankNameIgnoreCase(
                c.getGateway(), c.getCountryCode(), c.getChannelName()));
    }

    /**
     * The code of this bank on the given gateway: its own code if the catalogue row belongs to that
     * gateway, otherwise the same bank (matched by name) in that gateway's catalogue.
     * Returns null when that gateway has no such bank.
     */
    public String codeOnGateway(BanksModel bank, String gatewayName, String countryCode) {
        if (gatewayName.equalsIgnoreCase(bank.getGateway())) {
            return bank.getCode();
        }
        return banksRepository
                .findFirstByGatewayIgnoreCaseAndCountryCodeIgnoreCaseAndBankNameIgnoreCase(gatewayName, countryCode, bank.getBankName())
                .map(BanksModel::getCode)
                .orElse(null);
    }
}
