import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/data/vendor_services_data.dart';
import 'package:eventease/features/customer/data/providers/favorites_provider.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/presentation/views/customer/product_detail_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/chat_screen.dart';
import 'package:eventease/features/chat/data/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/customer/presentation/views/customer/vendor_info_screen.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/shared/widgets/app_footer.dart';
import 'package:flutter/foundation.dart';
import 'package:eventease/shared/widgets/service_video_player.dart';

class VendorServicesScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String vendorCategory;
  final String? vendorDescription;
  final String? vendorImage;

  const VendorServicesScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.vendorCategory,
    this.vendorDescription,
    this.vendorImage,
  });

  @override
  State<VendorServicesScreen> createState() => _VendorServicesScreenState();
}

class _VendorServicesScreenState extends State<VendorServicesScreen> {
  List<VendorService> _vendorServices = [];
  bool _isLoading = true;
  String? _vendorEmail;
  bool _isInitialized = false;
  List<String> _portfolioImages = [];
  List<String> _serviceAreas = [];

  @override
  void initState() {
    super.initState();
    _loadVendorServices();
  }

  Future<void> _loadVendorServices() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      
      // 1. Load services from Supabase for this vendor
      await vendorProvider.loadVendorServices(widget.vendorId);
      
      // 2. Get the enhanced services and convert to VendorService for the UI
      final enhancedServices = vendorProvider.getServicesForVendor(widget.vendorId);
      
      final List<VendorService> realServices = [];
      for (var enhanced in enhancedServices) {
        // Customer should ONLY see services that are active (not draft) and approved.
        if (enhanced.isActive && 
            enhanced.status == ServiceStatus.active && 
            enhanced.approvalStatus == ApprovalStatus.approved) {
          realServices.add(VendorService(
            id: enhanced.id,
            vendorId: enhanced.vendorId,
            name: enhanced.name,
            description: enhanced.description,
            category: enhanced.productCategory,
            subcategory: enhanced.subcategory,
            multiLayerPricing: enhanced.multiLayerPricing,
            basePrice: enhanced.price,
            types: enhanced.serviceTypes,
            images: enhanced.images,
            active: enhanced.isActive,
            status: enhanced.status,
            approvalStatus: enhanced.approvalStatus,
            availability: enhanced.availability,
            options: enhanced.options,
            logistics: enhanced.logistics,
            supportsAppointments: enhanced.supportsAppointments,
            supportsRentals: enhanced.supportsRentals,
            allowedActions: enhanced.allowedActions,
            locations: enhanced.locations,
            venueAddress: enhanced.venueAddress,
            coverageArea: enhanced.coverageArea,
            installmentEnabled: enhanced.installmentEnabled,
            depositPercentage: enhanced.depositPercentage,
            maxInstallments: enhanced.maxInstallments,
            paymentDeadlineDays: enhanced.paymentDeadlineDays,
            videoUrl: enhanced.videoUrl,
          ));
        }
      }

      // 3. Get vendor details to find email and userId
      final vendor = await vendorProvider.fetchVendorById(widget.vendorId);
      if (vendor != null && mounted) {
        setState(() {
          _vendorEmail = vendor.email ?? vendor.contactInfo['email'];
          if (vendor.portfolio != null && vendor.portfolio!.isNotEmpty) {
            _portfolioImages = vendor.portfolio!;
          } else {
             _portfolioImages = [];
          }
          _serviceAreas = vendor.serviceAreas;
        });
      }
      
      if ((_vendorEmail == null || _vendorEmail!.isEmpty) && realServices.isNotEmpty) {
        _vendorEmail = realServices.first.getVendorEmail();
      }

