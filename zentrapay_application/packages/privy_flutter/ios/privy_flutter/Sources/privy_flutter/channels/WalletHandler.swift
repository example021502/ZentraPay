import Flutter
import PrivySDK

/// Handles wallet-related operations in the Privy SDK for Flutter.
class WalletHandler: MethodHandler {
  private let methodChannel: FlutterMethodChannel

  // Private method constants
  private let createEthereumWallet = "createEthereumWallet"
  private let createSolanaWallet = "createSolanaWallet"
  private let ethSendRpcRequest = "ethSendRpcRequest"
  private let solanaSignMessage = "solanaSignMessage"
  private let solanaSignTransaction = "solanaSignTransaction"
  private let solanaSignAndSendTransaction = "solanaSignAndSendTransaction"
  private let addSignersMethod = "addSigners"
  private let removeSignerMethod = "removeSigner"
  private let removeAllSignersMethod = "removeAllSigners"
  private let migrateWalletsIfNeededMethod = "migrateWalletsIfNeeded"

  /// Define supported methods directly
  var supportedMethods: Set<String> {
    [createEthereumWallet, createSolanaWallet, ethSendRpcRequest, solanaSignMessage, solanaSignTransaction, solanaSignAndSendTransaction, addSignersMethod, removeSignerMethod, removeAllSignersMethod, migrateWalletsIfNeededMethod]
  }

