import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jugend_app/domain/viewmodels/feedback_view_model.dart';
import 'package:jugend_app/data/services/device_id_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  int _rating = 5;
  String? _userName;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit(FeedbackViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    final userId = await DeviceIdHelper.getSafeDeviceId();
    await viewModel.submitFeedback(
      userId: userId,
      userName: _userName,
      message: _messageController.text.trim(),
      rating: _rating,
      appVersion: null, // Optional: App-Version einfügen
      platform: null, // Optional: Plattform einfügen
    );
    if (!mounted) return;
    if (viewModel.submitSuccess) {
      _messageController.clear();
      setState(() => _rating = 5);
      FocusScope.of(context).unfocus();
      viewModel.resetSubmitState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.feedbackSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ChangeNotifierProvider(
      create: (_) => FeedbackViewModel()..loadFeedback(),
      child: Consumer<FeedbackViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
              title: Text(l10n.feedbackTitle),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.feedbackFormTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: l10n.feedbackName,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (val) => _userName = val.trim(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: l10n.feedbackMessage,
                            border: const OutlineInputBorder(),
                          ),
                          validator:
                              (val) =>
                                  (val == null || val.trim().isEmpty)
                                      ? l10n.feedbackMessageRequired
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.feedbackRating),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (i) => IconButton(
                              icon: Icon(
                                i < _rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                              ),
                              onPressed: () => setState(() => _rating = i + 1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                viewModel.isSubmitting
                                    ? null
                                    : () => _submit(viewModel),
                            child:
                                viewModel.isSubmitting
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(l10n.feedbackSubmit),
                          ),
                        ),
                        if (viewModel.submitError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              viewModel.submitError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l10n.feedbackListTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (viewModel.isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (viewModel.error != null)
                    Text(
                      viewModel.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (!viewModel.isLoading && viewModel.entries.isEmpty)
                    Text(l10n.feedbackListEmpty),
                  if (viewModel.entries.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: viewModel.entries.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final entry = viewModel.entries[i];
                        return ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                              (j) => Icon(
                                j < entry.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ),
                          title: Text(entry.message),
                          subtitle: Text(
                            entry.userName?.isNotEmpty == true
                                ? entry.userName!
                                : l10n.feedbackAnonymous,
                          ),
                          trailing: Text(
                            '${entry.createdAt.day.toString().padLeft(2, '0')}.${entry.createdAt.month.toString().padLeft(2, '0')}.${entry.createdAt.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
