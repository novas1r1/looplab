import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/app/router.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  bool _privacyAccepted = false;
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Welcome to RepeatLab',
      description:
          'Master any song by practicing difficult sections with repeating them or slowing them down.',
      icon: Icons.music_note,
    ),
    OnboardingSlide(
      title: 'Create Smart Loops',
      description:
          'Simply tap to mark the start and end of a section you want to practice. Adjust and fine-tune with our intuitive waveform display.',
      icon: Icons.loop,
    ),
    OnboardingSlide(
      title: 'Privacy First',
      description:
          'We value your privacy and handle your data with care. Please review our privacy policy and accept to continue.',
      icon: Icons.security,
      isPrivacySlide: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
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
                                  text: 'I accept the ',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                TextSpan(
                                  recognizer: TapGestureRecognizer()..onTap = _showPrivacyPolicy,
                                  text: 'Privacy Policy',
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
                        _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
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
