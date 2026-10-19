/// The EyeDropper API only exists in some browsers.
bool get eyeDropperSupported => false;

/// Opens the screen color picker; returns `#RRGGBB` or null when cancelled.
Future<String?> pickColorFromScreen() async => null;
