import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/presentation/components/service_guarantee_builder.dart';
import 'service_creation_state.dart';

class Step9Guarantee extends StatelessWidget {
  const Step9Guarantee({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide a stable UI to manage guarantee using the global ServiceCreationState
    final state = Provider.of<ServiceCreationState>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ServiceGuaranteeBuilder(
        initialGuarantee: state.guarantee,
        onChanged: (newGuarantee) {
          state.updateGuarantee(newGuarantee);
        },
      ),
    );
  }
}
