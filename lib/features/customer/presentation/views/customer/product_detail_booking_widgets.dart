import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class AllInPackageBookingWidget extends StatefulWidget {
  final int? selectedPax;
  final Function(int) onPaxChanged;
  final DateTime? selectedDate;
  final Function(DateTime) onDateChanged;
  final Map<String, bool> addOns;
  final Function(String, bool) onAddOnChanged;
  final Set<DateTime> unavailableDates;

  final List<int> paxOptions;

  const AllInPackageBookingWidget({
    super.key,
    required this.selectedPax,
    required this.onPaxChanged,
    required this.selectedDate,
    required this.onDateChanged,
    required this.addOns,
    required this.onAddOnChanged,
    this.paxOptions = const [10, 20, 50, 100, 200],
    this.unavailableDates = const {},
  });

  @override
  State<AllInPackageBookingWidget> createState() => _AllInPackageBookingWidgetState();
}

class _AllInPackageBookingWidgetState extends State<AllInPackageBookingWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaxSelector(),
          const SizedBox(height: 16),
          _buildAddOns(),
        ],
      ),
    );
  }

  Widget _buildPaxSelector() {
    final paxOptions = widget.paxOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of Guests',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: paxOptions.map((pax) {
            final isSelected = widget.selectedPax == pax;
            return ChoiceChip(
              label: Text('$pax pax'),
              selected: isSelected,
              onSelected: (_) => widget.onPaxChanged(pax),
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  Widget _buildAddOns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Services',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.addOns.keys.map((key) {
          return CheckboxListTile(
            title: Text(key),
            value: widget.addOns[key],
            onChanged: (value) {
              if (value != null) {
                widget.onAddOnChanged(key, value);
              }
            },
          );
        }),
      ],
    );
  }
}

class VenueBookingWidget extends StatefulWidget {
  final DateTimeRange? selectedDateRange;
  final Function(DateTimeRange) onDateRangeChanged;
  final String? selectedSeatingLayout;
  final Function(String) onSeatingLayoutChanged;
  final Map<String, bool> addOns;
  final Function(String, bool) onAddOnChanged;
  final Set<DateTime> unavailableDates;

  const VenueBookingWidget({
    super.key,
    required this.selectedDateRange,
    required this.onDateRangeChanged,
    required this.selectedSeatingLayout,
    required this.onSeatingLayoutChanged,
    required this.addOns,
    required this.onAddOnChanged,
    this.unavailableDates = const {},
  });

  @override
  State<VenueBookingWidget> createState() => _VenueBookingWidgetState();
}

class _VenueBookingWidgetState extends State<VenueBookingWidget> {
  final List<String> seatingLayouts = ['Theater', 'Banquet', 'Classroom', 'U-Shape'];

  @override
  Widget build(BuildContext context) {
    // START DEFENSIVE CODE
    // Ensure selectedSeatingLayout is in seatingLayouts or null
    final validSeatingLayout = (widget.selectedSeatingLayout != null && seatingLayouts.contains(widget.selectedSeatingLayout))
        ? widget.selectedSeatingLayout
        : null;
    // END DEFENSIVE CODE

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Venue Booking Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSeatingLayoutDropdown(validSeatingLayout),
          const SizedBox(height: 16),
          _buildAddOns(),
        ],
      ),
    );
  }

  Widget _buildSeatingLayoutDropdown([String? validLayout]) {
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seating Layout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: validLayout ?? ((widget.selectedSeatingLayout != null && seatingLayouts.contains(widget.selectedSeatingLayout)) ? widget.selectedSeatingLayout : null),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Select layout',
            ),
            items: seatingLayouts.map((layout) {
              return DropdownMenuItem<String>(
                value: layout,
                child: Text(layout),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                widget.onSeatingLayoutChanged(value);
              }
            },
          ),
        ],
     );
  }




  Widget _buildAddOns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Services',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.addOns.keys.map((key) {
          return CheckboxListTile(
            title: Text(key),
            value: widget.addOns[key],
            onChanged: (value) {
              if (value != null) {
                widget.onAddOnChanged(key, value);
              }
            },
          );
        }),
      ],
    );
  }
}

class CateringBookingWidget extends StatefulWidget {
  final int? selectedPax;
  final Function(int) onPaxChanged;
  final String? selectedMenu;
  final Function(String) onMenuChanged;
  final Map<String, bool> liveStationAddOns;
  final Function(String, bool) onAddOnChanged;
  final List<String> menuOptions; // Added parameter
  final List<int> paxOptions;

  const CateringBookingWidget({
    super.key,
    required this.selectedPax,
    required this.onPaxChanged,
    required this.selectedMenu,
    required this.onMenuChanged,
    required this.liveStationAddOns,
    required this.onAddOnChanged,
    this.paxOptions = const [10, 20, 50, 100, 200],
    this.menuOptions = const ['Standard', 'Premium', 'Vegetarian', 'Halal'], // Default fallback
  });

  @override
  State<CateringBookingWidget> createState() => _CateringBookingWidgetState();
}

