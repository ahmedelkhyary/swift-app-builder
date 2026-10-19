import 'package:flutter/material.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import 'phone_frame.dart';

/// The interactive prototype inside a device frame.
class PhonePreview extends StatelessWidget {
  const PhonePreview({
    super.key,
    required this.session,
    required this.template,
    required this.branding,
    required this.languageCode,
    this.dark = false,
    this.device = PhoneDevice.iphone,
    this.scale = 1,
  });

  final DemoSession session;
  final AppTemplate template;
  final BrandingConfig branding;
  final String languageCode;
  final bool dark;
  final PhoneDevice device;
  final double scale;

  @override
  Widget build(BuildContext context) {
    const size = Size(
      PhoneFrame.screenLogicalWidth,
      PhoneFrame.screenLogicalHeight,
    );
    return PhoneFrame(
      device: device,
      scale: scale,
      darkScreen: dark,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: size,
          viewInsets: EdgeInsets.zero,
          textScaler: TextScaler.noScaling,
        ),
        child: RecruitmentApp(
          session: session,
          template: template,
          branding: branding,
          languageCode: languageCode,
          brightness: dark ? Brightness.dark : Brightness.light,
          // The panel header states that this is a demo; no in-screen banner.
          showDemoBanner: false,
          topInset: PhoneFrame.topInsetFor(device),
        ),
      ),
    );
  }
}

/// Small, non-interactive rendering of a template's Home screen. It owns a
/// throwaway session, so it never touches the customer's preview progress.
class TemplateThumbnail extends StatefulWidget {
  const TemplateThumbnail({
    super.key,
    required this.template,
    required this.branding,
    required this.languageCode,
    required this.modules,
    this.aspectRatio = 1.15,
  });

  final AppTemplate template;
  final BrandingConfig branding;
  final String languageCode;
  final Set<ServiceModule> modules;

  /// Visible width / height; the top of the Home screen is shown.
  final double aspectRatio;

  @override
  State<TemplateThumbnail> createState() => _TemplateThumbnailState();
}

class _TemplateThumbnailState extends State<TemplateThumbnail> {
  static const _logicalWidth = 390.0;
  static const _logicalFullHeight = 844.0;

  late final DemoSession _session = DemoSession(
    repository: MockDemoRepository(latency: Duration.zero),
    enabledModules: widget.modules,
  )..signInDemo();

  @override
  void didUpdateWidget(TemplateThumbnail old) {
    super.didUpdateWidget(old);
    _session.setEnabledModules(widget.modules);
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRect(
        child: IgnorePointer(
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: _logicalWidth,
              height: _logicalWidth / widget.aspectRatio,
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: _logicalFullHeight,
                minHeight: _logicalFullHeight,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: const Size(_logicalWidth, _logicalFullHeight),
                    textScaler: TextScaler.noScaling,
                  ),
                  child: RecruitmentApp(
                    session: _session,
                    template: widget.template,
                    branding: widget.branding,
                    languageCode: widget.languageCode,
                    showDemoBanner: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
