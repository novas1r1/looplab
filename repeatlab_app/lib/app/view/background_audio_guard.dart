import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:repeatlab/data/services/audio_service_provider.dart';

/// Keeps the app from burning battery while backgrounded without playback.
///
/// The app declares the `audio` background mode, which can keep the process
/// alive (and the audio handler's loop-polling timers firing) for as long as
/// the app sits in the background — users on iPadOS 26 reported >10%/day
/// background drain from exactly this (RL-371).
///
/// On backgrounding while nothing is playing, this widget:
///  * cancels the audio handler's loop-polling timers,
///  * deactivates the audio session so the OS is free to suspend the process.
///
/// While the app is backgrounded *with* active playback (the legitimate
/// background-audio case) nothing is touched; if playback is then paused from
/// the lock screen, the same suspension kicks in. The handler re-arms its
/// timers on the next `play()`.
///
/// SoLoud is deliberately no part of this guard anymore: since the
/// route-change crash fix (FLUTTER-2Y/FLUTTER-FY) the engine only runs for
/// the seconds of an import probe (see `SongRepository.addSongFile`) and is
/// never left running — so there is nothing to suspend, and no unawaited
/// foreground re-init for an import to race (FLUTTER-KA).
class BackgroundAudioGuard extends StatefulWidget {
  final Widget child;

  const BackgroundAudioGuard({
    required this.child,
    super.key,
  });

  @override
  State<BackgroundAudioGuard> createState() => _BackgroundAudioGuardState();
}

class _BackgroundAudioGuardState extends State<BackgroundAudioGuard>
    with WidgetsBindingObserver {
  StreamSubscription<PlaybackState>? _backgroundPlaybackSub;
  bool _suspended = false;

  /// Suspension only matters where an OS battery budget exists; desktop
  /// window focus changes must not churn the audio session.
  bool get _isMobile => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_backgroundPlaybackSub?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isMobile) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _onBackgrounded();
      case AppLifecycleState.resumed:
        _onForegrounded();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Transient on mobile (control center swipe, app switcher); `paused`
        // follows if the app really goes to background.
        break;
    }
  }

  void _onBackgrounded() {
    final handler = AudioServiceProvider.activeHandler;
    if (handler == null || !handler.playbackState.value.playing) {
      _suspendNow();
      return;
    }

    // Legitimate background playback: leave everything running, but watch
    // for a pause from the lock screen / control center so the suspension
    // still happens while backgrounded.
    _backgroundPlaybackSub ??= handler.playbackState.listen((playbackState) {
      if (playbackState.playing) {
        // Resumed from the lock screen; `play()` re-arms the loop timers.
        _suspended = false;
      } else if (!_suspended) {
        _suspendNow();
      }
    });
  }

  void _onForegrounded() {
    unawaited(_backgroundPlaybackSub?.cancel());
    _backgroundPlaybackSub = null;
    _suspended = false;
  }

  void _suspendNow() {
    _suspended = true;

    AudioServiceProvider.activeHandler?.suspendBackgroundPolling();

    unawaited(_deactivateAudioSession());
  }

  Future<void> _deactivateAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (error, stackTrace) {
      // Never fatal: worst case the OS keeps the session (and drain) alive
      // until it reclaims it itself.
      log('Audio session deactivation failed: $error', stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
