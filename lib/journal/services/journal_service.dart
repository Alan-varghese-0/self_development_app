import 'package:supabase_flutter/supabase_flutter.dart';

class JournalService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getJournals() async {
    return await supabase
        .from('journal_entries')
        .select('''
          id,
          content,
          created_at,
          journal_ai_summaries(id)
        ''')
        .order('created_at', ascending: false);
  }

  Future<String> createJournal(String content) async {
    final user = supabase.auth.currentUser!;
    final res = await supabase
        .from('journal_entries')
        .insert({'user_id': user.id, 'content': content})
        .select()
        .single();

    return res['id'];
  }

  Future<void> generateAI({
    required String journalId,
    required String content,
    double score = 5,
  }) async {
    final user = supabase.auth.currentUser!;
    await supabase.functions.invoke(
      'generate_journal_ai',
      body: {
        'journal_id': journalId,
        'content': content,
        'user_id': user.id,
        'score': score,
      },
    );
  }

  Future<Map<String, dynamic>?> getAISummary(String journalId) async {
    return await supabase
        .from('journal_ai_summaries')
        .select()
        .eq('journal_id', journalId)
        .maybeSingle();
  }
}
