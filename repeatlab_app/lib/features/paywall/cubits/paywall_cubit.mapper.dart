// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'paywall_cubit.dart';

class PaywallStatusMapper extends EnumMapper<PaywallStatus> {
  PaywallStatusMapper._();

  static PaywallStatusMapper? _instance;
  static PaywallStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PaywallStatusMapper._());
    }
    return _instance!;
  }

  static PaywallStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  PaywallStatus decode(dynamic value) {
    switch (value) {
      case 'initial':
        return PaywallStatus.initial;
      case 'loading':
        return PaywallStatus.loading;
      case 'loaded':
        return PaywallStatus.loaded;
      case 'error':
        return PaywallStatus.error;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(PaywallStatus self) {
    switch (self) {
      case PaywallStatus.initial:
        return 'initial';
      case PaywallStatus.loading:
        return 'loading';
      case PaywallStatus.loaded:
        return 'loaded';
      case PaywallStatus.error:
        return 'error';
    }
  }
}

extension PaywallStatusMapperExtension on PaywallStatus {
  String toValue() {
    PaywallStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<PaywallStatus>(this) as String;
  }
}

class PaywallStateMapper extends ClassMapperBase<PaywallState> {
  PaywallStateMapper._();

  static PaywallStateMapper? _instance;
  static PaywallStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PaywallStateMapper._());
      PaywallStatusMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PaywallState';

  static PaywallStatus _$status(PaywallState v) => v.status;
  static const Field<PaywallState, PaywallStatus> _f$status =
      Field('status', _$status, opt: true, def: PaywallStatus.initial);
  static bool _$hasPurchased(PaywallState v) => v.hasPurchased;
  static const Field<PaywallState, bool> _f$hasPurchased =
      Field('hasPurchased', _$hasPurchased, opt: true, def: false);
  static PaywallResult? _$paywallResult(PaywallState v) => v.paywallResult;
  static const Field<PaywallState, PaywallResult> _f$paywallResult =
      Field('paywallResult', _$paywallResult, opt: true);

  @override
  final MappableFields<PaywallState> fields = const {
    #status: _f$status,
    #hasPurchased: _f$hasPurchased,
    #paywallResult: _f$paywallResult,
  };

  static PaywallState _instantiate(DecodingData data) {
    return PaywallState(
        status: data.dec(_f$status),
        hasPurchased: data.dec(_f$hasPurchased),
        paywallResult: data.dec(_f$paywallResult));
  }

  @override
  final Function instantiate = _instantiate;

  static PaywallState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PaywallState>(map);
  }

  static PaywallState fromJson(String json) {
    return ensureInitialized().decodeJson<PaywallState>(json);
  }
}

mixin PaywallStateMappable {
  String toJson() {
    return PaywallStateMapper.ensureInitialized()
        .encodeJson<PaywallState>(this as PaywallState);
  }

  Map<String, dynamic> toMap() {
    return PaywallStateMapper.ensureInitialized()
        .encodeMap<PaywallState>(this as PaywallState);
  }

  PaywallStateCopyWith<PaywallState, PaywallState, PaywallState> get copyWith =>
      _PaywallStateCopyWithImpl(this as PaywallState, $identity, $identity);
  @override
  String toString() {
    return PaywallStateMapper.ensureInitialized()
        .stringifyValue(this as PaywallState);
  }

  @override
  bool operator ==(Object other) {
    return PaywallStateMapper.ensureInitialized()
        .equalsValue(this as PaywallState, other);
  }

  @override
  int get hashCode {
    return PaywallStateMapper.ensureInitialized()
        .hashValue(this as PaywallState);
  }
}

extension PaywallStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PaywallState, $Out> {
  PaywallStateCopyWith<$R, PaywallState, $Out> get $asPaywallState =>
      $base.as((v, t, t2) => _PaywallStateCopyWithImpl(v, t, t2));
}

abstract class PaywallStateCopyWith<$R, $In extends PaywallState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {PaywallStatus? status,
      bool? hasPurchased,
      PaywallResult? paywallResult});
  PaywallStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PaywallStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PaywallState, $Out>
    implements PaywallStateCopyWith<$R, PaywallState, $Out> {
  _PaywallStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PaywallState> $mapper =
      PaywallStateMapper.ensureInitialized();
  @override
  $R call(
          {PaywallStatus? status,
          bool? hasPurchased,
          Object? paywallResult = $none}) =>
      $apply(FieldCopyWithData({
        if (status != null) #status: status,
        if (hasPurchased != null) #hasPurchased: hasPurchased,
        if (paywallResult != $none) #paywallResult: paywallResult
      }));
  @override
  PaywallState $make(CopyWithData data) => PaywallState(
      status: data.get(#status, or: $value.status),
      hasPurchased: data.get(#hasPurchased, or: $value.hasPurchased),
      paywallResult: data.get(#paywallResult, or: $value.paywallResult));

  @override
  PaywallStateCopyWith<$R2, PaywallState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _PaywallStateCopyWithImpl($value, $cast, t);
}
