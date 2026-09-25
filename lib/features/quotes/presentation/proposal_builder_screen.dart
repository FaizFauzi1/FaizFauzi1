import 'package:flutter/material.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/currency_formatter.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';
import 'package:eventease/features/quotes/data/models/proposal.dart';

/// Interactive vendor proposal builder with real-time total.
class ProposalBuilderScreen extends StatefulWidget {
  final Proposal? initialProposal;

  const ProposalBuilderScreen({super.key, this.initialProposal});

  @override
  State<ProposalBuilderScreen> createState() => _ProposalBuilderScreenState();
}

class _ProposalBuilderScreenState extends State<ProposalBuilderScreen> {
  late List<ProposalAddon> _addons;
  late double _baseAmount;

  @override
  void initState() {
    super.initState();
    _baseAmount = widget.initialProposal?.baseAmount ?? 5000;
    _addons = widget.initialProposal?.addons ??
        [
          const ProposalAddon(id: '1', name: 'Extra hour coverage', price: 500),
          const ProposalAddon(id: '2', name: 'Drone footage', price: 800),
          const ProposalAddon(id: '3', name: 'Same-day edit', price: 1200),
        ];
  }

  double get _total =>
      _baseAmount + _addons.where((a) => a.selected).fold(0.0, (s, a) => s + a.price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proposal Builder')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
              children: [
                Text('Base Package', style: EEDesignTokens.titleLarge),
                const SizedBox(height: 8),
                Text(CurrencyFormatter.format(_baseAmount),
                    style: EEDesignTokens.headlineMedium.copyWith(color: AppTheme.primaryColor)),
                const SizedBox(height: 24),
                Text('Optional Add-ons', style: EEDesignTokens.titleLarge),
                const SizedBox(height: 8),
                ..._addons.map((addon) => SwitchListTile(
                      title: Text(addon.name),
                      subtitle: Text(CurrencyFormatter.format(addon.price)),
                      value: addon.selected,
                      onChanged: (v) => setState(() {
                        final i = _addons.indexWhere((a) => a.id == addon.id);
                        _addons[i] = addon.copyWith(selected: v);
                      }),
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: EEDesignTokens.elevatedShadow,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total', style: EEDesignTokens.bodyMedium),
                        Text(
                          CurrencyFormatter.format(_total),
                          style: EEDesignTokens.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Proposal sent to customer')),
                      );
                    },
                    child: const Text('Send Proposal'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
