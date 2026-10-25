class VoiceCommandResult {
  final String commandId;
  final String commandType; // VOICE | CHAT
  final String language;
  final String transcript;
  final String? responseText;
  final String intent;
  final String status;
  final bool fraudAlert;
  final String? fraudReason;
  final int? durationMs;
  final double? confidence;
  final String createdAt;

  VoiceCommandResult({
    required this.commandId,
    this.commandType = 'VOICE',
    this.language = 'en',
    required this.transcript,
    this.responseText,
    this.intent = '',
    this.status = '',
    this.fraudAlert = false,
    this.fraudReason,
    this.durationMs,
    this.confidence,
    required this.createdAt,
  });

  bool get isVoice => commandType.toUpperCase() == 'VOICE';

  factory VoiceCommandResult.fromJson(Map<String, dynamic> json) =>
      VoiceCommandResult(
        commandId: json['commandId']?.toString() ?? '',
        commandType: json['commandType']?.toString() ?? 'VOICE',
        language: json['language']?.toString() ?? 'en',
        transcript: json['transcript']?.toString() ?? '',
        responseText: json['responseText']?.toString(),
        intent: json['intent']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        fraudAlert: json['fraudAlert'] == true,
        fraudReason: json['fraudReason']?.toString(),
        durationMs: (json['durationMs'] as num?)?.toInt(),
        confidence: (json['confidence'] as num?)?.toDouble(),
        createdAt: json['createdAt']?.toString() ?? '',
      );
}
