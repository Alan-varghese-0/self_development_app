import 'package:flutter/material.dart';
import 'package:self_develpoment_app/presentation/screens/admin/pdfAudioReaderPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPDFsPage extends StatefulWidget {
  const AdminPDFsPage({super.key});

  @override
  State<AdminPDFsPage> createState() => _AdminPDFsPageState();
}

class _AdminPDFsPageState extends State<AdminPDFsPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<dynamic> pdfList = [];

  @override
  void initState() {
    super.initState();
    loadPDFs();
  }

  Future<void> loadPDFs() async {
    try {
      final res = await supabase.from('pdf_notes').select();

      setState(() {
        pdfList = res;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading PDFs: $e");
      setState(() => loading = false);
    }
  }

  /// Extract just the filename from a full Supabase public URL
  String extractFileName(String fullUrl) {
    return fullUrl.split("/").last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("PDF Library"),
        backgroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pdfList.isEmpty
          ? const Center(
              child: Text(
                "No PDFs uploaded",
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pdfList.length,
              itemBuilder: (context, index) {
                final pdf = pdfList[index];

                final title = pdf['title'] ?? "Untitled";
                final category = pdf['category'] ?? "Unknown";
                final thumbUrl = pdf['thumbnail_url'];
                final fileUrl = pdf['file_url']; // full URL
                final pdfId = pdf['id'];

                final fileName = extractFileName(fileUrl);

                return Card(
                  color: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: thumbUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              thumbUrl,
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 45,
                          ),
                    title: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    subtitle: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfAudioReaderPage(
                            filePath: fileName, // ✔ CORRECT
                            pdfId: pdfId,
                            title: title,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
