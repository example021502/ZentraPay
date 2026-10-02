import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/features/Settings/widgets/section_label.dart';
import 'package:zentrapay_application/features/home/closeConfirmation.dart';

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
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionLabel(title),
        const SizedBox(height: 4),
        // Card decoration removed completely and layout wrapped in a compact Column
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(buttons.length, (index) {
            final buttonData = buttons[index];
            final bool isLogout = buttonData['name'] == "Logout";
            final bool isRedColored =
                isLogout || buttonData['name'] == "Delete Account";

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      buttonData["icon"],
                      color: isRedColored ? AppColors.main : AppTheme.textBlack,
                    ),
                    title: Text(
                      buttonData["name"],
                      style: TextStyle(
                        color: isRedColored
                            ? AppColors.main
                            : AppTheme.textBlack,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: isLogout
                        ? () => _logout(context)
                        : () => onTapOption(context, buttonData["name"]),
                  ),
                ),
                if (index < buttons.length - 1)
                  AppTheme.divider(context, AppTheme.lightGrey),
              ],
            );
          }),
        ),
      ],
    );
  }
}
