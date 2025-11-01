// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'speed_control_cubit.dart';

class SpeedControlStateMapper extends ClassMapperBase<SpeedControlState> {
  SpeedControlStateMapper._();

  static SpeedControlStateMapper? _instance;
  static SpeedControlStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SpeedControlStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SpeedControlState';

  static TempoMode _$tempoMode(SpeedControlState v) => v.tempoMode;
  static const Field<SpeedControlState, TempoMode> _f$tempoMode = Field(
    'tempoMode',
    _$tempoMode,
    opt: true,
    def: TempoMode.multiplier,
  );
  static double _$speedMultiplier(SpeedControlState v) => v.speedMultiplier;
  static const Field<SpeedControlState, double> _f$speedMultiplier = Field(
    'speedMultiplier',
    _$speedMultiplier,
    opt: true,
    def: 1.0,
  );
  static int? _$originalBpm(SpeedControlState v) => v.originalBpm;
  static const Field<SpeedControlState, int> _f$originalBpm = Field(
    'originalBpm',
    _$originalBpm,
    opt: true,
  );
  static int? _$currentBpm(SpeedControlState v) => v.currentBpm;
  static const Field<SpeedControlState, int> _f$currentBpm = Field(
    'currentBpm',
    _$currentBpm,
    opt: true,
  );
  static int? _$minBpm(SpeedControlState v) => v.minBpm;
  static const Field<SpeedControlState, int> _f$minBpm = Field(
    'minBpm',
    _$minBpm,
    opt: true,
  );
  static int? _$maxBpm(SpeedControlState v) => v.maxBpm;
  static const Field<SpeedControlState, int> _f$maxBpm = Field(
    'maxBpm',
    _$maxBpm,
    opt: true,
  );

  @override
  final MappableFields<SpeedControlState> fields = const {
    #tempoMode: _f$tempoMode,
    #speedMultiplier: _f$speedMultiplier,
    #originalBpm: _f$originalBpm,
    #currentBpm: _f$currentBpm,
    #minBpm: _f$minBpm,
    #maxBpm: _f$maxBpm,
  };

  static SpeedControlState _instantiate(DecodingData data) {
    return SpeedControlState(
      tempoMode: data.dec(_f$tempoMode),
      speedMultiplier: data.dec(_f$speedMultiplier),
      originalBpm: data.dec(_f$originalBpm),
      currentBpm: data.dec(_f$currentBpm),
      minBpm: data.dec(_f$minBpm),
      maxBpm: data.dec(_f$maxBpm),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SpeedControlState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SpeedControlState>(map);
  }

  static SpeedControlState fromJson(String json) {
    return ensureInitialized().decodeJson<SpeedControlState>(json);
  }
}

mixin SpeedControlStateMappable {
  String toJson() {
    return SpeedControlStateMapper.ensureInitialized()
        .encodeJson<SpeedControlState>(this as SpeedControlState);
  }

  Map<String, dynamic> toMap() {
    return SpeedControlStateMapper.ensureInitialized()
        .encodeMap<SpeedControlState>(this as SpeedControlState);
  }

  SpeedControlStateCopyWith<
    SpeedControlState,
    SpeedControlState,
    SpeedControlState
  >
  get copyWith =>
      _SpeedControlStateCopyWithImpl<SpeedControlState, SpeedControlState>(
        this as SpeedControlState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SpeedControlStateMapper.ensureInitialized().stringifyValue(
      this as SpeedControlState,
    );
  }

  @override
  bool operator ==(Object other) {
    return SpeedControlStateMapper.ensureInitialized().equalsValue(
      this as SpeedControlState,
      other,
    );
  }

  @override
  int get hashCode {
    return SpeedControlStateMapper.ensureInitialized().hashValue(
      this as SpeedControlState,
    );
  }
}

extension SpeedControlStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SpeedControlState, $Out> {
  SpeedControlStateCopyWith<$R, SpeedControlState, $Out>
  get $asSpeedControlState => $base.as(
    (v, t, t2) => _SpeedControlStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class SpeedControlStateCopyWith<
  $R,
  $In extends SpeedControlState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    TempoMode? tempoMode,
    double? speedMultiplier,
    int? originalBpm,
    int? currentBpm,
    int? minBpm,
    int? maxBpm,
  });
  SpeedControlStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SpeedControlStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SpeedControlState, $Out>
    implements SpeedControlStateCopyWith<$R, SpeedControlState, $Out> {
  _SpeedControlStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SpeedControlState> $mapper =
      SpeedControlStateMapper.ensureInitialized();
  @override
  $R call({
    TempoMode? tempoMode,
    double? speedMultiplier,
    Object? originalBpm = $none,
    Object? currentBpm = $none,
    Object? minBpm = $none,
    Object? maxBpm = $none,
  }) => $apply(
    FieldCopyWithData({
      if (tempoMode != null) #tempoMode: tempoMode,
      if (speedMultiplier != null) #speedMultiplier: speedMultiplier,
      if (originalBpm != $none) #originalBpm: originalBpm,
      if (currentBpm != $none) #currentBpm: currentBpm,
      if (minBpm != $none) #minBpm: minBpm,
      if (maxBpm != $none) #maxBpm: maxBpm,
    }),
  );
  @override
  SpeedControlState $make(CopyWithData data) => SpeedControlState(
    tempoMode: data.get(#tempoMode, or: $value.tempoMode),
    speedMultiplier: data.get(#speedMultiplier, or: $value.speedMultiplier),
    originalBpm: data.get(#originalBpm, or: $value.originalBpm),
    currentBpm: data.get(#currentBpm, or: $value.currentBpm),
    minBpm: data.get(#minBpm, or: $value.minBpm),
    maxBpm: data.get(#maxBpm, or: $value.maxBpm),
  );

  @override
  SpeedControlStateCopyWith<$R2, SpeedControlState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SpeedControlStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

