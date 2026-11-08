package com.zentrapay.backend.service.provider;

import com.zentrapay.backend.dto.provider.UserServiceDTO;
import com.zentrapay.backend.entity.BillProviderModel;
import com.zentrapay.backend.entity.ServiceProviderModel;
import com.zentrapay.backend.entity.UserServiceModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.BillProviderRepository;
import com.zentrapay.backend.repository.ServiceProvidersRepository;
import com.zentrapay.backend.repository.UserServiceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * The services a user added to their Home screen with the "New" button ({@code user_services}). Home shows
 * only these - never the whole provider directory.
 */
@Service
@RequiredArgsConstructor
public class UserServicesService {

    private final UserServiceRepository userServiceRepository;
    private final BillProviderRepository billProviderRepository;
    private final ServiceProvidersRepository serviceProvidersRepository;

    /** The user's services, oldest first. A provider that was since removed from its directory is skipped. */
    @Transactional(readOnly = true)
    public List<UserServiceDTO> list(UUID userId) {
        List<UserServiceModel> rows = userServiceRepository.findByUserIdOrderByCreatedAtAsc(userId);
        Map<UUID, BillProviderModel> bills = billProviderRepository.findAllById(idsOf(rows, UserServiceModel.BILL)).stream()
                .collect(Collectors.toMap(BillProviderModel::getProviderId, Function.identity()));
        Map<UUID, ServiceProviderModel> services = serviceProvidersRepository.findAllById(idsOf(rows, UserServiceModel.SERVICE)).stream()
                .collect(Collectors.toMap(ServiceProviderModel::getProviderId, Function.identity()));

        List<UserServiceDTO> result = new ArrayList<>();
        for (UserServiceModel row : rows) {
            if (UserServiceModel.BILL.equals(row.getServiceKind())) {
                BillProviderModel p = bills.get(row.getProviderId());
                if (p != null && Boolean.TRUE.equals(p.getActive())) {
                    result.add(dto(row, p.getBillerName(), p.getLogoUrl(), p.getCategoryCode(), p.getCountryCode()));
                }
            } else {
                ServiceProviderModel p = services.get(row.getProviderId());
                if (p != null && p.isActive()) {
                    result.add(dto(row, p.getProviderName(), p.getLogoUrl(), p.getCategoryCode(), p.getCountryCode()));
                }
            }
        }
        return result;
    }

    /** Adds a provider to the user's Home screen. Adding the same one again changes nothing. */
    @Transactional
    public UserServiceDTO add(UUID userId, String kindText, UUID providerId) {
        String kind = kindOf(kindText);
        String name;
        String logo;
        String category;
        String country;
        if (UserServiceModel.BILL.equals(kind)) {
            BillProviderModel p = billProviderRepository.findById(providerId)
                    .filter(b -> Boolean.TRUE.equals(b.getActive()))
                    .orElseThrow(() -> new ResourceNotFoundException("This bill provider is not available"));
            name = p.getBillerName();
            logo = p.getLogoUrl();
            category = p.getCategoryCode();
            country = p.getCountryCode();
        } else {
            ServiceProviderModel p = serviceProvidersRepository.findById(providerId)
                    .filter(ServiceProviderModel::isActive)
                    .orElseThrow(() -> new ResourceNotFoundException("This service provider is not available"));
            name = p.getProviderName();
            logo = p.getLogoUrl();
            category = p.getCategoryCode();
            country = p.getCountryCode();
        }
        UserServiceModel row = userServiceRepository.findByUserIdAndServiceKindAndProviderId(userId, kind, providerId)
                .orElseGet(() -> {
                    UserServiceModel created = new UserServiceModel();
                    created.setUserId(userId);
                    created.setServiceKind(kind);
                    created.setProviderId(providerId);
                    return userServiceRepository.saveAndFlush(created);
                });
        return dto(row, name, logo, category, country);
    }

    /** Removes a provider from the user's Home screen (nothing happens if it was not there). */
    @Transactional
    public void remove(UUID userId, String kindText, UUID providerId) {
        userServiceRepository.findByUserIdAndServiceKindAndProviderId(userId, kindOf(kindText), providerId)
                .ifPresent(userServiceRepository::delete);
    }

    private static String kindOf(String text) {
        String kind = text == null ? "" : text.trim().toUpperCase();
        if (!UserServiceModel.BILL.equals(kind) && !UserServiceModel.SERVICE.equals(kind)) {
            throw new IllegalArgumentException("Kind must be BILL or SERVICE");
        }
        return kind;
    }

    private static List<UUID> idsOf(List<UserServiceModel> rows, String kind) {
        return rows.stream().filter(r -> kind.equals(r.getServiceKind())).map(UserServiceModel::getProviderId).toList();
    }

    private static UserServiceDTO dto(UserServiceModel row, String name, String logo, String category, String country) {
        return new UserServiceDTO(row.getUserServiceId(), row.getServiceKind(), row.getProviderId(), name, logo, category, country,
                row.getCreatedAt() == null ? null : row.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant());
    }
}
