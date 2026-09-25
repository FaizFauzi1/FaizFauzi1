import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/models/event_type.dart';
import 'package:eventease/shared/models/other/venue.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';

class EventEditScreen extends StatefulWidget {
  final Event event;

  const EventEditScreen({super.key, required this.event});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _hostNameController;
  late final TextEditingController _hostEmailController;
  late final TextEditingController _hostPhoneController;
  late final TextEditingController _themeController;
  late final TextEditingController _dressCodeController;
  late final TextEditingController _maxGuestsController;
  late final TextEditingController _invitationMessageController;

  late EventType _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;
  Venue? _selectedVenue;
  late Map<String, bool> _guestFeatures;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _hostNameController = TextEditingController(text: widget.event.hostName);
    _hostEmailController = TextEditingController(text: widget.event.hostEmail);
    _hostPhoneController = TextEditingController(text: widget.event.hostPhone);
    _themeController = TextEditingController(text: widget.event.theme);
    _dressCodeController = TextEditingController(text: widget.event.dressCode);
    _maxGuestsController = TextEditingController(text: widget.event.maxGuests.toString());
    _invitationMessageController = TextEditingController(text: widget.event.invitationMessage);

    _selectedType = widget.event.type;
    _selectedDate = widget.event.date;
    _startTime = TimeOfDay.fromDateTime(widget.event.startTime);
    _endTime = widget.event.endTime != null ? TimeOfDay.fromDateTime(widget.event.endTime!) : null;
    _selectedVenue = widget.event.venue;
    _guestFeatures = Map<String, bool>.from(widget.event.additionalInfo['guestFeatures'] ?? {
      'giftRegistry': true,
      'photoSharing': true,
      'guestChat': true,
      'seatingAssignment': false,
      'mealPreferences': false,
      'eventSchedule': true,
      'eventMap': false,
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
      initialDate: _selectedDate,
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
      initialTime: isStart ? _startTime : (_endTime ?? TimeOfDay.now()),
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
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = _endTime != null ? DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime!.hour,
        _endTime!.minute,
      ) : null;

      final updatedEvent = widget.event.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        date: _selectedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        venue: _selectedVenue ?? widget.event.venue,
        hostName: _hostNameController.text,
        hostEmail: _hostEmailController.text,
        hostPhone: _hostPhoneController.text,
        theme: _themeController.text,
        dressCode: _dressCodeController.text,
        maxGuests: int.tryParse(_maxGuestsController.text) ?? widget.event.maxGuests,
        invitationMessage: _invitationMessageController.text,
        additionalInfo: {
          ...widget.event.additionalInfo,
          'guestFeatures': _guestFeatures,
        },
        updatedAt: DateTime.now(),
      );

      eventProvider.updateEvent(updatedEvent);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully!')),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
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
                  setState(() {
                    _selectedType = value!;
                  });
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
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
                  child: Text(_startTime.format(context)),
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
                  child: Text(_endTime != null ? _endTime!.format(context) : 'Select end time'),
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
                    'Update Event',
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
