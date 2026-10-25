# Changelog

## Unreleased

## [0.10.1]

### **Added**
- **Wallet Migration:** Added `Future<Result<void>> user.migrateWalletsIfNeeded()` for manually triggering TEE wallet migration when `disableAutomaticMigration` is enabled in `PrivyConfig`.

### **Fixed**
- Handle null user in session-refresh responses so a revoked session logs the user out cleanly

## [0.10.0]

### **Fixed**
- **User Refresh:** `PrivyUser.refresh()` now calls the native SDK's `refresh()` method instead of `getUser()`, ensuring server-side changes are fetched.

## [0.9.0]

### **Fixed**
- **Logout:** `privy.logout()` now succeeds silently when the user is already logged out on the native side, instead of erroring.

### **Added**
- **OAuth Linking & Unlinking (`privy.oAuth`):**
  - Added `Future<Result<PrivyUser>> privy.oAuth.link({required OAuthProvider provider, required String appUrlScheme})` for linking an OAuth provider to the currently authenticated user
  - Added `Future<Result<PrivyUser>> privy.oAuth.unlink({required OAuthProvider provider, required String subject})` for unlinking an OAuth provider from the currently authenticated user
- **MFA - SMS (`user.mfa.sms`):**
  - Added `Future<Result<void>> user.mfa.sms.enroll.sendCode(String phoneNumber)` for sending an SMS enrollment verification code
  - Added `Future<Result<PrivyUser>> user.mfa.sms.enroll.submit({required String code, required String phoneNumber})` for completing SMS MFA enrollment
  - Added `Future<Result<void>> user.mfa.sms.verify.sendCode()` for sending an SMS verification code during an MFA challenge
  - Added `Future<Result<void>> user.mfa.sms.verify.submit(String code)` for submitting an SMS OTP during an MFA challenge
  - Added `Future<Result<PrivyUser>> user.mfa.sms.unenroll()` for removing SMS as an MFA method
- **MFA - TOTP (`user.mfa.totp`):**
  - Added `Future<Result<TotpSecret>> user.mfa.totp.enroll.generateSecret()` for generating a TOTP secret during enrollment
  - Added `Future<Result<PrivyUser>> user.mfa.totp.enroll.submit(String code)` for completing TOTP MFA enrollment
  - Added `Future<Result<void>> user.mfa.totp.verify.submit(String code)` for submitting a TOTP code during an MFA challenge
  - Added `Future<Result<PrivyUser>> user.mfa.totp.unenroll()` for removing TOTP as an MFA method
  - Added `TotpSecret` model with `secret` and `authUrl` fields
- **MFA - Passkeys (`user.mfa.passkeys`):**
  - Added `Future<Result<PrivyUser>> user.mfa.passkeys.enroll.submit(List<String> credentialIds)` for enrolling passkey MFA
  - Added `Future<Result<void>> user.mfa.passkeys.verify.submit(String relyingParty)` for verifying passkey MFA using biometric authentication
  - Added `Future<Result<PrivyUser>> user.mfa.passkeys.unenroll({bool removeForLogin = true})` for unenrolling passkey MFA with option to keep or remove the passkey as a login method
- **Global MFA Management (`privy.mfa`):**
  - Added `Future<Result<void>> privy.mfa.setConfig(MfaConfig config)` for configuring MFA listener and timeout after SDK initialization
  - Added `Future<Result<void>> privy.mfa.resumeBlockedActions([Exception? mfaError])` for resuming or cancelling suspended MFA-protected operations
  - Added `MfaConfig` with `MfaListener listener` and `Duration timeout` (default 5 minutes) for configuring MFA behavior
  - Added `MfaListener` interface with `onMfaRequired(PrivyUser user)` callback for handling MFA verification requirements
  - Added `MfaMethod` sealed class with `MfaMethodSms`, `MfaMethodTotp`, and `MfaMethodPasskey` subtypes
- **MFA Error Handling:**
  - Added `MfaException` sealed class with typed subtypes: `MfaMissingOrInvalidException`, `MfaChallengeExpiredException`, `MfaMaxAttemptsReachedException`, and `MfaSdkTimeoutException`

## [0.8.0]

### **Added**
- **Authorization Signature:**
  - Added `generateAuthorizationSignatureFromBytes(Uint8List payload)` to `PrivyUser` for generating cryptographic signatures over pre-serialized binary payloads using the user's signer key
- **Telegram Oauth**
  - Added `OauthProvider.telegram` to suopport Telegram authentication support via OAuth flow

## [0.7.0]

