import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';

/// Why money is being taken out of the vault. Shown in the withdrawal flow and
/// kept on every withdrawal record.
const Map<String, String> kEmergencyCategories = {
  'MEDICAL': 'Medical',
  'ACCIDENT': 'Accident',
  'FUNERAL': 'Funeral / bereavement',
  'DISASTER': 'Fire, flood or disaster',
  'TRAVEL': 'Urgent travel',
  'INCOME_LOSS': 'Sudden loss of income',
  'OTHER': 'Other emergency',
};

/// One line of the vault's ledger. Amounts are whole minor units (pesewas,
/// cents) so repeated round-ups never drift the way doubles would.
class VaultEntry {
  final String id;
  final String type; // ROUND_UP | WITHDRAWAL
  final String currency;
  final int minor;
  final DateTime at;
  final String? reference;
  final String? category;
  final String? reason;
  final String? usage;

  const VaultEntry({
    required this.id,
    required this.type,
    required this.currency,
    required this.minor,
    required this.at,
    this.reference,
    this.category,
    this.reason,
    this.usage,
  });

  bool get isWithdrawal => type == 'WITHDRAWAL';

  double get amount => minor / 100;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'currency': currency,
    'minor': minor,
    'at': at.toIso8601String(),
    'reference': reference,
    'category': category,
    'reason': reason,
    'usage': usage,
  };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
    id: (json['id'] ?? '').toString(),
    type: (json['type'] ?? 'ROUND_UP').toString(),
    currency: (json['currency'] ?? 'GHS').toString(),
    minor: (json['minor'] as num?)?.toInt() ?? 0,
    at: DateTime.tryParse((json['at'] ?? '').toString()) ?? DateTime.now(),
    reference: json['reference']?.toString(),
    category: json['category']?.toString(),
    reason: json['reason']?.toString(),
    usage: json['usage']?.toString(),
  );
}

/// What a PIN attempt did.
enum VaultPinResult { ok, wrong, locked }

/// The Emergency Vault: while it is ACTIVE, every payment that has cents is
/// rounded UP to the next 0.50 and the difference is set aside here
/// (40.34 -> 40.50 saves 0.16; 40.60 -> 41.00 saves 0.40; 40.00 saves nothing).
///
/// The saved money is for emergencies only. Taking it out takes a reason, a
/// written explanation, confirmations, a typed phrase, the vault PIN and a
/// short waiting period - and no more than one withdrawal a day.
///
/// The ledger and the vault PIN are kept in the device's secure storage,
/// scoped to the signed-in user. The backend has no vault accounts yet, so
/// this class only RECORDS round-ups; it does not move money by itself.
class EmergencyVault extends ChangeNotifier {
  EmergencyVault._();
  static final EmergencyVault instance = EmergencyVault._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Wrong PIN guesses allowed before the vault locks.
  static const int maxPinAttempts = 3;
  static const Duration lockDuration = Duration(minutes: 15);

  /// Minimum gap between two withdrawals.
  static const Duration withdrawalCooldown = Duration(hours: 24);

  bool _loaded = false;
  bool _active = false;
  String? _pinHash;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  final List<VaultEntry> _entries = [];

  bool get isLoaded => _loaded;
  bool get isActive => _active;
  bool get hasPin => _pinHash != null;

  /// Newest first.
  List<VaultEntry> get entries => List.unmodifiable(_entries);
  List<VaultEntry> get roundUps =>
      _entries.where((e) => !e.isWithdrawal).toList();
  List<VaultEntry> get withdrawals =>
      _entries.where((e) => e.isWithdrawal).toList();

  /// Saved minus withdrawn, per currency, in minor units. Currencies whose
  /// balance is zero are left out.
  Map<String, int> get balancesMinor {
    final totals = <String, int>{};
    for (final e in _entries) {
      totals[e.currency] =
          (totals[e.currency] ?? 0) + (e.isWithdrawal ? -e.minor : e.minor);
    }
    totals.removeWhere((_, v) => v <= 0);
    return totals;
  }

  int balanceMinor(String currency) => balancesMinor[currency] ?? 0;

  bool get hasBalance => balancesMinor.isNotEmpty;

  DateTime? get lockedUntil =>
      _lockedUntil != null && _lockedUntil!.isAfter(DateTime.now())
      ? _lockedUntil
      : null;

  bool get isLocked => lockedUntil != null;

  int get attemptsLeft => maxPinAttempts - _failedAttempts;

  /// When the next withdrawal becomes possible, or null if one is possible now.
  DateTime? get nextWithdrawalAt {
    final last = withdrawals.isEmpty ? null : withdrawals.first.at;
    if (last == null) return null;
    final next = last.add(withdrawalCooldown);
    return next.isAfter(DateTime.now()) ? next : null;
  }

  // -------------------------------------------------------------- rounding

  /// The extra amount that rounds [amount] up to the next 0.50 (0 when it is
  /// already a multiple of 0.50). Worked in whole minor units.
  static int roundUpGapMinor(double amount) {
    final minor = (amount * 100).round();
    if (minor <= 0) return 0;
    final remainder = minor % 50;
    return remainder == 0 ? 0 : 50 - remainder;
  }

