package io.privy.privyflutter.helpers

import io.privy.auth.AuthState
import io.privy.auth.LinkedAccount
import io.privy.auth.MfaMethod
import io.privy.auth.PrivyUser
import io.privy.auth.oAuth.OAuthProvider
import io.privy.auth.siwe.SiweMessageParams
import io.privy.auth.siwe.WalletLoginMetadata
import io.privy.wallet.WalletClientType
import io.privy.wallet.ethereum.EmbeddedEthereumWallet
import io.privy.wallet.ethereum.EthereumRpcResponse
import io.privy.wallet.solana.EmbeddedSolanaWallet
import io.privy.wallet.solana.SendOptions
import io.privy.wallet.solana.SolanaCluster

/**
 * Utility function to serialize user data for sending to Flutter.
 */
fun serializeUser(user: PrivyUser): Map<String, Any?> {
    return mapOf(
        "id" to user.id,
        "linkedAccounts" to user.linkedAccounts.mapNotNull { it.serialized() },
        "mfaMethods" to user.mfaMethods.map { it.serialized() },
        "identityToken" to user.identityToken,
    )
}

private fun MfaMethod.serialized(): Map<String, Any?> {
    return when (this) {
        is MfaMethod.Sms -> mapOf(
            "type" to "sms",
            "verifiedAt" to this.verifiedAt,
        )
        is MfaMethod.Totp -> mapOf(
            "type" to "totp",
            "verifiedAt" to this.verifiedAt,
        )
        is MfaMethod.Passkey -> mapOf(
            "type" to "passkey",
            "verifiedAt" to this.verifiedAt,
        )
    }
}

/**
 * Extension function on LinkedAccount to serialize it for sending to Flutter.
 */
private fun LinkedAccount.serialized(): Map<String, Any?>? {
    return when (this) {
        is LinkedAccount.EmailAccount -> mapOf(
            "type" to "email",
            "emailAddress" to this.emailAddress,
        )
        is LinkedAccount.PhoneAccount -> mapOf(
            "type" to "phoneNumber",
            "phoneNumber" to this.phoneNumber,
        )
        is LinkedAccount.CustomAuth -> mapOf(
            "type" to "customAuth",
            "customUserId" to this.customUserId,
        )
        is LinkedAccount.EmbeddedEthereumWalletAccount -> mapOf(
            "type" to "ethereumWallet",
            "id" to this.id,
            "address" to this.address,
            "chainId" to this.chainId,
            "recoveryMethod" to this.recoveryMethod,
            "hdWalletIndex" to this.hdWalletIndex,
        )
        is LinkedAccount.EmbeddedSolanaWalletAccount -> mapOf(
            "type" to "solanaWallet",
            "id" to this.id,
            "address" to this.address,
            "chainId" to this.chainId,
            "recoveryMethod" to this.recoveryMethod,
            "hdWalletIndex" to this.hdWalletIndex,
        )
        is LinkedAccount.GoogleOAuthAccount -> mapOf(
            "type" to "google_oauth",
            "subject" to this.subject,
            "email" to this.email,
            "name" to this.name,
            "first_verified_at" to this.firstVerifiedAt,
            "latest_verified_at" to this.latestVerifiedAt,
        )
        is LinkedAccount.TwitterOAuthAccount -> mapOf(
            "type" to "twitter_oauth",
            "subject" to this.subject,
            "username" to this.username,
            "name" to this.name,
            "profile_picture_url" to this.profilePictureUrl,
            "first_verified_at" to this.firstVerifiedAt,
            "latest_verified_at" to this.latestVerifiedAt,
        )
        is LinkedAccount.DiscordOAuthAccount -> mapOf(
            "type" to "discord_oauth",
            "subject" to this.subject,
            "username" to this.username,
            "email" to this.email,
            "first_verified_at" to this.firstVerifiedAt,
            "latest_verified_at" to this.latestVerifiedAt,
        )
        is LinkedAccount.TelegramAccount -> mapOf(
            "type" to "telegram",
            "telegram_user_id" to this.telegramUserId,
            "first_name" to this.firstName,
            "last_name" to this.lastName,
            "username" to this.username,
            "photo_url" to this.photoUrl,
            "first_verified_at" to this.firstVerifiedAt,
            "latest_verified_at" to this.latestVerifiedAt,
        )
        is LinkedAccount.PasskeyAccount -> mapOf(
            "type" to "passkey",
            "credentialId" to this.credentialId,
            "authenticatorName" to this.authenticatorName,
            "createdWithBrowser" to this.createdWithBrowser,
            "createdWithOs" to this.createdWithOs,
            "createdWithDevice" to this.createdWithDevice,
            "publicKey" to this.publicKey,
            "enrolledInMfa" to this.enrolledInMfa,
            "verifiedAt" to this.verifiedAt,
            "firstVerifiedAt" to this.firstVerifiedAt,
            "latestVerifiedAt" to this.latestVerifiedAt,
        )
        is LinkedAccount.ExternalWalletAccount -> mapOf(
            "type" to "wallet",
            "address" to this.address,
            "chainType" to this.chainType.name,
            "chainId" to this.chainId?.toString(), // Convert to string for consistency
            "walletClientType" to this.walletClientType,
            "connectorType" to this.connectorType,
            "firstVerifiedAt" to this.firstVerifiedAt,
            "latestVerifiedAt" to this.latestVerifiedAt,
        )
        else -> mapOf(
            "type" to (this::class.simpleName ?: "Unknown"),
        )
    }
}

