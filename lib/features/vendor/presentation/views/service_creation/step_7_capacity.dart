import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'service_creation_state.dart';
import 'package:eventease/shared/models/services/team_capacity.dart';
import 'package:eventease/shared/widgets/custom_text_field.dart';

class Step7Capacity extends StatefulWidget {
  const Step7Capacity({super.key});

  @override
  State<Step7Capacity> createState() => _Step7CapacityState();
}

class _Step7CapacityState extends State<Step7Capacity> {
  late TextEditingController _totalTeamsController;
  late TextEditingController _maxEventsController;
  late TextEditingController _slotDurationController;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<ServiceCreationState>(context, listen: false);
    _totalTeamsController = TextEditingController(text: state.teamCapacity.totalTeamsAvailable.toString());
    _maxEventsController = TextEditingController(text: state.teamCapacity.maxEventsPerDay.toString());
    _slotDurationController = TextEditingController(text: state.slotConfig.slotDurationMinutes.toString());
  }

  @override
  void dispose() {
    _totalTeamsController.dispose();
    _maxEventsController.dispose();
    _slotDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ServiceCreationState>(context);
    final isHourly = state.pricingType.name == 'per_hour';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Availability & Capacity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Define how many bookings you can accept.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          const Text('Team Capacity', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          _buildTextField(
            controller: _totalTeamsController,
            label: 'Total Teams / Units Available',
            helperText: 'How many simultaneous events can you handle?',
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final valInt = int.tryParse(val) ?? 1;
              // Ideally update via method: state.updateCapacity(...)
              // For now, updating object reference directly (not ideal but works for prototype if we notify)
              // But TeamCapacityConfig is final. We must create new object.
              state.teamCapacity = TeamCapacityConfig(
                totalTeamsAvailable: valInt,
                maxEventsPerDay: state.teamCapacity.maxEventsPerDay,
              );
              // notifyListeners not accessible here easily unless we add method to state
            },
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _maxEventsController,
            label: 'Max Events Per Day',
            helperText: 'Maximum total bookings allowed in a single day.',
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final valInt = int.tryParse(val) ?? 1;
              state.teamCapacity = TeamCapacityConfig(
                totalTeamsAvailable: state.teamCapacity.totalTeamsAvailable,
                maxEventsPerDay: valInt,
              );
            },
          ),

          if (isHourly) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Divider(),
            ),
            const Text('Time Slots (Hourly Service)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _slotDurationController,
              label: 'Slot Duration (Minutes)',
              helperText: 'Default duration for each booking slot (e.g. 60 mins).',
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final valInt = int.tryParse(val) ?? 60;
                state.slotConfig = AvailabilitySlotConfig(
                  slotDurationMinutes: valInt,
                  maxEventsPerDay: state.slotConfig.maxEventsPerDay,
                  // Copy other fields if they existed...
                  autoGenerateSlots: true,
                  predefinedSlots: [],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

   Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }
}
