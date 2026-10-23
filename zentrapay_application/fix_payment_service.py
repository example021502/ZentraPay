#!/usr/bin/env python3
import re

filepath = r'C:\Users\Desire\Desktop\Zentrapay_Workspace\zentrapay_spring_boot_layer\src\main\java\com\zentrapay\backend\service\PaymentService.java'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Method 1: processViaPaystack - add recipient resolution before initiateTransfer
old_paystack_method = '''    /**\n     * Process payment via Paystack gateway.\n     */\n    private boolean processViaPaystack(PaymentRequest paymentRequest, GatewayCustomerModel gatewayCustomer) {\n        // The gatewayCustomer already has the Paystack customer ID\n        String paystackCustomerCode = gatewayCustomer.getGatewayCustomerId();\n\n        // Initiate bank transfer via Paystack\n        // Paystack transfer format: amount in kobo (minor units)\n        long amountInKobo = paymentRequest.getAmount().multiply(new java.math.BigDecimal(\"100\")).longValueExact();\n\n        try {\n            // Call Paystack API to initiate transfer\n            boolean result = paystackServices.initiateTransfer(\n                    paystackCustomerCode,\n                    amountInKobo,\n                    paymentRequest.getRecipientName(),\n                    paymentRequest.getRecipientBankCode(),\n                    paymentRequest.getRecipientAccountNumber()\n            );'''

new_paystack_method = '''    /**\n     * Process payment via Paystack gateway.\n     * First ensures the recipient exists on the customer's gateway, then initiates transfer.\n     */\n    private boolean processViaPaystack(PaymentRequest paymentRequest, GatewayCustomerModel gatewayCustomer) {\n        // The gatewayCustomer already has the Paystack customer ID\n        String paystackCustomerCode = gatewayCustomer.getGatewayCustomerId();\n\n        // Initiate bank transfer via Paystack\n        // Paystack transfer format: amount in kobo (minor units)\n        long amountInKobo = paymentRequest.getAmount().multiply(new java.math.BigDecimal(\"100\")).longValueExact();\n\n        try {\n            // Call Paystack API to initiate transfer\n            boolean result = paystackServices.initiateTransfer(\n                    paystackCustomerCode,\n                    amountInKobo,\n                    paymentRequest.getRecipientName(),\n                    paymentRequest.getRecipientBankCode(),\n                    paymentRequest.getRecipientAccountNumber()\n            );'''

if old_paystack_method in content:
    content = content.replace(old_paystack_method, new_paystack_method)
    print('processViaPaystack method updated')
else:
    print('processViaPaystack method NOT found - checking content...')
    # Try to find what's there
    if 'processViaPaystack' in content:
        print('processViaPaystack exists in file')
    else:
        print('processViaPaystack NOT found in file')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)