import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';

/// Mock data for testing
class MockData {
  MockData._();

  // ========== Loops ==========

  static const loopVerse = Loop(
    id: 1,
    name: 'Verse 1',
    songId: 'song-medium',
    color: LoopColor.green,
    start: Duration(seconds: 15),
    end: Duration(minutes: 1, seconds: 30),
  );

  static const loopChorus = Loop(
    id: 2,
    name: 'Chorus',
    songId: 'song-medium',
    color: LoopColor.orange,
    orderNumber: 1,
    start: Duration(minutes: 1, seconds: 30),
    end: Duration(minutes: 2, seconds: 45),
  );

  static const loopBridge = Loop(
    id: 3,
    name: 'Bridge',
    songId: 'song-medium',
    color: LoopColor.purple,
    orderNumber: 2,
    start: Duration(minutes: 3),
    end: Duration(minutes: 3, seconds: 30),
  );

  static const loopSolo = Loop(
    id: 4,
    name: 'Guitar Solo',
    songId: 'song-medium',
    color: LoopColor.pink,
    orderNumber: 3,
    start: Duration(minutes: 4),
    end: Duration(minutes: 5),
  );

  static const testLoops = [loopVerse, loopChorus, loopBridge, loopSolo];

  // ========== Songs ==========

  /// Short title and artist
  static const songShort = Song(
    id: 'song-short',
    title: 'Run',
    artist: 'AWOL',
    fileName: 'run.mp3',
    duration: Duration(minutes: 2, seconds: 30),
    bpm: 140,
  );

  /// Medium length title and artist
  static const songMedium = Song(
    id: 'song-medium',
    title: 'Bohemian Rhapsody',
    artist: 'Queen',
    fileName: 'bohemian_rhapsody.mp3',
    duration: Duration(minutes: 5, seconds: 55),
    bpm: 72,
  );

  /// Long title and artist
  static const songLong = Song(
    id: 'song-long',
    title: 'I Want to Break Free from Your Lies',
    artist: 'The Red Hot Chili Peppers',
    fileName: 'break_free.mp3',
    duration: Duration(minutes: 4, seconds: 18),
    bpm: 110,
  );

  /// Very long title and artist (should truncate)
  static const songVeryLong = Song(
    id: 'song-very-long',
    title: 'Everything in Its Right Place When the Morning Comes Around',
    artist: 'Rage Against the Machine featuring Special Guests',
    fileName: 'everything.mp3',
    duration: Duration(minutes: 7, seconds: 42),
    bpm: 95,
  );

  /// Super long title and artist (extreme case)
  static const songSuperLong = Song(
    id: 'song-super-long',
    title:
        'Several Species of Small Furry Animals Gathered Together in a Cave and Grooving with a Pict',
    artist:
        'The Artist Formerly Known As Prince And The New Power Generation Band',
    fileName: 'several_species.mp3',
    duration: Duration(minutes: 12, seconds: 5),
    bpm: 88,
  );

  /// Song without BPM
  static const songNoBpm = Song(
    id: 'song-no-bpm',
    title: 'Unknown Tempo',
    artist: 'Mystery Artist',
    fileName: 'unknown.mp3',
    duration: Duration(minutes: 3, seconds: 15),
  );

  static const testSongs = [
    songShort,
    songMedium,
    songLong,
    songVeryLong,
    songSuperLong,
    songNoBpm,
  ];
}
