import 'package:flutter/material.dart';
import 'package:eventease/core/database/database_service.dart';
import 'package:eventease/core/database/simple_database_init.dart';

class DatabaseStatusWidget extends StatefulWidget {
  const DatabaseStatusWidget({Key? key}) : super(key: key);

  @override
  State<DatabaseStatusWidget> createState() => _DatabaseStatusWidgetState();
}

class _DatabaseStatusWidgetState extends State<DatabaseStatusWidget> {
  String _status = 'Checking database...';
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _checkDatabaseStatus();
  }

  Future<void> _checkDatabaseStatus() async {
    try {
      final dbService = DatabaseService();
      final health = await dbService.healthCheck();
      final stats = await dbService.getDatabaseStatistics();
      
      setState(() {
        _status = health['status'] == 'healthy' ? 'Database is healthy!' : 'Database has issues';
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Database error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLoading ? Icons.hourglass_empty : 
                  _status.contains('healthy') ? Icons.check_circle : Icons.error,
                  color: _isLoading ? Colors.orange : 
                        _status.contains('healthy') ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Database Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_status),
            if (_stats != null) ...[
              const SizedBox(height: 8),
              Text('Size: ${(_stats!['database']['size'] / 1024).toStringAsFixed(2)} KB'),
              Text('Vendors: ${_stats!['vendors']['totalVendors']}'),
              Text('Orders: ${_stats!['orders']['totalOrders']}'),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkDatabaseStatus,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}



