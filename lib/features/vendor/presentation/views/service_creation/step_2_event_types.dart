import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'service_creation_state.dart';
import 'package:eventease/shared/models/event/event_type.dart';

class Step2EventTypes extends StatelessWidget {
  const Step2EventTypes({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch state for rebuilds on selection change
    final state = Provider.of<ServiceCreationState>(context);
    final allEvents = PredefinedEventTypes.getAllEventTypes();
    
    // Group events by category
    final weddingEvents = allEvents.where((e) => e.category == 'wedding').toList();
    final corporateEvents = allEvents.where((e) => e.category == 'corporate').toList();
    final socialEvents = allEvents.where((e) => e.category == 'social').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What type of events is this service for?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all that apply. This helps customers find you.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          _buildCategorySection(context, 'Wedding Events', weddingEvents, state),
          const SizedBox(height: 24),
          _buildCategorySection(context, 'Corporate Events', corporateEvents, state),
          const SizedBox(height: 24),
          _buildCategorySection(context, 'Social & Parties', socialEvents, state),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, String title, List<EventType> events, ServiceCreationState state) {
    if (events.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: events.map((event) {
            final isSelected = state.selectedEventTypes.contains(event.code);
            return FilterChip(
              label: Text(event.displayName),
              selected: isSelected,
              onSelected: (_) => state.toggleEventType(event.code),
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
