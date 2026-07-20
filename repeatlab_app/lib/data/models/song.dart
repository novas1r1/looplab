import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:repeatlab/data/models/loop.dart';

part 'song.mapper.dart';

@MappableClass(
  includeCustomMappers: [DurationMapper()],
)
class Song with SongMappable {
  final String id;
  final String title;
  final String artist;
  final String fileName;
  final Duration duration;

  /// Original tempo of the song in beats per minute (optional). If `null`, the
  /// user has not provided it yet and the BPM-based speed control will prompt
  /// for it.
  final int? bpm;
  final int? currentBpm;

  /// Pitch shift in semitones (-12..+12), 0 = original pitch. Persisted per
  /// song and reapplied on open (unlike speed, which resets to 1.0). Defaults
  /// to 0 so existing sembast records decode without a migration.
  final int pitchSemitones;

  /// Musical key (Tonart) of the song, e.g. "Am" or "F#", read from the
  /// file's ID3 TKEY tag on import. `null` when the file carried no key tag.
  final String? musicalKey;
  final List<Loop> loops;
  final LoopSort loopSort;
  final int sortOrder;

  /// Whether this entry is an audio file or a video file. Defaults to
  /// [MediaType.audio] so existing sembast records (which were written before
  /// this field existed) decode as audio without needing a migration.
  final MediaType mediaType;

  /// Display size of the video preview on the song page. Only meaningful when
  /// [mediaType] is [MediaType.video]; ignored for audio. Defaults to
  /// [VideoSizeMode.medium] so existing records decode without migration.
  final VideoSizeMode videoSizeMode;

  /// Metronome start offset in milliseconds — how far the click grid is
  /// shifted relative to playback start to line up with this song's first
  /// beat. Adjusted by the user via the nudge control. Defaults to 0 so
  /// existing sembast records decode without migration.
  final int metronomeOffsetMs;

  /// Metronome time signature for this song (e.g. 4/4, 6/8). Defaults keep
  /// existing sembast records decoding without migration.
  final int metronomeBeatsPerBar;
  final int metronomeBeatUnit;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.fileName,
    required this.duration,
    this.bpm,
    this.currentBpm,
    this.pitchSemitones = 0,
    this.musicalKey,
    this.loops = const [],
    this.loopSort = LoopSort.none,
    this.sortOrder = 0,
    this.mediaType = MediaType.audio,
    this.videoSizeMode = VideoSizeMode.medium,
    this.metronomeOffsetMs = 0,
    this.metronomeBeatsPerBar = 4,
    this.metronomeBeatUnit = 4,
  });

  Future<String> get path async {
    final appDir = await getApplicationDocumentsDirectory();

    return p.join(appDir.path, fileName);
  }
}

@MappableEnum()
enum LoopSort {
  manual,
  startTime,
  none,
}

@MappableEnum()
enum MediaType {
  audio,
  video,
}

@MappableEnum()
enum VideoSizeMode {
  small,
  medium,
  large,
}

class DurationMapper extends SimpleMapper<Duration> {
  const DurationMapper();

  @override
  Duration decode(dynamic value) {
    return Duration(microseconds: value as int);
  }

  @override
  dynamic encode(Duration self) {
    return self.inMicroseconds;
  }
}
