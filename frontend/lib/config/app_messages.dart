class AppMessages {
  AppMessages._();

  // ── Réseau ──
  static const String networkError =
      "Impossible de joindre le serveur. Vérifie ta connexion et réessaie.";
  static const String timeoutError =
      "Le serveur met trop de temps à répondre. Réessaie dans un instant.";
  static const String serverError =
      "Une erreur est survenue côté serveur. Réessaie dans quelques secondes.";
  static const String connectionClosed =
      "La connexion a été interrompue. Réessaie dans un instant.";

  // ── Auth ──
  static const String loginInvalidCredentials =
      "Email ou mot de passe incorrect. Vérifie tes informations.";
  static const String loginEmailRequired = "L'adresse email est requise.";
  static const String loginEmailInvalid =
      "Cette adresse email n'est pas valide.";
  static const String loginPasswordRequired = "Le mot de passe est requis.";
  static const String loginPasswordTooShort =
      "Le mot de passe doit contenir au moins 6 caractères.";
  static const String loginServerError =
      "Impossible de se connecter pour l'instant. Réessaie dans quelques instants.";
  static const String loginGoogleFailed =
      "La connexion avec Google n'a pas abouti. Réessaie.";
  static const String sessionExpired =
      "Ta session a expiré. Reconnecte-toi pour continuer.";

  // ── Inscription ──
  static const String registerNameRequired = "Le nom d'utilisateur est requis.";
  static const String registerEmailTaken =
      "Cette adresse email est déjà utilisée. Essaie de te connecter.";
  static const String registerPasswordMismatch =
      "Les deux mots de passe ne correspondent pas.";
  static const String registerSuccess =
      "Compte créé avec succès ! Tu peux maintenant te connecter.";
  static const String registerServerError =
      "Impossible de créer le compte pour l'instant. Réessaie dans quelques instants.";

  // ── Chat ──
  static const String chatStreamError =
      "Une erreur est survenue pendant la réponse. Réessaie ta question.";
  static const String chatConnectionError =
      "La connexion a été perdue. Vérifie ta connexion et réessaie.";
  static const String chatSystemStarting =
      "Le système démarre, patiente un instant puis réessaie.";

  // ── Compte ──
  static const String accountLoadError =
      "Impossible de charger ton profil. Réessaie dans un instant.";
  static const String accountNameUpdated = "Nom mis à jour avec succès.";
  static const String accountNameError =
      "Impossible de mettre à jour le nom. Réessaie.";
  static const String accountPasswordUpdated =
      "Mot de passe mis à jour avec succès.";
  static const String accountPasswordWrong =
      "Le mot de passe actuel est incorrect.";
  static const String accountPasswordSame =
      "Le nouveau mot de passe doit être différent de l'ancien.";
  static const String accountPasswordTooShort =
      "Le nouveau mot de passe doit contenir au moins 6 caractères.";
  static const String accountDeleteSuccess = "Ton compte a bien été supprimé.";
  static const String accountDeleteWrongPassword =
      "Mot de passe incorrect. Le compte n'a pas été supprimé.";
  static const String accountDeleteError =
      "Impossible de supprimer le compte pour l'instant. Réessaie.";

  // ── Conversations ──
  static const String conversationsLoadError =
      "Impossible de charger les conversations. Réessaie dans un instant.";
  static const String conversationDeleteError =
      "Impossible de supprimer cette conversation. Réessaie.";
  static const String conversationRenameError =
      "Impossible de renommer cette conversation. Réessaie.";
  static const String conversationsDeleteAllSuccess =
      "Toutes les conversations ont été supprimées.";
  static const String conversationsDeleteAllError =
      "Impossible de supprimer les conversations. Réessaie.";

  static String fromException(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('connection closed') || msg.contains('connection reset')) {
      return connectionClosed;
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return timeoutError;
    }
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('host')) {
      return networkError;
    }
    return networkError;
  }
}
