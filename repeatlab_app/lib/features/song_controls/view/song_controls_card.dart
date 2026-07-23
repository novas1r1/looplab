import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/pill_toggle.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song_controls/widget/metronome_panel.dart';
import 'package:repeatlab/features/song_controls/widget/pitch_panel.dart';
import 'package:repeatlab/features/song_controls/widget/speed_panel.dart';
import 'package:repeatlab/l10n/l10n.dart';

enum ControlsTab { speed, pitch }

/// Single card combining the tempo, pitch and metronome controls behind a
/// Tempo/Pitch tab selector. The metronome lives inline at the bottom of the
/// Tempo tab (below a divider) rather than as its own tab. The Pitch tab is
/// dropped on platforms without pitch support; the metronome section is
/// dropped where it isn't supported (desktop).
final class SongControlsCard extends StatefulWidget {
  const SongControlsCard({super.key});

  @override
  State<SongControlsCard> createState() => _SongControlsCardState();
}

class _SongControlsCardState extends State<SongControlsCard> {
  ControlsTab _selectedTab = ControlsTab.speed;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SongCubit>();
    final tabs = [
      ControlsTab.speed,
      if (cubit.isPitchControlSupported) ControlsTab.pitch,
    ];
    if (!tabs.contains(_selectedTab)) {
      _selectedTab = ControlsTab.speed;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        spacing: 12,
        children: [
          Row(
            children: [
              Expanded(
                child: PillToggle(
                  key: const Key('song.controls.tab'),
                  expand: true,
                  selectedIndex: tabs.indexOf(_selectedTab),
                  onChanged: (index) => _onSelectTab(tabs[index]),
                  segments: [
                    for (final tab in tabs)
                      PillSegment(
                        label: _tabLabel(context, tab),
                        key: Key('song.controls.tab.${tab.name}'),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                width: 32,
                child: IconButton(
                  key: const Key('song.controls.expand'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _onToggleExpand,
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.secondaryFixed,
                  ),
                ),
              ),
            ],
          ),
          if (_isExpanded) ...[
            switch (_selectedTab) {
              ControlsTab.speed => const SpeedPanel(),
              ControlsTab.pitch => const PitchPanel(),
            },
            if (_selectedTab == ControlsTab.speed && cubit.isMetronomeSupported)
              const MetronomePanel(),
          ],
        ],
      ),
    );
  }

  String _tabLabel(BuildContext context, ControlsTab tab) {
    return switch (tab) {
      ControlsTab.speed => context.l10n.speedControl,
      ControlsTab.pitch => context.l10n.pitchControl,
    };
  }

  void _onSelectTab(ControlsTab tab) {
    setState(() {
      _selectedTab = tab;
      _isExpanded = true;
    });

    AppAnalytics.trackEvent(switch (tab) {
      ControlsTab.speed => AppAnalytics.clickControlsTabSpeed,
      ControlsTab.pitch => AppAnalytics.clickControlsTabPitch,
    });
  }

  void _onToggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
}
