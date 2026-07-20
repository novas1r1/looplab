import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song_controls/widget/metronome_panel.dart';
import 'package:repeatlab/features/song_controls/widget/pitch_panel.dart';
import 'package:repeatlab/features/song_controls/widget/speed_panel.dart';
import 'package:repeatlab/l10n/l10n.dart';

enum ControlsTab { speed, pitch, metronome }

/// Single card combining the speed, pitch and metronome controls behind a
/// 3-segment tab header, replacing the previously stacked SpeedControl and
/// PitchControl cards. Unavailable tabs (pitch on unsupported platforms,
/// metronome on desktop) are dropped from the segment list entirely.
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
      if (cubit.isMetronomeSupported) ControlsTab.metronome,
    ];
    // If the active tab is unavailable for this song/platform, fall back to
    // the always-present speed tab.
    if (!tabs.contains(_selectedTab)) {
      _selectedTab = ControlsTab.speed;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8).copyWith(right: 0, top: 8, bottom: 8),
      child: Column(
        spacing: 4,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  // Three segments × 16 locales — long labels (pl, ru, …)
                  // scale down uniformly instead of overflowing.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      height: 36,
                      child: ToggleButtons(
                        key: const Key('song.controls.tab'),
                        borderRadius: BorderRadius.circular(10),
                        selectedColor: AppColors.onPrimaryContainer,
                        color: AppColors.secondary,
                        fillColor: AppColors.primaryContainer,
                        disabledColor: AppColors.secondary,
                        isSelected: [
                          for (final tab in tabs) tab == _selectedTab,
                        ],
                        onPressed: (index) => _onSelectTab(tabs[index]),
                        children: [
                          for (final tab in tabs)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                _tabLabel(context, tab),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 32,
                child: IconButton(
                  key: const Key('song.controls.reset'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _onReset(context),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.secondaryFixed,
                  ),
                ),
              ),
              SizedBox(
                height: 32,
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
          if (_isExpanded)
            switch (_selectedTab) {
              ControlsTab.speed => const SpeedPanel(),
              ControlsTab.pitch => const PitchPanel(),
              ControlsTab.metronome => MetronomePanel(
                onRequestSpeedTab: () => _onSelectTab(ControlsTab.speed),
              ),
            },
        ],
      ),
    );
  }

  String _tabLabel(BuildContext context, ControlsTab tab) {
    return switch (tab) {
      ControlsTab.speed => context.l10n.speedControl,
      ControlsTab.pitch => context.l10n.pitchControl,
      ControlsTab.metronome => context.l10n.metronome,
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
      ControlsTab.metronome => AppAnalytics.clickControlsTabMetronome,
    });
  }

  void _onToggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _onReset(BuildContext context) {
    final cubit = context.read<SongCubit>();
    switch (_selectedTab) {
      case ControlsTab.speed:
        cubit.resetSpeed();
      case ControlsTab.pitch:
        cubit.resetPitch();
      case ControlsTab.metronome:
        cubit.resetMetronomeOffset();
    }
  }
}
