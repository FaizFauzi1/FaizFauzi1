import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class ServiceCapabilityStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onChanged;

  const ServiceCapabilityStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<ServiceCapabilityStep> createState() => _ServiceCapabilityStepState();
}

class _ServiceCapabilityStepState extends State<ServiceCapabilityStep> {
  late TextEditingController _coverageStateController;
  late TextEditingController _coverageCityController;
  late TextEditingController _radiusController;
  late TextEditingController _maxPaxController;
  late TextEditingController _minOrderController;
  late TextEditingController _setupTimeController;
  late TextEditingController _breakdownTimeController;
  late TextEditingController _teamSizeController;
  late TextEditingController _equipmentController;
  
  bool _backupTeamAvailable = false;

  @override
  void initState() {
    super.initState();
    _coverageStateController = TextEditingController(text: widget.data['coverage_area_state']);
    _coverageCityController = TextEditingController(text: widget.data['coverage_area_city']);
    _radiusController = TextEditingController(text: widget.data['coverage_radius_km']?.toString());
    _maxPaxController = TextEditingController(text: widget.data['service_max_pax']?.toString());
    _minOrderController = TextEditingController(text: widget.data['min_order_amount']?.toString());
    _setupTimeController = TextEditingController(text: widget.data['setup_time_hours']?.toString());
    _breakdownTimeController = TextEditingController(text: widget.data['breakdown_time_hours']?.toString());
    _teamSizeController = TextEditingController(text: widget.data['team_size_per_event']?.toString());
    _equipmentController = TextEditingController(text: widget.data['equipment_provided']);
    
    _backupTeamAvailable = widget.data['backup_team_available'] ?? false;
    
    _setupListeners();
  }

  void _setupListeners() {
    void listener() => _updateParent();
    _coverageStateController.addListener(listener);
    _coverageCityController.addListener(listener);
    _radiusController.addListener(listener);
    _maxPaxController.addListener(listener);
    _minOrderController.addListener(listener);
    _setupTimeController.addListener(listener);
    _breakdownTimeController.addListener(listener);
    _teamSizeController.addListener(listener);
    _equipmentController.addListener(listener);
  }

  void _updateParent() {
    widget.onChanged({
      'coverage_area_state': _coverageStateController.text,
      'coverage_area_city': _coverageCityController.text,
      'coverage_radius_km': int.tryParse(_radiusController.text),
      'service_max_pax': int.tryParse(_maxPaxController.text),
      'min_order_amount': double.tryParse(_minOrderController.text),
      'setup_time_hours': double.tryParse(_setupTimeController.text),
      'breakdown_time_hours': double.tryParse(_breakdownTimeController.text),
      'team_size_per_event': int.tryParse(_teamSizeController.text),
      'equipment_provided': _equipmentController.text,
      'backup_team_available': _backupTeamAvailable,
    });
  }

  @override
  void dispose() {
    _coverageStateController.dispose();
    _coverageCityController.dispose();
    _radiusController.dispose();
    _maxPaxController.dispose();
    _minOrderController.dispose();
    _setupTimeController.dispose();
    _breakdownTimeController.dispose();
    _teamSizeController.dispose();
    _equipmentController.dispose();
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
            'Service Capabilities',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Define your operational capacity and coverage',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Coverage Area'),
          Row(
            children: [
              Expanded(child: _buildTextField('State', _coverageStateController)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('City', _coverageCityController)),
            ],
          ),
           _buildTextField('Service Radius (KM)', _radiusController, isNumber: true, hint: 'e.g. 50'),

          const SizedBox(height: 24),
          _buildSectionHeader('Capacity & Team'),
          Row(
             children: [
               Expanded(child: _buildTextField('Max Pax Capacity', _maxPaxController, isNumber: true, hint: 'e.g. 1000')),
               const SizedBox(width: 16),
               Expanded(child: _buildTextField('Min Order (RM)', _minOrderController, isNumber: true, hint: 'e.g. 500')),
             ],
           ),
           Row(
             children: [
               Expanded(child: _buildTextField('Setup Time (Hrs)', _setupTimeController, isNumber: true)),
               const SizedBox(width: 16),
               Expanded(child: _buildTextField('Breakdown Time', _breakdownTimeController, isNumber: true)),
             ],
           ),
           _buildTextField('Standard Team Size', _teamSizeController, isNumber: true, hint: 'Pax per event'),
           SwitchListTile(
               title: const Text('Backup Team Available?'),
               subtitle: const Text('In case of emergency staffing issues'),
               value: _backupTeamAvailable,
               onChanged: (val) {
                 setState(() => _backupTeamAvailable = val);
                 _updateParent();
               },
               activeColor: AppTheme.primaryColor,
           ),

          const SizedBox(height: 24),
          _buildSectionHeader('Equipment'),
          _buildTextField('Equipment Provided', _equipmentController, maxLines: 4, hint: 'List major equipment you bring (e.g. Tables, Chairs, Sound System, Ovens...)'),
        ],
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
    {bool isNumber = false, String? hint, int maxLines = 1}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
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
