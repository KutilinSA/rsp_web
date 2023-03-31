import 'dart:io';

import 'package:git/git.dart';
import 'package:path/path.dart' as path;

abstract class Git {
  const Git._();

  static Future<String?> getProjectDirectory() async {
    final scriptPath = path.dirname(Platform.script.toFilePath());

    if (await GitDir.isGitDir(scriptPath)) {
      final projectDirectory = await GitDir.fromExisting(scriptPath, allowSubdirectory: true);
      return projectDirectory.path;
    } else {
      return null;
    }
  }
}