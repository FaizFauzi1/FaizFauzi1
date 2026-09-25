import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/budget/data/providers/budget_provider.dart';
import 'package:eventease/features/budget/data/models/budget.dart';
import 'package:eventease/features/budget/data/models/budget_category.dart';
import 'package:eventease/features/budget/data/models/budget_expense.dart';
import 'package:eventease/features/customer/data/providers/customer_subscription_provider.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart' as ep;
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/shared/models/planner_models.dart' as planner;
import 'package:eventease/features/customer/presentation/views/customer/budget_screen.dart';
import 'package:eventease/shared/widgets/upgrade_required_overlay.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/shared/widgets/app_footer.dart';
import 'package:eventease/core/services/onboarding_service.dart';
import 'package:eventease/shared/widgets/tutorial_overlay.dart';
import 'package:eventease/features/event/data/models/event_template.dart';

/// CustomerPlannerScreen - full-featured, defensive & null-safe
class CustomerPlannerScreen extends StatefulWidget {
  final String? eventId;
  final int initialTab;
  const CustomerPlannerScreen({super.key, this.eventId, this.initialTab = 0});

  @override
  State<CustomerPlannerScreen> createState() => _CustomerPlannerScreenState();
}

// ...
// ---------------- State ----------------
class _CustomerPlannerScreenState extends State<CustomerPlannerScreen> with TickerProviderStateMixin {
  
  // Added template selection methods
  void _showTemplateSelection(ep.EventProvider eventProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Choose an Event Template',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: EventTemplate.availableTemplates.length,
                  itemBuilder: (context, index) {
                    final template = EventTemplate.availableTemplates[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () async {
                          if (widget.eventId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select an event first')),
                            );
                            Navigator.pop(context);
                            return;
                          }
                          
                          final event = eventProvider.getEventById(widget.eventId!);
                          if (event != null) {
                            await eventProvider.applyTemplate(event, template, clearExisting: true);
                            await eventProvider.loadEventDetails(widget.eventId!);
                          }
                          
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Applied template: ${template.title}')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(16),
                            color: AppTheme.primaryColor.withOpacity(0.02),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(_getTemplateIcon(template.type), color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(template.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(template.description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTemplateIcon(EventTemplateType type) {
    switch (type) {
      case EventTemplateType.wedding: return Icons.favorite;
      case EventTemplateType.corporate: return Icons.business;
      case EventTemplateType.party: return Icons.celebration;
      case EventTemplateType.blank: return Icons.note_add;
      default: return Icons.event;
    }
  }
  // ----- Data moved to EventProvider -----

  // ----- Filters & searches -----
  // All | Pending | Completed
  String _checklistFilter = 'All'; 
  String? _checklistCategory; // null = All
  DateTime? _checklistDate; // null = Any
  String _checklistSearch = '';

  String? _timelineCategory; // null = All
  DateTime? _timelineDate; // null = Any
  String _timelineSearch = '';
  bool _timelineSortAsc = true;
  String _timelineAudience = 'all'; // 'all', 'host', 'guest'
  // ----- Controllers -----
  final TextEditingController _taskAddController = TextEditingController();
  final TextEditingController _taskEditController = TextEditingController();

  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventNotesController = TextEditingController();
  final TextEditingController _eventCategoryController = TextEditingController();

  DateTime? _eventDate; // declared and used null-safe

  late final TabController _tabController;

  // Tutorial Keys
  final GlobalKey _timelineFiltersKey = GlobalKey();
  final GlobalKey _checklistProgressKey = GlobalKey();
  final GlobalKey _addFabKey = GlobalKey();
  
  bool _showTutorial = false;

  // ----- Helpers -----

  // ----- Category set (defaults included) -----
  List<String> _getAllCategories(List<planner.TimelineEvent> timeline) {
    final set = <String>{'Venue', 'Vendors', 'Guests', 'Catering', 'Decoration', 'Photography'};
    for (final e in timeline) {
      if (e.category.trim().isNotEmpty) set.add(e.category);
    }
    final list = set.toList()..sort();
    return list;
  }

  // ----- Helpers -----
  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Color _categoryColor(String category) {
    switch (category) {
      case 'Venue':
        return AppTheme.primaryColor;
      case 'Vendors':
        return AppTheme.secondaryColor;
      case 'Guests':
        return AppTheme.accentColor;
      case 'Catering':
        return Colors.orange;
      case 'Decoration':
        return Colors.purple;
      case 'Photography':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);

    // Initial load if eventId is provided
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final eventProvider = Provider.of<ep.EventProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (widget.eventId != null) {
        eventProvider.loadEventDetails(widget.eventId!);
      } else {
        // Find most recent event if none provided
        if (eventProvider.events.isEmpty && authProvider.isAuthenticated && authProvider.userId != null) {
          await eventProvider.loadEvents(authProvider.userId!);
        }
        
        if (eventProvider.events.isNotEmpty) {
          // Instead of assuming it's loaded, we might need a way to pass this down
          // Or ensure that the UI uses the first event if eventId is null.
          // The current build method seems to handle it by defaulting to events.firstOrNull.
          eventProvider.loadEventDetails(eventProvider.events.first.id);
        }
      }
    });

    _eventCategoryController.text = 'Venue';
    
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final completed = await OnboardingService.isTutorialCompleted('planner_tools');
    if (!completed && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskAddController.dispose();
    _taskEditController.dispose();
    _eventTitleController.dispose();
    _eventNotesController.dispose();
    _eventCategoryController.dispose();
    super.dispose();
  }

  // ---------------- Checklist actions ----------------


  void _showAddTaskDialog() {
    _taskAddController.clear();
    _eventCategoryController.text = 'General';
    _eventDate = null; // Used for due date

    final categories = ['General', 'Venue', 'Vendors', 'Guests', 'Catering', 'Decoration', 'Photography'];
    final currentCategory = _eventCategoryController.text;
    if (!categories.contains(currentCategory) && currentCategory.isNotEmpty) {
      categories.add(currentCategory);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskAddController,
                decoration: const InputDecoration(hintText: 'Task title'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categories.contains(_eventCategoryController.text) ? _eventCategoryController.text : categories.first,
                items: categories
                    .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => _eventCategoryController.text = v ?? 'General'),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(_eventDate == null ? 'No due date' : 'Due: ${_formatDate(_eventDate!)}')),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _eventDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialogState(() => _eventDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Set Date'),
                  ),
                  if (_eventDate != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setDialogState(() => _eventDate = null),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => _commitAddTask(ctx), child: const Text('Add')),
          ],
        );
      }),
    );
  }

