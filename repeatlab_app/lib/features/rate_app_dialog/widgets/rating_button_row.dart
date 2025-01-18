import 'package:flutter/material.dart';
import 'package:repeatlab/core/utils/svg_icon.dart';

class RatingButtonRow extends StatefulWidget {
  final Function(int starCount) onChangedRating;

  const RatingButtonRow({
    required this.onChangedRating,
    super.key,
  });

  @override
  State<RatingButtonRow> createState() => _RatingButtonRowState();
}

class _RatingButtonRowState extends State<RatingButtonRow> {
  List<bool> _isSelected = [false, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => _StarButton(
          isSelected: _isSelected[index],
          onChanged: (isSelected) => _onSelect(index + 1),
        ),
      ),
    );
  }

  void _onSelect(int starCount) {
    switch (starCount) {
      case 1:
        _isSelected = [true, false, false, false, false];
      case 2:
        _isSelected = [true, true, false, false, false];
      case 3:
        _isSelected = [true, true, true, false, false];
      case 4:
        _isSelected = [true, true, true, true, false];
      case 5:
        _isSelected = [true, true, true, true, true];
      default:
        throw Exception('Invalid star count');
    }

    setState(() {
      widget.onChangedRating(starCount);
    });
  }
}

class _StarButton extends StatelessWidget {
  final bool isSelected;
  final Function(bool) onChanged;

  const _StarButton({
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isSelected
          ? SvgIcon(
              name: 'ic_star_filled',
              size: 42,
              semanticLabel: 'star filled',
              color: Theme.of(context).colorScheme.primary,
            )
          : SvgIcon(
              name: 'ic_star',
              size: 42,
              semanticLabel: 'star',
              color: Theme.of(context).colorScheme.primary,
            ),
      onPressed: () => onChanged(!isSelected),
    );
  }
}
