import 'api_constants.dart';

class AppStrings {
  AppStrings._();

  static const String appName = 'AlterVPN';
  static const String tagline = 'Minimal. Secure. Free.';

  // Splash
  static const String splashTitle = 'ALTER';
  static const String splashSubtitle = 'VPN';

  // Onboarding
  static const String onboarding1Title = 'Privacy is not optional.';
  static const String onboarding1Subtitle =
      'Your connection, encrypted end-to-end.';
  static const String onboarding2Title = 'One tap.\nFully encrypted.';
  static const String onboarding2Subtitle =
      'Connect to any server in seconds.';
  static const String onboarding3Title = 'Free.\nOpen.\nYours.';
  static const String onboarding3Subtitle =
      'No subscriptions. No data collection.';
  static const String getStarted = 'Get Started';
  static const String next = 'Next';

  // Home
  static const String tapToConnect = 'Tap to connect';
  static const String connecting = 'Connecting...';
  static const String connected = 'Connected';
  static const String disconnecting = 'Disconnecting...';
  static const String disconnected = 'Disconnected';
  static const String selectServer = 'Select server';
  static const String downloadLabel = '↓';
  static const String uploadLabel = '↑';

  // Servers
  static const String serversTitle = 'Servers';
  static const String searchPlaceholder = 'Search countries...';
  static const String noServers = 'No servers available';
  static const String loadingServers = 'Loading servers...';
  static const String sessions = 'sessions';
  static const String ping = 'ping';
  static const String speed = 'speed';
  static const String refreshServers = 'Refresh';
  static const String free = 'Free';

  // Settings
  static const String settingsTitle = 'Settings';
  static const String connectionSection = 'Connection';
  static const String killSwitch = 'Kill Switch';
  static const String killSwitchSubtitle = 'Block traffic if VPN drops';
  static const String autoConnect = 'Auto Connect';
  static const String autoConnectSubtitle = 'Connect on app launch';
  static const String installVpnProfile = 'Install VPN Profile';
  static const String installVpnProfileSubtitle =
      'Request VPN permission / reinstall profile';
  static const String installVpnProfileSuccess =
      'VPN profile check complete. You can now connect.';
  static const String installVpnProfileError =
      'Could not install VPN profile. Please try again.';
  static const String appearanceSection = 'Appearance';
  static const String darkMode = 'Dark Mode';
  static const String darkModeSubtitle = 'Use dark theme';
  static const String aboutSection = 'About';
  static const String version = 'Version';
  static const String privacyPolicy = 'Privacy Policy';
  static const String licenses = 'Open Source Licenses';
  /// Public privacy page (served with the Railway web build). Same host as [ApiConstants.backendBaseUrl].
  static String get privacyPolicyUrl =>
      '${ApiConstants.backendBaseUrl}/privacy.html';
  static const String madeWith = 'Made with ♡';

  // Errors
  static const String errorTitle = 'Something went wrong';
  static const String errorRetry = 'Retry';
  static const String permissionDenied =
      'VPN permission denied. Go to Settings → Install VPN Profile and accept the prompt.';
  static const String connectionFailed = 'Connection failed';
  static const String invalidProfile =
      'Invalid server profile. Please select a different server.';
  static const String authFailure =
      'Authentication failed. Please check your credentials and try again.';
  static const String transportTimeout =
      'Network unreachable. Please check your internet connection and try again.';
  static const String serverUnavailable =
      'Server unavailable. Please try again later.';
  static const String noHealthyServers =
      'No available servers right now. Please try again later.';
  static const String connectInProgress =
      'A connection attempt is already in progress. Please wait.';
}
