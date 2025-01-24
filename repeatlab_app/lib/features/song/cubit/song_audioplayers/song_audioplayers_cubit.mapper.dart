// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'song_audioplayers_cubit.dart';

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
      case 'loadSuccess':
        return SongStatus.loadSuccess;
      case 'loadError':
        return SongStatus.loadError;
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
      case SongStatus.loadSuccess:
        return 'loadSuccess';
      case SongStatus.loadError:
        return 'loadError';
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

class SongAudioplayersStateMapper
    extends ClassMapperBase<SongAudioplayersState> {
  SongAudioplayersStateMapper._();

  static SongAudioplayersStateMapper? _instance;
  static SongAudioplayersStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SongAudioplayersStateMapper._());
      SongStatusMapper.ensureInitialized();
      SongMapper.ensureInitialized();
      LoopMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SongAudioplayersState';

  static double _$speed(SongAudioplayersState v) => v.speed;
  static const Field<SongAudioplayersState, double> _f$speed =
      Field('speed', _$speed, opt: true, def: 1.0);
  static SongStatus _$status(SongAudioplayersState v) => v.status;
  static const Field<SongAudioplayersState, SongStatus> _f$status =
      Field('status', _$status, opt: true, def: SongStatus.loading);
  static Song _$song(SongAudioplayersState v) => v.song;
  static const Field<SongAudioplayersState, Song> _f$song =
      Field('song', _$song);
  static String? _$error(SongAudioplayersState v) => v.error;
  static const Field<SongAudioplayersState, String> _f$error =
      Field('error', _$error, opt: true);
  static Float32List? _$data(SongAudioplayersState v) => v.data;
  static const Field<SongAudioplayersState, Float32List> _f$data =
      Field('data', _$data, opt: true);
  static Loop? _$activeLoop(SongAudioplayersState v) => v.activeLoop;
  static const Field<SongAudioplayersState, Loop> _f$activeLoop =
      Field('activeLoop', _$activeLoop, opt: true);
  static bool _$isLoopModeEnabled(SongAudioplayersState v) =>
      v.isLoopModeEnabled;
  static const Field<SongAudioplayersState, bool> _f$isLoopModeEnabled =
      Field('isLoopModeEnabled', _$isLoopModeEnabled, opt: true, def: false);
  static bool _$isTutorialCompleted(SongAudioplayersState v) =>
      v.isTutorialCompleted;
  static const Field<SongAudioplayersState, bool> _f$isTutorialCompleted =
      Field('isTutorialCompleted', _$isTutorialCompleted,
          opt: true, def: false);
  static PlayerState? _$playerState(SongAudioplayersState v) => v.playerState;
  static const Field<SongAudioplayersState, PlayerState> _f$playerState =
      Field('playerState', _$playerState, opt: true);
  static Duration? _$position(SongAudioplayersState v) => v.position;
  static const Field<SongAudioplayersState, Duration> _f$position =
      Field('position', _$position, opt: true);
  static Duration? _$duration(SongAudioplayersState v) => v.duration;
  static const Field<SongAudioplayersState, Duration> _f$duration =
      Field('duration', _$duration, opt: true);

  @override
  final MappableFields<SongAudioplayersState> fields = const {
    #speed: _f$speed,
    #status: _f$status,
    #song: _f$song,
    #error: _f$error,
    #data: _f$data,
    #activeLoop: _f$activeLoop,
    #isLoopModeEnabled: _f$isLoopModeEnabled,
    #isTutorialCompleted: _f$isTutorialCompleted,
    #playerState: _f$playerState,
    #position: _f$position,
    #duration: _f$duration,
  };

  static SongAudioplayersState _instantiate(DecodingData data) {
    return SongAudioplayersState(
        speed: data.dec(_f$speed),
        status: data.dec(_f$status),
        song: data.dec(_f$song),
        error: data.dec(_f$error),
        data: data.dec(_f$data),
        activeLoop: data.dec(_f$activeLoop),
        isLoopModeEnabled: data.dec(_f$isLoopModeEnabled),
        isTutorialCompleted: data.dec(_f$isTutorialCompleted),
        playerState: data.dec(_f$playerState),
        position: data.dec(_f$position),
        duration: data.dec(_f$duration));
  }

  @override
  final Function instantiate = _instantiate;

  static SongAudioplayersState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SongAudioplayersState>(map);
  }

  static SongAudioplayersState fromJson(String json) {
    return ensureInitialized().decodeJson<SongAudioplayersState>(json);
  }
}

