import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';

class CustomerPackageCustomizationScreen extends StatefulWidget {
  final CollaborativePackage package;

  const CustomerPackageCustomizationScreen({super.key, required this.package});

  @override
  State<CustomerPackageCustomizationScreen> createState() => _CustomerPackageCustomizationScreenState();
}

class _CustomerPackageCustomizationScreenState extends State<CustomerPackageCustomizationScreen> {
  late CollaborativePackage _pkg;
  final Map<String, String> _selectedCollaboratorIds = {};
  DateTime _eventDate = DateTime.now().add(const Duration(days: 90));
  bool _isCheckingAvailability = false;
  bool _availabilityChecked = false;
  final List<String> _bookedPreparationAppointmentIds = [];

  @override
  void initState() {
    super.initState();
    _pkg = widget.package;

    // Initialize selections for each component
    for (final comp in _pkg.components) {
      if (comp.selectedCollaboratorId != null) {
        _selectedCollaboratorIds[comp.id] = comp.selectedCollaboratorId!;
      } else if (comp.approvedCollaborators.isNotEmpty) {
        _selectedCollaboratorIds[comp.id] = comp.approvedCollaborators.first.vendorId;
      }
    }
  }

  double get _totalPrice {
    double total = _pkg.basePrice;
    for (final comp in _pkg.components) {
      final selectedId = _selectedCollaboratorIds[comp.id];
      if (selectedId != null) {
        final col = comp.approvedCollaborators.firstWhere(
          (c) => c.vendorId == selectedId,
          orElse: () => comp.approvedCollaborators.first,
        );
        total += col.priceDelta;
      }
    }
    return total;
  }

