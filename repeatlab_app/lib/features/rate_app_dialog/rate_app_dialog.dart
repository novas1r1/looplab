import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:lottie/lottie.dart';
import 'package:repeatlab/core/app_constants.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/rate_app_dialog/widgets/rating_button_row.dart';
import 'package:wiredash/wiredash.dart';

class RateAppDialog extends StatefulWidget {
  const RateAppDialog({
    super.key,
  });

  @override
  State<RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<RateAppDialog>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleRatingChanged(int rating) {
    setState(() {
      _selectedRating = rating;
    });
  }

  Widget _buildActionButton() {
    if (_selectedRating == null) return const SizedBox.shrink();

    if (_selectedRating! >= 4) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: () => _sendStoreRating(_selectedRating!),
        iconAlignment: IconAlignment.end,
        child: const Text('Send Rating'),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: () => _sendStoreRating(_selectedRating!),
          icon: const Icon(Icons.send),
          iconAlignment: IconAlignment.end,
          label: const Text('Send Rating'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _sendReview(context),
            child: const Text('Leave Review'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LottieBuilder.asset(
                  'assets/animations/lottie_stars.json',
                  controller: _animationController
                    ..forward()
                    ..repeat(),
                ),
              ),
              Expanded(
                child: LottieBuilder.asset(
                  'assets/animations/lottie_stars.json',
                  controller: _animationController
                    ..forward()
                    ..repeat(),
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 62),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.displaySmall,
                  children: [
                    const TextSpan(
                      text: 'Your Feedback helps me to add the features',
                    ),
                    TextSpan(
                      text: ' you ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: 'want'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox.square(
                        dimension: MediaQuery.sizeOf(context).width * 0.5,
                        child: Image.asset(
                          'assets/images/me.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Hi! I'm the creator of this app. Loving the app? A quick 5-star review would mean the world to me 😊! It motivates me to add more cool features for you.\nThank you! ❤️",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    RatingButtonRow(
                      onChangedRating: _handleRatingChanged,
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Not Now'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendStoreRating(int rating) async {
    final inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();

      if (mounted) {
        context.read<LocalConfigRepository>().setHasRatedApp(true);
        Navigator.of(context).pop();
      }
    } else {
      await inAppReview.openStoreListing(appStoreId: AppConstants.appStoreId);

      if (mounted) {
        context.read<LocalConfigRepository>().setHasRatedApp(true);
        Navigator.of(context).pop();
      }
    }
  }

  void _sendReview(BuildContext context) {
    Wiredash.of(context).show();

    if (mounted) {
      context.read<LocalConfigRepository>().setHasRatedApp(true);

      Navigator.of(context).pop();
    }
  }
}
