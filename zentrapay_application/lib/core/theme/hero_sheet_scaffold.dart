import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

import 'app_theme.dart';

/// The structural shell shared by every main tab screen: a hero header
/// (typically a [ZentraHeroCard] or a screen-specific variant of it) pinned
/// at the top, followed by a white, rounded-top sheet that always fills the
/// remaining screen height — even when [body]'s content is shorter than the
/// screen, so the page background never peeks out at the bottom — and
/// scrolls normally once [body] grows past the available height.
class HeroSheetScaffold extends StatelessWidget {
  final Widget header;
  final Widget body;
  final EdgeInsetsGeometry bodyPadding;
  final Color backgroundColor;
  final double headerGap;

  const HeroSheetScaffold({
    super.key,
    required this.header,
    required this.body,
    this.bodyPadding = const EdgeInsets.all(15.0),
    this.backgroundColor = AppColors.main,
    this.headerGap = AppTheme.spacingSm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          header,
          SizedBox(height: headerGap),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryWhite,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Padding(padding: bodyPadding, child: body),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
