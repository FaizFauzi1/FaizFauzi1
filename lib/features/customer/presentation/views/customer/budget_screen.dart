import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/budget/data/providers/budget_provider.dart';
import 'package:eventease/features/budget/data/models/budget.dart';
import 'package:eventease/features/budget/data/models/budget_category.dart';
import 'package:eventease/features/budget/data/models/budget_expense.dart';
import 'package:eventease/features/event/data/models/event_template.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart' as ep;
import 'package:eventease/core/services/onboarding_service.dart';
import 'package:eventease/shared/widgets/tutorial_overlay.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class CustomerBudgetScreen extends StatefulWidget {
  final String? eventId;
  final bool showAppBar;
  const CustomerBudgetScreen({super.key, this.eventId, this.showAppBar = true});

  @override
  State<CustomerBudgetScreen> createState() => _CustomerBudgetScreenState();
}

class _CustomerBudgetScreenState extends State<CustomerBudgetScreen> {
  final _labelController = TextEditingController();
  final _allocatedController = TextEditingController();
  
  // Tutorial Keys
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _categoriesKey = GlobalKey();
  final GlobalKey _addCategoryKey = GlobalKey();
  
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    final provider = context.read<BudgetProvider>();
    final eventProvider = context.read<ep.EventProvider>();
    
    String? idToLoad = widget.eventId;
    
    if (idToLoad == null && eventProvider.events.isNotEmpty) {
      idToLoad = eventProvider.events.first.id;
    }
    
