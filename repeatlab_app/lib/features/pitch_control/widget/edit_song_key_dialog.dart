import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/primary_button.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/features/pitch_control/widget/set_song_key_panel.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Edits (or clears) the song's own musical key.
///
/// Changing the reference resets the transposition to 0 — the previous shift
/// was relative to the old key and means nothing against the new one. The fine
/// tune survives, since it compensates for the recording rather than the key.
class EditSongKeyDialog extends StatefulWidget {
  const EditSongKeyDialog({
    required this.currentOriginalKey,
    super.key,
  });

  final String currentOriginalKey;

  @override
  State<EditSongKeyDialog> createState() => _EditSongKeyDialogState();
}

class _EditSongKeyDialogState extends State<EditSongKeyDialog> {
  late String _selectedKey = widget.currentOriginalKey;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.originalKey),
      content: SingleChildScrollView(
        child: SetSongKeyPanel(
          initialKey: widget.currentOriginalKey,
          showIntro: false,
          onKeySelected: (key) => _selectedKey = key,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('song.pitch.keyClear'),
          onPressed: () {
            AppAnalytics.trackEvent(
              AppAnalytics.clickSetOriginalKey,
              data: {'source': 'reset'},
            );
            Navigator.of(context).pop();
            context.read<SongCubit>().setOriginalKey(null);
          },
          child: Text(
            context.l10n.reset,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        PrimaryButton(
          text: context.l10n.setSongKey,
          onPressed: () {
            AppAnalytics.trackEvent(
              AppAnalytics.clickSetOriginalKey,
              data: {'key': _selectedKey, 'source': 'edit_dialog'},
            );
            context.read<SongCubit>().setOriginalKey(_selectedKey);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
