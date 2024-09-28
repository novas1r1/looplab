// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'song_cubit.dart';

class LoopStatusMapper extends EnumMapper<LoopStatus> {
  LoopStatusMapper._();

  static LoopStatusMapper? _instance;
  static LoopStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LoopStatusMapper._());
    }
    return _instance!;
  }

  static LoopStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  LoopStatus decode(dynamic value) {
    switch (value) {
      case 'initial':
        return LoopStatus.initial;
      case 'loading':
        return LoopStatus.loading;
      case 'loaded':
        return LoopStatus.loaded;
      case 'error':
        return LoopStatus.error;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(LoopStatus self) {
    switch (self) {
      case LoopStatus.initial:
        return 'initial';
      case LoopStatus.loading:
        return 'loading';
      case LoopStatus.loaded:
        return 'loaded';
      case LoopStatus.error:
        return 'error';
    }
  }
}

extension LoopStatusMapperExtension on LoopStatus {
  String toValue() {
    LoopStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<LoopStatus>(this) as String;
  }
}

class SongStateMapper extends ClassMapperBase<SongState> {
  SongStateMapper._();

  static SongStateMapper? _instance;
  static SongStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SongStateMapper._());
      LoopStatusMapper.ensureInitialized();
      LoopMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SongState';

  static LoopStatus _$status(SongState v) => v.status;
  static const Field<SongState, LoopStatus> _f$status =
      Field('status', _$status, opt: true, def: LoopStatus.initial);
  static List<Loop> _$loops(SongState v) => v.loops;
  static const Field<SongState, List<Loop>> _f$loops =
      Field('loops', _$loops, opt: true, def: const []);
  static String? _$error(SongState v) => v.error;
  static const Field<SongState, String> _f$error =
      Field('error', _$error, opt: true);

  @override
  final MappableFields<SongState> fields = const {
    #status: _f$status,
    #loops: _f$loops,
    #error: _f$error,
  };

  static SongState _instantiate(DecodingData data) {
    return SongState(
        status: data.dec(_f$status),
        loops: data.dec(_f$loops),
        error: data.dec(_f$error));
  }

  @override
  final Function instantiate = _instantiate;

  static SongState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SongState>(map);
  }

  static SongState fromJson(String json) {
    return ensureInitialized().decodeJson<SongState>(json);
  }
}

mixin SongStateMappable {
  String toJson() {
    return SongStateMapper.ensureInitialized()
        .encodeJson<SongState>(this as SongState);
  }

  Map<String, dynamic> toMap() {
    return SongStateMapper.ensureInitialized()
        .encodeMap<SongState>(this as SongState);
  }

  SongStateCopyWith<SongState, SongState, SongState> get copyWith =>
      _SongStateCopyWithImpl(this as SongState, $identity, $identity);
  @override
  String toString() {
    return SongStateMapper.ensureInitialized()
        .stringifyValue(this as SongState);
  }

  @override
  bool operator ==(Object other) {
    return SongStateMapper.ensureInitialized()
        .equalsValue(this as SongState, other);
  }

  @override
  int get hashCode {
    return SongStateMapper.ensureInitialized().hashValue(this as SongState);
  }
}

extension SongStateValueCopy<$R, $Out> on ObjectCopyWith<$R, SongState, $Out> {
  SongStateCopyWith<$R, SongState, $Out> get $asSongState =>
      $base.as((v, t, t2) => _SongStateCopyWithImpl(v, t, t2));
}

abstract class SongStateCopyWith<$R, $In extends SongState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Loop, LoopCopyWith<$R, Loop, Loop>> get loops;
  $R call({LoopStatus? status, List<Loop>? loops, String? error});
  SongStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SongStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SongState, $Out>
    implements SongStateCopyWith<$R, SongState, $Out> {
  _SongStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SongState> $mapper =
      SongStateMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Loop, LoopCopyWith<$R, Loop, Loop>> get loops =>
      ListCopyWith(
          $value.loops, (v, t) => v.copyWith.$chain(t), (v) => call(loops: v));
  @override
  $R call({LoopStatus? status, List<Loop>? loops, Object? error = $none}) =>
      $apply(FieldCopyWithData({
        if (status != null) #status: status,
        if (loops != null) #loops: loops,
        if (error != $none) #error: error
      }));
  @override
  SongState $make(CopyWithData data) => SongState(
      status: data.get(#status, or: $value.status),
      loops: data.get(#loops, or: $value.loops),
      error: data.get(#error, or: $value.error));

  @override
  SongStateCopyWith<$R2, SongState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _SongStateCopyWithImpl($value, $cast, t);
}
