import 'package:bloc_test/bloc_test.dart';
import 'package:repeatlab/features/changelog_dialog/cubits/changelog_dialog_cubit.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/cubit/song_exporter/song_exporter_cubit.dart';
import 'package:repeatlab/features/speed_control/cubit/speed_control_cubit.dart';

class MockAllSongsCubit extends MockCubit<AllSongsState> implements AllSongsCubit {}

class MockChangelogDialogCubit extends MockCubit<ChangelogDialogState>
    implements ChangelogDialogCubit {}

class MockSongCubit extends MockCubit<SongState> implements SongCubit {}

class MockSongExporterCubit extends MockCubit<SongExporterState> implements SongExporterCubit {}

class MockPremiumSubscriptionCubit extends MockCubit<PremiumSubscriptionState>
    implements PremiumSubscriptionCubit {}

class MockSpeedControlCubit extends MockCubit<SpeedControlState> implements SpeedControlCubit {}
