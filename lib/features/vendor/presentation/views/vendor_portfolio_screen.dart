import 'dart:io';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';

class VendorPortfolioScreen extends StatefulWidget {
  final String vendorId;

  const VendorPortfolioScreen({super.key, required this.vendorId});

  @override
  State<VendorPortfolioScreen> createState() => _VendorPortfolioScreenState();
}

class _VendorPortfolioScreenState extends State<VendorPortfolioScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, provider, child) {
        final vendor = provider.currentVendor;
        // Should verify we have a vendor, otherwise show loading or error
        if (vendor == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final portfolioImages = vendor.portfolio ?? [];

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Portfolio Gallery'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate),
                onPressed: _isUploading ? null : _addItem,
              ),
            ],
          ),
          body: Stack(
            children: [
              portfolioImages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No items in portfolio',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Add your first image'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: portfolioImages.length,
                      itemBuilder: (context, index) {
                        return _buildPortfolioCard(portfolioImages[index], provider);
                      },
                    ),
              if (_isUploading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortfolioCard(String imageUrl, VendorProvider provider) {
    return Container(
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
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                    onPressed: () => _deleteItem(imageUrl, provider),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Future<void> _addItem() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      
      setState(() => _isUploading = true);
      
      if (!mounted) return;
      final provider = Provider.of<VendorProvider>(context, listen: false);
      
      final bytes = await image.readAsBytes();
      final url = await provider.uploadPortfolioImage(bytes: bytes, fileName: image.name);
      
      if (url != null) {
          final currentPortfolio = List<String>.from(provider.currentVendor?.portfolio ?? []);
          currentPortfolio.add(url);
          await provider.updateVendorPortfolio(currentPortfolio);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image added successfully')),
            );
          }
      } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image')),
            );
         }
      }
    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
        }
    } finally {
        if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteItem(String imageUrl, VendorProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to remove this image from your portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUploading = true);
      try {
        final currentPortfolio = List<String>.from(provider.currentVendor?.portfolio ?? []);
        currentPortfolio.remove(imageUrl);
        await provider.updateVendorPortfolio(currentPortfolio);
        
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image removed')),
            );
        }
      } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting image: $e')),
            );
         }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }
}
