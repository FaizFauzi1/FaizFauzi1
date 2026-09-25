import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetScreenProvider extends ChangeNotifier {
  static const String _budgetItemsKey = 'budget_items';

  List<Map<String, dynamic>> _budgetItems = [
    {'label': 'Venue', 'spent': 8500.0, 'budget': 10000.0},
    {'label': 'Catering', 'spent': 5200.0, 'budget': 8000.0},
    {'label': 'Decoration', 'spent': 1800.0, 'budget': 2000.0},
    {'label': 'Photography', 'spent': 2500.0, 'budget': 3000.0},
  ];

  List<Map<String, dynamic>> get budgetItems => List.unmodifiable(_budgetItems);

  BudgetScreenProvider() {
    _loadBudgetItems();
  }

  Future<void> _loadBudgetItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString(_budgetItemsKey);
    if (itemsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(itemsJson);
        _budgetItems = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (e) {
        // If parsing fails, keep default items
        print('Error loading budget items: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _saveBudgetItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = jsonEncode(_budgetItems);
    await prefs.setString(_budgetItemsKey, itemsJson);
  }

  void addBudgetItem(Map<String, dynamic> item) {
    _budgetItems.add(item);
    _saveBudgetItems();
    notifyListeners();
  }

  void updateBudgetItem(int index, Map<String, dynamic> item) {
    if (index >= 0 && index < _budgetItems.length) {
      _budgetItems[index] = item;
      _saveBudgetItems();
      notifyListeners();
    }
  }

  void removeBudgetItem(int index) {
    if (index >= 0 && index < _budgetItems.length) {
      _budgetItems.removeAt(index);
      _saveBudgetItems();
      notifyListeners();
    }
  }

  void clearBudgetItems() {
    _budgetItems.clear();
    _saveBudgetItems();
    notifyListeners();
  }
}