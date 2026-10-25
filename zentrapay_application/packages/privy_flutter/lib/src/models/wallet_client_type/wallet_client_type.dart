/// Enum representing supported wallet client types for SIWE authentication.
/// This corresponds to the native WalletClientType enum and helps identify
/// which wallet client the user is connecting with.
enum WalletClientType {
  /// To be used if no wallet clients below apply
  other('other'),

  /// Privy wallet
  privy('privy'),

  /// Coinbase wallet
  coinbaseWallet('coinbase_wallet'),

  /// Wallet Connect supported wallets
  metamask('metamask'),
  trust('trust'),
  safe('safe'),
  rainbow('rainbow'),
  uniswap('uniswap'),
  zerion('zerion'),
  argent('argent'),
  spot('spot'),
  omni('omni'),
  cryptocom('cryptocom'),
  blockchain('blockchain'),
  safepal('safepal'),
  bitkeep('bitkeep'),
  zengo('zengo'),
  oneInch('oneInch'),
  binance('binance'),
  exodus('exodus'),
  mewWallet('mew_wallet'),
  alphawallet('alphawallet'),
  keyringPro('keyring_pro'),
  mathwallet('mathwallet'),
  unstoppable('unstoppable'),
  obvious('obvious'),
  ambire('ambire'),
  internetMoneyWallet('internet_money_wallet'),
  coin98('coin98'),
  abcWallet('abc_wallet'),
  arculusWallet('arculus_wallet'),
  haha('haha'),
  clingWallet('cling_wallet'),
  broearn('broearn'),
  copiosa('copiosa'),
  burritoWallet('burrito_wallet'),
  enjinWallet('enjin_wallet'),
  plasmaWallet('plasma_wallet'),
  avacus('avacus'),
  bee('bee'),
  pitaka('pitaka'),
  pltwallet('pltwallet'),
  minerva('minerva'),
  kryptogo('kryptogo'),
  prema('prema'),
  slingshot('slingshot'),
  kriptonio('kriptonio'),
  timeless('timeless'),
  secux('secux'),
  bitizen('bitizen'),
  blocto('blocto'),
  safemoon('safemoon');

  /// The raw string value that corresponds to the native enum
  const WalletClientType(this.rawValue);

  /// The raw string value used for serialization
  final String rawValue;

  /// Convert to string representation (returns rawValue)
  @override
  String toString() => rawValue;

  /// Create WalletClientType from string value
  static WalletClientType? fromString(String? value) {
    if (value == null) return null;
    for (WalletClientType type in WalletClientType.values) {
      if (type.rawValue == value) {
        return type;
      }
    }
    return WalletClientType.other;
  }

  /// Convert to JSON for sending via Method Channel
  String toJson() => rawValue;

  /// Create WalletClientType from JSON
  static WalletClientType? fromJson(String? json) => fromString(json);
}
