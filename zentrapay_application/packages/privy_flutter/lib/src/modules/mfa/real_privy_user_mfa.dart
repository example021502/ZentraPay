import 'package:privy_flutter/src/modules/mfa/privy_user_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/sms/privy_user_sms_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/sms/real_privy_user_sms_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/totp/privy_user_totp_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/totp/real_privy_user_totp_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/privy_user_passkeys_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/real_privy_user_passkeys_mfa.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';

/// Implementation of [PrivyUserMfa].
class RealPrivyUserMfa implements PrivyUserMfa {
  @override
  final PrivyUserTotpMfa totp;

  @override
  final PrivyUserSmsMfa sms;

  @override
  final PrivyUserPasskeysMfa passkeys;

  /// Constructor that initializes all MFA sub-modules.
  RealPrivyUserMfa(MethodChannelHandler channelHandler)
      : totp = RealPrivyUserTotpMfa(channelHandler),
        sms = RealPrivyUserSmsMfa(channelHandler),
        passkeys = RealPrivyUserPasskeysMfa(channelHandler);
}
