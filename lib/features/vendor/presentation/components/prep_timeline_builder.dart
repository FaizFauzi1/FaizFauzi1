import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/models/services/wedding_preparation_timeline.dart';

class PrepTimelineBuilder extends StatefulWidget {
  final List<WeddingPrepMilestone>? initialMilestones;
  final ValueChanged<List<WeddingPrepMilestone>> onChanged;

  const PrepTimelineBuilder({
    super.key,
    this.initialMilestones,
    required this.onChanged,
  });

  @override
  State<PrepTimelineBuilder> createState() => _PrepTimelineBuilderState();
}

class _PrepTimelineBuilderState extends State<PrepTimelineBuilder> {
  late List<WeddingPrepMilestone> _milestones;
  String _selectedEventTypeKey = 'wedding';

  @override
  void initState() {
    super.initState();
    _initMilestones();
  }

  void _initMilestones() {
    if (widget.initialMilestones != null && widget.initialMilestones!.isNotEmpty) {
      // Create a deep copy to allow local editing
      _milestones = widget.initialMilestones!.map((m) => m.copyWith()).toList();
    } else {
      _milestones = WeddingPrepTimeline.getSuggestedForEventType(_selectedEventTypeKey).map((m) => m.copyWith()).toList();
    }
  }

  void _notifyChanged() {
    widget.onChanged(_milestones);
  }

  void _toggleMilestone(int index, bool isEnabled) {
    setState(() {
      _milestones[index] = _milestones[index].copyWith(isEnabled: isEnabled);
    });
    _notifyChanged();
  }

  void _updateMilestone(int index, WeddingPrepMilestone updated) {
    setState(() {
      _milestones[index] = updated;
      _milestones.sort((a, b) => b.weeksBeforeEvent.compareTo(a.weeksBeforeEvent));
    });
    _notifyChanged();
  }

