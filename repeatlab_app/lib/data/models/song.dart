import 'package:dart_mappable/dart_mappable.dart';
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
  final List<Loop> loops;
  final LoopSort loopSort;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.fileName,
    required this.duration,
    this.loops = const [],
    this.loopSort = LoopSort.none,
  });

  Future<String> get path async {
    final appDir = await getApplicationDocumentsDirectory();

    return '${appDir.path}/$fileName';
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
