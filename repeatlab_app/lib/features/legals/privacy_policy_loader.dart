import 'package:flutter/services.dart';

Future<String> getPrivacyPolicy(String langCode) async {
  // get content from assets/data/dataprotection_{langCode}.html

  switch (langCode) {
    case 'de':
      return await rootBundle.loadString('assets/data/dataprotection_de.html');
    case 'es':
      return await rootBundle.loadString('assets/data/dataprotection_es.html');
    case 'fr':
      return await rootBundle.loadString('assets/data/dataprotection_fr.html');
    case 'it':
      return await rootBundle.loadString('assets/data/dataprotection_it.html');
    case 'nl':
      return await rootBundle.loadString('assets/data/dataprotection_nl.html');
    default:
      return await rootBundle.loadString('assets/data/dataprotection_en.html');
  }
}
