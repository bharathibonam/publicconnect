import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/meeting.dart';
import 'package:provider/provider.dart';
import '../../../services/app_state.dart';
import '../../../models/user.dart';
import '../../../services/supabase_service.dart';
import 'create_meeting_screen.dart';
class MeetingDetailsScreen extends StatelessWidget {
  final Meeting meeting;
  final dynamic themeConfig;

  const MeetingDetailsScreen({super.key, required this.meeting, required this.themeConfig});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    // Real-time resolution
    final currentMeeting = appState.meetings.firstWhere((m) => m.id == meeting.id, orElse: () => meeting);
    
    final bool isOrganizer = user != null && currentMeeting.createdBy == user.id;

    void _handleAction(String action) async {
      try {
        if (action == 'delete') {
          await SupabaseService.deleteMeeting(currentMeeting.id);
          if (context.mounted) Navigator.pop(context);
        } else if (action == 'cancel') {
          await SupabaseService.updateMeetingStatus(
            currentMeeting.id, 
            'cancelled',
            targetRoles: currentMeeting.targetRoles,
            meetingTitle: currentMeeting.title,
          );
        } else if (action == 'complete') {
          await SupabaseService.updateMeetingStatus(
            currentMeeting.id, 
            'completed',
            targetRoles: currentMeeting.targetRoles,
            meetingTitle: currentMeeting.title,
          );
        } else if (action == 'edit') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateMeetingScreen(meeting: currentMeeting)));
        }
      } catch (e) {
        debugPrint('Meeting Action Error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text('Meeting Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (isOrganizer)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onSelected: _handleAction,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: Text('Edit Meeting')),
                if (currentMeeting.status == 'upcoming')
                  const PopupMenuItem<String>(value: 'complete', child: Text('Mark as Completed')),
                if (currentMeeting.status == 'upcoming')
                  const PopupMenuItem<String>(value: 'cancel', child: Text('Cancel Meeting', style: TextStyle(color: Colors.orange))),
                const PopupMenuItem<String>(value: 'delete', child: Text('Delete Meeting', style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: meeting.status == 'completed' ? Colors.green.shade50 : (meeting.status == 'cancelled' ? Colors.red.shade50 : Colors.blue.shade50),
                borderRadius: BorderRadius.circular(12)
              ),
              child: Text(currentMeeting.status.toUpperCase(), style: TextStyle(color: currentMeeting.status == 'completed' ? Colors.green : (currentMeeting.status == 'cancelled' ? Colors.red : Colors.blue), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(currentMeeting.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Created by ${currentMeeting.createdBy} • Priority: ${currentMeeting.priority}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),

            // Date & Time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: themeConfig.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.calendar_today, color: themeConfig.primaryColor),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date & Time', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('${DateFormat('MMMM dd, yyyy').format(currentMeeting.date)} • ${currentMeeting.startTime} - ${currentMeeting.endTime}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Venue
            if (currentMeeting.venue != null || currentMeeting.location != null)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: themeConfig.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.location_on, color: themeConfig.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Venue', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(currentMeeting.venue ?? currentMeeting.location ?? 'No Venue Specified', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        if (currentMeeting.location != null)
                          GestureDetector(
                            onTap: () {},
                            child: Text('Open in Google Maps', style: TextStyle(color: themeConfig.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            if (currentMeeting.venue != null || currentMeeting.location != null) const SizedBox(height: 16),

            // Live Link
            if (currentMeeting.meetLink != null && currentMeeting.meetLink!.isNotEmpty)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: themeConfig.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.video_call, color: themeConfig.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Live Meeting Link', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(currentMeeting.meetLink!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {},
                          child: Text('Join Meeting', style: TextStyle(color: themeConfig.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (currentMeeting.meetLink != null && currentMeeting.meetLink!.isNotEmpty) const Divider(height: 48),

            if (currentMeeting.description != null && currentMeeting.description!.isNotEmpty) ...[
              const Text('Description & Agenda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                currentMeeting.description!,
                style: const TextStyle(color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],

            if (currentMeeting.attachmentUrl != null && currentMeeting.attachmentUrl!.isNotEmpty) ...[
              const Text('Attachments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                title: const Text('Meeting_Attachment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {},
                ),
              ),
              const Divider(height: 48),
            ],

            const Text('Target Audience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentMeeting.targetRoles.map((role) {
                return Chip(
                  label: Text(role, style: const TextStyle(fontSize: 12)),
                  backgroundColor: themeConfig.primaryColor.withValues(alpha: 0.1),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            Text('Created at: ${DateFormat('MMM dd, yyyy h:mm a').format(currentMeeting.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            const Divider(height: 48),

            const Text('Attendance Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            if (isOrganizer) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live Attendance Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAttendanceStat('Accepted', currentMeeting.attendance.where((a) => a['status'] == 'accepted').length, Colors.green),
                        _buildAttendanceStat('Declined', currentMeeting.attendance.where((a) => a['status'] == 'declined').length, Colors.red),
                        _buildAttendanceStat('Maybe', currentMeeting.attendance.where((a) => a['status'] == 'maybe').length, Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: user == null ? null : () async {
                      try {
                        await SupabaseService.updateMeetingAttendance(currentMeeting.id, user.id, 'accepted');
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance marked as ACCEPTED')));
                      } catch (e) {
                        debugPrint('Attendance Error: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('ACCEPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: user == null ? null : () async {
                      try {
                        await SupabaseService.updateMeetingAttendance(currentMeeting.id, user.id, 'declined');
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance marked as DECLINED')));
                      } catch (e) {
                        debugPrint('Attendance Error: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('DECLINE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: user == null ? null : () async {
                      try {
                        await SupabaseService.updateMeetingAttendance(currentMeeting.id, user.id, 'maybe');
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance marked as MAYBE')));
                      } catch (e) {
                        debugPrint('Attendance Error: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('MAYBE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
