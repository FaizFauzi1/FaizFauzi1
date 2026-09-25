import 'package:flutter/material.dart';
import 'package:eventease/core/database/database_test_widget.dart';

/// Simple main.dart to test your database
/// Replace your main.dart with this temporarily to test the database
void main() {
  runApp(const DatabaseTestApp());
}

class DatabaseTestApp extends StatelessWidget {
  const DatabaseTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventEase Database Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DatabaseTestWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}



