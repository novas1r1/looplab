import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';

/// Holds the user-selected app [Locale]. `null` means "follow system".
class LocaleCubit extends Cubit<Locale?> {
  final LocalConfigRepository localConfigRepository;

  LocaleCubit({required this.localConfigRepository})
    : super(_read(localConfigRepository));

  static Locale? _read(LocalConfigRepository repo) {
    final code = repo.languageCode;
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    await localConfigRepository.setLanguageCode(locale?.languageCode);
    emit(locale);
  }
}