/**
 * Utility function to serialize an EmbeddedSolanaWallet for sending to Flutter.
 */
fun serializeSolanaWallet(wallet: EmbeddedSolanaWallet): Map<String, Any?> {
    return mapOf(
        "type" to "solanaWallet",
        "id" to wallet.id,
        "address" to wallet.address,
        "chainId" to wallet.chainId,
        "recoveryMethod" to wallet.recoveryMethod,
        "hdWalletIndex" to wallet.hdWalletIndex,
        "chainType" to wallet.chainType.name, // Ensuring it's sent as a string
    )
}

/**
 * Utility function to serialize an EmbeddedEthereumWallet for sending to Flutter.
 */
fun serializeEthereumWallet(wallet: EmbeddedEthereumWallet): Map<String, Any?> {
    return mapOf(
        "type" to "ethereumWallet",
        "id" to wallet.id,
        "address" to wallet.address,
        "chainId" to wallet.chainId,
        "recoveryMethod" to wallet.recoveryMethod,
        "hdWalletIndex" to wallet.hdWalletIndex,
        "chainType" to wallet.chainType.name, // Ensuring it's sent as a string
    )
}

/**
 * Utility function to serialize an `EthereumRpcResponse` for sending to Flutter.
 */
fun serializeEthereumRpcResponse(response: EthereumRpcResponse): Map<String, Any?> {
    return mapOf(
        "method" to response.method,
        "data" to response.data,
    )
}

/**
 * Serializes the AuthState object into a Map<String, Any?>.
 */
fun serializeAuthState(authState: AuthState): Map<String, Any?> {
    return when (authState) {
        is AuthState.NotReady -> mapOf("type" to "NotReady")
        is AuthState.Unauthenticated -> mapOf("type" to "Unauthenticated")
        is AuthState.AuthenticatedUnverified -> mapOf(
            "type" to "AuthenticatedUnverified",)
        is AuthState.Authenticated -> mapOf(
            "type" to "Authenticated",
            "user" to serializeUser(authState.user),
        )
        else -> mapOf("type" to "NotReady") // Fallback for unexpected or unknown states
    }
}

/**
 * Deserializes a Map received from Flutter into a SiweMessageParams object.
 */
fun deserializeSiweMessageParams(data: Map<String, Any?>): SiweMessageParams {
    return SiweMessageParams(
        walletAddress = data["walletAddress"] as String,
        appDomain = data["appDomain"] as String,
        appUri = data["appUri"] as String,
        chainId = data["chainId"] as String
    )
}

/**
 * Deserializes a Map received from Flutter into a SiwsMessageParams object.
 */
fun deserializeSiwsMessageParams(data: Map<String, Any?>): io.privy.auth.siws.SiwsMessageParams {
    return io.privy.auth.siws.SiwsMessageParams(
        walletAddress = data["walletAddress"] as String,
        appDomain = data["appDomain"] as String,
        appUri = data["appUri"] as String
    )
}

/**
 * Deserializes a Map received from Flutter into a WalletLoginMetadata object.
 * Returns null if both parameters are null.
 */
fun deserializeWalletLoginMetadata(data: Map<String, Any?>): WalletLoginMetadata? {
    val walletClientTypeString = data["walletClientType"] as String?
    val connectorTypeString = data["connectorType"] as String?
    
    return if (walletClientTypeString == null && connectorTypeString == null) {
        null
    } else {
        WalletLoginMetadata(
            walletClientType = walletClientTypeString?.let(::convertToWalletClientType),
            connectorType = connectorTypeString
        )
    }
}

/**
 * Converts a string to WalletClientType enum using toString() method.
 */
private fun convertToWalletClientType(clientTypeString: String): WalletClientType {
    return WalletClientType.values().find { it.toString() == clientTypeString } 
        ?: WalletClientType.Other
}

/**
 * Converts a cluster string from Flutter to SolanaCluster enum.
 * Returns MainNet if null or unrecognized.
 */
fun convertToSolanaCluster(clusterString: String?): SolanaCluster {
    return when (clusterString?.lowercase()) {
        "mainnet" -> SolanaCluster.MainNet
        "devnet" -> SolanaCluster.DevNet
        "testnet" -> SolanaCluster.TestNet
        else -> SolanaCluster.MainNet // Default to mainnet
    }
}

/**
 * Converts a sendOptions map from Flutter to SendOptions object.
 */
fun convertToSendOptions(optionsMap: Map<String, Any>): SendOptions {
    return SendOptions(
        skipPreflight = optionsMap["skipPreflight"] as? Boolean,
        preflightCommitment = optionsMap["preflightCommitment"] as? String,
        maxRetries = (optionsMap["maxRetries"] as? Number)?.toInt(),
        minContextSlot = (optionsMap["minContextSlot"] as? Number)?.toLong(),
    )
}


