import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/notification.dart';
import 'package:zentrapay_application/core/repositories/notifications_repository.dart';
import 'package:zentrapay_application/core/repositories/user_profile_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// Notification-bell overlay — same slide-up-from-the-bottom sheet as the
/// History overlay (`showAppOverlaySheet`), listing real notifications from
/// `/api/notifications`. A tier-upgrade nudge is pinned at the top whenever
/// the cached profile's `kycTier < 2` — computed client-side from data
/// already on hand rather than a stored notification row, so it's always
/// accurate and never needs its own dedup/expiry bookkeeping.
void showNotificationsOverlay(BuildContext context, {VoidCallback? onUpgrade}) {
  showAppOverlaySheet(
    context: context,
    builder: (context) => _NotificationsOverlayContent(onUpgrade: onUpgrade),
  );
}

class _NotificationsOverlayContent extends StatefulWidget {
  final VoidCallback? onUpgrade;

  const _NotificationsOverlayContent({this.onUpgrade});

  @override
  State<_NotificationsOverlayContent> createState() =>
      _NotificationsOverlayContentState();
}

class _NotificationsOverlayContentState
    extends State<_NotificationsOverlayContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationsRepository.instance.ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        NotificationsRepository.instance,
        UserProfileRepository.instance,
      ]),
      builder: (context, _) {
        final repo = NotificationsRepository.instance;
        final notifications = repo.data ?? [];
        final tier = UserProfileRepository.instance.user?.kycTier ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Notifications", style: AppTheme.headlineMedium),
              const SizedBox(height: AppTheme.spacingMd),
              if (tier < 2) ...[
                _TierUpgradeCard(tier: tier, onUpgrade: widget.onUpgrade),
                const SizedBox(height: AppTheme.spacingMd),
              ],
              Expanded(
                child: repo.isLoading && notifications.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : notifications.isEmpty
                    ? Center(
                        child: Text(
                          "You're all caught up",
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.gray500,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppTheme.spacingSm),
                        itemBuilder: (context, index) =>
                            _NotificationTile(notification: notifications[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TierUpgradeCard extends StatelessWidget {
  final int tier;
  final VoidCallback? onUpgrade;

  const _TierUpgradeCard({required this.tier, this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).maybePop();
        onUpgrade?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.warningOrange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: AppTheme.warningOrange.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: AppTheme.warningOrange,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're Tier $tier",
                    style: AppTheme.labelLarge.copyWith(
                      color: AppTheme.warningOrange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Complete your profile & verification (Tier 2) to send or receive money",
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.gray700),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.warningOrange),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  IconData get _icon {
    switch (notification.type.toUpperCase()) {
      case 'TRANSFER':
        return Icons.swap_horiz;
      case 'SYSTEM':
        return Icons.info_outline;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          NotificationsRepository.instance.markRead(notification.notificationId);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppTheme.gray50
              : AppTheme.primaryPink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, color: AppTheme.secondaryNavy),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: AppTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.gray700),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryPink,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
