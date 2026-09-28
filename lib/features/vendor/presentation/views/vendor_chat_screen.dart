import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/chat/data/models/chat_message.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/vendor/presentation/views/v_chat_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/vendor_responsive_scaffold.dart';

class VendorChatScreen extends StatefulWidget {
  final bool embeddedInDashboard;

  const VendorChatScreen({super.key, this.embeddedInDashboard = false});

  @override
  State<VendorChatScreen> createState() => _VendorChatScreenState();
}

class _VendorChatScreenState extends State<VendorChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  ChatConversation? _selectedConversation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadConversationsFromSupabase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VendorResponsiveScaffold(
      title: 'Customer Messages',
      embedded: widget.embeddedInDashboard,
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final conversations = chatProvider.conversations.whereType<ChatConversation>().toList();
          final query = _searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? conversations
              : conversations.where((c) {
                  final last = c.messages.isNotEmpty ? c.messages.last.message : '';
                  return c.customerName.toLowerCase().contains(query) ||
                      c.vendorName.toLowerCase().contains(query) ||
                      last.toLowerCase().contains(query);
                }).toList();

          if (conversations.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 800;
              final listWidget = Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search customers...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),

                  // Conversations list
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No matching conversations'))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              return _buildConversationTile(filtered[index], isWideScreen);
                            },
                          ),
                  ),
                ],
              );

              if (isWideScreen) {
                return Row(
                  children: [
                    SizedBox(
                      width: 350,
                      child: listWidget,
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      child: _selectedConversation != null
                          ? VChatDetailScreen(
                              key: ValueKey(_selectedConversation!.id),
                              conversation: _selectedConversation!,
                            )
                          : const Center(
                              child: Text(
                                'Select a conversation to start chatting',
                                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 16),
                              ),
                            ),
                    ),
                  ],
                );
              }

              return listWidget;
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation, bool isWideScreen) {
    final isSelected = _selectedConversation?.id == conversation.id;
    return ListTile(
      selected: isWideScreen && isSelected,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.05),
      onTap: () {
        if (isWideScreen) {
          setState(() {
            _selectedConversation = conversation;
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VChatDetailScreen(conversation: conversation),
            ),
          );
        }
      },
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Text(
          conversation.vendorAvatar,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.vendorName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          if (conversation.isOnline)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(conversation.lastMessageTime),
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessageText,
              style: TextStyle(
                color: conversation.unreadCount > 0
                    ? AppTheme.textPrimaryColor
                    : AppTheme.textSecondaryColor,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return days[timestamp.weekday % 7];
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
