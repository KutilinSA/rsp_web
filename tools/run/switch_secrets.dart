import 'dart:io';

import 'package:tools/switch_secrets/secrets_switcher.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln('Usage: "dart run switch_secrets.dart <test/dev>"');
    exit(-1);
  }

  final environment = arguments.first;
  final result = await SecretsSwitcher.switchTo(environment);
  if (result != null) {
    stderr.writeln(result);
    exit(-1);
  }

  stdout.writeln('Secrets successfully switched to $environment!');
}
