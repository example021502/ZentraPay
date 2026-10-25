# Privy Flutter SDK

The **Privy Flutter SDK** is a Flutter plugin that connects your application to native **Privy SDKs** for **iOS and Android**. It enables **authentication, non-custodial embedded wallets**, and **user management** by leveraging Privy's platform-specific capabilities.

## Features

### Authentication
- Login with Phone
- Login with Email
- Login with Passkey
- Login with Custom Auth
- Login with OAuth (Google, Apple, Twitter, Discord)
- Login with SIWE (Sign-In with Ethereum)
- Login with SIWS (Sign-In with Solana)

### **Embedded Wallets (Ethereum & Solana)**
- Wallet Creation
- Automatic Recovery
- Signing Messages & Transactions

#### **Ethereum-Only Features**
- Broadcasting Transactions
- Multiple Embedded Wallets



## Getting Started

### Requirements
- **Flutter:** 3.24.0+
- **Dart:** 3.0.0+
- **Android:** API 27+ (8.1 Oreo or newer)
- **iOS:** 17+

### Installation
Add the latest Privy SDK dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  privy_flutter: ^0.0.1  # Replace with the latest version
```

Run:
```sh
flutter pub get
```

## Configuration

### Registering Your App
You must configure your **App ID and Client ID** in the **Privy Developer Dashboard**.

1. **iOS**: Add your app's **Bundle Identifier** under **Settings → Clients**.
2. **Android**: Add your **Application ID** from `build.gradle`.
3. Register **Allowed URL Schemes** for OAuth authentication in `Info.plist` (iOS) and `AndroidManifest.xml` (Android).

## Initialization

Import and configure Privy in your Flutter app:

```dart
import 'package:privy_flutter/privy_flutter.dart';

final privyConfig = PrivyConfig(
  appId: "YOUR_APP_ID",
  appClientId: "YOUR_CLIENT_ID",
);

final privy = Privy(config: privyConfig);
```

### Get the Current Authentication State
When the Privy SDK is initialized, the user's authentication state will be set to NotReady until Privy finishes initialization.
During this time, we suggest you show a loading state to your user. 
For you convenience, we've added a suspending getAuthState() function. Here's an example with some pseudocode:

```dart
await privy.getAuthState();
```

## Authentication

### Login with Email
Authenticate users via email-based OTP verification.

#### **Step 1: Send OTP to User’s Email**
```dart
final result = await privy.email.sendCode("user@example.com");
```
- **Success()**: OTP was sent successfully.
- **Failure(PrivyException)**: Error sending OTP.

#### **Step 2: Verify OTP and Login**
```dart
final loginResult = await privy.email.loginWithCode(code: "123456", email: "user@example.com");
```
- **Success(PrivyUser)**: User authenticated successfully.
- **Failure(PrivyException)**: Invalid OTP or authentication failed.

#### **Link Email to Existing Account**
```dart
final linkResult = await privy.email.linkWithCode(code: "123456", email: "user@example.com");
```
- **Success()**: Email linked successfully to current user.
- **Failure(PrivyException)**: Invalid OTP, user not authenticated, or linking failed.

#### **Update User's Email**
```dart
final updateResult = await privy.email.updateWithCode(code: "123456", email: "newemail@example.com");
```
- **Success()**: Email updated successfully.
- **Failure(PrivyException)**: Invalid OTP, user not authenticated, or update failed.

---

### Login with Phone
Authenticate users via SMS-based OTP verification.

#### **Step 1: Send OTP to User’s Phone Number**
```dart
final result = await privy.sms.sendCode("+14155552671");
```
- **Success()**: OTP was sent successfully.
- **Failure(PrivyException)**: Error sending OTP.

#### **Step 2: Verify OTP and Login**
```dart
final loginResult = await privy.sms.loginWithCode(code: "123456", phoneNumber: "+14155552671");
```
- **Success(PrivyUser)**: User authenticated successfully.
- **Failure(PrivyException)**: Invalid OTP or authentication failed.

#### **Link Phone Number to Existing Account**
```dart
final linkResult = await privy.sms.linkWithCode(code: "123456", phoneNumber: "+14155552671");
```
- **Success()**: Phone number linked successfully to current user.
- **Failure(PrivyException)**: Invalid OTP, user not authenticated, or linking failed.

#### **Update User's Phone Number**
```dart
final updateResult = await privy.sms.updateWithCode(code: "123456", phoneNumber: "+14155559999");
```
- **Success()**: Phone number updated successfully.
- **Failure(PrivyException)**: Invalid OTP, user not authenticated, or update failed.

---

### Login with Passkey
Authenticate users using WebAuthn passkeys for passwordless authentication.

#### **Signup with Passkey**
```dart
final signupResult = await privy.passkey.signup(
  relyingParty: "https://your-app.com",
  displayName: "Passkey Name",
);
```
- **Success(PrivyUser)**: User registered successfully with passkey.
- **Failure(PrivyException)**: Passkey creation failed or was cancelled.

#### **Login with Passkey**
```dart
final loginResult = await privy.passkey.login(
  relyingParty: "https://your-app.com",
);
```
- **Success(PrivyUser)**: User authenticated successfully.
- **Failure(PrivyException)**: Passkey authentication failed or was cancelled.

#### **Link Passkey to Existing Account**
```dart
final linkResult = await privy.passkey.link(
  relyingParty: "https://your-app.com",
  displayName: "My Passkey",
);
```
- **Success()**: Passkey linked successfully to current user.
- **Failure(PrivyException)**: User not authenticated, passkey creation failed, or linking failed.

#### **Unlink Passkey from Account**
```dart
final unlinkResult = await privy.passkey.unlink(
  credentialId: "credential-id-from-passkey-account",
);
```
- **Success()**: Passkey unlinked successfully from current user.
- **Failure(PrivyException)**: User not authenticated, credential not found, or unlinking failed.

---

### Login with Custom Auth
Authenticate users using a third-party authentication provider.

```dart
final loginResult = await privy.customAuth.loginWithCustomAccessToken();
```
- **Success(PrivyUser)**: User authenticated successfully.
- **Failure(PrivyException)**: Invalid or expired token.

---

### Login with OAuth
The Flutter SDK supports OAuth login with Google, Apple, Twitter, and Discord. For all other OAuth providers, use JWT-based authentication.

#### **Platform Configuration**

**Android**: Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<activity
    android:name="io.privy.sdk.oAuth.PrivyRedirectActivity"
    android:exported="true"
    android:launchMode="singleTask"
    android:theme="@android:style/Theme.Translucent.NoTitleBar">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="YOUR_CUSTOM_PRIVY_OAUTH_SCHEME" />
    </intent-filter>
</activity>
```