mixin SongAudioplayersStateMappable {
  String toJson() {
    return SongAudioplayersStateMapper.ensureInitialized()
        .encodeJson<SongAudioplayersState>(this as SongAudioplayersState);
  }

  Map<String, dynamic> toMap() {
    return SongAudioplayersStateMapper.ensureInitialized()
        .encodeMap<SongAudioplayersState>(this as SongAudioplayersState);
  }

  SongAudioplayersStateCopyWith<SongAudioplayersState, SongAudioplayersState,
          SongAudioplayersState>
      get copyWith => _SongAudioplayersStateCopyWithImpl(
          this as SongAudioplayersState, $identity, $identity);
  @override
  String toString() {
    return SongAudioplayersStateMapper.ensureInitialized()
        .stringifyValue(this as SongAudioplayersState);
  }

  @override
  bool operator ==(Object other) {
    return SongAudioplayersStateMapper.ensureInitialized()
        .equalsValue(this as SongAudioplayersState, other);
  }

  @override
  int get hashCode {
    return SongAudioplayersStateMapper.ensureInitialized()
        .hashValue(this as SongAudioplayersState);
  }
}

extension SongAudioplayersStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SongAudioplayersState, $Out> {
  SongAudioplayersStateCopyWith<$R, SongAudioplayersState, $Out>
      get $asSongAudioplayersState =>
          $base.as((v, t, t2) => _SongAudioplayersStateCopyWithImpl(v, t, t2));
}

abstract class SongAudioplayersStateCopyWith<
    $R,
    $In extends SongAudioplayersState,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  SongCopyWith<$R, Song, Song> get song;
  LoopCopyWith<$R, Loop, Loop>? get activeLoop;
  $R call(
      {double? speed,
      SongStatus? status,
      Song? song,
      String? error,
      Float32List? data,
      Loop? activeLoop,
      bool? isLoopModeEnabled,
      bool? isTutorialCompleted,
      PlayerState? playerState,
      Duration? position,
      Duration? duration});
  SongAudioplayersStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _SongAudioplayersStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SongAudioplayersState, $Out>
    implements SongAudioplayersStateCopyWith<$R, SongAudioplayersState, $Out> {
  _SongAudioplayersStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SongAudioplayersState> $mapper =
      SongAudioplayersStateMapper.ensureInitialized();
  @override
  SongCopyWith<$R, Song, Song> get song =>
      $value.song.copyWith.$chain((v) => call(song: v));
  @override
  LoopCopyWith<$R, Loop, Loop>? get activeLoop =>
      $value.activeLoop?.copyWith.$chain((v) => call(activeLoop: v));
  @override
  $R call(
          {double? speed,
          SongStatus? status,
          Song? song,
          Object? error = $none,
          Object? data = $none,
          Object? activeLoop = $none,
          bool? isLoopModeEnabled,
          bool? isTutorialCompleted,
          Object? playerState = $none,
          Object? position = $none,
          Object? duration = $none}) =>
      $apply(FieldCopyWithData({
        if (speed != null) #speed: speed,
        if (status != null) #status: status,
        if (song != null) #song: song,
        if (error != $none) #error: error,
        if (data != $none) #data: data,
        if (activeLoop != $none) #activeLoop: activeLoop,
        if (isLoopModeEnabled != null) #isLoopModeEnabled: isLoopModeEnabled,
        if (isTutorialCompleted != null)
          #isTutorialCompleted: isTutorialCompleted,
        if (playerState != $none) #playerState: playerState,
        if (position != $none) #position: position,
        if (duration != $none) #duration: duration
      }));
  @override
  SongAudioplayersState $make(CopyWithData data) => SongAudioplayersState(
      speed: data.get(#speed, or: $value.speed),
      status: data.get(#status, or: $value.status),
      song: data.get(#song, or: $value.song),
      error: data.get(#error, or: $value.error),
      data: data.get(#data, or: $value.data),
      activeLoop: data.get(#activeLoop, or: $value.activeLoop),
      isLoopModeEnabled:
          data.get(#isLoopModeEnabled, or: $value.isLoopModeEnabled),
      isTutorialCompleted:
          data.get(#isTutorialCompleted, or: $value.isTutorialCompleted),
      playerState: data.get(#playerState, or: $value.playerState),
      position: data.get(#position, or: $value.position),
      duration: data.get(#duration, or: $value.duration));

  @override
  SongAudioplayersStateCopyWith<$R2, SongAudioplayersState, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _SongAudioplayersStateCopyWithImpl($value, $cast, t);
}
