// Exporting the main entry point for the Privy SDK.
export 'src/privy.dart';

// Exporting the configuration model for Privy,
// which contains required parameters such as appId and appClientId.
export 'src/models/privy_config/privy_config.model.dart';

// Exporting the logging level enumeration,
// which allows developers to set different log levels for debugging.
export 'src/logging/privy_log_level_enum.dart';

// Exporting the authentication state model,
// which represents different authentication states such as NotReady, Unauthenticated, and Authenticated.
export 'src/models/auth_state/auth_state.dart';

// Exporting the user model,
// which represents the authenticated user's details.
export 'src/modules/privy_user/privy_user.dart';

export 'src/models/linked_accounts/linked_accounts.dart';

// Export the Result type to developer for error handling
export 'src/utils/result.dart';

// Export the custom authentication configuration model
export 'src/models/login_with_custom_auth_config/login_with_custom_auth_config.dart';

// Export the base embedded wallet model
export 'src/models/embedded_wallet/embedded_wallet.dart';

// Export the embedded Ethereum wallet model
export 'src/models/embedded_ethereum_wallet/embedded_ethereum_wallet.dart';

// Export the embedded Solana wallet model
export 'src/models/embedded_solana_wallet/embedded_solana_wallet.dart';

// Export the Ethereum RPC Request model
export 'src/models/ethereum_rpc_request/ethereum_rpc_request.dart';

// Export the Ethereum RPC Response model
export 'src/models/ethereum_rpc_response/ethereum_rpc_response.dart';

// Export the embedded Privy Exception wallet model
export 'src/errors/privy_exception.dart';

// Export typed MFA exceptions
export 'src/errors/mfa_exception.dart';

// Export the OAuth provider enum
export 'src/models/oauth_provider/oauth_provider.dart';

// Export the SIWE message parameters model
export 'src/models/siwe_message_params/siwe_message_params.dart';

// Export the SIWS message parameters model
export 'src/models/siws_message_params/siws_message_params.dart';

// Export the wallet login metadata model
export 'src/models/wallet_login_metadata/wallet_login_metadata.dart';

// Export the wallet client type enum
export 'src/models/wallet_client_type/wallet_client_type.dart';

// Export the Solana cluster enum
export 'src/enums/solana_cluster.dart';

// Export the send options model for Solana transactions
export 'src/models/send_options/send_options.dart';

// Export the wallet API payload model for authorization signatures
export 'src/models/wallet_api_payload/wallet_api_payload.dart';

// Export the signer input model for adding signers to wallets
export 'src/models/signer_input/signer_input.dart';

// Export the MFA configuration
export 'src/modules/mfa/mfa_config.dart';

// Export the MFA listener interface
export 'src/modules/mfa/mfa_listener.dart';
// Export MFA method enum (TOTP, SMS, Passkey) for inspecting user.mfaMethods
export 'src/modules/mfa/mfa_method.dart';
// Export PrivyMfa interface for privy.mfa access (setConfig, resumeBlockedActions)
export 'src/modules/mfa/privy_mfa.dart';

// Export TOTP secret model for MFA TOTP enrollment
export 'src/modules/mfa/totp/totp_secret.dart';
