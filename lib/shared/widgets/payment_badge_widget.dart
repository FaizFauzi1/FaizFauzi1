import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/customer/data/providers/customer_provider.dart';
import 'package:eventease/features/customer/presentation/views/customer/customer_installment_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A widget that displays a badge showing the count of overdue or upcoming payments
/// Tapping the badge navigates to the CustomerInstallmentScreen
class PaymentBadgeWidget extends StatefulWidget {
  final bool showUpcoming; // If true, shows upcoming payments; if false, shows late payments
  final double size;
  final Color? badgeColor;

  const PaymentBadgeWidget({
    Key? key,
    this.showUpcoming = false,
    this.size = 20,
    this.badgeColor,
  }) : super(key: key);

  @override
  State<PaymentBadgeWidget> createState() => _PaymentBadgeWidgetState();
}

class _PaymentBadgeWidgetState extends State<PaymentBadgeWidget> {
  int _count = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentCount();
  }

  Future<void> _loadPaymentCount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _count = 0;
          _isLoading = false;
        });
        return;
      }

      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final summary = await customerProvider.getInstallmentPaymentSummary(userId);

      setState(() {
        if (widget.showUpcoming) {
          _count = summary['total_pending_payments'] as int;
        } else {
          _count = summary['total_late_payments'] as int;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading payment count: $e');
      setState(() {
        _count = 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _count == 0) {
      return const SizedBox.shrink();
    }

    final badgeColor = widget.badgeColor ?? 
        (widget.showUpcoming ? Colors.orange : Colors.red);

    return GestureDetector(
      onTap: () {
        final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerInstallmentScreen(customerId: userId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.showUpcoming ? Icons.schedule : Icons.warning,
              color: Colors.white,
              size: widget.size,
            ),
            const SizedBox(width: 4),
            Text(
              '$_count',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.size * 0.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple circular badge that shows a count
/// Used for displaying payment counts in compact spaces
class PaymentCountBadge extends StatelessWidget {
  final int count;
  final Color color;
  final double size;

  const PaymentCountBadge({
    Key? key,
    required this.count,
    this.color = Colors.red,
    this.size = 18,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// A widget that displays payment summary information in the drawer header
class DrawerPaymentSummary extends StatefulWidget {
  const DrawerPaymentSummary({Key? key}) : super(key: key);

  @override
  State<DrawerPaymentSummary> createState() => _DrawerPaymentSummaryState();
}

class _DrawerPaymentSummaryState extends State<DrawerPaymentSummary> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final summary = await customerProvider.getInstallmentPaymentSummary(userId);

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading payment summary: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _summary == null) {
      return const SizedBox.shrink();
    }

    final hasPayments = (_summary!['active_installment_plans'] as int) > 0;
    if (!hasPayments) {
      return const SizedBox.shrink();
    }

    final lateCount = _summary!['total_late_payments'] as int;
    final pendingCount = _summary!['total_pending_payments'] as int;

    return GestureDetector(
      onTap: () {
        final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
        Navigator.pop(context); // Close drawer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerInstallmentScreen(customerId: userId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.payment, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Plans',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_summary!['active_installment_plans']} active',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (lateCount > 0)
              PaymentCountBadge(count: lateCount, color: Colors.red),
            if (lateCount > 0 && pendingCount > 0)
              const SizedBox(width: 6),
            if (pendingCount > 0)
              PaymentCountBadge(count: pendingCount, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}
