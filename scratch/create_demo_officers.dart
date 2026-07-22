import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final url = 'https://wdnfzvxnnuscbhrobavy.supabase.co';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndkbmZ6dnhubnVzY2Jocm9iYXZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyODA4NzYsImV4cCI6MjA5Nzg1Njg3Nn0.fZBcVEkEBpNx8rO6EIkfZlkMlKwMTsqqfazikGEPsjc';
  final supabase = SupabaseClient(url, key);

  try {
    // 1. Ensure Mandal Officer exists
    final mandalCheck = await supabase.from('users').select('*').eq('phoneNumber', '9876543210').maybeSingle();
    if (mandalCheck == null) {
      await supabase.from('users').insert({
        'id': 'officer_mandal_9876543210',
        'name': 'Ramesh Kumar',
        'phoneNumber': '9876543210',
        'password': 'password123',
        'role': 'mandalOfficer',
        'mandalName': 'Bhupalapatnam Mandal',
        'villageName': 'Bhupalapatnam',
        'officerRole': 'Mandal Officer',
        'createdAt': DateTime.now().toUtc().toIso8601String()
      });
      print('Created Mandal Officer account: 9876543210 / password123');
    } else {
      print('Mandal Officer exists: ${mandalCheck['phoneNumber']} / ${mandalCheck['password']}');
    }

    // 2. Ensure Category Officer exists
    final categoryCheck = await supabase.from('users').select('*').eq('phoneNumber', '9876543211').maybeSingle();
    if (categoryCheck == null) {
      await supabase.from('users').insert({
        'id': 'officer_category_9876543211',
        'name': 'Ramesh Kumar',
        'phoneNumber': '9876543211',
        'password': 'password123',
        'role': 'categoryOfficer',
        'wardName': 'Ward 12',
        'mandalName': 'Bhupalapatnam Mandal',
        'villageName': 'Bhupalapatnam',
        'officerRole': 'Water Supply Officer',
        'createdAt': DateTime.now().toUtc().toIso8601String()
      });
      print('Created Category Officer account: 9876543211 / password123');
    } else {
      print('Category Officer exists: ${categoryCheck['phoneNumber']} / ${categoryCheck['password']}');
    }

  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
