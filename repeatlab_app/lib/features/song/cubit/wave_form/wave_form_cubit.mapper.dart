// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'wave_form_cubit.dart';

class WaveFormStateMapper extends ClassMapperBase<WaveFormState> {
  WaveFormStateMapper._();

  static WaveFormStateMapper? _instance;
  static WaveFormStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WaveFormStateMapper._());
      LoopMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'WaveFormState';

  static WaveFormStateStatus _$status(WaveFormState v) => v.status;
  static const Field<WaveFormState, WaveFormStateStatus> _f$status = Field(
    'status',
    _$status,
    opt: true,
    def: WaveFormStateStatus.loading,
  );
  static Float32List? _$waveformData(WaveFormState v) => v.waveformData;
  static const Field<WaveFormState, Float32List> _f$waveformData = Field(
    'waveformData',
    _$waveformData,
    opt: true,
  );
  static Duration _$duration(WaveFormState v) => v.duration;
  static const Field<WaveFormState, Duration> _f$duration = Field(
    'duration',
    _$duration,
    opt: true,
    def: Duration.zero,
  );
  static Duration _$currentPosition(WaveFormState v) => v.currentPosition;
  static const Field<WaveFormState, Duration> _f$currentPosition = Field(
    'currentPosition',
    _$currentPosition,
    opt: true,
    def: Duration.zero,
  );
  static double _$waveformWidth(WaveFormState v) => v.waveformWidth;
  static const Field<WaveFormState, double> _f$waveformWidth = Field(
    'waveformWidth',
    _$waveformWidth,
    opt: true,
    def: 0.0,
  );
  static double _$screenWidth(WaveFormState v) => v.screenWidth;
  static const Field<WaveFormState, double> _f$screenWidth = Field(
    'screenWidth',
    _$screenWidth,
    opt: true,
    def: 0.0,
  );
  static List<Loop> _$loops(WaveFormState v) => v.loops;
  static const Field<WaveFormState, List<Loop>> _f$loops = Field(
    'loops',
    _$loops,
    opt: true,
    def: const [],
  );
  static Exception? _$error(WaveFormState v) => v.error;
  static const Field<WaveFormState, Exception> _f$error = Field(
    'error',
    _$error,
    opt: true,
  );

  @override
  final MappableFields<WaveFormState> fields = const {
    #status: _f$status,
    #waveformData: _f$waveformData,
    #duration: _f$duration,
    #currentPosition: _f$currentPosition,
    #waveformWidth: _f$waveformWidth,
    #screenWidth: _f$screenWidth,
    #loops: _f$loops,
    #error: _f$error,
  };

  static WaveFormState _instantiate(DecodingData data) {
    return WaveFormState(
      status: data.dec(_f$status),
      waveformData: data.dec(_f$waveformData),
      duration: data.dec(_f$duration),
      currentPosition: data.dec(_f$currentPosition),
      waveformWidth: data.dec(_f$waveformWidth),
      screenWidth: data.dec(_f$screenWidth),
      loops: data.dec(_f$loops),
      error: data.dec(_f$error),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static WaveFormState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WaveFormState>(map);
  }

  static WaveFormState fromJson(String json) {
    return ensureInitialized().decodeJson<WaveFormState>(json);
  }
}

mixin WaveFormStateMappable {
  String toJson() {
    return WaveFormStateMapper.ensureInitialized().encodeJson<WaveFormState>(
      this as WaveFormState,
    );
  }

  Map<String, dynamic> toMap() {
    return WaveFormStateMapper.ensureInitialized().encodeMap<WaveFormState>(
      this as WaveFormState,
    );
  }

  WaveFormStateCopyWith<WaveFormState, WaveFormState, WaveFormState>
  get copyWith => _WaveFormStateCopyWithImpl<WaveFormState, WaveFormState>(
    this as WaveFormState,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return WaveFormStateMapper.ensureInitialized().stringifyValue(
      this as WaveFormState,
    );
  }

  @override
  bool operator ==(Object other) {
    return WaveFormStateMapper.ensureInitialized().equalsValue(
      this as WaveFormState,
      other,
    );
  }

  @override
  int get hashCode {
    return WaveFormStateMapper.ensureInitialized().hashValue(
      this as WaveFormState,
    );
  }
}

extension WaveFormStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WaveFormState, $Out> {
  WaveFormStateCopyWith<$R, WaveFormState, $Out> get $asWaveFormState =>
      $base.as((v, t, t2) => _WaveFormStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class WaveFormStateCopyWith<$R, $In extends WaveFormState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Loop, LoopCopyWith<$R, Loop, Loop>> get loops;
  $R call({
    WaveFormStateStatus? status,
    Float32List? waveformData,
    Duration? duration,
    Duration? currentPosition,
    double? waveformWidth,
    double? screenWidth,
    List<Loop>? loops,
    Exception? error,
  });
  WaveFormStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _WaveFormStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WaveFormState, $Out>
    implements WaveFormStateCopyWith<$R, WaveFormState, $Out> {
  _WaveFormStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WaveFormState> $mapper =
      WaveFormStateMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Loop, LoopCopyWith<$R, Loop, Loop>> get loops =>
      ListCopyWith(
        $value.loops,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(loops: v),
      );
  @override
  $R call({
    WaveFormStateStatus? status,
    Object? waveformData = $none,
    Duration? duration,
    Duration? currentPosition,
    double? waveformWidth,
    double? screenWidth,
    List<Loop>? loops,
    Object? error = $none,
  }) => $apply(
    FieldCopyWithData({
      if (status != null) #status: status,
      if (waveformData != $none) #waveformData: waveformData,
      if (duration != null) #duration: duration,
      if (currentPosition != null) #currentPosition: currentPosition,
      if (waveformWidth != null) #waveformWidth: waveformWidth,
      if (screenWidth != null) #screenWidth: screenWidth,
      if (loops != null) #loops: loops,
      if (error != $none) #error: error,
    }),
  );
  @override
  WaveFormState $make(CopyWithData data) => WaveFormState(
    status: data.get(#status, or: $value.status),
    waveformData: data.get(#waveformData, or: $value.waveformData),
    duration: data.get(#duration, or: $value.duration),
    currentPosition: data.get(#currentPosition, or: $value.currentPosition),
    waveformWidth: data.get(#waveformWidth, or: $value.waveformWidth),
    screenWidth: data.get(#screenWidth, or: $value.screenWidth),
    loops: data.get(#loops, or: $value.loops),
    error: data.get(#error, or: $value.error),
  );

  @override
  WaveFormStateCopyWith<$R2, WaveFormState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _WaveFormStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

