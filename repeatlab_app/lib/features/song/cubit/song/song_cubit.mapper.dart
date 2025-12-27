// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
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
      case r'loading':
        return SongStatus.loading;
      case r'loadSuccess':
        return SongStatus.loadSuccess;
      case r'loadError':
        return SongStatus.loadError;
      case r'error':
        return SongStatus.error;
      case r'loopAdded':
        return SongStatus.loopAdded;
      case r'loopDeleted':
        return SongStatus.loopDeleted;
      case r'loopModeToggled':
        return SongStatus.loopModeToggled;
      case r'updated':
        return SongStatus.updated;
      case r'updating':
        return SongStatus.updating;
      case r'songDeleted':
        return SongStatus.songDeleted;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(SongStatus self) {
    switch (self) {
      case SongStatus.loading:
        return r'loading';
      case SongStatus.loadSuccess:
        return r'loadSuccess';
      case SongStatus.loadError:
        return r'loadError';
      case SongStatus.error:
        return r'error';
      case SongStatus.loopAdded:
        return r'loopAdded';
      case SongStatus.loopDeleted:
        return r'loopDeleted';
      case SongStatus.loopModeToggled:
        return r'loopModeToggled';
      case SongStatus.updated:
        return r'updated';
      case SongStatus.updating:
        return r'updating';
      case SongStatus.songDeleted:
        return r'songDeleted';
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

  static double _$speed(SongState v) => v.speed;
  static const Field<SongState, double> _f$speed = Field(
    'speed',
    _$speed,
    opt: true,
    def: 1.0,
  );
  static SongStatus _$status(SongState v) => v.status;
  static const Field<SongState, SongStatus> _f$status = Field(
    'status',
    _$status,
    opt: true,
    def: SongStatus.loading,
  );
  static Song _$song(SongState v) => v.song;
  static const Field<SongState, Song> _f$song = Field('song', _$song);
  static String? _$error(SongState v) => v.error;
  static const Field<SongState, String> _f$error = Field(
    'error',
    _$error,
    opt: true,
  );
  static Loop? _$activeLoop(SongState v) => v.activeLoop;
  static const Field<SongState, Loop> _f$activeLoop = Field(
    'activeLoop',
    _$activeLoop,
    opt: true,
  );
  static bool _$isLoopModeEnabled(SongState v) => v.isLoopModeEnabled;
  static const Field<SongState, bool> _f$isLoopModeEnabled = Field(
    'isLoopModeEnabled',
    _$isLoopModeEnabled,
    opt: true,
    def: false,
  );
  static bool _$isTutorialCompleted(SongState v) => v.isTutorialCompleted;
  static const Field<SongState, bool> _f$isTutorialCompleted = Field(
    'isTutorialCompleted',
    _$isTutorialCompleted,
    opt: true,
    def: false,
  );
  static bool _$isFullSongRepeatEnabled(SongState v) =>
      v.isFullSongRepeatEnabled;
  static const Field<SongState, bool> _f$isFullSongRepeatEnabled = Field(
    'isFullSongRepeatEnabled',
    _$isFullSongRepeatEnabled,
    opt: true,
    def: false,
  );
  static bool _$isAutoPlayEnabled(SongState v) => v.isAutoPlayEnabled;
  static const Field<SongState, bool> _f$isAutoPlayEnabled = Field(
    'isAutoPlayEnabled',
    _$isAutoPlayEnabled,
    opt: true,
    def: true,
  );
  static PlayerState? _$playerState(SongState v) => v.playerState;
  static const Field<SongState, PlayerState> _f$playerState = Field(
    'playerState',
    _$playerState,
    opt: true,
  );

  @override
  final MappableFields<SongState> fields = const {
    #speed: _f$speed,
    #status: _f$status,
    #song: _f$song,
    #error: _f$error,
    #activeLoop: _f$activeLoop,
    #isLoopModeEnabled: _f$isLoopModeEnabled,
    #isTutorialCompleted: _f$isTutorialCompleted,
    #isFullSongRepeatEnabled: _f$isFullSongRepeatEnabled,
    #isAutoPlayEnabled: _f$isAutoPlayEnabled,
    #playerState: _f$playerState,
  };

  static SongState _instantiate(DecodingData data) {
    return SongState(
      speed: data.dec(_f$speed),
      status: data.dec(_f$status),
      song: data.dec(_f$song),
      error: data.dec(_f$error),
      activeLoop: data.dec(_f$activeLoop),
      isLoopModeEnabled: data.dec(_f$isLoopModeEnabled),
      isTutorialCompleted: data.dec(_f$isTutorialCompleted),
      isFullSongRepeatEnabled: data.dec(_f$isFullSongRepeatEnabled),
      isAutoPlayEnabled: data.dec(_f$isAutoPlayEnabled),
      playerState: data.dec(_f$playerState),
    );
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
    return SongStateMapper.ensureInitialized().encodeJson<SongState>(
      this as SongState,
    );
  }

  Map<String, dynamic> toMap() {
    return SongStateMapper.ensureInitialized().encodeMap<SongState>(
      this as SongState,
    );
  }

  SongStateCopyWith<SongState, SongState, SongState> get copyWith =>
      _SongStateCopyWithImpl<SongState, SongState>(
        this as SongState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SongStateMapper.ensureInitialized().stringifyValue(
      this as SongState,
    );
  }

  @override
  bool operator ==(Object other) {
    return SongStateMapper.ensureInitialized().equalsValue(
      this as SongState,
      other,
    );
  }

  @override
  int get hashCode {
    return SongStateMapper.ensureInitialized().hashValue(this as SongState);
  }
}

extension SongStateValueCopy<$R, $Out> on ObjectCopyWith<$R, SongState, $Out> {
  SongStateCopyWith<$R, SongState, $Out> get $asSongState =>
      $base.as((v, t, t2) => _SongStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SongStateCopyWith<$R, $In extends SongState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  SongCopyWith<$R, Song, Song> get song;
  LoopCopyWith<$R, Loop, Loop>? get activeLoop;
  $R call({
    double? speed,
    SongStatus? status,
    Song? song,
    String? error,
    Loop? activeLoop,
    bool? isLoopModeEnabled,
    bool? isTutorialCompleted,
    bool? isFullSongRepeatEnabled,
    bool? isAutoPlayEnabled,
    PlayerState? playerState,
  });
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
  $R call({
    double? speed,
    SongStatus? status,
    Song? song,
    Object? error = $none,
    Object? activeLoop = $none,
    bool? isLoopModeEnabled,
    bool? isTutorialCompleted,
    bool? isFullSongRepeatEnabled,
    bool? isAutoPlayEnabled,
    Object? playerState = $none,
  }) => $apply(
    FieldCopyWithData({
      if (speed != null) #speed: speed,
      if (status != null) #status: status,
      if (song != null) #song: song,
      if (error != $none) #error: error,
      if (activeLoop != $none) #activeLoop: activeLoop,
      if (isLoopModeEnabled != null) #isLoopModeEnabled: isLoopModeEnabled,
      if (isTutorialCompleted != null)
        #isTutorialCompleted: isTutorialCompleted,
      if (isFullSongRepeatEnabled != null)
        #isFullSongRepeatEnabled: isFullSongRepeatEnabled,
      if (isAutoPlayEnabled != null) #isAutoPlayEnabled: isAutoPlayEnabled,
      if (playerState != $none) #playerState: playerState,
    }),
  );
  @override
  SongState $make(CopyWithData data) => SongState(
    speed: data.get(#speed, or: $value.speed),
    status: data.get(#status, or: $value.status),
    song: data.get(#song, or: $value.song),
    error: data.get(#error, or: $value.error),
    activeLoop: data.get(#activeLoop, or: $value.activeLoop),
    isLoopModeEnabled: data.get(
      #isLoopModeEnabled,
      or: $value.isLoopModeEnabled,
    ),
    isTutorialCompleted: data.get(
      #isTutorialCompleted,
      or: $value.isTutorialCompleted,
    ),
    isFullSongRepeatEnabled: data.get(
      #isFullSongRepeatEnabled,
      or: $value.isFullSongRepeatEnabled,
    ),
    isAutoPlayEnabled: data.get(
      #isAutoPlayEnabled,
      or: $value.isAutoPlayEnabled,
    ),
    playerState: data.get(#playerState, or: $value.playerState),
  );

  @override
  SongStateCopyWith<$R2, SongState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SongStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

