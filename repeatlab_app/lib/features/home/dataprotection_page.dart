import 'package:flutter/material.dart';
import 'package:repeatlab/l10n/l10n.dart';

class DataprotectionPage extends StatelessWidget {
  const DataprotectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.dataProtection),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                context.l10n.informationWeCollect,
                context.l10n.informationWeCollectSummary,
              ),
              _buildSection(
                context,
                context.l10n.dataController,
                context.l10n.dataControllerDescription,
              ),
              _buildSection(
                context,
                context.l10n.informationWeCollect,
                context.l10n.informationWeCollectDescription,
              ),
              _buildSection(
                context,
                context.l10n.legalBasisForProcessing,
                context.l10n.legalBasisForProcessingDescription,
              ),
              _buildSection(
                context,
                context.l10n.howWeUseYourInformation,
                context.l10n.howWeUseYourInformationDescription,
              ),
              _buildSection(
                context,
                context.l10n.yourRights,
                context.l10n.yourRightsDescription,
              ),
              _buildSection(
                context,
                context.l10n.thirdPartyServices,
                context.l10n.thirdPartyServicesDescription,
              ),
              _buildSection(
                context,
                context.l10n.contactUs,
                context.l10n.contactUsDescription,
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
