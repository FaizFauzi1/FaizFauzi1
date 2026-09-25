import 'package:eventease/features/booking/data/models/appointment.dart';
import 'package:eventease/features/booking/data/models/rental.dart';
import 'package:eventease/features/booking/data/providers/appointment_provider.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Appointments & Rentals',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: () => _showNewAppointmentDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Rentals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingAppointments(),
          _buildPastAppointments(),
          _buildRentals(),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final user = SupabaseService.client.auth.currentUser;
    
    if (user == null) {
      return _buildEmptyState(
        'Not Logged In',
        'Please log in to view your appointments',
        Icons.login,
      );
    }

    // Load appointments if not already loaded
    if (appointmentProvider.customerAppointments.isEmpty && !appointmentProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appointmentProvider.loadCustomerAppointments(user.id);
      });
    }

    if (appointmentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final upcomingAppointments = appointmentProvider.customerAppointments
        .where((apt) => apt.scheduledDate.isAfter(DateTime.now()))
        .toList();

    if (upcomingAppointments.isEmpty) {
      return _buildEmptyState(
        'No Upcoming Appointments',
        'You don\'t have any upcoming appointments',
        Icons.calendar_today,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcomingAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(upcomingAppointments[index]);
      },
    );
  }

  Widget _buildPastAppointments() {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final pastAppointments = appointmentProvider.customerAppointments
        .where((apt) => apt.scheduledDate.isBefore(DateTime.now()))
        .toList();

    if (appointmentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pastAppointments.isEmpty) {
      return _buildEmptyState(
        'No Past Appointments',
        'You don\'t have any past appointments',
        Icons.history,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pastAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(pastAppointments[index]);
      },
    );
  }

  Widget _buildRentals() {
    final rentals = _getSampleRentals();

    if (rentals.isEmpty) {
      return _buildEmptyState(
        'No Rentals',
        'You don\'t have any rental bookings',
        Icons.shopping_bag,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        return _buildRentalCard(rentals[index]);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getAppointmentTypeColor(appointment.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            _getAppointmentTypeIcon(appointment.type),
            color: _getAppointmentTypeColor(appointment.type),
          ),
        ),
        title: Text(
          _getAppointmentTypeTitle(appointment.type),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              appointment.location,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(appointment.scheduledDate)} • ${_formatTime(appointment.scheduledDate)}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: _buildStatusChip(appointment.status),
        onTap: () => _showAppointmentDetails(appointment),
      ),
    );
  }

  Widget _buildRentalCard(RentalBooking rental) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.shopping_bag,
            color: AppTheme.primaryColor,
          ),
        ),
        title: const Text(
          'Rental Booking',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Pickup: ${_formatDate(rental.pickupDate)}',
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
            Text(
              'Return: ${_formatDate(rental.returnDate)}',
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              'RM ${rental.totalCost.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: rental.isCompleted
            ? const Chip(
                label: Text('Completed'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white),
              )
            : const Chip(
                label: Text('Active'),
                backgroundColor: Colors.blue,
                labelStyle: TextStyle(color: Colors.white),
              ),
        onTap: () => _showRentalDetails(rental),
      ),
    );
  }

  Widget _buildStatusChip(AppointmentStatus status) {
    Color color;
    String text;

    switch (status) {
      case AppointmentStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case AppointmentStatus.confirmed:
        color = Colors.blue;
        text = 'Confirmed';
        break;
      case AppointmentStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case AppointmentStatus.noShow:
        color = Colors.grey;
        text = 'No Show';
        break;
    }

    return Chip(
      label: Text(text),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAppointmentTypeColor(AppointmentType type) {
    switch (type) {
      case AppointmentType.foodTasting:
        return Colors.orange;
      case AppointmentType.fitting:
        return Colors.purple;
      case AppointmentType.siteVisit:
        return Colors.blue;
      case AppointmentType.trial:
        return Colors.pink;
      case AppointmentType.consultation:
        return Colors.green;
      case AppointmentType.pickup:
        return Colors.teal;
      case AppointmentType.delivery:
        return Colors.indigo;
      case AppointmentType.returnItem:
        return Colors.red;
    }
  }

  IconData _getAppointmentTypeIcon(AppointmentType type) {
    switch (type) {
      case AppointmentType.foodTasting:
        return Icons.restaurant;
      case AppointmentType.fitting:
        return Icons.checkroom;
      case AppointmentType.siteVisit:
        return Icons.location_on;
      case AppointmentType.trial:
        return Icons.face;
      case AppointmentType.consultation:
        return Icons.chat;
      case AppointmentType.pickup:
        return Icons.point_of_sale;
      case AppointmentType.delivery:
        return Icons.local_shipping;
      case AppointmentType.returnItem:
        return Icons.assignment_return;
    }
  }

  String _getAppointmentTypeTitle(AppointmentType type) {
    switch (type) {
      case AppointmentType.foodTasting:
        return 'Food Tasting';
      case AppointmentType.fitting:
        return 'Fitting Session';
      case AppointmentType.siteVisit:
        return 'Site Visit';
      case AppointmentType.trial:
        return 'Trial Session';
      case AppointmentType.consultation:
        return 'Consultation';
      case AppointmentType.pickup:
        return 'Pickup';
      case AppointmentType.delivery:
        return 'Delivery';
      case AppointmentType.returnItem:
        return 'Return';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<Appointment> _getSampleAppointments() {
    return [
      Appointment(
        id: '1',
        vendorId: 'vendor1',
        customerId: 'customer1',
        serviceId: 'service1',
        type: AppointmentType.foodTasting,
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        duration: const Duration(hours: 1),
        location: 'Grand Ballroom KL',
        notes: 'Wedding catering tasting session',
        status: AppointmentStatus.confirmed,
        cost: 50.0,
        isPaid: true,
        reminder: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Appointment(
        id: '2',
        vendorId: 'vendor2',
        customerId: 'customer1',
        serviceId: 'service2',
        type: AppointmentType.fitting,
        scheduledDate: DateTime.now().add(const Duration(days: 5)),
        duration: const Duration(hours: 2),
        location: 'Elegant Fashion Boutique',
        notes: 'Wedding dress fitting',
        status: AppointmentStatus.pending,
        cost: 0.0,
        isPaid: false,
        reminder: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Appointment(
        id: '3',
        vendorId: 'vendor3',
        customerId: 'customer1',
        serviceId: 'service3',
        type: AppointmentType.siteVisit,
        scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
        duration: const Duration(hours: 1),
        location: 'Garden Pavilion',
        notes: 'Venue inspection',
        status: AppointmentStatus.completed,
        cost: 0.0,
        isPaid: false,
        reminder: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  List<RentalBooking> _getSampleRentals() {
    return [
      RentalBooking(
        id: '1',
        customerId: 'customer1',
        rentalItemId: 'item1',
        vendorId: 'vendor2',
        pickupDate: DateTime.now().add(const Duration(days: 3)),
        returnDate: DateTime.now().add(const Duration(days: 5)),
        selectedSizes: {'dress': 'M', 'shoes': '8'},
        totalCost: 300.0,
        deposit: 100.0,
        depositPaid: true,
        isCompleted: false,
        notes: 'Wedding dress rental',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  void _showNewAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Appointment'),
        content: const Text('Appointment booking dialog (placeholder)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment booking (placeholder)')),
              );
            },
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getAppointmentTypeColor(appointment.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      _getAppointmentTypeIcon(appointment.type),
                      color: _getAppointmentTypeColor(appointment.type),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getAppointmentTypeTitle(appointment.type),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          appointment.location,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(appointment.status),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Date', _formatDate(appointment.scheduledDate)),
              _buildDetailRow('Time', _formatTime(appointment.scheduledDate)),
              _buildDetailRow(
                'Duration', 
                appointment.duration != null 
                  ? '${appointment.duration!.inMinutes} minutes'
                  : 'TBD'
              ),
              if (appointment.cost != null && appointment.cost! > 0)
                _buildDetailRow('Cost', 'RM ${appointment.cost!.toStringAsFixed(2)}'),
              if (appointment.notes.isNotEmpty)
                _buildDetailRow('Notes', appointment.notes),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Open chat
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening chat...')),
                        );
                      },
                      child: const Text('Chat with Vendor'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final newDate = await showDatePicker(
                          context: context,
                          initialDate: appointment.scheduledDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (newDate != null) {
                          final newTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(appointment.scheduledDate),
                          );
                          if (newTime != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Reschedule requested: ${newDate.day}/${newDate.month}/${newDate.year} ${newTime.format(context)}')),
                            );
                          }
                        }
                      },
                      child: const Text('Reschedule'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRentalDetails(RentalBooking rental) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rental Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Pickup Date', _formatDate(rental.pickupDate)),
              _buildDetailRow('Return Date', _formatDate(rental.returnDate)),
              _buildDetailRow('Duration', '${rental.rentalDays} days'),
              _buildDetailRow('Total Cost', 'RM ${rental.totalCost.toStringAsFixed(2)}'),
              _buildDetailRow('Deposit', 'RM ${rental.deposit.toStringAsFixed(2)}'),
              if (rental.notes != null)
                _buildDetailRow('Notes', rental.notes!),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Contact vendor
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contacting vendor...')),
                        );
                      },
                      child: const Text('Contact Vendor'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: rental.returnDate,
                          firstDate: rental.returnDate,
                          lastDate: rental.returnDate.add(const Duration(days: 60)),
                        );
                        if (picked != null && picked.isAfter(rental.pickupDate)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Extension requested till ${picked.day}/${picked.month}/${picked.year}')),
                          );
                        }
                      },
                      child: const Text('Extend Rental'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
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

