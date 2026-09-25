import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';
import 'appointment_detail_and_outcome_screen.dart';

class VendorUnifiedCalendarScreen extends StatefulWidget {
  const VendorUnifiedCalendarScreen({super.key});

  @override
  State<VendorUnifiedCalendarScreen> createState() => _VendorUnifiedCalendarScreenState();
}

class _VendorUnifiedCalendarScreenState extends State<VendorUnifiedCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  VendorCalendarItemType? _selectedFilter;

  void _showAddBlockedTimeDialog() {
    final reasonCtrl = TextEditingController(text: 'Facility Maintenance');
    final startCtrl = TextEditingController(text: '09:00');
    final endCtrl = TextEditingController(text: '17:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: AppTheme.errorColor, size: 20),
            SizedBox(width: 8),
            Text('Block Off Time Slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Reason for Blockout (e.g. Leave, Maintenance, Holiday)'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startCtrl,
                    decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(labelText: 'End Time (HH:MM)'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            onPressed: () {
              if (reasonCtrl.text.isNotEmpty) {
                final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
                provider.addBlockedTime(
                  date: _selectedDate,
                  startTime: startCtrl.text.trim(),
                  endTime: endCtrl.text.trim(),
                  reason: reasonCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Blocked time slot added to schedule')),
                );
              }
            },
            child: const Text('Block Time'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VendorWorkflowProvider>(context);
    final allItems = provider.calendarItems;

    // Filter items
    final filteredItems = allItems.where((item) {
      if (_selectedFilter != null && item.type != _selectedFilter) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Unified Vendor Calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            tooltip: 'Block Out Time',
            onPressed: _showAddBlockedTimeDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Unified Schedule Legend & Quick Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(null, 'All Schedule'),
                  const SizedBox(width: 8),
                  _buildFilterChip(VendorCalendarItemType.booking, 'Bookings'),
                  const SizedBox(width: 8),
                  _buildFilterChip(VendorCalendarItemType.appointment, 'Appointments'),
                  const SizedBox(width: 8),
                  _buildFilterChip(VendorCalendarItemType.setupTime, 'Setup Time'),
                  const SizedBox(width: 8),
                  _buildFilterChip(VendorCalendarItemType.travelTime, 'Travel Time'),
                  const SizedBox(width: 8),
                  _buildFilterChip(VendorCalendarItemType.blockedTime, 'Blocked Time'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Date Strip
          _buildHorizontalDateStrip(),
          const Divider(height: 1),

          // Events / Agenda List
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No Schedule Items for this filter', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Unified calendar combines bookings, appointments, and logistics.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildCalendarItemCard(item, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(VendorCalendarItemType? type, String label) {
    final isSelected = _selectedFilter == type;
    final color = type?.color ?? AppTheme.primaryColor;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 4, backgroundColor: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalDateStrip() {
    final now = DateTime.now();
    final dates = List.generate(14, (i) => now.add(Duration(days: i - 2)));

    return Container(
      height: 70,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final d = dates[index];
          final isToday = d.day == now.day && d.month == now.month && d.year == now.year;
          final isSelected = d.day == _selectedDate.day && d.month == _selectedDate.month && d.year == _selectedDate.year;

          return InkWell(
            onTap: () => setState(() => _selectedDate = d),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : isToday
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(d).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarItemCard(VendorCalendarItem item, VendorWorkflowProvider provider) {
    final dateFormat = DateFormat('EEE, dd MMM');

    return InkWell(
      onTap: () {
        if (item.type == VendorCalendarItemType.appointment && item.relatedId != null) {
          final appt = provider.appointments.firstWhere(
            (a) => a.id == item.relatedId,
            orElse: () => provider.appointments.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppointmentDetailAndOutcomeScreen(appointment: appt),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left color accent bar
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: item.type.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            // Time & Date info
            SizedBox(
              width: 75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.startTime,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    item.endTime,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(item.date),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.type.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.type.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: item.type.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (item.clientName != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Client: ${item.clientName}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  if (item.serviceOrEventName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.serviceOrEventName!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                  if (item.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (item.type == VendorCalendarItemType.appointment)
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
