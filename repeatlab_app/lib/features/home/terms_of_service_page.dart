import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:repeatlab/core/ui/widgets/loading.dart';
import 'package:repeatlab/features/legals/terms_of_service_loader.dart';
import 'package:repeatlab/l10n/l10n.dart';

class TermsOfServicePage extends StatefulWidget {
  const TermsOfServicePage({super.key});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  @override
  Widget build(BuildContext context) {
    // get current language
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.onboardingTermsOfServiceLink),
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: getTermsOfService(langCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Loading());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading terms of service: ${snapshot.error}',
                ),
              );
            }

            if (snapshot.hasData) {
              return SingleChildScrollView(
                child: Html(
                  data: snapshot.data,
                ),
              );
            }

            return const Center(child: Text('No data available'));
          },
        ),
      ),
    );
  }
}
