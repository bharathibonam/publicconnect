import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://eadrinagzvqgjrspugix.supabase.co/rest/v1/complaints';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhZHJpbmFnenZxZ2pyc3B1Z2l4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwMjc4NzYsImV4cCI6MjA5NTYwMzg3Nn0.N_q-dcfdOwYdo9TlsSIMwHgWfVE2WkFk4Mpc_2eRU8U';

  final body = {
    'id': 'test_comp_1',
    'userId': 'some_user',
    'citizenName': 'Test',
    'citizenPhone': '12345',
    'category': 'Water',
    'description': 'test',
    'latitude': 0.0,
    'longitude': 0.0,
    'wardId': 'ward_1',
    'status': 'submitted',
    'priority': 'low',
    'createdAt': DateTime.now().toIso8601String(),
    'assignedOfficerId': null
  };

  final res = await http.post(
    Uri.parse(url),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
      'Content-Type': 'application/json',
      'Prefer': 'return=minimal'
    },
    body: jsonEncode(body)
  );

  // ignore: avoid_print
  print('Status: ${res.statusCode}');
  // ignore: avoid_print
  print('Body: ${res.body}');
}