  void _checkAvailability() async {
    setState(() => _isCheckingAvailability = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _isCheckingAvailability = false;
        _availabilityChecked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.successColor,
          content: Text('All selected vendors are confirmed AVAILABLE for this event date!'),
        ),
      );
    }
  }

  void _showBookAppointmentSheet(PackageComponent comp, CollaboratorOption collab, ServiceAppointmentType apptType) {
    DateTime apptDate = DateTime.now().add(const Duration(days: 7));
    String apptTime = '14:00';
    int paxCount = 4;
    final notesCtrl = TextEditingController(text: 'Preferred styling and requirements.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                          child: Icon(apptType.purpose.iconData, color: AppTheme.primaryColor, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text('Book ${apptType.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Vendor: ${collab.vendorName} · Component: ${comp.componentName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const Divider(height: 20),
                Text(apptType.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 14),

                // Date Picker Button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: apptDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setSheetState(() => apptDate = picked);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('dd MMM yyyy').format(apptDate), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: apptTime,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                        items: ['10:00', '11:30', '14:00', '15:30', '17:00']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => apptTime = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Number of Participants:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (paxCount > 1) setSheetState(() => paxCount--);
                          },
                        ),
                        Text('$paxCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            if (paxCount < apptType.maxParticipants) setSheetState(() => paxCount++);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Special Requests / Preferences', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          apptType.fee > 0
                              ? 'Fee: RM ${apptType.fee.toStringAsFixed(0)} (Credited toward package booking total upon purchase)'
                              : 'Free consultation session',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      final apptId = 'apt-cust-${DateTime.now().millisecondsSinceEpoch}';
                      final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);

                      provider.bookAppointment(
                        ServiceAppointmentBooking(
                          id: apptId,
                          appointmentTypeId: apptType.id,
                          appointmentTypeName: apptType.name,
                          purpose: apptType.purpose,
                          serviceId: collab.serviceId,
                          serviceName: collab.serviceName,
                          vendorId: collab.vendorId,
                          vendorName: collab.vendorName,
                          customerId: 'cust-current',
                          customerName: 'Sarah & Adam',
                          customerPhone: '+60 12-345 6789',
                          eventId: 'evt-sarah-wedding',
                          eventName: 'Sarah & Adam Wedding',
                          scheduledDate: apptDate,
                          scheduledTime: apptTime,
                          durationMinutes: apptType.durationMinutes,
                          participantsCount: paxCount,
                          location: apptType.location,
                          fee: apptType.fee,
                          isPaid: apptType.fee > 0,
                          creditTowardBooking: apptType.creditTowardBooking,
                          status: ServiceAppointmentStatus.confirmed,
                          packageId: _pkg.id,
                          packageComponentName: comp.componentName,
                          customerNotes: notesCtrl.text.trim(),
                        ),
                      );

                      setState(() {
                        _bookedPreparationAppointmentIds.add(apptId);
                      });

                      Navigator.pop(ctx);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.successColor,
                          content: Text('Appointment booked! Added to My Event and Vendor Calendar.'),
                        ),
                      );
                    },
                    child: Text('Confirm Appointment Booking (${apptType.fee > 0 ? "RM ${apptType.fee.toStringAsFixed(0)}" : "Free"})'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _proceedToPackageBooking() {
    final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);

    final parentBooking = provider.bookCollaborativePackage(
      package: _pkg,
      customerId: 'cust-current',
      customerName: 'Sarah & Adam',
      customerEmail: 'sarah.adam@example.com',
      eventId: 'evt-sarah-wedding',
      eventName: 'Sarah & Adam Wedding',
      eventDate: _eventDate,
      linkedAppointmentIds: _bookedPreparationAppointmentIds,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 28),
            SizedBox(width: 10),
            Text('Package Booked!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parent Booking Code: ${parentBooking.bookingCode}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
            const SizedBox(height: 6),
            Text('Total Amount: RM ${parentBooking.totalCalculatedPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            const Text(
              'Child bookings generated for each vendor:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...parentBooking.childBookings.map((cb) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${cb.componentName}: ${cb.vendorName} (RM ${cb.agreedPrice.toStringAsFixed(0)})',
                    style: const TextStyle(fontSize: 11)),
              );
            }),
            if (_bookedPreparationAppointmentIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${_bookedPreparationAppointmentIds.length} preparation appointments are linked and scheduled in your My Event calendar.',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('View in My Event'),
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
        title: const Text('Customize Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package Overview Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_pkg.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_pkg.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Base Package Price', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                          Text('RM ${_pkg.basePrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Your Customized Total',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          Text(
                            'RM ${_totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Package Appointment Dashboard (Preparation Checklist)
            _buildPreparationDashboard(),
            const SizedBox(height: 20),

            // Component Customizer
            const Text('Customize Package Components', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Fixed vendors are guaranteed; choose your preferred collaborators for custom components.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),

            ..._pkg.components.map((comp) {
              return _buildComponentCustomizationCard(comp);
            }),

            const SizedBox(height: 20),

            // Availability Check Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Event Date & Availability Verification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(dateFormat.format(_eventDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _eventDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (picked != null) {
                            setState(() {
                              _eventDate = picked;
                              _availabilityChecked = false;
                            });
                          }
                        },
                        child: const Text('Change Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _isCheckingAvailability ? null : _checkAvailability,
                      icon: _isCheckingAvailability
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_availabilityChecked ? Icons.check_circle : Icons.search,
                              color: _availabilityChecked ? AppTheme.successColor : AppTheme.primaryColor),
                      label: Text(
                        _availabilityChecked ? 'All Vendors Available on this Date!' : 'Verify Availability Across All Vendors',
                        style: TextStyle(
                          color: _availabilityChecked ? AppTheme.successColor : AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // Buffer for bottom checkout bar
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Package Price', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                Text(
                  'RM ${_totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _proceedToPackageBooking,
              child: const Text('Continue to Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // Preparation Appointments Dashboard inside Package
  Widget _buildPreparationDashboard() {
    return Container(
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
              const Row(
                children: [
                  Icon(Icons.checklist_rtl, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text('Package Preparation Sessions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${_bookedPreparationAppointmentIds.length} Scheduled',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Recommended & required appointments prior to final wedding day:',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 12),
          _buildPreparationItem('Venue Site Visit', 'Required before final floorplan confirmation', isCompleted: true),
          _buildPreparationItem('Banquet Food Tasting', 'Sample 6 dishes with chef (Credited to total)',
              isBooked: _bookedPreparationAppointmentIds.isNotEmpty),
          _buildPreparationItem('Bridal Makeup Trial', 'Recommended to test bridal look & lashes',
              isBooked: _bookedPreparationAppointmentIds.length > 1),
          _buildPreparationItem('Wedding Cake Tasting', 'Sample sponges and fillings (Optional)'),
        ],
      ),
    );
  }

  Widget _buildPreparationItem(String title, String subtitle, {bool isCompleted = false, bool isBooked = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle
                : isBooked
                    ? Icons.schedule
                    : Icons.radio_button_unchecked,
            size: 18,
            color: isCompleted
                ? AppTheme.successColor
                : isBooked
                    ? Colors.amber.shade800
                    : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentCustomizationCard(PackageComponent comp) {
    final currentSelectedId = _selectedCollaboratorIds[comp.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: comp.category.brandColor.withOpacity(0.12),
                    child: Icon(comp.category.iconData, color: comp.category.brandColor, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(comp.componentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: comp.appointmentRule.badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  comp.appointmentRule.displayName,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: comp.appointmentRule.badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comp.description, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
          const SizedBox(height: 12),

          // Collaborator choices
          ...comp.approvedCollaborators.map((collab) {
            final isSelected = currentSelectedId == collab.vendorId;
            final deltaText = collab.priceDelta == 0
                ? 'Included in Package'
                : collab.priceDelta > 0
                    ? '+RM ${collab.priceDelta.toStringAsFixed(0)}'
                    : '-RM ${collab.priceDelta.abs().toStringAsFixed(0)}';

            return InkWell(
              onTap: comp.isFixedVendor
                  ? null
                  : () {
                      setState(() {
                        _selectedCollaboratorIds[comp.id] = collab.vendorId;
                      });
                    },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          comp.isFixedVendor
                              ? Icons.lock_outline
                              : isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                          size: 18,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(collab.vendorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(collab.serviceName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Text(
                          deltaText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: collab.priceDelta > 0
                                ? Colors.amber.shade900
                                : collab.priceDelta < 0
                                    ? Colors.green.shade800
                                    : AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),

                    // If this collaborator has appointment options, display booking buttons!
                    if (isSelected && collab.appointmentOptions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 14),
                      Text('Available Preparation Appointments for ${collab.vendorName}:',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: collab.appointmentOptions.map((appt) {
                          return OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            onPressed: () => _showBookAppointmentSheet(comp, collab, appt),
                            icon: Icon(appt.purpose.iconData, size: 14, color: AppTheme.primaryColor),
                            label: Text(
                              'Book ${appt.name} (${appt.fee > 0 ? "RM ${appt.fee.toStringAsFixed(0)}" : "Free"})',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
