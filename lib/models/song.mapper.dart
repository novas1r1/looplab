// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'song.dart';

class SongMapper extends ClassMapperBase<Song> {
  SongMapper._();

  static SongMapper? _instance;
  static SongMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SongMapper._());
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
  static String _$path(Song v) => v.path;
  static const Field<Song, String> _f$path = Field('path', _$path);

  @override
  final MappableFields<Song> fields = const {
    #id: _f$id,
    #title: _f$title,
    #artist: _f$artist,
    #path: _f$path,
  };

  static Song _instantiate(DecodingData data) {
    return Song(
        id: data.dec(_f$id),
        title: data.dec(_f$title),
        artist: data.dec(_f$artist),
        path: data.dec(_f$path));
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
      _SongCopyWithImpl(this as Song, $identity, $identity);
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
      $base.as((v, t, t2) => _SongCopyWithImpl(v, t, t2));
}

abstract class SongCopyWith<$R, $In extends Song, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, String? title, String? artist, String? path});
  SongCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SongCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Song, $Out>
    implements SongCopyWith<$R, Song, $Out> {
  _SongCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Song> $mapper = SongMapper.ensureInitialized();
  @override
  $R call({String? id, String? title, String? artist, String? path}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (title != null) #title: title,
        if (artist != null) #artist: artist,
        if (path != null) #path: path
      }));
  @override
  Song $make(CopyWithData data) => Song(
      id: data.get(#id, or: $value.id),
      title: data.get(#title, or: $value.title),
      artist: data.get(#artist, or: $value.artist),
      path: data.get(#path, or: $value.path));

  @override
  SongCopyWith<$R2, Song, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _SongCopyWithImpl($value, $cast, t);
}
