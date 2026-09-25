import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

/// Calendar-based availability selector for services
/// Allows vendors to select specific available/unavailable dates
class CalendarAvailabilityWidget extends StatefulWidget {
  final Set<DateTime> initialAvailableDates;
  final Set<DateTime> initialUnavailableDates;
  final bool useWhitelist; // true = only listed dates available, false = all except listed
  final Function(Set<DateTime> availableDates, Set<DateTime> unavailableDates, bool useWhitelist) onChanged;

  const CalendarAvailabilityWidget({
    super.key,
    required this.initialAvailableDates,
    required this.initialUnavailableDates,
    required this.useWhitelist,
    required this.onChanged,
  });

  @override
  State<CalendarAvailabilityWidget> createState() => _CalendarAvailabilityWidgetState();
}

class _CalendarAvailabilityWidgetState extends State<CalendarAvailabilityWidget> {
  late Set<DateTime> _availableDates;
  late Set<DateTime> _unavailableDates;
  late bool _useWhitelist;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _availableDates = Set.from(widget.initialAvailableDates);
    _unavailableDates = Set.from(widget.initialUnavailableDates);
    _useWhitelist = widget.useWhitelist;
  }

  void _notifyChange() {
    widget.onChanged(_availableDates, _unavailableDates, _useWhitelist);
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!_isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _toggleDateAvailability(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _toggleDateRangeAvailability(start, end);
    }
  }

  void _toggleDateAvailability(DateTime date) {
    final normalized = _normalizeDate(date);
    setState(() {
      if (_useWhitelist) {
        // In whitelist mode, toggle available dates
        if (_availableDates.contains(normalized)) {
          _availableDates.remove(normalized);
        } else {
          _availableDates.add(normalized);
          _unavailableDates.remove(normalized); // Remove from unavailable if present
        }
      } else {
        // In blacklist mode, toggle unavailable dates
        if (_unavailableDates.contains(normalized)) {
          _unavailableDates.remove(normalized);
        } else {
          _unavailableDates.add(normalized);
          _availableDates.remove(normalized); // Remove from available if present
        }
      }
    });
    _notifyChange();
  }

  void _toggleDateRangeAvailability(DateTime start, DateTime end) {
    final normalizedStart = _normalizeDate(start);
    final normalizedEnd = _normalizeDate(end);
    
    setState(() {
      for (var date = normalizedStart;
          date.isBefore(normalizedEnd.add(const Duration(days: 1)));
          date = date.add(const Duration(days: 1))) {
        final normalized = _normalizeDate(date);
        
        if (_useWhitelist) {
          _availableDates.add(normalized);
          _unavailableDates.remove(normalized);
        } else {
          _unavailableDates.add(normalized);
          _availableDates.remove(normalized);
        }
      }
    });
    _notifyChange();
  }

  void _clearAll() {
    setState(() {
      _availableDates.clear();
      _unavailableDates.clear();
    });
    _notifyChange();
  }

  void _toggleMode() {
    setState(() {
      _useWhitelist = !_useWhitelist;
      // Swap the sets when toggling mode
      final temp = _availableDates;
      _availableDates = _unavailableDates;
      _unavailableDates = temp;
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with mode toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Service Availability',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'clear':
                    _clearAll();
                    break;
                  case 'toggle_mode':
                    _toggleMode();
                    break;
                  case 'range':
                    setState(() {
                      _rangeSelectionMode = _rangeSelectionMode == RangeSelectionMode.toggledOff
                          ? RangeSelectionMode.toggledOn
                          : RangeSelectionMode.toggledOff;
                    });
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'range',
                  child: Row(
                    children: [
                      Icon(
                        _rangeSelectionMode == RangeSelectionMode.toggledOn
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Range Selection'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'toggle_mode',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 20),
                      SizedBox(width: 8),
                      Text('Toggle Mode'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Mode indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _useWhitelist ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _useWhitelist ? Colors.green.shade200 : Colors.orange.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _useWhitelist ? Icons.check_circle : Icons.block,
                color: _useWhitelist ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _useWhitelist
                      ? 'Available Dates Mode: Only selected dates are available'
                      : 'Blocked Dates Mode: All dates available except selected',
                  style: TextStyle(
                    fontSize: 13,
                    color: _useWhitelist ? Colors.green.shade900 : Colors.orange.shade900,
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
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: _calendarFormat,
            rangeSelectionMode: _rangeSelectionMode,
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
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
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              rangeHighlightColor: Colors.blue.shade100,
              rangeStartDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.green,
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
          ),
        ),
        const SizedBox(height: 16),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendItem(Colors.green, 'Available'),
            _buildLegendItem(Colors.red, 'Unavailable'),
            _buildLegendItem(Colors.grey.shade300, 'Not Set'),
          ],
        ),
        const SizedBox(height: 16),

        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Available',
                _availableDates.length.toString(),
                Colors.green,
              ),
              _buildSummaryItem(
                'Unavailable',
                _unavailableDates.length.toString(),
                Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isSelected) {
    final normalized = _normalizeDate(day);
    final isAvailable = _availableDates.contains(normalized);
    final isUnavailable = _unavailableDates.contains(normalized);

    Color? backgroundColor;
    Color? textColor;

    if (isSelected) {
      backgroundColor = Colors.blue;
      textColor = Colors.white;
    } else if (isAvailable) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
    } else if (isUnavailable) {
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
    } else if (isToday) {
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade900;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isToday && !isSelected
            ? Border.all(color: Colors.blue, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor ?? Colors.black87,
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

  Widget _buildSummaryItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
