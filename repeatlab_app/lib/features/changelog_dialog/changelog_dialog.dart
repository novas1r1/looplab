import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:repeatlab/features/changelog_dialog/changelog_element.dart';
import 'package:repeatlab/features/changelog_dialog/changelog_version.dart';
import 'package:repeatlab/features/changelog_dialog/small_badge.dart';
import 'package:repeatlab/l10n/l10n.dart';

class ChangelogDialog extends StatefulWidget {
  const ChangelogDialog({
    super.key,
  });

  @override
  State<ChangelogDialog> createState() => _ChangelogDialogState();
}

class _ChangelogDialogState extends State<ChangelogDialog> with TickerProviderStateMixin {
  late final AnimationController _animationController;

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

  @override
  Widget build(BuildContext context) {
    final versions = [
      ChangelogVersion(
        version: '1.1.5',
        releaseDate: DateTime(2025, 04, 23),
        updates: [
          ChangelogElement(
            title: context.l10n.changelog113Title,
            description: context.l10n.changelog113Description,
          ),
        ],
      ),
      ChangelogVersion(
        version: '1.1.0',
        releaseDate: DateTime(2025, 03, 30),
        updates: [
          ChangelogElement(
            title: context.l10n.changelog110Title,
            description: context.l10n.changelog110Description,
          ),
        ],
      ),
      ChangelogVersion(
        version: '1.0.17',
        releaseDate: DateTime(2025, 02, 28),
        updates: [
          ChangelogElement(
            title: context.l10n.changelog1017Title,
            description: context.l10n.changelog1017Description,
            imagePaths: const [
              'assets/images/update_reorder_loop.png',
            ],
          ),
        ],
      ),
      ChangelogVersion(
        version: '1.0.13',
        releaseDate: DateTime(2025, 02, 14),
        updates: [
          ChangelogElement(
            title: context.l10n.changelog1013Title,
            description: context.l10n.changelog1013Description,
            imagePaths: const [
              'assets/images/update_feature_voting.jpeg',
            ],
          ),
        ],
      ),
    ];

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
            children: [
              const SizedBox(height: 75),
              Text(
                context.l10n.changelogTitle,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  // controller: ModalScrollController.of(context),
                  itemCount: versions.length,
                  itemBuilder: (context, index) {
                    final updates = versions[index].updates;

                    return Column(
                      children: [
                        SmallBadge(text: versions[index].version),
                        const SizedBox(height: 16),
                        ...List.generate(
                          updates.length,
                          (index) => ChangelogElement(
                            title: updates[index].title,
                            description: updates[index].description,
                            imagePaths: updates[index].imagePaths,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Semantics(
              label: 'Close',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