### **Added**
- **Authorization Signature:**
  - Added `generateAuthorizationSignature(WalletApiPayload payload)` to `PrivyUser` for generating cryptographic signatures over wallet API requests using the user's signer key
- **Add Signers:**
  - Added `addSigners(List<SignerInput> signers)` to `EmbeddedWallet` for adding key quorum signers to TEE-based embedded wallets
  - Added `addSigner(SignerInput signer)` convenience method for adding a single signer
  - Added `SignerInput` model with `signerId` and optional `policyIds` fields
- **Remove Signers:**
  - Added `removeSigner(String signerId)` to `EmbeddedWallet` for removing a specific signer by key quorum ID
  - Added `removeAllSigners()` to `EmbeddedWallet` for removing all additional signers from a wallet

## [0.6.0]

### **Added**
- **Email Unlink:**
  - Added `Future<Result<PrivyUser>> privy.email.unlink(email)` for unlinking email addresses from user accounts
- **SMS Unlink:**
  - Added `Future<Result<PrivyUser>> privy.sms.unlink(phoneNumber)` for unlinking phone numbers from user accounts

### **Changed**
- **Unlink methods now return the updated user:**
  - Account unlinking methods now return `Result<PrivyUser>` instead of `Result<void>`, providing immediate access to the updated user object after unlinking
  - **SIWE:** `privy.siwe.unlink(address)` now returns `Result<PrivyUser>`
  - **SIWS:** `privy.siws.unlink(address)` now returns `Result<PrivyUser>`
  - **Passkey:** `privy.passkey.unlink(credentialId)` now returns `Result<PrivyUser>`
- **Link methods now return the updated user:**
  - All account linking methods now return `Result<PrivyUser>` instead of `Result<void>`, providing immediate access to the updated user object after linking
  - **Email:** `privy.email.linkWithCode()` now returns `Result<PrivyUser>`
  - **SMS:** `privy.sms.linkWithCode()` now returns `Result<PrivyUser>`
  - **SIWE:** `privy.siwe.link()` now returns `Result<PrivyUser>`
  - **SIWS:** `privy.siws.link()` now returns `Result<PrivyUser>`
  - **Passkey:** `privy.passkey.link()` now returns `Result<PrivyUser>`


## [0.5.0]

### **Changed**
- **iOS Platform Requirements:**
  - Minimum iOS version bumped to 17.0 to support latest PrivySDK

### **Added**
- **Passkey Authentication:**
  - Added `privy.passkey.signup(relyingParty, displayName)` for passkey registration with WebAuthn
  - Added `privy.passkey.login(relyingParty)` for passkey authentication
  - Added `privy.passkey.link(relyingParty, displayName)` for linking passkeys to existing authenticated users
  - Added `privy.passkey.unlink(credentialId)` for unlinking passkeys from user accounts
- **SIWS Authentication:**
  - Added Sign-In with Solana (SIWS) support
  - Added `privy.siws.generateMessage(params)` method to create SIWS messages for Solana wallet signing
  - Added `privy.siws.login(message, signature, params, metadata)` method for authenticating users with SIWS signatures
  - Added `privy.siws.link(message, signature, params, metadata)` method for linking Solana wallets to authenticated users
  - Added `privy.siws.unlink(address)` method for unlinking Solana wallets from user accounts
- **Solana Transaction Support:**
  - Added `embeddedSolanaWallet.signTransaction(transaction)` for Solana transaction signing
  - Added `embeddedSolanaWallet.signAndSendTransaction(transaction)` for signing and broadcasting Solana transactions

### **Deprecated**
- **SIWE method names updated for consistency and brevity:**
  - `privy.siwe.generateSiweMessage()` → Use `privy.siwe.generateMessage()` instead
  - `privy.siwe.loginWithSiwe()` → Use `privy.siwe.login()` instead
  - `privy.siwe.linkWithSiwe()` → Use `privy.siwe.link()` instead
  - `privy.siwe.unlinkWallet()` → Use `privy.siwe.unlink()` instead

## [0.4.0]

### **Added**
- **Email Authentication:**
  - Added `updateWithCode` method to update user email addresses with OTP verification
- **SMS Authentication:**
  - Added `linkWithCode` method to link phone numbers to existing user accounts
  - Added `updateWithCode` method to update user phone numbers with OTP verification
