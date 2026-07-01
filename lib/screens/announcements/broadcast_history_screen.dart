import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/app_state.dart';
import '../../services/supabase_service.dart';
import 'announcement_details_screen.dart';
import '../../models/announcement.dart';

class BroadcastHistoryScreen extends StatefulWidget {
  const BroadcastHistoryScreen({super.key});

  @override
  State<BroadcastHistoryScreen> createState() => _BroadcastHistoryScreenState();
}

class _BroadcastHistoryScreenState extends State<BroadcastHistoryScreen> {
  List<Map<String, dynamic>> _stats = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    if (user == null) {
      setState(() { _loading = false; _error = 'Not logged in'; });
      return;
    }
    try {
      final data = await SupabaseService.getBroadcastStats(user.id);
      if (mounted) setState(() { _stats = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  String _audienceLabel(Map<String, dynamic> row) {
    final targetType = row['target_type'] ?? 'role';
    final targetId   = row['target_id'];
    final legacy     = row['target_audience'] ?? '';

    if (targetType == 'all') return 'All Users';
    if (targetType == 'role' && targetId != null) {
      switch (targetId) {
        case 'citizen':         return 'Citizens';
        case 'wardAdmin':       return 'Ward Members';
        case 'categoryOfficer': return 'Category Officers';
        case 'mandalOfficer':   return 'Mandal Officers';
        default:                return targetId;
      }
    }
    return legacy;
  }

  Color _audienceColor(String audience) {
    if (audience.contains('Citizen'))  return const Color(0xFF1565C0);
    if (audience.contains('Ward'))     return const Color(0xFF4527A0);
    if (audience.contains('Category')) return const Color(0xFF6A1B9A);
    if (audience.contains('Mandal'))   return const Color(0xFF2E7D32);
    return const Color(0xFF37474F);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Broadcast History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _stats.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stats.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) => _buildCard(ctx, _stats[i]),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text('Failed to load history', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No broadcasts yet.',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Your sent announcements will appear here.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext ctx, Map<String, dynamic> row) {
    final audience       = _audienceLabel(row);
    final audienceColor  = _audienceColor(audience);
    final title          = row['title'] ?? '';
    final createdAt      = DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final dateStr        = DateFormat('MMM d, yyyy').format(createdAt);
    final timeStr        = DateFormat('h:mm a').format(createdAt);
    final delivered      = (row['total_delivered'] as num?)?.toInt() ?? 0;
    final readCount      = (row['read_count'] as num?)?.toInt() ?? 0;
    final unreadCount    = (row['unread_count'] as num?)?.toInt() ?? 0;
    final readPct        = (row['read_percentage'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () {
        final a = Announcement.fromMap({
          'id':               row['announcement_id'] ?? '',
          'title':            row['title'] ?? '',
          'message':          row['message'] ?? '',
          'created_by_id':    row['sender_id'] ?? '',
          'created_by_role':  row['sender_role'] ?? '',
          'created_by_name':  row['sender_name'] ?? '',
          'target_audience':  row['target_audience'] ?? '',
          'target_type':      row['target_type'],
          'target_id':        row['target_id'],
          'image_url':        row['image_url'],
          'voice_url':        row['voice_url'],
          'attachment_url':   row['attachment_url'],
          'total_sent':       delivered,
          'created_at':       row['created_at'] ?? '',
        });
        Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => AnnouncementDetailsScreen(announcement: a),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: audienceColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.campaign, color: audienceColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A237E)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: audienceColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: audienceColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(audience, style: TextStyle(fontSize: 11, color: audienceColor, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Stats row ──
              Row(
                children: [
                  _statBadge(delivered, 'Delivered', Icons.send, const Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  _statBadge(readCount, 'Read', Icons.done_all, const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  _statBadge(unreadCount, 'Unread', Icons.mark_email_unread, Colors.orange.shade700),
                ],
              ),
              const SizedBox(height: 12),

              // ── Read progress bar ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Read Rate', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      Text('${readPct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: readPct / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        readPct > 70 ? const Color(0xFF2E7D32)
                            : readPct > 40 ? Colors.orange
                            : Colors.red.shade400,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBadge(int value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text('$value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
