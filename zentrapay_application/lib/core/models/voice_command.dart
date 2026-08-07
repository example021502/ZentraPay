class VoiceCommandResult {
  final String commandId;
  final String transcript;
  final String? responseText;
  final String createdAt;

  VoiceCommandResult({
    required this.commandId,
    required this.transcript,
    this.responseText,
    required this.createdAt,
  });

  factory VoiceCommandResult.fromJson(Map<String, dynamic> json) =>
      VoiceCommandResult(
        commandId: json['commandId'] ?? '',
        transcript: json['transcript'] ?? '',
        responseText: json['responseText'],
        createdAt: json['createdAt'] ?? '',
      );
}
