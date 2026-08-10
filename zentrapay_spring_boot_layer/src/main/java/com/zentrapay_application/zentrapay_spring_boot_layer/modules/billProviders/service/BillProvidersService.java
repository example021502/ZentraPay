package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Transaction;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.User;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Wallet;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.WalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.model.BillPayment;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.model.BillProvider;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.repository.BillPaymentRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.repository.BillProviderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class BillProvidersService {

    private final BillProviderRepository billProviderRepository;
    private final BillPaymentRepository billPaymentRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    @Transactional(readOnly = true)
    public List<BillProviderDTO> listProviders(String countryCode, String categoryCode) {
        List<BillProvider> providers;
        boolean hasCountry = countryCode != null && !countryCode.isBlank();
        boolean hasCategory = categoryCode != null && !categoryCode.isBlank();
        if (hasCountry && hasCategory) {
            providers = billProviderRepository.findByCountryCodeAndCategoryCode(countryCode.toUpperCase(), categoryCode.toUpperCase());
        } else if (hasCountry) {
            providers = billProviderRepository.findByCountryCode(countryCode.toUpperCase());
        } else if (hasCategory) {
            providers = billProviderRepository.findByCategoryCode(categoryCode.toUpperCase());
        } else {
            providers = billProviderRepository.findAll();
        }

        // Filter using the boolean active property via the getter method
        return providers.stream()
                .filter(BillProvider::getActive)
                .map(this::toProviderDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public ValidateResponseDTO validate(ValidateRequestDTO request) {
        BillProvider provider = billProviderRepository.findById(request.providerId())
                .orElseThrow(() -> new ResourceNotFoundException("Bill provider not found"));
        boolean valid = isValidReference(provider.getFetchRequirement(), request.customerReference());
        // No live utility-company lookup is wired up in this pass, so we can't return a
        // real customerName — leaving it null rather than fabricating one.
        return new ValidateResponseDTO(valid, null);
    }

    public PayResponseDTO pay(UUID userId, PayRequestDTO request) {
        BillProvider provider = billProviderRepository.findById(request.providerId())
                .orElseThrow(() -> new ResourceNotFoundException("Bill provider not found"));

        if (!isValidReference(provider.getFetchRequirement(), request.customerReference())) {
            throw new IllegalArgumentException("Invalid customer reference for " + provider.getBillerName());
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (!passwordEncoder.matches(request.pin() + pinPepper, user.getTransactionPinHash())) {
            throw new IllegalArgumentException("Invalid PIN");
        }

        Wallet wallet = walletRepository.findByUserIdAndCurrencyCode(userId, request.currencyCode())
                .orElseThrow(() -> new ResourceNotFoundException("No wallet found for currency " + request.currencyCode()));

        if (wallet.getBalance().compareTo(request.amount()) < 0) {
            throw new IllegalStateException("Insufficient balance");
        }

        int debited = walletRepository.debit(wallet.getWalletId(), request.amount());
        if (debited == 0) {
            throw new IllegalStateException("Insufficient balance");
        }

        Transaction transaction = new Transaction();
        transaction.setUserId(userId);
        transaction.setWalletId(wallet.getWalletId());
        transaction.setTypeCode("BILL_PAYMENT");
        transaction.setAmount(request.amount());
        transaction.setCurrencyCode(request.currencyCode());
        transaction.setStatus("SUCCESS");
        transaction.setReference("BILL-" + UUID.randomUUID().toString().substring(0, 12).toUpperCase());
        transaction.setCounterpartyName(provider.getBillerName());
        transaction.setCounterpartyIdentifier(request.customerReference());
        transaction.setDescription("Bill payment to " + provider.getBillerName());
        transaction = transactionRepository.save(transaction);

        BillPayment payment = new BillPayment();
        payment.setUserId(userId);
        payment.setProviderId(provider.getProviderId());
        payment.setTransactionId(transaction.getTransactionId());
        payment.setCustomerReference(request.customerReference());
        payment.setAmount(request.amount());
        payment.setCurrencyCode(request.currencyCode());
        payment.setStatus("SUCCESS");
        payment = billPaymentRepository.save(payment);

        return new PayResponseDTO(
                new PaymentSummaryDTO(payment.getPaymentId(), payment.getStatus()),
                toTransactionDTO(transaction));
    }

    @Transactional(readOnly = true)
    public List<BillPaymentHistoryDTO> history(UUID userId) {
        List<BillPayment> payments = billPaymentRepository.findByUserIdOrderByCreatedAtDesc(userId);
        if (payments.isEmpty()) {
            return List.of();
        }
        Map<UUID, BillProvider> providersById = billProviderRepository.findAllById(
                payments.stream().map(BillPayment::getProviderId).distinct().toList()
        ).stream().collect(java.util.stream.Collectors.toMap(BillProvider::getProviderId, p -> p));

        return payments.stream()
                .map(p -> new BillPaymentHistoryDTO(
                        p.getPaymentId(),
                        providersById.containsKey(p.getProviderId()) ? providersById.get(p.getProviderId()).getBillerName() : null,
                        p.getCustomerReference(),
                        p.getAmount(),
                        p.getCurrencyCode(),
                        p.getStatus(),
                        p.getCreatedAt()))
                .toList();
    }

    /**
     * Simple, real (non-mocked) format/length validation per the provider's
     * fetchRequirement — no live utility-company API call, per API_CONTRACT.md §8.
     */
    private boolean isValidReference(String fetchRequirement, String customerReference) {
        if (customerReference == null || customerReference.isBlank()) {
            return false;
        }
        String trimmed = customerReference.trim();
        if (trimmed.length() < 4 || trimmed.length() > 20) {
            return false;
        }
        if (fetchRequirement != null &&
                (fetchRequirement.contains("METER_NUMBER") || fetchRequirement.contains("ACCOUNT_NUMBER")
                        || fetchRequirement.contains("SMARTCARD_NUMBER"))) {
            return trimmed.chars().allMatch(Character::isDigit);
        }
        return true;
    }

    private BillProviderDTO toProviderDTO(BillProvider p) {
        return new BillProviderDTO(p.getProviderId(), p.getBillerName(), p.getCategoryCode(), p.getLogoUrl(), p.getFetchRequirement());
    }

    private TransactionDTO toTransactionDTO(Transaction t) {
        return new TransactionDTO(
                t.getTransactionId(), t.getTypeCode(), t.getAmount(), t.getCurrencyCode(), t.getStatus(),
                t.getGateway(), t.getReference(), t.getCounterpartyName(), t.getCounterpartyIdentifier(),
                t.getDescription(), t.getCreatedAt());
    }
}