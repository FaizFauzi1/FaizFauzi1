import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/booking/data/models/appointment.dart';
import 'package:eventease/features/booking/data/providers/appointment_provider.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/core/utils/app_theme.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen> {
  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      final role = user.userMetadata?['role'];
      final isVendor = role == 'vendor';
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<AppointmentProvider>(context, listen: false);
        if (isVendor) {
          provider.loadVendorAppointments(user.id);
        } else {
          provider.loadCustomerAppointments(user.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final user = SupabaseService.client.auth.currentUser;
    final isVendor = user?.userMetadata?['role'] == 'vendor';
    
    final appointments = isVendor 
        ? appointmentProvider.vendorAppointments 
        : appointmentProvider.customerAppointments;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Appointment Management',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: appointmentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  _buildSummaryCards(appointments),

                  const SizedBox(height: 24),

                  // Appointments list
                  const Text(
                    'All Appointments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (appointments.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: AppTheme.textSecondaryColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No appointments yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        return _buildAppointmentCard(appointment, isVendor);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards(List<Appointment> appointments) {
    final pendingCount = appointments.where((a) => a.status == AppointmentStatus.pending).length;
    final confirmedCount = appointments.where((a) => a.status == AppointmentStatus.confirmed).length;
    final completedCount = appointments.where((a) => a.status == AppointmentStatus.completed).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Pending',
            pendingCount.toString(),
            Icons.pending,
            AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Confirmed',
            confirmedCount.toString(),
            Icons.check_circle,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Completed',
            completedCount.toString(),
            Icons.done_all,
            AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, bool isVendor) {
    Color statusColor;
    switch (appointment.status) {
      case AppointmentStatus.pending:
        statusColor = AppTheme.warningColor;
        break;
      case AppointmentStatus.confirmed:
        statusColor = AppTheme.successColor;
        break;
      case AppointmentStatus.completed:
        statusColor = AppTheme.primaryColor;
        break;
      case AppointmentStatus.cancelled:
        statusColor = AppTheme.errorColor;
        break;
      case AppointmentStatus.noShow:
        statusColor = Colors.grey;
        break;
    }

    final isPending = appointment.status == AppointmentStatus.pending;
    final isFromChat = appointment.source == 'chat';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isFromChat ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getAppointmentIcon(appointment.type),
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getAppointmentTypeString(appointment.type),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                        if (isFromChat)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat, size: 12, color: AppTheme.primaryColor),
                                SizedBox(width: 4),
                                Text(
                                  'CHAT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${appointment.scheduledDate.day}/${appointment.scheduledDate.month}/${appointment.scheduledDate.year} at ${appointment.scheduledDate.hour}:${appointment.scheduledDate.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    if (appointment.customerName != null)
                      Text(
                        'Customer: ${appointment.customerName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (appointment.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              appointment.notes,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appointment.duration != null 
                  ? 'Duration: ${appointment.duration!.inHours}h ${appointment.duration!.inMinutes % 60}m'
                  : 'Duration: TBD',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              if (appointment.cost != null && appointment.cost! > 0)
                Text(
                  'RM ${appointment.cost!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Quick actions for pending appointments (Vendor Only)
          if (isPending && isVendor)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmAppointment(appointment),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelAppointment(appointment),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else if (appointment.status == AppointmentStatus.confirmed && isVendor)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAppointmentDetailsDialog(appointment),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _completeAppointment(appointment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Complete'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showAppointmentDetailsDialog(appointment),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View Details'),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getAppointmentIcon(AppointmentType type) {
    switch (type) {
      case AppointmentType.foodTasting:
        return Icons.restaurant;
      case AppointmentType.fitting:
        return Icons.checkroom;
      case AppointmentType.siteVisit:
        return Icons.location_on;
      case AppointmentType.trial:
        return Icons.try_sms_star;
      case AppointmentType.consultation:
        return Icons.chat;
      case AppointmentType.pickup:
        return Icons.local_shipping;
      case AppointmentType.delivery:
        return Icons.delivery_dining;
      case AppointmentType.returnItem:
        return Icons.assignment_return;
    }
  }

  String _getAppointmentTypeString(AppointmentType type) {
    switch (type) {
      case AppointmentType.foodTasting:
        return 'Food Tasting';
      case AppointmentType.fitting:
        return 'Fitting';
      case AppointmentType.siteVisit:
        return 'Site Visit';
      case AppointmentType.trial:
        return 'Trial';
      case AppointmentType.consultation:
        return 'Consultation';
      case AppointmentType.pickup:
        return 'Pickup';
      case AppointmentType.delivery:
        return 'Delivery';
      case AppointmentType.returnItem:
        return 'Return Item';
    }
  }

  Future<void> _confirmAppointment(Appointment appointment) async {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final success = await appointmentProvider.confirmAppointment(appointment.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment confirmed!')),
      );
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final success = await appointmentProvider.cancelAppointment(appointment.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment rejected')),
      );
    }
  }

  Future<void> _completeAppointment(Appointment appointment) async {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final success = await appointmentProvider.completeAppointment(appointment.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment marked as completed!')),
      );
    }
  }

  void _showAppointmentDetailsDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getAppointmentTypeString(appointment.type)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appointment.customerName != null)
                _buildDetailRow('Customer', appointment.customerName!),
              if (appointment.customerEmail != null)
                _buildDetailRow('Email', appointment.customerEmail!),
              _buildDetailRow('Date', '${appointment.scheduledDate.day}/${appointment.scheduledDate.month}/${appointment.scheduledDate.year}'),
              _buildDetailRow('Time', '${appointment.scheduledDate.hour}:${appointment.scheduledDate.minute.toString().padLeft(2, '0')}'),
              _buildDetailRow(
                'Duration', 
                appointment.duration != null 
                  ? '${appointment.duration!.inHours}h ${appointment.duration!.inMinutes % 60}m'
                  : 'TBD'
              ),
              _buildDetailRow('Location', appointment.location),
              if (appointment.notes.isNotEmpty)
                _buildDetailRow('Notes', appointment.notes),
              _buildDetailRow('Status', appointment.status.toString().split('.').last),
              if (appointment.cost != null)
                _buildDetailRow('Cost', 'RM ${appointment.cost!.toStringAsFixed(2)}'),
              if (appointment.source == 'chat')
                _buildDetailRow('Source', 'Chat Request'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
