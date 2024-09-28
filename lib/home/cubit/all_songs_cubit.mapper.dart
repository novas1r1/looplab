// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'all_songs_cubit.dart';

class AllSongsStatusMapper extends EnumMapper<AllSongsStatus> {
  AllSongsStatusMapper._();

  static AllSongsStatusMapper? _instance;
  static AllSongsStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AllSongsStatusMapper._());
    }
    return _instance!;
  }

  static AllSongsStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  AllSongsStatus decode(dynamic value) {
    switch (value) {
      case 'initial':
        return AllSongsStatus.initial;
      case 'loading':
        return AllSongsStatus.loading;
      case 'loaded':
        return AllSongsStatus.loaded;
      case 'error':
        return AllSongsStatus.error;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(AllSongsStatus self) {
    switch (self) {
      case AllSongsStatus.initial:
        return 'initial';
      case AllSongsStatus.loading:
        return 'loading';
      case AllSongsStatus.loaded:
        return 'loaded';
      case AllSongsStatus.error:
        return 'error';
    }
  }
}

extension AllSongsStatusMapperExtension on AllSongsStatus {
  String toValue() {
    AllSongsStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<AllSongsStatus>(this) as String;
  }
}

class AllSongsStateMapper extends ClassMapperBase<AllSongsState> {
  AllSongsStateMapper._();

  static AllSongsStateMapper? _instance;
  static AllSongsStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AllSongsStateMapper._());
      AllSongsStatusMapper.ensureInitialized();
      SongMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'AllSongsState';

  static AllSongsStatus _$status(AllSongsState v) => v.status;
  static const Field<AllSongsState, AllSongsStatus> _f$status =
      Field('status', _$status, opt: true, def: AllSongsStatus.initial);
  static List<Song> _$songs(AllSongsState v) => v.songs;
  static const Field<AllSongsState, List<Song>> _f$songs =
      Field('songs', _$songs, opt: true, def: const []);
  static String? _$errorMessage(AllSongsState v) => v.errorMessage;
  static const Field<AllSongsState, String> _f$errorMessage =
      Field('errorMessage', _$errorMessage, opt: true);

  @override
  final MappableFields<AllSongsState> fields = const {
    #status: _f$status,
    #songs: _f$songs,
    #errorMessage: _f$errorMessage,
  };

  static AllSongsState _instantiate(DecodingData data) {
    return AllSongsState(
        status: data.dec(_f$status),
        songs: data.dec(_f$songs),
        errorMessage: data.dec(_f$errorMessage));
  }

  @override
  final Function instantiate = _instantiate;

  static AllSongsState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AllSongsState>(map);
  }

  static AllSongsState fromJson(String json) {
    return ensureInitialized().decodeJson<AllSongsState>(json);
  }
}

mixin AllSongsStateMappable {
  String toJson() {
    return AllSongsStateMapper.ensureInitialized()
        .encodeJson<AllSongsState>(this as AllSongsState);
  }

  Map<String, dynamic> toMap() {
    return AllSongsStateMapper.ensureInitialized()
        .encodeMap<AllSongsState>(this as AllSongsState);
  }

  AllSongsStateCopyWith<AllSongsState, AllSongsState, AllSongsState>
      get copyWith => _AllSongsStateCopyWithImpl(
          this as AllSongsState, $identity, $identity);
  @override
  String toString() {
    return AllSongsStateMapper.ensureInitialized()
        .stringifyValue(this as AllSongsState);
  }

  @override
  bool operator ==(Object other) {
    return AllSongsStateMapper.ensureInitialized()
        .equalsValue(this as AllSongsState, other);
  }

  @override
  int get hashCode {
    return AllSongsStateMapper.ensureInitialized()
        .hashValue(this as AllSongsState);
  }
}

extension AllSongsStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AllSongsState, $Out> {
  AllSongsStateCopyWith<$R, AllSongsState, $Out> get $asAllSongsState =>
      $base.as((v, t, t2) => _AllSongsStateCopyWithImpl(v, t, t2));
}

abstract class AllSongsStateCopyWith<$R, $In extends AllSongsState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Song, SongCopyWith<$R, Song, Song>> get songs;
  $R call({AllSongsStatus? status, List<Song>? songs, String? errorMessage});
  AllSongsStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AllSongsStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AllSongsState, $Out>
    implements AllSongsStateCopyWith<$R, AllSongsState, $Out> {
  _AllSongsStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AllSongsState> $mapper =
      AllSongsStateMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Song, SongCopyWith<$R, Song, Song>> get songs =>
      ListCopyWith(
          $value.songs, (v, t) => v.copyWith.$chain(t), (v) => call(songs: v));
  @override
  $R call(
          {AllSongsStatus? status,
          List<Song>? songs,
          Object? errorMessage = $none}) =>
      $apply(FieldCopyWithData({
        if (status != null) #status: status,
        if (songs != null) #songs: songs,
        if (errorMessage != $none) #errorMessage: errorMessage
      }));
  @override
  AllSongsState $make(CopyWithData data) => AllSongsState(
      status: data.get(#status, or: $value.status),
      songs: data.get(#songs, or: $value.songs),
      errorMessage: data.get(#errorMessage, or: $value.errorMessage));

  @override
  AllSongsStateCopyWith<$R2, AllSongsState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _AllSongsStateCopyWithImpl($value, $cast, t);
}
