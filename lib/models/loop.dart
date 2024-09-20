import 'package:dart_mappable/dart_mappable.dart';

part 'loop.mapper.dart';

@MappableClass()
class Loop with LoopMappable {
  final String id;
  final String name;
  final String songId;
  final int microsecondStart;
  final int microsecondEnd;

  const Loop({
    required this.id,
    required this.name,
    required this.songId,
    required this.microsecondStart,
    required this.microsecondEnd,
  });
}
