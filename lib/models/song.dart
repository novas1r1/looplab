import 'package:dart_mappable/dart_mappable.dart';

part 'song.mapper.dart';

@MappableClass()
class Song with SongMappable {
  final String id;
  final String title;
  final String artist;
  final String path;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.path,
  });
}