- **Ethereum RPC Request Methods:**
  - Added `EthereumRpcRequest.personalSign(String message, String address)` for personal message signing
  - Added `EthereumRpcRequest.secp256k1Sign(String hash)` for secp256k1 signature generation
  - Added `EthereumRpcRequest.ethSign(String address, String message)` for Ethereum message signing
  - Added `EthereumRpcRequest.ethSignTypedDataV4(String address, String typedDataJson)` for EIP-712 typed data signing
  - Added `EthereumRpcRequest.ethSignTransaction(String transactionJson)` for transaction signing
  - Added `EthereumRpcRequest.ethSendTransaction(String transactionJson)` for direct transaction sending

## [0.3.0]

### **Added**
- **SIWE Authentication:**
  - Added Sign-In with Ethereum (SIWE) support for iOS and Android
  - Added `generateSiweMessage` method to create SIWE messages for wallet signing
  - Added `loginWithSiwe` method for authenticating users with SIWE signatures

## [0.2.0]

### **Added**
- **secp256k1_sign Support:**
  - Added support for `secp256k1_sign` RPC method in Ethereum wallet provider
  - Added secp256k1 signing functionality to example app wallet screen
- **privy.getUser() Method**
  - `Future<PrivyUser?> getUser()` - awaits ready under the hood, then returns user if authenticated

### **Deprecated**
- **eth_sendRawTransaction:**
  - `eth_sendRawTransaction` RPC method is deprecated and has been removed in this version.
  - Use `eth_sendTransaction` instead for sending transactions
- **Privy.user**
  - `Privy.user` - Devs should use `Future<PrivyUser?> getUser()` instead.

## [0.1.0] 

### **Added**
- **OAuth Authentication:**
  - Added Google OAuth login support for iOS and Android
  - Added Apple Sign In support for iOS (requires iOS 13.0+)
  - Added Twitter OAuth login support for iOS and Android
  - Added Discord OAuth login support for iOS and Android
  - OAuth redirect handling via custom URL schemes
- **getAuthState Method:**
  - Added `getAuthState` method to retrieve the current authentication state

### **Deprecated**
- `suspend fun awaitReady()` - Devs should use `suspend fun getAuthState(): AuthState` instead.
- `Privy.isReady`


### **Breaking Changes:**
- Email parameter is now required for `loginWithCode` method

## [0.1.0-beta.1] - Unified Wallet Support & Multiple Solana Wallets

- **Breaking Changes:**
  - Additional AuthState type: `AuthenticatedUnverified` added

### **Added**

- **Wallet Management:**
  - Full unified wallet support across platforms
  - Added `createAdditional` parameter to create multiple Solana wallets

---

## [0.0.8] - Solana Wallet Export & Ethereum Transaction Updates

### **Updated**
- **Public API:**
  - Exposed `EmbeddedSolanaWallet` object as publicly accessible.

---

## [0.0.7] - iOS SDK Update & User Refresh Function

### **Added**
- **User Management:**
  - Added `refresh` function to `PrivyUser` that allows developers to directly refresh user data.

### **Updated**
- **iOS SDK Compatibility:**
  - Updated iOS SDK version to `2.0.0-beta.5`.

---

## [0.0.6] - iOS SDK Version Update

### **Updated**
- **iOS SDK Compatibility:**
  - Updated iOS SDK version to `2.0.0-beta.5`.

---

## [0.0.5] - iOS SDK Version Update

### **Updated**
- **iOS SDK Compatibility:**
  - Updated iOS SDK version to `2.0.0-beta.4`.

---

## [0.0.4] - Flutter & iOS SDK Compatibility

### **Added**
- **Flutter SDK:**
  - Added CocoaPods support for easier iOS integration.

### **Updated**
- **iOS SDK Compatibility:**
  - Updated SDK for compatibility with iOS SDK version `2.0.0-beta.3`.

---

## [0.0.3] - Bug Fixes

### **Fixed**
- **Authentication:**
  - Fixed issue in `awaitReady` to ensure `authState` properly updates on initialization.

---

## [0.0.2] - Updates & Enhancements

### **Added**
- **Authentication:**
  - Implemented `getAccessToken` method to retrieve the user's authentication token.

### **Updated**
- **Native SDK Integration:**
  - Added support for `getAccessToken` call in native iOS & Android SDKs.
  - Refactored native code for improved maintainability and efficiency.

---

## [0.0.1] - Initial Release

### **Added**
- **Authentication:**
  - Login with Phone
  - Login with Email
  - Login with Custom Auth

- **Embedded Wallets:**
  - Wallet creation (Ethereum & Solana)
  - Automatic wallet recovery
  - Signing messages & transactions
  - Broadcasting transactions
  - Multiple wallet support

- **Platform Support:**
  - Native integration with iOS & Android SDKs
