import 'package:flutter/material.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';

/// Event context header shown at top of chat conversations.
class ChatEventContextHeader extends StatelessWidget {
  final String eventName;
  final DateTime? eventDate;
  final String? bookingStatus;
  final String? quoteStatus;
  final VoidCallback? onViewQuote;
  final VoidCallback? onPayDeposit;

  const ChatEventContextHeader({
    super.key,
    required this.eventName,
    this.eventDate,
    this.bookingStatus,
    this.quoteStatus,
    this.onViewQuote,
    this.onPayDeposit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        boxShadow: EEDesignTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eventName, style: EEDesignTokens.titleLarge),
          if (eventDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Event: ${_formatDate(eventDate!)}',
              style: EEDesignTokens.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
            ),
          ],
          if (bookingStatus != null || quoteStatus != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (bookingStatus != null) _chip('Booking: $bookingStatus'),
                if (quoteStatus != null) _chip('Quote: $quoteStatus'),
              ],
            ),
          ],
          if (onViewQuote != null || onPayDeposit != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onViewQuote != null)
                  Expanded(
                    child: OutlinedButton(onPressed: onViewQuote, child: const Text('View Quote')),
                  ),
                if (onViewQuote != null && onPayDeposit != null) const SizedBox(width: 8),
                if (onPayDeposit != null)
                  Expanded(
                    child: ElevatedButton(onPressed: onPayDeposit, child: const Text('Pay Deposit')),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(EEDesignTokens.radiusPill),
      ),
      child: Text(label, style: EEDesignTokens.labelMedium.copyWith(color: AppTheme.primaryColor)),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}
