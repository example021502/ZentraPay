import 'package:privy_flutter/src/errors/privy_exception.dart';

/// A sealed class representing the result of an operation.
sealed class Result<T> {
  const Result();

  /// Executes success or failure callbacks.
  void fold({
    required void Function(T value) onSuccess,
    required void Function(PrivyException error) onFailure,
  }) {
    switch (this) {
      case Success<T>():
        onSuccess((this as Success<T>).value);
      case Failure<T>():
        onFailure((this as Failure<T>).error);
    }
  }
}

/// Represents a successful result.
final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

/// Represents a failure result.
final class Failure<T> extends Result<T> {
  final PrivyException error;
  const Failure(this.error);
}
