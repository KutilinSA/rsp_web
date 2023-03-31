import 'dart:async';
import 'dart:io';

abstract class Paths {
  static const pubspecFileName = 'pubspec.yaml';
  static const toolsProjectDirectory = 'tools';
  static const secretsJsonFileRelativePath = 'secrets.json';
  static const secretsDartFileRelativePath = 'lib/secrets.dart';

  const Paths._();

  static bool fileExists(String path) => File(path).existsSync();
  static bool directoryExists(String path) => Directory(path).existsSync();

  static Future<String?> replaceFilesContent(File fromFile, File toFile) async {
    try {
      final fromFileContent = await fromFile.readAsString();
      await toFile.writeAsString(fromFileContent);
      return null;
    } on Exception catch (_) {
      return 'Error while replacing content from ${fromFile.path} to ${toFile.path}';
    }
  }

  static Future<String?> replaceLinesInFile(
    File file,
    bool Function(String line) linesFilter, {
    String? replaceWith,
  }) async {
    try {
      final fileLines = await file.readAsLines();
      final replacedLines = <String?>[];
      for (final line in fileLines) {
        replacedLines.add(line);
        if (linesFilter(line) && replaceWith != line) {
          replacedLines[replacedLines.length - 1] = replaceWith;
        }
      }
      replacedLines.retainWhere((element) => element != null);
      await file.writeAsString(replacedLines.join('\n'));
      return null;
    } on Exception catch (_) {
      return 'Error while replacing content in ${file.path}';
    }
  }
}