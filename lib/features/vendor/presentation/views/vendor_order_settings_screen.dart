import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/models/vendor_order_settings.dart';
import 'package:uuid/uuid.dart';

class VendorOrderSettingsScreen extends StatefulWidget {
  final String vendorId;

  const VendorOrderSettingsScreen({
    super.key,
    required this.vendorId,
  });

  @override
  State\u003cVendorOrderSettingsScreen\u003e createState() =\u003e _VendorOrderSettingsScreenState();
}

class _VendorOrderSettingsScreenState extends State\u003cVendorOrderSettingsScreen\u003e {
  bool _isLoading = true;
  bool _isSaving = false;
  VendorOrderSettings? _settings;

  // Form controllers
  final _orderInstructionsController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _maxQuantityController = TextEditingController();

  // Form state
  bool _requireEventDate = true;
  bool _requireEventTime = false;
  bool _requireDeliveryAddress = false;
  bool _requireSpecialRequirements = false;
  bool _showQuantityField = true;
  bool _showDeliveryMethod = true;
  String _defaultDeliveryMethod = 'Pickup';
  bool _autoApproveOrders = false;
  List\u003cCustomOrderField\u003e _customFields = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _orderInstructionsController.dispose();
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    super.dispose();
  }

  Future\u003cvoid\u003e _loadSettings() async {
    setState(() =\u003e _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('vendor_order_settings')
          .select()
          .eq('vendor_id', widget.vendorId)
          .maybeSingle();

      if (response != null) {
        _settings = VendorOrderSettings.fromSupabase(response);
        _applySettingsToForm();
      } else {
        // Use default settings
        _settings = VendorOrderSettings.defaultSettings(widget.vendorId);
        _applySettingsToForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    } finally {
      setState(() =\u003e _isLoading = false);
    }
  }

  void _applySettingsToForm() {
    if (_settings == null) return;
    setState(() {
      _requireEventDate = _settings!.requireEventDate;
      _requireEventTime = _settings!.requireEventTime;
      _requireDeliveryAddress = _settings!.requireDeliveryAddress;
      _requireSpecialRequirements = _settings!.requireSpecialRequirements;
      _showQuantityField = _settings!.showQuantityField;
      _showDeliveryMethod = _settings!.showDeliveryMethod;
      _defaultDeliveryMethod = _settings!.defaultDeliveryMethod;
      _autoApproveOrders = _settings!.autoApproveOrders;
      _customFields = List.from(_settings!.customFields);
      _orderInstructionsController.text = _settings!.orderInstructions ?? '';
      _minQuantityController.text = _settings!.minOrderQuantity.toString();
      _maxQuantityController.text = _settings!.maxOrderQuantity.toString();
    });
  }

  Future\u003cvoid\u003e _saveSettings() async {
    setState(() =\u003e _isSaving = true);
    try {
      final updatedSettings = VendorOrderSettings(
        vendorId: widget.vendorId,
        requireEventDate: _requireEventDate,
        requireEventTime: _requireEventTime,
        requireDeliveryAddress: _requireDeliveryAddress,
        requireSpecialRequirements: _requireSpecialRequirements,
        showQuantityField: _showQuantityField,
        showDeliveryMethod: _showDeliveryMethod,
        defaultDeliveryMethod: _defaultDeliveryMethod,
        minOrderQuantity: int.tryParse(_minQuantityController.text) ?? 1,
        maxOrderQuantity: int.tryParse(_maxQuantityController.text) ?? 999,
        customFields: _customFields,
        autoApproveOrders: _autoApproveOrders,
        orderInstructions: _orderInstructionsController.text.isNotEmpty
            ? _orderInstructionsController.text
            : null,
        createdAt: _settings?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await Supabase.instance.client
          .from('vendor_order_settings')
          .upsert(updatedSettings.toSupabaseJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order settings saved successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() =\u003e _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Order Form Settings',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Order Instructions'),
                  _buildInstructionsField(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Required Fields'),
                  _buildRequiredFieldsSection(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Quantity Settings'),
                  _buildQuantitySettings(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Delivery Options'),
                  _buildDeliverySettings(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Order Approval'),
                  _buildApprovalSettings(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Custom Fields'),
                  _buildCustomFieldsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildInstructionsField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _orderInstructionsController,
        decoration: const InputDecoration(
          labelText: 'Instructions for Customers',
          hintText: 'e.g., "Please provide event date and guest count"',
          border: OutlineInputBorder(),
          helperText: 'This message will appear at the top of the order form',
        ),
        maxLines: 3,
      ),
    );
  }

  Widget _buildRequiredFieldsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Require Event Date'),
            subtitle: const Text('Customers must select an event date'),
            value: _requireEventDate,
            onChanged: (value) =\u003e setState(() =\u003e _requireEventDate = value),
            activeColor: AppTheme.primaryColor,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Require Event Time'),
            subtitle: const Text('Customers must select an event time'),
            value: _requireEventTime,
            onChanged: (value) =\u003e setState(() =\u003e _requireEventTime = value),
            activeColor: AppTheme.primaryColor,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Require Delivery Address'),
            subtitle: const Text('Customers must provide delivery address'),
            value: _requireDeliveryAddress,
            onChanged: (value) =\u003e setState(() =\u003e _requireDeliveryAddress = value),
            activeColor: AppTheme.primaryColor,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Require Special Requirements'),
            subtitle: const Text('Customers must fill special requirements field'),
            value: _requireSpecialRequirements,
            onChanged: (value) =\u003e setState(() =\u003e _requireSpecialRequirements = value),
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Show Quantity Field'),
            subtitle: const Text('Allow customers to specify quantity'),
            value: _showQuantityField,
            onChanged: (value) =\u003e setState(() =\u003e _showQuantityField = value),
            activeColor: AppTheme.primaryColor,
          ),
          if (_showQuantityField) ...[\n            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliverySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Show Delivery Method'),
            subtitle: const Text('Allow customers to choose delivery method'),
            value: _showDeliveryMethod,
            onChanged: (value) =\u003e setState(() =\u003e _showDeliveryMethod = value),
            activeColor: AppTheme.primaryColor,
          ),
          if (_showDeliveryMethod) ...[\n            const SizedBox(height: 16),
            DropdownButtonFormField\u003cString\u003e(
              value: _defaultDeliveryMethod,
              decoration: const InputDecoration(
                labelText: 'Default Delivery Method',
                border: OutlineInputBorder(),
              ),
              items: ['Pickup', 'Delivery'].map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() =\u003e _defaultDeliveryMethod = value);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: const Text('Auto-Approve Orders'),
        subtitle: const Text('Automatically approve all incoming orders'),
        value: _autoApproveOrders,
        onChanged: (value) =\u003e setState(() =\u003e _autoApproveOrders = value),
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildCustomFieldsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add custom fields to collect specific information',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 16),
          if (_customFields.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No custom fields added yet',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
            )
          else
            ..._customFields.asMap().entries.map((entry) {
              final index = entry.key;
              final field = entry.value;
              return _buildCustomFieldTile(field, index);
            }).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addCustomField,
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Field'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFieldTile(CustomOrderField field, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_getFieldIcon(field.fieldType), color: AppTheme.primaryColor),
        title: Text(field.label),
        subtitle: Text('${field.fieldType} ${field.required ? "(Required)" : "(Optional)"}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () =\u003e _editCustomField(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () =\u003e _deleteCustomField(index),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFieldIcon(String fieldType) {
    switch (fieldType) {
      case 'text':
        return Icons.text_fields;
      case 'number':
        return Icons.numbers;
      case 'dropdown':
        return Icons.arrow_drop_down_circle;
      case 'checkbox':
        return Icons.check_box;
      case 'date':
        return Icons.calendar_today;
      default:
        return Icons.help_outline;
    }
  }

  void _addCustomField() {
    _showCustomFieldDialog(null);
  }

  void _editCustomField(int index) {
    _showCustomFieldDialog(index);
  }

  void _deleteCustomField(int index) {
    setState(() {
      _customFields.removeAt(index);
    });
  }

  void _showCustomFieldDialog(int? editIndex) {
    final isEditing = editIndex != null;
    final existingField = isEditing ? _customFields[editIndex] : null;

    final labelController = TextEditingController(text: existingField?.label ?? '');
    final placeholderController = TextEditingController(text: existingField?.placeholder ?? '');
    String fieldType = existingField?.fieldType ?? 'text';
    bool required = existingField?.required ?? false;
    List\u003cString\u003e options = List.from(existingField?.options ?? []);

    showDialog(
      context: context,
      builder: (context) =\u003e StatefulBuilder(
        builder: (context, setDialogState) =\u003e AlertDialog(
          title: Text(isEditing ? 'Edit Custom Field' : 'Add Custom Field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Field Label',
                    hintText: 'e.g., "Theme Color"',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField\u003cString\u003e(
                  value: fieldType,
                  decoration: const InputDecoration(labelText: 'Field Type'),
                  items: [
                    'text',
                    'number',
                    'dropdown',
                    'checkbox',
                    'date',
                  ].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() =\u003e fieldType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: placeholderController,
                  decoration: const InputDecoration(
                    labelText: 'Placeholder (optional)',
                    hintText: 'e.g., "Enter your preferred color"',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Required Field'),
                  value: required,
                  onChanged: (value) =\u003e setDialogState(() =\u003e required = value),
                  activeColor: AppTheme.primaryColor,
                ),
                if (fieldType == 'dropdown') ...[\n                  const SizedBox(height: 16),
                  const Text('Dropdown Options:'),
                  ...options.asMap().entries.map((entry) {
                    return ListTile(
                      title: Text(entry.value),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () {
                          setDialogState(() {
                            options.removeAt(entry.key);
                          });
                        },
                      ),
                    );
                  }).toList(),
                  TextButton.icon(
                    onPressed: () {
                      final optionController = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (ctx) =\u003e AlertDialog(
                          title: const Text('Add Option'),
                          content: TextField(
                            controller: optionController,
                            decoration: const InputDecoration(hintText: 'Option text'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =\u003e Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (optionController.text.isNotEmpty) {
                                  setDialogState(() {
                                    options.add(optionController.text);
                                  });
                                  Navigator.pop(ctx);
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Option'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =\u003e Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (labelController.text.isNotEmpty) {
                  final newField = CustomOrderField(
                    id: existingField?.id ?? const Uuid().v4(),
                    label: labelController.text,
                    fieldType: fieldType,
                    required: required,
                    placeholder: placeholderController.text.isNotEmpty
                        ? placeholderController.text
                        : null,
                    options: fieldType == 'dropdown' ? options : null,
                    order: existingField?.order ?? _customFields.length,
                  );

                  setState(() {
                    if (isEditing) {
                      _customFields[editIndex] = newField;
                    } else {
                      _customFields.add(newField);
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