      if (mounted) {
        setState(() {
          _vendorServices = realServices;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error loading customer-side vendor services: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = ResponsiveUtils.isWide(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: isWide ? _buildDesktopAppBar() : _buildMobileAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveWrapper(
              padding: EdgeInsets.zero,
              child: isWide ? _buildWideLayout() : _buildMobileLayout(),
            ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        widget.vendorName,
        style: const TextStyle(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: _buildAppBarActions(),
    );
  }

  PreferredSizeWidget _buildDesktopAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Text(
        widget.vendorName,
        style: const TextStyle(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        ..._buildAppBarActions(),
        const SizedBox(width: 16),
      ],
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          final isFavorited = favoritesProvider.isFavorited(widget.vendorId);
          return IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.red : AppTheme.textSecondaryColor,
            ),
            onPressed: () {
              favoritesProvider.toggleFavorite(widget.vendorId, FavoriteType.vendor);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorited ? 'Removed vendor from favorites' : 'Added vendor to favorites'
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Add to favorites',
          );
        },
      ),
      Consumer2<ChatProvider, VendorProvider>(
        builder: (context, chatProvider, vendorProvider, child) {
          final vendor = vendorProvider.getVendorById(widget.vendorId);
          final resolvedVendorId = vendor?.userId ?? widget.vendorId;
          final conversation = chatProvider.getConversationWithVendor(resolvedVendorId);
          final unreadCount = conversation?.unreadCount ?? 0;

          return IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.chat, color: AppTheme.textSecondaryColor),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openChatWithVendor,
            tooltip: 'Chat with vendor',
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.share, color: AppTheme.textSecondaryColor),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Share functionality coming soon!')),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.info_outline, color: AppTheme.textSecondaryColor),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VendorInfoScreen(vendorId: widget.vendorId),
            ),
          );
        },
        tooltip: 'Vendor Info',
      ),
    ];
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildVendorHeader(),
          ),
          const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'Services'),
              Tab(text: 'Portfolio'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildServicesTab(),
                _buildPortfolioTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return DefaultTabController(
      length: 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            _buildVendorHeaderWide(),
            const SizedBox(height: 32),
            const TabBar(
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              dividerColor: Colors.transparent,
              labelPadding: EdgeInsets.symmetric(horizontal: 48),
              isScrollable: true,
              tabs: [
                Tab(text: 'Services'),
                Tab(text: 'Portfolio'),
              ],
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 600,
                maxHeight: MediaQuery.of(context).size.height * 1.5,
              ),
              child: TabBarView(
                children: [
                  _buildServicesTabGrid(),
                  _buildPortfolioTab(),
                ],
              ),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 64),
              const AppFooter(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVendorHeaderWide() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: widget.vendorImage != null && widget.vendorImage!.isNotEmpty
                  ? Image.network(widget.vendorImage!, fit: BoxFit.cover)
                  : Icon(Icons.store, size: 60, color: AppTheme.primaryColor.withOpacity(0.5)),
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.vendorName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        widget.vendorCategory,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.vendorDescription != null)
                  Text(
                    widget.vendorDescription!,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor.withOpacity(0.8),
                      height: 1.6,
                    ),
                  ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatItemWide('Services', _vendorServices.length.toString(), Icons.layers_outlined),
                      const SizedBox(width: 40),
                      _buildStatItemWide('Rating', '4.8 (120+)', Icons.star_rounded),
                      const SizedBox(width: 40),
                      _buildStatItemWide('Location', 'Kuala Lumpur', Icons.location_on_outlined),
                      if (_vendorEmail != null) ...[
                        const SizedBox(width: 40),
                        _buildStatItemWide('Contact', _vendorEmail!, Icons.email_outlined),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemWide(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor.withOpacity(0.6)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildServicesTabGrid() {
    if (_vendorServices.isEmpty) return _buildEmptyState();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
        final double childAspectRatio = constraints.maxWidth > 1200 ? 0.85 : (constraints.maxWidth > 800 ? 0.8 : 0.75);
        
        return GridView.builder(
          padding: const EdgeInsets.all(0),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _vendorServices.length,
          itemBuilder: (context, index) => _buildServiceCard(_vendorServices[index]),
        );
      }
    );
  }

  Widget _buildServicesTab() {
    if (_vendorServices.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vendorServices.length,
      itemBuilder: (context, index) {
        final service = _vendorServices[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildServiceCard(service),
        );
      },
    );
  }

  Widget _buildPortfolioTab() {
     if (_portfolioImages.isEmpty) {
       return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No portfolio items yet',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 16),
              ),
            ],
          ),
       );
     }
     
     return LayoutBuilder(
       builder: (context, constraints) {
         final int crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
         return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: _portfolioImages.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _portfolioImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _showFullScreenImage(index);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
       }
     );
  }

  void _showFullScreenImage(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.9,
              child: PageView.builder(
                controller: PageController(initialPage: index),
                itemCount: _portfolioImages.length,
                itemBuilder: (context, i) {
                  return InteractiveViewer(
                    child: Image.network(
                      _portfolioImages[i],
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor Image and Basic Info
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: widget.vendorImage != null && widget.vendorImage!.isNotEmpty
                      ? Image.network(
                          widget.vendorImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.store,
                            size: 40,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : Icon(
                          Icons.store,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vendorName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.vendorCategory,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (widget.vendorDescription != null && widget.vendorDescription!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              widget.vendorDescription!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.6,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Vendor Stats
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatItem('Services', _vendorServices.length.toString()),
                const SizedBox(width: 24),
                _buildStatItem('Category', widget.vendorCategory),
                const SizedBox(width: 24),
                _buildStatItem('Rating', '4.5 ⭐'),
                const SizedBox(width: 24),
                _buildStatItem(
                  'Service Areas', 
                  _serviceAreas.isEmpty ? 'All Areas' : _serviceAreas.join(', ')
                ),
              ],
            ),
          ),

          if (_vendorEmail != null && _vendorEmail!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Email: $_vendorEmail',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }



  Widget _buildServiceCard(VendorService service) {
    final bool hasVideo = service.videoUrl != null && service.videoUrl!.isNotEmpty;
    final bool hasImage = service.images.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(vendorService: service),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Media Banner ──────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  // Show video player when video-only, else image
                  if (hasVideo && !hasImage)
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: ServiceVideoPlayer(videoUrl: service.videoUrl!),
                    )
                  else if (hasImage)
                    Image.network(
                      service.images.first,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _mediaBannerPlaceholder(
                        hasVideo ? Icons.videocam : _getCategoryIcon(service.category?.id ?? 'default'),
                      ),
                    )
                  else
                    _mediaBannerPlaceholder(_getCategoryIcon(service.category?.id ?? 'default')),

                  // Play badge overlay (when has image + video)
                  if (hasVideo && hasImage)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_fill, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Video', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),

                  // Price badge
                  Positioned(
                    bottom: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'from RM ${service.getMinPrice().toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Favourite button
                  if (service.id != null)
                    Positioned(
                      top: 8, left: 8,
                      child: Consumer<FavoritesProvider>(
                        builder: (ctx, favProv, _) {
                          final isFav = favProv.isFavorited(service.id!);
                          return GestureDetector(
                            onTap: () {
                              favProv.toggleFavorite(service.id!, FavoriteType.service);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(isFav ? 'Removed from favorites' : 'Added to favorites'),
                                duration: const Duration(seconds: 1),
                              ));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : AppTheme.textSecondaryColor,
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // ── Info Section ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.description,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (service.coverageArea != null && service.coverageArea!.isNotEmpty ||
                      service.venueAddress != null && service.venueAddress!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            service.coverageArea ?? service.venueAddress ?? '',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (service.category != null)
                        _buildFeatureBadge(service.category!.displayName, AppTheme.primaryColor, null),
                      if (service.supportsRentals == true)
                        _buildFeatureBadge('Rentals', AppTheme.secondaryColor, Icons.inventory),
                      if (service.supportsAppointments == true)
                        _buildFeatureBadge('Appts', AppTheme.accentColor, Icons.schedule),
                      if (service.installmentEnabled == true)
                        _buildFeatureBadge('Installments', Colors.green, Icons.payments),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaBannerPlaceholder(IconData icon) {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppTheme.primaryColor.withOpacity(0.08),
      child: Center(
        child: Icon(icon, size: 56, color: AppTheme.primaryColor.withOpacity(0.4)),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Services Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.vendorName} hasn\'t added any services yet.',
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

  Future<void> _openChatWithVendor() async {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    // Be robust: always try to get the latest vendor data to ensure we have the userId
    final vendor = await vendorProvider.fetchVendorById(widget.vendorId);
    
    if (_vendorEmail == null || _vendorEmail!.isEmpty) {
      if (vendor != null) {
        _vendorEmail = vendor.email ?? vendor.contactInfo['email'];
      }
    }

    if (_vendorEmail == null || _vendorEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor contact information not available')),
      );
      return;
    }

    final vendorPhone = vendor?.phone ?? vendor?.contactInfo['phone'] ?? '+1234567890';
    final resolvedVendorId = vendor?.userId;

    if (resolvedVendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resolve vendor chat ID. Please try again.')),
      );
      return;
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to chat with vendors')));
       return;
    }

    final vendorEmail = _vendorEmail ?? _vendorServices.firstWhere((s) => s.getVendorEmail() != null, orElse: () => _vendorServices.first).getVendorEmail() ?? 'info@vendor.com';
    final vendorAvatar = widget.vendorName.isNotEmpty ? widget.vendorName.substring(0, 1).toUpperCase() : 'V';

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final conversation = chatProvider.createConversation(
      vendorId: resolvedVendorId,
      vendorName: widget.vendorName,
      vendorEmail: vendorEmail,
      vendorPhone: vendorPhone,
      vendorAvatar: vendorAvatar,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerChatScreen(conversation: conversation),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'catering':
        return Icons.restaurant;
      case 'photography':
        return Icons.camera_alt;
      case 'venue':
        return Icons.location_on;
      case 'decoration':
        return Icons.celebration;
      case 'entertainment':
        return Icons.music_note;
      case 'transportation':
        return Icons.directions_car;
      case 'beauty':
        return Icons.face;
      case 'equipment':
        return Icons.settings;
      case 'planning':
        return Icons.event_note;
      case 'accommodation':
        return Icons.hotel;
      default:
        return Icons.store;
    }
  }

  Widget _buildFeatureBadge(String label, Color color, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
