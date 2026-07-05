// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'backup_manifest.dart';

class BackupManifestMapper extends ClassMapperBase<BackupManifest> {
  BackupManifestMapper._();

  static BackupManifestMapper? _instance;
  static BackupManifestMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BackupManifestMapper._());
      BackupFileInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'BackupManifest';

  static int _$schemaVersion(BackupManifest v) => v.schemaVersion;
  static const Field<BackupManifest, int> _f$schemaVersion = Field(
    'schemaVersion',
    _$schemaVersion,
  );
  static String _$appVersion(BackupManifest v) => v.appVersion;
  static const Field<BackupManifest, String> _f$appVersion = Field(
    'appVersion',
    _$appVersion,
  );
  static String _$exportedAt(BackupManifest v) => v.exportedAt;
  static const Field<BackupManifest, String> _f$exportedAt = Field(
    'exportedAt',
    _$exportedAt,
  );
  static int _$songCount(BackupManifest v) => v.songCount;
  static const Field<BackupManifest, int> _f$songCount = Field(
    'songCount',
    _$songCount,
  );
  static Map<String, BackupFileInfo> _$audioFiles(BackupManifest v) =>
      v.audioFiles;
  static const Field<BackupManifest, Map<String, BackupFileInfo>>
  _f$audioFiles = Field('audioFiles', _$audioFiles);

  @override
  final MappableFields<BackupManifest> fields = const {
    #schemaVersion: _f$schemaVersion,
    #appVersion: _f$appVersion,
    #exportedAt: _f$exportedAt,
    #songCount: _f$songCount,
    #audioFiles: _f$audioFiles,
  };

  static BackupManifest _instantiate(DecodingData data) {
    return BackupManifest(
      schemaVersion: data.dec(_f$schemaVersion),
      appVersion: data.dec(_f$appVersion),
      exportedAt: data.dec(_f$exportedAt),
      songCount: data.dec(_f$songCount),
      audioFiles: data.dec(_f$audioFiles),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static BackupManifest fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BackupManifest>(map);
  }

  static BackupManifest fromJson(String json) {
    return ensureInitialized().decodeJson<BackupManifest>(json);
  }
}

mixin BackupManifestMappable {
  String toJson() {
    return BackupManifestMapper.ensureInitialized().encodeJson<BackupManifest>(
      this as BackupManifest,
    );
  }

  Map<String, dynamic> toMap() {
    return BackupManifestMapper.ensureInitialized().encodeMap<BackupManifest>(
      this as BackupManifest,
    );
  }

  BackupManifestCopyWith<BackupManifest, BackupManifest, BackupManifest>
  get copyWith => _BackupManifestCopyWithImpl<BackupManifest, BackupManifest>(
    this as BackupManifest,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return BackupManifestMapper.ensureInitialized().stringifyValue(
      this as BackupManifest,
    );
  }

  @override
  bool operator ==(Object other) {
    return BackupManifestMapper.ensureInitialized().equalsValue(
      this as BackupManifest,
      other,
    );
  }

  @override
  int get hashCode {
    return BackupManifestMapper.ensureInitialized().hashValue(
      this as BackupManifest,
    );
  }
}

