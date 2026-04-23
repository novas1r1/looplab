import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/features/locale/cubit/locale_cubit.dart';
import 'package:repeatlab/l10n/arb/app_localizations.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Native-script names for each supported language code.
/// Kept outside the AppLocalizations so each language displays in its own
/// script regardless of the currently active app language.
const Map<String, String> _nativeLanguageNames = {
  'ar': 'العربية',
  'de': 'Deutsch',
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'hi': 'हिन्दी',
  'it': 'Italiano',
  'ja': '日本語',
  'ko': '한국어',
  'nl': 'Nederlands',
  'pl': 'Polski',
  'pt': 'Português',
  'ru': 'Русский',
  'sv': 'Svenska',
  'tr': 'Türkçe',
  'zh': '中文',
};

String nativeLanguageNameOf(Locale locale) =>
    _nativeLanguageNames[locale.languageCode] ?? locale.languageCode;

class LanguagePickerDialog extends StatelessWidget {
  const LanguagePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<LocaleCubit>().state;

    return SimpleDialog(
      title: Text(context.l10n.language),
      children: [
        _LanguageTile(
          label: context.l10n.systemDefault,
          isSelected: selected == null,
          onTap: () => _select(context, null),
        ),
        for (final locale in AppLocalizations.supportedLocales)
          _LanguageTile(
            label: nativeLanguageNameOf(locale),
            isSelected: selected?.languageCode == locale.languageCode,
            onTap: () => _select(context, locale),
          ),
      ],
    );
  }

  Future<void> _select(BuildContext context, Locale? locale) async {
    AppAnalytics.trackEvent(
      AppAnalytics.changeLanguage,
      data: {'language_code': locale?.languageCode ?? 'system'},
    );
    await context.read<LocaleCubit>().setLocale(locale);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onTap,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (isSelected) const Icon(Icons.check),
        ],
      ),
    );
  }
}
