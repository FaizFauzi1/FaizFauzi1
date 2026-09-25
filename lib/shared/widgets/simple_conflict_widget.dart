import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class SimpleConflictWidget extends StatelessWidget {
  final List<String> conflicts;
  final VoidCallback? onResolve;
  final VoidCallback? onIgnore;

  const SimpleConflictWidget({
    super.key,
    required this.conflicts,
    this.onResolve,
    this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
    if (conflicts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Text(
              'No conflicts detected!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                '${conflicts.length} conflicts detected',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...conflicts.map((conflict) => _buildConflictItem(conflict)),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildConflictItem(String conflict) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              conflict,
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onResolve != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onResolve,
              icon: const Icon(Icons.edit),
              label: const Text('Resolve'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
        if (onResolve != null && onIgnore != null) const SizedBox(width: 12),
        if (onIgnore != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onIgnore,
              icon: const Icon(Icons.warning),
              label: const Text('Proceed Anyway'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class AutomatedBookingWidget extends StatefulWidget {
  final Function(DateTime, String) onSlotSelected;

  const AutomatedBookingWidget({
    super.key,
    required this.onSlotSelected,
  });

  @override
  State<AutomatedBookingWidget> createState() => _AutomatedBookingWidgetState();
}

class _AutomatedBookingWidgetState extends State<AutomatedBookingWidget> {
  late DateTime _selectedDate;
  bool _isLoading = false;
  List<String> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    // Mock available slots
    setState(() {
      _availableSlots = [
        '09:00 - 10:00',
        '10:30 - 11:30',
        '14:00 - 15:00',
        '15:30 - 16:30',
        '18:00 - 19:00',
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automated Booking',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Select Date:',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_availableSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No available slots found',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _availableSlots.length,
              itemBuilder: (context, index) {
                return _buildSlotCard(_availableSlots[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSlotCard(String timeSlot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          final slotTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            int.parse(timeSlot.split(':')[0]),
            0,
          );
          widget.onSlotSelected(slotTime, timeSlot);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  timeSlot,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Available',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadSlots();
    }
  }
}
