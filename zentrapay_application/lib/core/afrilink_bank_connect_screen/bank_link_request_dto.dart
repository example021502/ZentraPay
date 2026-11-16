import 'dart:convert';

/// What the AfriLink Connect widget hands back on success, turned into the body of
/// `POST /api/zbanking/link`.
///
/// The widget returns the pieces that finish the link: a session id and auth token (when the link
/// still has to be completed) and/or the linked account's `id`, plus the AfriLink `userId` and the
/// `institution`. All of them are forwarded to the backend, which submits the token to AfriLink's
/// linking endpoint (or reads the account back) and saves the result.
///
/// No account number, no account holder name and no bank credentials ever pass through the app:
/// the user enters those inside AfriLink's widget, not in a ZentraPay form.
class BankLinkRequestDto {
  /// The auth token / code from the widget ("public token"). Empty when the widget already
  /// completed the link and only returned [accountId].
  final String publicToken;
  final String sessionId;

  /// The user id AfriLink holds the connection under.
  final String afriLinkUserId;
  final String accountId;
  final String institutionName;
  final String institutionId;
  final String institutionCountry;

  const BankLinkRequestDto({
    this.publicToken = '',
    this.sessionId = '',
    this.afriLinkUserId = '',
    this.accountId = '',
    this.institutionName = '',
    this.institutionId = '',
    this.institutionCountry = '',
  });

  Map<String, dynamic> toJson() => {
    if (publicToken.isNotEmpty) 'publicToken': publicToken,
    if (sessionId.isNotEmpty) 'sessionId': sessionId,
    if (afriLinkUserId.isNotEmpty) 'afriLinkUserId': afriLinkUserId,
    if (accountId.isNotEmpty) 'accountId': accountId,
    if (institutionName.isNotEmpty) 'institutionName': institutionName,
    if (institutionId.isNotEmpty) 'institutionId': institutionId,
    if (institutionCountry.isNotEmpty) 'institutionCountry': institutionCountry,
  };

  /// Parses the JSON string the widget page posts through the `AfriLinkChannel`
  /// JavaScript channel: `{ "type": "success", "data": { ... } }`. The widget may report the
  /// account at the top level or under `account`, and the institution as a name or as an object
  /// with `name` / `id`. Returns null when there is neither a token nor an account id to finish
  /// the link with.
  static BankLinkRequestDto? fromWidgetData(
    Map<String, dynamic> data, {
    String country = '',
  }) {
    var source = data;
    final nested = data['account'];
    if (nested is Map) {
      source = {...data, ...Map<String, dynamic>.from(nested)};
    }

    String pick(List<String> keys) {
      for (final key in keys) {
        final value = source[key];
        if (value != null && value is! Map && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }

    final token = pick(const [
      'publicToken',
      'public_token',
      'token',
      'authCode',
      'auth_code',
      'code',
    ]);
    final accountId = pick(const ['id', 'accountId', 'account_id']);
    if (token.isEmpty && accountId.isEmpty) return null;

    var name = '';
    var institutionId = '';
    final institution = source['institution'];
    if (institution is Map) {
      name = (institution['name'] ?? institution['bankName'] ?? '').toString();
      institutionId = (institution['id'] ?? institution['code'] ?? '')
          .toString();
    } else if (institution != null) {
      name = institution.toString();
    }

    return BankLinkRequestDto(
      publicToken: token,
      sessionId: pick(const ['sessionId', 'session_id', 'session']),
      afriLinkUserId: pick(const ['userId', 'user_id', 'customerId']),
      accountId: accountId,
      institutionName: name.trim(),
      institutionId: institutionId.trim(),
      institutionCountry: country,
    );
  }

  /// Convenience for tests: decode a raw JSON string.
  static Map<String, dynamic> decode(String raw) =>
      Map<String, dynamic>.from(jsonDecode(raw) as Map);
}
