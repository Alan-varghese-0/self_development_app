// lib/speech_training/speech_training_page.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpeechTrainingPage extends StatefulWidget {
  final List<String> sentences;
  final String level;

  const SpeechTrainingPage({
    super.key,
    required this.sentences,
    required this.level,
  });

  @override
  State<SpeechTrainingPage> createState() => _SpeechTrainingPageState();
}

class _SpeechTrainingPageState extends State<SpeechTrainingPage>
    with SingleTickerProviderStateMixin {
  late String targetSentence;
  String spokenText = '';
  bool isListening = false;
  double accuracy = 0;
  List<String> mistakes = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  Timer? _resultDebounce;
  String? _lastSavedSessionKey;
  DateTime? _lastSavedSessionTime;

  @override
  void initState() {
    super.initState();
    _pickRandomSentence();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseAnim = Tween<double>(
      begin: 0,
      end: 12,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    try {
      _speech.stop();
    } catch (e, st) {
      debugPrint('Error stopping speech on dispose: $e\n$st');
    }
    _tts.stop();
    _resultDebounce?.cancel();
    super.dispose();
  }

  void _pickRandomSentence() {
    final list = widget.sentences.isNotEmpty
        ? widget.sentences
        : ['Say something to practice!'];

    targetSentence = list[Random().nextInt(list.length)];
    spokenText = '';
    accuracy = 0;
    mistakes = [];
  }

  // -------------------------
  // START LISTENING
  // -------------------------
  Future<void> _initAndStartListening() async {
    if (isListening) return;

    PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please allow microphone permission.")),
      );
      return;
    }

    debugPrint('Initializing SpeechToText...');
    bool hasPermission = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );

    debugPrint('SpeechToText initialized. hasPermission=$hasPermission');

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission is required.")),
      );
      return;
    }

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenMode: stt.ListenMode.dictation,

        listenFor: const Duration(hours: 1),
        pauseFor: const Duration(hours: 1),
      );
    } catch (e, st) {
      debugPrint('Error starting listen: $e\n$st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Microphone error: $e')));
      return;
    }

    setState(() {
      isListening = true;
      spokenText = '';
      accuracy = 0;
      mistakes = [];
    });
    debugPrint('Started listening (isListening=$isListening)');
  }

  void _stopListening() {
    try {
      _speech.stop();
    } catch (e, st) {
      debugPrint('Error stopping listen: $e\n$st');
    }
    setState(() => isListening = false);
    _resultDebounce?.cancel();
  }

  void _onSpeechStatus(String status) {
    debugPrint('SpeechStatus: $status (isListening $isListening)');
    if (status == "done") {
      if (mounted) setState(() => isListening = false);
    }
  }

  void _onSpeechError(dynamic err) {
    debugPrint('SpeechError: $err');
    setState(() => isListening = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Speech error: $err")));
  }

  // -------------------------
  // ON SPEECH RESULT
  // -------------------------
  void _onSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;

    debugPrint('SpeechResult interim: $text; final=${result.finalResult}');
    setState(() => spokenText = text);

    _resultDebounce?.cancel();

    if (result.finalResult) {
      _processFinal(text);
      _stopListening();
    } else {
      _resultDebounce = Timer(
        const Duration(milliseconds: 800),
        () => _processFinal(spokenText),
      );
    }
  }

  // -------------------------
  // FINAL RESULT PROCESSING
  // -------------------------
  void _processFinal(String finalText) {
    debugPrint('ProcessFinal: $finalText');
    final spoken = finalText.toLowerCase().trim();
    final target = targetSentence.toLowerCase().trim();

    if (spoken.isEmpty) {
      setState(() {
        accuracy = 0;
        mistakes = target.split(" ");
      });
      return;
    }

    final spokenWords = spoken.split(RegExp(r'\s+'));
    final targetWords = target.split(RegExp(r'\s+'));

    int correct = 0;
    List<String> missed = [];

    for (final w in targetWords) {
      if (spokenWords.contains(w)) {
        correct++;
      } else {
        missed.add(w);
      }
    }

    double score = (correct / targetWords.length) * 100;

    final lengthPenalty = (spokenWords.length - targetWords.length).abs();
    score -= min(10, lengthPenalty * 2);

    if (score < 0) score = 0;

    setState(() {
      accuracy = score;
      mistakes = missed;
    });

    // SAVE TO SUPABASE HERE — run in the background so it doesn't block UI
    _saveSessionToSupabase(
      targetText: targetSentence,
      spokenText: finalText,
      accuracy: score,
      mistakes: missed,
    );
  }

  // -------------------------
  // SAVE SESSION TO SUPABASE
  // -------------------------
  Future<void> _saveSessionToSupabase({
    required String targetText,
    required String spokenText,
    required double accuracy,
    required List<String> mistakes,
  }) async {
    try {
      // guard against double-saving the same session repeatedly
      final sessionKey =
          '${widget.level}::$targetText::$spokenText::${accuracy.toStringAsFixed(2)}';
      if (_lastSavedSessionKey == sessionKey && _lastSavedSessionTime != null) {
        final elapsed = DateTime.now().difference(_lastSavedSessionTime!);
        if (elapsed < const Duration(seconds: 5)) {
          debugPrint(
            'Skipping duplicate save for sessionKey=$sessionKey (elapsed ${elapsed.inMilliseconds}ms)',
          );
          return;
        }
      }
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint("User not logged in. Skipping save to Supabase.");
        return;
      }

      await supabase.from("speech_sessions").insert({
        "user_id": user.id,
        "level": widget.level,
        "target_text": targetText,
        "spoken_text": spokenText,
        "accuracy": accuracy,
        "mistakes": mistakes,
      });

      debugPrint("Speech session saved to Supabase");
      _lastSavedSessionKey = sessionKey;
      _lastSavedSessionTime = DateTime.now();
    } catch (e, st) {
      debugPrint("Error saving session to Supabase: $e\n$st");
    }
  }

  Future<void> _speakCorrect() async {
    await _tts.stop();
    await _tts.speak(targetSentence);
  }

  void _nextSentence() {
    _pickRandomSentence();
    setState(() {});
  }

  // -------------------------
  // UI WIDGETS
  // -------------------------

  Widget _buildSentenceCard(BuildContext c) {
    final scheme = Theme.of(c).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            widget.level,
            style: Theme.of(
              c,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            targetSentence,
            textAlign: TextAlign.center,
            style: Theme.of(
              c,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Tap the mic and speak the sentence aloud",
            style: Theme.of(c).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMicControl(BuildContext c) {
    final scheme = Theme.of(c).colorScheme;

    return GestureDetector(
      onTap: () async {
        if (isListening) {
          _stopListening();
        } else {
          await _initAndStartListening();
        }
      },
      onLongPressStart: (_) async {
        // Press-and-hold support
        if (!isListening) await _initAndStartListening();
      },
      onLongPressEnd: (_) {
        if (isListening) _stopListening();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final glow = _pulseAnim.value;
              return Container(
                width: 136 + glow,
                height: 136 + glow,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening
                      ? scheme.primary.withOpacity(0.15)
                      : Colors.transparent,
                ),
              );
            },
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: isListening ? scheme.primary : scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              size: 44,
              color: isListening ? Colors.white : scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext c) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          spokenText.isEmpty ? "Your spoken words appear here" : spokenText,
          textAlign: TextAlign.center,
          style: Theme.of(c).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        Text(
          "Accuracy: ${accuracy.toStringAsFixed(0)}%",
          style: Theme.of(
            c,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (mistakes.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: mistakes
                .map(
                  (w) => Chip(
                    label: Text(w),
                    backgroundColor: Colors.red.shade50,
                    labelStyle: TextStyle(color: Colors.red.shade800),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  // -----------------------------------------------------
  // BUILD
  // -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.level} Practice"),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              _buildSentenceCard(context),
              const SizedBox(height: 18),
              Expanded(
                child: Column(
                  children: [
                    _buildMicControl(context),
                    const SizedBox(height: 20),
                    _buildResults(context),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _speakCorrect,
                          icon: const Icon(Icons.volume_up),
                          label: const Text("Hear"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.surfaceVariant,
                            foregroundColor: scheme.onSurfaceVariant,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _nextSentence,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Next"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.surfaceVariant,
                            foregroundColor: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
