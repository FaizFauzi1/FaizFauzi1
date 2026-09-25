import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/booth.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/models/expo_lead.dart';

class OrganizerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const OrganizerAppBar({super.key, required this.title, this.actions, this.bottom});

  @override
  Size get preferredSize => Size.fromHeight(bottom != null ? 96 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      actions: actions,
      bottom: bottom,
    );
  }
}

class BoothStatusChip extends StatelessWidget {
  final BoothStatus status;
  const BoothStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BoothStatus.available => ('Available', AppTheme.successColor),
      BoothStatus.pending => ('Pending', AppTheme.warningColor),
      BoothStatus.booked => ('Booked', AppTheme.primaryColor),
    };
    return _Chip(label: label, color: color);
  }
}

class ExhibitorStatusChip extends StatelessWidget {
  final ExhibitorStatus status;
  const ExhibitorStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ExhibitorStatus.pending => ('Pending', AppTheme.warningColor),
      ExhibitorStatus.underReview => ('Under Review', Colors.indigo),
      ExhibitorStatus.infoRequested => ('Info Requested', Colors.amber.shade900),
      ExhibitorStatus.approved => ('Approved', AppTheme.successColor),
      ExhibitorStatus.paymentPending => ('Payment Due', Colors.deepOrange),
      ExhibitorStatus.confirmed => ('Confirmed', const Color(0xFF10B981)),
      ExhibitorStatus.completed => ('Completed', Colors.blueGrey),
      ExhibitorStatus.rejected => ('Rejected', AppTheme.errorColor),
    };
    return _Chip(label: label, color: color);
  }
}

class PaymentStatusChip extends StatelessWidget {
  final PaymentStatus status;
  const PaymentStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PaymentStatus.paid => ('Paid', AppTheme.successColor),
      PaymentStatus.partial => ('Partial', AppTheme.warningColor),
      PaymentStatus.unpaid => ('Unpaid', AppTheme.errorColor),
    };
    return _Chip(label: label, color: color);
  }
}

class LeadTemperatureChip extends StatelessWidget {
  final LeadTemperature temp;
  const LeadTemperatureChip({super.key, required this.temp});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (temp) {
      LeadTemperature.hot => ('Hot', Colors.redAccent),
      LeadTemperature.warm => ('Warm', AppTheme.warningColor),
      LeadTemperature.cold => ('Cold', Colors.blueGrey),
    };
    return _Chip(label: label, color: color);
  }
}

class LeadStageChip extends StatelessWidget {
  final LeadStage stage;
  const LeadStageChip({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final label = switch (stage) {
      LeadStage.newLead => 'New',
      LeadStage.contacted => 'Contacted',
      LeadStage.followedUp => 'Followed up',
      LeadStage.converted => 'Converted',
      LeadStage.lost => 'Lost',
    };
    final color = switch (stage) {
      LeadStage.newLead => AppTheme.primaryColor,
      LeadStage.contacted => Colors.blue,
      LeadStage.followedUp => AppTheme.warningColor,
      LeadStage.converted => AppTheme.successColor,
      LeadStage.lost => AppTheme.errorColor,
    };
    return _Chip(label: label, color: color);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class OrganizerFilterChips extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const OrganizerFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[i]),
              selected: selected,
              onSelected: (_) => onSelected(i),
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              checkmarkColor: AppTheme.primaryColor,
            ),
          );
        }),
      ),
    );
  }
}

class OrganizerScannerPanel extends StatelessWidget {
  final String hint;
  final VoidCallback onSimulate;

  const OrganizerScannerPanel({super.key, required this.hint, required this.onSimulate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryColor, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.qr_code_scanner, size: 80, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 20),
          Text(hint, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onSimulate,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            icon: const Icon(Icons.flash_on),
            label: const Text('Simulate scan (preview)'),
          ),
        ],
      ),
    );
  }
}
