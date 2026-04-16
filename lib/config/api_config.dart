class ApiConfig {
  ApiConfig._();

  // JioSaavn self-hosted API URL
  // Deploy: https://github.com/sumitkolhe/jiosaavn-api → Vercel/Railway
  // Then add JIOSAAVN_BASE_URL as a Secret in GitHub and in run.bat locally
  static const String jiosaavnBaseUrl = String.fromEnvironment(
    'JIOSAAVN_BASE_URL',
    defaultValue: '',
  );

  static bool get enableJioSaavn => jiosaavnBaseUrl.isNotEmpty;

  // LRCLIB — free lyrics API, no key needed
  static const String lrclibBase = 'https://lrclib.net';
}
