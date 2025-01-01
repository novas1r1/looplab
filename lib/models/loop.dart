import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

part 'loop.mapper.dart';

@MappableClass()
class Loop with LoopMappable {
  final int id;
  final String name;
  final String songId;
  final LoopColor color;

  final Duration? start;
  final Duration? end;

  const Loop({
    required this.id,
    required this.name,
    required this.songId,
    required this.color,
    this.start,
    this.end,
  });
}

@MappableEnum()
enum LoopColor {
  purple(Color(0xFF6200FF)),
  green(Color(0xFF00FF00)),
  red(Color(0xFFFF0000)),
  pink(Color(0xFFFF00FF)),
  yellow(Color(0xFFFFFF00));

  final Color color;

  const LoopColor(this.color);
}
