import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/guest/data/providers/guest_provider.dart';
import 'package:eventease/shared/models/photo_album.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class PhotoSharingScreen extends StatefulWidget {
  final Event event;
  final List<PhotoAlbum> photoAlbums;

  const PhotoSharingScreen({
    super.key,
    required this.event,
    required this.photoAlbums,
  });

  @override
  State<PhotoSharingScreen> createState() => _PhotoSharingScreenState();
}

class _PhotoSharingScreenState extends State<PhotoSharingScreen> {
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploading = false;
  String? _selectedAlbumId;

  @override
  void initState() {
    super.initState();
    if (widget.photoAlbums.isNotEmpty) {
      _selectedAlbumId = widget.photoAlbums.first.id;
    }
    
    // Load fresh data from Supabase and auto-create album if needed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<GuestProvider>(context, listen: false);
      await provider.loadPhotoAlbumsForEvent(widget.event.id);
      
      // If still no albums after load, create a default one
      if (mounted) {
        final currentAlbums = provider.photoAlbums.where((a) => a.eventId == widget.event.id).toList();
        if (currentAlbums.isEmpty) {
          final newAlbum = PhotoAlbum(
            id: Uuid().v4(),
            eventId: widget.event.id,
            title: 'Event Gallery',
            description: 'Share your favorite moments from ${widget.event.title}!',
            photos: [],
            allowGuestUploads: true,
            requireApproval: false,
            maxPhotosPerGuest: 20,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await provider.createPhotoAlbum(newAlbum);
          if (mounted) {
            setState(() {
              _selectedAlbumId = newAlbum.id;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GuestProvider>(
      builder: (context, guestProvider, _) {
        final albums = guestProvider.photoAlbums.where((a) => a.eventId == widget.event.id).toList();
        
        // Use albums from provider if available, otherwise fallback to widget.photoAlbums
        final displayAlbums = albums.isNotEmpty ? albums : widget.photoAlbums;
        
        PhotoAlbum? selectedAlbum;
        if (displayAlbums.isNotEmpty) {
          // If we have albums but none selected, select the first one
          if (_selectedAlbumId == null) {
            _selectedAlbumId = displayAlbums.first.id;
          }

          try {
            selectedAlbum = displayAlbums.firstWhere(
              (a) => a.id == _selectedAlbumId,
              orElse: () => displayAlbums.first,
            );
          } catch (e) {
            selectedAlbum = displayAlbums.first;
          }
        }

        final canUpload = _selectedImages.isNotEmpty && selectedAlbum != null && !_isUploading;

        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.event.title} - Photos'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            actions: [
              if (_selectedImages.isNotEmpty)
                TextButton(
                  onPressed: canUpload ? () => _uploadPhotos(selectedAlbum!, guestProvider) : null,
                  child: Text(
                    _isUploading ? 'Uploading...' : 'Upload (${_selectedImages.length})',
                    style: TextStyle(
                      color: canUpload ? Colors.white : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => guestProvider.loadPhotoAlbumsForEvent(widget.event.id),
              ),
            ],
          ),
          body: guestProvider.isLoading && displayAlbums.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Photo Albums Section
                    if (displayAlbums.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey[100],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event Photo Albums',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: displayAlbums.length,
                                itemBuilder: (context, index) {
                                  final album = displayAlbums[index];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedAlbumId = album.id;
                                        _selectedImages.clear(); // Clear selection on album change
                                      });
                                    },
                                    child: _buildAlbumCard(album, isSelected: album.id == _selectedAlbumId),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Main Content Section
                    Expanded(
                      child: _selectedImages.isNotEmpty
                          ? _buildSelectedImagesGrid()
                          : (selectedAlbum != null && selectedAlbum.photos.isNotEmpty
                              ? _buildSharedGallery(selectedAlbum.photos)
                              : _buildEmptyState()),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showImageSourceDialog,
            child: const Icon(Icons.add_a_photo),
            tooltip: 'Add Photos',
          ),
        );
      },
    );
  }

  Widget _buildAlbumCard(PhotoAlbum album, {bool isSelected = false}) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: isSelected ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected 
              ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover
            Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: album.photos.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(album.photos.first.thumbnailUrl ?? album.photos.first.url),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: album.photos.isEmpty ? Colors.grey[300] : null,
              ),
              child: album.photos.isEmpty
                  ? const Icon(Icons.photo_album, size: 32, color: Colors.grey)
                  : null,
            ),

            // Album Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${album.photos.length} photos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No photos selected',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the camera button to add photos to share',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showImageSourceDialog,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Photos'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImagesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        final image = _selectedImages[index];
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSharedGallery(List<Photo> photos) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return GestureDetector(
          onTap: () => _showPhotoViewer(context, photo),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
              image: DecorationImage(
                image: (photo.url.startsWith('http') || photo.url.startsWith('https'))
                    ? NetworkImage(photo.url) as ImageProvider
                    : FileImage(File(photo.url)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPhotoViewer(BuildContext context, Photo photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: (photo.url.startsWith('http') || photo.url.startsWith('https'))
                  ? Image.network(photo.url, fit: BoxFit.contain)
                  : Image.file(File(photo.url), fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Uploaded by ${photo.uploadedBy}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Photos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadPhotos(PhotoAlbum album, GuestProvider provider) async {
    if (_selectedImages.isEmpty) return;

    final guestName = 'Guest User'; // In a real app, get from current auth/guest session

    // Check limits
    if (album.maxPhotosPerGuest != null) {
      final guestPhotosCount = album.photos.where((p) => p.uploadedBy == guestName).length;
      if (guestPhotosCount + _selectedImages.length > album.maxPhotosPerGuest!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Limit exceeded! You can only upload ${album.maxPhotosPerGuest} photos in this album.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isUploading = true;
    });

    try {
      int successCount = 0;
      // Process local files and upload to Supabase
      for (var file in _selectedImages) {
        await provider.uploadPhoto(
          albumId: album.id,
          file: file,
          guestName: guestName,
        );
        successCount++;
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully uploaded $successCount photo(s)!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear selected images
        setState(() {
          _selectedImages.clear();
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
