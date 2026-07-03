/// Build-time environment configuration.
///
/// Pass with: flutter run --dart-define=APP_ENV=prod
/// Defaults to dev so local runs never touch production services.
enum AppEnv { dev, prod }

abstract final class AppConfig {
  static const AppEnv env = String.fromEnvironment('APP_ENV') == 'prod'
      ? AppEnv.prod
      : AppEnv.dev;

  static bool get isDev => env == AppEnv.dev;
  static bool get isProd => env == AppEnv.prod;

  static String get appName => isProd ? 'HomeVault' : 'HomeVault Dev';
}
