// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'repeatlab_feature.dart';

class RepeatLabFeatureMapper extends ClassMapperBase<RepeatLabFeature> {
  RepeatLabFeatureMapper._();

  static RepeatLabFeatureMapper? _instance;
  static RepeatLabFeatureMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RepeatLabFeatureMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'RepeatLabFeature';

  static String _$title(RepeatLabFeature v) => v.title;
  static const Field<RepeatLabFeature, String> _f$title = Field(
    'title',
    _$title,
  );
  static bool _$isPremium(RepeatLabFeature v) => v.isPremium;
  static const Field<RepeatLabFeature, bool> _f$isPremium = Field(
    'isPremium',
    _$isPremium,
  );

  @override
  final MappableFields<RepeatLabFeature> fields = const {
    #title: _f$title,
    #isPremium: _f$isPremium,
  };

  static RepeatLabFeature _instantiate(DecodingData data) {
    return RepeatLabFeature(
      title: data.dec(_f$title),
      isPremium: data.dec(_f$isPremium),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RepeatLabFeature fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RepeatLabFeature>(map);
  }

  static RepeatLabFeature fromJson(String json) {
    return ensureInitialized().decodeJson<RepeatLabFeature>(json);
  }
}

mixin RepeatLabFeatureMappable {
  String toJson() {
    return RepeatLabFeatureMapper.ensureInitialized()
        .encodeJson<RepeatLabFeature>(this as RepeatLabFeature);
  }

  Map<String, dynamic> toMap() {
    return RepeatLabFeatureMapper.ensureInitialized()
        .encodeMap<RepeatLabFeature>(this as RepeatLabFeature);
  }

  RepeatLabFeatureCopyWith<RepeatLabFeature, RepeatLabFeature, RepeatLabFeature>
  get copyWith =>
      _RepeatLabFeatureCopyWithImpl<RepeatLabFeature, RepeatLabFeature>(
        this as RepeatLabFeature,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return RepeatLabFeatureMapper.ensureInitialized().stringifyValue(
      this as RepeatLabFeature,
    );
  }

  @override
  bool operator ==(Object other) {
    return RepeatLabFeatureMapper.ensureInitialized().equalsValue(
      this as RepeatLabFeature,
      other,
    );
  }

  @override
  int get hashCode {
    return RepeatLabFeatureMapper.ensureInitialized().hashValue(
      this as RepeatLabFeature,
    );
  }
}

extension RepeatLabFeatureValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RepeatLabFeature, $Out> {
  RepeatLabFeatureCopyWith<$R, RepeatLabFeature, $Out>
  get $asRepeatLabFeature =>
      $base.as((v, t, t2) => _RepeatLabFeatureCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class RepeatLabFeatureCopyWith<$R, $In extends RepeatLabFeature, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? title, bool? isPremium});
  RepeatLabFeatureCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _RepeatLabFeatureCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RepeatLabFeature, $Out>
    implements RepeatLabFeatureCopyWith<$R, RepeatLabFeature, $Out> {
  _RepeatLabFeatureCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RepeatLabFeature> $mapper =
      RepeatLabFeatureMapper.ensureInitialized();
  @override
  $R call({String? title, bool? isPremium}) => $apply(
    FieldCopyWithData({
      if (title != null) #title: title,
      if (isPremium != null) #isPremium: isPremium,
    }),
  );
  @override
  RepeatLabFeature $make(CopyWithData data) => RepeatLabFeature(
    title: data.get(#title, or: $value.title),
    isPremium: data.get(#isPremium, or: $value.isPremium),
  );

  @override
  RepeatLabFeatureCopyWith<$R2, RepeatLabFeature, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _RepeatLabFeatureCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

