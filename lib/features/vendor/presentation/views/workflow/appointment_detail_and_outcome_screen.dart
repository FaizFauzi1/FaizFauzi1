import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';

class AppointmentDetailAndOutcomeScreen extends StatefulWidget {
  final ServiceAppointmentBooking appointment;

  const AppointmentDetailAndOutcomeScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailAndOutcomeScreen> createState() => _AppointmentDetailAndOutcomeScreenState();
}

class _AppointmentDetailAndOutcomeScreenState extends State<AppointmentDetailAndOutcomeScreen> {
  late ServiceAppointmentBooking _appt;

  @override
  void initState() {
    super.initState();
    _appt = widget.appointment;
  }

  void _updateStatus(ServiceAppointmentStatus newStatus) {
    final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
    provider.updateAppointmentStatus(_appt.id, newStatus);
    setState(() {
      _appt = _appt.copyWith(status: newStatus);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: newStatus.color,
        content: Text('Appointment status updated to ${newStatus.displayName}'),
      ),
    );
  }

  void _showRecordOutcomeDialog() {
    final notesController = TextEditingController(text: _appt.outcomeNotes ?? '');
    String selectedOutcome = _getDefaultOutcomeOptions().first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(_appt.purpose.iconData, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              const Text('Record Outcome', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record consultation results and client decision for ${_appt.appointmentTypeName}:',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 12),
                const Text('Outcome Decision *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedOutcome,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _getDefaultOutcomeOptions().map((opt) {
                    return DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedOutcome = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text('Notes & Client Feedback', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Client liked beef rendang, requested less spicy chicken curry. Requested quote for 350 pax.',
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, foregroundColor: Colors.white),
              onPressed: () {
                final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
                provider.recordAppointmentOutcome(
                  appointmentId: _appt.id,
                  outcomeStatus: selectedOutcome,
                  outcomeNotes: notesController.text.trim(),
                );
                setState(() {
                  _appt = _appt.copyWith(
                    status: ServiceAppointmentStatus.completed,
                    outcomeStatus: selectedOutcome,
                    outcomeNotes: notesController.text.trim(),
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.successColor,
                    content: Text('Appointment marked Completed and outcome logged!'),
                  ),
                );
              },
              child: const Text('Save Outcome'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getDefaultOutcomeOptions() {
    switch (_appt.purpose) {
      case AppointmentPurpose.tasting:
        return [
          'Interested - Menu Approved',
          'Requested Recipe/Menu Changes',
          'Quote Requested for Custom Menu',
          'Declined',
          'Follow-up Required',
        ];
      case AppointmentPurpose.fitting:
        return [
          'Correct Size - Product Selected',
          'Alteration Required (Hemming/Waist)',
          'New Measurement Required',
          'Different Gown Selected',
          'Still Deciding',
        ];
      case AppointmentPurpose.visit:
        return [
          'Venue Suitable - Client Interested',
          'Layout Changes Required',
          'Additional AV/Stage Equipment Needed',
          'Follow-up Date Required',
          'Client Exploring Other Options',
        ];
      case AppointmentPurpose.trial:
        return [
          'Look Approved & Locked',
          'Minor Hairstyle Adjustment Requested',
          'Additional Bridesmaid Service Requested',
          'Follow-up Consultation Needed',
        ];
      case AppointmentPurpose.measurement:
        return [
          'Measurements Logged & Confirmed',
          'Fabric Selected & In Production',
          'Follow-up Second Fitting Scheduled',
        ];
      default:
        return [
          'Interested - Proceed to Quote',
          'Service Tailoring Requested',
          'Follow-up Required',
          'Declined by Client',
        ];
    }
  }

  void _showCreateQuoteDialog() {
    final quoteAmountController = TextEditingController(text: '18000');
    final detailsController = TextEditingController(
      text: 'Pre-filled from appointment outcome:\n'
          'Event: ${_appt.eventName ?? "Wedding"}\n'
          'Customer: ${_appt.customerName}\n'
          'Participants / Guests: ${_appt.participantsCount * 100}\n'
          'Dietary / Specifics: ${_appt.categorySpecificDetails.entries.map((e) => "${e.key}: ${e.value}").join(", ")}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.request_quote_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Create Formal Quote', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pre-fill service proposal for ${_appt.customerName} based on appointment consultation:',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quoteAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quoted Price (RM) *',
                  hintText: 'e.g. 18000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Proposal Items & Inclusions',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_appt.creditTowardBooking && _appt.fee > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Credit of RM ${_appt.fee.toStringAsFixed(0)} (appointment fee) will automatically apply at checkout.',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            onPressed: () {
              final quoteId = 'QUO-${DateTime.now().millisecondsSinceEpoch % 100000}';
              final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
              provider.linkQuoteToAppointment(_appt.id, quoteId);
              setState(() {
                _appt = _appt.copyWith(generatedQuoteId: quoteId);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.successColor,
                  content: Text('Quote $quoteId created and sent to ${_appt.customerName}!'),
                ),
              );
            },
            child: const Text('Send Quote to Customer'),
          ),
        ],
      ),
    );
  }

  void _showCreateBookingDialog() {
    final rentalPriceCtrl = TextEditingController(text: '800');
    final alterationCtrl = TextEditingController(text: '150');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.successColor),
            SizedBox(width: 8),
            Text('Convert to Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create finalized confirmed booking for ${_appt.customerName}:',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rentalPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Base Service / Rental Price (RM)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: alterationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Customization / Alteration Fee (RM)', border: OutlineInputBorder()),
              ),
              if (_appt.creditTowardBooking && _appt.fee > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'Appointment credit: -RM ${_appt.fee.toStringAsFixed(0)} will be deducted!',
                  style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, foregroundColor: Colors.white),
            onPressed: () {
              final bookingId = 'BK-${DateTime.now().millisecondsSinceEpoch % 100000}';
              final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
              provider.linkBookingToAppointment(_appt.id, bookingId);
              setState(() {
                _appt = _appt.copyWith(linkedChildBookingId: bookingId);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.successColor,
                  content: Text('Booking $bookingId created and linked to this appointment!'),
                ),
              );
            },
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Appointment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _appt.status.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 4, backgroundColor: _appt.status.color),
                            const SizedBox(width: 6),
                            Text(
                              _appt.status.displayName,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _appt.status.color),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _appt.fee > 0 ? Colors.amber.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _appt.fee > 0 ? 'RM ${_appt.fee.toStringAsFixed(0)}' : 'Free',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _appt.fee > 0 ? Colors.amber.shade900 : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _appt.appointmentTypeName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Purpose: ${_appt.purpose.displayName} · Service: ${_appt.serviceName}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(dateFormat.format(_appt.scheduledDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text('${_appt.scheduledTime} (${_appt.durationMinutes} min)', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_appt.location, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer & Event Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Client & Event Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: const Icon(Icons.person, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_appt.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(_appt.customerPhone, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_appt.eventName != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.celebration_outlined, size: 16, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text('Event: ${_appt.eventName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                        ],
                      ),
                    ),
                  ],
                  if (_appt.categorySpecificDetails.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Category-Specific Requirements:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ..._appt.categorySpecificDetails.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ${entry.key}: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Expanded(child: Text('${entry.value}', style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (_appt.customerNotes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Customer Notes: "${_appt.customerNotes}"', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // OUTCOME & POST-APPOINTMENT CONVERSION (Bridge Discovery -> Quote -> Booking)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Appointment Outcome', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      if (_appt.outcomeStatus == null)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: _showRecordOutcomeDialog,
                          icon: const Icon(Icons.fact_check_outlined, size: 16),
                          label: const Text('Record Outcome', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_appt.outcomeStatus != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, size: 18, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                _appt.outcomeStatus!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                              ),
                            ],
                          ),
                          if (_appt.outcomeNotes != null && _appt.outcomeNotes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              _appt.outcomeNotes!,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bridge Buttons: Create Quote or Create Booking
                    const Text('Next Action Bridge:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: _showCreateQuoteDialog,
                            icon: const Icon(Icons.request_quote_outlined),
                            label: Text(_appt.generatedQuoteId != null ? 'Quote: ${_appt.generatedQuoteId}' : 'Create Quote'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _showCreateBookingDialog,
                            icon: const Icon(Icons.bookmark_added_outlined),
                            label: Text(_appt.linkedChildBookingId != null ? 'Booked: ${_appt.linkedChildBookingId}' : 'Create Booking'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'After concluding the appointment, record the outcome to unlock automated Quote generation or direct Booking conversion.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Control Bar
            const Text('Update Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusActionButton(ServiceAppointmentStatus.confirmed, Icons.check),
                _buildStatusActionButton(ServiceAppointmentStatus.checkedIn, Icons.how_to_reg),
                _buildStatusActionButton(ServiceAppointmentStatus.inProgress, Icons.timelapse),
                _buildStatusActionButton(ServiceAppointmentStatus.completed, Icons.done_all),
                _buildStatusActionButton(ServiceAppointmentStatus.cancelled, Icons.cancel_outlined, isDestructive: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActionButton(ServiceAppointmentStatus status, IconData icon, {bool isDestructive = false}) {
    final isSelected = _appt.status == status;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : (isDestructive ? AppTheme.errorColor : AppTheme.textPrimaryColor),
        backgroundColor: isSelected ? (isDestructive ? AppTheme.errorColor : AppTheme.primaryColor) : Colors.white,
        side: BorderSide(color: isDestructive ? AppTheme.errorColor : AppTheme.borderColor),
      ),
      onPressed: () => _updateStatus(status),
      icon: Icon(icon, size: 16),
      label: Text(status.displayName, style: const TextStyle(fontSize: 12)),
    );
  }
}
