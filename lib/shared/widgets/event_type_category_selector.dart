import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/shared/models/services/service_category.dart';
import 'package:eventease/shared/providers/category_provider.dart';
import 'package:eventease/features/event/data/models/event_type.dart';

/// Widget for selecting event types and categories with progressive disclosure
class EventTypeCategorySelector extends StatefulWidget {
  final List<String> selectedEventTypeIds;
  final String? selectedCategoryId;
  final Function(List<String>) onEventTypesChanged;
  final Function(ServiceCategory?) onCategoryChanged;
  final bool isVerified;
  final VendorTier vendorTier;
  final String? verificationStatus;

  const EventTypeCategorySelector({
    Key? key,
    required this.selectedEventTypeIds,
    this.selectedCategoryId,
    required this.onEventTypesChanged,
    required this.onCategoryChanged,
    this.isVerified = false,
    this.vendorTier = VendorTier.basic,
    this.verificationStatus,
  }) : super(key: key);

  @override
  State<EventTypeCategorySelector> createState() =>
      _EventTypeCategorySelectorState();
}

class _EventTypeCategorySelectorState
    extends State<EventTypeCategorySelector> {
  List<ServiceCategory> _primaryCategories = [];
  List<ServiceCategory> _secondaryCategories = [];
  bool _showAllCategories = false;
  bool _isLoadingCategories = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.selectedEventTypeIds.isNotEmpty) {
      _loadCategories();
    }
  }

  @override
  void didUpdateWidget(EventTypeCategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedEventTypeIds != oldWidget.selectedEventTypeIds) {
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    if (widget.selectedEventTypeIds.isEmpty) {
      setState(() {
        _primaryCategories = [];
        _secondaryCategories = [];
      });
      return;
    }

    setState(() => _isLoadingCategories = true);

    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);

    try {
      final primary = await categoryProvider
          .getPrimaryCategoriesForEventTypes(widget.selectedEventTypeIds);
      final secondary = await categoryProvider
          .getSecondaryCategoriesForEventTypes(widget.selectedEventTypeIds);

      // Filter by vendor access
      final accessiblePrimary = primary
          .where((c) => c.canVendorAccess(
                isVerified: widget.isVerified,
                vendorTier: widget.vendorTier,
                verificationStatus: widget.verificationStatus,
              ))
          .toList();

      final accessibleSecondary = secondary
          .where((c) => c.canVendorAccess(
                isVerified: widget.isVerified,
                vendorTier: widget.vendorTier,
                verificationStatus: widget.verificationStatus,
              ))
          .toList();

      setState(() {
        _primaryCategories = accessiblePrimary;
        _secondaryCategories = accessibleSecondary;
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  List<ServiceCategory> get _displayedCategories {
    List<ServiceCategory> categories = _showAllCategories
        ? [..._primaryCategories, ..._secondaryCategories]
        : _primaryCategories;

    if (_searchQuery.isNotEmpty) {
      categories = categories
          .where((c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventTypeSelection(),
        const SizedBox(height: 24),
        if (widget.selectedEventTypeIds.isNotEmpty) ...[
          _buildCategorySelection(),
        ],
      ],
    );
  }

  Widget _buildEventTypeSelection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Step 1: Select Event Type(s)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Choose which event types this service is suitable for',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            _buildEventTypeChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeChips() {
    // Group event types by category
    final groups = {
      'Social Events': EventType.getSocialEvents(),
      'Corporate Events': EventType.getCorporateEvents(),
      'Community Events': EventType.getCommunityEvents(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value.map((eventType) {
                final isSelected =
                    widget.selectedEventTypeIds.contains(eventType.id);
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(eventType.icon, size: 16),
                      const SizedBox(width: 4),
                      Text(eventType.displayName),
                    ],
                  ),
                  onSelected: (selected) {
                    final newSelection = List<String>.from(
                        widget.selectedEventTypeIds);
                    if (selected) {
                      newSelection.add(eventType.id);
                    } else {
                      newSelection.remove(eventType.id);
                    }
                    widget.onEventTypesChanged(newSelection);
                  },
                  selectedColor: eventType.color.withOpacity(0.3),
                  checkmarkColor: eventType.color,
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Step 2: Select Service Category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Choose the category that best describes your service',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            
            // Search bar
            if (_primaryCategories.length + _secondaryCategories.length > 8)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

            // Loading state
            if (_isLoadingCategories)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_displayedCategories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'No categories found matching "$_searchQuery"'
                        : 'No categories available for selected event types',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              _buildCategoryGrid(),

            // Show More button
            if (_secondaryCategories.isNotEmpty && _searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _showAllCategories = !_showAllCategories);
                    },
                    icon: Icon(_showAllCategories
                        ? Icons.expand_less
                        : Icons.expand_more),
                    label: Text(_showAllCategories
                        ? 'Show Less'
                        : 'Show ${_secondaryCategories.length} More Categories'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _displayedCategories.length,
      itemBuilder: (context, index) {
        final category = _displayedCategories[index];
        final isSelected = widget.selectedCategoryId == category.id;

        return InkWell(
          onTap: category.isAdvanced && !widget.isVerified
              ? null
              : () => widget.onCategoryChanged(category),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : category.isAdvanced && !widget.isVerified
                      ? Colors.grey[100]
                      : Colors.white,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      category.icon,
                      size: 20,
                      color: category.isAdvanced && !widget.isVerified
                          ? Colors.grey
                          : category.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: category.isAdvanced && !widget.isVerified
                              ? Colors.grey
                              : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (category.isAdvanced)
                      Icon(
                        widget.isVerified ? Icons.verified : Icons.lock,
                        size: 16,
                        color: widget.isVerified
                            ? Colors.green
                            : Colors.grey,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${category.categoryType.displayName} • ${category.pricingModel.displayName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
