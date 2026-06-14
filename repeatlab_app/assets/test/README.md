# E2E test assets

These assets are consumed **only by the Patrol E2E suite** under
`integration_test/`.

## Audio

No file is needed — the add-audio flow synthesises a short silent WAV at runtime
(`integration_test/helpers/test_media.dart`), since WAV is natively supported by
SoLoud.

## Video (`test_video.mp4`)

The add-video flow needs a **real** short clip (media_kit probes the container
for a non-zero duration, so a hand-built/empty MP4 won't do). To enable it:

1. Drop a short (~5 s, small) clip here as `test_video.mp4`.
2. Declare the folder under `pubspec.yaml` → `flutter: assets:` so it ships into
   the test build's bundle:

   ```yaml
   flutter:
     assets:
       - assets/test/
   ```

Until then, `add_video_song_flow_test.dart` skips itself with a message rather
than failing.
