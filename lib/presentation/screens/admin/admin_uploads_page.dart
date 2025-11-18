import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AdminUploadsPage extends StatefulWidget {
  const AdminUploadsPage({super.key});

  @override
  State<AdminUploadsPage> createState() => _AdminUploadsPageState();
}

class _AdminUploadsPageState extends State<AdminUploadsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  File? _pickedPdf;
  PlatformFile? _pickedPdfMeta;
  File? _pickedThumb;

  bool _isUploading = false;
  double _progress = 0.0;

  final String pdfBucket = "pdfs";
  final String thumbBucket = "thumbnails";
  final String tableName = "pdf_notes";

  // ---------------------------
  // PICK PDF
  // ---------------------------
  Future<void> _pickPdf() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked == null) return;

    setState(() {
      _pickedPdfMeta = picked.files.first;
      _pickedPdf = File(picked.files.first.path!);
    });
  }

  // ---------------------------
  // PICK THUMBNAIL
  // ---------------------------
  Future<void> _pickThumb() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    if (picked == null) return;

    setState(() {
      _pickedThumb = File(picked.files.first.path!);
    });
  }

  // ---------------------------
  // UPLOAD EVERYTHING
  // ---------------------------
  Future<void> _uploadAll() async {
    print("JWT: ${Supabase.instance.client.auth.currentSession?.accessToken}");

    if (_pickedPdf == null ||
        _pickedThumb == null ||
        _titleController.text.isEmpty ||
        _categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields & pick files")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0.1;
    });

    final uuid = const Uuid().v4();
    final storage = Supabase.instance.client.storage;

    try {
      // -----------------------------------------
      // 1️⃣ UPLOAD PDF (normal upload)
      // -----------------------------------------
      final pdfExt = _pickedPdfMeta!.extension ?? "pdf";
      final pdfName = "$uuid.$pdfExt";

      await storage.from(pdfBucket).upload(pdfName, _pickedPdf!);

      final pdfUrl = storage.from(pdfBucket).getPublicUrl(pdfName);

      setState(() => _progress = 0.5);

      // -----------------------------------------
      // 2️⃣ UPLOAD THUMBNAIL
      // -----------------------------------------
      final thumbExt = _pickedThumb!.path.split('.').last;
      final thumbName = "$uuid-thumb.$thumbExt";

      await storage.from(thumbBucket).upload(thumbName, _pickedThumb!);

      final thumbUrl = storage.from(thumbBucket).getPublicUrl(thumbName);

      setState(() => _progress = 0.8);

      // -----------------------------------------
      // 3️⃣ INSERT INTO TABLE
      // -----------------------------------------
      await Supabase.instance.client.from(tableName).insert({
        "title": _titleController.text.trim(),
        "category": _categoryController.text.trim(),
        "file_url": pdfUrl,
        "thumbnail_url": thumbUrl,
      });

      setState(() => _progress = 1.0);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload Successful!")));

      // Reset UI
      setState(() {
        _pickedPdf = null;
        _pickedThumb = null;
        _pickedPdfMeta = null;
        _isUploading = false;
        _progress = 0.0;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Admin: Upload PDF"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Title",
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _categoryController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Category",
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickPdf,
                  child: const Text("Pick PDF"),
                ),
                const SizedBox(width: 12),
                Text(
                  _pickedPdfMeta?.name ?? "No PDF selected",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickThumb,
                  child: const Text("Pick Thumbnail"),
                ),
                const SizedBox(width: 12),
                _pickedThumb != null
                    ? Image.file(_pickedThumb!, width: 80, height: 100)
                    : const Text(
                        "No thumbnail",
                        style: TextStyle(color: Colors.white70),
                      ),
              ],
            ),

            const SizedBox(height: 20),

            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white12,
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 10),
              Text(
                "${(_progress * 100).toStringAsFixed(1)}%",
                style: const TextStyle(color: Colors.white70),
              ),
            ],

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: _isUploading ? null : _uploadAll,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text("Upload PDF"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
