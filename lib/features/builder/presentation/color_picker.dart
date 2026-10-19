import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/eye_dropper.dart';
import '../domain/color_tools.dart';

/// Result of a contrast check shown under the HEX/RGB inputs.
class ContrastStatus {
  const ContrastStatus({
    required this.ratio,
    required this.okMessage,
    required this.warnMessage,
  });

  final double ratio;
  final String okMessage;
  final String warnMessage;

  /// WCAG AA for normal text. Only ever a warning; it never blocks saving.
  bool get passes => ratio >= 4.5;
}

const _handleBorder = Colors.white;

/// Inline color picker: saturation/brightness area, hue slider, eyedropper
/// (where the browser supports it), HEX + RGB inputs, contrast check,
/// suggested colors and colors extracted from the logo.
///
/// The picker controls always stay left-to-right, like any color picker.
/// Every change is reported at most once per frame while dragging.
class ColorPickerPanel extends StatefulWidget {
  const ColorPickerPanel({
    super.key,
    required this.color,
    required this.onChanged,
    required this.roleName,
    required this.roleDescription,
    required this.presets,
    this.logoColors = const [],
    this.contrast,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final String roleName;
  final String roleDescription;
  final List<Color> presets;
  final List<Color> logoColors;
  final ContrastStatus? contrast;

  @override
  State<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<ColorPickerPanel> {
  late HSVColor _hsv = HSVColor.fromColor(widget.color);
  final _hex = TextEditingController();
  final _r = TextEditingController();
  final _g = TextEditingController();
  final _b = TextEditingController();
  final _hexFocus = FocusNode();
  final _rFocus = FocusNode();
  final _gFocus = FocusNode();
  final _bFocus = FocusNode();

  Color? _pending;
  bool _emitScheduled = false;

  @override
  void initState() {
    super.initState();
    for (final f in [_hexFocus, _rFocus, _gFocus, _bFocus]) {
      f.addListener(() {
        if (!f.hasFocus) _revertInvalidFields();
      });
    }
    _syncFields();
  }

  @override
  void didUpdateWidget(ColorPickerPanel old) {
    super.didUpdateWidget(old);
    if (hexOf(widget.color) != hexOf(_hsv.toColor())) {
      _hsv = _fromColorKeepingHue(widget.color);
    }
    _syncFields();
  }

  @override
  void dispose() {
    for (final c in [_hex, _r, _g, _b]) {
      c.dispose();
    }
    for (final f in [_hexFocus, _rFocus, _gFocus, _bFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  /// Grays and black have no hue; keep the one the user was on.
  HSVColor _fromColorKeepingHue(Color c) {
    final h = HSVColor.fromColor(c);
    return (h.saturation == 0 || h.value == 0) ? h.withHue(_hsv.hue) : h;
  }

  /// Writes the current color into inputs that are not being edited.
  void _syncFields() {
    final c = widget.color;
    final (r, g, b) = rgbOf(c);
    if (!_hexFocus.hasFocus) _hex.text = hexOf(c);
    if (!_rFocus.hasFocus) _r.text = '$r';
    if (!_gFocus.hasFocus) _g.text = '$g';
    if (!_bFocus.hasFocus) _b.text = '$b';
  }

  /// A field that lost focus with an invalid value goes back to the last
  /// valid color.
  void _revertInvalidFields() {
    final c = widget.color;
    final (r, g, b) = rgbOf(c);
    if (parseFlexibleHex(_hex.text) == null) _hex.text = hexOf(c);
    if (!_hexFocus.hasFocus && parseFlexibleHex(_hex.text) != null) {
      _hex.text = hexOf(parseFlexibleHex(_hex.text)!);
    }
    for (final e in [(_r, r), (_g, g), (_b, b)]) {
      final v = int.tryParse(e.$1.text);
      if (v == null || v > 255) e.$1.text = '${e.$2}';
    }
  }

  /// Drag path: update the picker immediately, tell the parent once per frame.
  void _applyHsv(HSVColor hsv) {
    setState(() => _hsv = hsv);
    _pending = hsv.toColor();
    if (_emitScheduled) return;
    _emitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitScheduled = false;
      final c = _pending;
      if (c != null && mounted) widget.onChanged(c);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Discrete path (HEX, RGB, swatches, eyedropper): apply right away.
  void _applyColor(Color c) {
    setState(() => _hsv = _fromColorKeepingHue(c));
    widget.onChanged(c);
  }

  void _onRgbChanged(int channel, String text) {
    final v = int.tryParse(text);
    if (v == null || v < 0 || v > 255) return;
    var (r, g, b) = rgbOf(widget.color);
    switch (channel) {
      case 0:
        r = v;
      case 1:
        g = v;
      default:
        b = v;
    }
    _applyColor(Color.fromARGB(255, r, g, b));
  }

  Future<void> _eyedrop() async {
    final hex = await pickColorFromScreen();
    final c = hex == null ? null : parseFlexibleHex(hex);
    if (c != null) _applyColor(c);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final twoColumns = MediaQuery.sizeOf(context).width >= 768;

    final picker = Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SaturationValueArea(hsv: _hsv, onChanged: _applyHsv),
          const SizedBox(height: 14),
          Row(
            children: [
              if (eyeDropperSupported) ...[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Tooltip(
                    message: l10n.eyedropperLabel,
                    child: IconButton.outlined(
                      key: const ValueKey('eyedropper'),
                      onPressed: _eyedrop,
                      icon: const Icon(Icons.colorize, size: 20),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(40, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: HueSlider(hsv: _hsv, onChanged: _applyHsv),
              ),
            ],
          ),
        ],
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SwatchBox(color: widget.color, size: 56, radius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.roleName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.roleDescription,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _LabeledField(
                label: l10n.hexLabel,
                child: TextField(
                  key: const ValueKey('hex-field'),
                  controller: _hex,
                  focusNode: _hexFocus,
                  textDirection: TextDirection.ltr,
                  style: monoStyle(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                  decoration: _inputDecoration(),
                  onChanged: (v) {
                    final c = parseFlexibleHex(v);
                    if (c != null && hexOf(c) != hexOf(widget.color)) {
                      _applyColor(c);
                    }
                  },
                  onSubmitted: (_) => _revertInvalidFields(),
                ),
              ),
            ),
            for (final e in [
              ('R', _r, _rFocus, 0, 'rgb-r'),
              ('G', _g, _gFocus, 1, 'rgb-g'),
              ('B', _b, _bFocus, 2, 'rgb-b'),
            ]) ...[
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _LabeledField(
                  label: e.$1,
                  child: TextField(
                    key: ValueKey(e.$5),
                    controller: e.$2,
                    focusNode: e.$3,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.number,
                    style: monoStyle(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: _inputDecoration(),
                    onChanged: (v) => _onRgbChanged(e.$4, v),
                    onSubmitted: (_) => _revertInvalidFields(),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (widget.contrast != null) ...[
          const SizedBox(height: 14),
          _ContrastRow(status: widget.contrast!),
        ],
        const SizedBox(height: 18),
        Text(
          l10n.suggestedColors,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 0,
          runSpacing: 0,
          children: [
            for (final c in widget.presets)
              _SwatchButton(
                key: ValueKey('preset-${hexOf(c)}'),
                color: c,
                selected: hexOf(c) == hexOf(widget.color),
                round: true,
                onTap: () => _applyColor(c),
              ),
          ],
        ),
        if (widget.logoColors.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            l10n.fromLogo,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Wrap(
            children: [
              for (final c in widget.logoColors)
                _SwatchButton(
                  key: ValueKey('logo-color-${hexOf(c)}'),
                  color: c,
                  selected: hexOf(c) == hexOf(widget.color),
                  round: false,
                  onTap: () => _applyColor(c),
                ),
            ],
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: twoColumns
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: picker),
                const SizedBox(width: 24),
                Expanded(child: details),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [picker, const SizedBox(height: 20), details],
            ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    constraints: const BoxConstraints(minHeight: 44),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _SwatchBox extends StatelessWidget {
  const _SwatchBox({
    required this.color,
    required this.size,
    required this.radius,
  });
  final Color color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        // Keeps white and other light colors visible.
        border: Border.all(color: const Color(0x1F000000)),
      ),
    );
  }
}

/// 32px swatch inside a 44px hit area.
class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    super.key,
    required this.color,
    required this.selected,
    required this.round,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final bool round;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.colorSwatchLabel(hexOf(color)),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: round ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: round ? null : BorderRadius.circular(8),
                border: Border.all(color: const Color(0x1F000000)),
                boxShadow: selected
                    ? const [
                        BoxShadow(color: Colors.white, spreadRadius: 2),
                        BoxShadow(color: AppColors.accent, spreadRadius: 4),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContrastRow extends StatelessWidget {
  const _ContrastRow({required this.status});
  final ContrastStatus status;

  @override
  Widget build(BuildContext context) {
    final ok = status.passes;
    final fg = ok ? const Color(0xFF1D6B3A) : const Color(0xFF7A4A00);
    return Container(
      key: const ValueKey('contrast-row'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFEAF5EE) : const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              ok ? Icons.check_circle : Icons.warning_amber_rounded,
              size: 18,
              color: fg,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                ok ? status.okMessage : status.warnMessage,
                style: TextStyle(fontSize: 13, color: fg, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pan recognizer that wins the gesture arena on pointer down, so dragging a
/// picker handle never scrolls the surrounding page.
class _EagerPanRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

Map<Type, GestureRecognizerFactory> _panGestures({
  required void Function(Offset) onPoint,
}) => {
  _EagerPanRecognizer:
      GestureRecognizerFactoryWithHandlers<_EagerPanRecognizer>(
        _EagerPanRecognizer.new,
        (r) => r
          ..dragStartBehavior = DragStartBehavior.down
          ..onStart = ((d) => onPoint(d.localPosition))
          ..onUpdate = ((d) => onPoint(d.localPosition)),
      ),
};

/// Saturation (x) and brightness (y) of the current hue.
class SaturationValueArea extends StatefulWidget {
  const SaturationValueArea({
    super.key,
    required this.hsv,
    required this.onChanged,
  });
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  State<SaturationValueArea> createState() => _SaturationValueAreaState();
}

class _SaturationValueAreaState extends State<SaturationValueArea> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _pick(Offset p, Size size) {
    final s = (p.dx / size.width).clamp(0.0, 1.0);
    final v = 1 - (p.dy / size.height).clamp(0.0, 1.0);
    widget.onChanged(widget.hsv.withSaturation(s).withValue(v));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = HardwareKeyboard.instance.isShiftPressed ? 0.10 : 0.01;
    var s = widget.hsv.saturation, v = widget.hsv.value;
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
      s -= step;
    } else if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      s += step;
    } else if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      v += step;
    } else if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      v -= step;
    } else {
      return KeyEventResult.ignored;
    }
    widget.onChanged(
      widget.hsv.withSaturation(s.clamp(0.0, 1.0)).withValue(v.clamp(0.0, 1.0)),
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hsv = widget.hsv;
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    return Semantics(
      slider: true,
      label: l10n.pickerAreaLabel,
      value: l10n.pickerAreaValue(
        '${(hsv.saturation * 100).round()}',
        '${(hsv.value * 100).round()}',
      ),
      onIncrease: () => widget.onChanged(
        hsv.withSaturation((hsv.saturation + 0.01).clamp(0.0, 1.0)),
      ),
      onDecrease: () => widget.onChanged(
        hsv.withSaturation((hsv.saturation - 0.01).clamp(0.0, 1.0)),
      ),
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        child: LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, 220);
            final x = hsv.saturation * size.width;
            final y = (1 - hsv.value) * size.height;
            return RawGestureDetector(
              key: const ValueKey('sv-area'),
              behavior: HitTestBehavior.opaque,
              gestures: _panGestures(
                onPoint: (p) {
                  _focus.requestFocus();
                  _pick(p, size);
                },
              ),
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, hueColor],
                            ),
                          ),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: x - 10,
                      top: y - 10,
                      child: IgnorePointer(
                        child: _Handle(
                          size: 20,
                          color: hsv.toColor(),
                          focused: _focus.hasFocus,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Rainbow hue slider (0–360°).
class HueSlider extends StatefulWidget {
  const HueSlider({super.key, required this.hsv, required this.onChanged});
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  State<HueSlider> createState() => _HueSliderState();
}

class _HueSliderState extends State<HueSlider> {
  static const _thumb = 22.0;
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _setHue(double hue) {
    widget.onChanged(widget.hsv.withHue(hue.clamp(0.0, 359.9)));
  }

  void _pick(double dx, double width) {
    final t = ((dx - _thumb / 2) / (width - _thumb)).clamp(0.0, 1.0);
    _setHue(t * 359.9);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = HardwareKeyboard.instance.isShiftPressed ? 10.0 : 1.0;
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft ||
        e.logicalKey == LogicalKeyboardKey.arrowDown) {
      _setHue(widget.hsv.hue - step);
    } else if (e.logicalKey == LogicalKeyboardKey.arrowRight ||
        e.logicalKey == LogicalKeyboardKey.arrowUp) {
      _setHue(widget.hsv.hue + step);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hsv = widget.hsv;
    return Semantics(
      slider: true,
      label: l10n.hueLabel,
      value: l10n.hueValue('${hsv.hue.round()}'),
      onIncrease: () => _setHue(hsv.hue + 1),
      onDecrease: () => _setHue(hsv.hue - 1),
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final left = (hsv.hue / 359.9).clamp(0.0, 1.0) * (w - _thumb);
            return RawGestureDetector(
              key: const ValueKey('hue-slider'),
              behavior: HitTestBehavior.opaque,
              gestures: _panGestures(
                onPoint: (p) {
                  _focus.requestFocus();
                  _pick(p.dx, w);
                },
              ),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        gradient: LinearGradient(
                          colors: [
                            for (var h = 0; h <= 360; h += 60)
                              HSVColor.fromAHSV(
                                1,
                                h.toDouble(),
                                1,
                                1,
                              ).toColor(),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: left,
                      child: IgnorePointer(
                        child: _Handle(
                          size: _thumb,
                          color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                          focused: _focus.hasFocus,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({
    required this.size,
    required this.color,
    required this.focused,
  });
  final double size;
  final Color color;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: _handleBorder, width: 3),
        boxShadow: [
          const BoxShadow(
            color: Color(0x59000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
          if (focused)
            const BoxShadow(color: AppColors.accent, spreadRadius: 3),
        ],
      ),
    );
  }
}
