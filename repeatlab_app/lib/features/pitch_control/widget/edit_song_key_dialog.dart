import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/interaction/primary_button.dart';
import 'package:repeatlab/core/ui/widgets/app_icon.dart';
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
      // Clearing the key is a third, destructive path that does not belong
      // beside Cancel/Save — it sits in the title row so the action row reads
      // as the plain either/or it is.
      title: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.originalKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            key: const Key('song.pitch.keyClear'),
            tooltip: context.l10n.reset,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () {
              AppAnalytics.trackEvent(
                AppAnalytics.clickSetOriginalKey,
                data: {'source': 'reset'},
              );
              Navigator.of(context).pop();
              context.read<SongCubit>().setOriginalKey(null);
            },
            icon: const AppIcon(
              iconName: 'ic_refresh',
              iconSize: 22,
              containerSize: 22,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SetSongKeyPanel(
          initialKey: widget.currentOriginalKey,
          showIntro: false,
          onKeySelected: (key) => _selectedKey = key,
        ),
      ),
      actions: [
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
