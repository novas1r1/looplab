// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'song_cubit.dart';

class SongStatusMapper extends EnumMapper<SongStatus> {
  SongStatusMapper._();

  static SongStatusMapper? _instance;
  static SongStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SongStatusMapper._());
    }
    return _instance!;
  }

  static SongStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  SongStatus decode(dynamic value) {
    switch (value) {
      case 'loading':
        return SongStatus.loading;
      case 'loaded':
        return SongStatus.loaded;
      case 'error':
        return SongStatus.error;
      case 'loopAdded':
        return SongStatus.loopAdded;
      case 'loopDeleted':
        return SongStatus.loopDeleted;
      case 'updated':
        return SongStatus.updated;
      case 'songDeleted':
        return SongStatus.songDeleted;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(SongStatus self) {
    switch (self) {
      case SongStatus.loading:
        return 'loading';
      case SongStatus.loaded:
        return 'loaded';
      case SongStatus.error:
        return 'error';
      case SongStatus.loopAdded:
        return 'loopAdded';
      case SongStatus.loopDeleted:
        return 'loopDeleted';
      case SongStatus.updated:
        return 'updated';
      case SongStatus.songDeleted:
        return 'songDeleted';
    }
  }
}

extension SongStatusMapperExtension on SongStatus {
  String toValue() {
    SongStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<SongStatus>(this) as String;
  }
}

class SongStateMapper extends ClassMapperBase<SongState> {
  SongStateMapper._();

  static SongStateMapper? _instance;
  static SongStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SongStateMapper._());
      SongStatusMapper.ensureInitialized();
      SongMapper.ensureInitialized();
      LoopMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SongState';

  static SongStatus _$status(SongState v) => v.status;
  static const Field<SongState, SongStatus> _f$status =
      Field('status', _$status, opt: true, def: SongStatus.loading);
  static Song _$song(SongState v) => v.song;
  static const Field<SongState, Song> _f$song = Field('song', _$song);
  static AudioSource? _$audioSource(SongState v) => v.audioSource;
  static const Field<SongState, AudioSource> _f$audioSource =
      Field('audioSource', _$audioSource, opt: true);
  static SoundHandle? _$handle(SongState v) => v.handle;
  static const Field<SongState, SoundHandle> _f$handle =
      Field('handle', _$handle, opt: true);
  static String? _$error(SongState v) => v.error;
  static const Field<SongState, String> _f$error =
      Field('error', _$error, opt: true);
  static Float32List? _$data(SongState v) => v.data;
  static const Field<SongState, Float32List> _f$data =
      Field('data', _$data, opt: true);
  static Loop? _$activeLoop(SongState v) => v.activeLoop;
  static const Field<SongState, Loop> _f$activeLoop =
      Field('activeLoop', _$activeLoop, opt: true);

  @override
  final MappableFields<SongState> fields = const {
    #status: _f$status,
    #song: _f$song,
    #audioSource: _f$audioSource,
    #handle: _f$handle,
    #error: _f$error,
    #data: _f$data,
    #activeLoop: _f$activeLoop,
  };

  static SongState _instantiate(DecodingData data) {
    return SongState(
        status: data.dec(_f$status),
        song: data.dec(_f$song),
        audioSource: data.dec(_f$audioSource),
        handle: data.dec(_f$handle),
        error: data.dec(_f$error),
        data: data.dec(_f$data),
        activeLoop: data.dec(_f$activeLoop));
  }

  @override
  final Function instantiate = _instantiate;

  static SongState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SongState>(map);
  }

  static SongState fromJson(String json) {
    return ensureInitialized().decodeJson<SongState>(json);
  }
}

mixin SongStateMappable {
  String toJson() {
    return SongStateMapper.ensureInitialized()
        .encodeJson<SongState>(this as SongState);
  }

  Map<String, dynamic> toMap() {
    return SongStateMapper.ensureInitialized()
        .encodeMap<SongState>(this as SongState);
  }

  SongStateCopyWith<SongState, SongState, SongState> get copyWith =>
      _SongStateCopyWithImpl(this as SongState, $identity, $identity);
  @override
  String toString() {
    return SongStateMapper.ensureInitialized()
        .stringifyValue(this as SongState);
  }

  @override
  bool operator ==(Object other) {
    return SongStateMapper.ensureInitialized()
        .equalsValue(this as SongState, other);
  }

  @override
  int get hashCode {
    return SongStateMapper.ensureInitialized().hashValue(this as SongState);
  }
}

extension SongStateValueCopy<$R, $Out> on ObjectCopyWith<$R, SongState, $Out> {
  SongStateCopyWith<$R, SongState, $Out> get $asSongState =>
      $base.as((v, t, t2) => _SongStateCopyWithImpl(v, t, t2));
}

abstract class SongStateCopyWith<$R, $In extends SongState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  SongCopyWith<$R, Song, Song> get song;
  LoopCopyWith<$R, Loop, Loop>? get activeLoop;
  $R call(
      {SongStatus? status,
      Song? song,
      AudioSource? audioSource,
      SoundHandle? handle,
      String? error,
      Float32List? data,
      Loop? activeLoop});
  SongStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SongStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SongState, $Out>
    implements SongStateCopyWith<$R, SongState, $Out> {
  _SongStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SongState> $mapper =
      SongStateMapper.ensureInitialized();
  @override
  SongCopyWith<$R, Song, Song> get song =>
      $value.song.copyWith.$chain((v) => call(song: v));
  @override
  LoopCopyWith<$R, Loop, Loop>? get activeLoop =>
      $value.activeLoop?.copyWith.$chain((v) => call(activeLoop: v));
  @override
  $R call(
          {SongStatus? status,
          Song? song,
          Object? audioSource = $none,
          Object? handle = $none,
          Object? error = $none,
          Object? data = $none,
          Object? activeLoop = $none}) =>
      $apply(FieldCopyWithData({
        if (status != null) #status: status,
        if (song != null) #song: song,
        if (audioSource != $none) #audioSource: audioSource,
        if (handle != $none) #handle: handle,
        if (error != $none) #error: error,
        if (data != $none) #data: data,
        if (activeLoop != $none) #activeLoop: activeLoop
      }));
  @override
  SongState $make(CopyWithData data) => SongState(
      status: data.get(#status, or: $value.status),
      song: data.get(#song, or: $value.song),
      audioSource: data.get(#audioSource, or: $value.audioSource),
      handle: data.get(#handle, or: $value.handle),
      error: data.get(#error, or: $value.error),
      data: data.get(#data, or: $value.data),
      activeLoop: data.get(#activeLoop, or: $value.activeLoop));

  @override
  SongStateCopyWith<$R2, SongState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _SongStateCopyWithImpl($value, $cast, t);
}
