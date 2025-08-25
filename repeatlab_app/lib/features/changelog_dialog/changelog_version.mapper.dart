// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'changelog_version.dart';

class ChangelogVersionMapper extends ClassMapperBase<ChangelogVersion> {
  ChangelogVersionMapper._();

  static ChangelogVersionMapper? _instance;
  static ChangelogVersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChangelogVersionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ChangelogVersion';

  static String _$version(ChangelogVersion v) => v.version;
  static const Field<ChangelogVersion, String> _f$version = Field(
    'version',
    _$version,
  );
  static DateTime _$releaseDate(ChangelogVersion v) => v.releaseDate;
  static const Field<ChangelogVersion, DateTime> _f$releaseDate = Field(
    'releaseDate',
    _$releaseDate,
  );
  static List<ChangelogElement> _$updates(ChangelogVersion v) => v.updates;
  static const Field<ChangelogVersion, List<ChangelogElement>> _f$updates =
      Field('updates', _$updates);

  @override
  final MappableFields<ChangelogVersion> fields = const {
    #version: _f$version,
    #releaseDate: _f$releaseDate,
    #updates: _f$updates,
  };

  static ChangelogVersion _instantiate(DecodingData data) {
    return ChangelogVersion(
      version: data.dec(_f$version),
      releaseDate: data.dec(_f$releaseDate),
      updates: data.dec(_f$updates),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ChangelogVersion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChangelogVersion>(map);
  }

  static ChangelogVersion fromJson(String json) {
    return ensureInitialized().decodeJson<ChangelogVersion>(json);
  }
}

mixin ChangelogVersionMappable {
  String toJson() {
    return ChangelogVersionMapper.ensureInitialized()
        .encodeJson<ChangelogVersion>(this as ChangelogVersion);
  }

  Map<String, dynamic> toMap() {
    return ChangelogVersionMapper.ensureInitialized()
        .encodeMap<ChangelogVersion>(this as ChangelogVersion);
  }

  ChangelogVersionCopyWith<ChangelogVersion, ChangelogVersion, ChangelogVersion>
  get copyWith =>
      _ChangelogVersionCopyWithImpl<ChangelogVersion, ChangelogVersion>(
        this as ChangelogVersion,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ChangelogVersionMapper.ensureInitialized().stringifyValue(
      this as ChangelogVersion,
    );
  }

  @override
  bool operator ==(Object other) {
    return ChangelogVersionMapper.ensureInitialized().equalsValue(
      this as ChangelogVersion,
      other,
    );
  }

  @override
  int get hashCode {
    return ChangelogVersionMapper.ensureInitialized().hashValue(
      this as ChangelogVersion,
    );
  }
}

extension ChangelogVersionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChangelogVersion, $Out> {
  ChangelogVersionCopyWith<$R, ChangelogVersion, $Out>
  get $asChangelogVersion =>
      $base.as((v, t, t2) => _ChangelogVersionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ChangelogVersionCopyWith<$R, $In extends ChangelogVersion, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ChangelogElement,
    ObjectCopyWith<$R, ChangelogElement, ChangelogElement>
  >
  get updates;
  $R call({
    String? version,
    DateTime? releaseDate,
    List<ChangelogElement>? updates,
  });
  ChangelogVersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ChangelogVersionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChangelogVersion, $Out>
    implements ChangelogVersionCopyWith<$R, ChangelogVersion, $Out> {
  _ChangelogVersionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChangelogVersion> $mapper =
      ChangelogVersionMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    ChangelogElement,
    ObjectCopyWith<$R, ChangelogElement, ChangelogElement>
  >
  get updates => ListCopyWith(
    $value.updates,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(updates: v),
  );
  @override
  $R call({
    String? version,
    DateTime? releaseDate,
    List<ChangelogElement>? updates,
  }) => $apply(
    FieldCopyWithData({
      if (version != null) #version: version,
      if (releaseDate != null) #releaseDate: releaseDate,
      if (updates != null) #updates: updates,
    }),
  );
  @override
  ChangelogVersion $make(CopyWithData data) => ChangelogVersion(
    version: data.get(#version, or: $value.version),
    releaseDate: data.get(#releaseDate, or: $value.releaseDate),
    updates: data.get(#updates, or: $value.updates),
  );

  @override
  ChangelogVersionCopyWith<$R2, ChangelogVersion, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ChangelogVersionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

