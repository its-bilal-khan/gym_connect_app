// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void webStorageWrite(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

String? webStorageRead(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void webStorageDelete(String key) {
  try {
    html.window.localStorage.remove(key);
  } catch (_) {}
}

void webStorageClear() {
  try {
    final keysToRemove = html.window.localStorage.keys
        .where((k) => k.startsWith('gymconnect_'))
        .toList();
    for (final k in keysToRemove) {
      html.window.localStorage.remove(k);
    }
  } catch (_) {}
}