  void _addMilestone(WeddingPrepMilestone milestone) {
    setState(() {
      _milestones.add(milestone);
      _milestones.sort((a, b) => b.weeksBeforeEvent.compareTo(a.weeksBeforeEvent));
    });
    _notifyChanged();
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestones.removeAt(index);
    });
    _notifyChanged();
  }

  void _applyEventTypeTemplate(String typeKey) {
    setState(() {
      _selectedEventTypeKey = typeKey;
      _milestones = WeddingPrepTimeline.getSuggestedForEventType(typeKey).map((m) => m.copyWith()).toList();
    });
    _notifyChanged();
  }

  void _resetTimeline() {
    _applyEventTypeTemplate(_selectedEventTypeKey);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFEC4899),
                Color(0xFF8B5CF6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preparation Timeline & Milestones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Show customers expected prep steps for ${WeddingPrepTimeline.eventTypeNames[_selectedEventTypeKey] ?? "this event"}.',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Event Type Template Selector Bar
        const Text(
          'Choose Event Type Template:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: WeddingPrepTimeline.eventTypeNames.entries.map((entry) {
              final isSelected = _selectedEventTypeKey == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected && !isSelected) {
                      _showTemplateConfirmDialog(entry.key, entry.value);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Legend
        Row(
          children: [
            _legendChip(Icons.store, 'Vendor Handles', const Color(0xFF6366F1)),
            const SizedBox(width: 8),
            _legendChip(Icons.people, 'Host / Client Does', const Color(0xFF10B981)),
          ],
        ),

        const SizedBox(height: 16),

        // Timeline items
        ..._milestones.asMap().entries.map((entry) {
          final index = entry.key;
          final milestone = entry.value;
          return _buildMilestoneCard(context, milestone, index);
        }),

        const SizedBox(height: 16),

        // Add custom milestone button
        OutlinedButton.icon(
          onPressed: () => _showAddMilestoneDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Custom Milestone'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: const BorderSide(color: AppTheme.primaryColor),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 8),

        // Reset to suggested
        TextButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Reset Timeline'),
                content: Text('Reset to the app-suggested ${WeddingPrepTimeline.eventTypeNames[_selectedEventTypeKey]} timeline? Any custom changes will be lost.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () {
                      _resetTimeline();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: Text('Reset to ${WeddingPrepTimeline.eventTypeNames[_selectedEventTypeKey]} template'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondaryColor),
        ),
      ],
    );
  }

  void _showTemplateConfirmDialog(String key, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apply $name Template?'),
        content: Text('This will replace current timeline milestones with suggested pre-event milestones for $name.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _applyEventTypeTemplate(key);
              Navigator.pop(ctx);
            },
            child: const Text('Apply Template'),
          ),
        ],
      ),
    );
  }

  Widget _legendChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMilestoneCard(
    BuildContext context,
    WeddingPrepMilestone milestone,
    int index,
  ) {
    final isVendor = milestone.isVendorResponsibility;
    final accentColor = isVendor ? const Color(0xFF6366F1) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: milestone.isEnabled ? accentColor.withOpacity(0.3) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time badge
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: milestone.isEnabled
                    ? accentColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(
                    milestone.iconData,
                    size: 20,
                    color: milestone.isEnabled ? accentColor : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    milestone.timeLabelShort,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: milestone.isEnabled ? accentColor : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: milestone.isEnabled
                                ? AppTheme.textPrimaryColor
                                : AppTheme.textSecondaryColor,
                            decoration: milestone.isEnabled ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      // Responsibility badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isVendor ? 'You' : 'Couple',
                          style: TextStyle(
                            fontSize: 10,
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    milestone.timeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: milestone.isEnabled ? accentColor : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    milestone.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: milestone.isEnabled
                          ? AppTheme.textSecondaryColor
                          : Colors.grey.shade400,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Toggle + Edit controls
            Column(
              children: [
                Switch(
                  value: milestone.isEnabled,
                  onChanged: (v) => _toggleMilestone(index, v),
                  activeColor: accentColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (milestone.isEnabled)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppTheme.textSecondaryColor,
                    onPressed: () => _showEditMilestoneDialog(context, milestone, index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (milestone.id.startsWith('custom_'))
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.red.shade300,
                    onPressed: () => _removeMilestone(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMilestoneDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int weeks = 4;
    bool isVendorResponsibility = true;
    String selectedIcon = 'check_circle';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Custom Milestone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Milestone Title *',
                    hintText: 'e.g. Hantaran Discussion',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What happens at this step?',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Weeks Before Event', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Slider(
                  value: weeks.toDouble(),
                  min: 0,
                  max: 52,
                  divisions: 52,
                  label: weeks == 0 ? 'Day Before' : '${weeks}W',
                  onChanged: (v) => setDlgState(() => weeks = v.round()),
                ),
                Text(
                  WeddingPrepMilestone(id: '', weeksBeforeEvent: weeks, title: '', description: '').timeLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Vendor Handles This', style: TextStyle(fontSize: 14)),
                  subtitle: Text(isVendorResponsibility ? 'You (vendor) are responsible' : 'Couple does this'),
                  value: isVendorResponsibility,
                  onChanged: (v) => setDlgState(() => isVendorResponsibility = v),
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                _addMilestone(WeddingPrepMilestone(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  weeksBeforeEvent: weeks,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  iconName: selectedIcon,
                  isVendorResponsibility: isVendorResponsibility,
                  isEnabled: true,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMilestoneDialog(
    BuildContext context,
    WeddingPrepMilestone milestone,
    int index,
  ) {
    final titleCtrl = TextEditingController(text: milestone.title);
    final descCtrl = TextEditingController(text: milestone.description);
    int weeks = milestone.weeksBeforeEvent;
    bool isVendorResponsibility = milestone.isVendorResponsibility;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Edit Milestone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                const Text('Weeks Before Event', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Slider(
                  value: weeks.toDouble(),
                  min: 0,
                  max: 52,
                  divisions: 52,
                  label: weeks == 0 ? 'Day Before' : '${weeks}W',
                  onChanged: (v) => setDlgState(() => weeks = v.round()),
                ),
                Text(
                  WeddingPrepMilestone(id: '', weeksBeforeEvent: weeks, title: '', description: '').timeLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Vendor Handles This', style: TextStyle(fontSize: 14)),
                  value: isVendorResponsibility,
                  onChanged: (v) => setDlgState(() => isVendorResponsibility = v),
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                _updateMilestone(
                  index,
                  milestone.copyWith(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    weeksBeforeEvent: weeks,
                    isVendorResponsibility: isVendorResponsibility,
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
