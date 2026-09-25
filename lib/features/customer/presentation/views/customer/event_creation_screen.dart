import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/models/event_type.dart';
import 'package:eventease/features/event/data/models/event_template.dart';
import 'package:eventease/shared/models/other/venue.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart' as ep;
import 'package:eventease/core/utils/app_theme.dart';

class EventCreationScreen extends StatefulWidget {
  const EventCreationScreen({super.key});

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _hostEmailController = TextEditingController();
  final _hostPhoneController = TextEditingController();
  final _themeController = TextEditingController();
  final _dressCodeController = TextEditingController();
  final _maxGuestsController = TextEditingController();
  final _invitationMessageController = TextEditingController();

  EventType _selectedType = EventType.wedding;
  EventTemplate _selectedTemplate = EventTemplate.availableTemplates[0];
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Venue? _selectedVenue;
  late Map<String, bool> _guestFeatures;

  @override
  void initState() {
    super.initState();
    _guestFeatures = {
      'giftRegistry': true,
      'photoSharing': true,
      'guestChat': true,
      'seatingAssignment': false,
      'mealPreferences': false,
      'eventSchedule': true,
      'eventMap': false,
    };
    // Pre-fill host info from auth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        _hostEmailController.text = authProvider.userEmail;
        _hostNameController.text = authProvider.userName ?? '';
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hostNameController.dispose();
    _hostEmailController.dispose();
    _hostPhoneController.dispose();
    _themeController.dispose();
    _dressCodeController.dispose();
    _maxGuestsController.dispose();
    _invitationMessageController.dispose();
    super.dispose();
  }

  String _formatFeatureName(String feature) {
    switch (feature) {
      case 'giftRegistry':
        return 'Gift Registry';
      case 'photoSharing':
        return 'Photo Sharing';
      case 'guestChat':
        return 'Guest Chat';
      case 'seatingAssignment':
        return 'Seating Assignment';
      case 'mealPreferences':
        return 'Meal Preferences';
      case 'eventSchedule':
        return 'Event Schedule';
      case 'eventMap':
        return 'Event Map';
      default:
        return feature;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and times')),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final eventProvider = Provider.of<ep.EventProvider>(context, listen: false);

      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      if (authProvider.userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session expired. Please log in again.')),
        );
        return;
      }

      final newEvent = Event(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        date: _selectedDate!,
        startTime: startDateTime,
        endTime: endDateTime,
        venue: _selectedVenue ?? Venue.sample(),
        hostId: authProvider.userId!, // Explicitly use UUID
        hostName: _hostNameController.text,
        hostEmail: _hostEmailController.text,
        hostPhone: _hostPhoneController.text,
        status: EventStatus.published,
        theme: _themeController.text,
        dressCode: _dressCodeController.text,
        maxGuests: int.tryParse(_maxGuestsController.text) ?? 100,
        isPublic: false,
        invitationMessage: _invitationMessageController.text,
        coverImage: null,
        tags: [],
        additionalInfo: {
          'guestFeatures': _guestFeatures,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _submitEvent(eventProvider, newEvent, _selectedTemplate);
    }
  }

  Future<void> _submitEvent(ep.EventProvider eventProvider, Event newEvent, EventTemplate template) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      await eventProvider.addEvent(newEvent, template: template);
      
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
        Navigator.of(context).pop(); // Go back to event list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Event'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Event Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Type
              DropdownButtonFormField<EventType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  border: OutlineInputBorder(),
                ),
                items: EventType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      // Auto-select template based on type
                      if (value.categoryGroup == 'corporate') {
                        _selectedTemplate = EventTemplate.availableTemplates.firstWhere((t) => t.type == EventTemplateType.corporate);
                      } else if (value.categoryGroup == 'educational') {
                        _selectedTemplate = EventTemplate.availableTemplates.firstWhere((t) => t.title.contains('Educational'));
                      } else if (value.categoryGroup == 'community') {
                         _selectedTemplate = EventTemplate.availableTemplates.firstWhere((t) => t.title.contains('Community'));
                      } else if (value.categoryGroup == 'social') {
                        if (value == EventType.wedding) {
                          _selectedTemplate = EventTemplate.availableTemplates.firstWhere((t) => t.type == EventTemplateType.wedding);
                        } else {
                          _selectedTemplate = EventTemplate.availableTemplates.firstWhere((t) => t.type == EventTemplateType.party);
                        }
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Event Tools Template
              DropdownButtonFormField<EventTemplate>(
                value: _selectedTemplate,
                decoration: const InputDecoration(
                  labelText: 'Event Tools Template',
                  border: OutlineInputBorder(),
                  helperText: 'Pre-fills checklists and budget categories',
                ),
                items: EventTemplate.availableTemplates.map((template) {
                  return DropdownMenuItem(
                    value: template,
                    child: Text(template.title),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTemplate = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Event Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select date',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Start Time
              InkWell(
                onTap: () => _selectTime(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _startTime != null
                        ? _startTime!.format(context)
                        : 'Select start time',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End Time
              InkWell(
                onTap: () => _selectTime(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _endTime != null
                        ? _endTime!.format(context)
                        : 'Select end time',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Host Name
              TextFormField(
                controller: _hostNameController,
                decoration: const InputDecoration(
                  labelText: 'Host Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter host name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Host Email
              TextFormField(
                controller: _hostEmailController,
                decoration: const InputDecoration(
                  labelText: 'Host Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter host email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Host Phone
              TextFormField(
                controller: _hostPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Host Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Theme
              TextFormField(
                controller: _themeController,
                decoration: const InputDecoration(
                  labelText: 'Theme',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Dress Code
              TextFormField(
                controller: _dressCodeController,
                decoration: const InputDecoration(
                  labelText: 'Dress Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Max Guests
              TextFormField(
                controller: _maxGuestsController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Guests',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Invitation Message
              TextFormField(
                controller: _invitationMessageController,
                decoration: const InputDecoration(
                  labelText: 'Invitation Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Guest Features
              const Text(
                'Guest Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              ..._guestFeatures.keys.map((feature) => CheckboxListTile(
                title: Text(_formatFeatureName(feature)),
                value: _guestFeatures[feature],
                onChanged: (value) {
                  setState(() {
                    _guestFeatures[feature] = value ?? false;
                  });
                },
              )),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text(
                    'Create Event',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
