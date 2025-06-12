// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'song.dart';

class LoopSortMapper extends EnumMapper<LoopSort> {
  LoopSortMapper._();

  static LoopSortMapper? _instance;
  static LoopSortMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LoopSortMapper._());
    }
    return _instance!;
  }

  static LoopSort fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  LoopSort decode(dynamic value) {
    switch (value) {
      case r'manual':
        return LoopSort.manual;
      case r'startTime':
        return LoopSort.startTime;
      case r'none':
        return LoopSort.none;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(LoopSort self) {
    switch (self) {
      case LoopSort.manual:
        return r'manual';
      case LoopSort.startTime:
        return r'startTime';
      case LoopSort.none:
        return r'none';
    }
  }
}

extension LoopSortMapperExtension on LoopSort {
  String toValue() {
    LoopSortMapper.ensureInitialized();
    return MapperContainer.globals.toValue<LoopSort>(this) as String;
  }
}

class SongMapper extends ClassMapperBase<Song> {
  SongMapper._();

  static SongMapper? _instance;
  static SongMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SongMapper._());
      MapperContainer.globals.useAll([DurationMapper()]);
      LoopMapper.ensureInitialized();
      LoopSortMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Song';

  static String _$id(Song v) => v.id;
  static const Field<Song, String> _f$id = Field('id', _$id);
  static String _$title(Song v) => v.title;
  static const Field<Song, String> _f$title = Field('title', _$title);
  static String _$artist(Song v) => v.artist;
  static const Field<Song, String> _f$artist = Field('artist', _$artist);
  static String _$fileName(Song v) => v.fileName;
  static const Field<Song, String> _f$fileName = Field('fileName', _$fileName);
  static Duration _$duration(Song v) => v.duration;
  static const Field<Song, Duration> _f$duration = Field('duration', _$duration);
  static List<Loop> _$loops(Song v) => v.loops;
  static const Field<Song, List<Loop>> _f$loops = Field('loops', _$loops, opt: true, def: const []);
  static LoopSort _$loopSort(Song v) => v.loopSort;
  static const Field<Song, LoopSort> _f$loopSort = Field(
    'loopSort',
    _$loopSort,
    opt: true,
    def: LoopSort.none,
  );

  @override
  final MappableFields<Song> fields = const {
    #id: _f$id,
    #title: _f$title,
    #artist: _f$artist,
    #fileName: _f$fileName,
    #duration: _f$duration,
    #loops: _f$loops,
    #loopSort: _f$loopSort,
  };

  static Song _instantiate(DecodingData data) {
    return Song(
      id: data.dec(_f$id),
      title: data.dec(_f$title),
      artist: data.dec(_f$artist),
      fileName: data.dec(_f$fileName),
      duration: data.dec(_f$duration),
      loops: data.dec(_f$loops),
      loopSort: data.dec(_f$loopSort),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Song fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Song>(map);
  }

  static Song fromJson(String json) {
    return ensureInitialized().decodeJson<Song>(json);
  }
}

mixin SongMappable {
  String toJson() {
    return SongMapper.ensureInitialized().encodeJson<Song>(this as Song);
  }

  Map<String, dynamic> toMap() {
    return SongMapper.ensureInitialized().encodeMap<Song>(this as Song);
  }

  SongCopyWith<Song, Song, Song> get copyWith =>
      _SongCopyWithImpl<Song, Song>(this as Song, $identity, $identity);
  @override
  String toString() {
    return SongMapper.ensureInitialized().stringifyValue(this as Song);
  }

  @override
  bool operator ==(Object other) {
    return SongMapper.ensureInitialized().equalsValue(this as Song, other);
  }

  @override
  int get hashCode {
    return SongMapper.ensureInitialized().hashValue(this as Song);
  }
}

extension SongValueCopy<$R, $Out> on ObjectCopyWith<$R, Song, $Out> {
  SongCopyWith<$R, Song, $Out> get $asSong =>
      $base.as((v, t, t2) => _SongCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SongCopyWith<$R, $In extends Song, $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Loop, LoopCopyWith<$R, Loop, Loop>> get loops;
  $R call({
    String? id,
    String? title,
    String? artist,
    String? fileName,
    Duration? duration,
    List<Loop>? loops,
    LoopSort? loopSort,
  });
  SongCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SongCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Song, $Out>
    implements SongCopyWith<$R, Song, $Out> {
  _SongCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Song> $mapper = SongMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Loop, LoopCopyWith<$R, Loop, Loop>> get loops =>
      ListCopyWith($value.loops, (v, t) => v.copyWith.$chain(t), (v) => call(loops: v));
  @override
  $R call({
    String? id,
    String? title,
    String? artist,
    String? fileName,
    Duration? duration,
    List<Loop>? loops,
    LoopSort? loopSort,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (title != null) #title: title,
      if (artist != null) #artist: artist,
      if (fileName != null) #fileName: fileName,
      if (duration != null) #duration: duration,
      if (loops != null) #loops: loops,
      if (loopSort != null) #loopSort: loopSort,
    }),
  );
  @override
  Song $make(CopyWithData data) => Song(
    id: data.get(#id, or: $value.id),
    title: data.get(#title, or: $value.title),
    artist: data.get(#artist, or: $value.artist),
    fileName: data.get(#fileName, or: $value.fileName),
    duration: data.get(#duration, or: $value.duration),
    loops: data.get(#loops, or: $value.loops),
    loopSort: data.get(#loopSort, or: $value.loopSort),
  );

  @override
  SongCopyWith<$R2, Song, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _SongCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