**iOS**: Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>privy.oauth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_CUSTOM_PRIVY_OAUTH_SCHEME</string>
        </array>
    </dict>
</array>
```

**Note**: Apple Sign In requires iOS 13.0+ and additional configuration in Xcode (Sign in with Apple capability). It is only available on iOS, not on Android Devices.

#### **Usage**
```dart
final result = await privy.oAuth.login(
  provider: OAuthProvider.google,  // .google, .apple, .twitter, .discord
  appUrlScheme: 'your-app-scheme',
);

result.fold(
  onSuccess: (user) => print('Login successful: ${user.id}'),
  onFailure: (error) => print('Login failed: $error'),
);
```

---

### Login with SIWE (Sign-In with Ethereum)
Authenticate users by having them sign a SIWE message with their Ethereum wallet.

#### **Step 1: Generate SIWE Message**
```dart
final params = SiweMessageParams(
  appDomain: "your-app.com",
  appUri: "https://your-app.com",
  chainId: "1", // Ethereum mainnet
  walletAddress: "0x...", // User's wallet address
);

final messageResult = await privy.siwe.generateMessage(params);
```

#### **Step 2: Have User Sign Message & Login**
```dart
// User signs the message with their wallet (outside of Privy)
final signature = "0x..."; // Signature from user's wallet

final loginResult = await privy.siwe.login(
  message: message,
  signature: signature,
  params: params,
  metadata: WalletLoginMetadata(
    walletClientType: WalletClientType.metamask,
    connectorType: "wallet_connect",
  ),
);
```
- **Success(PrivyUser)**: User authenticated successfully.
- **Failure(PrivyException)**: Invalid signature or authentication failed.

#### **Link Ethereum Wallet to Existing Account**
```dart
final linkResult = await privy.siwe.link(
  message: message,
  signature: signature,
  params: params,
);
```
- **Success()**: Ethereum wallet linked successfully to current user.
- **Failure(PrivyException)**: Invalid signature, user not authenticated, or linking failed.

---

### Login with SIWS (Sign-In with Solana)
Authenticate users by having them sign a SIWS message with their Solana wallet.

#### **Step 1: Generate SIWS Message**
```dart
final params = SiwsMessageParams(
  appDomain: "your-app.com",
  appUri: "https://your-app.com",
  walletAddress: "...", // User's Solana wallet address
);

