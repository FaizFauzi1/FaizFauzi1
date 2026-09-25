import 'package:flutter/material.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';

/// Standard empty state with illustration, message, and primary action.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EEDesignTokens.spaceXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(EEDesignTokens.spaceLg),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primaryColor).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: iconColor ?? AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: EEDesignTokens.spaceLg),
            Text(title, style: EEDesignTokens.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: EEDesignTokens.spaceSm),
            Text(
              message,
              style: EEDesignTokens.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: EEDesignTokens.spaceLg),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard error state with retry.
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      iconColor: AppTheme.errorColor,
      title: title,
      message: message,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
    );
  }
}

/// Success confirmation with optional action.
class SuccessStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SuccessStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.check_circle_outline,
      iconColor: AppTheme.successColor,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Offline state with cached-data hint.
class OfflineStateWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineStateWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_outlined,
      iconColor: AppTheme.warningColor,
      title: 'You\'re offline',
      message: 'Some features are unavailable. Cached planning data is still accessible.',
      actionLabel: onRetry != null ? 'Retry Connection' : null,
      onAction: onRetry,
    );
  }
}
