import 'dart:typed_data';

class SpreadsheetPickedFile {
  final String name;
  final Uint8List bytes;

  const SpreadsheetPickedFile({
    required this.name,
    required this.bytes,
  });
}
