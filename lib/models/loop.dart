import 'package:dart_mappable/dart_mappable.dart';

part 'loop.mapper.dart';

@MappableClass()
class Loop with LoopMappable {
  final String? id;
  final String name;
  final String songId;
  final Duration? start;
  final Duration? end;

  const Loop({
    this.id,
    required this.name,
    required this.songId,
    this.start,
    this.end,
  });
}
