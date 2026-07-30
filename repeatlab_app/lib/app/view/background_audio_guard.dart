import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/data/services/audio_service_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Keeps the app from burning battery while backgrounded without playback.
///
/// The app declares the `audio` background mode, and the SoLoud engine keeps
/// an output audio unit running from app start. Together they can keep the
/// process alive (and its polling timers firing) for as long as the app sits
/// in the background — users on iPadOS 26 reported >10%/day background drain
/// from exactly this (RL-371).
///
/// On backgrounding while nothing is playing, this widget:
///  * cancels the audio handler's loop-polling timers,
///  * shuts down the SoLoud engine (it is only used as an offline decoder for
///    waveforms and duration probing, so no playback state is lost),
///  * deactivates the audio session so the OS is free to suspend the process.
///
/// While the app is backgrounded *with* active playback (the legitimate
/// background-audio case) nothing is touched; if playback is then paused from
/// the lock screen, the same suspension kicks in. On foregrounding, SoLoud is
/// re-initialized; the handler re-arms its timers on the next `play()`.
class BackgroundAudioGuard extends StatefulWidget {
  final SoLoud soloud;
  final Widget child;

  const BackgroundAudioGuard({
    required this.soloud,
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
  /// window focus changes must not churn the audio engine.
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

    if (!widget.soloud.isInitialized) {
      unawaited(
        widget.soloud.init().catchError((Object error, StackTrace stackTrace) {
          // Waveform decoding degrades until the next foreground; playback
          // itself does not depend on SoLoud.
          unawaited(
            Sentry.captureException(
              error,
              stackTrace: stackTrace,
              hint: Hint.withMap({'location': 'soloud_foreground_reinit'}),
            ),
          );
        }),
      );
    }
  }

  void _suspendNow() {
    _suspended = true;

    AudioServiceProvider.activeHandler?.suspendBackgroundPolling();

    if (widget.soloud.isInitialized) {
      try {
        widget.soloud.deinit();
      } catch (error, stackTrace) {
        unawaited(
          Sentry.captureException(
            error,
            stackTrace: stackTrace,
            hint: Hint.withMap({'location': 'soloud_background_deinit'}),
          ),
        );
      }
    }

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
