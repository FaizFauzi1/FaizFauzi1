class AppConfig {
  // Change this to your live domain (Vercel, Netlify, or Custom)
  static const String webDomain = 'eventease-lake.vercel.app';
  static const String vercelDomain = 'eventease-lake.vercel.app';
  
  // Custom scheme for mobile apps
  static const String appScheme = 'eventease';
  
  static String get inviteLinkBase => 'https://$webDomain/rsvp/';
  static String get appInviteLinkBase => '$appScheme://rsvp/';

  // Helper to get the active primary domain
  static List<String> get supportedDomains => [
    webDomain,
    vercelDomain,
    'localhost',
  ];

  // PostHog Analytics Config
  static String get posthogApiKey => const String.fromEnvironment('POSTHOG_API_KEY', defaultValue: 'phc_xSZZAW5mMhMFbmHzL7UHCMWULW69CnudHUVF2xrWMpg6');
  static String get posthogHost => const String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://us.i.posthog.com');
}
