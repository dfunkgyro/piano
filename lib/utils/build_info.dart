class BuildInfo {
  static const String buildVersion =
      String.fromEnvironment('BUILD_VERSION', defaultValue: 'dev');
  static const String buildDate =
      String.fromEnvironment('BUILD_DATE', defaultValue: '');

  static String get display {
    if (buildDate.isEmpty) {
      return buildVersion;
    }
    return '$buildVersion ($buildDate)';
  }
}
