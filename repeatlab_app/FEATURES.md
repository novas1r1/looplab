# RepeatLab Features

**RepeatLab** is a comprehensive audio loop studio designed for musicians, students, and audio enthusiasts who want to master difficult sections of songs through precise looping and tempo control.

Each feature is marked as **Free** (available to everyone) or **Premium** (requires a subscription).

## 🎵 Core Audio Features (Free)

### Audio File Support — Free
- **Supported Formats**: MP3, WAV, OGG, FLAC (native SoLoud playback), plus M4A and AAC via conversion
- **Automatic Conversion**: M4A/AAC files are automatically converted to MP3 for compatibility (via FFmpeg)
- **Multi-File Import**: Select and import multiple audio files in one go, with a progress indicator
- **Metadata Reading**: Displays audio file metadata including title and artist information
- **Unlimited Songs**: Add as many audio files as you want to your library
- **Song Reordering**: Long-press and drag songs to organize your library; the custom order is saved

### Video Support (Beta) — Free
- **Video Import**: Import videos (MP4, MOV, M4V, MKV, WEBM, AVI) and practice with them like audio songs
- **Video Looping & Speed**: Loop sections of a video and change playback speed — ideal for tutorials and live performances (speed/pitch changes are Premium, as for audio)
- **Video Pitch Control**: Pitch shifting also works for video playback (via media_kit/libmpv)

### Audio Playback Engine — Free
- **High-Quality Playback**: Powered by SoLoud and AudioPlayers for optimal audio performance
- **Background Playback**: Continue listening even when the app is in background or device is in standby mode
- **Audio Service Integration**: Full media control integration with system audio controls

## 🔄 Loop Management

### Loop Creation & Control
- **One Loop per Song** — Free: Basic looping functionality for all users
- **Unlimited Loops** — Premium: Create multiple loops per song for comprehensive practice
- **Precise Loop Points** — Free: Set exact start and end positions using the waveform display
- **Visual Loop Indicators** — Free: See all your loops displayed on the timeline
- **Loop Reordering** — Premium: Drag and drop loops to reorganize them
- **Loop Editing** — Free: Fine-tune loop start/end times with precision controls
- **Edit While Paused** — Free: Freely move a loop's start and end points while playback is paused — the playhead no longer snaps back into the loop; boundaries take effect again on play
- **Loop Export** — Free: Export loops as audio files in MP3 (compressed) or WAV (lossless) format

### Loop Playback — Free
- **Seamless Looping**: Smooth transitions between loop start and end points — on Android the loop wrap happens natively inside the playback engine (zero detection latency); other platforms use predictive Dart-side scheduling
- **Loop Mode Toggle**: Switch between full song and loop-only playback
- **Jump to Loops**: Skip to the next or previous loop with the skip buttons — also from the notification and lock screen
- **Loop Activation**: Select and activate specific loops for focused practice
- **Auto-Play Setting**: Enable or disable automatic playback when selecting loops or navigating between them

## ⚡ Speed & Tempo Control (Premium)

### Two Tempo Modes
- **Multiplier Mode**: Adjust playback speed using a factor from 0.5× to 2.0× (default: 1.0×)
- **BPM Mode**: Control tempo in beats per minute for precise musical timing

### Multiplier Mode — Premium
- **Speed Range**: 0.5× (half speed) to 2.0× (double speed)
- **Default Speed**: 1.0× (original tempo) when opening any song
- **Bidirectional Sync**: When original BPM is set, current BPM updates to match the speed factor

### BPM Mode
- **Original BPM** — Free: Set the song's original tempo by typing it in or using Tap Tempo (also needed for the metronome)
- **Tap BPM Detection** — Free: Tap along with the music to automatically detect BPM
- **Edit Original BPM** — Free: Tap the original BPM tile to change or clear it
- **Current BPM Adjustment** — Premium: Change the playback tempo in BPM (range: original BPM × 0.5 to × 2.0)
- **Original BPM = 1.0×**: The original BPM always corresponds to speed factor 1.0
- **Bidirectional Sync**: Changing current BPM updates the speed factor accordingly

