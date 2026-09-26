import 'spreadsheet_picked_file.dart';
import 'universal_spreadsheet_picker_stub.dart'
    if (dart.library.html) 'universal_spreadsheet_picker_web.dart';

export 'spreadsheet_picked_file.dart';

Future<SpreadsheetPickedFile?> pickSpreadsheetFile() => pickSpreadsheetPlatformFile();
