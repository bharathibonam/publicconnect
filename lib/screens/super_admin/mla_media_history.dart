import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/app_state.dart';
import '../../models/mla_broadcast.dart';
import '../../themes/theme_provider.dart';
import 'mla_media_publisher.dart';

class MLAMediaHistoryScreen extends StatefulWidget {
  const MLAMediaHistoryScreen({super.key});

  @override
  State<MLAMediaHistoryScreen> createState() => _MLAMediaHistoryScreenState();
}

class _MLAMediaHistoryScreenState extends State<MLAMediaHistoryScreen> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    
    // Sort broadcasts: scheduled and published together, ordered by created_at DESC
    final broadcasts = appState.mlaBroadcasts.where((b) {
      if (_statusFilter == 'All') return true;
      return b.status.toLowerCase() == _statusFilter.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Media Broadcast History', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_photos_outlined, color: Color(0xFF0F172A)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MLAMediaPublisher()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal Status Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Published', 'Scheduled', 'Draft', 'Failed'].map((status) {
                  final isSelected = _statusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      selectedColor: themeConfig.primaryColor.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? themeConfig.primaryColor : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _statusFilter = status;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          Expanded(
            child: broadcasts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No media found matching filter', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: broadcasts.length,
                    itemBuilder: (context, index) {
                      final item = broadcasts[index];
                      return _buildBroadcastHistoryCard(context, item, themeConfig.primaryColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastHistoryCard(BuildContext context, MLABroadcast item, Color primaryColor) {
    final appState = Provider.of<AppState>(context, listen: false);
    final DateFormat formatter = DateFormat('dd MMM yyyy, hh:mm a');
    
    // Status color
    Color statusBgColor = Colors.green.shade50;
    Color statusTextColor = Colors.green;
    if (item.status == 'scheduled') {
      statusBgColor = Colors.blue.shade50;
      statusTextColor = Colors.blue;
    } else if (item.status == 'draft') {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange;
    } else if (item.status == 'failed') {
      statusBgColor = Colors.red.shade50;
      statusTextColor = Colors.red;
    }

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                color: primaryColor.withOpacity(0.05),
                child: item.type == BroadcastMediaType.photo
                    ? (item.photoUrl != null && item.photoUrl!.startsWith('http')
                        ? Image.network(item.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image, color: primaryColor))
                        : Icon(Icons.image, color: primaryColor, size: 28))
                    : item.type == BroadcastMediaType.reel
                        ? Icon(Icons.play_circle_fill, color: primaryColor, size: 32)
                        : Icon(Icons.description, color: primaryColor, size: 28),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(item.createdBy, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      formatter.format(item.createdAt),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
                if (item.status == 'scheduled' && item.scheduledAt != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        'Scheduled: ${formatter.format(item.scheduledAt!)}',
                        style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Action Buttons: Edit, Delete & Social Syndications Bar
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Views, Likes, Shares Metrics
                Row(
                  children: [
                    _metricChip(Icons.visibility_outlined, item.views.toString()),
                    const SizedBox(width: 8),
                    _metricChip(Icons.favorite_border, item.likes.toString()),
                    const SizedBox(width: 8),
                    _metricChip(Icons.share_outlined, item.shares.toString()),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(foregroundColor: primaryColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MLAMediaPublisher(broadcastToEdit: item),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm Deletion'),
                            content: const Text('Are you sure you want to permanently delete this broadcast? It will be removed from all storage, database caches, and citizen feeds instantly.'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await appState.deleteMLABroadcast(item);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Broadcast deleted successfully')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(IconData icon, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(count, style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
