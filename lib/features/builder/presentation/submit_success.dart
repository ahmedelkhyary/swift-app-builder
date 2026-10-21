import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

const _successGreen = Color(0xFF1A8F5F);
const _titleInk = Color(0xFF1B2340);
const _bodyGrey = Color(0xFF4F566E);
const _labelGrey = Color(0xFF5B6275);
const _upcomingGrey = Color(0xFF6B7390);
const _lineGrey = Color(0xFFDCDFEA);

/// Darkens [c] until it is readable (4.5:1) on white, for text.
Color _readableOnWhite(Color c) {
  var out = c;
  for (var i = 0; i < 12 && _contrast(out, Colors.white) < 4.5; i++) {
    out = Color.lerp(out, Colors.black, 0.15)!;
  }
  return out;
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Shows the "request submitted" modal (a bottom sheet on small screens).
/// It only closes through its "Back to start" button.
Future<void> showSubmitSuccess(
  BuildContext context, {
  required String appId,
  required String email,
  required Color primary,
}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: const Color(0x990F1428), // dark, ~60%
    transitionDuration: reduce
        ? Duration.zero
        : const Duration(milliseconds: 250),
    pageBuilder: (ctx, _, _) =>
        _SuccessPage(appId: appId, email: email, primary: primary),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final sheet = MediaQuery.sizeOf(ctx).width < 600;
      return Stack(
        children: [
          // Slight blur behind the card, fading in with the backdrop.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: curved,
                builder: (_, _) => BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 3 * curved.value,
                    sigmaY: 3 * curved.value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: curved,
            child: sheet
                ? SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  )
                : ScaleTransition(
                    scale: Tween(begin: 0.95, end: 1.0).animate(curved),
                    child: child,
                  ),
          ),
        ],
      );
    },
  );
}

class _SuccessPage extends StatelessWidget {
  const _SuccessPage({
    required this.appId,
    required this.email,
    required this.primary,
  });

  final String appId;
  final String email;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sheet = MediaQuery.sizeOf(context).width < 600;
    final card = Container(
      key: const ValueKey('submit-success'),
      constraints: const BoxConstraints(maxWidth: 424),
      padding: EdgeInsets.fromLTRB(
        sheet ? 24 : 32,
        sheet ? 28 : 32,
        sheet ? 24 : 32,
        sheet ? 24 : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: sheet
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x470F1428),
            blurRadius: 60,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: _SuccessCard(
        appId: appId,
        email: email,
        primary: primary,
        l10n: l10n,
      ),
    );
    // The route is a dialog: it has no back gesture and no Escape / barrier
    // dismissal, only the button inside closes it.
    return PopScope(
      canPop: false,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: l10n.requestSentTitle,
        child: SafeArea(
          child: Align(
            alignment: sheet ? Alignment.bottomCenter : Alignment.center,
            child: Padding(
              padding: sheet
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SingleChildScrollView(
                child: Material(type: MaterialType.transparency, child: card),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatefulWidget {
  const _SuccessCard({
    required this.appId,
    required this.email,
    required this.primary,
    required this.l10n,
  });

  final String appId;
  final String email;
  final Color primary;
  final AppLocalizations l10n;

  @override
  State<_SuccessCard> createState() => _SuccessCardState();
}

class _SuccessCardState extends State<_SuccessCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Reduced motion: show everything at once.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Fade + rise for the n-th timeline row (~100 ms apart, after the check).
  Animation<double> _row(int n) => CurvedAnimation(
    parent: _c,
    curve: Interval(0.35 + n * 0.1, 0.7 + n * 0.1, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final primary = widget.primary;
    final readablePrimary = _readableOnWhite(primary);
    final onPrimary = primary.computeLuminance() > 0.5
        ? const Color(0xFF111111)
        : Colors.white;
    final text = Theme.of(context).textTheme;

    final steps = [
      _Step(
        state: _StepState.done,
        title: l10n.stepReceived,
        subtitle: l10n.stateDone,
        primary: readablePrimary,
      ),
      _Step(
        state: _StepState.current,
        title: l10n.stepReview,
        subtitle: l10n.stateInProgress,
        primary: readablePrimary,
      ),
      _Step(
        state: _StepState.upcoming,
        title: l10n.stepContact,
        subtitle: widget.email.isEmpty ? '' : l10n.stepContactVia,
        email: widget.email,
        primary: readablePrimary,
        last: true,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _successGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) => CustomPaint(
                    painter: _CheckPainter((_c.value / 0.4).clamp(0.0, 1.0)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.requestSentTitle,
                      style: text.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _titleInk,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${l10n.requestReference}: '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: SelectableText(
                              widget.appId,
                              key: const ValueKey('request-ref'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _titleInk,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 13, color: _labelGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          l10n.requestSentBody,
          style: const TextStyle(fontSize: 15, color: _bodyGrey, height: 1.85),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            l10n.nextStepsTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _labelGrey,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // A list: every step reads as "title, state".
        Semantics(
          container: true,
          explicitChildNodes: true,
          child: Column(
            children: [
              for (var i = 0; i < steps.length; i++)
                FadeTransition(
                  opacity: _row(i),
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(_row(i)),
                    child: steps[i],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: FilledButton(
            key: const ValueKey('back-to-start'),
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(l10n.backToStart),
          ),
        ),
      ],
    );
  }
}

enum _StepState { done, current, upcoming }

class _Step extends StatelessWidget {
  const _Step({
    required this.state,
    required this.title,
    required this.subtitle,
    required this.primary,
    this.email,
    this.last = false,
  });

  final _StepState state;
  final String title;
  final String subtitle;
  final String? email;
  final Color primary;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stateLabel = switch (state) {
      _StepState.done => l10n.stateDone,
      _StepState.current => l10n.stateInProgress,
      _StepState.upcoming => l10n.stateUpcoming,
    };
    final titleColor = switch (state) {
      _StepState.done => _titleInk,
      _StepState.current => primary,
      _StepState.upcoming => _upcomingGrey,
    };
    final indicator = switch (state) {
      _StepState.done => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: _successGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      ),
      _StepState.current => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: primary, width: 3),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
        ),
      ),
      _StepState.upcoming => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _lineGrey, width: 2),
        ),
      ),
    };
    final line = state == _StepState.done ? _successGreen : _lineGrey;
    return Semantics(
      label: '$title, $stateLabel${email == null ? '' : ' $email'}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  indicator,
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 2,
                        constraints: const BoxConstraints(minHeight: 30),
                        color: line,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    if (email != null && email!.isNotEmpty)
                      Row(
                        children: [
                          Text(
                            '$subtitle ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _labelGrey,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              email!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _labelGrey,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: _labelGrey),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A check mark that draws itself as [progress] goes from 0 to 1.
class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.28, h * 0.52)
      ..lineTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.73, h * 0.36);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
