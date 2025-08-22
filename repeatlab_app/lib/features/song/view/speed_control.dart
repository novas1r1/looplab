import 'package:flutter/material.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';

enum _TempoMode { multiplier, bpm }

final class SpeedControl extends StatefulWidget {
  const SpeedControl({super.key});

  @override
  State<SpeedControl> createState() => _SpeedControlState();
}

class _SpeedControlState extends State<SpeedControl> {
  final _originalBpmController = TextEditingController();

  _TempoMode _mode = _TempoMode.multiplier;
  double _speedMultiplier = 1.0;

  int? _currentBpm;
  int? _originalBpm;

  // max 0.5 from original bpm
  int? _minBpm;

  // max 2.0 from original bpm
  int? _maxBpm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                child: Text(
                  'Speed Control',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondaryFixed,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: SizedBox(
                  height: 36,
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    color: Theme.of(context).colorScheme.secondary,
                    fillColor: Theme.of(context).colorScheme.primaryContainer,

                    isSelected: [_mode == _TempoMode.multiplier, _mode == _TempoMode.bpm],
                    onPressed: (index) {
                      setState(() {
                        _mode = index == 0 ? _TempoMode.multiplier : _TempoMode.bpm;
                      });
                    },
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
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _speedMultiplier = 1.0;
                      _currentBpm = _originalBpm;
                    });
                  },
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Theme.of(context).colorScheme.secondaryFixed,
                  ),
                ),
              ),
            ],
          ),
          if (_mode == _TempoMode.multiplier)
            _buildMultiplierMode(context)
          else
            _buildBpmMode(context),
        ],
      ),
    );
  }

  Widget _buildMultiplierMode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16).copyWith(top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // min speed
          Text('0.5×', style: context.labelLarge),
          // slider
          Expanded(
            child: Slider(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              value: _speedMultiplier,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (double value) {
                setState(() {
                  _speedMultiplier = value;
                });
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

  Widget _buildBpmMode(BuildContext context) {
    // if original bpm is not set, show a button to set it
    if (_originalBpm == null) {
      return Padding(
        padding: const EdgeInsets.all(16).copyWith(top: 0),
        child: Column(
          spacing: 8,
          children: [
            Text(
              'No BPM detected, please set the original BPM of the audio file.',
              style: context.labelLarge,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _originalBpmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter BPM',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // set the original bpm
                    // TODO(Verena): save to database
                    setState(() {
                      _originalBpm = int.tryParse(_originalBpmController.text);

                      if (_originalBpm != null) {
                        _minBpm = (_originalBpm! * 0.5).round();
                        _maxBpm = (_originalBpm! * 2.0).round();
                        _currentBpm = _originalBpm;
                      }
                    });
                  },
                  child: const Text('Set BPM'),
                ),
                TextButton(
                  onPressed: () {
                    // show a dialog to set the original bpm
                  },
                  child: const Text('Tap BPM'),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORIGINAL BPM',
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
                      'CURRENT BPM',
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
                  child: Slider(
                    padding: const EdgeInsets.symmetric(horizontal: 16),

                    value: _currentBpm?.toDouble() ?? 0,
                    min: _minBpm?.toDouble() ?? 0,
                    max: _maxBpm?.toDouble() ?? 0,
                    divisions: (_maxBpm ?? 0) - (_minBpm ?? 0),
                    onChanged: (double value) {
                      setState(() {
                        _currentBpm = value.round();
                      });
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
}
/* 
class SpeedControl extends StatefulWidget {
  const SpeedControl({super.key});

  @override
  State<SpeedControl> createState() => _SpeedControlState();
}

class _SpeedControlState extends State<SpeedControl> with SingleTickerProviderStateMixin {
  _TempoMode _mode = _TempoMode.multiplier;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 0.5,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = context.select((SongCubit cubit) => cubit.state.song);
    final speed = context.select((SongCubit cubit) => cubit.state.speed);

    final originalBpm = song.bpm;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Collapsed header - always visible
          _buildCollapsedHeader(context, speed, originalBpm),
          // Expandable content
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _heightAnimation,
                child: FadeTransition(
                  opacity: _heightAnimation,
                  child: _buildExpandableContent(context, speed, originalBpm),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedHeader(BuildContext context, double speed, int? originalBpm) {
    final speedLabel = _mode == _TempoMode.multiplier
        ? '${speed.toStringAsFixed(1)}×'
        : originalBpm != null
        ? '$originalBpm ⇾ ${(originalBpm * speed).round()} BPM'
        : 'No BPM';

    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.speed_rounded,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Speed Control',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                speedLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 3.14159,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    size: 24,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableContent(BuildContext context, double speed, int? originalBpm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          // Mode toggle buttons
          Row(
            children: [
              _buildModeToggle(context, originalBpm),
              const Spacer(),
              if (_mode == _TempoMode.multiplier) _buildResetButton(context),
            ],
          ),
          const SizedBox(height: 8),
          // Mode-specific content
          if (_mode == _TempoMode.multiplier)
            _buildMultiplierMode(context, speed)
          else
            _buildBpmMode(context, speed, originalBpm),
        ],
      ),
    );
  }

  Widget _buildModeToggle(BuildContext context, int? originalBpm) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ToggleButtons(
        isSelected: [
          _mode == _TempoMode.multiplier,
          _mode == _TempoMode.bpm,
        ],
        onPressed: (index) => _onSelectMode(index, context, originalBpm),
        borderRadius: BorderRadius.circular(6),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
        selectedColor: Theme.of(context).colorScheme.onPrimary,
        fillColor: Theme.of(context).colorScheme.primary,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '×',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'BPM',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return IconButton(
      onPressed: () => _onReset(context),
      icon: Icon(
        Icons.refresh_rounded,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      tooltip: 'Reset',
    );
  }

  Widget _buildMultiplierMode(BuildContext context, double speed) {
    final sliderValue = speed.clamp(0.5, 2.0);
    final sliderLabel = '${speed.toStringAsFixed(1)}×';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Speed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                sliderLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: sliderValue,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            label: sliderLabel,
            onChanged: (val) => _onUpdate(context, val, null),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0.5×',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '2.0×',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBpmMode(BuildContext context, double speed, int? originalBpm) {
    if (originalBpm == null) {
      return _buildBpmPrompt(context);
    }

    final sliderValue = (originalBpm * speed).clamp(originalBpm * 0.5, originalBpm * 2.0);
    final currentBpm = sliderValue.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BPM display row
        Row(
          children: [
            Expanded(
              child: _buildBpmCard(
                context,
                'Original BPM',
                originalBpm.toString(),
                Theme.of(context).colorScheme.surface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBpmCard(
                context,
                'Current BPM',
                currentBpm.toString(),
                Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _onTapLabel(context, originalBpm),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Left side buttons (-10, -1)
                Row(
                  children: [
                    _buildBpmButton(
                      context,
                      '-10',
                      () => _adjustBpm(context, -10, originalBpm, speed),
                      isLarge: false,
                    ),
                    const SizedBox(width: 4),
                    _buildBpmButton(
                      context,
                      '-1',
                      () => _adjustBpm(context, -1, originalBpm, speed),
                      isLarge: false,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Slider
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                      thumbColor: Theme.of(context).colorScheme.primary,
                      overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: sliderValue,
                      min: originalBpm * 0.5,
                      max: originalBpm * 2.0,
                      label: '$currentBpm BPM',
                      onChanged: (val) => _onUpdate(context, val, originalBpm),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Right side buttons (+1, +10)
                Row(
                  children: [
                    _buildBpmButton(
                      context,
                      '+1',
                      () => _adjustBpm(context, 1, originalBpm, speed),
                      isLarge: false,
                    ),
                    const SizedBox(width: 4),
                    _buildBpmButton(
                      context,
                      '+10',
                      () => _adjustBpm(context, 10, originalBpm, speed),
                      isLarge: false,
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(originalBpm * 0.5).round()} BPM',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${(originalBpm * 2.0).round()} BPM',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBpmCard(BuildContext context, String label, String value, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBpmPrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.music_note_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'No BPM Set',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set the BPM to use BPM mode for precise tempo control',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _onTapLabel(context, null),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Set BPM'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBpmButton(
    BuildContext context,
    String label,
    VoidCallback onPressed, {
    required bool isLarge,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  void _adjustBpm(BuildContext context, int adjustment, int? originalBpm, double currentSpeed) {
    if (originalBpm == null) return;

    final currentBpm = (originalBpm * currentSpeed).round();
    final newBpm = currentBpm + adjustment;

    // Clamp to valid range
    final minBpm = (originalBpm * 0.5).round();
    final maxBpm = (originalBpm * 2.0).round();
    final clampedBpm = newBpm.clamp(minBpm, maxBpm);

    // Convert back to speed multiplier
    final newSpeed = clampedBpm / originalBpm;

    _onUpdateSpeed(context, newSpeed);
  }

  Future<void> _onSelectMode(int index, BuildContext context, int? originalBpm) async {
    final selectedMode = index == 0 ? _TempoMode.multiplier : _TempoMode.bpm;

    if (selectedMode == _TempoMode.bpm && originalBpm == null) {
      final bpm = await _promptForBpm(context, originalBpm);
      if (bpm == null) return; // User cancelled.

      await context.read<SongCubit>().updateBpm(bpm);
    }

    setState(() => _mode = selectedMode);
  }

  Future<int?> _promptForBpm(BuildContext context, int? originalBpm) async {
    final controller = TextEditingController();
    controller.text = originalBpm?.toString() ?? '';

    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.enterSongBpm),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.enterSongBpmHint),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: context.l10n.enterSongBpmHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  Navigator.pop<int>(context, value);
                }
              },
              child: Text(context.l10n.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onUpdate(BuildContext context, double rawValue, int? originalBpm) async {
    double newSpeed;

    if (_mode == _TempoMode.multiplier) {
      newSpeed = rawValue;
    } else {
      // rawValue is BPM here.
      if (originalBpm == null || originalBpm == 0) return;
      newSpeed = rawValue / originalBpm;
    }

    _onUpdateSpeed(context, newSpeed);
  }

  Future<void> _onUpdateSpeed(BuildContext context, double newSpeed) async {
    AppAnalytics.trackEvent(AppAnalytics.clickUpdateSpeed, data: {'speed': newSpeed});

    final hasPurchased = context.read<PremiumSubscriptionCubit>().hasPremium;

    if (!context.mounted) return;

    if (hasPurchased) {
      context.read<SongCubit>().updateSpeed(newSpeed);
    } else {
      AppAnalytics.trackEvent(AppAnalytics.showPaywallSongSpeed);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
    }
  }

  Future<void> _onTapLabel(BuildContext context, int? originalBpm) async {
    if (_mode != _TempoMode.bpm) return;

    final bpm = await _promptForBpm(context, originalBpm);
    if (bpm == null) return;

    // Update song BPM only if it changed.
    if (originalBpm != bpm) {
      await context.read<SongCubit>().updateBpm(bpm);
    }
  }

  void _onReset(BuildContext context) {
    context.read<SongCubit>().updateSpeed(1.0);
  }
}
 */