  /// Initializes the handler with the Flutter MethodChannel.
  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
  }

  /// Handles incoming method calls from Flutter.
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case createEthereumWallet:
      createEthereumWallet(call, result: result)
    case createSolanaWallet:
      createSolanaWallet(call, result: result)
    case ethSendRpcRequest:
      ethSendRpcRequest(call, result: result)
    case solanaSignMessage:
      signSolanaMessage(call, result: result)
    case solanaSignTransaction:
      signSolanaTransaction(call, result: result)
    case solanaSignAndSendTransaction:
      signAndSendSolanaTransaction(call, result: result)
    case addSignersMethod:
      handleAddSigners(call, result: result)
    case removeSignerMethod:
      handleRemoveSigner(call, result: result)
    case removeAllSignersMethod:
      handleRemoveAllSigners(call, result: result)
    case migrateWalletsIfNeededMethod:
      handleMigrateWalletsIfNeeded(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// **Creates an Ethereum embedded wallet**
  private func createEthereumWallet(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let allowAdditional = args["allowAdditional"] as? Bool
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Missing or invalid allowAdditional parameter.",
          details: nil))
      return
    }

    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        let wallet = try await user.createEthereumWallet(allowAdditional: allowAdditional)
        MainThreadHelper.postSuccess(result, wallet.serialized())
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.walletCreationError,
            message: error.localizedDescription,
            details: nil))
      }
    }
  }

  /// **Creates a Solana embedded wallet**
  private func createSolanaWallet(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let allowAdditional = args["allowAdditional"] as? Bool
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Missing or invalid allowAdditional parameter.",
          details: nil))
      return
    }

    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        let wallet = try await user.createSolanaWallet(allowAdditional: allowAdditional)
        MainThreadHelper.postSuccess(result, wallet.serialized())
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.walletCreationError,
            message: error.localizedDescription,
            details: nil))
      }
    }
  }

  /// **Handles Ethereum RPC requests from the wallet**
  private func ethSendRpcRequest(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let walletAddress = args["walletAddress"] as? String,
      let method = args["method"] as? String,
      let params = args["params"] as? [String]
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Missing or invalid parameters.",
          details: nil))
      return
    }

    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        // Find the user's Ethereum wallet
        guard
          let wallet = user.embeddedEthereumWallets.first(where: { $0.address == walletAddress })
        else {
          MainThreadHelper.postError(
            result,
            FlutterError(
              code: ErrorConstants.walletNotFound,
              message: "No Ethereum wallet found with the given address.",
              details: nil))
          return
        }

        let rpcRequest = EthereumRpcRequest(method: method, params: params)
        let rpcResponse = try await wallet.provider.request(rpcRequest)

        let responseMap: [String: Any] = [
          "method": method,
          "data": rpcResponse,
        ]

        MainThreadHelper.postSuccess(result, responseMap)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.rpcRequestFailed,
            message: error.localizedDescription,
            details: nil))
      }
    }
  }

  /// **Signs a message using the Solana embedded wallet**
  private func signSolanaMessage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let message = args["message"] as? String,
      let walletAddress = args["walletAddress"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Missing or invalid parameters.",
          details: nil))
      return
    }

    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        // Find the user's Solana wallet
        guard let wallet = user.embeddedSolanaWallets.first(where: { $0.address == walletAddress })
        else {
          MainThreadHelper.postError(
            result,
            FlutterError(
              code: ErrorConstants.walletNotFound,
              message: "No Solana wallet found with the given address.",
              details: nil))
          return
        }

        let signature = try await wallet.provider.signMessage(message: message)

        MainThreadHelper.postSuccess(result, signature)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.solanaSignMessageError,
            message: error.localizedDescription,
            details: nil))
      }
    }
  }

  /// **Signs a transaction using the Solana embedded wallet**
  private func signSolanaTransaction(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let transactionArray = args["transaction"] as? [UInt8],
      let walletAddress = args["walletAddress"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Missing or invalid parameters.",
          details: nil))
      return
    }

    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        // Find the user's Solana wallet
        guard let wallet = user.embeddedSolanaWallets.first(where: { $0.address == walletAddress })
        else {
          MainThreadHelper.postError(
            result,
            FlutterError(
              code: ErrorConstants.walletNotFound,
              message: "No Solana wallet found with the given address.",
              details: nil))
          return
        }

        // Convert transaction array to Data and sign
        let transactionBytes = Data(transactionArray)
        let signedTransaction = try await wallet.provider.signTransaction(transaction: transactionBytes)

        MainThreadHelper.postSuccess(result, signedTransaction)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.solanaSignTransactionError,
            message: error.localizedDescription,
            details: nil))
      }
    }
  }

  /// **Signs and sends a transaction using the Solana embedded wallet**
  private func signAndSendSolanaTransaction(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let transactionArray = args["transaction"] as? [UInt8],
      let walletAddress = args["walletAddress"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Missing or invalid parameters.",
          details: nil))
      return
    }

    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        // Find the user's Solana wallet
        guard let wallet = user.embeddedSolanaWallets.first(where: { $0.address == walletAddress })
        else {
          MainThreadHelper.postError(
            result,
            FlutterError(
              code: ErrorConstants.walletNotFound,
              message: "No Solana wallet found with the given address.",
              details: nil))
          return
        }

        // Convert transaction array to Data
        let transactionBytes = Data(transactionArray)

        // Extract optional parameters
        let cluster = args["cluster"] as? String
        let rpcUrl = args["rpcUrl"] as? String
        let sendOptionsDict = args["sendOptions"] as? [String: Any]

        // Convert cluster and sendOptions using helper functions
        let solanaCluster = convertToSolanaCluster(cluster) ?? .mainnet
        let sendOptions = convertToSendOptions(sendOptionsDict)

        // Call the provider to sign and send the transaction
        let signature = try await wallet.provider.signAndSendTransaction(
          transaction: transactionBytes,
          cluster: solanaCluster,
          options: sendOptions
        )

        MainThreadHelper.postSuccess(result, signature)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.solanaSignAndSendTransactionError,
            message: error.localizedDescription,
            details: nil))
      }
    }
  }

  /// **Adds signers to an embedded wallet (Ethereum or Solana)**
  private func handleAddSigners(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let walletAddress = args["walletAddress"] as? String,
      let signersData = args["signers"] as? [[String: Any?]]
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "walletAddress and signers are required.",
          details: nil))
      return
    }

    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        // Find wallet by address across both Ethereum and Solana wallets
        let ethWallet = user.embeddedEthereumWallets.first(where: { $0.address == walletAddress })
        let solWallet = user.embeddedSolanaWallets.first(where: { $0.address == walletAddress })

        guard let wallet = ethWallet ?? solWallet else {
          MainThreadHelper.postError(
            result,
            FlutterError(
              code: ErrorConstants.walletNotFound,
              message: "No wallet found with the given address.",
              details: nil))
          return
        }

        // Convert signer data to SignerInput objects
        let signers = signersData.map { data in
          SignerInput(
            signerId: data["signer_id"] as! String,
            policyIds: data["override_policy_ids"] as? [String]
          )
        }

        try await wallet.addSigners(signers)
        MainThreadHelper.postSuccess(result, nil)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.addSignersError,
            message: error.localizedDescription,
            details: nil))
      }
    }
  }

  /// **Removes a specific signer from an embedded wallet**
  private func handleRemoveSigner(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let walletAddress = args["walletAddress"] as? String,
      let signerId = args["signerId"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "walletAddress and signerId are required.",
          details: nil))
      return
    }

    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        let ethWallet = user.embeddedEthereumWallets.first(where: { $0.address == walletAddress })
        let solWallet = user.embeddedSolanaWallets.first(where: { $0.address == walletAddress })

        guard let wallet = ethWallet ?? solWallet else {
          MainThreadHelper.postError(
            result,
            FlutterError(
              code: ErrorConstants.walletNotFound,
              message: "No wallet found with the given address.",
              details: nil))
          return
        }

        try await wallet.removeSigner(signerId: signerId)
        MainThreadHelper.postSuccess(result, nil)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.removeSignerError,
            message: error.localizedDescription,
            details: nil))
      }
    }
  }

  /// **Removes all signers from an embedded wallet**
  private func handleRemoveAllSigners(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let walletAddress = args["walletAddress"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "walletAddress is required.",
          details: nil))
      return
    }

    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        let ethWallet = user.embeddedEthereumWallets.first(where: { $0.address == walletAddress })
        let solWallet = user.embeddedSolanaWallets.first(where: { $0.address == walletAddress })

        guard let wallet = ethWallet ?? solWallet else {
          MainThreadHelper.postError(
            result,
            FlutterError(
              code: ErrorConstants.walletNotFound,
              message: "No wallet found with the given address.",
              details: nil))
          return
        }

        try await wallet.removeAllSigners()
        MainThreadHelper.postSuccess(result, nil)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.removeAllSignersError,
            message: error.localizedDescription,
            details: nil))
      }
    }
  }

  /// **Migrates user wallets to TEE if needed**
  private func handleMigrateWalletsIfNeeded(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        try await user.migrateWalletsIfNeeded()
        MainThreadHelper.postSuccess(result, nil)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.walletMigrationError,
            message: error.localizedDescription,
            details: nil))
      }
    }
  }
}
