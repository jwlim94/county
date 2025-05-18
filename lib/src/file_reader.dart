import 'package:flutter/services.dart';

class FileReader {
  static Future<String> readStringFromFile(String path) async {
    return await rootBundle.loadString(path);
  }
}
