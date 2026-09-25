import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';

class CollaboratorInvitationDetailScreen extends StatefulWidget {
  final CollaboratorInvitation invitation;

  const CollaboratorInvitationDetailScreen({super.key, required this.invitation});

  @override
  State<CollaboratorInvitationDetailScreen> createState() => _CollaboratorInvitationDetailScreenState();
}

class _CollaboratorInvitationDetailScreenState extends State<CollaboratorInvitationDetailScreen> {
  late CollaboratorInvitation _invitation;
  final _partnerPriceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  CommonServiceInfo? _selectedExistingService;
  final List<ServiceAppointmentType> _offeredAppointments = [];

  @override
  void initState() {
    super.initState();
    _invitation = widget.invitation;
    _partnerPriceCtrl.text = _invitation.packageAllowance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _partnerPriceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submitAcceptOffer() {
    final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
    final partnerPrice = double.tryParse(_partnerPriceCtrl.text) ?? _invitation.packageAllowance;
    final stdPrice = _selectedExistingService?.startingPrice ?? partnerPrice;
    final discount = (stdPrice > partnerPrice) ? (stdPrice - partnerPrice) : 0.0;

    provider.respondToInvitation(
      invitationId: _invitation.id,
      accept: true,
      offeredServiceId: _selectedExistingService?.id ?? 'srv-partner-${_invitation.id}',
      offeredServiceName: _selectedExistingService?.serviceName ?? _invitation.roleComponentName,
      partnerPrice: partnerPrice,
      partnerDiscount: discount,
      offeredAppointments: _offeredAppointments,
    );

    setState(() {
      _invitation = _invitation.copyWith(
        status: CollaborationStatus.offerSubmitted,
        partnerPriceOffered: partnerPrice,
        partnerDiscount: discount,
        offeredServiceName: _selectedExistingService?.serviceName ?? _invitation.roleComponentName,
        offeredAppointments: _offeredAppointments,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.successColor,
        content: Text('Offer submitted successfully to package owner!'),
      ),
    );
  }

  void _declineInvitation() {
    final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
    provider.respondToInvitation(invitationId: _invitation.id, accept: false);
    setState(() {
      _invitation = _invitation.copyWith(status: CollaborationStatus.declined);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation declined')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VendorWorkflowProvider>(context);
    final myServices = provider.services;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Collaboration Invitation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _invitation.status.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _invitation.status.displayName,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _invitation.status.color),
                        ),
                      ),
                      Text(
                        'Allowance: RM ${_invitation.packageAllowance.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'You are invited to contribute to a package!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Package: ${_invitation.packageName}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Package Owner: ${_invitation.ownerVendorName}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.category_outlined, 'Requested Role', _invitation.roleComponentName),
                  _buildDetailRow(Icons.event_outlined, 'Event Date Target', _invitation.eventDate),
                  _buildDetailRow(Icons.place_outlined, 'Location', _invitation.location),
                  if (_invitation.requestedAppointmentTypes.isNotEmpty)
                    _buildDetailRow(
                      Icons.calendar_today_outlined,
                      'Appointments Requested',
                      _invitation.requestedAppointmentTypes.join(', '),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Service Offer Section (Collaborator Service Offer)
            if (_invitation.status == CollaborationStatus.pending ||
                _invitation.status == CollaborationStatus.invitationSent) ...[
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
                    const Text('Your Service & Appointment Offer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Select an existing service from your catalog or enter custom terms for this partner package:',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                    const SizedBox(height: 14),

                    // Existing Service Selector
                    const Text('Select Service From Catalog', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<CommonServiceInfo>(
                      value: _selectedExistingService,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(12)),
                      hint: const Text('Choose a service...', style: TextStyle(fontSize: 13)),
                      items: myServices.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text('${s.serviceName} (RM ${s.startingPrice.toStringAsFixed(0)})', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedExistingService = val;
                            _partnerPriceCtrl.text = _invitation.packageAllowance.toStringAsFixed(0);
                            final appts = provider.getAppointmentTypesForService(val.id);
                            _offeredAppointments.clear();
                            _offeredAppointments.addAll(appts);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Partner Pricing
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Package Partner Price (RM) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _partnerPriceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. 800'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Standard Price (RM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  'RM ${_selectedExistingService?.startingPrice.toStringAsFixed(0) ?? _invitation.packageAllowance.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Collaborator Appointment Options
                    const Text('Attach Appointment Options', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Customers selecting you in this package will be able to book these consultation/trial sessions:',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                    const SizedBox(height: 10),

                    if (_offeredAppointments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('No appointment options attached. Customers will book directly without pre-consultation.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _offeredAppointments.add(
                                    ServiceAppointmentType(
                                      id: 'apt-offer-1',
                                      serviceId: '',
                                      name: '${_invitation.roleComponentName} Trial Session',
                                      description: 'Pre-event preparation and testing session.',
                                      purpose: AppointmentPurpose.trial,
                                      durationMinutes: 60,
                                      fee: 100.0,
                                      isPaid: true,
                                      creditTowardBooking: true,
                                    ),
                                  );
                                });
                              },
                              child: const Text('+ Add Trial Option', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._offeredAppointments.map((appt) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
                                  const SizedBox(width: 8),
                                  Text(appt.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(width: 8),
                                  Text('(${appt.durationMinutes} min)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                              Text(
                                appt.fee > 0 ? 'RM ${appt.fee.toStringAsFixed(0)}' : 'Free',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(color: AppTheme.errorColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _declineInvitation,
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _submitAcceptOffer,
                            child: const Text('Accept & Submit Service Offer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Offer Submitted: RM ${_invitation.partnerPriceOffered?.toStringAsFixed(0) ?? _invitation.packageAllowance.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your service is configured and ready for customers to select inside ${_invitation.packageName}.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
