import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:repeatlab/core/app_constants.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/dialog_helper.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';
import 'package:repeatlab/features/changelog_dialog/changelog_dialog.dart';
import 'package:repeatlab/features/home/dataprotection_page.dart';
import 'package:repeatlab/features/home/legal_notices_page.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/paywall/premium_screen.dart';
import 'package:repeatlab/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:userorient_flutter/userorient_flutter.dart';
import 'package:wiredash/wiredash.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appVersion = context.read<PackageInfo>().version;
    final buildNumber = context.read<PackageInfo>().buildNumber;
    final hasSubscribed = context.watch<PremiumSubscriptionCubit>().hasPremium;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'RepeatLab',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.appSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.newspaper),
            title: Text(context.l10n.whatsNew),
            onTap: () async {
              AppAnalytics.trackEvent(AppAnalytics.viewChangelogDialog);

              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                builder: (context) => const ChangelogDialog(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              context.l10n.userSettings,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
            ),
          ),
          FutureBuilder(
            future: context.read<PurchasesRepository>().hasSubscription,
            initialData: false,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              return snapshot.data == true
                  ? ListTile(
                      leading: const Icon(Icons.free_cancellation),
                      title: Text(context.l10n.cancelSubscription),
                      onTap: () {
                        _onCancelSubscription(context);
                      },
                    )
                  : const SizedBox.shrink();
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: Text(context.l10n.buyRepeatLabPro),
            onTap: () {
              AppAnalytics.trackEvent(AppAnalytics.viewPremiumScreen);

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              context.l10n.improveTheApp,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism),
            title: Text(context.l10n.voteForFeatures),
            onTap: () {
              UserOrient.setUser(
                extra: {
                  'appVersion': appVersion,
                  'buildNumber': buildNumber,
                  'isPremium': hasSubscribed,
                },
              );
              UserOrient.openBoard(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: Text(context.l10n.feedback),
            onTap: () {
              Wiredash.of(context).show(inheritMaterialTheme: true);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: Text(context.l10n.rateApp),
            onTap: () async {
              await DialogHelper.displayRateAppDialog(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              context.l10n.legals,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: Text(context.l10n.dataProtection),
            onTap: () {
              Navigator.pop(context);

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DataprotectionPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: Text(context.l10n.legalNotices),
            onTap: () {
              Navigator.pop(context);

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LegalNoticesPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: Text(context.l10n.licenses),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LicensePage(
                    applicationName: 'RepeatLab',
                    applicationVersion: appVersion,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${context.l10n.version} $appVersion ($buildNumber)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCancelSubscription(BuildContext context) {
    // TODO(Verena): Add a confirmation dialog
    /* final result = await DrumbitiousDialogs.showConfirmCancelDialog(
      context: context,
      title: context.l10n.cancelSubscriptionTitle,
      message: context.l10n.cancelSubscriptionText,
      noButtonText: context.l10n.cancel,
      yesButtonText: context.l10n.cancelSubscriptionButton,
    );

    if (result != null && result) { */
    if (Platform.isIOS) {
      AppAnalytics.trackEvent(
        AppAnalytics.clickCancelSubscriptionIos,
      );
      final uri = Uri.parse(AppConstants.urlIosSubscriptions);
      launchUrl(uri);
    } else {
      AppAnalytics.trackEvent(
        AppAnalytics.clickCancelSubscriptionAndroid,
      );
      final uri = Uri.parse(AppConstants.urlAndroidSubscriptions);
      launchUrl(uri);
    }

    /* } else {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    } */
  }
}
