import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/feedback_view_model.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedbackViewModel(),
      child: const FeedbackScreenContent(),
    );
  }
}

class FeedbackScreenContent extends StatefulWidget {
  const FeedbackScreenContent({super.key});

  @override
  State<FeedbackScreenContent> createState() => _FeedbackScreenContentState();
}

class _FeedbackScreenContentState extends State<FeedbackScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = '';
  int _rating = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FeedbackViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  hintText: 'z.B. Bug in der Freundesliste',
                ),
                validator: viewModel.validateTitle,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  hintText: 'Beschreibe dein Feedback so genau wie möglich',
                ),
                maxLines: 5,
                validator: viewModel.validateDescription,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategorie'),
                items:
                    viewModel.categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                  });
                },
                validator: viewModel.validateCategory,
              ),
              const SizedBox(height: 16),
              const Text('Bewertung'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    if (viewModel.validateRating(_rating) != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bitte gib eine Bewertung ein'),
                        ),
                      );
                      return;
                    }

                    try {
                      await viewModel.sendFeedback(
                        title: _titleController.text,
                        description: _descriptionController.text,
                        category: _selectedCategory,
                        rating: _rating,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Feedback erfolgreich gesendet'),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fehler: ${e.toString()}')),
                        );
                      }
                    }
                  }
                },
                child: const Text('Feedback senden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
