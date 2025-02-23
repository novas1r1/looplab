import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/app_constants.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/snackbar_helper.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';
import 'package:repeatlab/features/paywall/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumScreen extends StatelessWidget {
  @visibleForTesting
  final FetchProductsCubit? fetchProductsCubit;

  const PremiumScreen({
    super.key,
    @visibleForTesting this.fetchProductsCubit,
  });

  @override
  Widget build(BuildContext context) {
    return (fetchProductsCubit != null)
        ? BlocProvider.value(
            value: fetchProductsCubit!,
            child: const _PremiumView(),
          )
        : BlocProvider(
            create: (context) => FetchProductsCubit(
              crashReportingRepository: context.read<CrashReportingRepository>(),
              purchasesRepository: context.read<PurchasesRepository>(),
            )..fetchProducts(),
            child: const _PremiumView(),
          );
  }
}

class _PremiumView extends StatelessWidget {
  const _PremiumView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FetchProductsCubit, FetchProductsState>(
      listener: (context, state) => _onBuildListener(state, context),
      builder: (context, state) => _PremiumLoaded(fetchProductsState: state),
    );
  }

  void _onBuildListener(FetchProductsState state, BuildContext context) {
    if (state.action == FetchProductsAction.purchase) {
      if (state.status == FetchProductsStatus.success) {
        context.read<PremiumSubscriptionCubit>().checkStatus();
        SnackbarHelper.showSuccess(
          context,
          context.l10n.purchaseSuccess,
        );
      } else if (state.status == FetchProductsStatus.failure) {
        SnackbarHelper.showError(
          context,
          state.errorMessage.toString(),
        );
      }
    }
  }
}

class _PremiumLoaded extends StatefulWidget {
  final FetchProductsState fetchProductsState;

  const _PremiumLoaded({
    required this.fetchProductsState,
  });

  @override
  State<_PremiumLoaded> createState() => _PremiumLoadedState();
}

class _PremiumLoadedState extends State<_PremiumLoaded> {
  PlanPeriod _selectedPlan = PlanPeriod.yearly;

  @override
  Widget build(BuildContext context) {
    final yearlyPrice = widget.fetchProductsState.annualPackage?.storeProduct.priceString;
    final lifetimePrice = widget.fetchProductsState.lifetimePackage?.storeProduct.priceString;
    final hasSubscription = context.watch<PremiumSubscriptionCubit>().state.status ==
        PremiumSubscriptionStatus.subscribed;
    final hasLifetimePurchase = context.watch<PremiumSubscriptionCubit>().state.status ==
        PremiumSubscriptionStatus.lifetimePurchased;

    // yearly box should be selected if yearly was bought OR if lifetime was NOT bought and box was selected
    final yearlySelected =
        hasSubscription || (!hasLifetimePurchase && _selectedPlan == PlanPeriod.yearly);
    final lifetimeSelected =
        hasLifetimePurchase || (!hasSubscription && _selectedPlan == PlanPeriod.lifetime);

    return SafeArea(
      child: Scaffold(
        body: ListView(
          children: [
            Stack(
              children: [
                Image.asset('assets/images/header_2.png'),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.premiumHeadline,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 16),
                  FeatureTile(title: context.l10n.premiumFeatureUnlimitedLoops),
                  FeatureTile(title: context.l10n.premiumFeatureChangeMusicSpeed),
                  FeatureTile(title: context.l10n.premiumFeatureZoomInOut),
                  FeatureTile(title: context.l10n.premiumFeatureSupportDeveloper),
                  const SizedBox(height: 16),
                  // package yearly with title, subtitle, border if selected
                  PackageWidget(
                    period: PlanPeriod.yearly,
                    isSelected: yearlySelected,
                    onSelected: () => setState(() => _selectedPlan = PlanPeriod.yearly),
                    priceString: yearlyPrice ?? context.l10n.notAvailable,
                    hasSubscription: hasSubscription,
                    hasLifetimePurchase: hasLifetimePurchase,
                  ),

                  const SizedBox(height: 16),
                  // package lifetime with title, subtitle, border if selected
                  PackageWidget(
                    period: PlanPeriod.lifetime,
                    isSelected: lifetimeSelected,
                    onSelected: () => setState(() => _selectedPlan = PlanPeriod.lifetime),
                    priceString: lifetimePrice ?? context.l10n.notAvailable,
                    hasSubscription: hasSubscription,
                    hasLifetimePurchase: hasLifetimePurchase,
                  ),

                  const SizedBox(height: 16),

                  if (_selectedPlan == PlanPeriod.yearly) ...[
                    Text(
                      context.l10n.cancelAnytime,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: !hasSubscription &&
                            !hasLifetimePurchase &&
                            widget.fetchProductsState.annualPackage != null &&
                            widget.fetchProductsState.lifetimePackage != null
                        ? () {
                            if (_selectedPlan == PlanPeriod.yearly) {
                              context.read<FetchProductsCubit>().purchase(
                                    widget.fetchProductsState.annualPackage!,
                                  );
                            } else if (_selectedPlan == PlanPeriod.lifetime) {
                              context.read<FetchProductsCubit>().purchase(
                                    widget.fetchProductsState.lifetimePackage!,
                                  );
                            }
                          }
                        : null,
                    child: !hasSubscription && !hasLifetimePurchase
                        ? Text(context.l10n.purchase)
                        : Text(context.l10n.purchasedAlready),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Restore
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // restore
                            // TODO(Verena): what to do here?
                            //launchUrl(Uri.parse(AppConstants.urlRestore));
                            context.read<PremiumSubscriptionCubit>().restore();
                          },
                          child: FittedBox(child: Text(context.l10n.restore)),
                        ),
                      ),
                      // Terms

                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // open terms and conditions
                            launchUrl(Uri.parse(AppConstants.urlTermsAndConditions));
                          },
                          child: FittedBox(child: Text(context.l10n.terms)),
                        ),
                      ),
                      // Privacy

                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            launchUrl(Uri.parse(AppConstants.urlPrivacyPolicy));
                          },
                          child: FittedBox(child: Text(context.l10n.privacy)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PackageWidget extends StatelessWidget {
  final PlanPeriod period;
  final bool isSelected;
  final bool hasSubscription;
  final bool hasLifetimePurchase;
  final VoidCallback onSelected;
  final String priceString;

  const PackageWidget({
    super.key,
    required this.period,
    required this.isSelected,
    required this.onSelected,
    required this.priceString,
    required this.hasSubscription,
    required this.hasLifetimePurchase,
  });

  @override
  Widget build(BuildContext context) {
    final bool isApple = Platform.isIOS;

    return GestureDetector(
      onTap: () => onSelected(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'RepeatLab Pro ${period.name}',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (period == PlanPeriod.yearly)
                        Text(
                          context.l10n.yearlyDescription(priceString, isApple ? '3' : '5'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      if (period == PlanPeriod.lifetime)
                        Text(
                          context.l10n.lifetimeDescription,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (period == PlanPeriod.yearly)
                  Text(
                    "$priceString/${context.l10n.year}",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                if (period == PlanPeriod.lifetime)
                  Text(
                    priceString,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
              ],
            ),
            if (hasSubscription && period == PlanPeriod.yearly) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () {
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
                },
                child: Text(context.l10n.cancelSubscription),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final String title;

  const FeatureTile({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        spacing: 16,
        children: [
          Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
          Text(title),
        ],
      ),
    );
  }
}

enum PlanPeriod {
  lifetime,
  yearly,
}
