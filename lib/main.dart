import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const FlashcardApp());

class Flashcard {
  final String question;
  final String answer;
  const Flashcard(this.question, this.answer);

  Map<String, String> toJson() => {'q': question, 'a': answer};

  factory Flashcard.fromJson(Map<String, dynamic> json) =>
      Flashcard(json['q'] as String, json['a'] as String);
}

const List<Flashcard> sampleCards = [
  Flashcard('What is Flutter?',
      'An open-source UI toolkit by Google for building apps for mobile, web and desktop from one codebase.'),
  Flashcard('What language does Flutter use?', 'Dart.'),
  Flashcard('What is a Widget?',
      'The basic building block of a Flutter UI. Almost everything on screen is a widget.'),
  Flashcard('StatelessWidget vs StatefulWidget?',
      'A StatelessWidget never changes after it is built. A StatefulWidget holds state that can change and rebuild the UI.'),
];

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcard Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D5A80)),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      ),
      home: const FlashcardScreen(),
    );
  }
}

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  static const String _storageKey = 'flashcards';

  List<Flashcard> _cards = [];
  int _index = 0;
  bool _showAnswer = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    List<Flashcard> cards;
    if (saved == null) {
      cards = List.of(sampleCards);
    } else {
      final list = jsonDecode(saved) as List<dynamic>;
      cards = list
          .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _loading = false;
    });
  }

  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_cards.map((c) => c.toJson()).toList()));
  }

  void _next() {
    if (_cards.isEmpty) return;
    setState(() {
      _index = (_index + 1) % _cards.length;
      _showAnswer = false;
    });
  }

  void _previous() {
    if (_cards.isEmpty) return;
    setState(() {
      _index = (_index - 1 + _cards.length) % _cards.length;
      _showAnswer = false;
    });
  }

  Future<void> _addCard() async {
    final result = await showDialog<Flashcard>(
      context: context,
      builder: (_) => const CardDialog(title: 'Add flashcard'),
    );
    if (result == null) return;
    setState(() {
      _cards.add(result);
      _index = _cards.length - 1;
      _showAnswer = false;
    });
    await _saveCards();
  }

  Future<void> _editCard() async {
    if (_cards.isEmpty) return;
    final result = await showDialog<Flashcard>(
      context: context,
      builder: (_) =>
          CardDialog(title: 'Edit flashcard', existing: _cards[_index]),
    );
    if (result == null) return;
    setState(() => _cards[_index] = result);
    await _saveCards();
  }

  Future<void> _deleteCard() async {
    if (_cards.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this flashcard?'),
        content: Text(_cards[_index].question),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _cards.removeAt(_index);
      if (_index >= _cards.length) _index = _cards.isEmpty ? 0 : _cards.length - 1;
      _showAnswer = false;
    });
    await _saveCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCard,
        icon: const Icon(Icons.add),
        label: const Text('Add card'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _buildEmpty()
              : _buildCardView(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No flashcards yet.\nTap "Add card" to create your first one.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildCardView() {
    final card = _cards[_index];
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Card ${_index + 1} of ${_cards.length}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey('$_index-$_showAnswer-${card.question}-${card.answer}'),
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 260),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: _showAnswer ? const Color(0xFFE3EEF9) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD5DCE4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _showAnswer ? 'Answer' : 'Question',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _showAnswer ? card.answer : card.question,
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.4,
                          color: Color(0xFF1F2A30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => setState(() => _showAnswer = !_showAnswer),
                  child: Text(_showAnswer ? 'Hide Answer' : 'Show Answer'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previous,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _editCard,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _deleteCard,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog used for both adding and editing a flashcard.
class CardDialog extends StatefulWidget {
  final String title;
  final Flashcard? existing;
  const CardDialog({super.key, required this.title, this.existing});

  @override
  State<CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<CardDialog> {
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _questionController =
        TextEditingController(text: widget.existing?.question ?? '');
    _answerController =
        TextEditingController(text: widget.existing?.answer ?? '');
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _save() {
    final q = _questionController.text.trim();
    final a = _answerController.text.trim();
    if (q.isEmpty || a.isEmpty) {
      setState(() => _error = 'Enter both a question and an answer.');
      return;
    }
    Navigator.pop(context, Flashcard(q, a));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _questionController,
                autofocus: true,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _answerController,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Answer',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}