import 'package:patrol/patrol.dart';
import 'package:repeatlab/app/view/repository_wrapper.dart';
import 'package:repeatlab/bootstrap.dart';

import 'fakes.dart';

/// Pumps the real [bootstrap]-built app with test fakes injected.
///
/// - [filePicker] fakes media import / export (defaults to an empty fake).
/// - [isPro] toggles the faked RevenueCat entitlement.
///
/// Sentry / Clarity are NOT initialised here (they live in `main`), so test
/// runs stay offline and side-effect free.
Future<void> pumpRepeatLab(
  PatrolIntegrationTester $, {
  FilePickerWrapper? filePicker,
  bool isPro = true,
}) async {
  final app = await bootstrap(
    filePicker: filePicker ?? FakeFilePickerWrapper(),
    purchases: FakePurchasesRepository(isPro: isPro),
  );
  await $.pumpWidgetAndSettle(app);
}
