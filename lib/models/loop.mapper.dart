// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'loop.dart';

class LoopMapper extends ClassMapperBase<Loop> {
  LoopMapper._();

  static LoopMapper? _instance;
  static LoopMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LoopMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Loop';

  static String _$id(Loop v) => v.id;
  static const Field<Loop, String> _f$id = Field('id', _$id);
  static String _$name(Loop v) => v.name;
  static const Field<Loop, String> _f$name = Field('name', _$name);
  static String _$songId(Loop v) => v.songId;
  static const Field<Loop, String> _f$songId = Field('songId', _$songId);
  static int _$microsecondStart(Loop v) => v.microsecondStart;
  static const Field<Loop, int> _f$microsecondStart =
      Field('microsecondStart', _$microsecondStart);
  static int _$microsecondEnd(Loop v) => v.microsecondEnd;
  static const Field<Loop, int> _f$microsecondEnd =
      Field('microsecondEnd', _$microsecondEnd);

  @override
  final MappableFields<Loop> fields = const {
    #id: _f$id,
    #name: _f$name,
    #songId: _f$songId,
    #microsecondStart: _f$microsecondStart,
    #microsecondEnd: _f$microsecondEnd,
  };

  static Loop _instantiate(DecodingData data) {
    return Loop(
        id: data.dec(_f$id),
        name: data.dec(_f$name),
        songId: data.dec(_f$songId),
        microsecondStart: data.dec(_f$microsecondStart),
        microsecondEnd: data.dec(_f$microsecondEnd));
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
      _LoopCopyWithImpl(this as Loop, $identity, $identity);
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
      $base.as((v, t, t2) => _LoopCopyWithImpl(v, t, t2));
}

abstract class LoopCopyWith<$R, $In extends Loop, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? id,
      String? name,
      String? songId,
      int? microsecondStart,
      int? microsecondEnd});
  LoopCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LoopCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Loop, $Out>
    implements LoopCopyWith<$R, Loop, $Out> {
  _LoopCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Loop> $mapper = LoopMapper.ensureInitialized();
  @override
  $R call(
          {String? id,
          String? name,
          String? songId,
          int? microsecondStart,
          int? microsecondEnd}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (name != null) #name: name,
        if (songId != null) #songId: songId,
        if (microsecondStart != null) #microsecondStart: microsecondStart,
        if (microsecondEnd != null) #microsecondEnd: microsecondEnd
      }));
  @override
  Loop $make(CopyWithData data) => Loop(
      id: data.get(#id, or: $value.id),
      name: data.get(#name, or: $value.name),
      songId: data.get(#songId, or: $value.songId),
      microsecondStart:
          data.get(#microsecondStart, or: $value.microsecondStart),
      microsecondEnd: data.get(#microsecondEnd, or: $value.microsecondEnd));

  @override
  LoopCopyWith<$R2, Loop, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _LoopCopyWithImpl($value, $cast, t);
}
