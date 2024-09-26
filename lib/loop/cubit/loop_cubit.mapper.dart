// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'loop_cubit.dart';

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

class LoopStateMapper extends ClassMapperBase<LoopState> {
  LoopStateMapper._();

  static LoopStateMapper? _instance;
  static LoopStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LoopStateMapper._());
      LoopStatusMapper.ensureInitialized();
      LoopMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'LoopState';

  static LoopStatus _$status(LoopState v) => v.status;
  static const Field<LoopState, LoopStatus> _f$status =
      Field('status', _$status, opt: true, def: LoopStatus.initial);
  static List<Loop> _$loops(LoopState v) => v.loops;
  static const Field<LoopState, List<Loop>> _f$loops =
      Field('loops', _$loops, opt: true, def: const []);
  static String? _$error(LoopState v) => v.error;
  static const Field<LoopState, String> _f$error =
      Field('error', _$error, opt: true);

  @override
  final MappableFields<LoopState> fields = const {
    #status: _f$status,
    #loops: _f$loops,
    #error: _f$error,
  };

  static LoopState _instantiate(DecodingData data) {
    return LoopState(
        status: data.dec(_f$status),
        loops: data.dec(_f$loops),
        error: data.dec(_f$error));
  }

  @override
  final Function instantiate = _instantiate;

  static LoopState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LoopState>(map);
  }

  static LoopState fromJson(String json) {
    return ensureInitialized().decodeJson<LoopState>(json);
  }
}

mixin LoopStateMappable {
  String toJson() {
    return LoopStateMapper.ensureInitialized()
        .encodeJson<LoopState>(this as LoopState);
  }

  Map<String, dynamic> toMap() {
    return LoopStateMapper.ensureInitialized()
        .encodeMap<LoopState>(this as LoopState);
  }

  LoopStateCopyWith<LoopState, LoopState, LoopState> get copyWith =>
      _LoopStateCopyWithImpl(this as LoopState, $identity, $identity);
  @override
  String toString() {
    return LoopStateMapper.ensureInitialized()
        .stringifyValue(this as LoopState);
  }

  @override
  bool operator ==(Object other) {
    return LoopStateMapper.ensureInitialized()
        .equalsValue(this as LoopState, other);
  }

  @override
  int get hashCode {
    return LoopStateMapper.ensureInitialized().hashValue(this as LoopState);
  }
}

extension LoopStateValueCopy<$R, $Out> on ObjectCopyWith<$R, LoopState, $Out> {
  LoopStateCopyWith<$R, LoopState, $Out> get $asLoopState =>
      $base.as((v, t, t2) => _LoopStateCopyWithImpl(v, t, t2));
}

abstract class LoopStateCopyWith<$R, $In extends LoopState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Loop, LoopCopyWith<$R, Loop, Loop>> get loops;
  $R call({LoopStatus? status, List<Loop>? loops, String? error});
  LoopStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LoopStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LoopState, $Out>
    implements LoopStateCopyWith<$R, LoopState, $Out> {
  _LoopStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LoopState> $mapper =
      LoopStateMapper.ensureInitialized();
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
  LoopState $make(CopyWithData data) => LoopState(
      status: data.get(#status, or: $value.status),
      loops: data.get(#loops, or: $value.loops),
      error: data.get(#error, or: $value.error));

  @override
  LoopStateCopyWith<$R2, LoopState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _LoopStateCopyWithImpl($value, $cast, t);
}
