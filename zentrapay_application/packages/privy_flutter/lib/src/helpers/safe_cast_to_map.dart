Map<String, dynamic> safeCastToMap(Object? rawData) {
  if (rawData is Map<Object?, Object?>) {
    return rawData.map(
      (key, value) => MapEntry(key.toString(), value), // Ensures String keys
    );
  }
  throw Exception(
      "Expected a Map<Object?, Object?> but got: ${rawData.runtimeType}");
}
