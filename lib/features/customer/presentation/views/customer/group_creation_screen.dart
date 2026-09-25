import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/chat/data/models/chat_message.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/customer/presentation/views/customer/chat_screen.dart';
import 'package:provider/provider.dart';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({super.key});

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _selectedVendors = [];
  String _searchQuery = '';

  // Get available vendors from recent chat conversations
  List<Map<String, String>> get _availableVendors {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chatConversations = chatProvider.conversations.whereType<ChatConversation>().toList();

    // Sort by lastMessageTime descending (most recent first)
    chatConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    // Take the most recent conversations (limit to 10 for performance)
    final recentConversations = chatConversations.take(10).toList();

    final vendors = recentConversations.map((conv) => {
      'id': conv.vendorId,
      'name': conv.vendorName,
      'category': 'Recent Chat',
      'avatar': conv.vendorAvatar.isNotEmpty ? conv.vendorAvatar : conv.vendorName.substring(0, 2).toUpperCase(),
    }).toList();

    if (_searchQuery.isEmpty) {
      return vendors;
    }

    return vendors
        .where((vendor) =>
            vendor['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            vendor['category']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  bool get _canCreateGroup =>
      _groupNameController.text.trim().isNotEmpty &&
      _selectedVendors.length >= 2 &&
      _selectedVendors.length <= 3;

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleVendorSelection(Map<String, String> vendor) {
    setState(() {
      if (_selectedVendors.any((v) => v['id'] == vendor['id'])) {
        _selectedVendors.removeWhere((v) => v['id'] == vendor['id']);
      } else if (_selectedVendors.length < 3) {
        _selectedVendors.add(vendor);
      }
    });
  }

  void _createGroup() {
    if (!_canCreateGroup) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final groupName = _groupNameController.text.trim();

    final groupConversation = chatProvider.createGroupChat(
      groupName: groupName,
      selectedVendors: _selectedVendors,
    );

    Navigator.pop(context); // Close group creation screen

    // Navigate to the newly created group chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerChatScreen(conversation: groupConversation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Create Group Chat',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _canCreateGroup ? _createGroup : null,
            child: Text(
              'Create',
              style: TextStyle(
                color: _canCreateGroup ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group name input
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.textSecondaryColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.textSecondaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Selected vendors count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Selected Vendors (${_selectedVendors.length}/3)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                if (_selectedVendors.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selectedVendors.clear()),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
              ],
            ),
          ),

          // Selected vendors chips
          if (_selectedVendors.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedVendors.length,
                itemBuilder: (context, index) {
                  final vendor = _selectedVendors[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vendor['name']!,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _toggleVendorSelection(vendor),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.textSecondaryColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.textSecondaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Vendors list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _availableVendors.length,
              itemBuilder: (context, index) {
                final vendor = _availableVendors[index];
                final isSelected = _selectedVendors.any((v) => v['id'] == vendor['id']);
                final isDisabled = !isSelected && _selectedVendors.length >= 3;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          vendor['avatar']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      vendor['name']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? AppTheme.textSecondaryColor
                            : AppTheme.textPrimaryColor,
                      ),
                    ),
                    subtitle: Text(
                      vendor['category']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                        : isDisabled
                            ? Icon(Icons.radio_button_unchecked, color: AppTheme.textSecondaryColor.withOpacity(0.3))
                            : const Icon(Icons.radio_button_unchecked, color: AppTheme.textSecondaryColor),
                    onTap: isDisabled && !isSelected ? null : () => _toggleVendorSelection(vendor),
                  ),
                );
              },
            ),
          ),

          // Info text
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select 2-3 vendors to create a group chat for coordinating your event.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
