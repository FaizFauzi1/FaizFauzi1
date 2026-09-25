import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/data/models/transfer_listing.dart';
import 'package:eventease/features/customer/data/models/item_listing.dart';
import 'package:eventease/features/customer/data/providers/marketplace_provider.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/customer/presentation/views/customer/chat_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/seller_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListingDetailScreen extends StatefulWidget {
  final TransferListing? transferListing;
  final ItemListing? itemListing;

  const ListingDetailScreen({
    super.key,
    this.transferListing,
    this.itemListing,
  }) : assert(transferListing != null || itemListing != null);

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _isInterested = false;
  bool _isClaiming = false;
  bool _claimed = false;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  bool get _isOwnListing {
    final uid = _currentUserId;
    if (uid == null) return false;
    if (widget.transferListing != null) return widget.transferListing!.customerId == uid;
    return widget.itemListing!.customerId == uid;
  }

  bool get _isSold {
    if (widget.transferListing != null) {
      return widget.transferListing!.listingStatus == TransferListingStatus.sold;
    }
    return widget.itemListing!.listingStatus == ItemListingStatus.sold;
  }

  void _chatWithSeller(BuildContext context, String sellerId, String sellerName) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to chat')),
      );
      return;
    }

    if (currentUser.id == sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot chat with yourself')),
      );
      return;
    }

    final conversation = chatProvider.createConversation(
      vendorId: sellerId,
      vendorName: sellerName,
      vendorEmail: 'seller@example.com',
      vendorPhone: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerChatScreen(conversation: conversation),
      ),
    );
  }

  void _showReportDialog(BuildContext context, String listingId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Listing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please tell us why you are reporting this listing:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Scammer, inappropriate content, incorrect price...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<MarketplaceProvider>(context, listen: false);
                provider.reportListing(listingId, controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listing reported successfully. Thank you.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Buyer taps "I Want This" — shows confirmation dialog then marks listing
  Future<void> _claimListing() async {
    final isBooking = widget.transferListing != null;
    final title = isBooking ? widget.transferListing!.vendorName : widget.itemListing!.itemName;
    final price = isBooking ? widget.transferListing!.sellingPrice : widget.itemListing!.price;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Confirm Interest'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are expressing interest in:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'RM ${price.toStringAsFixed(2)}',
              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The seller will be notified. Chat with them to arrange payment & transfer.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("I'm Interested!", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isClaiming = true);

    // ⚡ TEST MODE: simulate claim locally
    await Future.delayed(const Duration(milliseconds: 800)); // simulate network

    if (mounted) {
      setState(() {
        _isClaiming = false;
        _claimed = true;
        _isInterested = true;
      });

      // Mark listing as sold in provider (local)
      final provider = Provider.of<MarketplaceProvider>(context, listen: false);
      final listingId = widget.transferListing?.id ?? widget.itemListing!.id;
      provider.markListingAsSold(listingId, isTransfer: widget.transferListing != null);

      _showClaimSuccessSheet(title, price);
    }
  }

  void _showClaimSuccessSheet(String title, double price) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Interest Registered! 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your interest in "$title" has been sent to the seller.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  _NextStep(icon: Icons.chat_bubble_outline, text: 'Chat with the seller to arrange details'),
                  SizedBox(height: 6),
                  _NextStep(icon: Icons.payment, text: 'Agree on payment method (bank transfer, etc.)'),
                  SizedBox(height: 6),
                  _NextStep(icon: Icons.handshake_outlined, text: 'Complete the booking/item handover'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  final sellerId = widget.transferListing?.customerId ?? widget.itemListing!.customerId;
                  _chatWithSeller(context, sellerId, 'Marketplace Seller');
                },
                icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                label: const Text('Chat with Seller Now', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: AppTheme.textSecondaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBooking = widget.transferListing != null;
    final images = isBooking ? widget.transferListing!.images : widget.itemListing!.images;
    final title = isBooking ? widget.transferListing!.vendorName : widget.itemListing!.itemName;
    final category = isBooking ? widget.transferListing!.category : widget.itemListing!.category;
    final price = isBooking ? widget.transferListing!.sellingPrice : widget.itemListing!.price;
    final description = isBooking ? widget.transferListing!.packageDescription : widget.itemListing!.description;
    final sellerId = isBooking ? widget.transferListing!.customerId : widget.itemListing!.customerId;
    final listingId = isBooking ? widget.transferListing!.id : widget.itemListing!.id;
    final isVerified = isBooking ? widget.transferListing!.vendorId != null : false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isBooking ? 'Booking Transfer Details' : 'Item Resale Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: Colors.red),
            onPressed: () => _showReportDialog(context, listingId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            if (images.isNotEmpty)
              Image.network(images.first, height: 260, width: double.infinity, fit: BoxFit.cover)
            else
              Container(
                height: 200,
                color: Colors.grey.shade100,
                alignment: Alignment.center,
                child: const Icon(Icons.image, size: 60, color: Colors.grey),
              ),

            // SOLD banner
            if (_isSold || _claimed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.red.shade600,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('LISTING SOLD / CLAIMED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified, color: AppTheme.successColor, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'EventEase Verified',
                                style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      else if (isBooking)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'External Vendor',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 12),

                  // Pricing Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'RM ${price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                      if (isBooking) ...[
                        const SizedBox(width: 12),
                        Text(
                          'RM ${widget.transferListing!.originalBookingPrice.toStringAsFixed(2)} original',
                          style: const TextStyle(fontSize: 14, decoration: TextDecoration.lineThrough, color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ],
                  ),

                  // Savings badge
                  if (isBooking && widget.transferListing!.originalBookingPrice > price) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'Save RM ${(widget.transferListing!.originalBookingPrice - price).toStringAsFixed(0)} (${((widget.transferListing!.originalBookingPrice - price) / widget.transferListing!.originalBookingPrice * 100).round()}% off)',
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],

                  const Divider(height: 32),

                  // Detail fields
                  if (isBooking) ...[
                    _buildDetailRow('Event Date', DateFormat('EEEE, dd MMM yyyy').format(widget.transferListing!.eventDate)),
                    if (widget.transferListing!.reason != null && widget.transferListing!.reason!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow('Reason for Transfer', widget.transferListing!.reason!),
                    ],
                  ] else ...[
                    _buildDetailRow('Condition', widget.itemListing!.condition == ItemCondition.newCondition ? 'New' : widget.itemListing!.condition == ItemCondition.likeNew ? 'Like New' : 'Used'),
                    if (widget.itemListing!.brand != null && widget.itemListing!.brand!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow('Brand', widget.itemListing!.brand!),
                    ],
                    if (widget.itemListing!.size != null && widget.itemListing!.size!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow('Size', widget.itemListing!.size!),
                    ],
                    const SizedBox(height: 12),
                    _buildDetailRow('Quantity', '${widget.itemListing!.quantity} available'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Location', widget.itemListing!.location),
                    const SizedBox(height: 12),
                    _buildDetailRow('Delivery Options', widget.itemListing!.deliveryOption == 'both' ? 'Delivery & Pickup' : widget.itemListing!.deliveryOption == 'delivery' ? 'Delivery Only' : 'Pickup Only'),
                  ],

                  const Divider(height: 32),

                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 15, color: AppTheme.textSecondaryColor, height: 1.5),
                  ),

                  const SizedBox(height: 32),

                  // Seller Card Info (Tappable to view full Seller Profile)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerProfileScreen(
                            sellerId: sellerId,
                            sellerName: 'Aisyah & Danial Wedding Wardrobe',
                            isVerified: true,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.person, color: AppTheme.primaryColor, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'Aisyah & Danial',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.verified, color: AppTheme.primaryColor, size: 16),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 14),
                                    SizedBox(width: 2),
                                    Text('4.9 (28 reviews) • ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    Text('View Profile →', style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!_isOwnListing && !(_isSold || _claimed))
                            ElevatedButton.icon(
                              onPressed: () => _chatWithSeller(context, sellerId, 'Aisyah & Danial'),
                              icon: const Icon(Icons.chat, size: 16, color: Colors.white),
                              label: const Text('Chat', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── BUYER ACTION BUTTONS ─────────────────────────────
                  if (_isOwnListing) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('This is your listing', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ] else if (_isSold || _claimed) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.block, color: Colors.red),
                          SizedBox(width: 8),
                          Text('This listing has been claimed', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Primary CTA — I Want This
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isClaiming ? null : _claimListing,
                        icon: _isClaiming
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.shopping_bag, color: Colors.white),
                        label: Text(
                          _isClaiming ? 'Processing...' : "I Want This! 🎉 (RM ${NumberFormat.decimalPattern().format(price.toInt())})",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Secondary — Make an Offer & Chat
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showMakeOfferDialog(context, price),
                            icon: const Icon(Icons.local_offer_outlined, size: 18),
                            label: const Text('Make an Offer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade700,
                              side: BorderSide(color: Colors.teal.shade700),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _chatWithSeller(context, sellerId, 'Aisyah & Danial'),
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text('Ask Question'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(color: AppTheme.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMakeOfferDialog(BuildContext context, double originalPrice) {
    final offerController = TextEditingController(text: (originalPrice * 0.85).round().toString());
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.local_offer, color: Colors.teal),
            SizedBox(width: 8),
            Text('Make an Offer', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Listed Price: RM ${NumberFormat.decimalPattern().format(originalPrice.toInt())}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 16),
            const Text('Your Offer Price (MYR)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: offerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'RM ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Message to Seller (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Can do self pickup this Saturday!',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Offer of RM ${offerController.text.trim()} sent to seller!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimaryColor),
          ),
        ),
      ],
    );
  }
}

class _NextStep extends StatelessWidget {
  final IconData icon;
  final String text;
  const _NextStep({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
