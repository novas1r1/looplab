import 'package:dart_mappable/dart_mappable.dart';
import 'package:repeatlab/data/models/song.dart';

part 'recording_layer.mapper.dart';

@MappableClass(
  includeCustomMappers: [DurationMapper(), DateTimeMapper()],
)
class RecordingLayer with RecordingLayerMappable {
  final String id;
  final String songId;
  final String filePath;
  final Duration startPosition;
  final Duration duration;
  final double volume;
  final bool isMuted;
  final DateTime createdAt;
  final String? label;

  const RecordingLayer({
    required this.id,
    required this.songId,
    required this.filePath,
    required this.startPosition,
    required this.duration,
    required this.createdAt,
    this.volume = 1.0,
    this.isMuted = false,
    this.label,
  });
}

class DateTimeMapper extends SimpleMapper<DateTime> {
  const DateTimeMapper();

  @override
  DateTime decode(dynamic value) {
    return DateTime.fromMillisecondsSinceEpoch(value as int);
  }

  @override
  dynamic encode(DateTime self) {
    return self.millisecondsSinceEpoch;
  }
}
