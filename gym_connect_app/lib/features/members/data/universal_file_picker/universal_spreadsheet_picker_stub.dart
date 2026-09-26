import 'package:file_picker/file_picker.dart';
import 'spreadsheet_picked_file.dart';

Future<SpreadsheetPickedFile?> pickSpreadsheetPlatformFile() async {
  try {
    final result = await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result.isEmpty) return null;
    final file = result.first;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    return SpreadsheetPickedFile(
      name: file.name,
      bytes: bytes,
    );
  } catch (_) {
    return null;
  }
}
