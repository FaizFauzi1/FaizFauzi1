import 'package:eventease/features/booking/data/models/appointment.dart';
import 'package:eventease/features/booking/data/models/rental.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  Map<DateTime, List<dynamic>> _events = {};
  
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    // Load sample appointments and rentals
    final appointments = _getSampleAppointments();
    final rentals = _getSampleRentals();
    
    // Group events by date
    for (final appointment in appointments) {
      final date = DateTime(
        appointment.scheduledDate.year,
        appointment.scheduledDate.month,
        appointment.scheduledDate.day,
      );
      _events[date] = [...(_events[date] ?? []), appointment];
    }
    
    for (final rental in rentals) {
      final date = DateTime(
        rental.pickupDate.year,
        rental.pickupDate.month,
        rental.pickupDate.day,
      );
      _events[date] = [...(_events[date] ?? []), rental];
    }
  }

  List<Appointment> _getSampleAppointments() {
    return [
      Appointment(
        id: '1',
        vendorId: '1',
        customerId: 'customer1',
        serviceId: 'service1',
        eventId: 'event1',
        type: AppointmentType.foodTasting,
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        duration: const Duration(hours: 2),
        location: 'Vendor Kitchen, KL',
        notes: 'Wedding catering tasting session',
        status: AppointmentStatus.confirmed,
        cost: 150.0,
        isPaid: true,
        reminder: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Appointment(
        id: '2',
        vendorId: '2',
        customerId: 'customer1',
        serviceId: 'service2',
        eventId: 'event1',
        type: AppointmentType.siteVisit,
        scheduledDate: DateTime.now().add(const Duration(days: 5)),
        duration: const Duration(hours: 1),
        location: 'Grand Ballroom KL',
        notes: 'Venue site visit for wedding',
        status: AppointmentStatus.pending,
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
        vendorId: '3',
        eventId: 'event1',
        pickupDate: DateTime.now().add(const Duration(days: 7)),
        returnDate: DateTime.now().add(const Duration(days: 8)),
        selectedSizes: {'dress': 'M'},
        totalCost: 500.0,
        deposit: 100.0,
        depositPaid: true,
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Calendar',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _addNewEvent,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          _buildCalendarGrid(),
          const SizedBox(height: 16),
          _buildEventsList(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor),
          ),
          Text(
            '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildWeekdayHeader(),
          _buildCalendarDays(daysInMonth, firstWeekday),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarDays(int daysInMonth, int firstWeekday) {
    final days = <Widget>[];
    
    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      days.add(const Expanded(child: SizedBox()));
    }
    
    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDate.year, _focusedDate.month, day);
      final isSelected = _selectedDate.year == date.year &&
          _selectedDate.month == date.month &&
          _selectedDate.day == date.day;
      final hasEvents = _events.containsKey(date);
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;
      
      days.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : isToday
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: AppTheme.primaryColor)
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? AppTheme.primaryColor
                                : AppTheme.textPrimaryColor,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hasEvents)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      children: days,
    );
  }

  Widget _buildEventsList() {
    final selectedDateEvents = _events[_selectedDate] ?? [];
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events for ${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (selectedDateEvents.isEmpty)
              _buildEmptyState()
            else
              Expanded(
                child: ListView.builder(
                  itemCount: selectedDateEvents.length,
                  itemBuilder: (context, index) {
                    final event = selectedDateEvents[index];
                    return _buildEventCard(event);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(dynamic event) {
    if (event is Appointment) {
      return _buildAppointmentCard(event);
    } else if (event is RentalBooking) {
      return _buildRentalCard(event);
    }
    return const SizedBox.shrink();
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getAppointmentTypeColor(appointment.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              _getAppointmentTypeIcon(appointment.type),
              color: _getAppointmentTypeColor(appointment.type),
              size: 24,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  appointment.duration != null 
                    ? '${_formatTime(appointment.scheduledDate)} - ${_formatTime(appointment.scheduledDate.add(appointment.duration!))}'
                    : '${_formatTime(appointment.scheduledDate)} - TBD',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  appointment.location,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusChip(appointment.status),
        ],
      ),
    );
  }

  Widget _buildRentalCard(RentalBooking rental) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.checkroom,
              color: AppTheme.secondaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rental Pickup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  '${_formatTime(rental.pickupDate)} - ${_formatTime(rental.returnDate)}',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'RM ${rental.totalCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Rental',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AppointmentStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case AppointmentStatus.confirmed:
        color = AppTheme.successColor;
        text = 'Confirmed';
        break;
      case AppointmentStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case AppointmentStatus.completed:
        color = AppTheme.primaryColor;
        text = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        color = AppTheme.errorColor;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No events scheduled',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new event',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
    });
  }

  void _addNewEvent() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddEventSheet(),
    );
  }

  Widget _buildAddEventSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Text(
                  'Add New Event',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildEventTypeButton('Appointment', Icons.calendar_today, () {
                    Navigator.pop(context);
                    // Navigate to appointment booking
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigate to appointment booking')),
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildEventTypeButton('Rental', Icons.checkroom, () {
                    Navigator.pop(context);
                    // Navigate to rental booking
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigate to rental booking')),
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildEventTypeButton('Custom Event', Icons.event, () {
                    Navigator.pop(context);
                    // Add custom event
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add custom event')),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeButton(String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
        return Icons.people;
      case AppointmentType.pickup:
        return Icons.local_shipping;
      case AppointmentType.delivery:
        return Icons.local_shipping;
      case AppointmentType.returnItem:
        return Icons.undo;
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
}





