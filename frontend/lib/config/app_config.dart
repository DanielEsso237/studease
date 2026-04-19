class AppConfig {
  static const String baseUrl =
      'https://enriqueta-overpositive-leandra.ngrok-free.dev';

  static const String registerUrl = '$baseUrl/auth/register';
  static const String loginUrl = '$baseUrl/auth/login';
  static const String googleAuthUrl = '$baseUrl/auth/google';
  static const String chatUrl = '$baseUrl/chat';
  static const String conversationsUrl = '$baseUrl/conversations';
  static const String conversationsAllUrl = '$baseUrl/conversations/delete-all';
  static const String accountUrl = '$baseUrl/account';
  static const String accountUsernameUrl = '$baseUrl/account/username';
  static const String accountPasswordUrl = '$baseUrl/account/password';
  static const String statusUrl = '$baseUrl/status';

  static String messagesUrl(int convId) =>
      '$baseUrl/conversations/$convId/messages';
  static String deleteConvUrl(int convId) => '$baseUrl/conversations/$convId';
  static String renameConvUrl(int convId) =>
      '$baseUrl/conversations/$convId/title';
}
