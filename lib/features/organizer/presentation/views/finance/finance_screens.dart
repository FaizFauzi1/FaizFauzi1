import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/expo_summary.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:intl/intl.dart';

class RevenueDashboardScreen extends StatelessWidget {
  const RevenueDashboardScreen({super.key});
  static const routeName = '/organizer/revenue-dashboard';

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final expos = ExpoSummary.sampleData();
    final total = expos.fold<double>(0, (s, e) => s + e.revenueRm);
    final booth = total * 0.68;
    final tickets = total * 0.24;
    final sponsor = total * 0.08;

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Revenue Dashboard'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppTheme.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total revenue', style: TextStyle(color: Colors.white70)),
                    Text(currency.format(total), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _RevenueBar('Booth sales', booth, total, AppTheme.primaryColor, currency),
            _RevenueBar('Ticket sales', tickets, total, AppTheme.secondaryColor, currency),
            _RevenueBar('Sponsorship', sponsor, total, AppTheme.accentColor, currency),
            const SizedBox(height: 20),
            const Text('By expo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...expos.map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${e.boothsBooked}/${e.boothCapacity} booths'),
                    trailing: Text(currency.format(e.revenueRm), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _RevenueBar extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;
  final NumberFormat currency;
  const _RevenueBar(this.label, this.amount, this.total, this.color, this.currency);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(currency.format(amount), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: total > 0 ? amount / total : 0, backgroundColor: AppTheme.borderColor, color: color, minHeight: 6, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});
  static const routeName = '/organizer/expense-tracker';

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  int _filter = 0;
  final _expenses = [
    _Expense('Venue rental – MITEC', 'Venue', 85000, DateTime.now().subtract(const Duration(days: 5))),
    _Expense('Facebook & Instagram ads', 'Marketing', 12500, DateTime.now().subtract(const Duration(days: 3))),
    _Expense('Staff wages (expo day)', 'Staff', 18000, DateTime.now().subtract(const Duration(days: 1))),
    _Expense('Security & crowd control', 'Operations', 6500, DateTime.now()),
    _Expense('Printing & signage', 'Marketing', 4200, DateTime.now()),
  ];

  List<_Expense> get _filtered {
    if (_filter == 0) return _expenses;
    const cats = ['All', 'Venue', 'Marketing', 'Staff', 'Operations'];
    final cat = cats[_filter];
    return _expenses.where((e) => e.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final total = _expenses.fold<double>(0, (s, e) => s + e.amountRm);
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Expense Tracker'),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: AppTheme.primaryColor, child: const Icon(Icons.add)),
      body: OrganizerScreenBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Total expenses', style: TextStyle(color: AppTheme.textSecondaryColor)),
                  const Spacer(),
                  Text(currency.format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
            ),
            OrganizerFilterChips(labels: const ['All', 'Venue', 'Marketing', 'Staff', 'Operations'], selectedIndex: _filter, onSelected: (i) => setState(() => _filter = i)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final e = _filtered[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(e.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${e.category} · ${DateFormat('d MMM yyyy').format(e.date)}'),
                      trailing: Text(currency.format(e.amountRm), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.errorColor)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Expense {
  final String label;
  final String category;
  final double amountRm;
  final DateTime date;
  const _Expense(this.label, this.category, this.amountRm, this.date);
}

class ProfitPerExpoScreen extends StatelessWidget {
  const ProfitPerExpoScreen({super.key});
  static const routeName = '/organizer/profit-per-expo';

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final expos = ExpoSummary.sampleData();
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Profit Per Expo'),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expos.length,
          itemBuilder: (context, i) {
            final e = expos[i];
            final expenses = e.revenueRm * 0.42;
            final profit = e.revenueRm - expenses;
            final margin = e.revenueRm > 0 ? profit / e.revenueRm : 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _ProfitRow('Revenue', currency.format(e.revenueRm)),
                    _ProfitRow('Expenses (est.)', currency.format(expenses)),
                    const Divider(),
                    _ProfitRow('Net profit', currency.format(profit), bold: true, color: profit >= 0 ? AppTheme.successColor : AppTheme.errorColor),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: margin.clamp(0.0, 1.0).toDouble(), backgroundColor: AppTheme.borderColor, color: AppTheme.successColor, minHeight: 6, borderRadius: BorderRadius.circular(4)),
                    Text('${(margin * 100).toStringAsFixed(1)}% margin', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfitRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _ProfitRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});
  static const routeName = '/organizer/invoice-management';

  @override
  State<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  int _filter = 0;
  final _invoices = [
    _Invoice('INV-2026-0142', 'Elegant Dining Solutions', 'Vendor booth', 8500, 'Paid'),
    _Invoice('INV-2026-0143', 'Capture Moments', 'Vendor booth', 6200, 'Unpaid'),
    _Invoice('INV-2026-0144', 'Maybank', 'Platinum sponsor', 85000, 'Paid'),
    _Invoice('INV-2026-0145', 'Royal Feast Caterers', 'Vendor booth', 8500, 'Partial'),
  ];

  List<_Invoice> get _filtered {
    if (_filter == 0) return _invoices;
    const statuses = ['All', 'Paid', 'Unpaid', 'Partial'];
    return _invoices.where((inv) => inv.status == statuses[_filter]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Invoice Management'),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: AppTheme.primaryColor, child: const Icon(Icons.add)),
      body: OrganizerScreenBody(
        child: Column(
          children: [
            OrganizerFilterChips(labels: const ['All', 'Paid', 'Unpaid', 'Partial'], selectedIndex: _filter, onSelected: (i) => setState(() => _filter = i)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final inv = _filtered[i];
                  final color = switch (inv.status) {
                    'Paid' => AppTheme.successColor,
                    'Partial' => AppTheme.warningColor,
                    _ => AppTheme.errorColor,
                  };
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(inv.party, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${inv.id} · ${inv.type}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currency.format(inv.amountRm), style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(inv.status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Invoice {
  final String id;
  final String party;
  final String type;
  final double amountRm;
  final String status;
  const _Invoice(this.id, this.party, this.type, this.amountRm, this.status);
}

class PaymentTrackingScreen extends StatefulWidget {
  const PaymentTrackingScreen({super.key});
  static const routeName = '/organizer/payment-tracking';

  @override
  State<PaymentTrackingScreen> createState() => _PaymentTrackingScreenState();
}

class _PaymentTrackingScreenState extends State<PaymentTrackingScreen> {
  int _filter = 0;
  final _payments = [
    _Payment('Capture Moments', 'Booth fee', 6200, 'Unpaid', 14),
    _Payment('Lens Artistry', 'Booth fee', 8500, 'Partial', 7),
    _Payment('Gourmet Delights', 'Booth fee', 8500, 'Unpaid', 21),
    _Payment('Tropicana', 'Sponsor fee', 18000, 'Unpaid', 30),
    _Payment('Elegant Dining Solutions', 'Booth fee', 8500, 'Paid', 0),
  ];

  List<_Payment> get _filtered {
    if (_filter == 0) return _payments;
    const statuses = ['All', 'Paid', 'Unpaid', 'Partial'];
    return _payments.where((p) => p.status == statuses[_filter]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final outstanding = _payments.where((p) => p.status != 'Paid').fold<double>(0, (s, p) => s + p.amountRm);
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Payment Tracking'),
      body: OrganizerScreenBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                child: ListTile(
                  leading: const Icon(Icons.warning_amber, color: AppTheme.warningColor),
                  title: Text('Outstanding: ${currency.format(outstanding)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${_payments.where((p) => p.status != 'Paid').length} pending payments'),
                ),
              ),
            ),
            OrganizerFilterChips(labels: const ['All', 'Paid', 'Unpaid', 'Partial'], selectedIndex: _filter, onSelected: (i) => setState(() => _filter = i)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final p = _filtered[i];
                  final color = switch (p.status) {
                    'Paid' => AppTheme.successColor,
                    'Partial' => AppTheme.warningColor,
                    _ => AppTheme.errorColor,
                  };
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(p.party, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${p.type}${p.daysOverdue > 0 ? ' · ${p.daysOverdue} days overdue' : ''}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currency.format(p.amountRm), style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(p.status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder sent to ${p.party}'))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Payment {
  final String party;
  final String type;
  final double amountRm;
  final String status;
  final int daysOverdue;
  const _Payment(this.party, this.type, this.amountRm, this.status, this.daysOverdue);
}
