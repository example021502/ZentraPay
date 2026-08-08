import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Placeholder for the Merchant tab — content to be added later.
class Settings extends StatelessWidget {
  const Settings({super.key});

  static const List<Map<String, dynamic>> settingsButtons = [
    {
      "title": "GENERAL",
      "buttons": [
        {"name": "Account", "icon": Icons.person},
        {"name": "Notifications", "icon": Icons.notifications},
        {"name": "Support", "icon": Icons.support_agent},
        {"name": "Logout", "icon": Icons.exit_to_app},
        {"name": "Delete Account", "icon": Icons.delete},
      ],
    },
    {
      "title": "FEEDBACK",
      "buttons": [
        {"name": "Report a bug", "icon": Icons.warning_amber},
        {"name": "Send feedback", "icon": Icons.send},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.gray50,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 30.0,
                  horizontal: 15.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Icon(
                        Icons.arrow_back,
                        size: 22,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingLg),
                    Text("Settings", style: AppTheme.headlineLarge),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: settingsButtons.map((section) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          section["title"],
                          style: AppTheme.headlineSmall.copyWith(
                            color: AppTheme.textBlack.withAlpha(80),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: section["buttons"].length,
                            separatorBuilder: (context, index) =>
                                AppTheme.divider(context, AppTheme.lightGrey),
                            itemBuilder: (context, index) {
                              final buttonData = section["buttons"][index];
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  leading: Icon(buttonData["icon"]),
                                  title: Text(buttonData["name"]),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                  ),
                                  onTap: () {},
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}