class _CateringBookingWidgetState extends State<CateringBookingWidget> {
  // Removed hardcoded list, now uses widget.menuOptions

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catering Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaxSelector(widget.menuOptions.isNotEmpty ? widget.paxOptions : [10, 20, 50, 100, 200]),
          if (widget.menuOptions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMenuSelector(),
          ],
          const SizedBox(height: 16),
          _buildLiveStations(),
        ],
      ),
    );
  }

  Widget _buildPaxSelector(List<int> paxOptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of Guests',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: paxOptions.map((pax) {
            final isSelected = widget.selectedPax == pax;
            return ChoiceChip(
              label: Text('$pax pax'),
              selected: isSelected,
              onSelected: (_) => widget.onPaxChanged(pax),
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMenuSelector() {
    // START DEFENSIVE CODE
    // Ensure selectedMenu is in menuOptions or null
    final validMenu = (widget.selectedMenu != null && widget.menuOptions.contains(widget.selectedMenu)) 
        ? widget.selectedMenu 
        : null;
    // END DEFENSIVE CODE

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Selection',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: validMenu,
          decoration: const InputDecoration(
            labelText: 'Choose Menu',
            border: OutlineInputBorder(),
          ),
          items: widget.menuOptions.map((menu) {
            return DropdownMenuItem(
              value: menu,
              child: Text(menu),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              widget.onMenuChanged(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildLiveStations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Cooking Stations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.liveStationAddOns.keys.map((key) {
          return CheckboxListTile(
            title: Text(key),
            value: widget.liveStationAddOns[key],
            onChanged: (value) {
              if (value != null) {
                widget.onAddOnChanged(key, value);
              }
            },
          );
        }),
      ],
    );
  }
}

class PhotographyBookingWidget extends StatefulWidget {
  final int selectedCrew;
  final Function(int) onCrewChanged;
  final int coverageHours;
  final Function(int) onCoverageHoursChanged;
  final Map<String, bool> addOns;
  final Function(String, bool) onAddOnChanged;

  const PhotographyBookingWidget({
    super.key,
    required this.selectedCrew,
    required this.onCrewChanged,
    required this.coverageHours,
    required this.onCoverageHoursChanged,
    required this.addOns,
    required this.onAddOnChanged,
  });

  @override
  State<PhotographyBookingWidget> createState() => _PhotographyBookingWidgetState();
}

class _PhotographyBookingWidgetState extends State<PhotographyBookingWidget> {
  @override
  Widget build(BuildContext context) {
    final crewOptions = [1, 2, 3];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photography Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildCrewSelector(crewOptions),
          const SizedBox(height: 16),
          _buildCoverageHours(),
          const SizedBox(height: 16),
          _buildAddOns(),
        ],
      ),
    );
  }

  Widget _buildCrewSelector(List<int> crewOptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photography Crew',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: crewOptions.map((crew) {
            final isSelected = widget.selectedCrew == crew;
            return ChoiceChip(
              label: Text('$crew photographer${crew > 1 ? 's' : ''}'),
              selected: isSelected,
              onSelected: (_) => widget.onCrewChanged(crew),
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCoverageHours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coverage Hours',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Hours:'),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: widget.coverageHours > 1 ? () => widget.onCoverageHoursChanged(widget.coverageHours - 1) : null,
            ),
            Text('${widget.coverageHours}'),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => widget.onCoverageHoursChanged(widget.coverageHours + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddOns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Services',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.addOns.keys.map((key) {
          return CheckboxListTile(
            title: Text(key),
            value: widget.addOns[key],
            onChanged: (value) {
              if (value != null) {
                widget.onAddOnChanged(key, value);
              }
            },
          );
        }),
      ],
    );
  }
}

class MakeupBookingWidget extends StatefulWidget {
  final String? selectedOutfitSet;
  final Function(String) onOutfitSetChanged;
  final Map<String, bool> extraSessions;
  final Function(String, bool) onExtraSessionChanged;

  const MakeupBookingWidget({
    super.key,
    required this.selectedOutfitSet,
    required this.onOutfitSetChanged,
    required this.extraSessions,
    required this.onExtraSessionChanged,
  });

  @override
  State<MakeupBookingWidget> createState() => _MakeupBookingWidgetState();
}

class _MakeupBookingWidgetState extends State<MakeupBookingWidget> {
  final List<String> outfitSets = ['Basic', 'Standard', 'Premium'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Makeup & Styling Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildOutfitSetSelector(),
          const SizedBox(height: 16),
          _buildExtraSessions(),
        ],
      ),
    );
  }

  Widget _buildOutfitSetSelector() {
    // START DEFENSIVE CODE
    // Ensure selectedOutfitSet is valid or null
    final validOutfitSet = (widget.selectedOutfitSet != null && outfitSets.contains(widget.selectedOutfitSet))
        ? widget.selectedOutfitSet
        : null;
    // END DEFENSIVE CODE

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outfit Set',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
            value: validOutfitSet,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Select outfit set',
            ),
            items: outfitSets.map((outfit) {
              return DropdownMenuItem<String>(
                value: outfit,
                child: Text(outfit),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                widget.onOutfitSetChanged(value);
              }
            },
          ),

      ],
    );
  }

  Widget _buildExtraSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Extra Sessions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.extraSessions.keys.map((key) {
          return CheckboxListTile(
            title: Text(key),
            value: widget.extraSessions[key],
            onChanged: (value) {
              if (value != null) {
                widget.onExtraSessionChanged(key, value);
              }
            },
          );
        }),
      ],
    );
  }
}
