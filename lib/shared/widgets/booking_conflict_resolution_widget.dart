import 'package:eventease/core/utils/booking_conflict_detector.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:flutter/material.dart';

class BookingConflictResolutionWidget extends StatelessWidget {
  final List<BookingConflict> conflicts;
  final VoidCallback? onResolveConflicts;
  final VoidCallback? onIgnoreConflicts;

  const BookingConflictResolutionWidget({
    super.key,
    required this.conflicts,
    this.onResolveConflicts,
    this.onIgnoreConflicts,
  });

  @override
  Widget build(BuildContext context) {
    if (conflicts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No conflicts detected! Your booking can proceed.',
                style: TextStyle(
                  color: Colors.green[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  BookingConflictDetector.getConflictSummary(conflicts),
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
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

  Widget _buildConflictItem(BookingConflict conflict) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getSeverityColor(conflict.severity).withValues(alpha: 0.1),
        border: Border.all(
          color: _getSeverityColor(conflict.severity).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSeverityIcon(conflict.severity),
                color: _getSeverityColor(conflict.severity),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                conflict.type.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: _getSeverityColor(conflict.severity),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getSeverityColor(conflict.severity),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  conflict.severity.toString().split('.').last,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conflict.message,
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
            ),
          ),
          if (conflict.conflictingBooking != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Conflicting booking: ${conflict.conflictingBooking!.customerName} on ${conflict.conflictingBooking!.bookingDate.toString().split(' ')[0]}',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ...ConflictResolutionSuggestion.getSuggestions(conflict).map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_right,
                    size: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
        if (onResolveConflicts != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onResolveConflicts,
              icon: const Icon(Icons.edit),
              label: const Text('Resolve'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        if (onResolveConflicts != null && onIgnoreConflicts != null)
          const SizedBox(width: 12),
        if (onIgnoreConflicts != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onIgnoreConflicts,
              icon: const Icon(Icons.warning),
              label: const Text('Proceed Anyway'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getSeverityColor(ConflictSeverity severity) {
    switch (severity) {
      case ConflictSeverity.critical:
        return Colors.red;
      case ConflictSeverity.high:
        return Colors.orange;
      case ConflictSeverity.medium:
        return Colors.yellow[700]!;
      case ConflictSeverity.low:
        return Colors.blue;
    }
  }

  IconData _getSeverityIcon(ConflictSeverity severity) {
    switch (severity) {
      case ConflictSeverity.critical:
        return Icons.error;
      case ConflictSeverity.high:
        return Icons.warning;
      case ConflictSeverity.medium:
        return Icons.info;
      case ConflictSeverity.low:
        return Icons.info_outline;
    }
  }
}

class AutomatedSchedulingWidget extends StatefulWidget {
  final VendorServiceEnhanced service;
  final List<Booking> existingBookings;
  final Duration bookingDuration;
  final Function(TimeSlotSuggestion) onSlotSelected;

  const AutomatedSchedulingWidget({
    super.key,
    required this.service,
    required this.existingBookings,
    required this.bookingDuration,
    required this.onSlotSelected,
  });

  @override
  State<AutomatedSchedulingWidget> createState() => _AutomatedSchedulingWidgetState();
}

class _AutomatedSchedulingWidgetState extends State<AutomatedSchedulingWidget> {
  late DateTime _selectedDate;
  List<TimeSlotSuggestion>? _suggestions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    final suggestions = AutomatedSchedulingService.suggestAvailableSlots(
      service: widget.service,
      date: _selectedDate,
      duration: widget.bookingDuration,
      existingBookings: widget.existingBookings,
    );

    setState(() {
      _suggestions = suggestions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automated Scheduling',
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
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
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
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (_suggestions == null || _suggestions!.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No available slots found for this date',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _suggestions!.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions![index];
                return _buildSlotCard(suggestion);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSlotCard(TimeSlotSuggestion suggestion) {
    final hasConflicts = suggestion.conflicts.isNotEmpty;
    final isAvailable = suggestion.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: isAvailable ? () => widget.onSlotSelected(suggestion) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasConflicts
                  ? Colors.orange.withValues(alpha: 0.3)
                  : isAvailable
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      suggestion.timeRange,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isAvailable
                            ? AppTheme.textPrimaryColor
                            : AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        color: isAvailable ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Duration: ${suggestion.duration.inHours}h ${suggestion.duration.inMinutes.remainder(60)}m',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
              if (hasConflicts) ...[
                const SizedBox(height: 8),
                Text(
                  '${suggestion.conflicts.length} conflicts detected',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
      _loadSuggestions();
    }
  }
}
