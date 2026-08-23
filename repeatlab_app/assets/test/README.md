# E2E test assets

These assets are consumed **only by the Patrol E2E suite** under
`integration_test/` (`integration_test/helpers/test_media.dart`). They are
declared in `pubspec.yaml` (`assets/test/`) so they ship in the test build's
bundle — which also means they ship in release builds; that's why each clip is
~1 s and the whole folder is ~120 KB.

One clip per format the app's pickers offer:

| Kind  | Files (`test_audio.*` / `test_video.*`)     | Mirrors                                     |
|-------|---------------------------------------------|---------------------------------------------|
| audio | mp3 m4a aac wav flac ogg wma opus aiff      | `FileRepository._audioPickerExtensions`     |
| video | mp4 mov m4v mkv webm avi                    | `SongRepository.videoPickerExtensions*`     |

If a picker extension is added, add a clip here **and** to
`TestMedia.bundledAudioFormats` / `bundledVideoFormats`;
`add_song_formats_flow_test.dart` then imports it on-device automatically.

## Regenerating

Audio is a 1 s mono 440 Hz sine (22.05 kHz; 8 kHz for the uncompressed
wav/aiff/flac to keep them small). Video is 1 s of 64×64 blue at 10 fps with an
AAC/Opus/MP3 audio track. Generated with ffmpeg 7.1:

```bash
A="-f lavfi -i sine=frequency=440:sample_rate=22050:duration=1"
A8="-f lavfi -i sine=frequency=440:sample_rate=8000:duration=1"
V="-f lavfi -i color=c=blue:s=64x64:r=10:d=1"
X264="-c:v libx264 -pix_fmt yuv420p -preset veryslow -crf 40 -c:a aac -b:a 24k -shortest"

ffmpeg -y $A  -ac 1 -c:a libmp3lame -b:a 32k test_audio.mp3
ffmpeg -y $A  -ac 1 -c:a aac -b:a 32k        test_audio.m4a
ffmpeg -y $A  -ac 1 -c:a aac -b:a 32k -f adts test_audio.aac
ffmpeg -y $A8 -ac 1 -c:a pcm_s16le           test_audio.wav
ffmpeg -y $A8 -ac 1 -c:a flac                test_audio.flac
ffmpeg -y $A  -ac 1 -c:a libvorbis -q:a 0    test_audio.ogg
ffmpeg -y $A  -ac 1 -c:a wmav2 -b:a 32k      test_audio.wma
ffmpeg -y $A  -ac 1 -c:a libopus -b:a 24k    test_audio.opus
ffmpeg -y $A8 -ac 1 -c:a pcm_s16be           test_audio.aiff

ffmpeg -y $V $A -ac 1 $X264 -movflags +faststart test_video.mp4
ffmpeg -y $V $A -ac 1 $X264 test_video.mov
ffmpeg -y $V $A -ac 1 $X264 test_video.m4v
ffmpeg -y $V $A -ac 1 $X264 test_video.mkv
ffmpeg -y $V $A -ac 1 -c:v libvpx-vp9 -b:v 20k -c:a libopus -b:a 24k -shortest test_video.webm
ffmpeg -y $V $A -ac 1 -c:v mpeg4 -q:v 31 -c:a libmp3lame -b:a 32k -shortest    test_video.avi
```

(No ffmpeg on the machine? `pip install imageio-ffmpeg` bundles a static build:
`python -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())"`.)
