import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:intl/intl.dart';

class VendorApplicationStatusScreen extends StatefulWidget {
  final ExhibitorVendor application;

  const VendorApplicationStatusScreen({super.key, required this.application});

  static const routeName = '/vendor-application-status';

  @override
  State<VendorApplicationStatusScreen> createState() => _VendorApplicationStatusScreenState();
}

class _VendorApplicationStatusScreenState extends State<VendorApplicationStatusScreen> {
  late ExhibitorVendor _app;
  final _responseCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _app = widget.application;
  }

  @override
  void dispose() {
    _responseCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendInfoResponse() async {
    final text = _responseCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await OrganizerRepository.instance.respondToMoreInfo(_app.id, text);
      if (mounted) {
        setState(() {
          _app = _app.copyWith(
            status: ExhibitorStatus.underReview,
            infoResponseMessage: text,
          );
          _isSending = false;
          _responseCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response sent to organiser'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Application Status'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Event & Package Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _app.expoName ?? 'Expo Application',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoBadge(Icons.workspace_premium, _app.packageName ?? 'Standard'),
                    const SizedBox(width: 10),
                    _infoBadge(Icons.payments, currency.format(_app.boothFeeRm)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _infoBadge(Icons.calendar_today, 'Applied: ${dateFormat.format(_app.appliedAt)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Status Timeline
          const Text(
            'Application Progress',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          _buildStatusTimeline(),
          const SizedBox(height: 24),

          // Organizer Info Request (if applicable)
          if (_app.status == ExhibitorStatus.infoRequested) ...[
            _buildInfoRequestCard(),
            const SizedBox(height: 24),
          ],

          // Approved Celebration (if applicable)
          if (_app.status == ExhibitorStatus.approved || _app.status == ExhibitorStatus.paymentPending) ...[
            _buildApprovalCard(currency, dateFormat),
            const SizedBox(height: 24),
          ],

          // Confirmed Card
          if (_app.status == ExhibitorStatus.confirmed) ...[
            _buildConfirmedCard(),
            const SizedBox(height: 24),
          ],

          // Application Details
          _buildDetailSection(),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final stages = [
      ('Applied', ExhibitorStatus.pending),
      ('Under Review', ExhibitorStatus.underReview),
      ('Approved', ExhibitorStatus.approved),
      ('Payment', ExhibitorStatus.paymentPending),
      ('Confirmed', ExhibitorStatus.confirmed),
    ];

    // Determine current stage index
    int currentIdx = 0;
    if (_app.status == ExhibitorStatus.underReview || _app.status == ExhibitorStatus.infoRequested) {
      currentIdx = 1;
    } else if (_app.status == ExhibitorStatus.approved) {
      currentIdx = 2;
    } else if (_app.status == ExhibitorStatus.paymentPending) {
      currentIdx = 3;
    } else if (_app.status == ExhibitorStatus.confirmed || _app.status == ExhibitorStatus.completed) {
      currentIdx = 4;
    } else if (_app.status == ExhibitorStatus.rejected) {
      currentIdx = -1; // special
    }

    return Column(
      children: List.generate(stages.length, (i) {
        final isComplete = i < currentIdx;
        final isActive = i == currentIdx;
        final isRejected = _app.status == ExhibitorStatus.rejected && i == 1;

        Color dotColor;
        if (isRejected) {
          dotColor = Colors.red;
        } else if (isComplete) {
          dotColor = const Color(0xFF10B981);
        } else if (isActive) {
          dotColor = AppTheme.primaryColor;
        } else {
          dotColor = const Color(0xFFCBD5E1);
        }

        String label = stages[i].$1;
        if (isRejected) label = 'Rejected';
        if (_app.status == ExhibitorStatus.infoRequested && i == 1) label = 'Info Requested';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isActive ? Border.all(color: dotColor.withValues(alpha: 0.3), width: 4) : null,
                  ),
                  child: Icon(
                    isComplete ? Icons.check : isRejected ? Icons.close : Icons.circle,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                if (i < stages.length - 1)
                  Container(
                    width: 2,
                    height: 32,
                    color: isComplete ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isActive || isComplete ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                      color: isActive
                          ? AppTheme.primaryColor
                          : isRejected
                              ? Colors.red
                              : const Color(0xFF334155),
                    ),
                  ),
                  if (i < stages.length - 1) const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoRequestCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFD97706), size: 22),
              SizedBox(width: 8),
              Text(
                'Organiser Needs More Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              _app.infoRequestMessage ?? 'The organiser has requested additional information.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF78350F), fontStyle: FontStyle.italic, height: 1.5),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _responseCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Type your response here...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendInfoResponse,
              icon: _isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 18),
              label: const Text('Send Response', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(NumberFormat currency, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'Your Application Has Been Approved!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF065F46)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _approvalRow('Booth', _app.boothNumber ?? 'TBD'),
          _approvalRow('Package', _app.packageName ?? 'Standard'),
          _approvalRow('Amount', currency.format(_app.boothFeeRm)),
          if (_app.paymentDeadline != null)
            _approvalRow('Payment Deadline', dateFormat.format(_app.paymentDeadline!)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/vendor-exhibitor-payment', arguments: _app);
              },
              icon: const Icon(Icons.payment, size: 20),
              label: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _approvalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF047857), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildConfirmedCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'Exhibitor Confirmed!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Booth ${_app.boothNumber ?? 'TBD'} · ${_app.boothHall} · ${_app.boothSize}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/vendor-exhibition-dashboard', arguments: _app);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Open Exhibition Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Application Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Divider(height: 20),
          _detailRow('Company', _app.companyName),
          _detailRow('Category', _app.category),
          _detailRow('Contact', _app.contactName),
          _detailRow('Phone', _app.phone),
          _detailRow('Email', _app.email),
          if (_app.exhibitingCategory != null && _app.exhibitingCategory!.isNotEmpty)
            _detailRow('Exhibiting', _app.exhibitingCategory!),
          if (_app.preferredLocation != null)
            _detailRow('Location Pref', _app.preferredLocation!),
          if (_app.requirements.isNotEmpty)
            _detailRow('Requirements', _app.requirements.join(', ')),
          _detailRow('Marketing Opt-in', _app.marketingOptIn ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          ),
        ],
      ),
    );
  }
}
