class Song {
  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.path,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      path: map['path'] as String,
    );
  }
  final String id;
  final String title;
  final String artist;
  final String path;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'path': path,
    };
  }
}