### Speed Control Features — Premium
- **Speed Reset**: Resets speed to 1.0× (and current BPM to original BPM if set)
- **Per-Song Reset**: Speed always resets to 1.0× when opening a song
- **Loop Speed Sync**: Loop playback always uses the same speed as song playback
- **Real-time Adjustment**: Change speed while audio is playing
- **Pitch Preservation**: Maintain audio quality during speed changes
- **Visual Speed Indicator**: See current playback speed at all times

## 🎼 Pitch Control (Premium, Beta)

### Pitch Adjustment
- **Semitone Range**: Transpose audio from -12 to +12 semitones (one octave down/up)
- **Independent Control**: Pitch changes work independently from speed adjustments
- **Real-time Processing**: Adjust pitch while audio is playing
- **Musical Transposition**: Perfect for practicing songs in different keys or matching your instrument's tuning

### Two Pitch Modes
- **Semitone Mode**: Adjust pitch with a slider in semitone steps
- **Key Mode**: Set the song's original musical key, then transpose directly to a target key (e.g. Am → Cm)

### Pitch Control Features
- **Semitone Precision**: Accurate musical interval adjustments
- **Visual Pitch Indicator**: See current pitch adjustment in semitones
- **Pitch Reset**: Quickly return to original pitch (0 semitones)
- **Compact UI**: Space-efficient tabbed interface with tempo controls

## 🥁 Metronome

A built-in metronome that keeps time with your song, shown in the Tempo tab. It requires the song's BPM to be set (free, via Tap Tempo or manual entry) and clicks only while the song plays, always following the current playback tempo.

### Basic Metronome — Free
- **On/Off Toggle**: Enable a steady click at the song's BPM
- **Speed Aware**: The click automatically follows tempo/speed changes
- **Reset Sync**: Clearing a beat alignment is always possible

### Sync & Advanced Controls — Premium
- **Sync to Song**: Tap along with the music to align the click with the actual beat (beat anchor)
- **Time Signature**: Choose from 2/4, 3/4, 4/4, 5/4, 6/8, 7/8, and 12/8 — with a downbeat accent once synced
- **Subdivisions**: Click in quarters, eighths, triplets, or sixteenths
- **Re-Tap Alignment**: Redo the tap-along beat capture at any time
- **Millisecond Nudge**: Shift the click earlier or later in ±25 ms steps for a perfect lock
- **Click Volume**: Adjust the metronome volume independently of the song

## 📊 Waveform Visualization

### Waveform Display — Free
- **Visual Audio Representation**: See the complete audio waveform
- **Current Position Indicator**: Track playback progress visually
- **Loop Visualization**: Loops are highlighted on the waveform
- **Interactive Navigation**: Drag to scrub through the audio

### Zoom Features — Premium
- **Zoom In/Out**: Magnify waveform for precise editing (0.25× to 5.0× zoom)
- **Zoom Controls**: Intuitive zoom buttons and slider
- **Zoom Persistence**: Maintains zoom level during playback
- **Precision Editing**: Enhanced accuracy for loop point selection

## 🎯 Navigation & Control (Free)

### Playback Controls
- **Play/Pause**: Standard playback controls
- **Skip Forward/Back**: Jump to the next or previous loop, or restart the current position
- **Seek Control**: Precise position seeking by dragging on the waveform
- **Position Display**: Current time and total duration

### User Interface
- **Intuitive Design**: Clean, musician-friendly interface
- **Touch Controls**: Gesture-based navigation and control
- **Visual Feedback**: Clear indicators for all states and actions
- **Responsive Design**: Optimized for various screen sizes

## 🌍 Internationalization (Free)

### Supported Languages
- **16 Languages**: Arabic, German, English, Spanish, French, Hindi, Italian, Japanese, Korean, Dutch, Polish, Portuguese, Russian, Swedish, Turkish, Chinese
- **In-App Language Switching**: Pick any of the 16 languages from the drawer, or follow the device's system default
- **Complete Localization**: All UI elements and messages translated
- **Regional Formats**: Proper time and number formatting for each locale

## 📚 User Experience (Free)

### Onboarding & Tutorial
- **Welcome Flow**: Guided introduction to app features
- **Interactive Tutorial**: Step-by-step guidance for first-time users
- **Privacy Controls**: Clear consent management for data usage
- **Feature Highlights**: Showcase of key functionality
- **Changelog Dialog**: See what's new after each update

