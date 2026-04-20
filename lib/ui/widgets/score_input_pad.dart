import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/throw_record.dart';
import '../../theme/app_theme.dart';

typedef OnThrowRecorded = void Function(int rawValue, String multiplierType);

class ScoreInputPad extends StatefulWidget {
  final OnThrowRecorded onThrow;
  final bool enabled;
  final int remainingScore;

  const ScoreInputPad({
    super.key,
    required this.onThrow,
    required this.enabled,
    required this.remainingScore,
  });

  @override
  State<ScoreInputPad> createState() => _ScoreInputPadState();
}

class _ScoreInputPadState extends State<ScoreInputPad> {
  String _selectedMultiplier = MultiplierType.single;
  // Staged throw: set when a number is tapped, cleared after confirm or cancel
  int? _stagedValue;

  void _stageNumber(int val) {
    if (!widget.enabled) return;
    setState(() => _stagedValue = val);
  }

  void _confirmThrow() {
    final val = _stagedValue;
    if (val == null || !widget.enabled) return;
    widget.onThrow(val, _selectedMultiplier);
    setState(() {
      _stagedValue = null;
      _selectedMultiplier = MultiplierType.single;
    });
  }

  void _cancelStaged() => setState(() => _stagedValue = null);

  void _recordSpecial(int rawValue, String type) {
    if (!widget.enabled) return;
    widget.onThrow(rawValue, type);
    setState(() {
      _stagedValue = null;
      _selectedMultiplier = MultiplierType.single;
    });
  }

  String get _stagedLabel {
    if (_stagedValue == null) return '';
    return '${MultiplierType.label(_selectedMultiplier)}$_stagedValue';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStagingBar(),
        const SizedBox(height: 6),
        _buildMultiplierRow(),
        const SizedBox(height: 6),
        Expanded(child: _buildNumberGrid()),
        const SizedBox(height: 6),
        _buildSpecialRow(),
      ],
    );
  }

  /// Shows what's staged and the confirm / cancel actions.
  Widget _buildStagingBar() {
    final hasStaged = _stagedValue != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasStaged ? AppColors.gold.withAlpha(20) : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasStaged ? AppColors.gold : AppColors.border,
          width: hasStaged ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasStaged ? _stagedLabel : 'Select multiplier, then tap a number',
              style: GoogleFonts.nunito(
                fontSize: hasStaged ? 22 : 13,
                fontWeight: FontWeight.w800,
                color: hasStaged ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
          ),
          if (hasStaged) ...[
            _ActionButton(
              label: '✓',
              color: AppColors.green,
              onTap: _confirmThrow,
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: '✕',
              color: AppColors.textSecondary,
              onTap: _cancelStaged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMultiplierRow() {
    return Row(
      children: [
        _MultiplierButton(
          label: 'Single',
          shortLabel: 'S',
          selected: _selectedMultiplier == MultiplierType.single,
          onTap: () => setState(() {
            _selectedMultiplier = MultiplierType.single;
            _stagedValue = null;
          }),
          enabled: widget.enabled,
        ),
        const SizedBox(width: 6),
        _MultiplierButton(
          label: 'Double',
          shortLabel: 'D',
          selected: _selectedMultiplier == MultiplierType.double_,
          onTap: () => setState(() {
            _selectedMultiplier = MultiplierType.double_;
            _stagedValue = null;
          }),
          enabled: widget.enabled,
          color: AppColors.gold,
        ),
        const SizedBox(width: 6),
        _MultiplierButton(
          label: 'Triple',
          shortLabel: 'T',
          selected: _selectedMultiplier == MultiplierType.triple,
          onTap: () => setState(() {
            _selectedMultiplier = MultiplierType.triple;
            _stagedValue = null;
          }),
          enabled: widget.enabled,
          color: AppColors.red,
        ),
      ],
    );
  }

  Widget _buildNumberGrid() {
    const rows = [
      [1, 2, 3, 4, 5],
      [6, 7, 8, 9, 10],
      [11, 12, 13, 14, 15],
      [16, 17, 18, 19, 20],
    ];
    return Column(
      children: rows
          .map(
            (row) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: row
                      .map(
                        (n) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _FlexButton(
                              label: '$n',
                              onTap: () => _stageNumber(n),
                              enabled: widget.enabled,
                              highlighted: _stagedValue == n,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSpecialRow() {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: _FlexButton(
              label: 'Bull  50',
              color: AppColors.red,
              onTap: () => _recordSpecial(25, MultiplierType.bull),
              enabled: widget.enabled,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _FlexButton(
              label: 'Outer  25',
              color: AppColors.blue,
              onTap: () => _recordSpecial(25, MultiplierType.outerBull),
              enabled: widget.enabled,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _FlexButton(
              label: 'Miss  0',
              color: AppColors.textSecondary,
              onTap: () => _recordSpecial(0, MultiplierType.miss),
              enabled: widget.enabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlexButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final Color? color;
  final bool highlighted;

  const _FlexButton({
    required this.label,
    required this.onTap,
    required this.enabled,
    this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary;
    return Material(
      color: highlighted
          ? AppColors.gold.withAlpha(30)
          : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlighted ? AppColors.gold : AppColors.border,
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: enabled ? effectiveColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(120)),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _MultiplierButton extends StatelessWidget {
  final String label;
  final String shortLabel;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;
  final Color? color;

  const _MultiplierButton({
    required this.label,
    required this.shortLabel,
    required this.selected,
    required this.onTap,
    required this.enabled,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.textPrimary;
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? activeColor.withAlpha(30) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? activeColor : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            '$shortLabel · $label',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? activeColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
