import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/ui/interaction/primary_button.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/paywall/premium_screen.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

// TODO: update tutorial
enum TempoMode { multiplier, bpm }

enum ControlMode { tempo, pitch }

final class SpeedControl extends StatefulWidget {
  final Function(double) onSpeedMultiplierChanged;
  final Function(int) onOriginalBpmChanged;
  final Function(int) onCurrentBpmChanged;
  final Function(TempoMode) onTempoModeChanged;
  final Function(int) onPitchChanged;

  final Song song;

  const SpeedControl({
    super.key,
    required this.onSpeedMultiplierChanged,
    required this.onOriginalBpmChanged,
    required this.onCurrentBpmChanged,
    required this.onTempoModeChanged,
    required this.onPitchChanged,
    required this.song,
  });

  @override
  State<SpeedControl> createState() => _SpeedControlState();
}

class _SpeedControlState extends State<SpeedControl> {
  final _originalBpmController = TextEditingController();

  TempoMode _mode = TempoMode.multiplier;
  ControlMode _controlMode = ControlMode.tempo;
  double _speedMultiplier = 1.0;
  int _pitchSemitones = 0; // -12 to +12 semitones

  int? _currentBpm;
  int? _originalBpm;

  // max 0.5 from original bpm
  int? _minBpm;

  // max 2.0 from original bpm
  int? _maxBpm;

  // Tap BPM functionality
  final List<DateTime> _tapTimes = [];
  int? _calculatedBpm;

