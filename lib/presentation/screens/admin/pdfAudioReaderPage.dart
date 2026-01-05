import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfAudioReaderPage extends StatefulWidget {
  const PdfAudioReaderPage({
    super.key,
    required this.filePath,
    required this.pdfId,
    required this.title,
    this.initialRate = 0.5, // ✅ natural default
  });

  final String filePath;
  final String pdfId;
  final String title;
  final double initialRate;

  @override
  State<PdfAudioReaderPage> createState() => _PdfAudioReaderPageState();
}

class _PdfAudioReaderPageState extends State<PdfAudioReaderPage> {
  // ================= TTS =================
  final FlutterTts _tts = FlutterTts();

  bool _loading = true;
  bool _playing = false;
  bool _autoAdvance = true;

  // ================= TEXT =================
  List<String> _chunks = [];
  int _currentChunkIndex = 0;

  static const int _charsPerChunk = 1200;
  static final RegExp _sentenceEnd = RegExp(r'([.!?])\s+');

  double _playbackRate = 0.5;

  // ================= SPEED DISPLAY =================
  String get displaySpeed {
    final logical = (_playbackRate / 0.5);
    return "${logical.toStringAsFixed(1)}x";
  }

  @override
  void initState() {
    super.initState();
    _playbackRate = widget.initialRate;
    _setupTts();
    _loadPdf();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // ================= TTS SETUP =================
  Future<void> _setupTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(_playbackRate);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setCompletionHandler(() {
      setState(() => _playing = false);

      if (_autoAdvance && _currentChunkIndex < _chunks.length - 1) {
        _currentChunkIndex++;
        _play();
      }
    });
  }

  // ================= PDF =================
  Future<Uint8List> _downloadPdf() async {
    final data = await Supabase.instance.client.storage
        .from('pdfs')
        .download(widget.filePath);

    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);

    throw Exception("Invalid PDF data");
  }

  Future<void> _loadPdf() async {
    setState(() => _loading = true);

    try {
      final bytes = await _downloadPdf();
      final doc = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();

      final normalized = text.replaceAll('\r\n', '\n').trim();
      if (normalized.isEmpty) {
        throw Exception("No selectable text in PDF");
      }

      _chunks = _splitIntoChunks(normalized);
      await _loadProgress();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("PDF error: $e")));
      }
    }

    setState(() => _loading = false);
  }

  List<String> _splitIntoChunks(String text) {
    final out = <String>[];
    int cursor = 0;

    while (cursor < text.length) {
      int end = (cursor + _charsPerChunk).clamp(0, text.length);

      if (end >= text.length) {
        out.add(text.substring(cursor).trim());
        break;
      }

      final sub = text.substring(cursor, end);
      final matches = _sentenceEnd.allMatches(sub).toList();

      if (matches.isNotEmpty) {
        final splitAt = cursor + matches.last.end;
        out.add(text.substring(cursor, splitAt).trim());
        cursor = splitAt;
      } else {
        out.add(text.substring(cursor, end).trim());
        cursor = end;
      }
    }
    return out;
  }

  // ================= PROGRESS =================
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _currentChunkIndex = prefs.getInt("${widget.pdfId}_chunk") ?? 0;
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("${widget.pdfId}_chunk", _currentChunkIndex);
  }

  // ================= CONTROLS =================
  Future<void> _play() async {
    if (_playing || _chunks.isEmpty) return;

    setState(() => _playing = true);
    await _tts.setSpeechRate(_playbackRate);
    await _tts.speak(_chunks[_currentChunkIndex]);
    await _saveProgress();
  }

  Future<void> _pause() async {
    await _tts.stop();
    setState(() => _playing = false);
    await _saveProgress();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              "Self Development • Audio Reading",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _autoAdvance ? Icons.loop : Icons.looks_one,
              color: Colors.white70,
            ),
            tooltip: "Auto continue",
            onPressed: () => setState(() => _autoAdvance = !_autoAdvance),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _chunks[_currentChunkIndex],
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _playing ? "Listening..." : "Paused",
                    style: TextStyle(
                      color: _playing ? Colors.greenAccent : Colors.white54,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _playing
                              ? Colors.redAccent
                              : Colors.greenAccent,
                        ),
                        child: IconButton(
                          iconSize: 40,
                          icon: Icon(
                            _playing ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                          ),
                          onPressed: _playing ? _pause : _play,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Reading Speed",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        displaySpeed,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  Slider(
                    value: _playbackRate,
                    min: 0.3,
                    max: 0.9,
                    divisions: 12,
                    onChanged: (v) {
                      setState(() => _playbackRate = v);
                      _tts.setSpeechRate(v);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
