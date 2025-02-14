// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'changelog_dialog_cubit.dart';

class ChangelogStatusMapper extends EnumMapper<ChangelogStatus> {
  ChangelogStatusMapper._();

  static ChangelogStatusMapper? _instance;
  static ChangelogStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChangelogStatusMapper._());
    }
    return _instance!;
  }

  static ChangelogStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ChangelogStatus decode(dynamic value) {
    switch (value) {
      case 'loading':
        return ChangelogStatus.loading;
      case 'loaded':
        return ChangelogStatus.loaded;
      case 'error':
        return ChangelogStatus.error;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ChangelogStatus self) {
    switch (self) {
      case ChangelogStatus.loading:
        return 'loading';
      case ChangelogStatus.loaded:
        return 'loaded';
      case ChangelogStatus.error:
        return 'error';
    }
  }
}

extension ChangelogStatusMapperExtension on ChangelogStatus {
  String toValue() {
    ChangelogStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ChangelogStatus>(this) as String;
  }
}

class ChangelogDialogStateMapper extends ClassMapperBase<ChangelogDialogState> {
  ChangelogDialogStateMapper._();

  static ChangelogDialogStateMapper? _instance;
  static ChangelogDialogStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChangelogDialogStateMapper._());
      ChangelogStatusMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ChangelogDialogState';

  static ChangelogStatus _$status(ChangelogDialogState v) => v.status;
  static const Field<ChangelogDialogState, ChangelogStatus> _f$status =
      Field('status', _$status, opt: true, def: ChangelogStatus.loading);
  static bool _$shouldShowDialog(ChangelogDialogState v) => v.shouldShowDialog;
  static const Field<ChangelogDialogState, bool> _f$shouldShowDialog =
      Field('shouldShowDialog', _$shouldShowDialog, opt: true, def: false);
  static String? _$errorMessage(ChangelogDialogState v) => v.errorMessage;
  static const Field<ChangelogDialogState, String> _f$errorMessage =
      Field('errorMessage', _$errorMessage, opt: true);

  @override
  final MappableFields<ChangelogDialogState> fields = const {
    #status: _f$status,
    #shouldShowDialog: _f$shouldShowDialog,
    #errorMessage: _f$errorMessage,
  };

  static ChangelogDialogState _instantiate(DecodingData data) {
    return ChangelogDialogState(
        status: data.dec(_f$status),
        shouldShowDialog: data.dec(_f$shouldShowDialog),
        errorMessage: data.dec(_f$errorMessage));
  }

  @override
  final Function instantiate = _instantiate;

  static ChangelogDialogState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChangelogDialogState>(map);
  }

  static ChangelogDialogState fromJson(String json) {
    return ensureInitialized().decodeJson<ChangelogDialogState>(json);
  }
}

mixin ChangelogDialogStateMappable {
  String toJson() {
    return ChangelogDialogStateMapper.ensureInitialized()
        .encodeJson<ChangelogDialogState>(this as ChangelogDialogState);
  }

  Map<String, dynamic> toMap() {
    return ChangelogDialogStateMapper.ensureInitialized()
        .encodeMap<ChangelogDialogState>(this as ChangelogDialogState);
  }

  ChangelogDialogStateCopyWith<ChangelogDialogState, ChangelogDialogState,
          ChangelogDialogState>
      get copyWith => _ChangelogDialogStateCopyWithImpl(
          this as ChangelogDialogState, $identity, $identity);
  @override
  String toString() {
    return ChangelogDialogStateMapper.ensureInitialized()
        .stringifyValue(this as ChangelogDialogState);
  }

  @override
  bool operator ==(Object other) {
    return ChangelogDialogStateMapper.ensureInitialized()
        .equalsValue(this as ChangelogDialogState, other);
  }

  @override
  int get hashCode {
    return ChangelogDialogStateMapper.ensureInitialized()
        .hashValue(this as ChangelogDialogState);
  }
}

extension ChangelogDialogStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChangelogDialogState, $Out> {
  ChangelogDialogStateCopyWith<$R, ChangelogDialogState, $Out>
      get $asChangelogDialogState =>
          $base.as((v, t, t2) => _ChangelogDialogStateCopyWithImpl(v, t, t2));
}

abstract class ChangelogDialogStateCopyWith<
    $R,
    $In extends ChangelogDialogState,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {ChangelogStatus? status, bool? shouldShowDialog, String? errorMessage});
  ChangelogDialogStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ChangelogDialogStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChangelogDialogState, $Out>
    implements ChangelogDialogStateCopyWith<$R, ChangelogDialogState, $Out> {
  _ChangelogDialogStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChangelogDialogState> $mapper =
      ChangelogDialogStateMapper.ensureInitialized();
  @override
  $R call(
          {ChangelogStatus? status,
          bool? shouldShowDialog,
          Object? errorMessage = $none}) =>
      $apply(FieldCopyWithData({
        if (status != null) #status: status,
        if (shouldShowDialog != null) #shouldShowDialog: shouldShowDialog,
        if (errorMessage != $none) #errorMessage: errorMessage
      }));
  @override
  ChangelogDialogState $make(CopyWithData data) => ChangelogDialogState(
      status: data.get(#status, or: $value.status),
      shouldShowDialog:
          data.get(#shouldShowDialog, or: $value.shouldShowDialog),
      errorMessage: data.get(#errorMessage, or: $value.errorMessage));

  @override
  ChangelogDialogStateCopyWith<$R2, ChangelogDialogState, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _ChangelogDialogStateCopyWithImpl($value, $cast, t);
}
