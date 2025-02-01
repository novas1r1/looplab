import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:lottie/lottie.dart';
import 'package:repeatlab/core/app_constants.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/rate_app_dialog/widgets/rating_button_row.dart';
import 'package:repeatlab/l10n/l10n.dart';
import 'package:wiredash/wiredash.dart';

class RateAppDialog extends StatefulWidget {
  const RateAppDialog({
    super.key,
  });

  @override
  State<RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<RateAppDialog> with TickerProviderStateMixin {
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
        child: Text(
          context.l10n.sendRating,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: () => _sendStoreRating(_selectedRating!),
          icon: const Icon(Icons.send),
          iconAlignment: IconAlignment.end,
          label: Text(
            context.l10n.sendRating,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _sendReview(context),
            child: Text(
              context.l10n.leaveReview,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
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
                    TextSpan(
                      text: context.l10n.yourFeedbackHelpsMe,
                    ),
                    TextSpan(
                      text: context.l10n.you,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: context.l10n.want),
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
                      context.l10n.rateDialogDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
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
                      child: Text(context.l10n.notNow),
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
