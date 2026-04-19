// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'backup_cubit.dart';

class BackupStateMapper extends ClassMapperBase<BackupState> {
  BackupStateMapper._();

  static BackupStateMapper? _instance;
  static BackupStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BackupStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'BackupState';

  static BackupStatus _$status(BackupState v) => v.status;
  static const Field<BackupState, BackupStatus> _f$status = Field(
    'status',
    _$status,
    opt: true,
    def: BackupStatus.idle,
  );
  static String? _$errorMessage(BackupState v) => v.errorMessage;
  static const Field<BackupState, String> _f$errorMessage = Field(
    'errorMessage',
    _$errorMessage,
    opt: true,
  );
  static BackupImportSummary? _$lastImportSummary(BackupState v) =>
      v.lastImportSummary;
  static const Field<BackupState, BackupImportSummary> _f$lastImportSummary =
      Field('lastImportSummary', _$lastImportSummary, opt: true);

  @override
  final MappableFields<BackupState> fields = const {
    #status: _f$status,
    #errorMessage: _f$errorMessage,
    #lastImportSummary: _f$lastImportSummary,
  };

  static BackupState _instantiate(DecodingData data) {
    return BackupState(
      status: data.dec(_f$status),
      errorMessage: data.dec(_f$errorMessage),
      lastImportSummary: data.dec(_f$lastImportSummary),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static BackupState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BackupState>(map);
  }

  static BackupState fromJson(String json) {
    return ensureInitialized().decodeJson<BackupState>(json);
  }
}

mixin BackupStateMappable {
  String toJson() {
    return BackupStateMapper.ensureInitialized().encodeJson<BackupState>(
      this as BackupState,
    );
  }

  Map<String, dynamic> toMap() {
    return BackupStateMapper.ensureInitialized().encodeMap<BackupState>(
      this as BackupState,
    );
  }

  BackupStateCopyWith<BackupState, BackupState, BackupState> get copyWith =>
      _BackupStateCopyWithImpl<BackupState, BackupState>(
        this as BackupState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return BackupStateMapper.ensureInitialized().stringifyValue(
      this as BackupState,
    );
  }

  @override
  bool operator ==(Object other) {
    return BackupStateMapper.ensureInitialized().equalsValue(
      this as BackupState,
      other,
    );
  }

  @override
  int get hashCode {
    return BackupStateMapper.ensureInitialized().hashValue(this as BackupState);
  }
}

extension BackupStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, BackupState, $Out> {
  BackupStateCopyWith<$R, BackupState, $Out> get $asBackupState =>
      $base.as((v, t, t2) => _BackupStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class BackupStateCopyWith<$R, $In extends BackupState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    BackupStatus? status,
    String? errorMessage,
    BackupImportSummary? lastImportSummary,
  });
  BackupStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _BackupStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, BackupState, $Out>
    implements BackupStateCopyWith<$R, BackupState, $Out> {
  _BackupStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<BackupState> $mapper =
      BackupStateMapper.ensureInitialized();
  @override
  $R call({
    BackupStatus? status,
    Object? errorMessage = $none,
    Object? lastImportSummary = $none,
  }) => $apply(
    FieldCopyWithData({
      if (status != null) #status: status,
      if (errorMessage != $none) #errorMessage: errorMessage,
      if (lastImportSummary != $none) #lastImportSummary: lastImportSummary,
    }),
  );
  @override
  BackupState $make(CopyWithData data) => BackupState(
    status: data.get(#status, or: $value.status),
    errorMessage: data.get(#errorMessage, or: $value.errorMessage),
    lastImportSummary: data.get(
      #lastImportSummary,
      or: $value.lastImportSummary,
    ),
  );

  @override
  BackupStateCopyWith<$R2, BackupState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _BackupStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

