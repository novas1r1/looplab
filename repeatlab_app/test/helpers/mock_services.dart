import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:mocktail/mocktail.dart';

class MockSoLoud extends Mock implements SoLoud {
  @override
  void setInaudibleBehavior(SoundHandle handle, bool mustTick, bool kill) {
    // TODO: implement setInaudibleBehavior
  }
}

class MockAudioSource extends Mock implements AudioSource {}
