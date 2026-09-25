import 'package:eventease/features/support/data/models/support_ticket.dart';
import 'package:eventease/features/support/data/providers/support_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'customer_support_screen.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final Set<String> _expandedItems = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportProvider = Provider.of<SupportProvider>(context);
    final faqs = _getFilteredFAQs(supportProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('FAQ & Knowledge Base'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search FAQs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('All'),
                      _buildCategoryChip('Booking'),
                      _buildCategoryChip('Payment'),
                      _buildCategoryChip('Vendor'),
                      _buildCategoryChip('Account'),
                      _buildCategoryChip('Technical'),
                      _buildCategoryChip('General'),
                      _buildCategoryChip('Refund'),
                      _buildCategoryChip('Cancellation'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // FAQ List
          Expanded(
            child: faqs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      return _buildFAQCard(faqs[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactSupportDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.contact_support, color: Colors.white),
      ),
    );
  }

  List<FAQItem> _getFilteredFAQs(SupportProvider supportProvider) {
    List<FAQItem> faqs = supportProvider.faqs;

    // Filter by category
    if (_selectedCategory != 'All') {
      faqs = faqs.where((faq) {
        return faq.category.toString().split('.').last.toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      faqs = faqs.where((faq) {
        return faq.question.toLowerCase().contains(query) ||
               faq.answer.toLowerCase().contains(query);
      }).toList();
    }

    // Sort by view count (most viewed first)
    faqs.sort((a, b) => b.viewCount.compareTo(a.viewCount));

    return faqs;
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    final isExpanded = _expandedItems.contains(faq.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              faq.question,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(faq.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      faq.category.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getCategoryColor(faq.category),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.visibility,
                    size: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${faq.viewCount} views',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppTheme.primaryColor,
            ),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedItems.remove(faq.id);
                } else {
                  _expandedItems.add(faq.id);
                  // Increment view count
                  final supportProvider = Provider.of<SupportProvider>(context, listen: false);
                  supportProvider.incrementFAQViewCount(faq.id);
                }
              });
            },
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    faq.answer,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.thumb_up_outlined),
                        onPressed: () => _showFeedbackDialog(faq, true),
                        color: AppTheme.textSecondaryColor,
                        iconSize: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.thumb_down_outlined),
                        onPressed: () => _showFeedbackDialog(faq, false),
                        color: AppTheme.textSecondaryColor,
                        iconSize: 20,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showContactSupportDialog(),
                        icon: const Icon(Icons.contact_support, size: 16),
                        label: const Text('Still need help?'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No FAQs found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filter criteria',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showContactSupportDialog(),
            icon: const Icon(Icons.contact_support),
            label: const Text('Contact Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(TicketCategory category) {
    switch (category) {
      case TicketCategory.booking:
        return Colors.blue;
      case TicketCategory.payment:
        return Colors.green;
      case TicketCategory.vendor:
        return Colors.orange;
      case TicketCategory.account:
        return Colors.purple;
      case TicketCategory.technical:
        return Colors.red;
      case TicketCategory.general:
        return Colors.grey;
      case TicketCategory.refund:
        return Colors.teal;
      case TicketCategory.cancellation:
        return Colors.indigo;
    }
  }

  void _showFeedbackDialog(FAQItem faq, bool isHelpful) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHelpful ? 'Helpful!' : 'Not Helpful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isHelpful
                  ? 'Thanks for your feedback! We\'re glad this FAQ was helpful.'
                  : 'Sorry this FAQ wasn\'t helpful. Would you like to contact support for more assistance?',
            ),
            const SizedBox(height: 16),
            if (!isHelpful)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showContactSupportDialog();
                },
                icon: const Icon(Icons.contact_support),
                label: const Text('Contact Support'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'Can\'t find what you\'re looking for? Our support team is here to help!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to customer support screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerSupportScreen(),
                ),
              );
            },
            child: const Text('Get Support'),
          ),
        ],
      ),
    );
  }
}
