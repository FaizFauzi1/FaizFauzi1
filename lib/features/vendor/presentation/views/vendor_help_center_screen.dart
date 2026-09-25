import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class VendorHelpCenterScreen extends StatefulWidget {
  const VendorHelpCenterScreen({super.key});

  @override
  State<VendorHelpCenterScreen> createState() => _VendorHelpCenterScreenState();
}

class _VendorHelpCenterScreenState extends State<VendorHelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _faqCategories = [
    {
      'title': 'Getting Started',
      'icon': Icons.rocket_launch,
      'color': AppTheme.primaryColor,
      'faqs': [
        {
          'question': 'How do I set up my vendor profile?',
          'answer': 'Go to Profile settings and fill in your business information, contact details, and service descriptions.',
        },
        {
          'question': 'How to add my first service?',
          'answer': 'Navigate to Services tab, click Add Service, and fill in the service details including pricing and availability.',
        },
        {
          'question': 'Setting up payment methods',
          'answer': 'Go to Settings > Payments to connect your bank account and configure payment options.',
        },
      ],
    },
    {
      'title': 'Bookings & Management',
      'icon': Icons.book_online,
      'color': AppTheme.secondaryColor,
      'faqs': [
        {
          'question': 'How do I manage booking requests?',
          'answer': 'Check the Bookings tab for pending requests. You can approve, reject, or modify bookings from there.',
        },
        {
          'question': 'Can I set availability schedules?',
          'answer': 'Yes, in the Services section, you can set weekly availability, buffer times, and maximum bookings per day.',
        },
        {
          'question': 'How to handle booking cancellations?',
          'answer': 'Go to the specific booking and use the cancellation option. Refunds will be processed automatically.',
        },
      ],
    },
    {
      'title': 'Payments & Payouts',
      'icon': Icons.payment,
      'color': AppTheme.successColor,
      'faqs': [
        {
          'question': 'When do I get paid?',
          'answer': 'Payouts are processed weekly on Fridays for the previous week\'s completed bookings.',
        },
        {
          'question': 'What are the commission fees?',
          'answer': 'Our platform fee is 5% of each booking. Premium vendors get reduced rates.',
        },
        {
          'question': 'How to view payment history?',
          'answer': 'Check the Reports section for detailed payment and payout history.',
        },
      ],
    },
    {
      'title': 'Marketing & Promotions',
      'icon': Icons.campaign,
      'color': AppTheme.accentColor,
      'faqs': [
        {
          'question': 'How to create promotions?',
          'answer': 'Go to Promotions tab, click Add Promotion, and set discount type, duration, and conditions.',
        },
        {
          'question': 'Running ads on the platform',
          'answer': 'Use the Ads section to create campaigns, set budgets, and target specific customer segments.',
        },
        {
          'question': 'How to improve my visibility?',
          'answer': 'Maintain high ratings, complete profiles, and use promotional tools to increase visibility.',
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> _contactOptions = [
    {
      'title': 'Live Chat',
      'subtitle': 'Chat with our support team',
      'icon': Icons.chat,
      'color': AppTheme.primaryColor,
      'action': 'chat',
    },
    {
      'title': 'Email Support',
      'subtitle': 'support@eventease.com',
      'icon': Icons.email,
      'color': AppTheme.secondaryColor,
      'action': 'email',
    },
    {
      'title': 'Phone Support',
      'subtitle': '+60 3-1234 5678',
      'icon': Icons.phone,
      'color': AppTheme.successColor,
      'action': 'phone',
    },
    {
      'title': 'Video Tutorials',
      'subtitle': 'Watch step-by-step guides',
      'icon': Icons.video_library,
      'color': AppTheme.accentColor,
      'action': 'tutorials',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _faqCategories.where((category) {
      return category['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             category['faqs'].any((faq) =>
               faq['question'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
               faq['answer'].toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Help Center',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact support
                  const Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._contactOptions.map((option) => _buildContactCard(option)).toList(),
                  const SizedBox(height: 24),

                  // FAQ sections
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...filteredCategories.map((category) => _buildFAQCategory(category)).toList(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: option['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            option['icon'],
            color: option['color'],
          ),
        ),
        title: Text(
          option['title'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          option['subtitle'],
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _handleContactAction(option['action']),
      ),
    );
  }

  Widget _buildFAQCategory(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: category['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  category['icon'],
                  color: category['color'],
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...category['faqs'].map((faq) => _buildFAQItem(faq)).toList(),
        ],
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return ExpansionTile(
      title: Text(
        faq['question'],
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            faq['answer'],
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _handleContactAction(String action) {
    switch (action) {
      case 'chat':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening live chat...')),
        );
        break;
      case 'email':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening email client...')),
        );
        break;
      case 'phone':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calling support...')),
        );
        break;
      case 'tutorials':
        _showVideoTutorials();
        break;
    }
  }

  void _showVideoTutorials() {
    final tutorials = [
      {'title': 'Getting Started Guide', 'duration': '5:30'},
      {'title': 'Managing Your Services', 'duration': '8:15'},
      {'title': 'Handling Bookings', 'duration': '6:45'},
      {'title': 'Payment & Payout Setup', 'duration': '4:20'},
      {'title': 'Marketing Your Business', 'duration': '7:10'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video Tutorials',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: tutorials.length,
                itemBuilder: (context, index) {
                  final tutorial = tutorials[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tutorial['title']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              Text(
                                tutorial['duration']!,
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
