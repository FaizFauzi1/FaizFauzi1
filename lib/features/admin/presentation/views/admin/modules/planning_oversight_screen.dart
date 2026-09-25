import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminPlanningOversightScreen extends StatelessWidget {
  const AdminPlanningOversightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Planning Oversight',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('💰 Budgets'),
            if (admin.budgets.isEmpty) _emptyState("No budgets available yet."),
            ...admin.budgets.map((b) =>
                _budgetCard(b.couple, b.spent.toDouble(), b.total.toDouble())),
            const SizedBox(height: 20),
            _sectionTitle('🎟️ RSVP & Seating'),
            if (admin.rsvps.isEmpty) _emptyState("No RSVP data yet."),
            ...admin.rsvps
                .map((r) => _rsvpCard(r.event, r.yes, r.no, r.pending)),
            const SizedBox(height: 20),
            _sectionTitle('💡 Suggestions'),
            if (admin.suggestions.isEmpty) _emptyState("No suggestions yet."),
            ...admin.suggestions
                .map((s) => _suggestionCard(s.couple, s.suggestion)),
          ],
        ),
      ),
    );
  }

  /// Section Title
  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );

  /// Empty State
  Widget _emptyState(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );

  /// Budget Card with Progress Bar
  Widget _budgetCard(String couple, double spent, double total) {
    final progress = (spent / total).clamp(0, 1.0);
    final percent = (progress * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: const Icon(Icons.account_balance_wallet,
                    color: Colors.green),
              ),
              title: Text(couple,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text("RM $spent / RM $total"),
              trailing: Text("$percent%",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress.toDouble(),
              backgroundColor: Colors.grey[300],
              color: progress > 0.8 ? Colors.red : Colors.green,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }

  /// RSVP Card with Chips
  Widget _rsvpCard(String event, int yes, int no, int pending) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(Icons.event_seat, color: Colors.blue),
              ),
              title: Text(event,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("RSVP Breakdown"),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar:
                      const Icon(Icons.check, color: Colors.white, size: 18),
                  label: Text("Yes $yes"),
                  backgroundColor: Colors.green,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                Chip(
                  avatar:
                      const Icon(Icons.close, color: Colors.white, size: 18),
                  label: Text("No $no"),
                  backgroundColor: Colors.red,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                Chip(
                  avatar: const Icon(Icons.hourglass_empty,
                      color: Colors.white, size: 18),
                  label: Text("Pending $pending"),
                  backgroundColor: Colors.orange,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// Suggestion Card
  Widget _suggestionCard(String couple, String suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber.withOpacity(0.2),
                  child: const Icon(Icons.lightbulb, color: Colors.amber),
                ),
                const SizedBox(width: 10),
                Text(couple,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(10),
              child: Text(
                suggestion,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
