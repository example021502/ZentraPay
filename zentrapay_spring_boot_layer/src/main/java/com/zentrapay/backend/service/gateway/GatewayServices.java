package com.zentrapay.backend.service.gateway;

import com.zentrapay.backend.entity.GatewayCustomerModel;
import com.zentrapay.backend.entity.GatewayModel;
import com.zentrapay.backend.entity.GatewayRecipientsModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.GatewayCountriesRepository;
import com.zentrapay.backend.repository.GatewayCustomerRepository;
import com.zentrapay.backend.repository.GatewayRecipientsRepository;
import com.zentrapay.backend.repository.GatewayRepository;
import com.zentrapay.backend.service.common.Datatypes;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * The gateway "brain": decides WHICH gateways a payment may use and keeps our
 * gateway customers and recipients in sync with them.
 *
 * <p><b>Routing</b> (primary first, then the failover):
 * <ul>
 *   <li>national payments      : Paystack (primary) -> Flutterwave (secondary), narrowed to the gateways that
 *       serve the user's country when the gateway directory lists them</li>
 *   <li>cross-border payments  : Onafriq only</li>
 * </ul>
 *
 * <p><b>Customer / recipient rule</b>: a recipient is always created on the SAME
 * gateway as the customer it belongs to. So the flow for one gateway is always:
 * <pre>
 *   getOrCreateCustomer(user, gateway)  ->  getOrCreateRecipient(customer, destination)
 * </pre>
 * Both are cached in {@code gateway_customers} / {@code gateway_recipients}, so the
 * gateway is only called the first time a user or a destination is seen.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GatewayServices {

    private final GatewayRepository gatewayRepository;
    private final GatewayCountriesRepository gatewayCountriesRepository;
    private final GatewayCustomerRepository gatewayCustomerRepository;
    private final GatewayRecipientsRepository gatewayRecipientsRepository;
    private final PaystackServices paystackServices;
    private final FlutterwaveServices flutterwaveServices;
    private final OnafriqServices onafriqServices;

    /**
     * Where the money is going: a bank account or mobile-money wallet, in one country and currency.
     */
    public record Destination(String checkoutType, String countryCode, String currencyCode,
                              String channelCode, String accountNumber, String accountName) {
    }

    // ------------------------------------------------------------------
    // Routing
    // ------------------------------------------------------------------

    /**
     * The gateways to try for a payment, the best first. Gateways that are not seeded
     * or are switched off are skipped.
     *
     * @param crossBorder true when sender and receiver are in different countries
     */
    public List<GatewayModel> gatewaysFor(boolean crossBorder) {
        return gatewaysFor(crossBorder, null);
    }

    /**
     * Same, narrowed to the gateways that serve {@code countryCode} (the nation of the user / payee).
     * Domestic: Paystack first, Flutterwave second - but a gateway the directory says does not operate in
     * that country is left out, so e.g. a country only Flutterwave serves goes straight to Flutterwave.
     * When the directory has no gateway list for the country the standard order is used as it is.
     * Cross-border: Onafriq only.
     */
    public List<GatewayModel> gatewaysFor(boolean crossBorder, String countryCode) {
        List<Datatypes.PaymentGateway> order = crossBorder
                ? List.of(Datatypes.PaymentGateway.ONAFRIQ)
                : List.of(Datatypes.PaymentGateway.PAYSTACK, Datatypes.PaymentGateway.FLUTTERWAVE);

        if (!crossBorder && countryCode != null && !countryCode.isBlank()) {
            java.util.Set<String> serving = gatewayCountriesRepository.findFirstByCountryCode(countryCode.trim().toUpperCase())
                    .map(c -> c.getGateways() == null ? "" : c.getGateways())
                    .map(list -> java.util.Arrays.stream(list.split(","))
                            .map(g -> g.trim().toUpperCase()).filter(g -> !g.isEmpty())
                            .collect(java.util.stream.Collectors.toSet()))
                    .orElse(java.util.Set.of());
            if (!serving.isEmpty()) {
                List<Datatypes.PaymentGateway> narrowed = order.stream().filter(g -> serving.contains(g.name())).toList();
                if (!narrowed.isEmpty()) {
                    order = narrowed;
                }
            }
        }

        List<GatewayModel> gateways = new ArrayList<>();
        for (Datatypes.PaymentGateway name : order) {
            gatewayRepository.findByProviderNameIgnoreCase(name.name())
                    .filter(GatewayModel::getActive)
                    .ifPresent(gateways::add);
        }
        if (gateways.isEmpty()) {
            throw new PaymentGatewayException("No payment gateway is available right now, please try again later");
        }
        return gateways;
    }

    /**
     * The gateway enum for a gateway row.
     */
    public Datatypes.PaymentGateway nameOf(GatewayModel gateway) {
        return Datatypes.PaymentGateway.valueOf(gateway.getProviderName().toUpperCase());
    }

    /**
     * The gateway row for a gateway name.
     */
    public GatewayModel gatewayByName(Datatypes.PaymentGateway name) {
        return gatewayRepository.findByProviderNameIgnoreCase(name.name())
                .filter(GatewayModel::getActive)
                .orElseThrow(() -> new PaymentGatewayException(name + " is not available right now"));
    }

    /**
     * The gateway row for a gateway id.
     */
    public GatewayModel gatewayById(UUID gatewayId) {
        return gatewayRepository.findById(gatewayId)
                .orElseThrow(() -> new ResourceNotFoundException("Gateway not found"));
    }

    // ------------------------------------------------------------------
    // Customers
    // ------------------------------------------------------------------

    /**
     * Returns the user's customer on this gateway, creating it on the gateway
     * the first time. (No DB transaction is held open during the gateway call.)
     */
    public GatewayCustomerModel getOrCreateCustomer(UserModel user, GatewayModel gateway) {
        return gatewayCustomerRepository.findByUserIdAndGatewayId(user.getUserId(), gateway.getProviderId())
                .orElseGet(() -> createCustomer(user, gateway));
    }

    private GatewayCustomerModel createCustomer(UserModel user, GatewayModel gateway) {
        log.info("Creating {} customer for user {}", gateway.getProviderName(), user.getUserId());

        String customerCode = switch (nameOf(gateway)) {
            case PAYSTACK ->
                    paystackServices.createCustomer(user.getEmail(), user.getFirstName(), user.getLastName(), user.getPhoneNumber());
            case FLUTTERWAVE ->
                    flutterwaveServices.createCustomer(user.getEmail(), user.getFirstName(), user.getLastName(), user.getPhoneNumber());
            case ONAFRIQ ->
                    onafriqServices.createCustomer(user.getEmail(), user.getFirstName(), user.getLastName(), user.getPhoneNumber());
        };

        GatewayCustomerModel customer = new GatewayCustomerModel();
        customer.setUserId(user.getUserId());
        customer.setGatewayId(gateway.getProviderId());
        customer.setEmail(user.getEmail());
        customer.setGatewayCustomerId(customerCode);
        try {
            return gatewayCustomerRepository.save(customer);
        } catch (DataIntegrityViolationException e) {
            // Two requests created the same customer at once - use the one that won
            return gatewayCustomerRepository.findByUserIdAndGatewayId(user.getUserId(), gateway.getProviderId())
                    .orElseThrow(() -> e);
        }
    }

    // ------------------------------------------------------------------
    // Recipients
    // ------------------------------------------------------------------

    /**
     * Returns the recipient for this destination on the customer's gateway, creating
     * it on that gateway the first time. The recipient is always linked to the
     * given customer, so customer and recipient can never be on different gateways.
     */
    public GatewayRecipientsModel getOrCreateRecipient(GatewayCustomerModel customer, Destination destination) {
        return gatewayRecipientsRepository
                .findByUserIdAndGatewayIdAndCheckoutTypeAndChannelCodeAndAccountIdentifier(
                        customer.getUserId(), customer.getGatewayId(), destination.checkoutType(),
                        destination.channelCode(), destination.accountNumber())
                .orElseGet(() -> createRecipient(customer, destination));
    }

    private GatewayRecipientsModel createRecipient(GatewayCustomerModel customer, Destination d) {
        GatewayModel gateway = gatewayById(customer.getGatewayId());
        log.info("Creating {} recipient {} / {} for user {}", gateway.getProviderName(), d.channelCode(), com.zentrapay.backend.service.payment.DestinationTokenService.mask(d.accountNumber()), customer.getUserId());

        String recipientCode = switch (nameOf(gateway)) {
            case PAYSTACK ->
                    paystackServices.createRecipient(d.checkoutType(), d.countryCode(), d.accountName(), d.accountNumber(), d.channelCode(), d.currencyCode());
            case FLUTTERWAVE ->
                    flutterwaveServices.createBeneficiary(d.accountName(), d.accountNumber(), d.channelCode());
            case ONAFRIQ ->
                    onafriqServices.createRecipient(d.checkoutType(), d.countryCode(), d.accountName(), d.accountNumber(), d.channelCode(), d.currencyCode());
        };

        GatewayRecipientsModel recipient = new GatewayRecipientsModel();
        recipient.setUserId(customer.getUserId());
        recipient.setGatewayId(customer.getGatewayId());
        recipient.setCustomerId(customer.getId());
        recipient.setCheckoutType(d.checkoutType());
        recipient.setChannelCode(d.channelCode());
        recipient.setAccountIdentifier(d.accountNumber());
        recipient.setAccountName(d.accountName());
        recipient.setGatewayRecipientCode(recipientCode);
        try {
            return gatewayRecipientsRepository.save(recipient);
        } catch (DataIntegrityViolationException e) {
            return gatewayRecipientsRepository
                    .findByUserIdAndGatewayIdAndCheckoutTypeAndChannelCodeAndAccountIdentifier(
                            customer.getUserId(), customer.getGatewayId(), d.checkoutType(), d.channelCode(), d.accountNumber())
                    .orElseThrow(() -> e);
        }
    }
}
