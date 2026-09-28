import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:eventease/core/services/supabase_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ArticleEditorDialog extends StatefulWidget {
  final AdminProvider admin;
  const ArticleEditorDialog({super.key, required this.admin});

  @override
  State<ArticleEditorDialog> createState() => _ArticleEditorDialogState();
}

class _ArticleEditorDialogState extends State<ArticleEditorDialog> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _authorCtrl = TextEditingController();
  final TextEditingController _linkedVendorIdCtrl = TextEditingController();
  final TextEditingController _linkedVendorNameCtrl = TextEditingController();
  final quill.QuillController _quillController = quill.QuillController.basic();
  
  String? _featuredImageUrl;
  bool _isUploadingImage = false;
  
  String _selectedCategory = "event_guide";
  String _selectedCTA = "none";

  final List<Map<String, String>> categories = [
    {"val": "event_guide", "label": "📘 Event Guide"},
    {"val": "vendor_tips", "label": "💡 Vendor Tips"},
    {"val": "budgeting", "label": "💰 Budgeting"},
    {"val": "general", "label": "📰 General"},
  ];

  final List<Map<String, String>> ctaTypes = [
    {"val": "none", "label": "No CTA"},
    {"val": "book_vendor", "label": "📅 Book Vendor"},
    {"val": "view_package", "label": "📦 View Package"},
    {"val": "get_quote", "label": "💬 Get Quote"},
  ];

  @override
  void initState() {
    super.initState();
    _authorCtrl.text = "Admin";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("📝 Article Editor"),
      content: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          children: [
            if (_isUploadingImage)
              const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured Image Picker
                GestureDetector(
                  onTap: _pickFeaturedImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      image: _featuredImageUrl != null
                          ? DecorationImage(image: NetworkImage(_featuredImageUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _featuredImageUrl == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey),
                              SizedBox(height: 4),
                              Text("Featured", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _titleCtrl,
                              decoration: const InputDecoration(
                                labelText: "Article Title *",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _authorCtrl,
                              decoration: const InputDecoration(
                                labelText: "Author",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              items: categories.map((c) => DropdownMenuItem(value: c['val'], child: Text(c['label']!))).toList(),
                              onChanged: (val) => setState(() => _selectedCategory = val!),
                              decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCTA,
                              items: ctaTypes.map((c) => DropdownMenuItem(value: c['val'], child: Text(c['label']!))).toList(),
                              onChanged: (val) => setState(() => _selectedCTA = val!),
                              decoration: const InputDecoration(labelText: "Call to Action", border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_selectedCTA != "none") ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _linkedVendorNameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Target Vendor Name",
                        hintText: "e.g. Dream Photography",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _linkedVendorIdCtrl,
                      decoration: const InputDecoration(
                        labelText: "Target ID (Vendor/Package UUID)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Rich Text Editor
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: quill.QuillSimpleToolbar(
                          controller: _quillController,
                          config: const quill.QuillSimpleToolbarConfig(
                            showLink: true,
                            showSearchButton: true,
                            showSmallButton: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
                        tooltip: "Insert Image",
                        onPressed: _insertImageIntoContent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: quill.QuillEditor.basic(
                        controller: _quillController,
                        config: const quill.QuillEditorConfig(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        OutlinedButton(onPressed: () => _showPreview(context), child: const Text("Preview")),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () => _saveArticle(status: 'draft'),
          child: const Text("Save Draft"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () => _saveArticle(status: 'published'),
          child: const Text("Publish Now"),
        ),
      ],
    );
  }

  Future<void> _saveArticle({required String status}) async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required")));
      return;
    }

    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());
    
    try {
      await widget.admin.addArticle(Article(
        id: '',
        title: _titleCtrl.text,
        author: _authorCtrl.text,
        content: contentJson,
        status: status,
        category: _selectedCategory,
        ctaType: _selectedCTA,
        linkedVendorId: _linkedVendorIdCtrl.text.isNotEmpty ? _linkedVendorIdCtrl.text : null,
        linkedVendorName: _linkedVendorNameCtrl.text.isNotEmpty ? _linkedVendorNameCtrl.text : null,
        featuredImage: _featuredImageUrl,
        views: 0,
      ));
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'published' ? "Article published!" : "Draft saved."),
            backgroundColor: status == 'published' ? Colors.green : Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _pickFeaturedImage() async {
    final picker = img_picker.ImagePicker();
    final image = await picker.pickImage(source: img_picker.ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isUploadingImage = true);
      try {
        final bytes = await image.readAsBytes();
        final ext = image.name.split('.').last;
        final fileName = 'featured_${const Uuid().v4()}.$ext';
        
        await SupabaseService.uploadFile(
          bucket: 'articles',
          path: fileName,
          fileBytes: bytes,
        );
        
        final url = SupabaseService.getPublicUrl(bucket: 'articles', path: fileName);
        setState(() {
          _featuredImageUrl = url;
          _isUploadingImage = false;
        });
      } catch (e) {
        setState(() => _isUploadingImage = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
        }
      }
    }
  }

  Future<void> _insertImageIntoContent() async {
    final picker = img_picker.ImagePicker();
    final image = await picker.pickImage(source: img_picker.ImageSource.gallery);
    
    if (image != null) {
      final url = await _uploadImage(File(image.path));
      if (url != null) {
        final index = _quillController.selection.baseOffset;
        _quillController.document.insert(index, quill.BlockEmbed.image(url));
        // Move cursor after the image
        _quillController.updateSelection(
          TextSelection.collapsed(offset: index + 1),
          quill.ChangeSource.local,
        );
      }
    }
  }

  Future<String?> _uploadImage(File file) async {
    setState(() => _isUploadingImage = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last;
      final fileName = 'content_${const Uuid().v4()}.$ext';
      
      await SupabaseService.uploadFile(
        bucket: 'articles',
        path: fileName,
        fileBytes: bytes,
      );
      
      final url = SupabaseService.getPublicUrl(bucket: 'articles', path: fileName);
      setState(() => _isUploadingImage = false);
      return url;
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
      }
      return null;
    }
  }

  void _showPreview(BuildContext context) {
    final previewDoc = _quillController.document.toDelta();
    final previewEditor = quill.QuillController(
      document: quill.Document.fromDelta(previewDoc),
      selection: const TextSelection.collapsed(offset: 0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Preview: ${_titleCtrl.text}"),
        content: SizedBox(
          width: 800,
          height: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(label: Text(_selectedCategory.toUpperCase())),
                  if (_selectedCTA != "none") ...[
                    const SizedBox(width: 8),
                    Chip(label: Text("CTA: $_selectedCTA"), backgroundColor: Colors.blue.shade50),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: quill.QuillEditor.basic(
                    controller: previewEditor,
                    config: const quill.QuillEditorConfig(
                      showCursor: false,
                      enableInteractiveSelection: false,
                      enableSelectionToolbar: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Back to Editor")),
        ],
      ),
    );
  }
}
