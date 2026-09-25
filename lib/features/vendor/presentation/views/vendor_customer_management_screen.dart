import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VendorCustomerManagementScreen extends StatefulWidget {
  const VendorCustomerManagementScreen({super.key});

  @override
  State<VendorCustomerManagementScreen> createState() => _VendorCustomerManagementScreenState();
}

class _VendorCustomerManagementScreenState extends State<VendorCustomerManagementScreen> {
  String _searchQuery = '';
  String _selectedSegment = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final effectiveId = AdminImpersonationService.instance.effectiveUserId ?? auth.userId;
    if (effectiveId != null) {
      await Provider.of<BookingProvider>(context, listen: false).loadVendorBookings(effectiveId);
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'C';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  List<Map<String, dynamic>> _extractCustomersFromBookings(List<Booking> bookings) {
    final Map<String, List<Booking>> grouped = {};
    for (final b in bookings) {
      final key = b.customerId.isNotEmpty
          ? b.customerId
          : (b.customerEmail.isNotEmpty ? b.customerEmail : b.customerName);
      if (key.trim().isEmpty) continue;
      grouped.putIfAbsent(key, () => []).add(b);
    }

    final List<Map<String, dynamic>> result = [];
    final now = DateTime.now();

    for (final entry in grouped.entries) {
      final customerBookings = entry.value;
      customerBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      final first = customerBookings.first;

      final totalSpent = customerBookings
          .where((b) =>
              b.status != BookingStatus.cancelled &&
              b.status != BookingStatus.cancelledByUser &&
              b.status != BookingStatus.cancelledByVendor &&
              b.status != BookingStatus.rejected)
          .fold<double>(0.0, (sum, b) => sum + b.amount);

      final totalBookings = customerBookings.length;
      final latestDate = first.bookingDate;
      final daysSinceLast = now.difference(latestDate).inDays;
      final status = daysSinceLast <= 180 ? 'Active' : 'Inactive';

      String segment = 'Regular';
      if (totalSpent >= 10000) {
        segment = 'VIP';
      } else if (customerBookings.any((b) =>
          (b.eventType ?? '').toLowerCase().contains('corporate') ||
          (b.customerName.toLowerCase().contains('corp') ||
              b.customerName.toLowerCase().contains('sdn bhd')))) {
        segment = 'Corporate';
      } else if (totalBookings <= 1) {
        segment = 'New';
      }

      result.add({
        'id': first.customerId.isNotEmpty ? first.customerId : entry.key,
        'name': first.customerName.isNotEmpty ? first.customerName : 'Customer',
        'email': first.customerEmail,
        'phone': first.customerPhone,
        'totalBookings': totalBookings,
        'totalSpent': totalSpent,
        'lastBooking': DateFormat('yyyy-MM-dd').format(latestDate),
        'rating': 5.0,
        'status': status,
        'segment': segment,
        'avatar': _getInitials(first.customerName),
        'bookings': customerBookings.map((b) => {
          'event': b.serviceName.isNotEmpty
              ? b.serviceName
              : (b.eventType ?? 'Booking #${b.id.length > 6 ? b.id.substring(0, 6) : b.id}'),
          'date': DateFormat('yyyy-MM-dd').format(b.bookingDate),
          'amount': b.amount.toStringAsFixed(0),
        }).toList(),
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final customers = _extractCustomersFromBookings(bookingProvider.vendorBookings);

    final filteredCustomers = customers.where((customer) {
      final matchesSearch = customer['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer['email'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSegment = _selectedSegment == 'All' || customer['segment'] == _selectedSegment;
      final matchesStatus = _selectedStatus == 'All' || customer['status'] == _selectedStatus;
      return matchesSearch && matchesSegment && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Customer Management',
          style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: bookingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and filters
                _buildSearchAndFilters(),

                // Customer stats
                _buildCustomerStats(customers),

                // Customer list
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text(
                                'No customers found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Customers who book your services will appear here.',
                                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredCustomers.length,
                          itemBuilder: (context, index) =>
                              _buildCustomerCard(filteredCustomers[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),

          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSegment,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Segments')),
                    DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                    DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                    DropdownMenuItem(value: 'Corporate', child: Text('Corporate')),
                    DropdownMenuItem(value: 'New', child: Text('New')),
                  ],
                  onChanged: (value) => setState(() => _selectedSegment = value!),
                  decoration: const InputDecoration(
                    labelText: 'Segment',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Status')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                  ],
                  onChanged: (value) => setState(() => _selectedStatus = value!),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStats(List<Map<String, dynamic>> customers) {
    final totalCustomers = customers.length;
    final activeCustomers = customers.where((c) => c['status'] == 'Active').length;
    final totalRevenue = customers.fold<double>(0, (sum, c) => sum + (c['totalSpent'] as double));
    final avgRating = customers.isEmpty
        ? 0.0
        : customers.fold<double>(0, (sum, c) => sum + (c['rating'] as double)) / customers.length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatItem('Total Customers', totalCustomers.toString(), Icons.people),
          _buildStatItem('Active', activeCustomers.toString(), Icons.check_circle),
          _buildStatItem('Total Revenue', 'RM ${totalRevenue.toStringAsFixed(0)}', Icons.attach_money),
          _buildStatItem('Avg Rating', avgRating > 0 ? avgRating.toStringAsFixed(1) : '-', Icons.star),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            label,
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

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
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
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    customer['avatar'],
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Customer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customer['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: customer['status'] == 'Active'
                                ? Colors.green.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            customer['status'],
                            style: TextStyle(
                              color: customer['status'] == 'Active'
                                  ? Colors.green
                                  : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if ((customer['email'] as String).isNotEmpty)
                      Text(
                        customer['email'],
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          customer['rating'].toString(),
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${customer['totalBookings']} bookings',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount and segment
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${(customer['totalSpent'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getSegmentColor(customer['segment']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      customer['segment'],
                      style: TextStyle(
                        color: _getSegmentColor(customer['segment']),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewCustomerDetails(customer),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sendMessage(customer),
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text('Message'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _createBooking(customer),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Book'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSegmentColor(String segment) {
    switch (segment) {
      case 'VIP':
        return Colors.purple;
      case 'Corporate':
        return Colors.blue;
      case 'Regular':
        return Colors.green;
      case 'New':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  void _viewCustomerDetails(Map<String, dynamic> customer) {
    final bookings = customer['bookings'] as List<dynamic>;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          customer['avatar'],
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          if ((customer['email'] as String).isNotEmpty)
                            Text(
                              customer['email'],
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          if ((customer['phone'] as String).isNotEmpty)
                            Text(
                              customer['phone'],
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Customer stats
                Row(
                  children: [
                    _buildDetailStat('Total Bookings', customer['totalBookings'].toString()),
                    _buildDetailStat('Total Spent', 'RM ${(customer['totalSpent'] as double).toStringAsFixed(0)}'),
                    _buildDetailStat('Rating', customer['rating'].toString()),
                  ],
                ),

                const SizedBox(height: 20),

                // Recent bookings
                const Text(
                  'Recent Bookings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (bookings.isEmpty)
                  const Text('No bookings recorded yet.', style: TextStyle(color: AppTheme.textSecondaryColor))
                else
                  ...bookings.map((booking) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking['event'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              booking['date'],
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'RM ${booking['amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  )),

                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _sendMessage(customer);
                        },
                        child: const Text('Send Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
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

  void _sendMessage(Map<String, dynamic> customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening chat with ${customer['name']}...')),
    );
  }

  void _createBooking(Map<String, dynamic> customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Creating booking for ${customer['name']}...')),
    );
  }
}
