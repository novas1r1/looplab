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
