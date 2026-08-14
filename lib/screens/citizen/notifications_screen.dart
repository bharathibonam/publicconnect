import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/app_state.dart';
import '../../models/app_notification.dart';
import '../../models/user.dart';
import '../../models/complaint.dart';
import '../../services/supabase_service.dart';
import '../../widgets/shared_officer_widgets.dart';
import '../announcements/announcement_details_screen.dart';
import '../ward_admin/completed_work_details_screen.dart';
import 'my_ward_screen.dart';
import '../super_admin/meetings/meeting_details_screen.dart';
import '../../../themes/theme_provider.dart';
import 'track_complaints.dart';

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

  Future<void> _fetchAndShowComplaint(BuildContext context, String complaintId, AppState appState, bool isTelugu) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingCtx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(isTelugu ? 'ఫిర్యాదును లోడ్ చేస్తోంది...' : 'Loading complaint...'),
          ],
        ),
      ),
    );

    bool success = false;
    while (!success) {
      try {
        var comp = appState.complaints.firstWhere(
          (c) => c.id == complaintId,
          orElse: () => throw Exception('Not found locally'),
        );
        
        if (context.mounted) {
          Navigator.pop(context); // Pop loading dialog
          ComplaintDetailsModal.show(context, comp, isTelugu);
        }
        success = true;
      } catch (e) {
        try {
          final compMap = await SupabaseService.getComplaintById(complaintId);
          if (compMap != null) {
            final comp = Complaint.fromMap(compMap);
            if (context.mounted) {
              Navigator.pop(context); // Pop loading dialog
              ComplaintDetailsModal.show(context, comp, isTelugu);
            }
            success = true;
          } else {
            throw Exception('Complaint not found in database');
          }
        } catch (dbError) {
          if (context.mounted) {
            Navigator.pop(context); // Pop loading dialog
          }
          
          bool retry = false;
          if (context.mounted) {
            retry = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (errorCtx) => AlertDialog(
                title: Text(isTelugu ? 'లోపం' : 'Error'),
                content: Text(isTelugu ? 'ఫిర్యాదును లోడ్ చేయడం సాధ్యం కాలేదు.' : 'Unable to load complaint.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(errorCtx, false),
                    child: Text(isTelugu ? 'రద్దు చేయి' : 'Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(errorCtx, true),
                    child: Text(isTelugu ? 'మళ్ళీ ప్రయత్నించు' : 'Retry'),
                  ),
                ],
              ),
            ) ?? false;
          }
          
          if (!retry) {
            break;
          }
          
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (loadingCtx) => AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 20),
                    Text(isTelugu ? 'ఫిర్యాదును లోడ్ చేస్తోంది...' : 'Loading complaint...'),
                  ],
                ),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _onTap(BuildContext context, AppNotification notif, AppState appState) async {
    appState.markNotificationAsRead(notif.id);
    final isTelugu = appState.isTelugu;

    if (notif.isAnnouncementNotification) {
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
      if (notif.complaintId != null && notif.complaintId!.isNotEmpty) {
        appState.setHighlightedComplaintId(notif.complaintId);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrackComplaintsScreen()),
        );
      } else {
        Navigator.pop(context);
      }
    } else if (notif.effectiveType == 'complaint') {
      final complaintId = notif.referenceId ?? notif.complaintId;
      if (complaintId != null && complaintId.isNotEmpty) {
        _fetchAndShowComplaint(context, complaintId, appState, isTelugu);
      } else {
        Navigator.pop(context);
      }
    } else if (notif.effectiveType == 'meeting') {
      final meetingId = notif.referenceId ?? notif.complaintId;
      if (meetingId != null) {
        try {
          final meeting = appState.meetings.firstWhere((m) => m.id == meetingId);
          final themeConfig = Provider.of<ThemeProvider>(context, listen: false).activeParty;
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => MeetingDetailsScreen(meeting: meeting, themeConfig: themeConfig),
          ));
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting not found or has been deleted.')));
          }
        }
      }
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
      case 'meeting':
        return _TileConfig(
          icon: Icons.groups,
          color: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF3E8FF),
          label: 'Meeting',
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