  @override
  void initState() {
    super.initState();
    _originalBpmController.text = widget.song.bpm?.toString() ?? '';
    _originalBpm = widget.song.bpm;
    if (_originalBpm != null) {
      _minBpm = _calculateMinBpm(_originalBpm!);
      _maxBpm = _calculateMaxBpm(_originalBpm!);
      // for now dont use the current bpm as a starting point
      // _currentBpm = widget.song.currentBpm ?? _originalBpm;
      _currentBpm = _originalBpm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;
    final isPitchSupported = context.select((SongCubit cubit) => cubit.state.isPitchSupported);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header with tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                child: Text(
                  _controlMode == ControlMode.tempo ? context.l10n.speedControl : 'Pitch Control',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondaryFixed,
                  ),
                ),
              ),
              // Control mode tabs (Tempo/Pitch)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: SizedBox(
                  height: 36,
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    color: Theme.of(context).colorScheme.secondary,
                    fillColor: Theme.of(context).colorScheme.primaryContainer,
                    disabledColor: Theme.of(context).colorScheme.secondary,
                    isSelected: [
                      _controlMode == ControlMode.tempo,
                      _controlMode == ControlMode.pitch,
                    ],
                    onPressed: (index) {
                      if (index == 1 && !isPitchSupported) {
                        _showPitchUnsupportedMessage(context);
                        return;
                      }
                      _onChangeControlMode(index);
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Tempo',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Pitch',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                child: IconButton(
                  onPressed: () {
                    if (_controlMode == ControlMode.tempo) {
                      _onResetSpeedForMode(_mode);
                    } else if (isPitchSupported) {
                      _onResetPitch();
                    } else {
                      _showPitchUnsupportedMessage(context);
                    }
                  },
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Theme.of(context).colorScheme.secondaryFixed,
                  ),
                ),
              ),
            ],
          ),
          // Content area - show tempo or pitch controls based on selected tab
          if (_controlMode == ControlMode.tempo) ...[
            // Tempo mode selector (only show for premium users)
            if (hasPremium)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  height: 36,
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    color: Theme.of(context).colorScheme.secondary,
                    fillColor: Theme.of(context).colorScheme.primaryContainer,
                    disabledColor: Theme.of(context).colorScheme.secondary,
                    isSelected: [_mode == TempoMode.multiplier, _mode == TempoMode.bpm],
                    onPressed: (index) => _onChangeTempoMode(index),
                    children: const [
                      Text(
                        '×',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        'BPM',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            if (_mode == TempoMode.multiplier) _buildMultiplierMode(context, hasPremium),
            if (_mode == TempoMode.bpm) _buildBpmMode(context, hasPremium),
          ],
          if (_controlMode == ControlMode.pitch)
            if (isPitchSupported)
              _buildPitchMode(context)
            else
              _buildPitchUnsupportedNotice(context),
        ],
      ),
    );
  }

  Widget _buildMultiplierMode(BuildContext context, bool hasPremium) {
    return Padding(
      padding: const EdgeInsets.all(16).copyWith(top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // min speed
          Text('0.5×', style: context.labelLarge),
          // slider
          Expanded(
            child: CustomSlider(
              value: _speedMultiplier,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (double value) {
                if (!hasPremium) {
                  return;
                } else {
                  setState(() {
                    _speedMultiplier = value;
                  });
                }
              },
              onChangeEnd: (double value) {
                if (!hasPremium) {
                  _showPremiumDialog(context);
                } else {
                  widget.onSpeedMultiplierChanged(value);
                }
              },
            ),
          ),
          // max speed
          Text('2.0×', style: context.labelLarge),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_speedMultiplier.toStringAsFixed(1)}×',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBpmMode(BuildContext context, bool hasPremium) {
    // if original bpm is not set, show a button to set it
    if (_originalBpm == null) {
      return Padding(
        padding: const EdgeInsets.all(16).copyWith(top: 0),
        child: Column(
          spacing: 8,
          children: [
            Text(
              context.l10n.hereYouCanSetTheOriginalBpmOfTheAudioFile,
              style: context.labelLarge.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _originalBpmController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: context.l10n.enterSongBpm,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _onSetOriginalBpm,
                  child: Text(context.l10n.setBpm),
                ),
                TextButton(
                  onPressed: _showTapBpmDialog,
                  child: Text(context.l10n.tapBpm),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16).copyWith(top: 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _originalBpmController.text = _originalBpm?.toString() ?? '';
                    _originalBpm = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.originalBpm,
                        style: context.titleSmall.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        _originalBpm?.toString() ?? '-',
                        style: context.headlineMedium.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.currentBpm,
                      style: context.titleSmall.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      _currentBpm?.toString() ?? '-',
                      style: context.headlineMedium.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_minBpm != null && _maxBpm != null && _currentBpm != null)
            Row(
              children: [
                // min bpm
                Text(_minBpm?.toString() ?? '-', style: context.labelLarge),
                // slider
                Expanded(
                  child: CustomSlider(
                    value: _currentBpm?.toDouble() ?? 0,
                    min: _minBpm?.toDouble() ?? 0,
                    max: _maxBpm?.toDouble() ?? 0,
                    divisions: (_maxBpm ?? 0) - (_minBpm ?? 0),
                    onChanged: (double value) {
                      // check if premium user, if not, show a dialog to upgrade
                      if (!hasPremium) {
                        return;
                      } else {
                        setState(() {
                          _currentBpm = value.round();
                        });
                      }
                    },
                    onChangeEnd: (double value) {
                      if (!hasPremium) {
                        _showPremiumDialog(context);
                      } else {
                        widget.onCurrentBpmChanged(value.round());
                      }
                    },
                  ),
                ),
                // max bpm
                Text(_maxBpm?.toString() ?? '-', style: context.labelLarge),
              ],
            ),
        ],
      ),
    );
  }

  // min bpm are calculated by multiplying the original bpm by 0.5
  // but cannot be smaller than 1
  int? _calculateMinBpm(int originalBpm) {
    return (originalBpm * 0.5).round().clamp(1, originalBpm);
  }

  // max bpm are calculated by multiplying the original bpm by 2.0
  // but cannot be larger than 400
  int? _calculateMaxBpm(int originalBpm) {
    return (originalBpm * 2.0).round().clamp(originalBpm, 400);
  }

  void _calculateBpmFromTaps() {
    if (_tapTimes.length < 2) return;

    // Keep only the last 8 taps for more accurate measurement
    if (_tapTimes.length > 8) {
      _tapTimes.removeAt(0);
    }

    // Calculate intervals between consecutive taps
    final intervals = <int>[];
    for (int i = 1; i < _tapTimes.length; i++) {
      final interval = _tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds;
      intervals.add(interval);
    }

    if (intervals.isEmpty) return;

    // Calculate average interval
    final averageInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    // Convert to BPM: 60000ms per minute / average interval in ms
    final bpm = (60000 / averageInterval).round();

    // Only accept reasonable BPM values (40-200)
    if (bpm >= 40 && bpm <= 200) {
      setState(() {
        _calculatedBpm = bpm;
      });
    }
  }

  void _resetTapBpm() {
    setState(() {
      _tapTimes.clear();
      _calculatedBpm = null;
    });
  }

  void _showTapBpmDialog() {
    _resetTapBpm();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.l10n.tapBpm),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.tapTheButtonBelowInRhythmWithYourMusicToDetectTheBpm,
                  ),
                  const SizedBox(height: 24),
                  if (_calculatedBpm != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            context.l10n.detectedBpm,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_calculatedBpm',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        context.l10n.tapAtLeast2TimesToDetectBpm,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        _tapTimes.add(DateTime.now());
                        _calculateBpmFromTaps();
                        setDialogState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: const CircleBorder(),
                        elevation: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.touch_app, size: 32),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.tap,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${context.l10n.taps}: ${_tapTimes.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  onPressed: () {
                    _resetTapBpm();
                    Navigator.of(context).pop();
                  },
                  child: Text(context.l10n.cancel),
                ),
                PrimaryButton(
                  text: context.l10n.useBpm,
                  onPressed: _calculatedBpm != null
                      ? () {
                          // Update the text field with the calculated BPM
                          setState(() {
                            _originalBpmController.text = _calculatedBpm?.toString() ?? '';
                            _originalBpm = _calculatedBpm;
                            _minBpm = _calculateMinBpm(_originalBpm!);
                            _maxBpm = _calculateMaxBpm(_originalBpm!);
                            _currentBpm = _originalBpm;
                          });

                          AppAnalytics.trackEvent(
                            AppAnalytics.clickUseTappedBpm,
                            data: {
                              'bpm': _calculatedBpm,
                            },
                          );

                          Navigator.of(context).pop();
                        }
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onChangeTempoMode(int index) {
    setState(() {
      _mode = index == 0 ? TempoMode.multiplier : TempoMode.bpm;
    });

    if (index == 0) {
      AppAnalytics.trackEvent(
        AppAnalytics.clickTempoModeMultiplier,
      );
    } else {
      AppAnalytics.trackEvent(
        AppAnalytics.clickTempoModeBpm,
      );
    }

    widget.onTempoModeChanged(_mode);
  }

  void _onResetSpeedForMode(TempoMode mode) {
    if (mode == TempoMode.multiplier) {
      setState(() {
        _speedMultiplier = 1.0;
      });
      widget.onSpeedMultiplierChanged(_speedMultiplier);
    } else {
      setState(() {
        _currentBpm = _originalBpm;
      });
      widget.onCurrentBpmChanged(_currentBpm!);
    }
  }

  void _onSetOriginalBpm() {
    // set the original bpm
    setState(() {
      _originalBpm = int.tryParse(_originalBpmController.text);

      if (_originalBpm != null) {
        _minBpm = _calculateMinBpm(_originalBpm!);
        _maxBpm = _calculateMaxBpm(_originalBpm!);
        _currentBpm = _originalBpm;
        widget.onOriginalBpmChanged(_originalBpm!);
      }
    });
  }

  Future<void> _showPremiumDialog(BuildContext context) async {
    AppAnalytics.trackEvent(
      AppAnalytics.viewPremiumScreen,
      data: {
        'from': 'speed_control_${_mode.name}',
      },
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PremiumScreen(),
      ),
    );
  }

  void _onChangeControlMode(int index) {
    setState(() {
      _controlMode = index == 0 ? ControlMode.tempo : ControlMode.pitch;
    });
  }

  Widget _buildPitchMode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16).copyWith(top: 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // min pitch
              Text('-12', style: context.labelLarge),
              // slider
              Expanded(
                child: CustomSlider(
                  value: _pitchSemitones.toDouble(),
                  min: -12.0,
                  max: 12.0,
                  divisions: 24,
                  onChanged: (double value) {
                    setState(() {
                      _pitchSemitones = value.round();
                    });
                  },
                  onChangeEnd: (double value) {
                    widget.onPitchChanged(value.round());
                  },
                ),
              ),
              // max pitch
              Text('+12', style: context.labelLarge),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_pitchSemitones >= 0 ? '+' : ''}$_pitchSemitones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onResetPitch() {
    setState(() {
      _pitchSemitones = 0;
    });
    widget.onPitchChanged(0);
  }

  Widget _buildPitchUnsupportedNotice(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 8),
      child: Text(
        'Pitch shifting is not available on this device.',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showPitchUnsupportedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pitch shifting is not available on this device.'),
      ),
    );
  }
}
