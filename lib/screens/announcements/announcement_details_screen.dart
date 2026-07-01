import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/app_state.dart';
import '../../models/announcement.dart';
import '../../models/announcement_read.dart';
import '../../services/supabase_service.dart';

class AnnouncementDetailsScreen extends StatefulWidget {
  /// Pass either an already-loaded announcement or just its ID.
  final Announcement? announcement;
  final String? announcementId;
  /// Optional: the notification ID to mark as read on open.
  final String? notificationId;

  const AnnouncementDetailsScreen({
    super.key,
    this.announcement,
    this.announcementId,
    this.notificationId,
  }) : assert(announcement != null || announcementId != null,
            'Provide either announcement or announcementId');

  @override
  State<AnnouncementDetailsScreen> createState() =>
      _AnnouncementDetailsScreenState();
}

class _AnnouncementDetailsScreenState
    extends State<AnnouncementDetailsScreen> {
  Announcement? _announcement;
  bool _loading = true;
  bool _markedRead = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.announcement != null) {
      _announcement = widget.announcement;
      setState(() => _loading = false);
    } else {
      final a = await SupabaseService.getAnnouncementById(widget.announcementId!);
      if (mounted) setState(() { _announcement = a; _loading = false; });
    }
    _markRead();
  }

  Future<void> _markRead() async {
    if (_markedRead) return;
    _markedRead = true;

    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    if (user == null) return;

    // Mark the notification as read in Supabase (triggers DB sync to announcement_reads)
    if (widget.notificationId != null) {
      await appState.markNotificationAsRead(widget.notificationId!);
    }

    // Also upsert into announcement_reads directly for read receipt tracking
    if (_announcement != null) {
      final read = AnnouncementRead(
        id: 'read_${_announcement!.id}_${user.id}',
        announcementId: _announcement!.id,
        userId: user.id,
        readAt: DateTime.now(),
      );
      if (appState.isSupabaseConnected) {
        await SupabaseService.markAnnouncementAsRead(read);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _roleBadgeLabel(String role) {
    switch (role) {
      case 'superAdmin':   return 'MLA';
      case 'mandalOfficer': return 'Mandal Officer';
      case 'categoryOfficer': return 'Category Officer';
      case 'wardAdmin':    return 'Ward Member';
      case 'citizen':      return 'Citizen';
      default:             return role;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'superAdmin':    return const Color(0xFF1565C0);
      case 'mandalOfficer': return const Color(0xFF2E7D32);
      case 'categoryOfficer': return const Color(0xFF6A1B9A);
      case 'wardAdmin':     return const Color(0xFF4527A0);
      default:              return const Color(0xFF37474F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Announcement Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _announcement == null
              ? _buildNotFound()
              : _buildContent(theme),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.announcement_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Announcement not found.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final a = _announcement!;
    final roleColor = _roleColor(a.createdByRole);
    final dateStr = DateFormat('MMMM d, yyyy').format(a.createdAt.toLocal());
    final timeStr = DateFormat('h:mm a').format(a.createdAt.toLocal());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ──────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [roleColor, roleColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: roleColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        a.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _infoChip(Icons.person, a.createdByName),
                    const SizedBox(width: 8),
                    _infoChip(Icons.verified_user, _roleBadgeLabel(a.createdByRole)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoChip(Icons.calendar_today, dateStr),
                    const SizedBox(width: 8),
                    _infoChip(Icons.access_time, timeStr),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Message card ─────────────────────────────────────────
          _sectionCard(
            icon: Icons.message_outlined,
            title: 'Message',
            child: Text(
              a.message,
              style: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF37474F)),
            ),
          ),
          const SizedBox(height: 14),

          // ── Audience & sender details ─────────────────────────────
          _sectionCard(
            icon: Icons.people_outline,
            title: 'Broadcast Details',
            child: Column(
              children: [
                _detailRow('Target Audience', a.targetAudience, Icons.group),
                const Divider(height: 20),
                _detailRow('Sender Role', _roleBadgeLabel(a.createdByRole), Icons.badge_outlined),
                if (a.totalSent > 0) ...[
                  const Divider(height: 20),
                  _detailRow('Delivered To', '${a.totalSent} recipients', Icons.send),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Image attachment ─────────────────────────────────────
          if (a.imageUrl != null && a.imageUrl!.isNotEmpty) ...[
            _sectionCard(
              icon: Icons.image_outlined,
              title: 'Attached Image',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  a.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, e, s) => const SizedBox(
                    height: 100,
                    child: Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Voice note ───────────────────────────────────────────
          if (a.voiceUrl != null && a.voiceUrl!.isNotEmpty) ...[
            _sectionCard(
              icon: Icons.mic_none,
              title: 'Voice Announcement',
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(a.voiceUrl!),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Play Voice Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── PDF attachment ───────────────────────────────────────
          if (a.attachmentUrl != null && a.attachmentUrl!.isNotEmpty) ...[
            _sectionCard(
              icon: Icons.picture_as_pdf_outlined,
              title: 'PDF Attachment',
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(a.attachmentUrl!),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Open PDF Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1565C0))),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A237E))),
      ],
    );
  }
}
