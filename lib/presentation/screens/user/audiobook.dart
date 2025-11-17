import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class AudiobooksPage extends StatefulWidget {
  const AudiobooksPage({super.key});

  @override
  State<AudiobooksPage> createState() => _AudiobooksPageState();
}

class _AudiobooksPageState extends State<AudiobooksPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = [
    'All',
    'Personal Growth',
    'Productivity',
    'Wellness',
    'Ikigai',
    'Mindfulness',
    'Biography',
  ];

  String selectedCategory = 'All';

  final List<Map<String, dynamic>> audiobooks = [
    {
      "title": "The Growth Mindset",
      "author": "Carol Dweck",
      "duration": "—",
      "progress": 0.75,
      "cover": "assets/books/book1.png",
    },
    {
      "title": "Atomic Habits",
      "author": "James Clear",
      "duration": "5 hr 45 min",
      "progress": 0.5,
      "cover": "assets/books/book2.png",
    },
    {
      "title": "Ikigai",
      "author": "Héctor Garcia & Francesc Miralles",
      "duration": "4 hr 15 min",
      "progress": 0.2,
      "cover": "assets/books/book3.png",
    },
    {
      "title": "The Power of Now",
      "author": "Eckhart Tolle",
      "duration": "—",
      "progress": 0.2,
      "cover": "assets/books/book4.png",
    },
    {
      "title": "Deep Work",
      "author": "Cal Newport",
      "duration": "7 hr 00 min",
      "progress": 0.1,
      "cover": "assets/books/book5.png",
    },
    {
      "title": "Becoming",
      "author": "Michelle Obama",
      "duration": "15 hr 00 min",
      "progress": 0.5,
      "cover": "assets/books/book6.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredBooks = selectedCategory == 'All'
        ? audiobooks
        : audiobooks.where((book) {
            return book['title'].toString().toLowerCase().contains(
                  selectedCategory.toLowerCase(),
                ) ||
                book['author'].toString().toLowerCase().contains(
                  selectedCategory.toLowerCase(),
                );
          }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "AUDIOBOOKS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // 🔍 Search Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Search Audiobooks...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.grey),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 🔹 Category Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat == selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Audiobook Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: filteredBooks.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                  itemBuilder: (context, index) {
                    final book = filteredBooks[index];
                    return _AudiobookCard(
                      title: book['title'],
                      author: book['author'],
                      duration: book['duration'],
                      progress: book['progress'],
                      cover: book['cover'],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // 🔸 Bottom Navigation Bar
    );
  }
}

//
// 🔹 Audiobook Card Widget
//
class _AudiobookCard extends StatelessWidget {
  final String title;
  final String author;
  final String duration;
  final double progress;
  final String cover;

  const _AudiobookCard({
    required this.title,
    required this.author,
    required this.duration,
    required this.progress,
    required this.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Placeholder
              Container(
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                  image: DecorationImage(
                    image: AssetImage(cover),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'by $author',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Spacer(),
              Text(
                duration,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 6),
              LinearPercentIndicator(
                lineHeight: 6,
                percent: progress,
                progressColor: const Color(0xFF1E3A8A),
                backgroundColor: Colors.grey[200],
                barRadius: const Radius.circular(6),
              ),
              const SizedBox(height: 4),
              Text(
                "${(progress * 100).round()}% Completed",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
