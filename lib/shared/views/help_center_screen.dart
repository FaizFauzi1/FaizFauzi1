import 'package:flutter/material.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';
import 'package:eventease/shared/widgets/design_system/state_widgets.dart';

/// Universal help center for customers, vendors, and admins.
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _categories = [
    ('Booking Help', Icons.event, 'How to book vendors and manage reservations'),
    ('Billing & Payments', Icons.payment, 'Deposits, installments, refunds'),
    ('Account & Security', Icons.security, 'Login, password, biometrics'),
    ('Vendor Help', Icons.store, 'Onboarding, payouts, services'),
    ('Disputes & Support', Icons.support_agent, 'Report issues and track tickets'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _categories.where((c) =>
        _query.isEmpty || c.$1.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search help articles…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(EEDesignTokens.radiusMd)),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: EEDesignTokens.spaceLg),
          if (filtered.isEmpty)
            const EmptyStateWidget(
              icon: Icons.search_off,
              title: 'No results',
              message: 'Try a different search term or browse categories below.',
            )
          else
            ...filtered.map((cat) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(cat.$2, color: AppTheme.primaryColor),
                    title: Text(cat.$1, style: EEDesignTokens.titleLarge.copyWith(fontSize: 16)),
                    subtitle: Text(cat.$3),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                )),
          const SizedBox(height: EEDesignTokens.spaceLg),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat),
            label: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
