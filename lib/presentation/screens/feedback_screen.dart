import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/feedback_view_model.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:go_router/go_router.dart';

final feedbackViewModelProvider = ChangeNotifierProvider<FeedbackViewModel>(
  (ref) => FeedbackViewModel(),
);

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final formKey = GlobalKey<FormState>();
  final messageController = TextEditingController();
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Lade Feedback beim Start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedbackViewModelProvider.notifier).loadFeedback();
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(feedbackViewModelProvider.notifier);
    final viewModelState = ref.watch(feedbackViewModelProvider);
    final authState = ref.watch(authViewModelProvider);

    // User-ID aus AuthViewModel holen
    final userId = authState.profile?.uid ?? 'anonymous';
    final isLoggedIn = authState.status == AuthStatus.signedIn;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: const Text('Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Feedback-Formular
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feedback senden',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      // Name-Feld nur anzeigen wenn nicht eingeloggt
                      if (!isLoggedIn) ...[
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name (optional)',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          labelText: 'Nachricht',
                        ),
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
                              index < viewModelState.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              viewModel.setRating(index + 1);
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      if (viewModelState.submitError != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            viewModelState.submitError!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              viewModelState.isSubmitting
                                  ? null
                                  : () async {
                                    if (formKey.currentState?.validate() ??
                                        false) {
                                      if (viewModelState.rating == 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Bitte gib eine Bewertung ab',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      try {
                                        await viewModel.submitFeedback(
                                          userId: userId,
                                          userName:
                                              isLoggedIn
                                                  ? (authState
                                                          .profile
                                                          ?.displayName ??
                                                      'Anonym')
                                                  : (nameController
                                                          .text
                                                          .isNotEmpty
                                                      ? nameController.text
                                                      : 'Anonym'),
                                          message: messageController.text,
                                          rating: viewModelState.rating,
                                          appVersion: null,
                                          platform: null,
                                        );

                                        if (context.mounted &&
                                            viewModelState.submitSuccess) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Feedback erfolgreich gesendet',
                                              ),
                                            ),
                                          );
                                          viewModel.resetSubmitState();
                                          messageController.clear();
                                          nameController.clear();
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Fehler: ${e.toString()}',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                          child:
                              viewModelState.isSubmitting
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Feedback senden'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Feedback-Liste
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Letzte Feedbacks',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildFeedbackList(
                      context,
                      viewModelState,
                      viewModel,
                      userId,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackList(
    BuildContext context,
    FeedbackViewModel viewModelState,
    FeedbackViewModel viewModel,
    String userId,
  ) {
    if (viewModelState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModelState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Fehler: ${viewModelState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(feedbackViewModelProvider.notifier).loadFeedback();
              },
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (viewModelState.entries.isEmpty) {
      return const Center(child: Text('Noch kein Feedback vorhanden.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModelState.entries.length,
      itemBuilder: (context, index) {
        final entry = viewModelState.entries[index];
        final likeCount = viewModelState.likeUserIds[entry.id]?.length ?? 0;
        final userVote = viewModelState.getUserVote(entry.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.userName ?? 'Anonym',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(5, (starIndex) {
                        return Icon(
                          starIndex < entry.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(entry.message),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${entry.createdAt.day}.${entry.createdAt.month}.${entry.createdAt.year}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const Spacer(),
                    // Like/Dislike Buttons
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            userVote == 'like'
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            color: userVote == 'like' ? Colors.blue : null,
                            size: 20,
                          ),
                          onPressed:
                              () => viewModel.likeFeedback(entry.id, userId),
                        ),
                        Text(
                          likeCount.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        IconButton(
                          icon: Icon(
                            userVote == 'dislike'
                                ? Icons.thumb_down
                                : Icons.thumb_down_outlined,
                            color: userVote == 'dislike' ? Colors.red : null,
                            size: 20,
                          ),
                          onPressed:
                              () => viewModel.dislikeFeedback(entry.id, userId),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
