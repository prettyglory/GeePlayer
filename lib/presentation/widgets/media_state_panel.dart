import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_colors.dart';

enum MediaViewStatus { loading, empty, error }

class MediaStatePanel extends StatelessWidget {
  const MediaStatePanel({
    required this.status,
    required this.message,
    this.icon,
    this.onRetry,
    this.actionLabel = 'Try again',
    this.onSecondary,
    this.secondaryLabel,
    this.compact = false,
    super.key,
  });

  final MediaViewStatus status;
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String actionLabel;
  final VoidCallback? onSecondary;
  final String? secondaryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visual = switch (status) {
      MediaViewStatus.loading => const CircularProgressIndicator(),
      MediaViewStatus.empty => Icon(
        icon ?? Icons.inbox_outlined,
        size: compact ? 30 : 42,
        color: GeeColors.accentLight,
      ),
      MediaViewStatus.error => Icon(
        icon ?? Icons.error_outline_rounded,
        size: compact ? 30 : 42,
        color: Theme.of(context).colorScheme.error,
      ),
    };

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: compact ? 25 : 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visual,
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: GeeColors.textMuted, height: 1.4),
            ),
            if (onRetry != null || onSecondary != null) ...[
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: [
                  if (onRetry != null)
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(actionLabel),
                    ),
                  if (onSecondary != null)
                    TextButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel ?? 'More options'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