  void _commitAddTask(BuildContext ctx) {
    final text = (_taskAddController.text ?? '').trim();
    if (text.isEmpty) return;
    
    final eventId = widget.eventId ?? Provider.of<ep.EventProvider>(context, listen: false).events.firstOrNull?.id;
    if (eventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an event first')));
      return;
    }

    final eventProvider = Provider.of<ep.EventProvider>(context, listen: false);
    final event = eventProvider.getEventById(eventId);
    final hostId = event?.hostId ?? '';

    final newItem = planner.ChecklistItem(
      id: const Uuid().v4(),
      eventId: eventId,
      userId: hostId,
      title: text,
      category: _eventCategoryController.text,
      dueDate: _eventDate,
      createdAt: DateTime.now(),
    );
    
    eventProvider.addChecklistItem(newItem);
    Navigator.pop(ctx);
  }

  void _showEditTaskDialog(planner.ChecklistItem item) {
    _taskEditController.text = item.title;
    _eventCategoryController.text = item.category;
    _eventDate = item.dueDate;

    final categories = ['General', 'Venue', 'Vendors', 'Guests', 'Catering', 'Decoration', 'Photography'];
    if (!categories.contains(item.category) && item.category.isNotEmpty) {
      categories.add(item.category);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskEditController,
                decoration: const InputDecoration(hintText: 'Update task title'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categories.contains(_eventCategoryController.text) ? _eventCategoryController.text : categories.first,
                items: categories
                    .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => _eventCategoryController.text = v ?? 'General'),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(_eventDate == null ? 'No due date' : 'Due: ${_formatDate(_eventDate!)}')),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _eventDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialogState(() => _eventDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Set Date'),
                  ),
                  if (_eventDate != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setDialogState(() => _eventDate = null),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => _commitEditTask(ctx, item), child: const Text('Save')),
          ],
        );
      }),
    );
  }

  void _commitEditTask(BuildContext ctx, planner.ChecklistItem item) {
    final text = (_taskEditController.text ?? '').trim();
    if (text.isNotEmpty) {
      final updated = item.copyWith(
        title: text,
        category: _eventCategoryController.text,
        dueDate: _eventDate,
      );
      Provider.of<ep.EventProvider>(context, listen: false).updateChecklistItem(updated);
    }
    Navigator.pop(ctx);
  }

  void _toggleTask(planner.ChecklistItem item, bool? val) {
    final updated = item.copyWith(isDone: val ?? false);
    Provider.of<ep.EventProvider>(context, listen: false).updateChecklistItem(updated);
  }

  Future<bool?> _confirmDeleteTask(planner.ChecklistItem item) async {
    final should = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    return should;
  }

  // ---------------- Timeline actions ----------------

  void _openAddTimelineDialog(List<String> allCategories) {
    _eventTitleController.clear();
    _eventNotesController.clear();
    _eventCategoryController.text = allCategories.isNotEmpty ? allCategories.first : 'Venue';
    _eventDate = DateTime.now().add(const Duration(hours: 1));
    String selectedAudience = 'all';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        final currentCat = _eventCategoryController.text;
        if (!allCategories.contains(currentCat) && currentCat.isNotEmpty) {
          allCategories.add(currentCat);
        }
        
        final dt = _eventDate ?? DateTime.now();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Add Timeline Event', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _eventTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    hintText: 'e.g. Guest Arrival & Registration',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: allCategories.contains(_eventCategoryController.text) ? _eventCategoryController.text : (allCategories.isNotEmpty ? allCategories.first : 'Venue'),
                  items: allCategories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => _eventCategoryController.text = (v ?? '').toString()),
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _eventNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'e.g. Doors open at main hall entrance',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Audience / Visibility:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('Everyone'),
                      avatar: const Icon(Icons.people_outline, size: 16),
                      selected: selectedAudience == 'all',
                      onSelected: (s) => setDialogState(() => selectedAudience = 'all'),
                    ),
                    ChoiceChip(
                      label: const Text('Host Only'),
                      avatar: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                      selected: selectedAudience == 'host',
                      onSelected: (s) => setDialogState(() => selectedAudience = 'host'),
                    ),
                    ChoiceChip(
                      label: const Text('Guest Itinerary'),
                      avatar: const Icon(Icons.confirmation_number_outlined, size: 16),
                      selected: selectedAudience == 'guest',
                      onSelected: (s) => setDialogState(() => selectedAudience = 'guest'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${_formatDate(dt)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Time: ${_formatTime(dt)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Pick Date',
                        icon: const Icon(Icons.calendar_today, size: 20),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dt,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _eventDate = DateTime(picked.year, picked.month, picked.day, dt.hour, dt.minute);
                            });
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'Pick Time',
                        icon: const Icon(Icons.access_time, size: 20, color: AppTheme.primaryColor),
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dt),
                          );
                          if (pickedTime != null) {
                            setDialogState(() {
                              _eventDate = DateTime(dt.year, dt.month, dt.day, pickedTime.hour, pickedTime.minute);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final title = (_eventTitleController.text ?? '').trim();
                final category = (_eventCategoryController.text ?? '').trim().isNotEmpty
                    ? _eventCategoryController.text.trim()
                    : (allCategories.isNotEmpty ? allCategories.first : 'Venue');
                final date = _eventDate ?? DateTime.now();
                final notes = (_eventNotesController.text ?? '').trim();
                if (title.isEmpty) return;
                
                final eventId = widget.eventId ?? Provider.of<ep.EventProvider>(context, listen: false).events.firstOrNull?.id;
                if (eventId == null) return;

                final eventProvider = Provider.of<ep.EventProvider>(context, listen: false);
                final event = eventProvider.getEventById(eventId);
                final hostId = event?.hostId ?? '';

                final newItem = planner.TimelineEvent(
                  id: const Uuid().v4(),
                  eventId: eventId,
                  userId: hostId,
                  title: title,
                  category: category,
                  date: date,
                  notes: notes,
                  audience: selectedAudience,
                  createdAt: DateTime.now(),
                );

                eventProvider.addTimelineEvent(newItem);
                Navigator.pop(ctx);
              },
              child: const Text('Add Event'),
            ),
          ],
        );
      }),
    );
  }

  void _openEditTimelineDialog(planner.TimelineEvent event, List<String> allCategories) {
    _eventTitleController.text = event.title;
    _eventNotesController.text = event.notes;
    _eventCategoryController.text = event.category;
    _eventDate = event.date;
    String selectedAudience = event.audience;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        if (!allCategories.contains(_eventCategoryController.text) && _eventCategoryController.text.isNotEmpty) {
          allCategories.add(_eventCategoryController.text);
        }

        final dt = _eventDate ?? DateTime.now();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_calendar, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Edit Timeline Event', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _eventTitleController,
                  decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: allCategories.contains(_eventCategoryController.text) ? _eventCategoryController.text : (allCategories.isNotEmpty ? allCategories.first : 'Venue'),
                  items: allCategories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => _eventCategoryController.text = (v ?? '').toString()),
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _eventNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Audience / Visibility:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('Everyone'),
                      avatar: const Icon(Icons.people_outline, size: 16),
                      selected: selectedAudience == 'all',
                      onSelected: (s) => setDialogState(() => selectedAudience = 'all'),
                    ),
                    ChoiceChip(
                      label: const Text('Host Only'),
                      avatar: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                      selected: selectedAudience == 'host',
                      onSelected: (s) => setDialogState(() => selectedAudience = 'host'),
                    ),
                    ChoiceChip(
                      label: const Text('Guest Itinerary'),
                      avatar: const Icon(Icons.confirmation_number_outlined, size: 16),
                      selected: selectedAudience == 'guest',
                      onSelected: (s) => setDialogState(() => selectedAudience = 'guest'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${_formatDate(dt)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Time: ${_formatTime(dt)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Pick Date',
                        icon: const Icon(Icons.calendar_today, size: 20),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dt,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _eventDate = DateTime(picked.year, picked.month, picked.day, dt.hour, dt.minute);
                            });
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'Pick Time',
                        icon: const Icon(Icons.access_time, size: 20, color: AppTheme.primaryColor),
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dt),
                          );
                          if (pickedTime != null) {
                            setDialogState(() {
                              _eventDate = DateTime(dt.year, dt.month, dt.day, pickedTime.hour, pickedTime.minute);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final title = (_eventTitleController.text ?? '').trim();
                final category = (_eventCategoryController.text ?? '').trim().isNotEmpty
                    ? _eventCategoryController.text.trim()
                    : (allCategories.isNotEmpty ? allCategories.first : 'Venue');
                final date = _eventDate ?? DateTime.now();
                final notes = (_eventNotesController.text ?? '').trim();
                if (title.isEmpty) return;
                
                final updated = event.copyWith(
                  title: title,
                  category: category,
                  date: date,
                  notes: notes,
                  audience: selectedAudience,
                );
                Provider.of<ep.EventProvider>(context, listen: false).updateTimelineEvent(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }

  Future<bool?> _confirmDeleteTimeline(planner.TimelineEvent e) async {
    final should = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('Delete "${e.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    return should;
  }

  // ---------------- UI tiles ----------------

  // ---------------- UI tiles ----------------

  String _formatTime(DateTime dt) {
    try {
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
  }

  Widget _timelineTile(planner.TimelineEvent e, List<String> allCategories, {bool isFirst = false, bool isLast = false}) {
    final categoryColor = _categoryColor(e.category);
    final timeStr = _formatTime(e.date);

    Color audienceColor;
    String audienceLabel;
    IconData audienceIcon;

    switch (e.audience) {
      case 'host':
        audienceColor = const Color(0xFF8B5CF6);
        audienceLabel = 'Host Only';
        audienceIcon = Icons.admin_panel_settings_outlined;
        break;
      case 'guest':
        audienceColor = const Color(0xFF10B981);
        audienceLabel = 'Guest Itinerary';
        audienceIcon = Icons.confirmation_number_outlined;
        break;
      case 'all':
      default:
        audienceColor = const Color(0xFF3B82F6);
        audienceLabel = 'Everyone';
        audienceIcon = Icons.people_outline;
        break;
    }

    return Dismissible(
      key: ValueKey('timeline_${e.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await _confirmDeleteTimeline(e),
      onDismissed: (_) {
        Provider.of<ep.EventProvider>(context, listen: false).deleteTimelineEvent(e.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Badge & Date Column
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: categoryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(e.date),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Timeline Node Circle & Connector Line
            Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: categoryColor,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 75,
                    color: Colors.grey.shade200,
                  ),
              ],
            ),

            const SizedBox(width: 10),

            // Main Content Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: categoryColor.withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Audience Badges
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            e.category.isNotEmpty ? e.category : 'General',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: categoryColor),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: audienceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(audienceIcon, size: 11, color: audienceColor),
                              const SizedBox(width: 3),
                              Text(
                                audienceLabel,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: audienceColor),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _openEditTimelineDialog(e, allCategories),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.edit, size: 16, color: Colors.grey),
                          ),
                        ),
                        InkWell(
                          onTap: () => _showEventMenu(e, allCategories),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.more_vert, size: 16, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      e.title.isNotEmpty ? e.title : 'Untitled Event',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),

                    if (e.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        e.notes,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventMenu(planner.TimelineEvent e, List<String> allCategories) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openEditTimelineDialog(e, allCategories);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteTimeline(e).then((should) {
                    if (should == true) {
                      Provider.of<ep.EventProvider>(context, listen: false).deleteTimelineEvent(e.id);
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _checkTile(planner.ChecklistItem item) {
    final categoryColor = _categoryColor(item.category);
    final isOverdue = item.dueDate != null && !item.isDone && item.dueDate!.isBefore(DateTime.now());

    return Dismissible(
      key: ValueKey('check_${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final should = await _confirmDeleteTask(item);
        return should;
      },
      onDismissed: (_) {
        Provider.of<ep.EventProvider>(context, listen: false).deleteChecklistItem(item.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: item.isDone ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isOverdue ? Border.all(color: Colors.red.shade300, width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  value: item.isDone,
                  onChanged: (v) => _toggleTask(item, v),
                  activeColor: AppTheme.primaryColor,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    item.title.isNotEmpty ? item.title : 'Untitled task',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: item.isDone ? Colors.green : AppTheme.textPrimaryColor,
                      decoration: item.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(fontSize: 10, color: categoryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (item.dueDate != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.calendar_today, size: 10, color: isOverdue ? Colors.red : Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(item.dueDate!),
                          style: TextStyle(
                            fontSize: 10,
                            color: isOverdue ? Colors.red : Colors.grey[600],
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  secondary: IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showEditTaskDialog(item)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Text(message, style: const TextStyle(color: AppTheme.textSecondaryColor)),
    );
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    return Consumer<ep.EventProvider>(
      builder: (context, eventProvider, _) {
        final eventId = widget.eventId ?? eventProvider.events.firstOrNull?.id;
        final currentChecklist = eventId != null ? eventProvider.getChecklistForEvent(eventId) : <planner.ChecklistItem>[];
        final currentTimeline = eventId != null ? eventProvider.getTimelineForEvent(eventId) : <planner.TimelineEvent>[];
        final allCategories = _getAllCategories(currentTimeline);

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Consumer<ep.EventProvider>(
              builder: (context, provider, _) {
                final currentEvent = widget.eventId != null 
                    ? provider.getEventById(widget.eventId!)
                    : provider.events.firstOrNull;
                
                return DropdownButton<String>(
                  value: currentEvent?.id,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textPrimaryColor),
                  onChanged: (newId) {
                    if (newId != null) {
                      // Navigate to the same screen with new eventId
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerPlannerScreen(eventId: newId),
                        ),
                      );
                    }
                  },
                  items: provider.events.map((event) {
                    return DropdownMenuItem<String>(
                      value: event.id,
                      child: Text(event.title, style: const TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  hint: const Text('Select Event', style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
                );
              },
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [Tab(text: 'Timeline'), Tab(text: 'Checklist'), Tab(text: 'Budget')],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.change_circle_outlined),
                onPressed: () {
                  final eventProvider = Provider.of<ep.EventProvider>(context, listen: false);
                  _showTemplateSelection(eventProvider);
                },
                tooltip: 'Change Template',
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _openGlobalSearch(currentTimeline, currentChecklist),
              ),
            ],
          ),
          floatingActionButton: _tabController.index < 2
              ? FloatingActionButton(
                  key: _addFabKey,
                  backgroundColor: AppTheme.primaryColor,
                  onPressed: () {
                    if (_tabController.index == 0) {
                      _openAddTimelineDialog(allCategories);
                    } else {
                      _showAddTaskDialog();
                    }
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Add (timeline/task)',
                )
              : null,
          body: Stack(
            children: [
              Consumer<CustomerSubscriptionProvider>(
                builder: (context, subProvider, _) {
                  final isLocked = !subProvider.hasWeddingPass;
                  return UpgradeRequiredOverlay(
                    isLocked: isLocked,
                    title: 'Unlock Planning Tools',
                    description: 'Get the Wedding Planner Pass to access Budget Tracker, Checklist, Timeline, and more.',
                    onUpgradePressed: () => Navigator.pushNamed(context, '/customer-subscription'),
                    child: IgnorePointer(
                      ignoring: isLocked,
                      child: ResponsiveWrapper(
                        padding: EdgeInsets.zero,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTimelineTab(currentTimeline, allCategories),
                            _buildChecklistTab(currentChecklist),
                            _buildBudgetTab(eventId),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_showTutorial)
                TutorialOverlay(
                  steps: [
                    TutorialStep(
                      title: 'Welcome to Event Planner',
                      message: 'This is your command center for organizing every detail of your event.',
                      alignment: Alignment.center,
                    ),
                    TutorialStep(
                      title: 'Timeline & Checklist',
                      message: 'Switch between your itinerary and your to-do list using these tabs.',
                      alignment: Alignment.topCenter,
                    ),
                    TutorialStep(
                      title: 'Add Items',
                      message: 'Tap this button to add a new timeline event or a checklist task.',
                      targetKey: _addFabKey,
                      alignment: Alignment.bottomCenter,
                    ),
                    TutorialStep(
                      title: 'Track Progress',
                      message: 'The checklist progress bar helps you visualize how much is left to do.',
                      targetKey: _checklistProgressKey,
                      alignment: Alignment.bottomCenter,
                    ),
                  ],
                  onCompleted: () {
                    OnboardingService.markTutorialAsCompleted('planner_tools');
                    setState(() => _showTutorial = false);
                  },
                  onSkip: () {
                    OnboardingService.markTutorialAsCompleted('planner_tools');
                    setState(() => _showTutorial = false);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showTimelineTemplatePresets(ep.EventProvider eventProvider) {
    final eventId = widget.eventId ?? eventProvider.events.firstOrNull?.id;
    if (eventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event first')),
      );
      return;
    }
    final event = eventProvider.getEventById(eventId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Load Event Type Timeline Template',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select an event type template to pre-fill run-of-show schedule milestones.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...EventTemplate.availableTemplates.where((t) => t.defaultTimelineEvents.isNotEmpty).map((tpl) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getTemplateIcon(tpl.type), color: AppTheme.primaryColor),
                ),
                title: Text(tpl.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${tpl.defaultTimelineEvents.length} preset schedule events'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (event != null) {
                    await eventProvider.applyTemplate(event, tpl, clearExisting: false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added ${tpl.defaultTimelineEvents.length} timeline items from ${tpl.title}')),
                    );
                  }
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab(List<planner.TimelineEvent> timeline, List<String> allCategories) {
    // Audience filter
    final audienceFiltered = _timelineAudience == 'all'
        ? timeline
        : timeline.where((e) => e.audience == _timelineAudience).toList();

    final visibleTimeline = audienceFiltered.where((e) {
      final categoryOk = _timelineCategory == null || e.category == _timelineCategory;
      final dateOk = _timelineDate == null || _sameDay(e.date, _timelineDate!);
      final searchOk = _timelineSearch.trim().isEmpty ||
          e.title.toLowerCase().contains(_timelineSearch.toLowerCase()) ||
          e.notes.toLowerCase().contains(_timelineSearch.toLowerCase());
      return categoryOk && dateOk && searchOk;
    }).toList();

    // Sort by date/time
    visibleTimeline.sort((a, b) =>
        _timelineSortAsc ? a.date.compareTo(b.date) : b.date.compareTo(a.date));

    // Count summary
    final hostCount = timeline.where((e) => e.audience == 'host').length;
    final guestCount = timeline.where((e) => e.audience == 'guest').length;
    final allCount = timeline.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Template Presets Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Timeline Templates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Load pre-built schedules for Wedding, Corporate, Party, etc.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Consumer<ep.EventProvider>(
                  builder: (context, provider, _) => TextButton(
                    onPressed: () => _showTimelineTemplatePresets(provider),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                    child: const Text('Load Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Audience Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _audienceChip(
                  label: 'All Events',
                  count: allCount,
                  icon: Icons.view_timeline_outlined,
                  color: const Color(0xFF6366F1),
                  selected: _timelineAudience == 'all',
                  onTap: () => setState(() => _timelineAudience = 'all'),
                ),
                const SizedBox(width: 8),
                _audienceChip(
                  label: 'Host Timeline',
                  count: hostCount,
                  icon: Icons.admin_panel_settings_outlined,
                  color: const Color(0xFF8B5CF6),
                  selected: _timelineAudience == 'host',
                  onTap: () => setState(() => _timelineAudience = 'host'),
                ),
                const SizedBox(width: 8),
                _audienceChip(
                  label: 'Guest Itinerary',
                  count: guestCount,
                  icon: Icons.confirmation_number_outlined,
                  color: const Color(0xFF10B981),
                  selected: _timelineAudience == 'guest',
                  onTap: () => setState(() => _timelineAudience = 'guest'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filters row
          Row(children: [
            Expanded(
              child: DropdownButton<String?>(
                value: _timelineCategory,
                hint: const Text('All categories'),
                isExpanded: true,
                items: [null, ...allCategories].map((c) {
                  final label = c == null ? 'All categories' : c;
                  return DropdownMenuItem<String?>(value: c, child: Text(label));
                }).toList(),
                onChanged: (v) => setState(() => _timelineCategory = v),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _timelineDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _timelineDate = picked);
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(
                _timelineDate == null ? 'Any date' : _formatDate(_timelineDate!),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            IconButton(
              icon: Icon(_timelineSortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 20),
              onPressed: () => setState(() => _timelineSortAsc = !_timelineSortAsc),
              tooltip: _timelineSortAsc ? 'Earliest first' : 'Latest first',
            ),
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () => setState(() {
                _timelineCategory = null;
                _timelineDate = null;
                _timelineSearch = '';
                _timelineAudience = 'all';
              }),
              tooltip: 'Clear filters',
            ),
          ]),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search timeline title or notes',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            onChanged: (v) => setState(() => _timelineSearch = v),
          ),
          const SizedBox(height: 16),
          if (visibleTimeline.isEmpty)
            _emptyCard('No events match your filters.')
          else
            Column(
              children: List.generate(visibleTimeline.length, (i) {
                return _timelineTile(
                  visibleTimeline[i],
                  allCategories,
                  isFirst: i == 0,
                  isLast: i == visibleTimeline.length - 1,
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _audienceChip({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? color : color.withOpacity(0.2)),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.25) : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistTab(List<planner.ChecklistItem> checklist) {
    final categories = <String>{'General', 'Venue', 'Vendors', 'Guests', 'Catering', 'Decoration', 'Photography'};
    for (final item in checklist) {
      if (item.category.isNotEmpty) categories.add(item.category);
    }
    final sortedCategories = categories.toList()..sort();

    final visibleChecklist = checklist.where((item) {
      final matchFilter = _checklistFilter == 'All' || (_checklistFilter == 'Pending' ? !item.isDone : item.isDone);
      final matchCategory = _checklistCategory == null || item.category == _checklistCategory;
      final matchDate = _checklistDate == null || (item.dueDate != null && _sameDay(item.dueDate!, _checklistDate!));
      final matchSearch = _checklistSearch.trim().isEmpty || item.title.toLowerCase().contains(_checklistSearch.toLowerCase());
      return matchFilter && matchCategory && matchDate && matchSearch;
    }).toList()
      ..sort((a, b) {
        if (a.dueDate != null && b.dueDate != null) return a.dueDate!.compareTo(b.dueDate!);
        if (a.dueDate != null) return -1;
        if (b.dueDate != null) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });

    final completedCount = checklist.where((c) => c.isDone).length;
    final progress = checklist.isEmpty ? 0.0 : completedCount / checklist.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // --- Filters ---
        Row(children: [
          Expanded(
            child: DropdownButton<String>(
              value: _checklistFilter,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Status')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              ],
              onChanged: (v) => setState(() => _checklistFilter = v ?? 'All'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String?>(
              value: _checklistCategory,
              hint: const Text('All Categories'),
              isExpanded: true,
              items: [null, ...sortedCategories].map((c) {
                return DropdownMenuItem<String?>(value: c, child: Text(c ?? 'All Categories'));
              }).toList(),
              onChanged: (v) => setState(() => _checklistCategory = v),
            ),
          ),
        ]),
        Row(children: [
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _checklistDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _checklistDate = picked);
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_checklistDate == null ? 'Any Date' : _formatDate(_checklistDate!)),
          ),
          const Spacer(),
          if (_checklistDate != null || _checklistCategory != null || _checklistFilter != 'All' || _checklistSearch.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() {
                _checklistCategory = null;
                _checklistDate = null;
                _checklistFilter = 'All';
                _checklistSearch = '';
              }),
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Reset'),
            ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          key: _checklistProgressKey,
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade300,
            color: AppTheme.primaryColor,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search tasks',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (v) => setState(() => _checklistSearch = v),
        ),
        const SizedBox(height: 16),
        if (visibleChecklist.isEmpty)
          _emptyCard('No tasks match your filters.')
        else
          Column(children: visibleChecklist.map((c) => _checkTile(c)).toList()),
      ]),
    );
  }

  Widget _buildBudgetTab(String? eventId) {
    return CustomerBudgetScreen(
      eventId: eventId,
      showAppBar: false,
    );
  }

  // ---------------- Search helpers ----------------

  void _openGlobalSearch(List<planner.TimelineEvent> timeline, List<planner.ChecklistItem> checklist) {
    showDialog(
      context: context,
      builder: (ctx) {
        String q = '';
        return AlertDialog(
          title: const Text('Global Search'),
          content: TextField(onChanged: (v) => q = v ?? '', decoration: const InputDecoration(hintText: 'Search timeline and tasks')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (q.trim().isEmpty) {
                  Navigator.pop(ctx);
                  return;
                }
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  builder: (sheetCtx) {
                    final timelineHits = timeline.where((e) {
                      final title = e.title.toLowerCase();
                      final notes = e.notes.toLowerCase();
                      final ql = q.toLowerCase();
                      return title.contains(ql) || notes.contains(ql);
                    }).toList();
                    final checklistHits = checklist.where((t) => t.title.toLowerCase().contains(q.toLowerCase())).toList();
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Results for "$q"', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (timelineHits.isEmpty && checklistHits.isEmpty) const Text('No results found.'),
                          if (timelineHits.isNotEmpty) ...[
                            const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ...timelineHits.map((e) => ListTile(title: Text(e.title.isNotEmpty ? e.title : 'Untitled'), subtitle: Text(_formatDate(e.date)), onTap: () { Navigator.pop(sheetCtx); _openEditTimelineDialog(e, _getAllCategories(timeline)); })).toList(),
                            const SizedBox(height: 8),
                          ],
                          if (checklistHits.isNotEmpty) ...[
                            const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ...checklistHits.map((t) => ListTile(title: Text(t.title.isNotEmpty ? t.title : 'Untitled'), trailing: Checkbox(value: t.isDone, onChanged: (_) => _toggleTask(t, !t.isDone)), onTap: () { Navigator.pop(sheetCtx); _showEditTaskDialog(t); })).toList(),
                          ],
                        ]),
                      ),
                    );
                  },
                );
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _openChecklistSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String q = '';
        return AlertDialog(
          title: const Text('Search tasks'),
          content: TextField(onChanged: (v) => q = v ?? '', decoration: const InputDecoration(hintText: 'Task name')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () { Navigator.pop(ctx); setState(() => _checklistSearch = q); }, child: const Text('Search')),
          ],
        );
      },
    );
  }
}

