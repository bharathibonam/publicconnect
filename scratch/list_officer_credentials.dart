import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final url = 'https://wdnfzvxnnuscbhrobavy.supabase.co';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndkbmZ6dnhubnVzY2Jocm9iYXZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyODA4NzYsImV4cCI6MjA5Nzg1Njg3Nn0.fZBcVEkEBpNx8rO6EIkfZlkMlKwMTsqqfazikGEPsjc';
  final supabase = SupabaseClient(url, key);

  try {
    final res = await supabase.from('users').select('name, phoneNumber, password, role, officerRole, mandalName, wardName');
    print('=== ALL REGISTERED USERS IN SUPABASE ===');
    for (var row in res) {
      print('Name: ${row['name']} | Role: ${row['role']} | Phone: ${row['phoneNumber']} | Pass: ${row['password']} | OfficerRole: ${row['officerRole']} | Mandal: ${row['mandalName']}');
    }
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
