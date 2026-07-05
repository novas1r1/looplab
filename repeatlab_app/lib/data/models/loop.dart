import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

part 'loop.mapper.dart';

@MappableClass()
class Loop with LoopMappable {
  final int id;
  final String name;
  final String songId;
  final LoopColor color;
  final int orderNumber;

  final Duration? start;
  final Duration? end;

  const Loop({
    required this.id,
    required this.name,
    required this.songId,
    required this.color,
    this.orderNumber = 0,
    this.start,
    this.end,
  });
}

@MappableEnum()
enum LoopColor {
  green(Color(0xFFA3FF12)),
  orange(Color(0xFFFF7849)),
  pink(Color(0xFFFF3D81)),
  purple(Color(0xFFC084FC)),
  yellow(Color(0xFFFFE933))
  ;

  final Color color;

  const LoopColor(this.color);
}
