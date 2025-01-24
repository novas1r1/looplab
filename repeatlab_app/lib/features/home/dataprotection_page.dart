import 'package:flutter/material.dart';

class DataprotectionPage extends StatelessWidget {
  const DataprotectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                'Information We Collect',
                'Your privacy is important to us. This Privacy Policy outlines how we collect, use, and protect your information when you use our mobile application (the "App"), which is available on iOS and Android platforms. This policy is compliant with the General Data Protection Regulation (GDPR).\n\n'
                    'Effective Date: 23. January 2025',
              ),
              _buildSection(
                context,
                'Data Controller',
                'The data controller responsible for your information is:\n\n'
                    'Verena Zaiser\n'
                    'Reichenbachstr. 17\n'
                    '70372 Stuttgart\n\n'
                    'Email: support@repeatlab.de',
              ),
              _buildSection(
                context,
                'Information We Collect',
                '• Personal Information: Information you provide to us, such as your email address when submitting feedback via Wiredash.\n'
                    '• Payment Information: Data related to in-app purchases and subscriptions, processed by RevenueCat.\n'
                    '• Crash Logs: Information about app errors and crashes, collected through Sentry.\n'
                    '• Usage Data: Analytics data to help us improve your experience.',
              ),
              _buildSection(
                context,
                'Legal Basis for Processing',
                'We process your data based on the following legal bases:\n\n'
                    '• Your consent for feedback submissions via Wiredash and app analytics.\n'
                    '• Performance of a contract for processing payments and managing subscriptions through RevenueCat.\n'
                    '• Our legitimate interest in ensuring the App operates effectively by using Sentry for crash reporting.',
              ),
              _buildSection(
                context,
                'How We Use Your Information',
                'We use the information we collect for the following purposes:\n\n'
                    '• To process in-app purchases and manage subscriptions through RevenueCat.\n'
                    '• To gather feedback and improve the App using Wiredash.\n'
                    '• To monitor and fix issues using Sentry crash logging.\n'
                    '• To improve user experience and enhance App features.',
              ),
              _buildSection(
                context,
                'Your Rights',
                'Under the GDPR, you have the following rights:\n\n'
                    '• The right to access the personal information we hold about you.\n'
                    '• The right to request corrections to your personal information.\n'
                    '• The right to request deletion of your personal information ("right to be forgotten").\n'
                    '• The right to data portability.\n'
                    '• The right to object to processing based on our legitimate interests.\n'
                    '• The right to withdraw consent at any time.\n'
                    '• The right to lodge a complaint with a supervisory authority.',
              ),
              _buildSection(
                context,
                'Third-Party Services',
                'We use third-party services to enhance our App:\n\n'
                    '• Wiredash: Used to collect user feedback.\n'
                    '• RevenueCat: Used to process in-app purchases and subscriptions.\n'
                    '• Sentry: Used for error monitoring and crash reporting.',
              ),
              _buildSection(
                context,
                'Contact Us',
                'If you have any questions or concerns about this Privacy Policy, or if you wish to exercise your rights under GDPR, please contact us at support@repeatlab.de\n\n'
                    'Thank you for using our App!',
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
