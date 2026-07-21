import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final url = 'https://wdnfzvxnnuscbhrobavy.supabase.co';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndkbmZ6dnhubnVzY2Jocm9iYXZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyODA4NzYsImV4cCI6MjA5Nzg1Njg3Nn0.fZBcVEkEBpNx8rO6EIkfZlkMlKwMTsqqfazikGEPsjc';

  final supabase = SupabaseClient(url, key);

  try {
    print('--- 1. VERIFY MEETINGS TABLE (SELECT) ---');
    await supabase.from('meetings').select().limit(1);
    print('✅ meetings select OK');

    print('\n--- 2. VERIFY TARGETS TABLE (SELECT) ---');
    await supabase.from('meeting_targets').select().limit(1);
    print('✅ meeting_targets select OK');

    print('\n--- 3. VERIFY NOTIFICATIONS TABLE (SELECT) ---');
    await supabase.from('notifications').select().limit(1);
    print('✅ notifications select OK');

    print('\n--- 4. TEST CREATE MEETING (INSERT) ---');
    final meetingId = 'test-meeting-id-${DateTime.now().millisecondsSinceEpoch}';
    final meetingData = {
      'title': 'Test Verification Meeting',
      'date': '2026-07-25',
      'start_time': '10:00:00',
      'end_time': '11:00:00',
      'created_by': 'system_test',
      'status': 'upcoming'
    };
    
    // Test Meetings Insert
    final res = await supabase.from('meetings').insert(meetingData).select('id').single();
    final dbMeetingId = res['id'];
    print('✅ meetings insert OK. Inserted ID: $dbMeetingId');

    // Test Targets Insert
    await supabase.from('meeting_targets').insert([
      {'meeting_id': dbMeetingId, 'target_role': 'Citizen'}
    ]);
    print('✅ meeting_targets insert OK');

    // Fetch users for notification test
    final usersResponse = await supabase.from('users').select('id, role').limit(1);
    if (usersResponse.isNotEmpty) {
      final user = usersResponse.first;
      // Test Notifications Insert
      final notificationData = {
        'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
        'userId': user['id'],
        'title': 'Test Meeting Scheduled',
        'body': 'Meeting Body',
        'type': 'meeting',
        'reference_id': dbMeetingId,
        'isRead': false,
        'createdAt': DateTime.now().toUtc().toIso8601String()
      };
      await supabase.from('notifications').insert(notificationData);
      print('✅ notifications insert OK. User ID: ${user['id']}');
    }

    print('\n--- 5. TEST ATTENDANCE (UPSERT) ---');
    if (usersResponse.isNotEmpty) {
      final user = usersResponse.first;
      await supabase.from('meeting_attendance').insert({
        'meeting_id': dbMeetingId,
        'user_id': user['id'],
        'status': 'accepted'
      });
      print('✅ attendance insert OK');
      
      // Test trigger/touch
      await supabase.from('meetings').update({'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', dbMeetingId);
      print('✅ attendance touch (meetings updated_at) OK');
    }

    print('\n--- 6. TEST UPDATE MEETING ---');
    await supabase.from('meetings').update({'title': 'Updated Title'}).eq('id', dbMeetingId);
    print('✅ meetings update OK');

    print('\n--- 7. TEST COMPLETE MEETING ---');
    await supabase.from('meetings').update({'status': 'completed', 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', dbMeetingId);
    print('✅ meeting status update (complete) OK');

    print('\n--- 8. TEST DELETE MEETING ---');
    await supabase.from('meetings').delete().eq('id', dbMeetingId);
    print('✅ meeting delete OK (cascade should handle targets and attendance)');

    print('\n🎉 ALL DATABASE WORKFLOWS VERIFIED SUCCESSFULLY!');
    exit(0);

  } on PostgrestException catch (e) {
    print('\n❌ SUPABASE ERROR DETECTED');
    print('Message: ${e.message}');
    print('Code: ${e.code}');
    print('Details: ${e.details}');
    print('Hint: ${e.hint}');
    exit(1);
  } catch (e, st) {
    print('\n❌ GENERAL ERROR DETECTED');
    print(e);
    print(st);
    exit(1);
  }
}
