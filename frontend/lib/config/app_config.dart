class AppConfig {
  static const String baseUrl =
      'https://enriqueta-overpositive-leandra.ngrok-free.dev';

  static const String registerUrl = '$baseUrl/register';
  static const String loginUrl = '$baseUrl/login';
  static const String chatUrl = '$baseUrl/chat';
  static const String conversationsUrl = '$baseUrl/conversations';
  static const String accountUrl = '$baseUrl/account';
  static const String accountUsernameUrl = '$baseUrl/account/username';
  static const String accountPasswordUrl = '$baseUrl/account/password';

  static String messagesUrl(int convId) =>
      '$baseUrl/conversations/$convId/messages';
  static String deleteConvUrl(int convId) => '$baseUrl/conversations/$convId';
  static String renameConvUrl(int convId) =>
      '$baseUrl/conversations/$convId/title';
}
