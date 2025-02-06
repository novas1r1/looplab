import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/app_constants.dart';
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
    final premiumState = context.watch<PremiumSubscriptionCubit>().state;

    final yearlyPrice = widget.fetchProductsState.annualPackage?.storeProduct.priceString;
    final lifetimePrice = widget.fetchProductsState.lifetimePackage?.storeProduct.priceString;

    return SafeArea(
      child: Scaffold(
        body: ListView(
          children: [
            Image.asset('assets/images/header_2.png'),
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
                    isSelected: _selectedPlan == PlanPeriod.yearly,
                    onSelected: () => setState(() => _selectedPlan = PlanPeriod.yearly),
                    priceString: yearlyPrice ?? 'Not available',
                  ),

                  const SizedBox(height: 16),
                  // package lifetime with title, subtitle, border if selected
                  PackageWidget(
                    period: PlanPeriod.lifetime,
                    isSelected: _selectedPlan == PlanPeriod.lifetime,
                    onSelected: () => setState(() => _selectedPlan = PlanPeriod.lifetime),
                    priceString: lifetimePrice ?? 'Not available',
                  ),

                  const SizedBox(height: 16),
                  if (_selectedPlan == PlanPeriod.yearly) ...[
                    Text(
                      "You can cancel anytime before the trial ends in Google Play settings to avoid being charged.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () {
                      if (_selectedPlan == PlanPeriod.yearly) {
                        context.read<FetchProductsCubit>().purchase(
                              widget.fetchProductsState.annualPackage!,
                            );
                      } else if (_selectedPlan == PlanPeriod.lifetime) {
                        context.read<FetchProductsCubit>().purchase(
                              widget.fetchProductsState.lifetimePackage!,
                            );
                      }
                    },
                    child: const Text('Purchase'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Restore
                      TextButton(
                        onPressed: () {
                          // restore
                          // TODO(Verena): what to do here?
                          //launchUrl(Uri.parse(AppConstants.urlRestore));
                          context.read<PremiumSubscriptionCubit>().restore();
                        },
                        child: const Text('Restore'),
                      ),
                      // Terms

                      TextButton(
                        onPressed: () {
                          // open terms and conditions
                          launchUrl(Uri.parse(AppConstants.urlTermsAndConditions));
                        },
                        child: const Text('Terms'),
                      ),
                      // Privacy
                      TextButton(
                        onPressed: () {
                          launchUrl(Uri.parse(AppConstants.urlPrivacyPolicy));
                        },
                        child: const Text('Privacy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ), /* SingleChildScrollView(

          child: Stack(
            children: [
              Transform.translate(
                offset: const Offset(0, -120),
                child: Transform.scale(
                  scale: 2,
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      height: 200,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      context.l10n.premiumDescription,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Image.asset(
                      'assets/images/badge_pro_large.png',
                      height: 100,
                      semanticLabel: 'Image Premium Badge',
                    ),
                    AppSpacings.sbh16,
                    ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => const Divider(),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paidFeatures.length,
                      itemBuilder: (context, index) =>
                          FeatureTile(title: _paidFeatures[index].title),
                    ),
                    AppSpacings.sbh16,
                    ContentBox(
                      child: _displayMonhtlyOffer(premiumState.status),
                    ).animate().shimmer(
                          delay: const Duration(milliseconds: 500),
                          duration: const Duration(milliseconds: 700),
                        ),
                    AppSpacings.sbh16,
                    Stack(
                      children: [
                        ContentBox(
                          child: _displayAnualOffer(premiumState.status),
                        ).animate().shimmer(
                              delay: const Duration(milliseconds: 700),
                              duration: const Duration(milliseconds: 700),
                            ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '30% off',
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SecondaryButton(
                      text: context.l10n.close,
                      onPressed: _onPressedClose(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ), */
      ),
    );
  }

  /*Future<void> _onCancelSubscription(
    BuildContext context,
  ) async {
    final result = await DrumbitiousDialogs.showConfirmCancelDialog(
      context: context,
      title: context.l10n.cancelSubscriptionTitle,
      message: context.l10n.cancelSubscriptionText,
      noButtonText: context.l10n.cancel,
      yesButtonText: context.l10n.cancelSubscriptionButton,
    );

    if (result != null && result) { 
      if (Platform.isIOS) {
        AppAnalytics.trackEvent(
          AppAnalytics.clickCancelSubscriptionIos,
        );
        final uri = Uri.parse(AppConstants.urlIosSubscriptions);
        launchUrl(uri);

      } else {
        AppAnalytics.logEvent(
          name: AppAnalyticsEvent.cancelSubscriptionAndroidClicked,
        );
        final uri = Uri.parse(Config.URL_ANDROID_SUBSCRIPTIONS);
        launchUrl(uri);
      }
    } else {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }*/

  /* void _onPressedClose(BuildContext context) {
    AppAnalytics.logEvent(name: AppAnalyticsEvent.premiumBuyCancelled);
    context.pop();
  } */

  /* String _getLifetimePriceText(
    Package? package,
    AppLocalizations translator,
  ) {
    if (package == null) return 'NO PRICE';

    return '${translator.premiumHints5Days} '
        '${package.storeProduct.priceString}'
        '${translator.premiumHintsMonthly}';
  } */

  /*  String _getAnnualPriceText(
    Package? package,
    AppLocalizations translator,
  ) {
    if (package == null) return 'NO PRICE';

    return '${translator.premiumHints14Days} '
        '${package.storeProduct.priceString}'
        '${translator.premiumHintsAnnual}';
  } */

  /* Widget _displayMonhtlyOffer(PremiumSubscriptionStatus premiumStatus) {
    switch (widget.fetchProductsState.status) {
      case FetchProductsStatus.loading:
        return const CircularProgressIndicator();
      case FetchProductsStatus.success:
      case FetchProductsStatus.failure:
        return Column(
          children: [
            PremiumPrice(
              monthlyPackage: widget.fetchProductsState.monthlyPackage,
              annualPackage: widget.fetchProductsState.annualPackage,
              planPeriod: PlanPeriod.monthly,
            ),
            AppSpacings.sbh8,
            Text(
              _getMonthlyPriceText(
                widget.fetchProductsState.monthlyPackage,
                context.l10n,
              ),
            ),
            AppSpacings.sbh16,
            PrimaryButton(
              prefixIcon: const Icon(
                DrumbitiousIcons.ic_diamond,
                color: Colors.white,
              ),
              text: premiumStatus == PremiumSubscriptionStatus.subscribed
                  ? context.l10n.buttonAlreadyPurchased
                  : context.l10n.buttonBuyMonthly,
              onPressed: premiumStatus == PremiumSubscriptionStatus.subscribed ||
                      widget.fetchProductsState.monthlyPackage == null
                  ? null
                  : () {
                      AppAnalytics.logEvent(
                        name: AppAnalyticsEvent.premiumBuyMonthlyClicked,
                      );
                      if (widget.fetchProductsState.monthlyPackage != null) {
                        context.read<FetchProductsCubit>().purchase(
                              widget.fetchProductsState.monthlyPackage!,
                            );
                      } else {
                        context.read<CrashReportingRepository>().reportCrash(
                              const PremiumNoOfferAvailableException(),
                            );
                      }
                    },
            ),
          ],
        );
    }
  } */

  /* Widget _displayAnualOffer(PremiumSubscriptionStatus premiumStatus) {
    switch (widget.fetchProductsState.status) {
      case FetchProductsStatus.loading:
        return const AppLoadingWidget();
      case FetchProductsStatus.success:
      case FetchProductsStatus.anonymousAccount:
      case FetchProductsStatus.failure:
        return Column(
          children: [
            PremiumPrice(
              monthlyPackage: widget.fetchProductsState.monthlyPackage,
              annualPackage: widget.fetchProductsState.annualPackage,
              planPeriod: PlanPeriod.annual,
            ),
            AppSpacings.sbh8,
            Text(
              _getAnnualPriceText(
                widget.fetchProductsState.annualPackage,
                context.l10n,
              ),
            ),
            AppSpacings.sbh16,
            PrimaryButton(
              prefixIcon: const Icon(
                DrumbitiousIcons.ic_diamond,
                color: Colors.white,
              ),
              text: premiumStatus == PremiumSubscriptionStatus.subscribed
                  ? context.l10n.buttonAlreadyPurchased
                  : context.l10n.buttonBuyAnnual,
              onPressed: premiumStatus == PremiumSubscriptionStatus.subscribed ||
                      widget.fetchProductsState.annualPackage == null
                  ? null
                  : () {
                      AppAnalytics.logEvent(
                        name: AppAnalyticsEvent.premiumBuyAnnualClicked,
                      );
                      if (widget.fetchProductsState.annualPackage != null) {
                        context.read<FetchProductsCubit>().purchase(
                              widget.fetchProductsState.annualPackage!,
                            );
                      } else {
                        context.read<CrashReportingRepository>().reportCrash(
                              const PremiumNoOfferAvailableException(),
                            );
                      }
                    },
            ),
            if (premiumStatus == PremiumSubscriptionStatus.subscribed) ...[
              AppSpacings.sbh8,
              PrimaryButton(
                prefixIcon: const Icon(Icons.cancel_outlined),
                text: context.l10n.cancelSubscription,
                onPressed: () => _onCancelSubscription(context),
              ),
            ],
          ],
        );
      // return Text(widget.fetchProductsState.exception.toString());
    }
  } */
}

class PackageWidget extends StatelessWidget {
  final PlanPeriod period;
  final bool isSelected;

  final VoidCallback onSelected;
  final String priceString;

  const PackageWidget({
    super.key,
    required this.period,
    required this.isSelected,
    required this.onSelected,
    required this.priceString,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RepeatLab Pro ${period.name}',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (period == PlanPeriod.yearly)
                    Text(
                      '5-day free trial, then $priceString/year. Subscription auto-renews unless canceled in Google Play settings before the trial ends.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (period == PlanPeriod.lifetime)
                    Text(
                      'One-time payment. No subscription required.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (period == PlanPeriod.yearly)
              Text(
                "$priceString/year",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            if (period == PlanPeriod.lifetime)
              Text(
                priceString,
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
