import 'package:supabase/supabase.dart';
import 'dart:io';

bool _matchRole(String target, String actual) {
  final t = target.replaceAll(' ', '').replaceAll('_', '').toLowerCase();
  final a = actual.replaceAll(' ', '').replaceAll('_', '').toLowerCase();
  if (t == a) return true;
  if ((t == 'wardmember' || t == 'wardadmin') && (a == 'wardmember' || a == 'wardadmin')) return true;
  return false;
}

void main() async {
  final url = 'https://wdnfzvxnnuscbhrobavy.supabase.co';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndkbmZ6dnhubnVzY2Jocm9iYXZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyODA4NzYsImV4cCI6MjA5Nzg1Njg3Nn0.fZBcVEkEBpNx8rO6EIkfZlkMlKwMTsqqfazikGEPsjc';
  final supabase = SupabaseClient(url, key);

  try {
    final meetingId = 'test_meeting_${DateTime.now().millisecondsSinceEpoch}';
    final targetRoles = ['Ward Member'];
    
    // Simulate what createMeeting does
    final usersResponse = await supabase.from('users').select('id, role');
    final List<Map<String, dynamic>> notifications = [];
    int matchCount = 0;
    
    for (var u in usersResponse) {
      if (targetRoles.contains('All Users') || targetRoles.any((r) => _matchRole(r, u['role'].toString()))) {
        matchCount++;
        notifications.add({
          'id': 'notif_${DateTime.now().millisecondsSinceEpoch}_${u['id'].hashCode}',
          'userId': u['id'],
          'title': 'New Meeting Scheduled',
          'body': 'test',
          'type': 'meeting',
          'reference_id': meetingId,
          'isRead': false,
          'createdAt': DateTime.now().toUtc().toIso8601String()
        });
      }
    }
    
    print('Users queried: ${usersResponse.length}');
    print('Ward Members matched: $matchCount');
    
    if (notifications.isNotEmpty) {
      await supabase.from('notifications').insert(notifications);
      print('Inserted ${notifications.length} notifications successfully.');
    }
    
  } catch (e) {
    print(e);
  }
  exit(0);
}
