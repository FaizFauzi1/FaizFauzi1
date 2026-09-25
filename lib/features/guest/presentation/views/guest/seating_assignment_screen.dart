import 'package:flutter/material.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/guest/data/models/guest.dart';

class SeatingAssignmentScreen extends StatefulWidget {
  final Event event;
  final Guest guest;

  const SeatingAssignmentScreen({
    super.key,
    required this.event,
    required this.guest,
  });

  @override
  State<SeatingAssignmentScreen> createState() => _SeatingAssignmentScreenState();
}

class _SeatingAssignmentScreenState extends State<SeatingAssignmentScreen> {
  String? _selectedTable;
  String? _selectedSeat;

  // Sample seating data - in real app this would come from backend
  final List<Map<String, dynamic>> _tables = [
    {
      'id': 'T1',
      'name': 'Table 1',
      'capacity': 8,
      'guests': ['John Smith', 'Sarah Johnson', 'Mike Wilson', 'Emma Davis'],
      'location': 'Center Front',
    },
    {
      'id': 'T2',
      'name': 'Table 2',
      'capacity': 8,
      'guests': ['Alex Brown', 'Lisa Chen', 'David Lee', 'Anna Garcia'],
      'location': 'Center Middle',
    },
    {
      'id': 'T3',
      'name': 'Table 3',
      'capacity': 6,
      'guests': ['Tom Anderson', 'Maria Rodriguez', 'Chris Taylor'],
      'location': 'Left Side',
    },
    {
      'id': 'T4',
      'name': 'Table 4',
      'capacity': 6,
      'guests': ['Jennifer White', 'Robert Martinez', 'Linda Thompson'],
      'location': 'Right Side',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Check if seating assignment feature is enabled
    final guestFeatures = widget.event.additionalInfo['guestFeatures'] as Map<String, dynamic>? ?? {};
    final isSeatingAssignmentEnabled = guestFeatures['Seating Assignment'] ?? false;

    if (!isSeatingAssignmentEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.event.title} - Seating'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: _buildFeatureDisabledState('Seating Assignment'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event.title} - Seating'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Your Seating Assignment',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find your table and seat for the event',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Current Assignment Card
              if (_selectedTable != null && _selectedSeat != null) ...[
                _buildCurrentAssignmentCard(),
                const SizedBox(height: 24),
              ],

              // Venue Layout
              Text(
                'Venue Layout',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildVenueLayout(),

              const SizedBox(height: 24),

              // Table Details
              Text(
                'Table Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildTableGrid(),

              const SizedBox(height: 24),

              // Special Notes
              _buildSpecialNotesCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentAssignmentCard() {
    final table = _tables.firstWhere((t) => t['id'] == _selectedTable);
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_seat,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Seat Assignment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Table: ${table['name']} (${table['location']})',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Seat: $_selectedSeat',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Fellow guests at your table: ${(table['guests'] as List<String>).join(', ')}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueLayout() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance,
              size: 48,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 8),
            Text(
              'Stage',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _tables.length,
      itemBuilder: (context, index) {
        final table = _tables[index];
        final isSelected = _selectedTable == table['id'];

        return GestureDetector(
          onTap: () => _selectTable(table['id']),
          child: Card(
            elevation: isSelected ? 8 : 2,
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.table_restaurant,
                        size: 20,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          table['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${table['guests'].length}/${table['capacity']} seats',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    table['location'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        (table['guests'] as List<String>).join(', '),
                        style: const TextStyle(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecialNotesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Important Notes',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Please arrive 15 minutes before your seating time',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Table assignments are final and cannot be changed on the day of the event',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              '• If you have special seating requirements, please contact the event coordinator',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Name cards will be placed at each seat',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _selectTable(String tableId) {
    setState(() {
      _selectedTable = tableId;
      // Auto-assign first available seat
      final table = _tables.firstWhere((t) => t['id'] == tableId);
      final occupiedSeats = table['guests'].length;
      _selectedSeat = 'Seat ${occupiedSeats + 1}';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${tableId} - Seat $_selectedSeat'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFeatureDisabledState(String featureName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_seat_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '$featureName Disabled',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature has been disabled by the event host.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
