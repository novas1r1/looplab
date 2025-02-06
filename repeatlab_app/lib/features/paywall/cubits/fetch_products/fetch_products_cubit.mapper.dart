// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'fetch_products_cubit.dart';

class FetchProductsStatusMapper extends EnumMapper<FetchProductsStatus> {
  FetchProductsStatusMapper._();

  static FetchProductsStatusMapper? _instance;
  static FetchProductsStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FetchProductsStatusMapper._());
    }
    return _instance!;
  }

  static FetchProductsStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  FetchProductsStatus decode(dynamic value) {
    switch (value) {
      case 'loading':
        return FetchProductsStatus.loading;
      case 'success':
        return FetchProductsStatus.success;
      case 'failure':
        return FetchProductsStatus.failure;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(FetchProductsStatus self) {
    switch (self) {
      case FetchProductsStatus.loading:
        return 'loading';
      case FetchProductsStatus.success:
        return 'success';
      case FetchProductsStatus.failure:
        return 'failure';
    }
  }
}

extension FetchProductsStatusMapperExtension on FetchProductsStatus {
  String toValue() {
    FetchProductsStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<FetchProductsStatus>(this) as String;
  }
}

class FetchProductsActionMapper extends EnumMapper<FetchProductsAction> {
  FetchProductsActionMapper._();

  static FetchProductsActionMapper? _instance;
  static FetchProductsActionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FetchProductsActionMapper._());
    }
    return _instance!;
  }

  static FetchProductsAction fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  FetchProductsAction decode(dynamic value) {
    switch (value) {
      case 'none':
        return FetchProductsAction.none;
      case 'fetch':
        return FetchProductsAction.fetch;
      case 'purchase':
        return FetchProductsAction.purchase;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(FetchProductsAction self) {
    switch (self) {
      case FetchProductsAction.none:
        return 'none';
      case FetchProductsAction.fetch:
        return 'fetch';
      case FetchProductsAction.purchase:
        return 'purchase';
    }
  }
}

extension FetchProductsActionMapperExtension on FetchProductsAction {
  String toValue() {
    FetchProductsActionMapper.ensureInitialized();
    return MapperContainer.globals.toValue<FetchProductsAction>(this) as String;
  }
}

class FetchProductsStateMapper extends ClassMapperBase<FetchProductsState> {
  FetchProductsStateMapper._();

  static FetchProductsStateMapper? _instance;
  static FetchProductsStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FetchProductsStateMapper._());
      FetchProductsStatusMapper.ensureInitialized();
      FetchProductsActionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FetchProductsState';

  static FetchProductsStatus _$status(FetchProductsState v) => v.status;
  static const Field<FetchProductsState, FetchProductsStatus> _f$status =
      Field('status', _$status, opt: true, def: FetchProductsStatus.loading);
  static FetchProductsAction _$action(FetchProductsState v) => v.action;
  static const Field<FetchProductsState, FetchProductsAction> _f$action =
      Field('action', _$action, opt: true, def: FetchProductsAction.none);
  static Package? _$annualPackage(FetchProductsState v) => v.annualPackage;
  static const Field<FetchProductsState, Package> _f$annualPackage =
      Field('annualPackage', _$annualPackage, opt: true);
  static Package? _$lifetimePackage(FetchProductsState v) => v.lifetimePackage;
  static const Field<FetchProductsState, Package> _f$lifetimePackage =
      Field('lifetimePackage', _$lifetimePackage, opt: true);
  static String? _$errorMessage(FetchProductsState v) => v.errorMessage;
  static const Field<FetchProductsState, String> _f$errorMessage =
      Field('errorMessage', _$errorMessage, opt: true);

  @override
  final MappableFields<FetchProductsState> fields = const {
    #status: _f$status,
    #action: _f$action,
    #annualPackage: _f$annualPackage,
    #lifetimePackage: _f$lifetimePackage,
    #errorMessage: _f$errorMessage,
  };

  static FetchProductsState _instantiate(DecodingData data) {
    return FetchProductsState(
        status: data.dec(_f$status),
        action: data.dec(_f$action),
        annualPackage: data.dec(_f$annualPackage),
        lifetimePackage: data.dec(_f$lifetimePackage),
        errorMessage: data.dec(_f$errorMessage));
  }

  @override
  final Function instantiate = _instantiate;

  static FetchProductsState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FetchProductsState>(map);
  }

  static FetchProductsState fromJson(String json) {
    return ensureInitialized().decodeJson<FetchProductsState>(json);
  }
}

mixin FetchProductsStateMappable {
  String toJson() {
    return FetchProductsStateMapper.ensureInitialized()
        .encodeJson<FetchProductsState>(this as FetchProductsState);
  }

  Map<String, dynamic> toMap() {
    return FetchProductsStateMapper.ensureInitialized()
        .encodeMap<FetchProductsState>(this as FetchProductsState);
  }

  FetchProductsStateCopyWith<FetchProductsState, FetchProductsState,
          FetchProductsState>
      get copyWith => _FetchProductsStateCopyWithImpl(
          this as FetchProductsState, $identity, $identity);
  @override
  String toString() {
    return FetchProductsStateMapper.ensureInitialized()
        .stringifyValue(this as FetchProductsState);
  }

  @override
  bool operator ==(Object other) {
    return FetchProductsStateMapper.ensureInitialized()
        .equalsValue(this as FetchProductsState, other);
  }

  @override
  int get hashCode {
    return FetchProductsStateMapper.ensureInitialized()
        .hashValue(this as FetchProductsState);
  }
}

extension FetchProductsStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FetchProductsState, $Out> {
  FetchProductsStateCopyWith<$R, FetchProductsState, $Out>
      get $asFetchProductsState =>
          $base.as((v, t, t2) => _FetchProductsStateCopyWithImpl(v, t, t2));
}

abstract class FetchProductsStateCopyWith<$R, $In extends FetchProductsState,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {FetchProductsStatus? status,
      FetchProductsAction? action,
      Package? annualPackage,
      Package? lifetimePackage,
      String? errorMessage});
  FetchProductsStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _FetchProductsStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FetchProductsState, $Out>
    implements FetchProductsStateCopyWith<$R, FetchProductsState, $Out> {
  _FetchProductsStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FetchProductsState> $mapper =
      FetchProductsStateMapper.ensureInitialized();
  @override
  $R call(
          {FetchProductsStatus? status,
          FetchProductsAction? action,
          Object? annualPackage = $none,
          Object? lifetimePackage = $none,
          Object? errorMessage = $none}) =>
      $apply(FieldCopyWithData({
        if (status != null) #status: status,
        if (action != null) #action: action,
        if (annualPackage != $none) #annualPackage: annualPackage,
        if (lifetimePackage != $none) #lifetimePackage: lifetimePackage,
        if (errorMessage != $none) #errorMessage: errorMessage
      }));
  @override
  FetchProductsState $make(CopyWithData data) => FetchProductsState(
      status: data.get(#status, or: $value.status),
      action: data.get(#action, or: $value.action),
      annualPackage: data.get(#annualPackage, or: $value.annualPackage),
      lifetimePackage: data.get(#lifetimePackage, or: $value.lifetimePackage),
      errorMessage: data.get(#errorMessage, or: $value.errorMessage));

  @override
  FetchProductsStateCopyWith<$R2, FetchProductsState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _FetchProductsStateCopyWithImpl($value, $cast, t);
}
