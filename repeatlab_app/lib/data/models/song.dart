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

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.fileName,
    required this.duration,
    this.bpm,
    this.currentBpm,
    this.loops = const [],
    this.loopSort = LoopSort.none,
    this.sortOrder = 0,
    this.mediaType = MediaType.audio,
    this.videoSizeMode = VideoSizeMode.medium,
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
