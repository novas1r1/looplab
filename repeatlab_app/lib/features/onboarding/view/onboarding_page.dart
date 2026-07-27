import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/app/router.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  bool _privacyAccepted = false;

  // Optional analytics — GDPR opt-in, so it starts unchecked.
  bool _analyticsAccepted = false;

  int _currentPage = 0;

  List<_OnboardingSlide> _slides = [];

  @override
  void initState() {
    super.initState();
    AppAnalytics.trackEvent(AppAnalytics.viewOnboarding);
    AppAnalytics.trackEvent(AppAnalytics.onboardingStarted);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _consentIndex => _slides.length;

  int get _pageCount => _slides.length + 1;

  bool get _isConsentPage => _currentPage == _consentIndex;

  @override
  Widget build(BuildContext context) {
    _slides = [
      _OnboardingSlide(
        eyebrow: context.l10n.onboardingEyebrow1,
        title: context.l10n.onboardingTitle1,
        description: context.l10n.onboardingDescription1,
        icon: Icons.graphic_eq,
      ),
      _OnboardingSlide(
        eyebrow: context.l10n.onboardingEyebrow2,
        title: context.l10n.onboardingTitle2,
        description: context.l10n.onboardingDescription2,
        icon: Icons.repeat,
      ),
      _OnboardingSlide(
        eyebrow: context.l10n.onboardingEyebrow3,
        title: context.l10n.onboardingTitle3,
        description: context.l10n.onboardingDescription3,
        icon: Icons.speed,
      ),
      _OnboardingSlide(
        eyebrow: context.l10n.onboardingEyebrow4,
        title: context.l10n.onboardingTitle4,
        description: context.l10n.onboardingDescription4,
        icon: Icons.music_note,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pageCount,
                itemBuilder: (context, index) {
                  if (index < _slides.length) {
                    return _buildInfoSlide(_slides[index]);
                  }
                  return _buildConsentSlide();
                },
              ),
            ),
            if (_isConsentPage)
              _buildConsentBottomBar()
            else
              _buildInfoBottomBar(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar: progress indicator + Skip
  // ---------------------------------------------------------------------------

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 20, 6),
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            _buildProgress(),
            const Spacer(),
            if (!_isConsentPage)
              TextButton(
                key: const Key('onboarding.skip'),
                onPressed: _skip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.l10n.onboardingSkip,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_pageCount, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(right: index < _pageCount - 1 ? 7 : 0),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Info slide
  // ---------------------------------------------------------------------------

  Widget _buildInfoSlide(_OnboardingSlide slide) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMedallion(slide.icon),
          const SizedBox(height: 56),
          Text(
            slide.eyebrow.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Oswald',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              letterSpacing: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedallion(IconData icon) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.inversePrimary,
                  borderRadius: BorderRadius.circular(74),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                decoration: BoxDecoration(
                  // rgba(20, 19, 19, 0.35)
                  color: const Color(0x59141313),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Center(
                  child: Icon(icon, size: 64, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Consent slide
  // ---------------------------------------------------------------------------

  Widget _buildConsentSlide() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.shield_outlined, size: 44, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            context.l10n.onboardingConsentTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.onboardingConsentBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _buildConsentCard(
            cardKey: const Key('onboarding.analytics'),
            checked: _analyticsAccepted,
            onTap: () => setState(() => _analyticsAccepted = !_analyticsAccepted),
            title: context.l10n.onboardingAnalyticsTitle,
            body: Text(
              context.l10n.onboardingAnalyticsBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildConsentCard(
            cardKey: const Key('onboarding.privacy'),
            checked: _privacyAccepted,
            onTap: () => setState(() => _privacyAccepted = !_privacyAccepted),
            title: context.l10n.onboardingDataProtectionTitle,
            body: _buildDataProtectionText(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildDataProtectionText(ThemeData theme) {
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
      height: 1.35,
    );
    final linkStyle = baseStyle?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    );
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: context.l10n.onboardingIAccept),
          TextSpan(
            recognizer: TapGestureRecognizer()..onTap = _showPrivacyPolicy,
            text: context.l10n.onboardingPrivacyPolicyLink,
            style: linkStyle,
          ),
          TextSpan(text: context.l10n.and),
          TextSpan(
            recognizer: TapGestureRecognizer()..onTap = _showTermsOfService,
            text: context.l10n.onboardingTermsOfServiceLink,
            style: linkStyle,
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildConsentCard({
    required Key cardKey,
    required bool checked,
    required VoidCallback onTap,
    required String title,
    required Widget body,
  }) {
    return InkWell(
      key: cardKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: checked ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckIndicator(checked),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  body,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckIndicator(bool checked) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: checked ? AppColors.primary : AppColors.outline,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bars
  // ---------------------------------------------------------------------------

  Widget _buildInfoBottomBar() {
    final isLastInfo = _currentPage == _slides.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
      child: Row(
        children: [
          _buildBackButton(enabled: _currentPage > 0),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton(
                key: const Key('onboarding.next'),
                style: _primaryButtonStyle(),
                onPressed: _advance,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLastInfo
                          ? context.l10n.onboardingContinue
                          : context.l10n.onboardingNext,
                    ),
                    const SizedBox(width: 8),
                    Icon(isLastInfo ? Icons.check : Icons.arrow_forward, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const Key('onboarding.next'),
              style: _primaryButtonStyle(),
              onPressed: _privacyAccepted ? _finishOnboarding : null,
              child: Text(context.l10n.onboardingGetStarted),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.onboardingConsentFootnote,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
      disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(
        fontFamily: 'Nunito Sans',
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }

  Widget _buildBackButton({required bool enabled}) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: enabled ? _back : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Icon(
            Icons.arrow_back,
            size: 24,
            color: AppColors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _advance() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skip() {
    AppAnalytics.trackEvent(
      AppAnalytics.onboardingSkipped,
      data: {'from_page': _currentPage},
    );
    _pageController.animateToPage(
      _consentIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishOnboarding() async {
    final localConfig = context.read<LocalConfigRepository>();

    // Apply consent FIRST so PostHog is opted in before we emit the onboarding
    // funnel events. setAnalyticsEnabled also settles the pre-consent buffer:
    // on opt-in it flushes view_onboarding/onboarding_started (held in memory
    // by AppAnalytics until now), on decline it discards them.
    await localConfig.setIntroShown(wasShown: true);
    await localConfig.setAnalyticsEnabled(isEnabled: _analyticsAccepted);

    AppAnalytics.trackEvent(AppAnalytics.onboardingCompleted);
    if (_analyticsAccepted) {
      AppAnalytics.trackEvent(AppAnalytics.onboardingAnalyticsAccepted);
    }
    // On decline PostHog stays opted out, so an `onboarding_analytics_declined`
    // event could never be delivered anyway — decline is unmeasurable
    // client-side under strict consent, by design.

    if (mounted) {
      // show paywall, after paywall is dismissed, navigate to home
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

      if (!hasWeeklySubscription &&
          !hasYearlySubscription &&
          !hasLifetimePurchased) {
        log('no subscription or lifetime purchase');

        try {
          await context.read<PremiumSubscriptionCubit>().presentPaywall(
            source: 'onboarding',
          );
        } catch (e) {
          log('error presenting paywall: $e');
        }
      } else {
        log('has subscribed or has lifetime purchased');
      }

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(
          AppRouter.generateRoute(const RouteSettings(name: '/')),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).pushNamed('/privacy');
  }

  void _showTermsOfService() {
    Navigator.of(context).pushNamed('/terms');
  }
}

class _OnboardingSlide {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;

  _OnboardingSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
  });
}
