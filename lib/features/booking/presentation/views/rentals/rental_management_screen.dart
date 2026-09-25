import 'package:flutter/material.dart';
import 'package:eventease/features/booking/data/models/rental.dart';
import 'package:eventease/core/utils/app_theme.dart';

class RentalManagementScreen extends StatefulWidget {
  const RentalManagementScreen({super.key});

  @override
  State<RentalManagementScreen> createState() => _RentalManagementScreenState();
}

class _RentalManagementScreenState extends State<RentalManagementScreen> {
  // Mock rental items data
  final List<RentalItem> _rentalItems = [
    RentalItem(
      id: '1',
      vendorId: 'vendor_123',
      name: 'Elegant Wedding Dress',
      description: 'Beautiful white wedding dress with lace details',
      category: 'Suits & Gowns',
      images: ['https://via.placeholder.com/300x400?text=Wedding+Dress'],
      sizes: {'dress': ['S', 'M', 'L', 'XL']},
      dailyRate: 150.0,
      weeklyRate: 800.0,
      deposit: 300.0,
      status: RentalStatus.available,
      tags: ['wedding', 'elegant', 'lace'],
      specifications: {'color': 'white', 'material': 'lace'},
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    RentalItem(
      id: '2',
      vendorId: 'vendor_123',
      name: 'Crystal Centerpieces',
      description: 'Set of 10 crystal centerpieces for tables',
      category: 'Decorations',
      images: ['https://via.placeholder.com/300x300?text=Centerpieces'],
      sizes: {},
      dailyRate: 50.0,
      weeklyRate: 250.0,
      deposit: 100.0,
      status: RentalStatus.available,
      tags: ['wedding', 'crystal', 'elegant'],
      specifications: {'pieces': 10, 'material': 'crystal'},
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
    RentalItem(
      id: '3',
      vendorId: 'vendor_123',
      name: 'Groom\'s Tuxedo',
      description: 'Classic black tuxedo for grooms',
      category: 'Suits & Gowns',
      images: ['https://via.placeholder.com/300x400?text=Tuxedo'],
      sizes: {'suit': ['S', 'M', 'L', 'XL'], 'shoes': ['8', '9', '10', '11']},
      dailyRate: 100.0,
      weeklyRate: 500.0,
      deposit: 200.0,
      status: RentalStatus.rented,
      rentedUntil: DateTime.now().add(const Duration(days: 3)),
      currentRentalId: 'rental_123',
      tags: ['wedding', 'tuxedo', 'classic'],
      specifications: {'color': 'black', 'material': 'wool'},
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
    ),
  ];

  // Mock rental bookings data
  final List<RentalBooking> _rentalBookings = [
    RentalBooking(
      id: '1',
      customerId: 'customer_456',
      rentalItemId: '1',
      vendorId: 'vendor_123',
      pickupDate: DateTime.now().add(const Duration(days: 1)),
      returnDate: DateTime.now().add(const Duration(days: 3)),
      selectedSizes: {'dress': 'M'},
      totalCost: 300.0,
      deposit: 150.0,
      depositPaid: true,
      isCompleted: false,
      notes: 'For wedding ceremony',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Rental Management',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: () {
              _showAddRentalItemDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            _buildSummaryCards(),

            const SizedBox(height: 24),

            // Rental items list
            const Text(
              'Rental Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rentalItems.length,
              itemBuilder: (context, index) {
                final item = _rentalItems[index];
                return _buildRentalItemCard(item);
              },
            ),

            const SizedBox(height: 24),

            // Rental bookings list
            const Text(
              'Active Rentals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rentalBookings.length,
              itemBuilder: (context, index) {
                final booking = _rentalBookings[index];
                return _buildRentalBookingCard(booking);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final availableCount = _rentalItems.where((item) => item.isAvailable).length;
    final rentedCount = _rentalItems.where((item) => item.isRented).length;
    final reservedCount = _rentalItems.where((item) => item.isReserved).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Available',
            availableCount.toString(),
            Icons.check_circle,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Rented',
            rentedCount.toString(),
            Icons.inventory,
            AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Reserved',
            reservedCount.toString(),
            Icons.schedule,
            AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRentalItemCard(RentalItem item) {
    Color statusColor;
    switch (item.status) {
      case RentalStatus.available:
        statusColor = AppTheme.successColor;
        break;
      case RentalStatus.rented:
        statusColor = AppTheme.warningColor;
        break;
      case RentalStatus.reserved:
        statusColor = AppTheme.primaryColor;
        break;
      case RentalStatus.maintenance:
        statusColor = AppTheme.errorColor;
        break;
      case RentalStatus.damaged:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getRentalItemIcon(item.category),
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily: RM ${item.dailyRate.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                'Deposit: RM ${item.deposit.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showRentalItemDetailsDialog(context, item);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _updateRentalItemStatus(item);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Update'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentalBookingCard(RentalBooking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rental Booking #${booking.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pickup: ${booking.pickupDate.day}/${booking.pickupDate.month}/${booking.pickupDate.year}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'RM ${booking.totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Return: ${booking.returnDate.day}/${booking.returnDate.month}/${booking.returnDate.year}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          if (booking.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${booking.notes}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getRentalItemIcon(String category) {
    switch (category) {
      case 'Suits & Gowns':
        return Icons.checkroom;
      case 'Decorations':
        return Icons.celebration;
      case 'Accessories':
        return Icons.watch;
      default:
        return Icons.inventory;
    }
  }

  void _showAddRentalItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Rental Item'),
        content: const Text('This feature is under development. You can add rental items here.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRentalItemDetailsDialog(BuildContext context, RentalItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${item.category}'),
            Text('Daily Rate: RM ${item.dailyRate.toStringAsFixed(2)}'),
            Text('Weekly Rate: RM ${item.weeklyRate.toStringAsFixed(2)}'),
            Text('Deposit: RM ${item.deposit.toStringAsFixed(2)}'),
            Text('Status: ${item.status.toString().split('.').last}'),
            Text('Tags: ${item.tags.join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateRentalItemStatus(RentalItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Rental Item Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RentalStatus.values.map((status) {
            return ListTile(
              title: Text(status.toString().split('.').last),
              onTap: () {
                setState(() {
                  final index = _rentalItems.indexWhere((i) => i.id == item.id);
                  if (index != -1) {
                    _rentalItems[index] = item.copyWith(status: status);
                  }
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
