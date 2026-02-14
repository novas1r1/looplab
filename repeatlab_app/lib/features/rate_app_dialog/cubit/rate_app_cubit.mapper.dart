// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'rate_app_cubit.dart';

class RateAppStatusMapper extends EnumMapper<RateAppStatus> {
  RateAppStatusMapper._();

  static RateAppStatusMapper? _instance;
  static RateAppStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RateAppStatusMapper._());
    }
    return _instance!;
  }

  static RateAppStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  RateAppStatus decode(dynamic value) {
    switch (value) {
      case r'initial':
        return RateAppStatus.initial;
      case r'rated':
        return RateAppStatus.rated;
      case r'notRated':
        return RateAppStatus.notRated;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(RateAppStatus self) {
    switch (self) {
      case RateAppStatus.initial:
        return r'initial';
      case RateAppStatus.rated:
        return r'rated';
      case RateAppStatus.notRated:
        return r'notRated';
    }
  }
}

extension RateAppStatusMapperExtension on RateAppStatus {
  String toValue() {
    RateAppStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<RateAppStatus>(this) as String;
  }
}

class RateAppStateMapper extends ClassMapperBase<RateAppState> {
  RateAppStateMapper._();

  static RateAppStateMapper? _instance;
  static RateAppStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RateAppStateMapper._());
      RateAppStatusMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'RateAppState';

  static RateAppStatus _$status(RateAppState v) => v.status;
  static const Field<RateAppState, RateAppStatus> _f$status = Field(
    'status',
    _$status,
    opt: true,
    def: RateAppStatus.initial,
  );
  static bool _$shouldShowDialog(RateAppState v) => v.shouldShowDialog;
  static const Field<RateAppState, bool> _f$shouldShowDialog = Field(
    'shouldShowDialog',
    _$shouldShowDialog,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<RateAppState> fields = const {
    #status: _f$status,
    #shouldShowDialog: _f$shouldShowDialog,
  };

  static RateAppState _instantiate(DecodingData data) {
    return RateAppState(
      status: data.dec(_f$status),
      shouldShowDialog: data.dec(_f$shouldShowDialog),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RateAppState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RateAppState>(map);
  }

  static RateAppState fromJson(String json) {
    return ensureInitialized().decodeJson<RateAppState>(json);
  }
}

mixin RateAppStateMappable {
  String toJson() {
    return RateAppStateMapper.ensureInitialized().encodeJson<RateAppState>(
      this as RateAppState,
    );
  }

  Map<String, dynamic> toMap() {
    return RateAppStateMapper.ensureInitialized().encodeMap<RateAppState>(
      this as RateAppState,
    );
  }

  RateAppStateCopyWith<RateAppState, RateAppState, RateAppState> get copyWith =>
      _RateAppStateCopyWithImpl<RateAppState, RateAppState>(
        this as RateAppState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return RateAppStateMapper.ensureInitialized().stringifyValue(
      this as RateAppState,
    );
  }

  @override
  bool operator ==(Object other) {
    return RateAppStateMapper.ensureInitialized().equalsValue(
      this as RateAppState,
      other,
    );
  }

  @override
  int get hashCode {
    return RateAppStateMapper.ensureInitialized().hashValue(
      this as RateAppState,
    );
  }
}

extension RateAppStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RateAppState, $Out> {
  RateAppStateCopyWith<$R, RateAppState, $Out> get $asRateAppState =>
      $base.as((v, t, t2) => _RateAppStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class RateAppStateCopyWith<$R, $In extends RateAppState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({RateAppStatus? status, bool? shouldShowDialog});
  RateAppStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _RateAppStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RateAppState, $Out>
    implements RateAppStateCopyWith<$R, RateAppState, $Out> {
  _RateAppStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RateAppState> $mapper =
      RateAppStateMapper.ensureInitialized();
  @override
  $R call({RateAppStatus? status, bool? shouldShowDialog}) => $apply(
    FieldCopyWithData({
      if (status != null) #status: status,
      if (shouldShowDialog != null) #shouldShowDialog: shouldShowDialog,
    }),
  );
  @override
  RateAppState $make(CopyWithData data) => RateAppState(
    status: data.get(#status, or: $value.status),
    shouldShowDialog: data.get(#shouldShowDialog, or: $value.shouldShowDialog),
  );

  @override
  RateAppStateCopyWith<$R2, RateAppState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _RateAppStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

