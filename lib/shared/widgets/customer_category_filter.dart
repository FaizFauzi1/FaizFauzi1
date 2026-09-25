import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/shared/models/services/service_category.dart';
import 'package:eventease/shared/providers/category_provider.dart';
import 'package:eventease/features/event/data/models/event_type.dart';

/// Customer-facing category filter widget for search and browse
class CustomerCategoryFilter extends StatefulWidget {
  final String? selectedEventTypeId;
  final String? selectedCategoryId;
  final Function(String?) onEventTypeChanged;
  final Function(String?) onCategoryChanged;

  const CustomerCategoryFilter({
    Key? key,
    this.selectedEventTypeId,
    this.selectedCategoryId,
    required this.onEventTypeChanged,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  State<CustomerCategoryFilter> createState() => _CustomerCategoryFilterState();
}

class _CustomerCategoryFilterState extends State<CustomerCategoryFilter> {
  List<ServiceCategory> _categories = [];
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedEventTypeId != null) {
      _loadCategories();
    }
  }

  @override
  void didUpdateWidget(CustomerCategoryFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedEventTypeId != oldWidget.selectedEventTypeId) {
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    if (widget.selectedEventTypeId == null) {
      setState(() => _categories = []);
      return;
    }

    setState(() => _isLoadingCategories = true);

    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);

    try {
      final categories = await categoryProvider
          .getCategoriesForEventTypes([widget.selectedEventTypeId!]);

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventTypeFilter(),
        if (widget.selectedEventTypeId != null) ...[
          const SizedBox(height: 16),
          _buildCategoryFilter(),
        ],
      ],
    );
  }

  Widget _buildEventTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Event Type',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // "All" chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: widget.selectedEventTypeId == null,
                  label: const Text('All Events'),
                  onSelected: (selected) {
                    if (selected) {
                      widget.onEventTypeChanged(null);
                      widget.onCategoryChanged(null);
                    }
                  },
                ),
              ),
              // Event type chips
              ...EventType.values.map((eventType) {
                final isSelected = widget.selectedEventTypeId == eventType.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
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
                      if (selected) {
                        widget.onEventTypeChanged(eventType.id);
                        widget.onCategoryChanged(null); // Reset category
                      } else {
                        widget.onEventTypeChanged(null);
                        widget.onCategoryChanged(null);
                      }
                    },
                    selectedColor: eventType.color.withOpacity(0.3),
                    checkmarkColor: eventType.color,
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    if (_isLoadingCategories) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Category',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // "All Categories" chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: widget.selectedCategoryId == null,
                  label: const Text('All Categories'),
                  onSelected: (selected) {
                    if (selected) {
                      widget.onCategoryChanged(null);
                    }
                  },
                ),
              ),
              // Category chips
              ..._categories.map((category) {
                final isSelected = widget.selectedCategoryId == category.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(category.icon, size: 16),
                        const SizedBox(width: 4),
                        Text(category.name),
                      ],
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        widget.onCategoryChanged(category.id);
                      } else {
                        widget.onCategoryChanged(null);
                      }
                    },
                    selectedColor: category.color.withOpacity(0.3),
                    checkmarkColor: category.color,
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Category grid view for browsing
class CategoryBrowseGrid extends StatelessWidget {
  final String? eventTypeId;
  final Function(ServiceCategory) onCategoryTap;

  const CategoryBrowseGrid({
    Key? key,
    this.eventTypeId,
    required this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ServiceCategory>>(
      future: _loadCategories(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return const Center(
            child: Text('No categories available'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryCard(
              category: category,
              onTap: () => onCategoryTap(category),
            );
          },
        );
      },
    );
  }

  Future<List<ServiceCategory>> _loadCategories(BuildContext context) async {
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);

    if (eventTypeId != null) {
      return categoryProvider.getCategoriesForEventTypes([eventTypeId!]);
    } else {
      await categoryProvider.fetchCategories();
      return categoryProvider.allCategories;
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              category.color.withOpacity(0.8),
              category.color,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: category.color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                category.icon,
                size: 40,
                color: Colors.white,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.categoryType.displayName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
