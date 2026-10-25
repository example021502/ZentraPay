/// Options for sending Solana transactions.
class SendOptions {
  const SendOptions({
    this.skipPreflight,
    this.preflightCommitment,
    this.maxRetries,
    this.minContextSlot,
  });

  final bool? skipPreflight;
  final String? preflightCommitment;
  final int? maxRetries;
  final int? minContextSlot;

  Map<String, dynamic> toJson() {
    return {
      if (skipPreflight != null) 'skipPreflight': skipPreflight,
      if (preflightCommitment != null)
        'preflightCommitment': preflightCommitment,
      if (maxRetries != null) 'maxRetries': maxRetries,
      if (minContextSlot != null) 'minContextSlot': minContextSlot,
    };
  }
}
