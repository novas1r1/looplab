import 'package:flutter/services.dart';

Future<String> getTermsOfService(String langCode) async {
  // get content from assets/data/termsofservice_{langCode}.html

  switch (langCode) {
    case 'de':
      return await rootBundle.loadString('assets/data/termsofservice_de.html');
    case 'es':
      return await rootBundle.loadString('assets/data/termsofservice_es.html');
    case 'fr':
      return await rootBundle.loadString('assets/data/termsofservice_fr.html');
    case 'it':
      return await rootBundle.loadString('assets/data/termsofservice_it.html');
    case 'nl':
      return await rootBundle.loadString('assets/data/termsofservice_nl.html');
    default:
      return await rootBundle.loadString('assets/data/termsofservice_en.html');
  }
}
