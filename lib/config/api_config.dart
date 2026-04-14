class ApiConfig {
  ApiConfig._();

  // JioSaavn self-hosted API URL (deploy on Cloudflare — see Phase 4)
  // Leave empty string until you deploy it — app won't crash, just skips JioSaavn
  static const String jiosaavnBaseUrl = String.fromEnvironment(
    'JIOSAAVN_BASE_URL',
    defaultValue: '',
  );

  static final bool enableJioSaavn = jiosaavnBaseUrl.isNotEmpty;

  // LRCLIB — free lyrics API, no key needed
  static const String lrclibBase = 'https://lrclib.net';
}