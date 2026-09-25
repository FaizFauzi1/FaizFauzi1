import 'package:flutter/material.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';

/// Post-event photo/video delivery portal for photography vendors.
class PhotoDeliveryPortalScreen extends StatelessWidget {
  const PhotoDeliveryPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deliverables')),
      body: ListView(
        padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
        children: [
          _statusCard('Delivery Status', 'In Progress', AppTheme.warningColor, 0.65),
          const SizedBox(height: 16),
          const Text('Albums', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
          _albumTile('Ceremony Highlights', 48, true),
          _albumTile('Reception Gallery', 120, false),
          _albumTile('Raw Footage', 0, false, isVideo: true),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.rate_review),
            label: const Text('Leave Review Before Download'),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(String title, String status, Color color, double progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: EEDesignTokens.titleLarge),
                Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, color: color),
            const SizedBox(height: 4),
            Text('Deadline: 14 days after event', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _albumTile(String name, int count, bool ready, {bool isVideo = false}) {
    return ListTile(
      leading: Icon(isVideo ? Icons.videocam : Icons.photo_album),
      title: Text(name),
      subtitle: Text(ready ? '$count files ready' : 'Processing...'),
      trailing: ready
          ? IconButton(icon: const Icon(Icons.download), onPressed: () {})
          : const SizedBox(width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