  static String formatMinor(int minor, {String currency = ''}) {
    final whole = (minor ~/ 100).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    final cents = (minor % 100).toString().padLeft(2, '0');
    final text = '$whole.$cents';
    return currency.isEmpty ? text : '$currency $text';
  }

  // --------------------------------------------------------------- storage

  String get _key {
    final id =
        SecureStorageService.getUserId() ??
        SecureStorageService.getSession()['userId'] ??
        'guest';
    return 'emergency_vault_$id';
  }

  String _hash(String pin) {
    final id =
        SecureStorageService.getUserId() ??
        SecureStorageService.getSession()['userId'] ??
        'guest';
    return sha256.convert(utf8.encode('zentrapay-vault:$id:$pin')).toString();
  }

  /// Reads the saved vault once. Safe to call repeatedly.
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    try {
      final raw = await _storage.read(key: _key);
      _entries.clear();
      _active = false;
      _pinHash = null;
      _failedAttempts = 0;
      _lockedUntil = null;
      if (raw != null && raw.isNotEmpty) {
        final data = json.decode(raw) as Map<String, dynamic>;
        _active = data['active'] == true;
        _pinHash = data['pinHash']?.toString();
        _failedAttempts = (data['failedAttempts'] as num?)?.toInt() ?? 0;
        _lockedUntil = DateTime.tryParse('${data['lockedUntil'] ?? ''}');
        final list = (data['entries'] as List?) ?? const [];
        _entries.addAll(
          list.whereType<Map>().map(
            (e) => VaultEntry.fromJson(Map<String, dynamic>.from(e)),
          ),
        );
        _entries.sort((a, b) => b.at.compareTo(a.at));
      }
    } catch (e) {
      debugPrint('Emergency vault could not be read: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      await _storage.write(
        key: _key,
        value: json.encode({
          'active': _active,
          'pinHash': _pinHash,
          'failedAttempts': _failedAttempts,
          'lockedUntil': _lockedUntil?.toIso8601String(),
          'entries': _entries.map((e) => e.toJson()).toList(),
        }),
      );
    } catch (e) {
      debugPrint('Emergency vault could not be saved: $e');
    }
  }

  /// Forget everything held in memory (sign-out). The saved copy stays on the
  /// device for the next sign-in of the same user.
  void reset() {
    _loaded = false;
    _active = false;
    _pinHash = null;
    _failedAttempts = 0;
    _lockedUntil = null;
    _entries.clear();
    notifyListeners();
  }

  // ----------------------------------------------------------------- switch

  Future<void> setActive(bool value) async {
    await load();
    if (value && !hasPin) return; // a PIN must exist first
    _active = value;
    notifyListeners();
    await _save();
  }

  /// Creates (or replaces) the vault PIN and switches the vault on.
  Future<void> createPin(String pin) async {
    await load();
    _pinHash = _hash(pin);
    _failedAttempts = 0;
    _lockedUntil = null;
    _active = true;
    notifyListeners();
    await _save();
  }

  Future<VaultPinResult> verifyPin(String pin) async {
    await load();
    if (isLocked) return VaultPinResult.locked;
    if (_pinHash != null && _hash(pin) == _pinHash) {
      _failedAttempts = 0;
      _lockedUntil = null;
      notifyListeners();
      await _save();
      return VaultPinResult.ok;
    }
    _failedAttempts++;
    if (_failedAttempts >= maxPinAttempts) {
      _lockedUntil = DateTime.now().add(lockDuration);
      _failedAttempts = 0;
      notifyListeners();
      await _save();
      return VaultPinResult.locked;
    }
    notifyListeners();
    await _save();
    return VaultPinResult.wrong;
  }

  // ---------------------------------------------------------------- ledger

  /// Called after a payment succeeds. When the vault is active and [amount]
  /// has a gap to the next 0.50, records it and returns the saved minor units;
  /// otherwise returns 0.
  Future<int> recordRoundUp({
    required double amount,
    required String currency,
    String? reference,
  }) async {
    await load();
    if (!_active || currency.trim().isEmpty) return 0;
    final gap = roundUpGapMinor(amount);
    if (gap <= 0) return 0;
    final now = DateTime.now();
    _entries.insert(
      0,
      VaultEntry(
        id: 'ru_${now.microsecondsSinceEpoch}',
        type: 'ROUND_UP',
        currency: currency.trim().toUpperCase(),
        minor: gap,
        at: now,
        reference: reference,
      ),
    );
    notifyListeners();
    await _save();
    return gap;
  }

  /// Records a completed emergency withdrawal. The caller has already run the
  /// whole verification flow; this only re-checks the money rules.
  Future<void> recordWithdrawal({
    required int minor,
    required String currency,
    required String category,
    required String reason,
    required String usage,
  }) async {
    await load();
    if (minor <= 0 || minor > balanceMinor(currency)) {
      throw StateError('That is more than the vault holds.');
    }
    if (nextWithdrawalAt != null) {
      throw StateError('Only one emergency withdrawal is allowed per day.');
    }
    final now = DateTime.now();
    _entries.insert(
      0,
      VaultEntry(
        id: 'wd_${now.microsecondsSinceEpoch}',
        type: 'WITHDRAWAL',
        currency: currency,
        minor: minor,
        at: now,
        category: category,
        reason: reason,
        usage: usage,
      ),
    );
    notifyListeners();
    await _save();
  }
}
