import 'package:flutter/material.dart';
import 'package:eventease/core/database/simple_database_init.dart';
import 'package:eventease/core/database/database_service.dart';

/// Simple widget to test and manage your database
class DatabaseTestWidget extends StatefulWidget {
  const DatabaseTestWidget({Key? key}) : super(key: key);

  @override
  State<DatabaseTestWidget> createState() => _DatabaseTestWidgetState();
}

class _DatabaseTestWidgetState extends State<DatabaseTestWidget> {
  String _status = 'Ready to test database';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Database Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _initializeDatabase,
                  child: const Text('Initialize Database'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _showLocation,
                  child: const Text('Show Location'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testDatabase,
                  child: const Text('Test Database'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _showStats,
                  child: const Text('Show Statistics'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Click "Initialize Database" to create the database\n'
              '2. Click "Show Location" to see where your database file is\n'
              '3. Click "Test Database" to verify everything works\n'
              '4. Use SQLite Browser to view your database file',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeDatabase() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing database...';
    });

    try {
      await SimpleDatabaseInit.initializeAndTest();
      setState(() {
        _status =
            'Database initialized successfully! Check console for details.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showLocation() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting database location...';
    });

    try {
      await SimpleDatabaseInit.showDatabaseLocation();
      setState(() {
        _status = 'Database location shown in console. Check the output above.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDatabase() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing database...';
    });

    try {
      final dbService = DatabaseService();
      await dbService.initializeDatabase();

      final health = await dbService.healthCheck();
      final stats = await dbService.getDatabaseStatistics();

      setState(() {
        _status = 'Database test completed!\n'
            'Status: ${health['status']}\n'
            'Vendors: ${health['vendorCount']}\n'
            'Customers: ${health['customerCount']}\n'
            'Size: ${(stats['database']['size'] / 1024).toStringAsFixed(2)} KB';
      });
    } catch (e) {
      setState(() {
        _status = 'Test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showStats() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting database statistics...';
    });

    try {
      final dbService = DatabaseService();
      final stats = await dbService.getDatabaseStatistics();

      setState(() {
        _status = 'Database Statistics:\n'
            'Size: ${(stats['database']['size'] / 1024).toStringAsFixed(2)} KB\n'
            'Vendors: ${stats['vendors']['totalVendors']}\n'
            'Orders: ${stats['orders']['totalOrders']}\n'
            'Revenue: RM ${stats['orders']['totalRevenue'].toStringAsFixed(2)}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting stats: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}



