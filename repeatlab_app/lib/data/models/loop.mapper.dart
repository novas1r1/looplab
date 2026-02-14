// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'loop.dart';

class LoopColorMapper extends EnumMapper<LoopColor> {
  LoopColorMapper._();

  static LoopColorMapper? _instance;
  static LoopColorMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LoopColorMapper._());
    }
    return _instance!;
  }

  static LoopColor fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  LoopColor decode(dynamic value) {
    switch (value) {
      case r'green':
        return LoopColor.green;
      case r'orange':
        return LoopColor.orange;
      case r'pink':
        return LoopColor.pink;
      case r'purple':
        return LoopColor.purple;
      case r'yellow':
        return LoopColor.yellow;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(LoopColor self) {
    switch (self) {
      case LoopColor.green:
        return r'green';
      case LoopColor.orange:
        return r'orange';
      case LoopColor.pink:
        return r'pink';
      case LoopColor.purple:
        return r'purple';
      case LoopColor.yellow:
        return r'yellow';
    }
  }
}

extension LoopColorMapperExtension on LoopColor {
  String toValue() {
    LoopColorMapper.ensureInitialized();
    return MapperContainer.globals.toValue<LoopColor>(this) as String;
  }
}

class LoopMapper extends ClassMapperBase<Loop> {
  LoopMapper._();

  static LoopMapper? _instance;
  static LoopMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LoopMapper._());
      LoopColorMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Loop';

  static int _$id(Loop v) => v.id;
  static const Field<Loop, int> _f$id = Field('id', _$id);
  static String _$name(Loop v) => v.name;
  static const Field<Loop, String> _f$name = Field('name', _$name);
  static String _$songId(Loop v) => v.songId;
  static const Field<Loop, String> _f$songId = Field('songId', _$songId);
  static LoopColor _$color(Loop v) => v.color;
  static const Field<Loop, LoopColor> _f$color = Field('color', _$color);
  static int _$orderNumber(Loop v) => v.orderNumber;
  static const Field<Loop, int> _f$orderNumber = Field(
    'orderNumber',
    _$orderNumber,
    opt: true,
    def: 0,
  );
  static Duration? _$start(Loop v) => v.start;
  static const Field<Loop, Duration> _f$start = Field(
    'start',
    _$start,
    opt: true,
  );
  static Duration? _$end(Loop v) => v.end;
  static const Field<Loop, Duration> _f$end = Field('end', _$end, opt: true);

  @override
  final MappableFields<Loop> fields = const {
    #id: _f$id,
    #name: _f$name,
    #songId: _f$songId,
    #color: _f$color,
    #orderNumber: _f$orderNumber,
    #start: _f$start,
    #end: _f$end,
  };

  static Loop _instantiate(DecodingData data) {
    return Loop(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      songId: data.dec(_f$songId),
      color: data.dec(_f$color),
      orderNumber: data.dec(_f$orderNumber),
      start: data.dec(_f$start),
      end: data.dec(_f$end),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Loop fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Loop>(map);
  }

  static Loop fromJson(String json) {
    return ensureInitialized().decodeJson<Loop>(json);
  }
}

mixin LoopMappable {
  String toJson() {
    return LoopMapper.ensureInitialized().encodeJson<Loop>(this as Loop);
  }

  Map<String, dynamic> toMap() {
    return LoopMapper.ensureInitialized().encodeMap<Loop>(this as Loop);
  }

  LoopCopyWith<Loop, Loop, Loop> get copyWith =>
      _LoopCopyWithImpl<Loop, Loop>(this as Loop, $identity, $identity);
  @override
  String toString() {
    return LoopMapper.ensureInitialized().stringifyValue(this as Loop);
  }

  @override
  bool operator ==(Object other) {
    return LoopMapper.ensureInitialized().equalsValue(this as Loop, other);
  }

  @override
  int get hashCode {
    return LoopMapper.ensureInitialized().hashValue(this as Loop);
  }
}

extension LoopValueCopy<$R, $Out> on ObjectCopyWith<$R, Loop, $Out> {
  LoopCopyWith<$R, Loop, $Out> get $asLoop =>
      $base.as((v, t, t2) => _LoopCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LoopCopyWith<$R, $In extends Loop, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? id,
    String? name,
    String? songId,
    LoopColor? color,
    int? orderNumber,
    Duration? start,
    Duration? end,
  });
  LoopCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LoopCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Loop, $Out>
    implements LoopCopyWith<$R, Loop, $Out> {
  _LoopCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Loop> $mapper = LoopMapper.ensureInitialized();
  @override
  $R call({
    int? id,
    String? name,
    String? songId,
    LoopColor? color,
    int? orderNumber,
    Object? start = $none,
    Object? end = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (songId != null) #songId: songId,
      if (color != null) #color: color,
      if (orderNumber != null) #orderNumber: orderNumber,
      if (start != $none) #start: start,
      if (end != $none) #end: end,
    }),
  );
  @override
  Loop $make(CopyWithData data) => Loop(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    songId: data.get(#songId, or: $value.songId),
    color: data.get(#color, or: $value.color),
    orderNumber: data.get(#orderNumber, or: $value.orderNumber),
    start: data.get(#start, or: $value.start),
    end: data.get(#end, or: $value.end),
  );

  @override
  LoopCopyWith<$R2, Loop, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _LoopCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

