// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'premium_subscription_cubit.dart';

class PremiumSubscriptionStateMapper extends ClassMapperBase<PremiumSubscriptionState> {
  PremiumSubscriptionStateMapper._();

  static PremiumSubscriptionStateMapper? _instance;
  static PremiumSubscriptionStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PremiumSubscriptionStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PremiumSubscriptionState';

  static PremiumSubscriptionStatus _$status(PremiumSubscriptionState v) => v.status;
  static const Field<PremiumSubscriptionState, PremiumSubscriptionStatus> _f$status = Field(
    'status',
    _$status,
    opt: true,
    def: PremiumSubscriptionStatus.initial,
  );
  static bool _$hasSubscription(PremiumSubscriptionState v) => v.hasSubscription;
  static const Field<PremiumSubscriptionState, bool> _f$hasSubscription = Field(
    'hasSubscription',
    _$hasSubscription,
    opt: true,
    def: false,
  );
  static bool _$hasLifetimePurchase(PremiumSubscriptionState v) => v.hasLifetimePurchase;
  static const Field<PremiumSubscriptionState, bool> _f$hasLifetimePurchase = Field(
    'hasLifetimePurchase',
    _$hasLifetimePurchase,
    opt: true,
    def: false,
  );
  static String? _$errorMessage(PremiumSubscriptionState v) => v.errorMessage;
  static const Field<PremiumSubscriptionState, String> _f$errorMessage = Field(
    'errorMessage',
    _$errorMessage,
    opt: true,
  );

  @override
  final MappableFields<PremiumSubscriptionState> fields = const {
    #status: _f$status,
    #hasSubscription: _f$hasSubscription,
    #hasLifetimePurchase: _f$hasLifetimePurchase,
    #errorMessage: _f$errorMessage,
  };

  static PremiumSubscriptionState _instantiate(DecodingData data) {
    return PremiumSubscriptionState(
      status: data.dec(_f$status),
      hasSubscription: data.dec(_f$hasSubscription),
      hasLifetimePurchase: data.dec(_f$hasLifetimePurchase),
      errorMessage: data.dec(_f$errorMessage),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PremiumSubscriptionState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PremiumSubscriptionState>(map);
  }

  static PremiumSubscriptionState fromJson(String json) {
    return ensureInitialized().decodeJson<PremiumSubscriptionState>(json);
  }
}

mixin PremiumSubscriptionStateMappable {
  String toJson() {
    return PremiumSubscriptionStateMapper.ensureInitialized().encodeJson<PremiumSubscriptionState>(
      this as PremiumSubscriptionState,
    );
  }

  Map<String, dynamic> toMap() {
    return PremiumSubscriptionStateMapper.ensureInitialized().encodeMap<PremiumSubscriptionState>(
      this as PremiumSubscriptionState,
    );
  }

  PremiumSubscriptionStateCopyWith<
    PremiumSubscriptionState,
    PremiumSubscriptionState,
    PremiumSubscriptionState
  >
  get copyWith =>
      _PremiumSubscriptionStateCopyWithImpl<PremiumSubscriptionState, PremiumSubscriptionState>(
        this as PremiumSubscriptionState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PremiumSubscriptionStateMapper.ensureInitialized().stringifyValue(
      this as PremiumSubscriptionState,
    );
  }

  @override
  bool operator ==(Object other) {
    return PremiumSubscriptionStateMapper.ensureInitialized().equalsValue(
      this as PremiumSubscriptionState,
      other,
    );
  }

  @override
  int get hashCode {
    return PremiumSubscriptionStateMapper.ensureInitialized().hashValue(
      this as PremiumSubscriptionState,
    );
  }
}

extension PremiumSubscriptionStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PremiumSubscriptionState, $Out> {
  PremiumSubscriptionStateCopyWith<$R, PremiumSubscriptionState, $Out>
  get $asPremiumSubscriptionState =>
      $base.as((v, t, t2) => _PremiumSubscriptionStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PremiumSubscriptionStateCopyWith<$R, $In extends PremiumSubscriptionState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    PremiumSubscriptionStatus? status,
    bool? hasSubscription,
    bool? hasLifetimePurchase,
    String? errorMessage,
  });
  PremiumSubscriptionStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PremiumSubscriptionStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PremiumSubscriptionState, $Out>
    implements PremiumSubscriptionStateCopyWith<$R, PremiumSubscriptionState, $Out> {
  _PremiumSubscriptionStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PremiumSubscriptionState> $mapper =
      PremiumSubscriptionStateMapper.ensureInitialized();
  @override
  $R call({
    PremiumSubscriptionStatus? status,
    bool? hasSubscription,
    bool? hasLifetimePurchase,
    Object? errorMessage = $none,
  }) => $apply(
    FieldCopyWithData({
      if (status != null) #status: status,
      if (hasSubscription != null) #hasSubscription: hasSubscription,
      if (hasLifetimePurchase != null) #hasLifetimePurchase: hasLifetimePurchase,
      if (errorMessage != $none) #errorMessage: errorMessage,
    }),
  );
  @override
  PremiumSubscriptionState $make(CopyWithData data) => PremiumSubscriptionState(
    status: data.get(#status, or: $value.status),
    hasSubscription: data.get(#hasSubscription, or: $value.hasSubscription),
    hasLifetimePurchase: data.get(#hasLifetimePurchase, or: $value.hasLifetimePurchase),
    errorMessage: data.get(#errorMessage, or: $value.errorMessage),
  );

  @override
  PremiumSubscriptionStateCopyWith<$R2, PremiumSubscriptionState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PremiumSubscriptionStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
