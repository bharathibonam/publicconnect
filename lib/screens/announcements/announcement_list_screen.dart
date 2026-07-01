import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/app_state.dart';


import 'announcement_details_screen.dart';

class AnnouncementListScreen extends StatelessWidget {
  final String? initialAnnouncementId;
  const AnnouncementListScreen({super.key, this.initialAnnouncementId});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;

    // Get visible announcements for this user
    final announcements = appState.getVisibleAnnouncements();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          isTelugu ? 'ప్రకటనలు' : 'Announcements',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: announcements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    isTelugu ? 'ప్రకటనలు ఏవీ లేవు.' : 'No announcements found.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final a = announcements[index];
                
                // Find corresponding notification to check read status
                final notif = appState.notifications.where(
                  (n) => n.isAnnouncementNotification && n.announcementId == a.id
                ).firstOrNull;

                final isUnread = notif != null && !notif.isRead;
                final isHighlighted = a.id == initialAnnouncementId;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => AnnouncementDetailsScreen(
                        announcement: a,
                        notificationId: notif?.id, // Ensure read status maps backward
                      ),
                    ));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isHighlighted || isUnread ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnread ? const Color(0xFF1565C0).withValues(alpha: 0.5) : (isHighlighted ? const Color(0xFF1565C0) : Colors.transparent),
                        width: isUnread || isHighlighted ? 2 : 0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isHighlighted || isUnread ? 0.08 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.campaign, color: Color(0xFF1565C0), size: 20),
                                    if (isUnread)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.title,
                                      style: TextStyle(
                                        fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold, 
                                        fontSize: 15, 
                                        color: const Color(0xFF1A237E)
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${a.createdByName} · ${a.createdByRole.toUpperCase()}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                notif != null 
                                    ? DateFormat('MMM d, h:mm a').format(notif.createdAt.toLocal())
                                    : DateFormat('MMM d, h:mm a').format(a.createdAt.toLocal()),
                                style: TextStyle(
                                  fontSize: 11, 
                                  color: isUnread ? const Color(0xFF1565C0) : Colors.grey.shade500,
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            a.message,
                            style: TextStyle(
                              fontSize: 14, 
                              height: 1.5, 
                              color: isUnread ? const Color(0xFF0F172A) : const Color(0xFF37474F)
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (a.imageUrl != null || a.voiceUrl != null || a.attachmentUrl != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (a.imageUrl != null) _attachChip(Icons.image_outlined, 'Image'),
                                if (a.voiceUrl != null) ...[const SizedBox(width: 6), _attachChip(Icons.mic, 'Voice')],
                                if (a.attachmentUrl != null) ...[const SizedBox(width: 6), _attachChip(Icons.picture_as_pdf_outlined, 'PDF')],
                              ],
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(isUnread ? 'Tap to read' : 'Tap to view', style: TextStyle(fontSize: 11, color: isUnread ? const Color(0xFF1565C0) : Colors.grey.shade400, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                              Icon(Icons.chevron_right, size: 14, color: isUnread ? const Color(0xFF1565C0) : Colors.grey.shade400),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _attachChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF1565C0)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
