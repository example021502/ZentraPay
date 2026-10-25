import Combine
import Flutter
import Foundation
import PrivySDK

/// Handles auth state changes and sends updates to Flutter via EventChannel.
class AuthStateEventChannelHandler: NSObject, FlutterStreamHandler {

  private var eventSink: FlutterEventSink?
  private var authStateTask: Task<Void, Never>?
  private let authStateSubject = CurrentValueSubject<AuthState, Never>(.notReady)  // Start with NotReady

  func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink)
    -> FlutterError?
  {
    self.eventSink = eventSink
    subscribeToAuthState()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    authStateTask?.cancel()
    authStateTask = nil
    eventSink = nil
    return nil
  }
  
  deinit {
    authStateTask?.cancel()
  }

  /// Subscribes to PrivyManager's authentication state updates and sends events to Flutter.
  private func subscribeToAuthState() {
    authStateTask = Task { [weak self] in
      for await authState in PrivyManager.shared.privy.authStateStream {
        guard let self = self else {
          return  // Exit the loop if self is nil
        }

        self.authStateSubject.send(authState)

        let serializedState = authState.serialized()

        DispatchQueue.main.async {
          self.eventSink?(serializedState)
        }
      }
    }
  }
}