    if (idToLoad != null) {
      await provider.loadBudgetForEvent(idToLoad);
    } else {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        await provider.loadBudgets(authProvider.userId!);
      }
    }
    // ... rest of the method

    // Check for tutorial
    final hasCompletedTutorial = await OnboardingService.isTutorialCompleted('budget_planner');
    if (!hasCompletedTutorial && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  void _showTemplateSelection(BudgetProvider provider, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Choose an Event Template',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: EventTemplate.availableTemplates.length,
                  itemBuilder: (context, index) {
                    final template = EventTemplate.availableTemplates[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () async {
                          if (widget.eventId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select an event first')),
                            );
                            Navigator.pop(context);
                            return;
                          }
                          // Call applyTemplate which handles clearing old data and applying new
                          final eventProvider = context.read<ep.EventProvider>();
                          final event = eventProvider.getEventById(widget.eventId!);
                          
                          if (event != null) {
                            await eventProvider.applyTemplate(event, template, clearExisting: true);
                            await provider.loadBudgetForEvent(widget.eventId!);
                          }
                          
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Applied template: ${template.title}')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(16),
                            color: AppTheme.primaryColor.withOpacity(0.02),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(_getTemplateIcon(template.type), color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(template.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(template.description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTemplateIcon(EventTemplateType type) {
    switch (type) {
      case EventTemplateType.wedding: return Icons.favorite;
      case EventTemplateType.corporate: return Icons.business;
      case EventTemplateType.party: return Icons.celebration;
      case EventTemplateType.blank: return Icons.note_add;
    }
  }

  void _showTotalBudgetDialog(BudgetProvider provider, Budget budget) {
    _allocatedController.text = budget.totalBudget.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Set Total Budget"),
        content: TextField(
          controller: _allocatedController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Total Budget (RM)",
            border: OutlineInputBorder(),
            prefixText: "RM ",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(_allocatedController.text.trim());
              if (val != null && val >= 0) {
                provider.updateTotalBudget(budget.id, val);
                Navigator.pop(context);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(bool isEditing, BudgetProvider provider, String budgetId, [BudgetCategory? category]) {
    if (isEditing && category != null) {
      _labelController.text = category.name;
      _allocatedController.text = category.allocatedAmount.toString();
    } else {
      _labelController.clear();
      _allocatedController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? "Edit Category" : "Add Category"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: "Category Name", border: OutlineInputBorder()),
              enabled: !isEditing,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _allocatedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Allocated Budget (RM)", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          if (isEditing && category != null)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Delete Category?"),
                    content: Text("This will permanently remove '${category.name}' and all its associated expenses."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                      ElevatedButton(
                        onPressed: () {
                          provider.deleteCategory(budgetId, category.id);
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
                );
              },
              child: const Text("Delete Category", style: TextStyle(color: Colors.red)),
            ),
          const Spacer(),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final allocatedText = _allocatedController.text.trim();
              final label = _labelController.text.trim();
              if (allocatedText.isNotEmpty) {
                final allocated = double.tryParse(allocatedText) ?? 0;
                if (allocated >= 0) {
                  if (isEditing && category != null) {
                    provider.updateBudgetAllocation(budgetId, category.id, allocated);
                  } else if (label.isNotEmpty) {
                    provider.addCategory(budgetId, label, allocated);
                  }
                  Navigator.pop(context);
                }
              }
            },
            child: Text(isEditing ? "Update" : "Add"),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BudgetProvider provider, String budgetId, String categoryId) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Expense Name")),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (RM)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (nameController.text.isNotEmpty && amount > 0) {
                final expense = BudgetExpense(
                  id: const Uuid().v4(),
                  budgetId: budgetId,
                  categoryId: categoryId,
                  vendorId: '',
                  description: nameController.text,
                  amount: amount,
                  status: ExpenseStatus.paid,
                  expenseDate: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                provider.addExpense(expense);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final authProvider = context.read<AuthProvider>();

    if (!provider.isLoaded) {
      final loadingWidget = const Center(child: CircularProgressIndicator());
      if (!widget.showAppBar) return loadingWidget;
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('Budget Planner'), centerTitle: true),
        body: loadingWidget,
      );
    }

    Budget? budget;
    if (widget.eventId != null) {
      budget = provider.budgets.where((b) => b.eventId == widget.eventId).firstOrNull;
    } else if (provider.budgets.isNotEmpty) {
      budget = provider.budgets.first;
    }

    if (budget == null) {
      final emptyBody = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 24),
              const Text('No Budget Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Choose a template to get started with your event budget tracking.', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                onPressed: () => _showTemplateSelection(provider, authProvider),
                label: const Text('Initialize Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );

      if (!widget.showAppBar) return emptyBody;
      return Scaffold(backgroundColor: AppTheme.backgroundColor, appBar: AppBar(title: const Text('Budget Planner'), centerTitle: true), body: emptyBody);
    }

    final activeBudget = budget;
    
    final content = Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(provider, activeBudget),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                TextButton.icon(
                  onPressed: () => _showCategoryDialog(false, provider, activeBudget.id),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Custom"),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeBudget.categories.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No categories yet.")))
            else
              Column(
                key: _categoriesKey,
                children: activeBudget.categories.map((c) => _budgetCategoryTile(provider, activeBudget, c)).toList(),
              ),
            
            if (activeBudget.expenses.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text("Recent Expenses", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 12),
              ...activeBudget.expenses.reversed.take(5).map((e) => _expenseTile(provider, activeBudget, e)),
            ],
            const SizedBox(height: 80), // Padding for tutorial button
          ],
        ),
        
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            key: _addCategoryKey,
            onPressed: () => setState(() => _showTutorial = true),
            backgroundColor: Colors.white,
            mini: true,
            child: const Icon(Icons.help_outline, color: AppTheme.primaryColor),
          ),
        ),

        if (_showTutorial)
          TutorialOverlay(
            steps: [
              TutorialStep(
                title: 'Welcome to Budget Planner',
                message: 'Track your event expenses and manage allocations in one place.',
                alignment: Alignment.center,
              ),
              TutorialStep(
                title: 'Budget Summary',
                message: 'Tap the card to change your total target budget.',
                targetKey: _summaryKey,
                alignment: Alignment.bottomCenter,
              ),
              TutorialStep(
                title: 'Manage Categories',
                message: 'Tap on any category to update its allocation or add expenses. Green = under budget, Red = over budget.',
                targetKey: _categoriesKey,
                alignment: Alignment.topCenter,
              ),
            ],
            onCompleted: () {
              OnboardingService.markTutorialAsCompleted('budget_planner');
              setState(() => _showTutorial = false);
            },
            onSkip: () {
              OnboardingService.markTutorialAsCompleted('budget_planner');
              setState(() => _showTutorial = false);
            },
          ),
      ],
    );

    if (!widget.showAppBar) return content;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Budget Planner'), centerTitle: true),
      body: content,
    );
  }

  Widget _buildSummaryCard(BudgetProvider provider, Budget activeBudget) {
    final totalSpent = activeBudget.spentBudget;
    final totalBudget = activeBudget.totalBudget;
    final totalAllocated = activeBudget.allocatedBudget;
    final totalRatio = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final allocatedRatio = totalBudget > 0 ? (totalAllocated / totalBudget).clamp(0.0, 1.0) : 0.0;
    final isOverSpent = activeBudget.isOverSpent;
    final isOverAllocated = activeBudget.isOverAllocated;
    final alerts = activeBudget.getBudgetAlerts();

    return GestureDetector(
      onTap: () => _showTotalBudgetDialog(provider, activeBudget),
      child: Container(
        key: _summaryKey,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Overall Budget", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Icon(Icons.edit, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "RM ${totalSpent.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isOverSpent ? Colors.red : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "of RM ${totalBudget.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  "${(totalRatio * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isOverSpent ? Colors.red : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: totalRatio,
                backgroundColor: Colors.grey.shade100,
                color: isOverSpent ? Colors.red : AppTheme.primaryColor,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Allocated: RM ${totalAllocated.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isOverAllocated ? Colors.orange[800] : Colors.grey[700],
                  ),
                ),
                Text(
                  "${(allocatedRatio * 100).toStringAsFixed(0)}% Assigned",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: allocatedRatio,
                backgroundColor: Colors.grey.shade100,
                color: isOverAllocated ? Colors.orange : Colors.blueGrey,
                minHeight: 4,
              ),
            ),
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...alerts.map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      alert.contains('exceeds') ? Icons.error_outline : Icons.info_outline,
                      color: alert.contains('exceeds') ? Colors.red : Colors.orange[700],
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert,
                        style: TextStyle(
                          fontSize: 12,
                          color: alert.contains('exceeds') ? Colors.red : Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _budgetCategoryTile(BudgetProvider provider, Budget budget, BudgetCategory category) {
    final spent = category.spentAmount;
    final allocated = category.allocatedAmount;
    final ratio = allocated > 0 ? (spent / allocated).clamp(0.0, 1.0) : 0.0;
    final isOver = category.isOverBudget;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: Color(int.parse(category.color.replaceAll('#', '0xFF'))), shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      "RM ${spent.toStringAsFixed(0)} / RM ${allocated.toStringAsFixed(0)}",
                      style: TextStyle(fontSize: 12, color: isOver ? Colors.red : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: Colors.grey.shade100,
                color: isOver ? Colors.red : AppTheme.primaryColor,
                minHeight: 6,
              ),
            ),
          ),
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showCategoryDialog(true, provider, budget.id, category),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Edit Allocation"),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showAddExpenseDialog(provider, budget.id, category.id),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Add Expense"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ),
            ...budget.expenses.where((e) => e.categoryId == category.id).map((e) => _expenseTile(provider, budget, e)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _expenseTile(BudgetProvider provider, Budget budget, BudgetExpense expense) {
    return ListTile(
      dense: true,
      title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(DateFormat('dd MMM yyyy').format(expense.createdAt)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("RM ${expense.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
            onPressed: () => provider.deleteExpense(expense.id, budget.id),
          ),
        ],
      ),
    );
  }
}
