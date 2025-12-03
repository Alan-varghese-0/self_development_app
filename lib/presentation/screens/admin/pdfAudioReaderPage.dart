// lib/screens/pdf_audio_reader_page.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfAudioReaderPage extends StatefulWidget {
  const PdfAudioReaderPage({
    super.key,
    required this.filePath, // filename only, e.g. "myfile.pdf"
    required this.pdfId, // DB id / uuid for progress keys
    required this.title, // human title shown in app bar
    this.initialRate = 1.0, // playback speed default (1.0)
  });

  final String filePath;
  final String pdfId;
  final String title;
  final double initialRate;

  @override
  State<PdfAudioReaderPage> createState() => _PdfAudioReaderPageState();
}

class _PdfAudioReaderPageState extends State<PdfAudioReaderPage> {
  // audio player
  final AudioPlayer _audioPlayer = AudioPlayer(playerId: 'pdf_reader_player');

  // UI / state
  bool _loading = true;
  bool _playing = false;
  bool _autoAdvance = true;

  // chunks & positions
  List<String> _chunks = [];
  int _currentChunkIndex = 0;
  int _charOffsetInChunk = 0;

  // chunking params
  static const int _charsPerChunk = 1400;
  static final RegExp _sentenceEnd = RegExp(r'([.!?])\s+');

  // totals (for seek/progress)
  int _totalChars = 0;
  List<int> _cumulative = [];

  // TTS / voice
  String _selectedVoice = "female";

  // playback speed (this controls audio playback rate)
  double _playbackRate = 1.0; // user-chosen playback speed (0.5 - 2.0)

  // guards
  bool _isHandlingCompletion = false;
  bool _requestInFlight = false;

  @override
  void initState() {
    super.initState();
    _playbackRate = widget.initialRate;
    _bindAudioCallbacks();
    _loadPdfAndPrepare();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _bindAudioCallbacks() {
    // Listen for player state changes to detect when playback completes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.completed) {
        if (_isHandlingCompletion) return;
        _isHandlingCompletion = true;
        try {
          _onChunkComplete();
        } finally {
          _isHandlingCompletion = false;
        }
      } else if (state == PlayerState.stopped || state == PlayerState.paused) {
        setState(() => _playing = false);
      }
    });
  }

  // ---------------- PDF download & chunk preparation ----------------
  Future<Uint8List> _downloadPdfBytes() async {
    final storage = Supabase.instance.client.storage;
    final data = await storage.from('pdfs').download(widget.filePath);

    // storage.download may return Uint8List or List<int> depending on SDK
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);

    throw Exception("Unexpected download result: ${data.runtimeType}");
  }

  Future<void> _loadPdfAndPrepare() async {
    setState(() => _loading = true);

    try {
      final bytes = await _downloadPdfBytes();

      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load PDF: $e")));
      }
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

  void _buildTotals() {
    _totalChars = _chunks.fold(0, (p, e) => p + e.length);
    _cumulative = List<int>.filled(_chunks.length, 0);
    int sum = 0;
    for (int i = 0; i < _chunks.length; i++) {
      sum += _chunks[i].length;
      _cumulative[i] = sum;
    }
  }

  // ---------------- progress persistence ----------------
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

  // ---------------- TTS generation (Supabase function) ----------------
  Future<Uint8List> _generateTtsBytes(String text, String voice) async {
    if (_requestInFlight) {
      throw Exception("TTS request already in flight");
    }
    _requestInFlight = true;
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'super-service',
        body: {'text': text, 'voice': voice},
      );

      // Check HTTP status (new SDK)
      if (res.status != 200) {
        throw Exception(
          "TTS function error: ${res.data ?? 'status ${res.status}'}",
        );
      }

      final dynamic data = res.data;
      if (data == null || data['audio'] == null) {
        throw Exception("Invalid TTS response: ${data}");
      }

      final String b64 = data['audio'] as String;
      return base64Decode(b64);
    } finally {
      _requestInFlight = false;
    }
  }

  // ---------------- audio playback helpers ----------------
  Future<void> _applyPlaybackRate() async {
    try {
      // audioplayers uses setPlaybackRate(double) in the versions around 2.x
      await _audioPlayer.setPlaybackRate(_playbackRate);
    } catch (e) {
      debugPrint(
        "Playback rate not supported on this platform/library version: $e",
      );
      // ignore: avoid_print
      // If setPlaybackRate is not available, we simply ignore playback rate changes.
    }
  }

  Future<void> _playBytes(Uint8List bytes) async {
    await _applyPlaybackRate();
    await _audioPlayer.stop();
    await _audioPlayer.play(BytesSource(bytes));
    setState(() => _playing = true);
  }

  // ---------------- core speak control ----------------
  Future<void> _speakCurrentChunk() async {
    if (_chunks.isEmpty) return;
    if (_currentChunkIndex >= _chunks.length) return;

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

    setState(() => _playing = true);
    try {
      final bytes = await _generateTtsBytes(toSpeak, _selectedVoice);
      await _playBytes(bytes);
      // completion handled by onPlayerStateChanged
    } catch (e) {
      debugPrint("TTS generation/play error: $e");
      setState(() => _playing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("TTS failed: $e")));
      }
    }
  }

  Future<void> _play() async {
    if (_playing) return;
    if (_chunks.isEmpty) return;
    await _speakCurrentChunk();
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
    setState(() => _playing = false);
    await _saveProgress();
  }

  void _onChunkComplete() {
    setState(() {
      _playing = false;
      _charOffsetInChunk = 0;
      if (_autoAdvance && _currentChunkIndex < _chunks.length - 1) {
        _currentChunkIndex++;
      }
    });

    _saveProgress();

    if (_autoAdvance && _currentChunkIndex < _chunks.length - 1) {
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
                _playing ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white,
              ),
              onPressed: _playing ? _pause : _play,
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
        // voice + playback speed
        // Replace the Row with this:
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Voice", style: TextStyle(color: Colors.white70)),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedVoice,
                  dropdownColor: Colors.black,
                  items:
                      [
                        "female",
                        "female-soft",
                        "female-high",
                        "male",
                        "male-deep",
                        "male-low",
                        "neutral",
                        "narrator",
                      ].map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(v, style: TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                  onChanged: (v) => setState(() => _selectedVoice = v!),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Speed", style: TextStyle(color: Colors.white70)),
                SizedBox(width: 8),
                SizedBox(
                  width: 150,
                  child: Slider(
                    value: _playbackRate,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: "${_playbackRate.toStringAsFixed(2)}x",
                    onChanged: (v) {
                      setState(() => _playbackRate = v);
                      _applyPlaybackRate();
                    },
                  ),
                ),
              ],
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
