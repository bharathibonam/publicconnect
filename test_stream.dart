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
    final res = await supabase.from('meetings').select('*, meeting_targets(target_role)');
    List<dynamic> allMeetings = res;
    
    // Simulate what happens in streamMeetings for wardAdmin
    final userRole = 'wardAdmin';
    final userId = 'some_ward_admin_id';
    
    final filtered = allMeetings.where((m) {
      if (userRole.toLowerCase() == 'superadmin' || userRole.toLowerCase() == 'super admin') return true;
      
      // Map joined targets back to a simple list of strings
      List<dynamic> rawTargets = m['meeting_targets'] ?? [];
      List<String> targetRoles = rawTargets.map((t) => t['target_role'].toString()).toList();
      
      bool matchedRole = targetRoles.any((r) => _matchRole(r, userRole));
      return m['created_by'] == userId || matchedRole || targetRoles.contains('All Users');
    }).toList();
    
    print('Total Meetings: ${allMeetings.length}');
    for (var m in allMeetings) {
      print('Meeting ID: ${m['id']}, target_roles: ${m['target_roles']}');
    }
    print('Filtered for Ward Admin: ${filtered.length}');
    
    if (filtered.isNotEmpty) {
      print('Example filtered meeting target_roles: ${filtered.last['target_roles']}');
    }
  } catch (e) {
    print(e);
  }
  exit(0);
}
