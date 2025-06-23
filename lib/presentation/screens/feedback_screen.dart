import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/feedback_view_model.dart';

final feedbackViewModelProvider = ChangeNotifierProvider<FeedbackViewModel>(
  (ref) => FeedbackViewModel(),
);

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(feedbackViewModelProvider.notifier);
    final formKey = GlobalKey<FormState>();
    final messageController = TextEditingController();
    final nameController = TextEditingController();
    int rating = 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Nachricht'),
                maxLines: 5,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Bitte gib eine Nachricht ein.'
                            : null,
              ),
              const SizedBox(height: 16),
              const Text('Bewertung'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      rating = index + 1;
                    },
                  );
                }),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    try {
                      await viewModel.submitFeedback(
                        userId: '', // Hole UserId aus Auth falls nötig
                        userName: nameController.text,
                        message: messageController.text,
                        rating: rating,
                        appVersion: null,
                        platform: null,
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
