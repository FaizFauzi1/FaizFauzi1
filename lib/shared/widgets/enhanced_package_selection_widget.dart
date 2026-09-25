import 'package:flutter/material.dart';
import '../models/services/service_package.dart';

class EnhancedPackageSelectionWidget extends StatefulWidget {
  final List<ServicePackage> packages;
  final ServicePackage? selectedPackage;
  final int? selectedPax;
  final Function(ServicePackage, int)? onPackageSelected;
  final bool showDetails;

  const EnhancedPackageSelectionWidget({
    Key? key,
    required this.packages,
    this.selectedPackage,
    this.selectedPax,
    this.onPackageSelected,
    this.showDetails = true,
  }) : super(key: key);

  @override
  _EnhancedPackageSelectionWidgetState createState() =>
      _EnhancedPackageSelectionWidgetState();
}

class _EnhancedPackageSelectionWidgetState
    extends State<EnhancedPackageSelectionWidget> {
  ServicePackage? _selectedPackage;
  int? _selectedPax;

  @override
  void initState() {
    super.initState();
    _selectedPackage = widget.selectedPackage ?? (widget.packages.isNotEmpty ? widget.packages.first : null);
    final availablePax = _selectedPackage?.getAvailablePax();
    _selectedPax = widget.selectedPax ?? ((availablePax != null && availablePax.isNotEmpty) ? availablePax.first : null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Package',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),

        // Package Selection
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.packages.length,
            itemBuilder: (context, index) {
              final package = widget.packages[index];
              final isSelected = _selectedPackage?.id == package.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPackage = package;
                    final availablePax = package.getAvailablePax();
                    _selectedPax = availablePax.isNotEmpty ? availablePax.first : null;
                  });
                  if (_selectedPax != null) {
                    widget.onPackageSelected?.call(package, _selectedPax!);
                  }
                },
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white70 : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        package.priceByPax.isNotEmpty 
                          ? 'From RM ${package.priceByPax.values.first.toStringAsFixed(0)}'
                          : 'Contact for Price',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Pax Selection
        if (_selectedPackage != null) ...[
          Text(
            'Number of Guests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedPackage!.getAvailablePax().map((pax) {
              final isSelected = _selectedPax == pax;
              final price = _selectedPackage!.getPriceForPax(pax);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPax = pax;
                  });
                  widget.onPackageSelected?.call(_selectedPackage!, pax);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$pax pax',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'RM ${price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Package Details
          if (widget.showDetails) ...[
            _buildPackageDetails(_selectedPackage!),
          ],
        ],
      ],
    );
  }

  Widget _buildPackageDetails(ServicePackage package) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Package Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Venue Details
          if (package.venueDetails != null) ...[
            _buildDetailSection(
              'Venue Information',
              [
                'Venue: ${package.venueDetails!.venueName}',
                'Address: ${package.venueDetails!.address}',
                'Capacity: ${package.venueDetails!.minCapacity} - ${package.venueDetails!.maxCapacity} guests',
                'Theme: ${package.venueDetails!.eventTheme}',
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Menus
          if (package.menus != null) ...[
            _buildDetailSection(
              'Menu Highlights',
              [
                'Main Courses: ${package.menus!.mainMenu.take(2).join(", ")}...',
                if (package.menus!.bridalDishes.isNotEmpty)
                  'Bridal Dishes: ${package.menus!.bridalDishes.take(2).join(", ")}...',
                if (package.menus!.teaCorner != null)
                  'Tea Corner: ${package.menus!.teaCorner!.snacks.take(2).join(", ")}...',
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Inclusions
          if (package.inclusions != null) ...[
            _buildDetailSection(
              'Inclusions',
              [
                'Facilities: ${package.inclusions!.commonFacilities.take(3).join(", ")}...',
                'Services: ${package.inclusions!.commonServices.take(3).join(", ")}...',
                'Photography: ${package.inclusions!.photographyServices.take(2).join(", ")}...',
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 2),
          child: Text(
            '• $item',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        )),
      ],
    );
  }
}
