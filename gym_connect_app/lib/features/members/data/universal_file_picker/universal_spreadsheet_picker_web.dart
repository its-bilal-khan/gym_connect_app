// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'spreadsheet_picked_file.dart';

Future<SpreadsheetPickedFile?> pickSpreadsheetPlatformFile() async {
  try {
    final uploadInput = html.FileUploadInputElement()
      ..accept = '.xlsx,.xls,.csv';

    uploadInput.click();

    await uploadInput.onChange.first;

    if (uploadInput.files == null || uploadInput.files!.isEmpty) {
      return null;
    }

    final file = uploadInput.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;

    final dynamic res = reader.result;
    if (res == null) return null;

    Uint8List bytes;
    if (res is Uint8List) {
      bytes = res;
    } else if (res is ByteBuffer) {
      bytes = res.asUint8List();
    } else if (res is List<int>) {
      bytes = Uint8List.fromList(res);
    } else {
      bytes = Uint8List(0);
    }

    return SpreadsheetPickedFile(
      name: file.name,
      bytes: bytes,
    );
  } catch (e) {
    return null;
  }
}
