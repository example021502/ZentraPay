package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.ADD_SIGNERS_ERROR
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.REMOVE_ALL_SIGNERS_ERROR
import io.privy.privyflutter.constants.ErrorConstants.REMOVE_SIGNER_ERROR
import io.privy.privyflutter.constants.ErrorConstants.RPC_REQUEST_FAILED
import io.privy.privyflutter.constants.ErrorConstants.SOLANA_SIGN_AND_SEND_TRANSACTION_ERROR
import io.privy.privyflutter.constants.ErrorConstants.SOLANA_SIGN_MESSAGE_ERROR
import io.privy.privyflutter.constants.ErrorConstants.SOLANA_SIGN_TRANSACTION_ERROR
import io.privy.privyflutter.constants.ErrorConstants.USER_NOT_AUTHENTICATED
import io.privy.privyflutter.constants.ErrorConstants.WALLET_CREATION_ERROR
import io.privy.privyflutter.constants.ErrorConstants.WALLET_MIGRATION_ERROR
import io.privy.privyflutter.constants.ErrorConstants.WALLET_NOT_FOUND
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.convertToSendOptions
import io.privy.privyflutter.helpers.convertToSolanaCluster
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeEthereumRpcResponse
import io.privy.privyflutter.helpers.serializeEthereumWallet
import io.privy.privyflutter.helpers.serializeSolanaWallet
import io.privy.wallet.SignerInput
import io.privy.wallet.ethereum.EmbeddedEthereumWallet
import io.privy.wallet.ethereum.EthereumRpcRequest
import io.privy.wallet.ethereum.EthereumRpcResponse
import io.privy.wallet.solana.EmbeddedSolanaWallet
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

class WalletHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        CREATE_ETHEREUM_WALLET,
        CREATE_SOLANA_WALLET,
        ETH_SEND_RPC_REQUEST,
        SOLANA_SIGN_MESSAGE,
        SOLANA_SIGN_TRANSACTION,
        SOLANA_SIGN_AND_SEND_TRANSACTION,
        ADD_SIGNERS,
        REMOVE_SIGNER,
        REMOVE_ALL_SIGNERS,
        MIGRATE_WALLETS_IF_NEEDED,
    ),
) {

    // Define private constants
    private companion object {
        private const val CREATE_ETHEREUM_WALLET = "createEthereumWallet"
        private const val CREATE_SOLANA_WALLET = "createSolanaWallet"
        private const val ETH_SEND_RPC_REQUEST = "ethSendRpcRequest"
        private const val SOLANA_SIGN_MESSAGE = "solanaSignMessage"
        private const val SOLANA_SIGN_TRANSACTION = "solanaSignTransaction"
        private const val SOLANA_SIGN_AND_SEND_TRANSACTION = "solanaSignAndSendTransaction"
        private const val ADD_SIGNERS = "addSigners"
        private const val REMOVE_SIGNER = "removeSigner"
        private const val REMOVE_ALL_SIGNERS = "removeAllSigners"
        private const val MIGRATE_WALLETS_IF_NEEDED = "migrateWalletsIfNeeded"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            CREATE_ETHEREUM_WALLET -> {
                val allowAdditional = call.argument<Boolean>("allowAdditional") ?: false
                handleCreateEthereumWallet(allowAdditional, result)
            }

            CREATE_SOLANA_WALLET -> {
                val allowAdditional = call.argument<Boolean>("allowAdditional") ?: false
                handleCreateSolanaWallet(allowAdditional, result)
            }
            ETH_SEND_RPC_REQUEST -> {
                val walletAddress = call.argument<String>("walletAddress")
                val method = call.argument<String>("method")
                val params = call.argument<List<String>>("params") ?: emptyList()

                if (walletAddress == null || method == null) {
                    result.error(INVALID_ARGUMENT, "walletAddress and method are required.", null)
                    return
                }

                handleEthSendRpcRequest(walletAddress, method, params, result)
            }

            SOLANA_SIGN_MESSAGE -> {
                val message = call.argument<String>("message")
                val walletAddress = call.argument<String>("walletAddress")

                if (message == null || walletAddress == null) {
                    result.error(INVALID_ARGUMENT, "Message and Wallet Address are required.", null)
                    return
                }

                handleSolanaSignMessage(message, walletAddress, result)
            }

            SOLANA_SIGN_TRANSACTION -> {
                val transactionList = call.argument<List<Int>>("transaction")
                val walletAddress = call.argument<String>("walletAddress")

                if (transactionList == null || walletAddress == null) {
                    result.error(INVALID_ARGUMENT, "Transaction and Wallet Address are required.", null)
                    return
                }

                // Convert List<Int> to ByteArray
                val transaction = transactionList.map { it.toByte() }.toByteArray()

                handleSolanaSignTransaction(transaction, walletAddress, result)
            }

            SOLANA_SIGN_AND_SEND_TRANSACTION -> {
                val transactionList = call.argument<List<Int>>("transaction")
                val walletAddress = call.argument<String>("walletAddress")
                val cluster = call.argument<String>("cluster")
                val rpcUrl = call.argument<String>("rpcUrl")
                val sendOptions = call.argument<Map<String, Any>>("sendOptions")

                if (transactionList == null || walletAddress == null) {
                    result.error(INVALID_ARGUMENT, "Transaction and Wallet Address are required.", null)
                    return
                }

                // Convert List<Int> to ByteArray
                val transaction = transactionList.map { it.toByte() }.toByteArray()

                handleSolanaSignAndSendTransaction(transaction, walletAddress, cluster, rpcUrl, sendOptions, result)
            }

            ADD_SIGNERS -> {
                val walletAddress = call.argument<String>("walletAddress")
                val signers = call.argument<List<Map<String, Any?>>>("signers")

                if (walletAddress == null || signers == null) {
                    result.error(INVALID_ARGUMENT, "walletAddress and signers are required.", null)
                    return
                }

                handleAddSigners(walletAddress, signers, result)
            }

            REMOVE_SIGNER -> {
                val walletAddress = call.argument<String>("walletAddress")
                val signerId = call.argument<String>("signerId")

                if (walletAddress == null || signerId == null) {
                    result.error(INVALID_ARGUMENT, "walletAddress and signerId are required.", null)
                    return
                }

                handleRemoveSigner(walletAddress, signerId, result)
            }

            REMOVE_ALL_SIGNERS -> {
                val walletAddress = call.argument<String>("walletAddress")

                if (walletAddress == null) {
                    result.error(INVALID_ARGUMENT, "walletAddress is required.", null)
                    return
                }

                handleRemoveAllSigners(walletAddress, result)
            }

            MIGRATE_WALLETS_IF_NEEDED -> {
                handleMigrateWalletsIfNeeded(result)
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Handles adding signers to an embedded wallet (Ethereum or Solana).
     */
    private fun handleAddSigners(
        walletAddress: String,
        signersData: List<Map<String, Any?>>,
        result: MethodChannel.Result,
    ) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user

                if (user == null) {
                    result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                    return@launch
                }

                val wallet =
                    user.embeddedEthereumWallets.firstOrNull { it.address == walletAddress }
                        ?: user.embeddedSolanaWallets.firstOrNull { it.address == walletAddress }

                if (wallet == null) {
                    result.postError(WALLET_NOT_FOUND, "No wallet found for the given address.", null)
                    return@launch
                }

                val signers = signersData.map { data ->
                    SignerInput(
                        signerId = data["signer_id"] as String,
                        policyIds = (data["override_policy_ids"] as? List<String>),
                    )
                }

                wallet.addSigners(signers).fold(
                    onSuccess = {
                        result.postSuccess(null)
                    },
                    onFailure = { error ->
                        result.postError(ADD_SIGNERS_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(ADD_SIGNERS_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles removing a specific signer from an embedded wallet.
     */
    private fun handleRemoveSigner(
        walletAddress: String,
        signerId: String,
        result: MethodChannel.Result,
    ) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user

                if (user == null) {
                    result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                    return@launch
                }

                val wallet =
                    user.embeddedEthereumWallets.firstOrNull { it.address == walletAddress }
                        ?: user.embeddedSolanaWallets.firstOrNull { it.address == walletAddress }

                if (wallet == null) {
                    result.postError(WALLET_NOT_FOUND, "No wallet found for the given address.", null)
                    return@launch
                }

                wallet.removeSigner(signerId).fold(
                    onSuccess = {
                        result.postSuccess(null)
                    },
                    onFailure = { error ->
                        result.postError(REMOVE_SIGNER_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(REMOVE_SIGNER_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles removing all signers from an embedded wallet.
     */
    private fun handleRemoveAllSigners(
        walletAddress: String,
        result: MethodChannel.Result,
    ) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user

                if (user == null) {
                    result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                    return@launch
                }

                val wallet =
                    user.embeddedEthereumWallets.firstOrNull { it.address == walletAddress }
                        ?: user.embeddedSolanaWallets.firstOrNull { it.address == walletAddress }

                if (wallet == null) {
                    result.postError(WALLET_NOT_FOUND, "No wallet found for the given address.", null)
                    return@launch
                }

                wallet.removeAllSigners().fold(
                    onSuccess = {
                        result.postSuccess(null)
                    },
                    onFailure = { error ->
                        result.postError(REMOVE_ALL_SIGNERS_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(REMOVE_ALL_SIGNERS_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles signing a Solana message using the user's Solana embedded wallet.
     */
    private fun handleSolanaSignMessage(
        message: String,
        walletAddress: String,
        result: MethodChannel.Result,
    ) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user

                if (user == null) {
                    result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                    return@launch
                }
                // Retrieve the wallet that matches the provided address
                val solanaWallet =
                    user.embeddedSolanaWallets.firstOrNull { it.address == walletAddress }

                if (solanaWallet == null) {
                    result.postError(WALLET_NOT_FOUND, "No Solana wallet found for the user.", null)

                    return@launch
                }
                // Call the provider to sign the message
                val signResult: Result<String> = solanaWallet.provider.signMessage(message)

                signResult.fold(
                    onSuccess = { signature ->
                        result.postSuccess(signature) // Return the signed message as a string
                    },
                    onFailure = { error ->
                        result.postError(SOLANA_SIGN_MESSAGE_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(SOLANA_SIGN_MESSAGE_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles signing a Solana transaction using the user's Solana embedded wallet.
     */
    private fun handleSolanaSignTransaction(
        transaction: ByteArray,
        walletAddress: String,
        result: MethodChannel.Result,
    ) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user

                if (user == null) {
                    result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                    return@launch
                }
                // Retrieve the wallet that matches the provided address
                val solanaWallet =
                    user.embeddedSolanaWallets.firstOrNull { it.address == walletAddress }

                if (solanaWallet == null) {
                    result.postError(WALLET_NOT_FOUND, "No Solana wallet found for the user.", null)

                    return@launch
                }
                // Call the provider to sign the transaction
                val signResult: Result<String> = solanaWallet.provider.signTransaction(transaction)

                signResult.fold(
                    onSuccess = { signedTransaction ->
                        result.postSuccess(signedTransaction) // Return the signed transaction as a string
                    },
                    onFailure = { error ->
                        result.postError(SOLANA_SIGN_TRANSACTION_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(SOLANA_SIGN_TRANSACTION_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles signing and sending a Solana transaction using the user's Solana embedded wallet.
     */
    private fun handleSolanaSignAndSendTransaction(
        transaction: ByteArray,
        walletAddress: String,
        cluster: String?,
        rpcUrl: String?,
        sendOptions: Map<String, Any>?,
        result: MethodChannel.Result,
    ) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user

                if (user == null) {
                    result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                    return@launch
                }
                // Retrieve the wallet that matches the provided address
                val solanaWallet =
                    user.embeddedSolanaWallets.firstOrNull { it.address == walletAddress }

                if (solanaWallet == null) {
                    result.postError(WALLET_NOT_FOUND, "No Solana wallet found for the user.", null)
                    return@launch
                }

                // Convert cluster string and sendOptions map to proper types if provided
                val solanaCluster = convertToSolanaCluster(cluster)
                val solanaOptions = sendOptions?.let { convertToSendOptions(it) }

                // Call the provider to sign and send the transaction
                val signResult: Result<String> = solanaWallet.provider.signAndSendTransaction(
                    transaction,
                    solanaCluster,
                    rpcUrl,
                    solanaOptions,
                )

                signResult.fold(
                    onSuccess = { signature ->
                        result.postSuccess(signature) // Return the transaction signature
                    },
                    onFailure = { error ->
                        result.postError(SOLANA_SIGN_AND_SEND_TRANSACTION_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(SOLANA_SIGN_AND_SEND_TRANSACTION_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles Ethereum wallet creation asynchronously using coroutines and Result handling.
     */
    private fun handleCreateEthereumWallet(allowAdditional: Boolean, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user

                if (user == null) {
                    result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)

                    return@launch
                }

                val walletResult: Result<EmbeddedEthereumWallet> =
                    user.createEthereumWallet(allowAdditional)

                walletResult.fold(
                    onSuccess = { wallet ->
                        result.postSuccess(serializeEthereumWallet(wallet)) // Return serialized wallet data
                    },
                    onFailure = { error ->
                        result.error(WALLET_CREATION_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(WALLET_CREATION_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles Solana wallet creation asynchronously using coroutines and Result handling.
     */
    private fun handleCreateSolanaWallet(allowAdditional: Boolean, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user

                if (user == null) {
                    result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)

                    return@launch
                }

                val walletResult: Result<EmbeddedSolanaWallet> = user.createSolanaWallet(allowAdditional)

                walletResult.fold(
                    onSuccess = { wallet ->
                        result.postSuccess(serializeSolanaWallet(wallet)) // Return serialized wallet data
                    },
                    onFailure = { error ->
                        result.postError(WALLET_CREATION_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(WALLET_CREATION_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles migrating user wallets to TEE if needed.
     */
    private fun handleMigrateWalletsIfNeeded(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user

                if (user == null) {
                    result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                    return@launch
                }

                user.migrateWalletsIfNeeded().fold(
                    onSuccess = {
                        result.postSuccess(null)
                    },
                    onFailure = { error ->
                        result.postError(WALLET_MIGRATION_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(WALLET_MIGRATION_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles Ethereum RPC requests using the correct wallet instance.
     */
    private fun handleEthSendRpcRequest(
        walletAddress: String,
        method: String,
        params: List<String>,
        result: MethodChannel.Result,
    ) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user

                if (user == null) {
                    result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)

                    return@launch
                }

                // Find the correct wallet by address
                val wallet =
                    user.embeddedEthereumWallets.firstOrNull { it.address == walletAddress }

                if (wallet == null) {
                    result.postError(
                        WALLET_NOT_FOUND,
                        "No Ethereum wallet found for the given address.",
                        null,
                    )

                    return@launch
                }
                // Create the RPC request
                val rpcRequest = EthereumRpcRequest(method, params)

                // Call the provider's request method
                val rpcResponse: Result<EthereumRpcResponse> = wallet.provider.request(rpcRequest)

                rpcResponse.fold(
                    onSuccess = { response ->
                        result.postSuccess(
                            serializeEthereumRpcResponse(
                                response,
                            ),
                        )
                    },
                    onFailure = { error ->
                        result.postError(RPC_REQUEST_FAILED, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(RPC_REQUEST_FAILED, e.message, null)
            }
        }
    }
}