extension BackupManifestValueCopy<$R, $Out>
    on ObjectCopyWith<$R, BackupManifest, $Out> {
  BackupManifestCopyWith<$R, BackupManifest, $Out> get $asBackupManifest =>
      $base.as((v, t, t2) => _BackupManifestCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class BackupManifestCopyWith<$R, $In extends BackupManifest, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    BackupFileInfo,
    BackupFileInfoCopyWith<$R, BackupFileInfo, BackupFileInfo>
  >
  get audioFiles;
  $R call({
    int? schemaVersion,
    String? appVersion,
    String? exportedAt,
    int? songCount,
    Map<String, BackupFileInfo>? audioFiles,
  });
  BackupManifestCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _BackupManifestCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, BackupManifest, $Out>
    implements BackupManifestCopyWith<$R, BackupManifest, $Out> {
  _BackupManifestCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<BackupManifest> $mapper =
      BackupManifestMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    BackupFileInfo,
    BackupFileInfoCopyWith<$R, BackupFileInfo, BackupFileInfo>
  >
  get audioFiles => MapCopyWith(
    $value.audioFiles,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(audioFiles: v),
  );
  @override
  $R call({
    int? schemaVersion,
    String? appVersion,
    String? exportedAt,
    int? songCount,
    Map<String, BackupFileInfo>? audioFiles,
  }) => $apply(
    FieldCopyWithData({
      if (schemaVersion != null) #schemaVersion: schemaVersion,
      if (appVersion != null) #appVersion: appVersion,
      if (exportedAt != null) #exportedAt: exportedAt,
      if (songCount != null) #songCount: songCount,
      if (audioFiles != null) #audioFiles: audioFiles,
    }),
  );
  @override
  BackupManifest $make(CopyWithData data) => BackupManifest(
    schemaVersion: data.get(#schemaVersion, or: $value.schemaVersion),
    appVersion: data.get(#appVersion, or: $value.appVersion),
    exportedAt: data.get(#exportedAt, or: $value.exportedAt),
    songCount: data.get(#songCount, or: $value.songCount),
    audioFiles: data.get(#audioFiles, or: $value.audioFiles),
  );

  @override
  BackupManifestCopyWith<$R2, BackupManifest, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _BackupManifestCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class BackupFileInfoMapper extends ClassMapperBase<BackupFileInfo> {
  BackupFileInfoMapper._();

  static BackupFileInfoMapper? _instance;
  static BackupFileInfoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BackupFileInfoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'BackupFileInfo';

  static int _$size(BackupFileInfo v) => v.size;
  static const Field<BackupFileInfo, int> _f$size = Field('size', _$size);
  static String? _$sha256(BackupFileInfo v) => v.sha256;
  static const Field<BackupFileInfo, String> _f$sha256 = Field(
    'sha256',
    _$sha256,
    opt: true,
  );

  @override
  final MappableFields<BackupFileInfo> fields = const {
    #size: _f$size,
    #sha256: _f$sha256,
  };

  static BackupFileInfo _instantiate(DecodingData data) {
    return BackupFileInfo(size: data.dec(_f$size), sha256: data.dec(_f$sha256));
  }

  @override
  final Function instantiate = _instantiate;

  static BackupFileInfo fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BackupFileInfo>(map);
  }

  static BackupFileInfo fromJson(String json) {
    return ensureInitialized().decodeJson<BackupFileInfo>(json);
  }
}

mixin BackupFileInfoMappable {
  String toJson() {
    return BackupFileInfoMapper.ensureInitialized().encodeJson<BackupFileInfo>(
      this as BackupFileInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return BackupFileInfoMapper.ensureInitialized().encodeMap<BackupFileInfo>(
      this as BackupFileInfo,
    );
  }

  BackupFileInfoCopyWith<BackupFileInfo, BackupFileInfo, BackupFileInfo>
  get copyWith => _BackupFileInfoCopyWithImpl<BackupFileInfo, BackupFileInfo>(
    this as BackupFileInfo,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return BackupFileInfoMapper.ensureInitialized().stringifyValue(
      this as BackupFileInfo,
    );
  }

  @override
  bool operator ==(Object other) {
    return BackupFileInfoMapper.ensureInitialized().equalsValue(
      this as BackupFileInfo,
      other,
    );
  }

  @override
  int get hashCode {
    return BackupFileInfoMapper.ensureInitialized().hashValue(
      this as BackupFileInfo,
    );
  }
}

extension BackupFileInfoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, BackupFileInfo, $Out> {
  BackupFileInfoCopyWith<$R, BackupFileInfo, $Out> get $asBackupFileInfo =>
      $base.as((v, t, t2) => _BackupFileInfoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class BackupFileInfoCopyWith<$R, $In extends BackupFileInfo, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? size, String? sha256});
  BackupFileInfoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _BackupFileInfoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, BackupFileInfo, $Out>
    implements BackupFileInfoCopyWith<$R, BackupFileInfo, $Out> {
  _BackupFileInfoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<BackupFileInfo> $mapper =
      BackupFileInfoMapper.ensureInitialized();
  @override
  $R call({int? size, Object? sha256 = $none}) => $apply(
    FieldCopyWithData({
      if (size != null) #size: size,
      if (sha256 != $none) #sha256: sha256,
    }),
  );
  @override
  BackupFileInfo $make(CopyWithData data) => BackupFileInfo(
    size: data.get(#size, or: $value.size),
    sha256: data.get(#sha256, or: $value.sha256),
  );

  @override
  BackupFileInfoCopyWith<$R2, BackupFileInfo, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _BackupFileInfoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

