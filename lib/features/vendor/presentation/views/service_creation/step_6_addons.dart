import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'service_creation_state.dart';
import 'package:eventease/shared/models/services/pricing_model.dart';
import 'package:eventease/shared/widgets/custom_text_field.dart';
import 'package:eventease/core/utils/app_theme.dart';

class Step6AddOns extends StatelessWidget {
  const Step6AddOns({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ServiceCreationState>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Optional Add-Ons',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddOnDialog(context, state),
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Offer extra services or items to increase your earnings.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          if (state.addOns.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.extension_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text('No add-ons yet. Click "Add Item" to create one.'),
                  ],
                ),
              ),
            ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.addOns.length,
            itemBuilder: (context, index) {
              final addon = state.addOns[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(addon.name),
                  subtitle: Text('${addon.formattedPrice} (${addon.pricingType.displayName})'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddOnDialog(context, state, index: index, existing: addon),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => state.removeAddOn(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddOnDialog(BuildContext context, ServiceCreationState state, {int? index, ServiceAddOn? existing}) {
    showDialog(
      context: context,
      builder: (ctx) => _AddOnDialog(
        initialAddOn: existing,
        serviceId: state.id ?? '',
        onSave: (newAddOn) {
          if (index != null) {
            state.updateAddOn(index, newAddOn);
          } else {
            state.addAddOn(newAddOn);
          }
        },
      ),
    );
  }
}

class _AddOnDialog extends StatefulWidget {
  final ServiceAddOn? initialAddOn;
  final String serviceId;
  final Function(ServiceAddOn) onSave;

  const _AddOnDialog({
    this.initialAddOn, 
    required this.serviceId,
    required this.onSave
  });

  @override
  State<_AddOnDialog> createState() => _AddOnDialogState();
}

class _AddOnDialogState extends State<_AddOnDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  AddOnPricingType _pricingType = AddOnPricingType.fixed;
  bool _isOptional = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialAddOn?.name ?? '');
    _descController = TextEditingController(text: widget.initialAddOn?.description ?? '');
    _priceController = TextEditingController(text: widget.initialAddOn?.fixedPrice?.toString() ?? '');
    _pricingType = widget.initialAddOn?.pricingType ?? AddOnPricingType.fixed;
    _isOptional = widget.initialAddOn?.isOptional ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialAddOn == null ? 'New Add-On' : 'Edit Add-On'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AddOnPricingType>(
                value: _pricingType,
                decoration: const InputDecoration(labelText: 'Pricing Type'),
                items: AddOnPricingType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _pricingType = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price', prefixText: 'RM '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Optional?'),
                value: _isOptional,
                onChanged: (val) => setState(() => _isOptional = val),
                 contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newAddOn = ServiceAddOn(
                id: widget.initialAddOn?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                serviceId: widget.serviceId,
                name: _nameController.text,
                description: _descController.text,
                fixedPrice: double.tryParse(_priceController.text),
                pricingType: _pricingType,
                isOptional: _isOptional,
              );
              widget.onSave(newAddOn);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
