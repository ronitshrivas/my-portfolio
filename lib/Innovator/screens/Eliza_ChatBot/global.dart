import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<void> _saveCodeToAppData(String code) async {
  try {
    // Get the application doc
    //uments directory (AppData equivalent for the app)
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/eliza_chat_screen.dart');
    await file.writeAsString(code);
    print('File saved to: ${file.path}');
  } catch (e) {
    print('Error saving file: $e');
  }
}

  //const String apiKey = 'AIzaSyAAsNe3vn85mCgYz3la055Jm5QfhFV2x8k';
