// lib/screens/pdf_audio_reader_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfAudioReaderPage extends StatefulWidget {
  const PdfAudioReaderPage({
    super.key,
    required this.filePath, // filename only, e.g. "myfile.pdf"
    required this.pdfId, // DB id / uuid for progress keys
    required this.title, // human title shown in app bar
    this.initialRate = 0.45,
  });

  final String filePath;
  final String pdfId;
  final String title;
  final double initialRate;

  @override
  State<PdfAudioReaderPage> createState() => _PdfAudioReaderPageState();
}

class _PdfAudioReaderPageState extends State<PdfAudioReaderPage> {
  final FlutterTts _tts = FlutterTts();

  bool _loading = true;
  bool _speaking = false;
  bool _autoAdvance = true;

  List<String> _chunks = [];
  int _currentChunkIndex = 0;
  int _charOffsetInChunk = 0;

  // chunk tuning
  static const int _charsPerChunk = 1400;
  static final RegExp _sentenceEnd = RegExp(r'([.!?])\s+');

  // totals for progress calculations
  int _totalChars = 0;
  List<int> _cumulative = [];

  double _speechRate = 0.45;

  // guard to avoid double completion handling
  bool _isHandlingCompletion = false;

  @override
  void initState() {
    super.initState();
    _speechRate = widget.initialRate;
    _initTts();
    _loadPdfAndPrepare();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(_speechRate);

    // Completion handler
    _tts.setCompletionHandler(() async {
      if (_isHandlingCompletion) return;
      _isHandlingCompletion = true;
      try {
        _onChunkComplete();
      } finally {
        _isHandlingCompletion = false;
      }
    });

    _tts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      setState(() => _speaking = false);
    });
  }

  Future<Uint8List> _downloadPdfBytes() async {
    final storage = Supabase.instance.client.storage;
    // bucket name 'pdfs'; filePath is filename only
    final data = await storage.from('pdfs').download(widget.filePath);

    // ignore: unnecessary_type_check
    if (data is Uint8List) return data;
    // ignore: dead_code, unnecessary_type_check
    if (data is List<int>) return Uint8List.fromList(data);

    throw Exception("Unexpected download result: ${data.runtimeType}");
  }

  Future<void> _loadPdfAndPrepare() async {
    setState(() => _loading = true);

    try {
      final bytes = await _downloadPdfBytes();

      // Syncfusion extraction
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      // ignore: dead_code
      final String fullText = extractor.extractText() ?? "";
      document.dispose();

      final normalized = fullText.replaceAll('\r\n', '\n').trim();

      if (normalized.isEmpty) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No selectable text found in this PDF (scanned image?)",
            ),
          ),
        );
        return;
      }

      _chunks = _splitIntoChunks(normalized);
      _buildTotals();

      await _loadSavedProgress();

      setState(() => _loading = false);
    } catch (e, st) {
      debugPrint("PDF load error: $e\n$st");
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load PDF: $e")));
    }
  }

  void _buildTotals() {
    _totalChars = _chunks.fold(0, (p, e) => p + e.length);
    _cumulative = List<int>.filled(_chunks.length, 0);
    int sum = 0;
    for (int i = 0; i < _chunks.length; i++) {
      sum += _chunks[i].length;
      _cumulative[i] = sum;
    }
  }

  List<String> _splitIntoChunks(String text) {
    if (text.isEmpty) return [];
    final List<String> out = [];
    int cursor = 0;
    final int len = text.length;

    while (cursor < len) {
      int end = (cursor + _charsPerChunk).clamp(0, len);
      if (end >= len) {
        out.add(text.substring(cursor).trim());
        break;
      }

      // attempt to split on sentence boundary inside the chunk
      final sub = text.substring(cursor, end);
      final matches = _sentenceEnd.allMatches(sub).toList();
      if (matches.isNotEmpty) {
        final last = matches.last;
        final splitAt = cursor + last.end;
        out.add(text.substring(cursor, splitAt).trim());
        cursor = splitAt;
      } else {
        out.add(text.substring(cursor, end).trim());
        cursor = end;
      }

      while (cursor < len && text[cursor].trim().isEmpty) cursor++;
    }

    return out;
  }

  Future<void> _loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final kIndex = "${widget.pdfId}_chunk_index";
    final kOffset = "${widget.pdfId}_char_offset";

    final savedIndex = prefs.getInt(kIndex) ?? 0;
    final savedOffset = prefs.getInt(kOffset) ?? 0;

    _currentChunkIndex = (savedIndex >= 0 && savedIndex < _chunks.length)
        ? savedIndex
        : 0;
    _charOffsetInChunk =
        (_chunks.isNotEmpty &&
            savedOffset >= 0 &&
            savedOffset < _chunks[_currentChunkIndex].length)
        ? savedOffset
        : 0;
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("${widget.pdfId}_chunk_index", _currentChunkIndex);
    await prefs.setInt("${widget.pdfId}_char_offset", _charOffsetInChunk);
  }

  Future<void> _speakCurrentChunk() async {
    if (_chunks.isEmpty) return;
    final chunk = _chunks[_currentChunkIndex];
    if (_charOffsetInChunk >= chunk.length) {
      _onChunkComplete();
      return;
    }
    final toSpeak = chunk.substring(_charOffsetInChunk).trim();
    if (toSpeak.isEmpty) {
      _onChunkComplete();
      return;
    }

    setState(() => _speaking = true);
    await _tts.setSpeechRate(_speechRate);
    await _tts.speak(toSpeak);
    // completion handled by handler
  }

  Future<void> _play() async {
    if (_speaking) return;
    if (_chunks.isEmpty) return;
    await _speakCurrentChunk();
  }

  Future<void> _pause() async {
    await _tts.stop();
    setState(() => _speaking = false);
    await _saveProgress();
  }

  void _onChunkComplete() {
    // called from completion handler; ensure UI update and advance
    setState(() {
      _speaking = false;
      _charOffsetInChunk = 0;
      if (_autoAdvance && _currentChunkIndex < _chunks.length - 1) {
        _currentChunkIndex++;
      }
    });

    _saveProgress();

    if (_autoAdvance && _currentChunkIndex < _chunks.length - 1) {
      // small delay to avoid immediate handler reentrancy
      Future.delayed(
        const Duration(milliseconds: 150),
        () => _speakCurrentChunk(),
      );
    }
  }

  Future<void> _nextChunk() async {
    await _pause();
    setState(() {
      if (_currentChunkIndex < _chunks.length - 1) _currentChunkIndex++;
      _charOffsetInChunk = 0;
    });
    await _saveProgress();
    await _play();
  }

  Future<void> _prevChunk() async {
    await _pause();
    setState(() {
      if (_currentChunkIndex > 0) _currentChunkIndex--;
      _charOffsetInChunk = 0;
    });
    await _saveProgress();
    await _play();
  }

  Future<void> _jumpForwardChars(int chars) async {
    await _pause();
    setState(() {
      _charOffsetInChunk = (_charOffsetInChunk + chars).clamp(
        0,
        _chunks[_currentChunkIndex].length,
      );
      while (_charOffsetInChunk >= _chunks[_currentChunkIndex].length &&
          _currentChunkIndex < _chunks.length - 1) {
        _charOffsetInChunk -= _chunks[_currentChunkIndex].length;
        _currentChunkIndex++;
      }
    });
    await _saveProgress();
    await _play();
  }

  Future<void> _jumpBackwardChars(int chars) async {
    await _pause();
    setState(() {
      _charOffsetInChunk = (_charOffsetInChunk - chars);
      while (_charOffsetInChunk < 0 && _currentChunkIndex > 0) {
        _currentChunkIndex--;
        _charOffsetInChunk += _chunks[_currentChunkIndex].length;
      }
      if (_charOffsetInChunk < 0) _charOffsetInChunk = 0;
    });
    await _saveProgress();
    await _play();
  }

  /// Seek by percent of total chars across whole book
  Future<void> _seekPercent(double percent) async {
    if (_chunks.isEmpty) return;
    final targetChar = (_totalChars * percent).floor().clamp(
      0,
      _totalChars - 1,
    );
    // find chunk containing targetChar using cumulative sums
    int chunk = 0;
    while (chunk < _cumulative.length && _cumulative[chunk] <= targetChar)
      chunk++;
    final prevCum = chunk == 0 ? 0 : _cumulative[chunk - 1];
    setState(() {
      _currentChunkIndex = chunk.clamp(0, _chunks.length - 1);
      _charOffsetInChunk = (targetChar - prevCum).clamp(
        0,
        _chunks[_currentChunkIndex].length - 1,
      );
    });
    await _saveProgress();
    await _play();
  }

  String get _currentPreview {
    if (_chunks.isEmpty) return "";
    final chunk = _chunks[_currentChunkIndex];
    final preview = (_charOffsetInChunk < chunk.length)
        ? chunk.substring(_charOffsetInChunk)
        : "";
    return preview.replaceAll('\n', ' ').trim();
  }

  double get _progressPercent {
    if (_chunks.isEmpty || _totalChars == 0) return 0.0;
    final prevChars = _currentChunkIndex == 0
        ? 0
        : _cumulative[_currentChunkIndex - 1];
    final done = prevChars + _charOffsetInChunk;
    return (done / _totalChars).clamp(0.0, 1.0);
  }

  Widget _buildControls() {
    return Column(
      children: [
        Text(
          _chunks.isEmpty
              ? "No text"
              : "Chunk ${_currentChunkIndex + 1} / ${_chunks.length}",
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              onPressed: _prevChunk,
              iconSize: 34,
            ),
            IconButton(
              icon: Icon(
                _speaking ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white,
              ),
              onPressed: _speaking ? _pause : _play,
              iconSize: 64,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              onPressed: _nextChunk,
              iconSize: 34,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _jumpBackwardChars(450),
              child: const Text(
                "<< 15s approx",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(width: 20),
            TextButton(
              onPressed: () => _jumpForwardChars(450),
              child: const Text(
                "15s approx >>",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Speed", style: TextStyle(color: Colors.white70)),
            const SizedBox(width: 8),
            Slider(
              value: _speechRate,
              min: 0.25,
              max: 1.0,
              divisions: 15,
              label: _speechRate.toStringAsFixed(2),
              onChanged: (v) async {
                setState(() => _speechRate = v);

                // Stop current speech so new rate applies immediately
                await _tts.stop();
                await _tts.setSpeechRate(_speechRate);

                // Resume reading from current position
                if (_speaking == true) {
                  await _speakCurrentChunk();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.title.isNotEmpty
        ? widget.title
        : widget.filePath.split('/').last;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Reading: $displayTitle"),
        actions: [
          IconButton(
            icon: Icon(
              _autoAdvance ? Icons.repeat : Icons.repeat_one,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _autoAdvance = !_autoAdvance),
            tooltip: _autoAdvance ? "Auto advance ON" : "Auto advance OFF",
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  // Preview / text area
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _currentPreview.isEmpty ? "No text" : _currentPreview,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  // progress + slider
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Chunk ${_currentChunkIndex + 1}/${_chunks.length}",
                            style: const TextStyle(color: Colors.white60),
                          ),
                          Text(
                            "${(_progressPercent * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ],
                      ),
                      Slider(
                        value: _progressPercent,
                        onChanged: (v) => _seekPercent(v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // controls
                  _buildControls(),
                ],
              ),
            ),
    );
  }
}
