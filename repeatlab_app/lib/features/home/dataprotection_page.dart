import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:repeatlab/core/ui/widgets/loading.dart';
import 'package:repeatlab/features/legals/privacy_policy_loader.dart';
import 'package:repeatlab/l10n/l10n.dart';

class DataprotectionPage extends StatefulWidget {
  const DataprotectionPage({super.key});

  @override
  State<DataprotectionPage> createState() => _DataprotectionPageState();
}

class _DataprotectionPageState extends State<DataprotectionPage> {
  @override
  Widget build(BuildContext context) {
    // get current language
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.dataProtection),
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: getPrivacyPolicy(langCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Loading());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading privacy policy: ${snapshot.error}'),
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
