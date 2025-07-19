import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:repeatlab/features/legals/en_terms_and_conditions.dart';
import 'package:repeatlab/l10n/l10n.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.onboardingTermsOfServiceLink),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Html(
            data: termsOfService,
          ),
        ),
      ),
    );
  }
}
