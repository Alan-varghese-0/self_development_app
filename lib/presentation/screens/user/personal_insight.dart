import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpiritualInsightsPage extends StatefulWidget {
  const SpiritualInsightsPage({super.key});

  @override
  State<SpiritualInsightsPage> createState() => _SpiritualInsightsPageState();
}

class _SpiritualInsightsPageState extends State<SpiritualInsightsPage> {
  String? selectedFeature;

  // Shared State
  void _resetAll() {
    setState(() {
      selectedFeature = null;
      zodiacResult = null;
      zodiacCurrentQ = 0;
      selectedZodiacOption = null;
      zodiacPoints.updateAll((key, value) => 0);
      spiritAnimal = null;
      currentQuestion = 0;
      selectedAnimalOption = null;
      animalPoints.updateAll((key, value) => 0);
      birthStone = null;
      selectedMonth = null;
      lifePathNumber = null;
      chakraResult = null;
      auraResult = null;
      affirmation = null;
    });
  }

  // 🪐 Zodiac Quiz
  int zodiacCurrentQ = 0;
  String? zodiacResult;
  String? selectedZodiacOption;
  final Map<String, int> zodiacPoints = {
    "♈ Aries": 0,
    "♉ Taurus": 0,
    "♊ Gemini": 0,
    "♋ Cancer": 0,
    "♌ Leo": 0,
    "♍ Virgo": 0,
    "♎ Libra": 0,
    "♏ Scorpio": 0,
    "♐ Sagittarius": 0,
    "♑ Capricorn": 0,
    "♒ Aquarius": 0,
    "♓ Pisces": 0,
  };

  final List<Map<String, dynamic>> zodiacQuiz = [
    {
      "q": "How do you face challenges?",
      "options": {
        "♈ Aries": "With bold action and courage",
        "♑ Capricorn": "With patience and planning",
        "♊ Gemini": "By talking and thinking it through",
        "♋ Cancer": "By protecting those I love",
      },
    },
    {
      "q": "What brings you the most joy?",
      "options": {
        "♌ Leo": "Being appreciated and creative",
        "♉ Taurus": "Peace, food, and comfort",
        "♐ Sagittarius": "Adventure and discovery",
        "♓ Pisces": "Helping or inspiring others",
      },
    },
    {
      "q": "Which quality describes you best?",
      "options": {
        "♏ Scorpio": "Intense and mysterious",
        "♎ Libra": "Balanced and fair",
        "♍ Virgo": "Organized and thoughtful",
        "♒ Aquarius": "Unique and visionary",
      },
    },
  ];

  String _zodiacMeaning(String sign) {
    switch (sign) {
      case "♈ Aries":
        return "Energetic, bold, and ambitious.";
      case "♉ Taurus":
        return "Stable, patient, and loyal.";
      case "♊ Gemini":
        return "Curious, adaptable, and expressive.";
      case "♋ Cancer":
        return "Caring, emotional, and intuitive.";
      case "♌ Leo":
        return "Confident, generous, and passionate.";
      case "♍ Virgo":
        return "Practical, analytical, and kind.";
      case "♎ Libra":
        return "Balanced, social, and charming.";
      case "♏ Scorpio":
        return "Mysterious, intense, and brave.";
      case "♐ Sagittarius":
        return "Optimistic, adventurous, and wise.";
      case "♑ Capricorn":
        return "Disciplined, ambitious, and grounded.";
      case "♒ Aquarius":
        return "Visionary, unique, and intellectual.";
      case "♓ Pisces":
        return "Compassionate, artistic, and empathetic.";
      default:
        return "";
    }
  }

  // 🐾 Spirit Animal
  int currentQuestion = 0;
  String? spiritAnimal;
  String? selectedAnimalOption;
  final Map<String, int> animalPoints = {
    "🦁 Lion": 0,
    "🦉 Owl": 0,
    "🐬 Dolphin": 0,
    "🐘 Elephant": 0,
  };

  final List<Map<String, dynamic>> spiritQuestions = [
    {
      "q": "What best describes you?",
      "options": {
        "🦁 Lion": "Brave & Confident",
        "🦉 Owl": "Wise & Observant",
        "🐬 Dolphin": "Playful & Friendly",
        "🐘 Elephant": "Calm & Caring",
      },
    },
    {
      "q": "How do you approach challenges?",
      "options": {
        "🦁 Lion": "Face them head-on",
        "🦉 Owl": "Think before acting",
        "🐬 Dolphin": "Seek support",
        "🐘 Elephant": "Stay patient",
      },
    },
    {
      "q": "What brings you peace?",
      "options": {
        "🦁 Lion": "Winning & leading",
        "🦉 Owl": "Learning & solitude",
        "🐬 Dolphin": "Being social",
        "🐘 Elephant": "Family & stability",
      },
    },
  ];

