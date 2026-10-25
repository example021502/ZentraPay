import 'package:flutter/services.dart';
import 'package:privy_flutter/src/utils/json_serializable.dart'; // Importing JsonSerializable mixin

/// Handles communication with the native platform via MethodChannels.
class MethodChannelHandler {
  /// The method channel used for invoking native methods.
  static const MethodChannel _channel = MethodChannel('privy_flutter');

  /// Invokes a method on the native platform and returns a result of type [T].
  ///
  /// [method]: The name of the method to invoke.
  /// [arguments]: Optional arguments to send with the method call.
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    try {
      // Automatically serialize the arguments if they implement JsonSerializable
      final serializedArguments = _serializeArguments(arguments);
      final result =
          await _channel.invokeMethod<T>(method, serializedArguments);
      return result;
    } on PlatformException {
      rethrow;
    }
  }

  /// Sets a method call handler for listening to method calls from the native platform.
  void setMethodCallHandler(Future<dynamic> Function(MethodCall call) handler) {
    _channel.setMethodCallHandler(handler);
  }

  /// Recursively serializes arguments before sending them to the native platform.
  ///
  /// Handles lists, maps, and objects that implement `JsonSerializable`.
  dynamic _serializeArguments(dynamic object) {
    if (object == null) return null;

    // If it's a list, recursively serialize each element
    if (object is List) {
      return object.map((arg) => _serializeArguments(arg)).toList();
    }

    // If it's a map, recursively serialize its values
    if (object is Map) {
      return object
          .map((key, value) => MapEntry(key, _serializeArguments(value)));
    }

    // If the object implements `JsonSerializable`, call its `toJson` method
    if (object is JsonSerializable) {
      return object.toJson();
    }

    // Otherwise, return the object as-is
    return object;
  }
}
