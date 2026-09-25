import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/presentation/components/prep_timeline_builder.dart';
import 'package:eventease/shared/models/services/wedding_preparation_timeline.dart';
import 'service_creation_state.dart';

class Step8PrepTimeline extends StatelessWidget {
  const Step8PrepTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide a stable UI to manage timeline using the global ServiceCreationState
    final state = Provider.of<ServiceCreationState>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: PrepTimelineBuilder(
        initialMilestones: state.weddingTimeline,
        onChanged: (newTimeline) {
          state.setWeddingTimeline(newTimeline);
        },
      ),
    );
  }
}
