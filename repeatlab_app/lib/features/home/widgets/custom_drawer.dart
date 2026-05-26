import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:repeatlab/core/app_constants.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';
import 'package:repeatlab/features/changelog_dialog/changelog_dialog.dart';
import 'package:repeatlab/features/home/dataprotection_page.dart';
import 'package:repeatlab/features/home/legal_notices_page.dart';
import 'package:repeatlab/features/home/settings_page.dart';
import 'package:repeatlab/features/home/terms_of_service_page.dart';
import 'package:repeatlab/features/locale/cubit/locale_cubit.dart';
import 'package:repeatlab/features/locale/widgets/language_picker_dialog.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
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

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'RepeatLab',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.appSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.newspaper),
            title: Text(
              context.l10n.whatsNew,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            onTap: () async {
              AppAnalytics.trackEvent(AppAnalytics.viewChangelogDialog);

              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.surface,
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
                color: AppColors.onSurface,
              ),
            ),
          ),
          BlocBuilder<PremiumSubscriptionCubit, PremiumSubscriptionState>(
            builder: (context, state) {
              final hasPremium =
                  state.hasWeeklySubscription ||
                  state.hasYearlySubscription ||
                  state.hasLifetimePurchase;
              final hasSubscription =
                  state.hasWeeklySubscription || state.hasYearlySubscription;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasSubscription)
                    ListTile(
                      leading: const Icon(Icons.free_cancellation),
                      title: Text(context.l10n.cancelSubscription),
                      onTap: () {
                        _onCancelSubscription(context);
                      },
                    ),
                  if (!hasPremium)
                    ListTile(
                      leading: const Icon(Icons.shopping_cart),
                      title: Text(context.l10n.buyRepeatLabPro),
                      onTap: () async {
                        AppAnalytics.trackEvent(
                          AppAnalytics.viewPaywallFromDrawer,
                        );
                        await context
                            .read<PremiumSubscriptionCubit>()
                            .presentPaywall();
                      },
                    ),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(context.l10n.settings),
            onTap: () => _onSettings(context),
          ),
          BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, selectedLocale) {
              final subtitle = selectedLocale == null
                  ? context.l10n.systemDefault
                  : nativeLanguageNameOf(selectedLocale);
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(context.l10n.language),
                subtitle: Text(subtitle),
                onTap: () => _onLanguage(context),
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
              AppAnalytics.trackEvent(AppAnalytics.clickVoteForFeatures);
              _onVoteForFeatures(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: Text(context.l10n.feedback),
            onTap: () {
              AppAnalytics.trackEvent(AppAnalytics.clickFeedback);
              AppAnalytics.trackEvent(AppAnalytics.viewFeedback);
              Wiredash.of(context).show(inheritMaterialTheme: true);
              Navigator.pop(context);
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
              AppAnalytics.trackEvent(AppAnalytics.viewDataProtection);
              Navigator.pop(context);

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DataprotectionPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: Text(context.l10n.terms),
            onTap: () {
              AppAnalytics.trackEvent(AppAnalytics.viewTermsOfService);
              Navigator.pop(context);

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TermsOfServicePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: Text(context.l10n.legalNotices),
            onTap: () {
              AppAnalytics.trackEvent(AppAnalytics.viewLegalNotices);
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
              AppAnalytics.trackEvent(AppAnalytics.viewLicenses);
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    final revenueCatUser = await context
                        .read<PurchasesRepository>()
                        .revenueCatUser;

                    if (!context.mounted) return;

                    // display dialog to copy to clipboard
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(context.l10n.copyToClipboard),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(revenueCatUser.originalAppUserId),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  revenueCatUser.activeSubscriptions.join(', '),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final purchaserInfo =
                                        await Purchases.getCustomerInfo();
                                    log(
                                      '--- REVENUECAT: purchaserInfo: $purchaserInfo',
                                    );
                                    log(
                                      '--- REVENUECAT: purchaserInfo.activeSubscriptions: ${purchaserInfo.activeSubscriptions}',
                                    );
                                    log(
                                      '--- REVENUECAT: purchaserInfo.entitlements: ${purchaserInfo.entitlements.all}',
                                    );
                                  },
                                  icon: const Icon(Icons.refresh),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              revenueCatUser.entitlements.all.keys.join(', '),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: revenueCatUser.originalAppUserId,
                                  ),
                                );
                                Navigator.of(context).pop();
                              },
                              child: Text(context.l10n.copyToClipboard),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () async {
                                await context
                                    .read<PremiumSubscriptionCubit>()
                                    .presentPaywall(
                                      ifNeeded: false,
                                    );
                              },
                              child: const Text('Open Paywall'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    '${context.l10n.version} $appVersion ($buildNumber)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
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

  void _onVoteForFeatures(BuildContext context) {
    final appVersion = context.read<PackageInfo>().version;
    final buildNumber = context.read<PackageInfo>().buildNumber;
    final hasWeeklySubscription = context
        .read<PremiumSubscriptionCubit>()
        .state
        .hasWeeklySubscription;
    final hasYearlySubscription = context
        .read<PremiumSubscriptionCubit>()
        .state
        .hasYearlySubscription;
    final hasLifetimePurchased = context
        .read<PremiumSubscriptionCubit>()
        .state
        .hasLifetimePurchase;

    UserOrient.setUser(
      extra: {
        'appVersion': appVersion,
        'buildNumber': buildNumber,
        'hasWeeklySubscription': hasWeeklySubscription,
        'hasYearlySubscription': hasYearlySubscription,
        'hasLifetimePurchased': hasLifetimePurchased,
      },
    );
    UserOrient.openBoard(context);
  }

  void _onSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  Future<void> _onLanguage(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickChangeLanguage);
    final localeCubit = context.read<LocaleCubit>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: localeCubit,
        child: const LanguagePickerDialog(),
      ),
    );
  }
}
