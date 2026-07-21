import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final url = 'https://wdnfzvxnnuscbhrobavy.supabase.co';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndkbmZ6dnhubnVzY2Jocm9iYXZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyODA4NzYsImV4cCI6MjA5Nzg1Njg3Nn0.fZBcVEkEBpNx8rO6EIkfZlkMlKwMTsqqfazikGEPsjc';
  final supabase = SupabaseClient(url, key);

  try {
    // Generate an ID for the notification and see if it accepts text
    final testId = 'test-${DateTime.now().millisecondsSinceEpoch}';
    await supabase.from('notifications').insert({
      'id': testId,
      'userId': 'invalid-user',
      'title': 'test',
      'body': 'test'
    });
  } catch (e) {
    print(e);
  }
  exit(0);
}
