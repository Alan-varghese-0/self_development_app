import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/journal_service.dart';

class DiarySummaryPage extends StatefulWidget {
  final String journalId;
  final bool autoGenerate;

  const DiarySummaryPage({
    super.key,
    required this.journalId,
    this.autoGenerate = false,
  });

  @override
  State<DiarySummaryPage> createState() => _DiarySummaryPageState();
}

class _DiarySummaryPageState extends State<DiarySummaryPage> {
  final JournalService service = JournalService();

  bool loading = true;
  bool generating = false;
  Map<String, dynamic>? ai;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  /// 🔹 ONE-TIME FAST CHECK
  Future<void> _loadSummary() async {
    ai = await service.getAISummary(widget.journalId);
    setState(() => loading = false);
  }

  /// 🔹 MANUAL AI GENERATION
  Future<void> _generateAI() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("You must be logged in")));
      return;
    }

    setState(() => generating = true);

    final journal = await supabase
        .from('journal_entries')
        .select('content')
        .eq('id', widget.journalId)
        .single();

    await supabase.functions.invoke(
      'generate_journal_ai',
      body: {
        'journal_id': widget.journalId,
        'content': journal['content'],
        'user_id': user.id,
        'score': 5,
      },
    );

    await _loadSummary();

    setState(() => generating = false);
  }

  @override
  Widget build(BuildContext context) {
    /// 🔄 INITIAL LOAD
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    /// ❌ NO AI SUMMARY YET
    if (ai == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("AI Summary")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "No AI summary generated yet.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: generating ? null : _generateAI,
                child: generating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Generate AI Summary"),
              ),
            ],
          ),
        ),
      );
    }

    /// ✅ AI SUMMARY EXISTS
    return Scaffold(
      appBar: AppBar(title: const Text("AI Summary")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mood: ${ai!['mood']} • Score: ${ai!['score']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(ai!['summary']),
            const SizedBox(height: 20),
            const Text(
              "Suggestions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(ai!['insights']),
          ],
        ),
      ),
    );
  }
}
