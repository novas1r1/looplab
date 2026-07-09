import 'package:flutter/material.dart';

/// App-wide motion tokens. All animations use these durations and curves so
/// motion stays consistent: fast attack, soft decay — like a note envelope.
// ignore: avoid_classes_with_only_static_members
abstract final class Motion {
  /// Press feedback (scale on tap).
  static const xfast = Duration(milliseconds: 100);

  /// Small flips, chips, icon morphs.
  static const fast = Duration(milliseconds: 150);

  /// Most state transitions.
  static const standard = Duration(milliseconds: 250);

  /// Pages, sheets, expand/collapse.
  static const slow = Duration(milliseconds: 400);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Rare one-shot "pop" moments only (FAB/empty-state entrance).
  static const Curve pop = Curves.easeOutBack;

  /// Returns [Duration.zero] when the platform requests reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