final messageResult = await privy.siws.generateMessage(params);
```

#### **Step 2: Have User Sign Message & Login**
```dart
// User signs the message with their Solana wallet (outside of Privy)
final signature = "..."; // Signature from user's wallet

final loginResult = await privy.siws.login(
  message: message,
  signature: signature,
  params: params,
  metadata: WalletLoginMetadata(
    walletClientType: WalletClientType.phantom,
    connectorType: "wallet_connect",
  ),
);
```
- **Success(PrivyUser)**: User authenticated successfully.
- **Failure(PrivyException)**: Invalid signature or authentication failed.

#### **Link Solana Wallet to Existing Account**
```dart
final linkResult = await privy.siws.link(
  message: message,
  signature: signature,
  params: params,
);
```
- **Success()**: Solana wallet linked successfully to current user.
- **Failure(PrivyException)**: Invalid signature, user not authenticated, or linking failed.

#### **Unlink Solana Wallet from Account**
```dart
final unlinkResult = await privy.siws.unlink(
  address: "solana-wallet-address",
);
```
- **Success()**: Solana wallet unlinked successfully from current user.
- **Failure(PrivyException)**: User not authenticated, wallet not found, or unlinking failed.

---

### Get Access Token
Retrieve the user's authentication token for API requests.

```dart
final user = await privy.getUser();
final getAccessTokenResult = await user?.getAccessToken();
```
- **Success(String)**: Token retrieved successfully.
- **Failure(PrivyException)**: User not authenticated or error occurred.

---

### Refresh User Data
Manually refresh the user data to ensure you have the latest information.

```dart
final user = await privy.getUser();
final refreshResult = await user?.refresh();
```
- **Success(void)**: User data refreshed successfully.
- **Failure(PrivyException)**: Error occurred while refreshing user data.

---

## Embedded Wallets

### Create an Ethereum Wallet
Creates a non-custodial Ethereum embedded wallet for the user.

```dart
final user = await privy.getUser();
final walletResult = await user?.createEthereumWallet();
```
- **Success(EmbeddedEthereumWallet)**: Wallet created successfully.
- **Failure(PrivyException)**: User not authenticated, network error, or wallet limit exceeded.

---

### Create a Solana Wallet
Creates a non-custodial Solana embedded wallet for the user. You can create multiple wallets by setting `createAdditional` to true.

```dart
final user = await privy.getUser();
// Create initial wallet
final walletResult = await user?.createSolanaWallet();

// Create additional wallet
final additionalWalletResult = await user?.createSolanaWallet(createAdditional: true);
```
- **Success(EmbeddedSolanaWallet)**: Wallet created successfully.
- **Failure(PrivyException)**: User not authenticated or network error.

---

### Sign a Message (Solana)
Sign a message using the user’s Solana embedded wallet.

```dart
final user = await privy.getUser();
final signature = await user?.embeddedSolanaWallets.first.provider.signMessage("message");
```
- **Success(String)**: Signature generated successfully.
- **Failure(PrivyException)**: User not authenticated or wallet not found.

---

## Logout
Logs the user out and clears the persisted session.

```dart
await privy.logout();
```
- **Success()**: User logged out successfully.
- **Failure(PrivyException)**: Error during logout.

---

## Error Handling

All SDK responses use `Result<T>`. Handle success or failure using either `.fold()` or a `switch` statement.

### **Using `.fold()`**
The `.fold()` method allows you to execute separate callbacks for success and failure.

```dart
result.fold(
  onSuccess: (user) => print("Success: ${user.id}"),
  onFailure: (error) => print("Error: ${error.message}"),
);
```

---

### **Using a `switch` Statement**
Alternatively, you can use a `switch` statement to handle success and failure.

```dart
switch (result) {
  case Success(:final user): // Extracts `user` from Success<T>
    print("Success: ${user.id}");
    break;
  
  case Failure(:final error): // Extracts `error` from Failure<T>
    print("Error: ${error.message}");
    break;
}
```


## License
This project is licensed under the **MIT License**.

---

For more details, visit the **[Privy Developer Dashboard](https://dashboard.privy.io)**.



