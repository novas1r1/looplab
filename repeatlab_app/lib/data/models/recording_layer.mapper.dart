// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'recording_layer.dart';

class RecordingLayerMapper extends ClassMapperBase<RecordingLayer> {
  RecordingLayerMapper._();

  static RecordingLayerMapper? _instance;
  static RecordingLayerMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RecordingLayerMapper._());
      MapperContainer.globals.useAll([DurationMapper(), DateTimeMapper()]);
    }
    return _instance!;
  }

  @override
  final String id = 'RecordingLayer';

  static String _$id(RecordingLayer v) => v.id;
  static const Field<RecordingLayer, String> _f$id = Field('id', _$id);
  static String _$songId(RecordingLayer v) => v.songId;
  static const Field<RecordingLayer, String> _f$songId = Field(
    'songId',
    _$songId,
  );
  static String _$filePath(RecordingLayer v) => v.filePath;
  static const Field<RecordingLayer, String> _f$filePath = Field(
    'filePath',
    _$filePath,
  );
  static Duration _$startPosition(RecordingLayer v) => v.startPosition;
  static const Field<RecordingLayer, Duration> _f$startPosition = Field(
    'startPosition',
    _$startPosition,
  );
  static Duration _$duration(RecordingLayer v) => v.duration;
  static const Field<RecordingLayer, Duration> _f$duration = Field(
    'duration',
    _$duration,
  );
  static DateTime _$createdAt(RecordingLayer v) => v.createdAt;
  static const Field<RecordingLayer, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
  );
  static double _$volume(RecordingLayer v) => v.volume;
  static const Field<RecordingLayer, double> _f$volume = Field(
    'volume',
    _$volume,
    opt: true,
    def: 1.0,
  );
  static bool _$isMuted(RecordingLayer v) => v.isMuted;
  static const Field<RecordingLayer, bool> _f$isMuted = Field(
    'isMuted',
    _$isMuted,
    opt: true,
    def: false,
  );
  static String? _$label(RecordingLayer v) => v.label;
  static const Field<RecordingLayer, String> _f$label = Field(
    'label',
    _$label,
    opt: true,
  );

  @override
  final MappableFields<RecordingLayer> fields = const {
    #id: _f$id,
    #songId: _f$songId,
    #filePath: _f$filePath,
    #startPosition: _f$startPosition,
    #duration: _f$duration,
    #createdAt: _f$createdAt,
    #volume: _f$volume,
    #isMuted: _f$isMuted,
    #label: _f$label,
  };

  static RecordingLayer _instantiate(DecodingData data) {
    return RecordingLayer(
      id: data.dec(_f$id),
      songId: data.dec(_f$songId),
      filePath: data.dec(_f$filePath),
      startPosition: data.dec(_f$startPosition),
      duration: data.dec(_f$duration),
      createdAt: data.dec(_f$createdAt),
      volume: data.dec(_f$volume),
      isMuted: data.dec(_f$isMuted),
      label: data.dec(_f$label),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RecordingLayer fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RecordingLayer>(map);
  }

  static RecordingLayer fromJson(String json) {
    return ensureInitialized().decodeJson<RecordingLayer>(json);
  }
}

mixin RecordingLayerMappable {
  String toJson() {
    return RecordingLayerMapper.ensureInitialized().encodeJson<RecordingLayer>(
      this as RecordingLayer,
    );
  }

  Map<String, dynamic> toMap() {
    return RecordingLayerMapper.ensureInitialized().encodeMap<RecordingLayer>(
      this as RecordingLayer,
    );
  }

  RecordingLayerCopyWith<RecordingLayer, RecordingLayer, RecordingLayer>
  get copyWith => _RecordingLayerCopyWithImpl<RecordingLayer, RecordingLayer>(
    this as RecordingLayer,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return RecordingLayerMapper.ensureInitialized().stringifyValue(
      this as RecordingLayer,
    );
  }

  @override
  bool operator ==(Object other) {
    return RecordingLayerMapper.ensureInitialized().equalsValue(
      this as RecordingLayer,
      other,
    );
  }

  @override
  int get hashCode {
    return RecordingLayerMapper.ensureInitialized().hashValue(
      this as RecordingLayer,
    );
  }
}

extension RecordingLayerValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RecordingLayer, $Out> {
  RecordingLayerCopyWith<$R, RecordingLayer, $Out> get $asRecordingLayer =>
      $base.as((v, t, t2) => _RecordingLayerCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class RecordingLayerCopyWith<$R, $In extends RecordingLayer, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? songId,
    String? filePath,
    Duration? startPosition,
    Duration? duration,
    DateTime? createdAt,
    double? volume,
    bool? isMuted,
    String? label,
  });
  RecordingLayerCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _RecordingLayerCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RecordingLayer, $Out>
    implements RecordingLayerCopyWith<$R, RecordingLayer, $Out> {
  _RecordingLayerCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RecordingLayer> $mapper =
      RecordingLayerMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? songId,
    String? filePath,
    Duration? startPosition,
    Duration? duration,
    DateTime? createdAt,
    double? volume,
    bool? isMuted,
    Object? label = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (songId != null) #songId: songId,
      if (filePath != null) #filePath: filePath,
      if (startPosition != null) #startPosition: startPosition,
      if (duration != null) #duration: duration,
      if (createdAt != null) #createdAt: createdAt,
      if (volume != null) #volume: volume,
      if (isMuted != null) #isMuted: isMuted,
      if (label != $none) #label: label,
    }),
  );
  @override
  RecordingLayer $make(CopyWithData data) => RecordingLayer(
    id: data.get(#id, or: $value.id),
    songId: data.get(#songId, or: $value.songId),
    filePath: data.get(#filePath, or: $value.filePath),
    startPosition: data.get(#startPosition, or: $value.startPosition),
    duration: data.get(#duration, or: $value.duration),
    createdAt: data.get(#createdAt, or: $value.createdAt),
    volume: data.get(#volume, or: $value.volume),
    isMuted: data.get(#isMuted, or: $value.isMuted),
    label: data.get(#label, or: $value.label),
  );

  @override
  RecordingLayerCopyWith<$R2, RecordingLayer, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _RecordingLayerCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

