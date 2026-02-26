// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'recording_cubit.dart';

class RecordingStatusMapper extends EnumMapper<RecordingStatus> {
  RecordingStatusMapper._();

  static RecordingStatusMapper? _instance;
  static RecordingStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RecordingStatusMapper._());
    }
    return _instance!;
  }

  static RecordingStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  RecordingStatus decode(dynamic value) {
    switch (value) {
      case r'idle':
        return RecordingStatus.idle;
      case r'permissionDenied':
        return RecordingStatus.permissionDenied;
      case r'countdown':
        return RecordingStatus.countdown;
      case r'recording':
        return RecordingStatus.recording;
      case r'saving':
        return RecordingStatus.saving;
      case r'error':
        return RecordingStatus.error;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(RecordingStatus self) {
    switch (self) {
      case RecordingStatus.idle:
        return r'idle';
      case RecordingStatus.permissionDenied:
        return r'permissionDenied';
      case RecordingStatus.countdown:
        return r'countdown';
      case RecordingStatus.recording:
        return r'recording';
      case RecordingStatus.saving:
        return r'saving';
      case RecordingStatus.error:
        return r'error';
    }
  }
}

extension RecordingStatusMapperExtension on RecordingStatus {
  String toValue() {
    RecordingStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<RecordingStatus>(this) as String;
  }
}

class RecordingStateMapper extends ClassMapperBase<RecordingState> {
  RecordingStateMapper._();

  static RecordingStateMapper? _instance;
  static RecordingStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RecordingStateMapper._());
      RecordingStatusMapper.ensureInitialized();
      RecordingLayerMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'RecordingState';

  static RecordingStatus _$status(RecordingState v) => v.status;
  static const Field<RecordingState, RecordingStatus> _f$status = Field(
    'status',
    _$status,
    opt: true,
    def: RecordingStatus.idle,
  );
  static List<RecordingLayer> _$layers(RecordingState v) => v.layers;
  static const Field<RecordingState, List<RecordingLayer>> _f$layers = Field(
    'layers',
    _$layers,
    opt: true,
    def: const [],
  );
  static int? _$countdownValue(RecordingState v) => v.countdownValue;
  static const Field<RecordingState, int> _f$countdownValue = Field(
    'countdownValue',
    _$countdownValue,
    opt: true,
  );
  static String? _$activeLayerId(RecordingState v) => v.activeLayerId;
  static const Field<RecordingState, String> _f$activeLayerId = Field(
    'activeLayerId',
    _$activeLayerId,
    opt: true,
  );
  static Duration? _$currentRecordingDuration(RecordingState v) =>
      v.currentRecordingDuration;
  static const Field<RecordingState, Duration> _f$currentRecordingDuration =
      Field('currentRecordingDuration', _$currentRecordingDuration, opt: true);
  static String? _$error(RecordingState v) => v.error;
  static const Field<RecordingState, String> _f$error = Field(
    'error',
    _$error,
    opt: true,
  );

  @override
  final MappableFields<RecordingState> fields = const {
    #status: _f$status,
    #layers: _f$layers,
    #countdownValue: _f$countdownValue,
    #activeLayerId: _f$activeLayerId,
    #currentRecordingDuration: _f$currentRecordingDuration,
    #error: _f$error,
  };

  static RecordingState _instantiate(DecodingData data) {
    return RecordingState(
      status: data.dec(_f$status),
      layers: data.dec(_f$layers),
      countdownValue: data.dec(_f$countdownValue),
      activeLayerId: data.dec(_f$activeLayerId),
      currentRecordingDuration: data.dec(_f$currentRecordingDuration),
      error: data.dec(_f$error),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RecordingState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RecordingState>(map);
  }

  static RecordingState fromJson(String json) {
    return ensureInitialized().decodeJson<RecordingState>(json);
  }
}

mixin RecordingStateMappable {
  String toJson() {
    return RecordingStateMapper.ensureInitialized().encodeJson<RecordingState>(
      this as RecordingState,
    );
  }

  Map<String, dynamic> toMap() {
    return RecordingStateMapper.ensureInitialized().encodeMap<RecordingState>(
      this as RecordingState,
    );
  }

  RecordingStateCopyWith<RecordingState, RecordingState, RecordingState>
  get copyWith => _RecordingStateCopyWithImpl<RecordingState, RecordingState>(
    this as RecordingState,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return RecordingStateMapper.ensureInitialized().stringifyValue(
      this as RecordingState,
    );
  }

  @override
  bool operator ==(Object other) {
    return RecordingStateMapper.ensureInitialized().equalsValue(
      this as RecordingState,
      other,
    );
  }

  @override
  int get hashCode {
    return RecordingStateMapper.ensureInitialized().hashValue(
      this as RecordingState,
    );
  }
}

extension RecordingStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RecordingState, $Out> {
  RecordingStateCopyWith<$R, RecordingState, $Out> get $asRecordingState =>
      $base.as((v, t, t2) => _RecordingStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class RecordingStateCopyWith<$R, $In extends RecordingState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    RecordingLayer,
    RecordingLayerCopyWith<$R, RecordingLayer, RecordingLayer>
  >
  get layers;
  $R call({
    RecordingStatus? status,
    List<RecordingLayer>? layers,
    int? countdownValue,
    String? activeLayerId,
    Duration? currentRecordingDuration,
    String? error,
  });
  RecordingStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _RecordingStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RecordingState, $Out>
    implements RecordingStateCopyWith<$R, RecordingState, $Out> {
  _RecordingStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RecordingState> $mapper =
      RecordingStateMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    RecordingLayer,
    RecordingLayerCopyWith<$R, RecordingLayer, RecordingLayer>
  >
  get layers => ListCopyWith(
    $value.layers,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(layers: v),
  );
  @override
  $R call({
    RecordingStatus? status,
    List<RecordingLayer>? layers,
    Object? countdownValue = $none,
    Object? activeLayerId = $none,
    Object? currentRecordingDuration = $none,
    Object? error = $none,
  }) => $apply(
    FieldCopyWithData({
      if (status != null) #status: status,
      if (layers != null) #layers: layers,
      if (countdownValue != $none) #countdownValue: countdownValue,
      if (activeLayerId != $none) #activeLayerId: activeLayerId,
      if (currentRecordingDuration != $none)
        #currentRecordingDuration: currentRecordingDuration,
      if (error != $none) #error: error,
    }),
  );
  @override
  RecordingState $make(CopyWithData data) => RecordingState(
    status: data.get(#status, or: $value.status),
    layers: data.get(#layers, or: $value.layers),
    countdownValue: data.get(#countdownValue, or: $value.countdownValue),
    activeLayerId: data.get(#activeLayerId, or: $value.activeLayerId),
    currentRecordingDuration: data.get(
      #currentRecordingDuration,
      or: $value.currentRecordingDuration,
    ),
    error: data.get(#error, or: $value.error),
  );

  @override
  RecordingStateCopyWith<$R2, RecordingState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _RecordingStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

