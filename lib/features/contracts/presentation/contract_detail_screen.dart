import 'package:flutter/material.dart';

import 'package:eventease/core/utils/ee_design_tokens.dart';

/// Digital contract with e-signature status tracking.
class ContractDetailScreen extends StatelessWidget {
  final String contractTitle;

  const ContractDetailScreen({super.key, this.contractTitle = 'Service Agreement'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contractTitle)),
      body: ListView(
        padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
        children: [
          _buildSignatureProgress(),
          const SizedBox(height: 24),
          const Text('Contract Terms', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
            'This agreement outlines the services, payment schedule, cancellation policy, and deliverables for your event booking through EventEase.',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.draw),
                  label: const Text('Sign Contract'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signature Status', style: EEDesignTokens.titleLarge),
            const SizedBox(height: 16),
            _sigRow('Vendor', signed: true),
            _sigRow('Customer', signed: false),
          ],
        ),
      ),
    );
  }

  Widget _sigRow(String party, {required bool signed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(signed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: signed ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          Text(party),
          const Spacer(),
          Text(signed ? 'Signed' : 'Pending',
              style: TextStyle(color: signed ? Colors.green : Colors.orange)),
        ],
      ),
    );
  }
}
