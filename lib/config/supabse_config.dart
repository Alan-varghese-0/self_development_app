import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://fedhdjnrpykyqsyaizmp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZlZGhkam5ycHlreXFzeWFpem1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2OTI3MzgsImV4cCI6MjA3ODI2ODczOH0.KqFXlp1hQnr5mgIxKEMAj8IQLBEV_wKT65BCqfB-vUI',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
