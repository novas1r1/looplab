// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'song_exporter_cubit.dart';

class SongExporterStatusMapper extends EnumMapper<SongExporterStatus> {
  SongExporterStatusMapper._();

  static SongExporterStatusMapper? _instance;
  static SongExporterStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SongExporterStatusMapper._());
    }
    return _instance!;
  }

  static SongExporterStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  SongExporterStatus decode(dynamic value) {
    switch (value) {
      case r'initial':
        return SongExporterStatus.initial;
      case r'exporting':
        return SongExporterStatus.exporting;
      case r'exportSuccess':
        return SongExporterStatus.exportSuccess;
      case r'exportError':
        return SongExporterStatus.exportError;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(SongExporterStatus self) {
    switch (self) {
      case SongExporterStatus.initial:
        return r'initial';
      case SongExporterStatus.exporting:
        return r'exporting';
      case SongExporterStatus.exportSuccess:
        return r'exportSuccess';
      case SongExporterStatus.exportError:
        return r'exportError';
    }
  }
}

extension SongExporterStatusMapperExtension on SongExporterStatus {
  String toValue() {
    SongExporterStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<SongExporterStatus>(this) as String;
  }
}

class SongExporterStateMapper extends ClassMapperBase<SongExporterState> {
  SongExporterStateMapper._();

  static SongExporterStateMapper? _instance;
  static SongExporterStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SongExporterStateMapper._());
      SongExporterStatusMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SongExporterState';

  static SongExporterStatus _$status(SongExporterState v) => v.status;
  static const Field<SongExporterState, SongExporterStatus> _f$status = Field(
    'status',
    _$status,
    opt: true,
    def: SongExporterStatus.initial,
  );
  static String? _$errorMessage(SongExporterState v) => v.errorMessage;
  static const Field<SongExporterState, String> _f$errorMessage = Field(
    'errorMessage',
    _$errorMessage,
    opt: true,
  );

  @override
  final MappableFields<SongExporterState> fields = const {
    #status: _f$status,
    #errorMessage: _f$errorMessage,
  };

  static SongExporterState _instantiate(DecodingData data) {
    return SongExporterState(
      status: data.dec(_f$status),
      errorMessage: data.dec(_f$errorMessage),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SongExporterState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SongExporterState>(map);
  }

  static SongExporterState fromJson(String json) {
    return ensureInitialized().decodeJson<SongExporterState>(json);
  }
}

mixin SongExporterStateMappable {
  String toJson() {
    return SongExporterStateMapper.ensureInitialized()
        .encodeJson<SongExporterState>(this as SongExporterState);
  }

  Map<String, dynamic> toMap() {
    return SongExporterStateMapper.ensureInitialized()
        .encodeMap<SongExporterState>(this as SongExporterState);
  }

  SongExporterStateCopyWith<
    SongExporterState,
    SongExporterState,
    SongExporterState
  >
  get copyWith =>
      _SongExporterStateCopyWithImpl<SongExporterState, SongExporterState>(
        this as SongExporterState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SongExporterStateMapper.ensureInitialized().stringifyValue(
      this as SongExporterState,
    );
  }

  @override
  bool operator ==(Object other) {
    return SongExporterStateMapper.ensureInitialized().equalsValue(
      this as SongExporterState,
      other,
    );
  }

  @override
  int get hashCode {
    return SongExporterStateMapper.ensureInitialized().hashValue(
      this as SongExporterState,
    );
  }
}

extension SongExporterStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SongExporterState, $Out> {
  SongExporterStateCopyWith<$R, SongExporterState, $Out>
  get $asSongExporterState => $base.as(
    (v, t, t2) => _SongExporterStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class SongExporterStateCopyWith<
  $R,
  $In extends SongExporterState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({SongExporterStatus? status, String? errorMessage});
  SongExporterStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SongExporterStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SongExporterState, $Out>
    implements SongExporterStateCopyWith<$R, SongExporterState, $Out> {
  _SongExporterStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SongExporterState> $mapper =
      SongExporterStateMapper.ensureInitialized();
  @override
  $R call({SongExporterStatus? status, Object? errorMessage = $none}) => $apply(
    FieldCopyWithData({
      if (status != null) #status: status,
      if (errorMessage != $none) #errorMessage: errorMessage,
    }),
  );
  @override
  SongExporterState $make(CopyWithData data) => SongExporterState(
    status: data.get(#status, or: $value.status),
    errorMessage: data.get(#errorMessage, or: $value.errorMessage),
  );

  @override
  SongExporterStateCopyWith<$R2, SongExporterState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SongExporterStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

