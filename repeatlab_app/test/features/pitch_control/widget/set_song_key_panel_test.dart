import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/features/pitch_control/widget/set_song_key_panel.dart';

import '../../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<String>> pumpPanel(
    WidgetTester tester, {
    String? initialKey,
    bool showIntro = true,
  }) async {
    final selected = <String>[];

    await tester.pumpApp(
      Scaffold(
        body: SetSongKeyPanel(
          initialKey: initialKey,
          showIntro: showIntro,
          onKeySelected: selected.add,
        ),
      ),
      locale: const Locale('en'),
    );

    return selected;
  }

  group('SetSongKeyPanel', () {
    testWidgets('starts on major and shows the 12 major keys', (tester) async {
      await pumpPanel(tester);

      expect(find.text('Major'), findsOneWidget);
      expect(find.text('Minor'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D♭'), findsOneWidget);
      expect(find.text('B♭'), findsOneWidget);
      // Minor spellings belong to the other mode.
      expect(find.text('C♯m'), findsNothing);
    });

    testWidgets('the intro can be suppressed for the dialog', (tester) async {
      await pumpPanel(tester);
      expect(
        find.textContaining("Set the song's key once"),
        findsOneWidget,
      );

      await pumpPanel(tester, showIntro: false);
      expect(find.textContaining("Set the song's key once"), findsNothing);
    });

    testWidgets('switching to minor swaps the grid', (tester) async {
      await pumpPanel(tester);

      await tester.tap(find.byKey(const Key('song.pitch.keyQuality.minor')));
      await tester.pumpAndSettle();

      expect(find.text('Cm'), findsOneWidget);
      expect(find.text('C♯m'), findsOneWidget);
      expect(find.text('D♭'), findsNothing);
    });

    testWidgets('picking a key reports it in canonical form', (tester) async {
      final selected = await pumpPanel(tester);

      await tester.tap(find.byKey(const Key('song.pitch.key.D#')));
      await tester.pump();

      // The grid labels it E♭, but the callback reports the canonical name.
      expect(find.text('E♭'), findsOneWidget);
      expect(selected, ['D#']);
    });

    testWidgets('the chosen root survives a mode switch', (tester) async {
      final selected = await pumpPanel(tester);

      await tester.tap(find.byKey(const Key('song.pitch.key.G')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('song.pitch.keyQuality.minor')));
      await tester.pumpAndSettle();

      // G stays picked as Gm rather than silently clearing.
      expect(selected, ['G', 'Gm']);
      expect(find.text('Gm'), findsOneWidget);
    });

    testWidgets('an existing minor key opens on the minor grid', (
      tester,
    ) async {
      await pumpPanel(tester, initialKey: 'A#m');

      expect(find.text('B♭m'), findsOneWidget);
      expect(find.text('Cm'), findsOneWidget);
    });
  });
}
