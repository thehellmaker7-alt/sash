import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const PrepRankApp());

class PrepRankApp extends StatelessWidget {
  const PrepRankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PrepRank',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F51D8)),
        scaffoldBackgroundColor: const Color(0xFFF1F3F8),
        cardTheme: const CardThemeData(
          color: Color(0xFFF4F3FB),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class Question {
  final String text;
  final List<String> options;
  final int answer;
  final String explanation;
  const Question(this.text, this.options, this.answer, this.explanation);
}

class Subject {
  final String id, name, description;
  final IconData icon;
  final List<Question> questions;
  const Subject(this.id, this.name, this.description, this.icon, this.questions);
}

const subjects = <Subject>[
  Subject('quant', 'Quantitative Aptitude', 'Percentages, ratios, interest and speed', Icons.calculate_outlined, [
    Question('What is 15% of 240?', ['32', '36', '38', '40'], 1, '15% of 240 = 0.15 × 240 = 36.'),
    Question('A train runs at 60 km/h. How far does it go in 45 minutes?', ['40 km', '45 km', '50 km', '55 km'], 1, 'Distance = 60 × 0.75 = 45 km.'),
    Question('Simple interest on ₹5,000 at 8% per annum for 3 years is:', ['₹1,000', '₹1,200', '₹1,400', '₹1,500'], 1, 'SI = 5000 × 8 × 3 / 100 = ₹1,200.'),
    Question('Two numbers are in the ratio 3:5 and their sum is 64. The larger number is:', ['24', '32', '40', '44'], 2, 'One part = 64 / 8 = 8. Larger number = 5 × 8 = 40.'),
    Question('The average of 12, 18, 24, 30 and 36 is:', ['20', '22', '24', '26'], 2, 'Their sum is 120. Average = 120 / 5 = 24.'),
  ]),
  Subject('reasoning', 'Logical Reasoning', 'Series, relations, coding and directions', Icons.psychology_outlined, [
    Question('Find the next term: 2, 6, 12, 20, 30, ?', ['38', '40', '42', '44'], 2, 'Differences are 4, 6, 8, 10. Next is 30 + 12 = 42.'),
    Question('A is the sister of B, and B is the father of C. How is A related to C?', ['Mother', 'Aunt', 'Grandmother', 'Cousin'], 1, 'A is the sister of C’s father, so A is the aunt.'),
    Question('Pick the odd one out.', ['Apple', 'Mango', 'Carrot', 'Banana'], 2, 'Carrot is a vegetable; the others are fruits.'),
    Question('If CAT is coded as 24 by adding letter values, what is DOG?', ['24', '26', '28', '30'], 1, 'D + O + G = 4 + 15 + 7 = 26.'),
    Question('A man walks 5 km north, 3 km east, then 5 km south. How far is he from the start?', ['3 km', '5 km', '8 km', '13 km'], 0, 'The north and south walks cancel, leaving 3 km east.'),
  ]),
  Subject('gk', 'General Awareness', 'Polity, geography, science and economy', Icons.public, [
    Question('Who chaired the Drafting Committee of the Indian Constitution?', ['Jawaharlal Nehru', 'Dr. B. R. Ambedkar', 'Dr. Rajendra Prasad', 'Sardar Patel'], 1, 'Dr. B. R. Ambedkar chaired the Drafting Committee.'),
    Question('What is the capital of Australia?', ['Sydney', 'Melbourne', 'Canberra', 'Perth'], 2, 'Canberra is the capital of Australia.'),
    Question('Which Article of the Indian Constitution abolishes untouchability?', ['Article 14', 'Article 15', 'Article 17', 'Article 21'], 2, 'Article 17 abolishes untouchability.'),
    Question('Which planet is known as the Red Planet?', ['Venus', 'Mars', 'Jupiter', 'Mercury'], 1, 'Iron oxide on Mars gives it its red colour.'),
    Question('The Reserve Bank of India was established in:', ['1925', '1935', '1947', '1950'], 1, 'The RBI began operations on 1 April 1935.'),
  ]),
  Subject('english', 'English Language', 'Vocabulary, grammar and spelling', Icons.menu_book, [
    Question('Choose the synonym of ABUNDANT.', ['Scarce', 'Plentiful', 'Rare', 'Tiny'], 1, 'Abundant means existing in large quantities.'),
    Question('Choose the antonym of BRAVE.', ['Bold', 'Fearless', 'Cowardly', 'Strong'], 2, 'Cowardly is the opposite of brave.'),
    Question('Fill in the blank: She ___ to school every day.', ['go', 'goes', 'going', 'gone'], 1, 'A third-person singular subject takes “goes”.'),
    Question('One word for “a person who loves books”:', ['Philanthropist', 'Bibliophile', 'Misanthrope', 'Pedant'], 1, 'A bibliophile loves or collects books.'),
    Question('Choose the correct spelling.', ['Acommodation', 'Accomodation', 'Accommodation', 'Acomodation'], 2, 'Accommodation has a double c and a double m.'),
  ]),
];

String clock(int seconds) => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
String marks(double value) => value.toStringAsFixed(2).replaceAll(RegExp(r'\.0+$'), '').replaceAll(RegExp(r'(\.\d*[1-9])0+$'), r'$1');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, double> bestScores = {};

  @override
  void initState() {
    super.initState();
    loadBestScores();
  }

  Future<void> loadBestScores() async {
    final prefs = await SharedPreferences.getInstance();
    final values = <String, double>{};
    for (final subject in subjects) {
      final score = prefs.getDouble('best_${subject.id}');
      if (score != null) values[subject.id] = score;
    }
    final mock = prefs.getDouble('best_mock');
    if (mock != null) values['mock'] = mock;
    if (mounted) setState(() => bestScores = values);
  }

  void startQuiz(String id, String title, List<Question> questions) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => QuizScreen(id: id, title: title, questions: questions, onBestScore: loadBestScores),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final allQuestions = subjects.expand((s) => s.questions).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('PrepRank'), backgroundColor: Colors.transparent),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Practice for SSC, Banking, Railways and State exams', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Timed tests. +1 for a correct answer, −0.25 for a wrong one.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        Card(child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: const Icon(Icons.assignment_outlined, size: 36),
          title: const Text('Full Mock Test', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          subtitle: Text('${allQuestions.length} questions • ${allQuestions.length} minutes • All subjects\n${bestScores['mock'] == null ? '' : 'Best: ${marks(bestScores['mock']!)}'}'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {
            final mixed = List<Question>.from(allQuestions)..shuffle(Random());
            startQuiz('mock', 'Full Mock Test', mixed);
          },
        )),
        const SizedBox(height: 12),
        const Text('Subject tests', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...subjects.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(child: Icon(s.icon)),
            title: Text(s.name),
            subtitle: Text('${s.description}\n${s.questions.length} questions • ${s.questions.length} min${bestScores[s.id] == null ? '' : ' • Best: ${marks(bestScores[s.id]!)}'}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => startQuiz(s.id, s.name, s.questions),
          )),
        )),
      ]),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final String id, title;
  final List<Question> questions;
  final Future<void> Function() onBestScore;
  const QuizScreen({super.key, required this.id, required this.title, required this.questions, required this.onBestScore});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int secondsPerQuestion = 60;
  static const double negativeMark = 0.25;
  late List<int?> answers;
  int current = 0;
  late int remaining;
  late int totalSeconds;
  Timer? timer;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    answers = List<int?>.filled(widget.questions.length, null);
    totalSeconds = widget.questions.length * secondsPerQuestion;
    remaining = totalSeconds;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remaining <= 1) {
        remaining = 0;
        finish();
      } else {
        setState(() => remaining--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  int get correct => List.generate(answers.length, (i) => answers[i] == widget.questions[i].answer ? 1 : 0).fold(0, (a, b) => a + b);
  int get wrong => List.generate(answers.length, (i) => answers[i] != null && answers[i] != widget.questions[i].answer ? 1 : 0).fold(0, (a, b) => a + b);
  int get skipped => answers.where((a) => a == null).length;
  double get score => correct - wrong * negativeMark;
  int get answered => answers.where((a) => a != null).length;
  int get accuracy => correct + wrong == 0 ? 0 : (correct / (correct + wrong) * 100).round();

  Future<void> finish() async {
    if (finished) return;
    finished = true;
    timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final key = 'best_${widget.id}';
    final old = prefs.getDouble(key) ?? -99999;
    if (score > old) await prefs.setDouble(key, score);
    if (!mounted) return;
    await widget.onBestScore();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultScreen(
      title: widget.title, questions: widget.questions, answers: answers,
      correct: correct, wrong: wrong, skipped: skipped, score: score,
      accuracy: accuracy, usedSeconds: totalSeconds - remaining,
    )));
  }

  Future<void> confirmSubmit() async {
    final submit = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Submit test?'),
      content: Text(skipped == 0 ? 'You have answered every question.' : '$skipped question(s) are still unanswered.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep going')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
      ],
    ));
    if (submit == true) await finish();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[current];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis), actions: [
        Padding(padding: const EdgeInsets.only(right: 12), child: Center(child: Chip(
          avatar: const Icon(Icons.timer_outlined, size: 18),
          backgroundColor: remaining < 60 ? Theme.of(context).colorScheme.errorContainer : null,
          label: Text(clock(remaining)),
        ))),
      ]),
      body: Column(children: [
        LinearProgressIndicator(value: answered / widget.questions.length),
        SizedBox(height: 56, child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          scrollDirection: Axis.horizontal,
          itemCount: widget.questions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) => ChoiceChip(
            label: Text('${i + 1}'), selected: current == i,
            avatar: answers[i] == null ? null : const Icon(Icons.check, size: 15),
            onSelected: (_) => setState(() => current = i),
          ),
        )),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Question ${current + 1} of ${widget.questions.length}', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          Text(q.text, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          ...List.generate(q.options.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(shape: RoundedRectangleBorder(
              side: BorderSide(color: answers[current] == i ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
              borderRadius: BorderRadius.circular(14),
            ), child: RadioListTile<int>(
              value: i, groupValue: answers[current],
              onChanged: (value) => setState(() => answers[current] = value),
              title: Text('${'ABCD'[i]}.  ${q.options[i]}'),
            )),
          )),
        ])),
        SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          OutlinedButton(onPressed: current == 0 ? null : () => setState(() => current--), child: const Text('Previous')),
          TextButton(onPressed: answers[current] == null ? null : () => setState(() => answers[current] = null), child: const Text('Clear')),
          const Spacer(),
          if (current < widget.questions.length - 1)
            FilledButton(onPressed: () => setState(() => current++), child: const Text('Next'))
          else
            FilledButton(onPressed: confirmSubmit, child: const Text('Submit')),
        ]))),
      ]),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final String title;
  final List<Question> questions;
  final List<int?> answers;
  final int correct, wrong, skipped, accuracy, usedSeconds;
  final double score;
  const ResultScreen({super.key, required this.title, required this.questions, required this.answers, required this.correct, required this.wrong, required this.skipped, required this.score, required this.accuracy, required this.usedSeconds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$title: Result'), automaticallyImplyLeading: false),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: Theme.of(context).colorScheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
          const Text('Your score'),
          Text('${marks(score)} / ${questions.length}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
          Text('Accuracy $accuracy%  |  Time ${clock(usedSeconds)}'),
        ]))),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _Stat(label: 'Correct', value: '$correct', color: Colors.green),
          _Stat(label: 'Wrong', value: '$wrong', color: Colors.red),
          _Stat(label: 'Skipped', value: '$skipped', color: null),
        ]))),
        const SizedBox(height: 18),
        Text('Review answers', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...List.generate(questions.length, (i) {
          final q = questions[i];
          final a = answers[i];
          final isCorrect = a == q.answer;
          final color = a == null ? Colors.grey : isCorrect ? Colors.green : Colors.red;
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ExpansionTile(
            leading: Icon(a == null ? Icons.remove_circle_outline : isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined, color: color),
            title: Text('Q${i + 1}. ${q.text}'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Align(alignment: Alignment.centerLeft, child: Text(a == null ? 'You skipped this question.' : 'Your answer: ${q.options[a]}', style: TextStyle(color: color))),
              Align(alignment: Alignment.centerLeft, child: Text('Correct answer: ${q.options[q.answer]}', style: const TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(height: 5),
              Align(alignment: Alignment.centerLeft, child: Text(q.explanation, style: const TextStyle(color: Colors.black54))),
            ],
          ));
        }),
        const SizedBox(height: 8),
        FilledButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('Back to home')),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: const TextStyle(fontSize: 12)),
  ]);
}
