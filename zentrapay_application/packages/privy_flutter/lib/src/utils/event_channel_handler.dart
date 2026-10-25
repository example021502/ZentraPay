import 'package:flutter/services.dart';

/// A handler class for managing an EventChannel in Flutter.
/// This class listens to events from the native platform via an EventChannel.
class EventChannelHandler {
  /// A private variable to store the event stream, ensuring it is initialized only once.
  Stream<dynamic>? _eventStream;

  /// The EventChannel used to communicate with the native platform.
  /// This channel listens for authentication state changes.
  static const EventChannel _eventChannel =
      EventChannel('privy_flutter/authState');

  /// Starts listening to the event channel and returns a stream of events.
  ///
  /// - If `_eventStream` is not yet initialized, it is assigned a stream from `_eventChannel.receiveBroadcastStream()`.
  /// - This ensures that only one stream instance is created and reused.
  ///
  /// Returns a `Stream<dynamic>` that emits authentication state updates from the native side.
  Stream<dynamic> listen() {
    _eventStream ??= _eventChannel.receiveBroadcastStream();
    return _eventStream!;
  }
}
