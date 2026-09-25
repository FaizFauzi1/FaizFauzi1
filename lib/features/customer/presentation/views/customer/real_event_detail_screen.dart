import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/data/models/real_event_model.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/customer/presentation/views/customer/chat_screen.dart';
import 'package:provider/provider.dart';

class RealEventDetailScreen extends StatefulWidget {
  final RealEvent event;

  const RealEventDetailScreen({super.key, required this.event});

  @override
  State<RealEventDetailScreen> createState() => _RealEventDetailScreenState();
}

class _RealEventDetailScreenState extends State<RealEventDetailScreen> {
  int _selectedPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black45,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: Icon(Icons.share, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event inspiration link copied!')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    event.galleryImages.isNotEmpty ? event.galleryImages[_selectedPhotoIndex] : event.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      child: const Icon(Icons.celebration, size: 64, color: AppTheme.primaryColor),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.eventType.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.title,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${event.venueName}, ${event.location}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Quick Metrics
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildEventMetric(Icons.attach_money, 'Budget Range', event.budgetRange),
                        Container(height: 30, width: 1, color: Colors.grey.shade200),
                        _buildEventMetric(Icons.people_outline, 'Guest Count', '${event.guestCount} Guests'),
                        Container(height: 30, width: 1, color: Colors.grey.shade200),
                        _buildEventMetric(Icons.calendar_today, 'Event Date', DateFormat('MMM yyyy').format(event.eventDate)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Photo Gallery Strip
                  if (event.galleryImages.length > 1) ...[
                    const Text(
                      'Event Photo Gallery',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: event.galleryImages.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedPhotoIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedPhotoIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  event.galleryImages[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Event Story & Inspiration
                  const Text(
                    'The Event Story & Vision',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.storyDescription,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor, height: 1.6),
                  ),
                  const SizedBox(height: 28),

                  // Tagged Vendors Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vendor Dream Team (${event.taggedVendors.length})',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                      ),
                      TextButton.icon(
                        onPressed: () => _showBulkInquiryDialog(context, event),
                        icon: const Icon(Icons.forward_to_inbox, size: 16),
                        label: const Text('Bulk Inquire All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...event.taggedVendors.map((vendor) => _buildVendorTile(context, vendor)),

                  const SizedBox(height: 32),

                  // Action Buttons
                  // "Recreate this Event" Button
                  ElevatedButton.icon(
                    onPressed: () => _recreateEvent(context, event),
                    icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                    label: const Text(
                      'Recreate this Event in My Planner 🪄',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showBulkInquiryDialog(context, event),
                    icon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                    label: const Text(
                      'Send Inquiry to All Vendors (1-Click)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
        ),
      ],
    );
  }

  Widget _buildVendorTile(BuildContext context, TaggedVendor vendor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      vendor.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (vendor.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: AppTheme.primaryColor),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${vendor.role} • ${vendor.priceRange}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor, size: 20),
            tooltip: 'Chat with vendor',
            onPressed: () {
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              final conversation = chatProvider.createConversation(
                vendorId: vendor.id,
                vendorName: vendor.name,
                vendorEmail: 'vendor@eventease.com',
                vendorPhone: '',
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CustomerChatScreen(conversation: conversation)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _recreateEvent(BuildContext context, RealEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Recreate this Event?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'We will copy the vendor shortlist (${event.taggedVendors.length} vendors) and estimated budget (RM ${event.estimatedTotalBudget.toInt()}) into your active Event Planner project!',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vendors and budget imported into your Event Planner!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add to Planner'),
          ),
        ],
      ),
    );
  }

  void _showBulkInquiryDialog(BuildContext context, RealEvent event) {
    final dateController = TextEditingController(text: 'December 2026');
    final guestController = TextEditingController(text: event.guestCount.toString());
    final messageController = TextEditingController(
      text: "Hi! I loved your work on '${event.title}' and would love to check your availability and request a quote for our upcoming event!",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.forward_to_inbox, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Inquire ${event.taggedVendors.length} Vendors in 1-Click',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Send simultaneous inquiries to Venue, Photographer, Florist, and Caterer.',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 16),

              const Text('Estimated Event Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Estimated Guest Count', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: guestController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.people, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Custom Message to All Vendors', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Inquiries sent to all ${event.taggedVendors.length} vendors!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Send Bulk Inquiries Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
