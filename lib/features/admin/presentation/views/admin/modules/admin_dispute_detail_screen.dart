import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/currency_formatter.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';
import 'package:eventease/features/admin/data/providers/admin_disputes_provider.dart';
import 'package:eventease/shared/widgets/design_system/premium_widgets.dart';

/// Dispute detail with evidence timeline and refund workflow.
class AdminDisputeDetailScreen extends StatefulWidget {
  final String disputeId;

  const AdminDisputeDetailScreen({super.key, required this.disputeId});

  @override
  State<AdminDisputeDetailScreen> createState() => _AdminDisputeDetailScreenState();
}

class _AdminDisputeDetailScreenState extends State<AdminDisputeDetailScreen> {
  final _decisionController = TextEditingController();
  final _refundController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDisputesProvider>().loadDisputeDetail(widget.disputeId);
    });
  }

  @override
  void dispose() {
    _decisionController.dispose();
    _refundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDisputesProvider>();
    final dispute = provider.selected;

    if (dispute == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispute Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Case ${dispute.caseId}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
        children: [
          Row(
            children: [
              Expanded(child: Text(dispute.parties, style: EEDesignTokens.titleLarge)),
              PillBadge(label: dispute.status, color: AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 8),
          Text('Severity: ${dispute.severity}', style: EEDesignTokens.bodyMedium),
          if (dispute.comments != null) ...[
            const SizedBox(height: 8),
            Text(dispute.comments!, style: EEDesignTokens.bodyMedium),
          ],
          const Divider(height: 32),
          Text('Evidence Timeline', style: EEDesignTokens.headlineMedium),
          const SizedBox(height: 12),
          ...dispute.evidence.map(_evidenceTile),
          const Divider(height: 32),
          Text('Admin Decision', style: EEDesignTokens.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _decisionController,
            decoration: const InputDecoration(
              labelText: 'Decision notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _refundController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Refund amount (${CurrencyFormatter.symbol})',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final refund = double.tryParse(_refundController.text);
                    await provider.resolveDispute(
                      dispute.id,
                      decision: _decisionController.text,
                      refundAmount: refund,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dispute resolved')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Resolve & Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _evidenceTile(DisputeEvidence e) {
    final icon = switch (e.evidenceType) {
      'chat' => Icons.chat,
      'payment' => Icons.payment,
      'contract' => Icons.description,
      _ => Icons.attach_file,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(e.title),
        subtitle: Text(e.content ?? ''),
        trailing: Text(
          '${e.createdAt.day}/${e.createdAt.month}',
          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
        ),
      ),
    );
  }
}
