import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/app_state.dart';
import '../../models/app_notification.dart';
import '../announcements/announcement_details_screen.dart';
import '../ward_admin/completed_work_details_screen.dart';
import 'my_ward_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;
    final notifications = appState.notifications;
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          isTelugu ? 'నోటిఫికేషన్లు' : 'Notifications',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () => appState.markAllNotificationsAsRead(),
              icon: const Icon(Icons.done_all, color: Colors.white70, size: 18),
              label: const Text('Mark all read', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmpty(isTelugu)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, i) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                return _buildTile(context, notifications[index], appState, isTelugu);
              },
            ),
    );
  }

  Widget _buildEmpty(bool isTelugu) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isTelugu ? 'నోటిఫికేషన్లు లేవు' : 'No notifications',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isTelugu ? 'కొత్త నోటిఫికేషన్లు ఇక్కడ కనిపిస్తాయి.' : 'New notifications will appear here.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, AppNotification notif, AppState appState, bool isTelugu) {
    final config = _tileConfig(notif.effectiveType);
    final timeStr = DateFormat('MMM d, h:mm a').format(notif.createdAt.toLocal());

    return Material(
      color: notif.isRead ? Colors.white : const Color(0xFFEFF6FF),
      child: InkWell(
        onTap: () => _onTap(context, notif, appState),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: config.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(config.icon, color: config.color, size: 22),
                  ),
                  if (!notif.isRead)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red.shade500,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // ── Content ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                              color: const Color(0xFF1A237E),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: config.bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        config.label,
                        style: TextStyle(fontSize: 10, color: config.color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, AppNotification notif, AppState appState) async {
    // Mark as read optimistically
    appState.markNotificationAsRead(notif.id);

    if (notif.isAnnouncementNotification) {
      // Open announcement details directly
      final announcementId = notif.announcementId ?? notif.complaintId;
      if (announcementId != null && announcementId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailsScreen(
              announcementId: announcementId,
              notificationId: notif.id,
            ),
          ),
        );
      }
    } else if (notif.effectiveType == 'completed_work') {
      final workId = notif.referenceId ?? notif.complaintId;
      final cw = appState.completedWorks.firstWhere((w) => w.id == workId, orElse: () => throw Exception('Not found'));
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CompletedWorkDetailsScreen(work: cw, notificationId: notif.id),
      ));
    } else if (notif.effectiveType == 'ward_update' || notif.effectiveType == 'work_update') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => MyWardScreen(initialUpdateId: notif.complaintId),
      ));
    } else if (notif.effectiveType == 'complaint_status' || notif.effectiveType == 'complaint_resolved') {
      Navigator.pop(context);
      appState.setHighlightedComplaintId(notif.complaintId);
      appState.setCitizenTabIndex(3);
    } else {
      Navigator.pop(context);
    }
  }

  _TileConfig _tileConfig(String type) {
    switch (type) {
      case 'announcement':
      case 'broadcast':
        return _TileConfig(
          icon: Icons.campaign,
          color: const Color(0xFFE65100),
          bgColor: const Color(0xFFFFF3E0),
          label: 'Announcement',
        );
      case 'ward_update':
      case 'work_update':
        return _TileConfig(
          icon: Icons.assignment_turned_in,
          color: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
          label: 'Ward Update',
        );
      case 'completed_work':
        return _TileConfig(
          icon: Icons.check_circle,
          color: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
          label: 'Completed Work',
        );
      case 'complaint_status':
      case 'complaint_resolved':
        return _TileConfig(
          icon: Icons.task_alt,
          color: const Color(0xFF1565C0),
          bgColor: const Color(0xFFE3F2FD),
          label: 'Complaint Update',
        );
      default:
        return _TileConfig(
          icon: Icons.notifications,
          color: Colors.grey.shade600,
          bgColor: Colors.grey.shade100,
          label: 'Notification',
        );
    }
  }
}

class _TileConfig {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;
  const _TileConfig({required this.icon, required this.color, required this.bgColor, required this.label});
}
