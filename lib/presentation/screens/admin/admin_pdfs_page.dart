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

  String extractFileName(String fullUrl) {
    return fullUrl.split("/").last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "PDF Library",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pdfList.isEmpty
          ? const Center(
              child: Text(
                "No PDFs uploaded",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pdfList.length,
              itemBuilder: (context, index) {
                final pdf = pdfList[index];

                final title = pdf['title'] ?? "Untitled";
                final category = pdf['category'] ?? "General";
                final thumbUrl = pdf['thumbnail_url'];
                final fileUrl = pdf['file_url'];
                final pdfId = pdf['id'];

                final fileName = extractFileName(fileUrl);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfAudioReaderPage(
                            filePath: fileName,
                            pdfId: pdfId,
                            title: title,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: thumbUrl != null
                                ? Image.network(
                                    thumbUrl,
                                    width: 70,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 70,
                                    height: 90,
                                    color: Colors.white10,
                                    child: const Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.redAccent,
                                      size: 40,
                                    ),
                                  ),
                          ),

                          const SizedBox(width: 14),

                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Category chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
