import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';

class CreateExpoScreen extends StatefulWidget {
  const CreateExpoScreen({super.key});

  static const routeName = '/organizer/create-expo';

  @override
  State<CreateExpoScreen> createState() => _CreateExpoScreenState();
}

class _CreateExpoScreenState extends State<CreateExpoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '80');
  DateTime? _startDate;
  TimeOfDay? _startTime;
  String _ticketType = 'free_and_paid';
  String _pricingStrategy = 'tiered_zones';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _venueCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (time == null || !mounted) return;
    setState(() {
      _startDate = date;
      _startTime = time;
    });
  }

  bool _isSaving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final startAt = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endAt = startAt.add(const Duration(days: 3));
      final capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 80;

      final createdId = await OrganizerRepository.instance.createExpo(
        name: _nameCtrl.text.trim(),
        venue: _venueCtrl.text.trim(),
        startAt: startAt,
        endAt: endAt,
        boothCapacity: capacity,
        ticketStrategy: _ticketType,
        pricingStrategy: _pricingStrategy,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expo "${_nameCtrl.text.trim()}" created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, createdId != null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating expo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _startDate == null
        ? 'Select date & time'
        : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} '
            '${_startTime!.format(context)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Expo'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: OrganizerScreenBody(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Expo name',
                  hintText: 'e.g. KL Bridal Fair 2026',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _venueCtrl,
                decoration: const InputDecoration(
                  labelText: 'Venue',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                title: const Text('Date & time'),
                subtitle: Text(dateLabel),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Booth capacity',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Enter a valid capacity';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _ticketType,
                decoration: const InputDecoration(labelText: 'Ticket type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'free_only', child: Text('Free admission only')),
                  DropdownMenuItem(value: 'free_and_paid', child: Text('Free + Paid/VIP ticket')),
                  DropdownMenuItem(value: 'paid_only', child: Text('Paid tickets only')),
                ],
                onChanged: (v) => setState(() => _ticketType = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _pricingStrategy,
                decoration: const InputDecoration(
                  labelText: 'Pricing strategy',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'flat', child: Text('Flat booth pricing')),
                  DropdownMenuItem(value: 'tiered_zones', child: Text('Zone-based (A / B / VIP)')),
                  DropdownMenuItem(value: 'early_bird', child: Text('Early bird + normal tiers')),
                ],
                onChanged: (v) => setState(() => _pricingStrategy = v!),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create expo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
