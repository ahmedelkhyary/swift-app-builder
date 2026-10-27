import 'dart:convert';

import 'package:web/web.dart' as web;

/// Triggers a browser download of [content] as [filename].
void downloadTextFile(String filename, String content) {
  final uri = Uri.dataFromString(
    content,
    mimeType: 'application/json',
    encoding: utf8,
  );
  final anchor = web.HTMLAnchorElement()
    ..href = uri.toString()
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