### Help & Support
- **In-App Tutorial**: Contextual help system with coach marks
- **Feedback System**: Built-in bug reporting and feature requests via Wiredash
- **Rate App Integration**: Easy app store rating system
- **Feature Voting**: Community-driven feature prioritization via UserOrient

## 💎 Free vs. Premium at a Glance

### Free Features
- **Unlimited Songs**: No limit on audio or video file imports
- **One Loop per Song**: Basic looping functionality, including loop export
- **Basic Metronome**: Steady click at the song's tempo
- **Original BPM / Tap Tempo**: Set and edit the song's tempo
- **No Advertisements**: Clean, ad-free experience
- **Core Playback**: All essential audio playback features, background playback, media controls

### Premium (Subscription) Features
- **Unlimited Loops**: Create as many loops as needed per song (including drag-to-reorder)
- **Speed Control**: Full tempo and BPM adjustment capabilities
- **Pitch Control**: Full pitch adjustment capabilities (semitones and key mode)
- **Metronome Sync & Advanced Controls**: Beat alignment, time signatures with accent, subdivisions, nudge, click volume
- **Waveform Zoom**: Enhanced precision with zoom functionality
- **Backup & Restore**: Export the entire library and restore it on another device
- **Developer Support**: Support independent development

## 🔧 Technical Features

### Data Management
- **Local Storage** — Free: All audio files stored locally on device
- **Database Integration** — Free: Efficient data management with Sembast
- **Settings Persistence** — Free: User preferences saved across sessions
- **Backup & Restore** — Premium: Export the entire library — songs, loops, and optionally audio files — to a single backup file and restore it on another device, with Merge or Replace mode

### Performance & Reliability
- **Crash Reporting**: Automatic error reporting via Sentry
- **Analytics**: Optional, consent-gated usage analytics via PostHog (EU-hosted) and Microsoft Clarity
- **Performance Monitoring**: Optimized for smooth audio playback
- **Memory Management**: Efficient handling of large audio files

### Privacy & Security
- **Privacy First**: Minimal data collection with user consent
- **Local Processing**: Audio files processed locally, not uploaded
- **GDPR Compliant**: Full compliance with privacy regulations
- **Consent Management**: Granular control over data usage

## 📱 Platform Support

### Mobile Platforms
- **iOS**: Full iOS support with native integration
- **Android**: Complete Android compatibility
- **Cross-Platform**: Consistent experience across devices

### System Integration
- **Media Controls**: Integration with system media controls
- **Background Audio**: Continues playing when app is backgrounded
- **Lock Screen Controls**: Control playback from lock screen
- **Notification Controls**: Media controls in notification panel

## 🛠 Development Features

### Quality Assurance
- **Automated Testing**: Comprehensive test coverage
- **Code Quality**: Lint rules and static analysis
- **Error Handling**: Robust error management and recovery
- **Performance Optimization**: Optimized for smooth operation

### Monitoring & Analytics
- **Crash Monitoring**: Real-time crash detection and reporting
- **Performance Tracking**: Monitor app performance metrics
- **User Analytics**: Optional usage pattern analysis
- **Feature Usage**: Track feature adoption and usage

---

## Getting Started

1. **Import Audio or Video**: Add your favorite songs (or videos) in supported formats — multiple files at once
2. **Create Loops**: Mark sections you want to practice
3. **Set the Tempo**: Tap in or enter the song's BPM, then turn on the metronome
4. **Adjust Speed**: Fine-tune tempo for comfortable practice (Premium)
5. **Adjust Pitch**: Transpose songs to comfortable keys (Premium)
6. **Practice**: Use loops to master difficult passages
7. **Progress**: Track your improvement over time

## Premium Upgrade

Unlock the full potential of RepeatLab with premium features:
- Unlimited loops per song
- Complete speed and BPM control
- Pitch control (semitones and key mode)
- Metronome sync and advanced controls
- Waveform zoom for precision editing
- Library backup & restore
- Support independent development

---

*RepeatLab - Your Music Loop Station*
