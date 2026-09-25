import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class OperationsStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onChanged;

  const OperationsStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<OperationsStep> createState() => _OperationsStepState();
}

class _OperationsStepState extends State<OperationsStep> {
  late TextEditingController _maxBookingsController;
  late TextEditingController _leadTimeController;
  
  bool _sameDayBooking = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<String> _selectedDays = [];
  final List<String> _daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _maxBookingsController = TextEditingController(text: widget.data['max_bookings_per_day']?.toString() ?? '1');
    _leadTimeController = TextEditingController(text: widget.data['lead_time_days']?.toString() ?? '3');
    _sameDayBooking = widget.data['same_day_booking_allowed'] ?? false;
    
    // Parse times
    if (widget.data['operating_hours_start'] != null) {
        // Assuming HH:MM format from DB/String
        _startTime = _parseTime(widget.data['operating_hours_start']);
    } else {
        _startTime = const TimeOfDay(hour: 9, minute: 0);
    }

    if (widget.data['operating_hours_end'] != null) {
        _endTime = _parseTime(widget.data['operating_hours_end']);
    } else {
        _endTime = const TimeOfDay(hour: 18, minute: 0);
    }
    
    if (widget.data['operating_days'] != null) {
       _selectedDays.addAll(List<String>.from(widget.data['operating_days']));
    } else {
       // Default Mon-Fri
       _selectedDays.addAll(['Mon', 'Tue', 'Wed', 'Thu', 'Fri']);
    }

    _setupListeners();
  }

  TimeOfDay _parseTime(String timeStr) {
      // Very specific parser for HH:MM:SS or HH:MM
      try {
        final parts = timeStr.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
          return const TimeOfDay(hour: 9, minute: 0);
      }
  }

  void _setupListeners() {
    void listener() => _updateParent();
    _maxBookingsController.addListener(listener);
    _leadTimeController.addListener(listener);
  }

  void _updateParent() {
    widget.onChanged({
      'operating_days': _selectedDays,
      'operating_hours_start': _formatTime(_startTime),
      'operating_hours_end': _formatTime(_endTime),
      'max_bookings_per_day': int.tryParse(_maxBookingsController.text),
      'lead_time_days': int.tryParse(_leadTimeController.text),
      'same_day_booking_allowed': _sameDayBooking,
      // Blackout dates handled separately/later due to complexity
      'blackout_dates': [], 
    });
  }

  String _formatTime(TimeOfDay? time) {
      if (time == null) return "09:00";
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
  }

  @override
  void dispose() {
    _maxBookingsController.dispose();
    _leadTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'When are you available to accept bookings?',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Operating Days'),
          Wrap(
            spacing: 8,
            children: _daysOfWeek.map((day) {
               final isSelected = _selectedDays.contains(day);
               return FilterChip(
                 label: Text(day),
                 selected: isSelected,
                 onSelected: (selected) {
                   setState(() {
                     if (selected) {
                       _selectedDays.add(day);
                     } else {
                       _selectedDays.remove(day);
                     }
                   });
                   _updateParent();
                 },
                 selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                 checkmarkColor: AppTheme.primaryColor,
               );
            }).toList(),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Operating Hours'),
          Row(
            children: [
                Expanded(child: _buildTimePicker('Start Time', _startTime, (t) {
                    setState(() => _startTime = t);
                    _updateParent();
                })),
                const SizedBox(width: 16),
                Expanded(child: _buildTimePicker('End Time', _endTime, (t) {
                    setState(() => _endTime = t);
                    _updateParent();
                })),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Booking Rules'),
          Row(
             children: [
               Expanded(child: _buildTextField('Max Bookings / Day', _maxBookingsController, isNumber: true)),
               const SizedBox(width: 16),
               Expanded(child: _buildTextField('Min Lead Time (Days)', _leadTimeController, isNumber: true, hint: 'e.g. 3')),
             ],
           ),
           SwitchListTile(
               title: const Text('Allow Same-Day Bookings?'),
               value: _sameDayBooking,
               onChanged: (val) {
                 setState(() => _sameDayBooking = val);
                 _updateParent();
               },
               activeColor: AppTheme.primaryColor,
           ),
        ],
      ),
    );
  }
  
  Widget _buildTimePicker(String label, TimeOfDay? time, Function(TimeOfDay) OnPicked) {
    return InkWell(
        onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: time ?? TimeOfDay.now());
            if (picked != null) OnPicked(picked);
        },
        child: InputDecorator(
            decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: const Icon(Icons.access_time),
            ),
            child: Text(time?.format(context) ?? 'Select Time'),
        ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    {bool isNumber = false, String? hint}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
