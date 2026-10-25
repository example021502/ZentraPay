import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The shared hero header for every section: flat primary pink (a darkened
/// pink in dark mode) with a glass icon badge, so each section looks like part
/// of the same family but carries its own icon, title and optional [child]
/// (stats, tabs, a rate card, a balance...).
///
/// Used together with [SectionSheet] - the white rounded sheet that follows it.
class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  final bool showBack;
  final VoidCallback? onBack;

  /// Buttons shown at the top right (help, history, ...).
  final List<Widget> actions;

  /// Extra content under the title (stat chips, a tab strip, a hero card).
  final Widget? child;

  /// Height of the white rounded edge painted along the header's bottom, so
  /// the sheet below appears to slide up over the gradient.
  final double bottomOverlap;

  /// Colour of the sheet that follows; match the screen body behind it.
  final Color? sheetColor;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle = '',
    this.showBack = false,
    this.onBack,
    this.actions = const [],
    this.child,
    this.bottomOverlap = 24,
    this.sheetColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.headerPink,
      child: ClipRect(
        child: Stack(
          children: [
            // The sheet's rounded top edge, drawn over the header.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bottomOverlap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: sheetColor ?? AppTheme.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(bottomOverlap),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  AppTheme.spacingSm,
                  AppTheme.spacingMd,
                  AppTheme.spacingMd + bottomOverlap,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBack || actions.isNotEmpty)
                      Row(
                        children: [
                          if (showBack)
                            SectionHeaderButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap:
                                  onBack ?? () => Navigator.maybePop(context),
                            ),
                          const Spacer(),
                          ...actions.map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: a,
                            ),
                          ),
                        ],
                      ),
                    if (showBack || actions.isNotEmpty)
                      const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.glassSurfaceStrong,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg,
                            ),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Icon(
                            icon,
                            color: AppTheme.textBlack,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.whiteHeadline.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.whiteBodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (child != null) ...[
                      const SizedBox(height: AppTheme.spacingMd),
                      child!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The back arrow of a sub-section: just the icon, no container.
class SectionBackArrow extends StatelessWidget {
  final VoidCallback? onTap;

  const SectionBackArrow({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap ?? () => Navigator.maybePop(context),
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Icon(Icons.arrow_back, color: AppTheme.textBlack, size: 24),
      ),
    );
  }
}

/// Small glass circle button for [SectionHeader.actions] / the back arrow.
class SectionHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const SectionHeaderButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppTheme.glassSurfaceStrong,
      shape: CircleBorder(side: BorderSide(color: AppTheme.glassBorder)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppTheme.textBlack, size: 20),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// The white sheet that follows a [SectionHeader] (whose bottom edge already
/// draws the rounded top). It ALWAYS keeps [topPadding] of breathing room above
/// its first child, so content never touches the rounded edge.
class SectionSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double topPadding;

  /// Defaults to the surface colour; match the header's `sheetColor`.
  final Color? color;

  const SectionSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(15, 0, 15, 15),
    this.topPadding = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color ?? AppTheme.surface,
      child: Padding(
        padding: padding.add(EdgeInsets.only(top: topPadding)),
        child: child,
      ),
    );
  }
}

/// Scrolling page for a section: the [header] on top and the [sheet] below it,
/// where the sheet always stretches to the bottom of the screen. With little
/// content the sheet is padded out to the screen bottom instead of ending
/// part-way up and exposing the page behind it.
class SectionScrollView extends StatelessWidget {
  final Widget header;

  /// Normally a [SectionSheet].
  final Widget sheet;
  final ScrollPhysics? physics;
  final Future<void> Function()? onRefresh;

  const SectionScrollView({
    super.key,
    required this.header,
    required this.sheet,
    this.physics,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final scroll = CustomScrollView(
      physics: onRefresh != null
          ? const AlwaysScrollableScrollPhysics()
          : physics,
      slivers: [
        SliverToBoxAdapter(child: header),
        SliverFillRemaining(hasScrollBody: false, child: sheet),
      ],
    );
    if (onRefresh == null) return scroll;
    return RefreshIndicator(
      color: AppTheme.primaryPink,
      backgroundColor: AppTheme.surface,
      onRefresh: onRefresh!,
      child: scroll,
    );
  }
}
