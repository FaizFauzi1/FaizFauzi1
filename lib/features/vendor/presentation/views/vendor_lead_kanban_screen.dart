import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';

enum LeadStage { newLead, quoteSent, depositPaid, completed }

class VendorLead {
  final String id;
  final String customerName;
  final String eventType;
  final DateTime eventDate;
  final double estimatedValue;
  LeadStage stage;

  VendorLead({
    required this.id,
    required this.customerName,
    required this.eventType,
    required this.eventDate,
    required this.estimatedValue,
    this.stage = LeadStage.newLead,
  });
}

/// Kanban lead management for vendor dashboard.
class VendorLeadKanbanScreen extends StatefulWidget {
  const VendorLeadKanbanScreen({super.key});

  @override
  State<VendorLeadKanbanScreen> createState() => _VendorLeadKanbanScreenState();
}

class _VendorLeadKanbanScreenState extends State<VendorLeadKanbanScreen> {
  final List<VendorLead> _leads = [];
  bool _hasInitializedLeads = false;

  static const _stages = LeadStage.values;
  static const _stageLabels = {
    LeadStage.newLead: 'New Lead',
    LeadStage.quoteSent: 'Quote Sent',
    LeadStage.depositPaid: 'Deposit Paid',
    LeadStage.completed: 'Completed',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final effectiveId = AdminImpersonationService.instance.effectiveUserId ?? auth.userId;
    if (effectiveId != null) {
      await Provider.of<BookingProvider>(context, listen: false).loadVendorBookings(effectiveId);
    }
  }

  LeadStage _mapStatusToStage(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingVendor:
      case BookingStatus.pending:
        return LeadStage.newLead;
      case BookingStatus.awaitingPayment:
      case BookingStatus.changeRequested:
      case BookingStatus.changeApproved:
      case BookingStatus.awaitingAdjustmentPayment:
        return LeadStage.quoteSent;
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
        return LeadStage.depositPaid;
      case BookingStatus.completed:
        return LeadStage.completed;
      default:
        return LeadStage.newLead;
    }
  }

  BookingStatus _mapStageToStatus(LeadStage stage) {
    switch (stage) {
      case LeadStage.newLead:
        return BookingStatus.pendingVendor;
      case LeadStage.quoteSent:
        return BookingStatus.awaitingPayment;
      case LeadStage.depositPaid:
        return BookingStatus.confirmed;
      case LeadStage.completed:
        return BookingStatus.completed;
    }
  }

  void _syncLeadsFromBookings(List<Booking> bookings) {
    _leads.clear();
    for (final b in bookings) {
      if (b.status == BookingStatus.cancelled ||
          b.status == BookingStatus.cancelledByUser ||
          b.status == BookingStatus.cancelledByVendor ||
          b.status == BookingStatus.rejected) {
        continue;
      }
      _leads.add(
        VendorLead(
          id: b.id,
          customerName: b.customerName.isNotEmpty ? b.customerName : 'Customer #${b.id.length > 5 ? b.id.substring(0, 5) : b.id}',
          eventType: b.serviceName.isNotEmpty ? b.serviceName : (b.eventType ?? 'Event Service'),
          eventDate: b.bookingDate,
          estimatedValue: b.amount,
          stage: _mapStatusToStage(b.status),
        ),
      );
    }
    _hasInitializedLeads = true;
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    if (!_hasInitializedLeads && !bookingProvider.isLoading) {
      _syncLeadsFromBookings(bookingProvider.vendorBookings);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lead Pipeline')),
      body: bookingProvider.isLoading && !_hasInitializedLeads
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _hasInitializedLeads = false;
                await _loadData();
                if (mounted) _syncLeadsFromBookings(bookingProvider.vendorBookings);
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 800;
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: constraints.maxHeight,
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _stages.map((stage) => Expanded(child: _buildColumn(stage))).toList(),
                              )
                            : ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
                                children: _stages
                                    .map((stage) => SizedBox(
                                          width: 280,
                                          child: _buildColumn(stage),
                                        ))
                                    .toList(),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildColumn(LeadStage stage) {
    final columnLeads = _leads.where((l) => l.stage == stage).toList();
    return DragTarget<VendorLead>(
      onAcceptWithDetails: (details) async {
        setState(() => details.data.stage = stage);
        await context.read<BookingProvider>().updateBookingStatus(
              details.data.id,
              _mapStageToStatus(stage),
            );
      },
      builder: (context, candidate, rejected) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(EEDesignTokens.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${_stageLabels[stage]} (${columnLeads.length})',
                  style: EEDesignTokens.titleLarge,
                ),
              ),
              Expanded(
                child: columnLeads.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                          child: Text(
                            'No leads in this stage',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: columnLeads.map(_buildLeadCard).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeadCard(VendorLead lead) {
    return Draggable<VendorLead>(
      data: lead,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(EEDesignTokens.radiusMd),
        child: SizedBox(width: 240, child: _cardContent(lead)),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: _cardContent(lead)),
      child: _cardContent(lead),
    );
  }

  Widget _cardContent(VendorLead lead) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lead.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(lead.eventType, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
            const SizedBox(height: 4),
            Text('RM ${lead.estimatedValue.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
