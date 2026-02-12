import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/translation_service.dart';
import '../cubit/translation_cubit.dart';
import '../cubit/translation_state.dart';

/// Settings card for configuring translation
class TranslationSettingsCard extends StatelessWidget {
  const TranslationSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TranslationCubit, TranslationState>(
      builder: (context, state) {
        if (state is TranslationLoading) {
          return _buildLoadingCard(context, state);
        }

        if (state is TranslationError) {
          return _buildErrorCard(context, state);
        }

        if (state is TranslationReady) {
          return _buildSettingsCard(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context, TranslationLoading state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.translate, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Translation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: state.progress),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, TranslationError state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  'Translation Error',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TranslationCubit>().initialize();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, TranslationReady state) {
    final cubit = context.read<TranslationCubit>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggle
            Row(
              children: [
                const Icon(Icons.translate, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Real-Time Translation',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (state.isNpuAccelerated)
                        Row(
                          children: [
                            Icon(Icons.bolt,
                                size: 14, color: Colors.amber.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'NPU Accelerated',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.amber.shade700),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: state.isEnabled,
                  onChanged: (_) => cubit.toggleEnabled(),
                ),
              ],
            ),

            const Divider(height: 24),

            // Language selection
            AnimatedOpacity(
              opacity: state.isEnabled ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  // Source language with auto-detect hint
                  _LanguageSelector(
                    label: 'Speak in',
                    selectedLanguage: state.sourceLanguage,
                    languages: cubit.getAvailableLanguages(),
                    onChanged: state.isEnabled
                        ? (lang) => cubit.setSourceLanguage(lang)
                        : null,
                    hint: 'Auto-detect coming soon',
                  ),

                  const SizedBox(height: 12),

                  // Arrow with active animation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: state.isEnabled ? Colors.blue : Colors.grey,
                      ),
                      if (state.isEnabled) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Target language
                  _LanguageSelector(
                    label: 'Translate to',
                    selectedLanguage: state.targetLanguage,
                    languages: cubit.getAvailableLanguages(),
                    onChanged: state.isEnabled
                        ? (lang) => cubit.setTargetLanguage(lang)
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Show original toggle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Show original text',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: state.showOriginal,
                        onChanged: state.isEnabled
                            ? (_) => cubit.toggleShowOriginal()
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Privacy note
            Row(
              children: [
                const Icon(Icons.shield, size: 14, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '100% on-device • No data leaves your device',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Language dropdown selector widget
class _LanguageSelector extends StatelessWidget {
  final String label;
  final TranslationLanguage selectedLanguage;
  final List<TranslationLanguage> languages;
  final ValueChanged<TranslationLanguage>? onChanged;
  final String? hint;

  const _LanguageSelector({
    required this.label,
    required this.selectedLanguage,
    required this.languages,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<TranslationLanguage>(
            value: selectedLanguage,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: languages.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Row(
                  children: [
                    Text(_getFlagEmoji(lang.code)),
                    const SizedBox(width: 8),
                    Text(lang.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged != null
                ? (lang) {
                    if (lang != null) onChanged!(lang);
                  }
                : null,
          ),
        ),
      ],
    );
  }

  String _getFlagEmoji(String langCode) {
    switch (langCode) {
      case 'en':
        return '🇺🇸';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'it':
        return '🇮🇹';
      case 'pt':
        return '🇵🇹';
      case 'zh':
        return '🇨🇳';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      case 'ar':
        return '🇸🇦';
      case 'hi':
        return '🇮🇳';
      case 'ru':
        return '🇷🇺';
      case 'vi':
        return '🇻🇳';
      case 'tl':
        return '🇵🇭';
      case 'uk':
        return '🇺🇦';
      default:
        return '🌐';
    }
  }
}
