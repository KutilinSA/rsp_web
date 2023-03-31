enum Environment {
  test,
  dev,
}

extension EnvironmentConverter on Environment {
  String get asString {
    switch (this) {
      case Environment.test:
        return 'test';
      case Environment.dev:
        return 'dev';
    }
  }

  static Environment? fromString(String target) {
    switch (target.toLowerCase()) {
      case 'test':
        return Environment.test;
      case 'dev':
        return Environment.dev;
      default:
        return null;
    }
  }
}