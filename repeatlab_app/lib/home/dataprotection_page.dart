import 'package:flutter/material.dart';

class DataprotectionPage extends StatelessWidget {
  const DataprotectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Protection'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                'Overview',
                'We take your privacy seriously. This policy describes what personal information we collect and how we use it.',
              ),
              _buildSection(
                context,
                'User Feedback (Wiredash)',
                'We use Wiredash to collect user feedback and improve our app. When you submit feedback:'
                    '\n\n• Screenshots you choose to share'
                    '\n• Device information for bug reporting'
                    '\n• Any text feedback you provide'
                    '\n\nWiredash is GDPR compliant and hosted in the EU.',
              ),
              _buildSection(
                context,
                'Analytics (PostHog)',
                'We use PostHog to understand app usage patterns:'
                    '\n\n• Basic usage statistics'
                    '\n• Feature interaction data'
                    '\n• Performance metrics'
                    '\n\nThis helps us improve the app experience. Data is anonymized where possible.',
              ),
              _buildSection(
                context,
                'Purchases (RevenueCat)',
                'For processing in-app purchases, we use RevenueCat:'
                    '\n\n• Purchase history'
                    '\n• Subscription status'
                    '\n• Transaction information'
                    '\n\nThis information is necessary to provide access to purchased features.',
              ),
              _buildSection(
                context,
                'Your Rights',
                'You have the right to:'
                    '\n\n• Access your personal data'
                    '\n• Request data deletion'
                    '\n• Opt out of analytics'
                    '\n• Request data correction'
                    '\n\nContact us for any privacy-related concerns.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
