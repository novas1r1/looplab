import 'package:dart_mappable/dart_mappable.dart';
import 'package:repeatlab/l10n/l10n.dart';

part 'repeatlab_feature.mapper.dart';

@MappableClass()
class RepeatLabFeature with RepeatLabFeatureMappable {
  final String title;
  final bool isPremium;

  const RepeatLabFeature({
    required this.title,
    required this.isPremium,
  });
}

List<RepeatLabFeature> getPremiumFeatures(
  AppLocalizations translator,
) =>
    [
      RepeatLabFeature(
        title: translator.premiumFeatureUnlimitedLoops,
        isPremium: true,
      ),
      RepeatLabFeature(
        title: translator.premiumFeatureChangeMusicSpeed,
        isPremium: true,
      ),
      RepeatLabFeature(
        title: translator.premiumFeatureZoomInOut,
        isPremium: true,
      ),
      RepeatLabFeature(
        title: translator.premiumFeatureSupportDeveloper,
        isPremium: true,
      ),
    ];
