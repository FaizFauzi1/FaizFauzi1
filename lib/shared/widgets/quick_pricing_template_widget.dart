import 'package:flutter/material.dart';

class QuickPricingTemplateWidget extends StatelessWidget {
  final Function(Map<String, dynamic>) onTemplateApplied;

  const QuickPricingTemplateWidget({
    Key? key,
    required this.onTemplateApplied,
  }) : super(key: key);

  final List<Map<String, dynamic>> _templates = const [
    {
      'name': 'Basic Package',
      'pricing': {'basic': 100.0, 'standard': 150.0, 'premium': 200.0, 'enterprise': 250.0},
    },
    {
      'name': 'Premium Package',
      'pricing': {'basic': 200.0, 'standard': 300.0, 'premium': 400.0, 'enterprise': 500.0},
    },
    {
      'name': 'Enterprise Package',
      'pricing': {'basic': 500.0, 'standard': 750.0, 'premium': 1000.0, 'enterprise': 1500.0},
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Pricing Templates',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._templates.map((template) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed: () => onTemplateApplied(template['pricing'] as Map<String, dynamic>),
                child: Text(template['name'] as String),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