  // 💎 Birth Stone
  String? selectedMonth;
  String? birthStone;
  String _getBirthStone(String month) {
    switch (month) {
      case "January":
        return "💎 Garnet - symbolizes protection & strength.";
      case "February":
        return "💜 Amethyst - symbolizes calm & clarity.";
      case "March":
        return "💙 Aquamarine - symbolizes peace & courage.";
      case "April":
        return "💎 Diamond - symbolizes purity & love.";
      case "May":
        return "💚 Emerald - symbolizes growth & balance.";
      case "June":
        return "🤍 Pearl - symbolizes harmony & wisdom.";
      case "July":
        return "❤️ Ruby - symbolizes passion & vitality.";
      case "August":
        return "💎 Peridot - symbolizes energy & renewal.";
      case "September":
        return "💙 Sapphire - symbolizes truth & faith.";
      case "October":
        return "🩵 Opal - symbolizes creativity & hope.";
      case "November":
        return "💛 Topaz - symbolizes joy & abundance.";
      case "December":
        return "💙 Turquoise - symbolizes protection & luck.";
      default:
        return "";
    }
  }

  // 🔢 Life Path Number (Numerology)
  String? lifePathNumber;
  void _calculateLifePathNumber(DateTime date) {
    int sum = date.year + date.month + date.day;
    while (sum > 9 && sum != 11 && sum != 22) {
      sum = sum
          .toString()
          .split('')
          .map((e) => int.parse(e))
          .reduce((a, b) => a + b);
    }
    setState(() {
      lifePathNumber = "Your Life Path Number is $sum";
    });
  }

  // 🧘 Chakra Balance Quiz
  String? chakraResult;
  final List<Map<String, dynamic>> chakraQuiz = [
    {
      "q": "Where do you feel your strongest energy?",
      "options": {
        "Root": "Base / Groundedness",
        "Heart": "Love / Compassion",
        "Throat": "Expression / Truth",
        "Third Eye": "Intuition / Vision",
      },
    },
  ];

  // 🌈 Aura Color Quiz
  String? auraResult;
  final List<Map<String, dynamic>> auraQuiz = [
    {
      "q": "What emotion do you feel most often?",
      "options": {
        "💜 Violet": "Spiritual / Creative",
        "💙 Blue": "Peaceful / Calm",
        "💚 Green": "Balanced / Nurturing",
        "❤️ Red": "Passionate / Energetic",
      },
    },
  ];

  // 🌸 Daily Affirmation
  String? affirmation;
  final List<String> affirmations = [
    "You are aligned with your higher self.",
    "Your energy attracts peace and clarity.",
    "You are guided by love and light.",
    "Every breath fills you with purpose.",
    "Your spirit shines brighter each day.",
  ];

  // 🌌 MAIN UI
  @override
  Widget build(BuildContext context) {
    if (selectedFeature == null) return _buildHub();
    switch (selectedFeature) {
      case "zodiac":
        return _buildZodiacQuiz();
      case "spirit":
        return _buildSpiritAnimal();
      case "birthstone":
        return _buildBirthStone();
      case "lifepath":
        return _buildLifePath();
      case "chakra":
        return _buildChakra();
      case "aura":
        return _buildAura();
      case "affirmation":
        return _buildAffirmation();
      default:
        return _buildHub();
    }
  }

