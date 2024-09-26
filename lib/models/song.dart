import 'package:dart_mappable/dart_mappable.dart';

part 'song.mapper.dart';

@MappableClass(
  includeCustomMappers: [DurationMapper()],
)
class Song with SongMappable {
  final String id;
  final String title;
  final String artist;
  final String path;
  final Duration duration;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.path,
    required this.duration,
  });
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
