/// Navigation event types for skip button actions.
///
/// Emitted by media handlers (audio / video) when external controls (e.g.
/// notification skip buttons, Bluetooth headset, keyboard shortcuts) request
/// loop navigation. The [SongCubit] / [VideoSongCubit] listens to these and
/// translates them into loop selection calls without recursing back into the
/// handler's own skip methods.
enum LoopNavigationEvent {
  restartCurrentLoop,
  previousLoop,
  nextLoop,
}
