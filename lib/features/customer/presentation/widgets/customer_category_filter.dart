import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/event/data/models/event_type.dart';

class CustomerCategoryFilter extends StatelessWidget {
  final EventType? selectedEventType;
  final Function(EventType?) onEventTypeSelected;

  const CustomerCategoryFilter({
    super.key,
    required this.selectedEventType,
    required this.onEventTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: EventType.values.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedEventType == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All Event Types'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) onEventTypeSelected(null);
                },
                backgroundColor: Colors.white,
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  ),
                ),
              ),
            );
          }

          final eventType = EventType.values[index - 1];
          final isSelected = selectedEventType == eventType;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                eventType.icon,
                size: 16,
                color: isSelected ? eventType.color : Colors.grey,
              ),
              label: Text(eventType.displayName),
              selected: isSelected,
              onSelected: (selected) {
                 onEventTypeSelected(selected ? eventType : null);
              },
              backgroundColor: Colors.white,
              selectedColor: eventType.color.withOpacity(0.1),
              labelStyle: TextStyle(
                color: isSelected ? eventType.color : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? eventType.color : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
