import 'package:flutter/material.dart';
import 'package:eventease/features/event/data/models/event.dart';

class MealPreferencesScreen extends StatefulWidget {
  final Event event;

  const MealPreferencesScreen({
    super.key,
    required this.event,
  });

  @override
  State<MealPreferencesScreen> createState() => _MealPreferencesScreenState();
}

class _MealPreferencesScreenState extends State<MealPreferencesScreen> {
  final Map<String, bool> _mealOptions = {
    'Vegetarian': false,
    'Vegan': false,
    'Gluten-Free': false,
    'Halal': false,
    'Kosher': false,
    'No Preference': true,
  };

  @override
  Widget build(BuildContext context) {
    // Check if meal preferences feature is enabled
    final guestFeatures = widget.event.additionalInfo['guestFeatures'] as Map<String, dynamic>? ?? {};
    final isMealPreferencesEnabled = guestFeatures['Meal Preferences'] ?? false;

    if (!isMealPreferencesEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.event.title} - Meal Preferences'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: _buildFeatureDisabledState('Meal Preferences'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event.title} - Meal Preferences'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select your meal preferences',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _mealOptions.keys.map((option) {
                  return CheckboxListTile(
                    title: Text(option),
                    value: _mealOptions[option],
                    onChanged: (bool? value) {
                      setState(() {
                        if (option == 'No Preference') {
                          // If No Preference selected, uncheck others
                          _mealOptions.updateAll((key, _) => false);
                          _mealOptions['No Preference'] = value ?? false;
                        } else {
                          _mealOptions[option] = value ?? false;
                          if (_mealOptions.values.any((v) => v)) {
                            _mealOptions['No Preference'] = false;
                          } else {
                            _mealOptions['No Preference'] = true;
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: _savePreferences,
              child: const Text('Save Preferences'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePreferences() {
    final selectedOptions = _mealOptions.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // TODO: Save preferences to backend or local storage

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selectedOptions.isEmpty
              ? 'No meal preferences selected.'
              : 'Saved preferences: ${selectedOptions.join(', ')}',
        ),
      ),
    );
  }

  Widget _buildFeatureDisabledState(String featureName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '$featureName Disabled',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature has been disabled by the event host.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
