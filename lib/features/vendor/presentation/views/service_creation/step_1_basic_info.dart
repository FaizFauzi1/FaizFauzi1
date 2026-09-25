import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'service_creation_state.dart';
import 'package:eventease/shared/widgets/custom_text_field.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/utils/constants/image_constants.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/models/services/service_enums.dart';

class Step1BasicInfo extends StatefulWidget {
  const Step1BasicInfo({super.key});

  @override
  State<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends State<Step1BasicInfo> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<ServiceCreationState>(context, listen: false);
    _nameController = TextEditingController(text: state.name);
    _descController = TextEditingController(text: state.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ServiceCreationState>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start with the essentials.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Service Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => state.updateBasicInfo(name: val),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: (val) => state.updateBasicInfo(description: val),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Service Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all that apply (e.g., both Product and Rental).',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ServiceType.values.map((type) {
              final isSelected = state.selectedServiceTypes.contains(type);
              return FilterChip(
                label: Text(type.name.toUpperCase()),
                selected: isSelected,
                onSelected: (val) {
                  state.toggleServiceType(type);
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<EventCategory>(
            value: state.category,
            decoration: const InputDecoration(
              labelText: 'Business Category',
              border: OutlineInputBorder(),
            ),
            items: EventCategory.values.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(cat.toString().split('.').last.toUpperCase()),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) state.updateBasicInfo(category: val);
            },
          ),
          const SizedBox(height: 32),
          _buildImageSection(state),
        ],
      ),
    );
  }

  Widget _buildImageSection(ServiceCreationState state) {
    final bool hasImages = state.images.isNotEmpty;
    final String displayUrl = hasImages 
        ? state.images.first 
        : ImageConstants.getDefaultImageUrl(state.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Cover Image',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          hasImages 
              ? 'This image will be shown as the main cover for your service.' 
              : 'No images uploaded yet. The default placeholder below will be used if you don\'t provide one.',
          style: TextStyle(
            color: hasImages ? Colors.grey[600] : AppTheme.primaryColor,
            fontSize: 14,
            fontWeight: hasImages ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
            image: DecorationImage(
              image: NetworkImage(displayUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: !hasImages 
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_not_supported, color: Colors.white, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'DEFAULT PLACEHOLDER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement image picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image Upload coming soon! For now, we use high-quality placeholders.')),
              );
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(hasImages ? 'Change Main Image' : 'Upload Your Own Images'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: hasImages ? Colors.grey[200] : AppTheme.primaryColor,
              foregroundColor: hasImages ? Colors.black87 : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
