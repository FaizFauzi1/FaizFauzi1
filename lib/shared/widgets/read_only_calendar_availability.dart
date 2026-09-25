import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

/// Read-only calendar availability viewer for customers and admins
/// Shows service availability in a visual calendar format
class ReadOnlyCalendarAvailability extends StatefulWidget {
  final Set<DateTime> availableDates;
  final Set<DateTime> unavailableDates;
  final bool useWhitelist;
  final String title;

  const ReadOnlyCalendarAvailability({
    super.key,
    required this.availableDates,
    required this.unavailableDates,
    required this.useWhitelist,
    this.title = 'Service Availability',
  });

  @override
  State<ReadOnlyCalendarAvailability> createState() => _ReadOnlyCalendarAvailabilityState();
}

class _ReadOnlyCalendarAvailabilityState extends State<ReadOnlyCalendarAvailability> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isDateAvailable(DateTime date) {
    final normalized = _normalizeDate(date);
    if (widget.useWhitelist) {
      // In whitelist mode, only listed dates are available
      return widget.availableDates.contains(normalized);
    } else {
      // In blacklist mode, all dates available except listed
      return !widget.unavailableDates.contains(normalized);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Availability Info'),
                    content: Text(
                      widget.useWhitelist
                          ? 'Green dates are available for booking. Other dates are not available.'
                          : 'All dates are available except red dates which are blocked.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Mode indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.useWhitelist ? Colors.green.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.useWhitelist ? Colors.green.shade200 : Colors.blue.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.useWhitelist ? Icons.event_available : Icons.event,
                color: widget.useWhitelist ? Colors.green : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.useWhitelist
                      ? 'Only green dates are available for booking'
                      : 'All dates available except blocked dates',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.useWhitelist ? Colors.green.shade900 : Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calendar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.shade200,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, false, false);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, true, false);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, false, true);
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendItem(Colors.green.shade100, 'Available'),
            if (!widget.useWhitelist)
              _buildLegendItem(Colors.red.shade100, 'Blocked'),
            _buildLegendItem(Colors.grey.shade200, 'Not Available'),
          ],
        ),
        const SizedBox(height: 16),

        // Summary
        if (widget.useWhitelist && widget.availableDates.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.availableDates.length} dates available for booking',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!widget.useWhitelist && widget.unavailableDates.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.block, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.unavailableDates.length} dates blocked',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isSelected) {
    final normalized = _normalizeDate(day);
    final isAvailable = _isDateAvailable(day);
    final isInPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    Color? backgroundColor;
    Color? textColor;

    if (isSelected) {
      backgroundColor = Colors.blue.shade600;
      textColor = Colors.white;
    } else if (isInPast) {
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey.shade400;
    } else if (isAvailable) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
    } else {
      backgroundColor = widget.useWhitelist ? Colors.grey.shade200 : Colors.red.shade100;
      textColor = widget.useWhitelist ? Colors.grey.shade600 : Colors.red.shade900;
    }

    if (isToday && !isSelected) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
