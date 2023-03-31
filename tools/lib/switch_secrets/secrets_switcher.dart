import 'dart:convert';
import 'dart:io';

import 'package:tools/switch_secrets/environment.dart';
import 'package:tools/utils/utils.dart';

abstract class SecretsSwitcher {
  static const _ignoreConstantIdentifierNamesHeader = '// ignore_for_file: constant_identifier_names';
  static const _ignorePreferSingleQuotesHeader = '// ignore_for_file: prefer_single_quotes';

  const SecretsSwitcher._();

  static Future<String?> switchTo(String environment) async {
    final convertedEnvironment = EnvironmentConverter.fromString(environment);
    if (convertedEnvironment == null) {
      return 'Undefined environment "$environment", available environment: "test", "dev"';
    }

    final projectDirectory = await Git.getProjectDirectory();
    if (projectDirectory == null) {
      return "Can't detect git root directory, seems like script is moved outside repository";
    }
    final secretsJsonFile = File('$projectDirectory/${Paths.toolsProjectDirectory}/${Paths.secretsJsonFileRelativePath}');
    final secretsDartFile = File('$projectDirectory/${Paths.secretsDartFileRelativePath}');
    if (Paths.fileExists(secretsJsonFile.path)) {
      try {
        final secretsFileContent = await secretsJsonFile.readAsString();
        final secrets = jsonDecode(secretsFileContent) as Map<String, dynamic>;
        if (!secrets.containsKey(convertedEnvironment.asString)) {
          return 'Secrets for ${convertedEnvironment.asString} environment are not set in ${secretsJsonFile.path}';
        }

        final environmentSecrets = secrets[convertedEnvironment.asString] as Map<String, dynamic>;
        final contents = <String>[
          _ignoreConstantIdentifierNamesHeader,
          _ignorePreferSingleQuotesHeader,
          '\n',
          for (final secret in environmentSecrets.entries)
            _jsonToDartSecret(secret),
        ];
        await secretsDartFile.writeAsString(contents.join('\n'));
        return null;
      } on Exception catch (_) {
        return 'Error while reading secrets from ${secretsJsonFile.path}';
      }
    } else {
      return "Can't find secrets file, ensure ${secretsJsonFile.path} exits";
    }
  }

  static String _jsonToDartSecret(MapEntry<String, dynamic> secret) {
    var secretValue = secret.value as Object?;
    var secretType = secretValue.runtimeType.toString();

    if (secretValue is String) {
      secretValue = jsonEncode(secretValue);
    } else if (secretValue is Map<String, dynamic>) {
      final type = '${secretValue['_type'] ?? 'dynamic'}';
      secretType = 'Map<String, $type>';
      secretValue = '<String, $type>${jsonEncode(secretValue..remove('_type'))}';
    }

    return 'const $secretType ${secret.key} = $secretValue;';
  }
}