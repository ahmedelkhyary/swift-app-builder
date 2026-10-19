/// Non-web fallback (used by VM tests).
void downloadTextFile(String filename, String content) {
  throw UnsupportedError('Downloads are only supported on web');
}