  // 🪷 Hub Screen
  Widget _buildHub() {
    final cards = [
      {
        "title": "Zodiac Quiz",
        "icon": Icons.stars,
        "color": Colors.indigo,
        "key": "zodiac",
      },
      {
        "title": "Spirit Animal",
        "icon": Icons.pets,
        "color": Colors.tealAccent,
        "key": "spirit",
      },
      {
        "title": "Birth Stone",
        "icon": Icons.diamond,
        "color": Colors.pinkAccent,
        "key": "birthstone",
      },
      {
        "title": "Life Path Number",
        "icon": Icons.numbers,
        "color": Colors.deepOrangeAccent,
        "key": "lifepath",
      },
      {
        "title": "Chakra Balance",
        "icon": Icons.auto_awesome,
        "color": Colors.deepPurpleAccent,
        "key": "chakra",
      },
      {
        "title": "Aura Color",
        "icon": Icons.color_lens,
        "color": Colors.lightBlueAccent,
        "key": "aura",
      },
      {
        "title": "Daily Affirmation",
        "icon": Icons.self_improvement,
        "color": Colors.amberAccent,
        "key": "affirmation",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A052C),
      appBar: AppBar(
        title: const Text("Spiritual Insights"),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1246), Color(0xFF09041D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, i) {
            final Map<String, dynamic> c = cards[i];
            return InkWell(
              onTap: () => setState(() => selectedFeature = c["key"]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (c["color"] as Color).withOpacity(0.4),
                      Colors.deepPurple.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      color: (c["color"] as Color).withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c["icon"], color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      c["title"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 🌙 Feature Builders
  Widget _buildZodiacQuiz() => _quizTemplate(
    title: "Zodiac Quiz",
    currentQ: zodiacCurrentQ,
    selected: selectedZodiacOption,
    quiz: zodiacQuiz,
    color: Colors.deepPurpleAccent,
    onNext: () {
      setState(() {
        zodiacPoints[selectedZodiacOption!] =
            zodiacPoints[selectedZodiacOption!]! + 1;
        selectedZodiacOption = null;
        if (zodiacCurrentQ < zodiacQuiz.length - 1) {
          zodiacCurrentQ++;
        } else {
          zodiacResult = zodiacPoints.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
        }
      });
    },
    result: zodiacResult == null
        ? null
        : "$zodiacResult - ${_zodiacMeaning(zodiacResult!)}",
  );

  Widget _buildSpiritAnimal() => _quizTemplate(
    title: "Spirit Animal",
    currentQ: currentQuestion,
    selected: selectedAnimalOption,
    quiz: spiritQuestions,
    color: Colors.tealAccent.shade700,
    onNext: () {
      setState(() {
        animalPoints[selectedAnimalOption!] =
            animalPoints[selectedAnimalOption!]! + 1;
        selectedAnimalOption = null;
        if (currentQuestion < spiritQuestions.length - 1) {
          currentQuestion++;
        } else {
          spiritAnimal = animalPoints.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
        }
      });
    },
    result: spiritAnimal,
  );

  Widget _buildBirthStone() {
    final months = DateFormat().dateSymbols.MONTHS
        .takeWhile((m) => m.isNotEmpty)
        .toList();
    return _gradientScaffold(
      title: "Birth Stone Finder",
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: "Select Month",
              border: OutlineInputBorder(),
            ),
            value: selectedMonth,
            items: months
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (val) => setState(() {
              selectedMonth = val;
              birthStone = _getBirthStone(val!);
            }),
          ),
          const SizedBox(height: 40),
          if (birthStone != null) _resultCard(birthStone!),
        ],
      ),
    );
  }

  Widget _buildLifePath() => _gradientScaffold(
    title: "Life Path Number",
    child: Column(
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (picked != null) _calculateLifePathNumber(picked);
          },
          icon: const Icon(Icons.calendar_today),
          label: const Text("Select Your Birth Date"),
        ),
        const SizedBox(height: 40),
        if (lifePathNumber != null) _resultCard(lifePathNumber!),
      ],
    ),
  );

  Widget _buildChakra() => _quizTemplate(
    title: "Chakra Balance",
    quiz: chakraQuiz,
    selected: selectedZodiacOption,
    onNext: () => setState(() => chakraResult = selectedZodiacOption),
    color: Colors.purple,
    result: chakraResult,
  );

  Widget _buildAura() => _quizTemplate(
    title: "Aura Color",
    quiz: auraQuiz,
    selected: selectedZodiacOption,
    onNext: () => setState(() => auraResult = selectedZodiacOption),
    color: Colors.blueAccent,
    result: auraResult,
  );

  Widget _buildAffirmation() {
    affirmation ??= (affirmations..shuffle()).first;
    return _gradientScaffold(
      title: "Daily Affirmation",
      child: Center(child: _resultCard("🌟 $affirmation 🌟")),
    );
  }

  // 🧘 Reusable Quiz Template
  Widget _quizTemplate({
    required String title,
    required List<Map<String, dynamic>> quiz,
    String? selected,
    int currentQ = 0,
    required Function onNext,
    required Color color,
    String? result,
  }) {
    if (result != null) {
      return _gradientScaffold(
        title: title,
        child: Center(child: _resultCard(result)),
      );
    }
    final q = quiz[currentQ];
    return _gradientScaffold(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q["q"],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...q["options"].entries.map((opt) {
            final isSelected = selected == opt.key;
            return Card(
              color: isSelected ? color : Colors.white12,
              child: RadioListTile<String>(
                title: Text(
                  opt.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
                value: opt.key,
                groupValue: selected,
                onChanged: (val) => setState(() => selectedZodiacOption = val),
                activeColor: Colors.white,
              ),
            );
          }),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: selected == null ? null : () => onNext(),
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌙 Helpers
  Widget _resultCard(String text) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      textAlign: TextAlign.center,
    ),
  );

  Widget _gradientScaffold({required String title, required Widget child}) =>
      Scaffold(
        backgroundColor: const Color(0xFF0A052C),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(title),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _resetAll,
            color: Colors.white,
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1246), Color(0xFF09041D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      );
}
