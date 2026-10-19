import 'dart:math' as math;

import 'package:flutter/material.dart';

enum PhoneDevice { iphone, android }

/// Reusable device chrome. The [child] is laid out at the phone's logical
/// size ([screenLogicalSize]) and scaled into the screen, so any app content
/// renders exactly as on a real phone. The whole frame scales down
/// proportionally when its container is narrower than the frame.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.device,
    required this.child,
    this.scale = 1,
    this.darkScreen = false,
  });

  final PhoneDevice device;
  final Widget child;

  /// Display scale (1 = 300×620 plus side buttons).
  final double scale;

  /// Makes the home indicator light so it stays visible on dark content.
  final bool darkScreen;

  static const _bodyWidth = 300.0;
  static const _bodyHeight = 620.0;
  static const _buttonWidth = 3.0;
  static const _bezel = 11.0;
  static const _totalWidth = _bodyWidth + 2 * _buttonWidth;

  /// Logical size the app content is laid out at.
  static const screenLogicalWidth = 390.0;
  static const _screenWidth = _bodyWidth - 2 * _bezel;
  static const _screenHeight = _bodyHeight - 2 * _bezel;
  static const screenLogicalHeight =
      screenLogicalWidth * _screenHeight / _screenWidth;

  /// Space the content should keep clear at the top, in app (logical) units.
  static double topInsetFor(PhoneDevice d) {
    final framePx = d == PhoneDevice.iphone ? 46.0 : 34.0;
    return framePx * screenLogicalWidth / _screenWidth;
  }

  @override
  Widget build(BuildContext context) {
    final isIphone = device == PhoneDevice.iphone;
    final outerRadius = isIphone ? 52.0 : 40.0;
    final screenRadius = isIphone ? 42.0 : 30.0;
    const buttonColor = Color(0xFF2A2F3A);

    Widget button(double top, double height, {required bool left}) =>
        Positioned(
          top: top,
          left: left ? 0 : null,
          right: left ? null : 0,
          width: _buttonWidth,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );

    final body = SizedBox(
      width: _totalWidth,
      height: _bodyHeight,
      child: Stack(
        children: [
          if (isIphone) ...[
            button(92, 22, left: true), // action
            button(134, 42, left: true), // volume up
            button(186, 42, left: true), // volume down
            button(152, 72, left: false), // power
          ] else ...[
            button(150, 58, left: false), // power
            button(222, 78, left: false), // volume
          ],
          Positioned(
            left: _buttonWidth,
            top: 0,
            width: _bodyWidth,
            height: _bodyHeight,
            child: Container(
              padding: const EdgeInsets.all(_bezel),
              decoration: BoxDecoration(
                color: const Color(0xFF14171D),
                borderRadius: BorderRadius.circular(outerRadius),
                border: Border.all(color: const Color(0xFF3A404C), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x73141828),
                    offset: Offset(0, 30),
                    blurRadius: 60,
                    spreadRadius: -20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenRadius),
                child: ColoredBox(
                  color: Colors.white,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: screenLogicalWidth,
                      height: screenLogicalHeight,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isIphone)
            Positioned(
              top: _bezel + 10,
              left: _buttonWidth + (_bodyWidth - 92) / 2,
              child: Container(
                width: 92,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            )
          else
            Positioned(
              top: _bezel + 12,
              left: _buttonWidth + (_bodyWidth - 12) / 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (isIphone)
            Positioned(
              bottom: _bezel + 7,
              left: _buttonWidth + (_bodyWidth - 108) / 2,
              child: Container(
                width: 108,
                height: 4,
                decoration: BoxDecoration(
                  color: darkScreen
                      ? Colors.white.withValues(alpha: 0.85)
                      : const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, box) {
        final wanted = _totalWidth * scale;
        final f = box.maxWidth.isFinite
            ? math.min(1.0, box.maxWidth / wanted)
            : 1.0;
        return SizedBox(
          width: wanted * f,
          height: _bodyHeight * scale * f,
          child: FittedBox(fit: BoxFit.contain, child: body),
        );
      },
    );
  }
}
