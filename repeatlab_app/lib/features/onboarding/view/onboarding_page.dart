import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/app/router.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/l10n/l10n.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  bool _privacyAccepted = false;
  int _currentPage = 0;

  List<OnboardingSlide> _slides = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _slides = [
      OnboardingSlide(
        title: context.l10n.onboardingTitle1,
        description: context.l10n.onboardingDescription1,
        icon: Icons.music_note,
      ),
      OnboardingSlide(
        title: context.l10n.onboardingTitle2,
        description: context.l10n.onboardingDescription2,
        icon: Icons.loop,
      ),
      OnboardingSlide(
        title: context.l10n.onboardingTitle3,
        description: context.l10n.onboardingDescription3,
        icon: Icons.security,
        isPrivacySlide: true,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => _buildDotIndicator(index),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_currentPage == _slides.length - 1) ...[
                    Row(
                      children: [
                        Checkbox(
                          value: _privacyAccepted,
                          onChanged: (value) {
                            setState(() {
                              _privacyAccepted = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: context.l10n.onboardingPrivacyPolicy,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                TextSpan(
                                  recognizer: TapGestureRecognizer()..onTap = _showPrivacyPolicy,
                                  text: context.l10n.onboardingPrivacyPolicyLink,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        decoration: TextDecoration.underline,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _currentPage == _slides.length - 1
                          ? (_privacyAccepted ? _finishOnboarding : null)
                          : () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? context.l10n.onboardingGetStarted
                            : context.l10n.onboardingNext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _finishOnboarding() async {
    final localConfig = context.read<LocalConfigRepository>();

    await localConfig.setIntroShown(wasShown: true);

    if (mounted) {
      Navigator.of(context)
          .pushReplacement(AppRouter.generateRoute(const RouteSettings(name: '/')));
    }
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).pushNamed('/privacy');
  }

  Widget _buildSlide(OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            slide.icon,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final bool isPrivacySlide;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    this.isPrivacySlide = false,
  });
}
