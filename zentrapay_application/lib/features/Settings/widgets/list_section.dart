import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/features/Settings/widgets/section_label.dart';
import 'package:zentrapay_application/features/Settings/widgets/settings_card.dart';
import 'package:zentrapay_application/features/home/close_confirmation.dart';

/// A titled, compact list of settings rows — the GENERAL, FEEDBACK and
/// DANGER ZONE blocks.
///
/// Every entry in [buttons] is a `{"name": String, "icon": IconData}` map.
/// "Logout" and "Delete Account" are tinted with [AppColors.main] to read as
/// destructive/terminal actions. Tapping a row either:
///  * runs the "Logout" row's own confirm-then-`/login` flow (the dialog is
///    where the token is actually wiped, see `showCloseConfirmationDialog`), or
///  * forwards the row name to [onTapOption] for the parent to render.
class ListSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> buttons;
  final void Function(BuildContext context, String option) onTapOption;

  const ListSection({
    super.key,
    required this.title,
    required this.buttons,
    required this.onTapOption,
  });

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showCloseConfirmationDialog(context);
    if (!context.mounted || !confirmed) return;
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionLabel(title),
        const SizedBox(height: 4),
        SettingsCard(
          children: [
            for (final buttonData in buttons)
              SettingsNavTile(
                icon: buttonData["icon"] as IconData,
                title: buttonData["name"] as String,
                color:
                    (buttonData['name'] == "Logout" ||
                        buttonData['name'] == "Delete Account")
                    ? AppColors.main
                    : null,
                onTap: buttonData['name'] == "Logout"
                    ? () => _logout(context)
                    : () => onTapOption(context, buttonData["name"]),
              ),
          ],
        ),
      ],
    );
  }
}
