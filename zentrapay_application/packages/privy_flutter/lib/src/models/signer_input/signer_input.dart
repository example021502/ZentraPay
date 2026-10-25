/// Input model for adding a signer to an embedded wallet.
class SignerInput {
  /// The key quorum ID that will be allowed to transact on the wallet.
  final String signerId;

  /// Optional list of policy IDs that transactions from this signer must satisfy.
  final List<String>? policyIds;

  /// Constructor
  const SignerInput({
    required this.signerId,
    this.policyIds,
  });

  /// Convert to JSON for method channel communication.
  Map<String, dynamic> toJson() => {
        'signer_id': signerId,
        'override_policy_ids': policyIds,
      };
}
