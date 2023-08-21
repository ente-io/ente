// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'fr';

  static String m0(count) =>
      "${Intl.plural(count, one: 'Ajoutez un objet', other: 'Ajoutez des objets')}";

  static String m2(albumName) => "Ajouté avec succès à  ${albumName}";

  static String m5(paymentProvider) =>
      "Veuillez d\'abord annuler votre abonnement existant de ${paymentProvider}";

  static String m6(user) =>
      "${user} ne pourra pas ajouter plus de photos à cet album\n\nIl pourrait toujours supprimer les photos existantes ajoutées par eux";

  static String m7(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Votre famille a demandé ${storageAmountInGb} GB jusqu\'à présent',
            'false':
                'Vous avez réclamé ${storageAmountInGb} GB jusqu\'à présent',
            'other':
                'Vous avez réclamé ${storageAmountInGb} GB jusqu\'à présent!',
          })}";

  static String m8(albumName) => "Lien collaboratif créé pour ${albumName}";

  static String m10(provider) =>
      "Veuillez nous contacter à support@ente.io pour gérer votre abonnement ${provider}.";

  static String m11(currentlyDeleting, totalCount) =>
      "Suppression de ${currentlyDeleting} / ${totalCount}";

  static String m12(albumName) =>
      "Cela supprimera le lien public pour accéder à \"${albumName}\".";

  static String m13(supportEmail) =>
      "Veuillez envoyer un e-mail à ${supportEmail} depuis votre adresse enregistrée";

  static String m14(count, storageSaved) =>
      "Vous avez nettoyé ${Intl.plural(count, one: '${count} fichier dupliqué', other: '${count} fichiers dupliqués')}, sauvegarde (${storageSaved}!)";

  static String m15(newEmail) => "L\'e-mail a été changé en ${newEmail}";

  static String m16(email) =>
      "${email} n\'a pas de compte ente.\n\nEnvoyez une invitation pour partager des photos.";

  static String m19(storageAmountInGB) =>
      "${storageAmountInGB} Go chaque fois que quelqu\'un s\'inscrit à une offre payante et applique votre code";

  static String m25(count) =>
      "${Intl.plural(count, one: '${count} objet', other: '${count} objets')}";

  static String m26(expiryTime) => "Le lien expirera le ${expiryTime}";

  static String m27(maxValue) =>
      "Lorsqu\'elle est définie au maximum (${maxValue}), la limite de l\'appareil sera assouplie pour permettre des pointes temporaires d\'un grand nombre de téléspectateurs.";

  static String m28(count, formattedCount) =>
      "${Intl.plural(count, one: '${formattedCount} mémoire', other: '${formattedCount} souvenirs')}";

  static String m29(count) =>
      "${Intl.plural(count, one: 'Déplacez l\'objet', other: 'Déplacez des objets')}";

  static String m30(albumName) => "Déplacé avec succès vers ${albumName}";

  static String m31(passwordStrengthValue) =>
      "Puissance du mot de passe : ${passwordStrengthValue}";

  static String m34(toEmail) => "Merci de nous envoyer un e-mail à ${toEmail}";

  static String m35(toEmail) => "Envoyez les logs à ${toEmail}";

  static String m36(storeName) => "Notez-nous sur ${storeName}";

  static String m37(storageInGB) =>
      "3. Vous recevez tous les deux ${storageInGB} GB* gratuits";

  static String m38(userEmail) =>
      "${userEmail} sera retiré de cet album partagé\n\nToutes les photos ajoutées par eux seront également retirées de l\'album";

  static String m39(endDate) => "Renouvellement le ${endDate}";

  static String m40(count) => "${count} sélectionné";

  static String m41(count, yourCount) =>
      "${count} sélectionné (${yourCount} votre)";

  static String m42(verificationID) =>
      "Voici mon ID de vérification : ${verificationID} pour ente.io.";

  static String m43(verificationID) =>
      "Hé, pouvez-vous confirmer qu\'il s\'agit de votre ID de vérification ente.io : ${verificationID}";

  static String m44(referralCode, referralStorageInGB) =>
      "code de parrainage ente : ${referralCode} \n\nAppliquez le dans Paramètres → Général → Références pour obtenir ${referralStorageInGB} Go gratuitement après votre inscription à un plan payant\n\nhttps://ente.io";

  static String m45(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Partagez avec des personnes spécifiques', one: 'Partagé avec 1 personne', other: 'Partagé avec ${numberOfPeople} des gens')}";

  static String m46(emailIDs) => "Partagé avec ${emailIDs}";

  static String m47(fileType) =>
      "Ce ${fileType} sera supprimé de votre appareil.";

  static String m48(fileType) =>
      "Ce ${fileType} est à la fois dans ente et votre appareil.";

  static String m49(fileType) => "Ce ${fileType} sera supprimé de ente.";

  static String m50(storageAmountInGB) => "${storageAmountInGB} Go";

  static String m53(endDate) => "Votre abonnement sera annulé le ${endDate}";

  static String m54(completed, total) =>
      "${completed}/${total} souvenirs préservés";

  static String m55(storageAmountInGB) =>
      "Ils obtiennent aussi ${storageAmountInGB} Go";

  static String m56(email) => "Ceci est l\'ID de vérification de ${email}";

  static String m58(email) => "Vérifier ${email}";

  static String m60(count) =>
      "${Intl.plural(count, one: '${count} il y a un an', other: '${count} il y a des années')}";

  static String m61(storageSaved) =>
      "Vous avez libéré ${storageSaved} avec succès !";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Une nouvelle version de Wire est disponible."),
        "about": MessageLookupByLibrary.simpleMessage("À propos"),
        "account": MessageLookupByLibrary.simpleMessage("Compte"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bienvenue !"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Je comprends que si je perds mon mot de passe, je risque de perdre mes données puisque mes données sont <underline>chiffrées de bout en bout</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessions actives"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Ajouter un nouvel email"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Ajouter un collaborateur"),
        "addItem": m0,
        "addMore": MessageLookupByLibrary.simpleMessage("Ajouter Plus"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Ajouter à l\'album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Ajouter à ente"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Ajouter un observateur"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Ajouté comme"),
        "addedSuccessfullyTo": m2,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Ajout aux favoris..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Avancé"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Avancé"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Après 1 jour"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Après 1 heure"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Après 1 mois"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Après 1 semaine"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Après 1 an"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Propriétaire"),
        "albumTitle": MessageLookupByLibrary.simpleMessage("Titre de l\'album"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album mis à jour"),
        "albums": MessageLookupByLibrary.simpleMessage("Albums"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Tout est effacé"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
            "Tous les souvenirs conservés"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Autoriser les personnes avec le lien à ajouter des photos à l\'album partagé."),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
            "Autoriser l\'ajout de photos"),
        "allowDownloads": MessageLookupByLibrary.simpleMessage(
            "Autoriser les téléchargements"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Autoriser les personnes à ajouter des photos"),
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Appliquer"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Utiliser le code"),
        "archive": MessageLookupByLibrary.simpleMessage("Archiver"),
        "archiving":
            MessageLookupByLibrary.simpleMessage("Archivage en cours..."),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Es-tu sûre de vouloir annuler?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Êtes-vous certains de vouloir changer d\'offre ?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Êtes-vous sûr de vouloir quitter ?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Voulez-vous vraiment vous déconnecter ?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Êtes-vous sûr de vouloir renouveler ?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Votre abonnement a été annulé. Souhaitez-vous partager la raison ?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Quelle est la principale raison pour laquelle vous supprimez votre compte ?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Demandez à vos proches de partager"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour modifier les paramètres de l\'écran de verrouillage"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour modifier votre adresse e-mail"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour modifier votre mot de passe"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Veuillez vous authentifier pour configurer l\'authentification à deux facteurs"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour débuter la suppression du compte"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour voir vos sessions actives"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour voir vos fichiers cachés"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour afficher votre clé de récupération"),
        "available": MessageLookupByLibrary.simpleMessage("Disponible"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Dossiers sauvegardés"),
        "backup": MessageLookupByLibrary.simpleMessage("Sauvegarde"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Sauvegarde sur données mobiles"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Paramètres de la sauvegarde"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Sauvegarde des vidéos"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData":
            MessageLookupByLibrary.simpleMessage("Données mises en cache"),
        "canNotUploadToAlbumsOwnedByOthers": MessageLookupByLibrary.simpleMessage(
            "Impossible de télécharger dans les albums appartenant à d\'autres personnes"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Ne peut créer de lien que pour les fichiers que vous possédez"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Vous ne pouvez supprimer que les fichiers que vous possédez"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuler"),
        "cancelOtherSubscription": m5,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Annuler l\'abonnement"),
        "cannotAddMorePhotosAfterBecomingViewer": m6,
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Modifier l\'e-mail"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Modifier le mot de passe"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Modifier le mot de passe"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Modifier les permissions ?"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Vérifier les mises à jour"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Veuillez consulter votre boîte de courriels (et les indésirables) pour compléter la vérification"),
        "checking": MessageLookupByLibrary.simpleMessage("Vérification..."),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
            "Réclamer le stockage gratuit"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Réclamez plus !"),
        "claimed": MessageLookupByLibrary.simpleMessage("Réclamée"),
        "claimedStorageSoFar": m7,
        "clearCaches":
            MessageLookupByLibrary.simpleMessage("Nettoyer le cache"),
        "close": MessageLookupByLibrary.simpleMessage("Fermer"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Durée du Club par capture"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Code appliqué"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Code copié dans le presse-papiers"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Code utilisé par vous"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Créez un lien pour permettre aux gens d\'ajouter et de voir des photos dans votre album partagé sans avoir besoin d\'une application ente ou d\'un compte. Idéal pour collecter des photos d\'événement."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Lien collaboratif"),
        "collaborativeLinkCreatedFor": m8,
        "collaborator": MessageLookupByLibrary.simpleMessage("Collaborateur"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Les collaborateurs peuvent ajouter des photos et des vidéos à l\'album partagé."),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
            "Collecter des photos de l\'événement"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Récupérer les photos"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmer"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Voulez-vous vraiment désactiver l\'authentification à deux facteurs ?"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Confirmer la suppression du compte"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Oui, je veux supprimer définitivement ce compte et toutes ses données."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirmer le mot de passe"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Confirmer le changement de l\'offre"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmer la clé de récupération"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmer la clé de récupération"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contacter l\'assistance"),
        "contactToManageSubscription": m10,
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuer"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Copier l’adresse e-mail"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copier le lien"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copiez-collez ce code\ndans votre application d\'authentification"),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
            "Impossible de libérer de l\'espace"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Créer un compte"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Appuyez longuement pour sélectionner des photos et cliquez sur + pour créer un album"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Créer un nouveau compte"),
        "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage(
            "Créer ou sélectionner un album"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Créer un lien public"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Création du lien..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Mise à jour critique disponible"),
        "currentUsageIs": MessageLookupByLibrary.simpleMessage(
            "L\'utilisation actuelle est "),
        "custom": MessageLookupByLibrary.simpleMessage("Personnaliser"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("Sombre"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Déchiffrage..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Déduplication de fichiers"),
        "delete": MessageLookupByLibrary.simpleMessage("Supprimer"),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Supprimer mon compte"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Nous sommes désolés de vous voir partir. Veuillez partager vos commentaires pour nous aider à nous améliorer."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Supprimer définitivement le compte"),
        "deleteAlbum":
            MessageLookupByLibrary.simpleMessage("Supprimer l\'album"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Supprimer aussi les photos (et vidéos) présentes dans cet album depuis <bold>tous</bold> les autres albums dont ils font partie ?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Ceci supprimera tous les albums vides. Ceci est utile lorsque vous voulez réduire l\'encombrement dans votre liste d\'albums."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Tout Supprimer"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Vous allez supprimer définitivement votre compte et toutes ses données.\nCette action est irréversible."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Veuillez envoyer un e-mail à <warning>account-deletion@ente.io</warning> à partir de votre adresse e-mail enregistrée."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Supprimer les albums vides"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage(
                "Supprimer les albums vides ?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Supprimer des deux"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Supprimer de l\'appareil"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Supprimer de ente"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Supprimer des photos"),
        "deleteProgress": m11,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Il manque une fonction clé dont j\'ai besoin"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "L\'application ou une certaine fonctionnalité ne se comporte pas comme je pense qu\'elle devrait"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "J\'ai trouvé un autre service que je préfère"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Ma raison n\'est pas listée"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Votre demande sera traitée en moins de 72 heures."),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Supprimer l\'album partagé ?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "L\'album sera supprimé pour tout le monde\n\nVous perdrez l\'accès aux photos partagées dans cet album qui est détenues par d\'autres personnes"),
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Tout déselectionner"),
        "details": MessageLookupByLibrary.simpleMessage("Détails"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Désactiver le verrouillage de l\'écran de l\'appareil lorsque ente est au premier plan et il y a une sauvegarde en cours. Ce n\'est normalement pas nécessaire, mais peut aider les gros téléchargements et les premières importations de grandes bibliothèques plus rapidement."),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Le savais-tu ?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Désactiver le verrouillage automatique"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Les téléspectateurs peuvent toujours prendre des captures d\'écran ou enregistrer une copie de vos photos en utilisant des outils externes"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Veuillez remarquer"),
        "disableLinkMessage": m12,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Désactiver la double-authentification"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Désactiver la double-authentification..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Rejeter"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Plus tard"),
        "done": MessageLookupByLibrary.simpleMessage("Terminé"),
        "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "Doubler votre espace de stockage"),
        "download": MessageLookupByLibrary.simpleMessage("Télécharger"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Échec du téléchargement"),
        "downloading":
            MessageLookupByLibrary.simpleMessage("Téléchargement en cours..."),
        "dropSupportEmail": m13,
        "duplicateFileCountWithStorageSaved": m14,
        "edit": MessageLookupByLibrary.simpleMessage("Éditer"),
        "eligible": MessageLookupByLibrary.simpleMessage("éligible"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailChangedTo": m15,
        "emailNoEnteAccount": m16,
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("Envoyez vos logs par e-mail"),
        "empty": MessageLookupByLibrary.simpleMessage("Vide"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Vider la corbeille ?"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
            "Chiffrement de la sauvegarde..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Chiffrement"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Clés de chiffrement"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "ente conserve vos souvenirs, donc ils sont toujours disponibles pour vous, même si vous perdez votre appareil."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Vous pouvez également ajouter votre famille à votre forfait."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Saisir un nom d\'album"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Entrer le code"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Entrez le code fourni par votre ami pour réclamer de l\'espace de stockage gratuit pour vous deux"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Entrer e-mail"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Entrez le nom du fichier"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Entrez un nouveau mot de passe que nous pouvons utiliser pour chiffrer vos données"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Saisissez le mot de passe"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Entrez un mot de passe que nous pouvons utiliser pour chiffrer vos données"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
            "Entrez le code de parrainage"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Entrez le code à 6 chiffres de\nvotre application d\'authentification"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Veuillez entrer une adresse email valide."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Entrez votre adresse e-mail"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Entrez votre mot de passe"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Entrez votre clé de récupération"),
        "error": MessageLookupByLibrary.simpleMessage("Erreur"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Ce lien a expiré. Veuillez sélectionner un nouveau délai d\'expiration ou désactiver l\'expiration du lien."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Exporter les logs"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exportez vos données"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
            "Impossible d\'appliquer le code"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Échec de l\'annulation"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Failed to download video"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Impossible de récupérer l\'original pour l\'édition"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Impossible de récupérer les détails du parrainage. Veuillez réessayer plus tard."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Impossible de charger les albums"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Échec du renouvellement"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Forfaits famille"),
        "faq": MessageLookupByLibrary.simpleMessage("FAQ"),
        "faqs": MessageLookupByLibrary.simpleMessage("FAQ"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favori"),
        "feedback": MessageLookupByLibrary.simpleMessage("Commentaires"),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Fichier enregistré dans la galerie"),
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Fichiers supprimés"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Mot de passe oublié"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Stockage gratuit réclamé"),
        "freeStorageOnReferralSuccess": m19,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Stockage gratuit utilisable"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Essai gratuit"),
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Libérer de l\'espace sur l\'appareil"),
        "general": MessageLookupByLibrary.simpleMessage("Général"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Génération des clés de chiffrement..."),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("Identifiant Google Play"),
        "hidden": MessageLookupByLibrary.simpleMessage("Masqué"),
        "hide": MessageLookupByLibrary.simpleMessage("Masquer"),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("Comment ça fonctionne"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Demandez-leur d\'appuyer longuement sur leur adresse e-mail sur l\'écran des paramètres et de vérifier que les identifiants des deux appareils correspondent."),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Certains fichiers de cet album sont ignorés parce qu\'ils avaient été précédemment supprimés de ente."),
        "importing":
            MessageLookupByLibrary.simpleMessage("Importation en cours..."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Mot de passe incorrect"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "La clé de récupération que vous avez entrée est incorrecte"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Clé de récupération non valide"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Appareil non sécurisé"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Installation manuelle"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Adresse e-mail invalide"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Clé invalide"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "La clé de récupération que vous avez saisie n\'est pas valide. Veuillez vous assurer qu\'elle "),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Inviter à ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invite tes ami(e)s"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Invite your friends to ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Il semble qu\'une erreur s\'est produite. Veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter notre équipe d\'assistance."),
        "itemCount": m25,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Les éléments montrent le nombre de jours restants avant la suppression définitive"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Les éléments sélectionnés seront supprimés de cet album"),
        "keepPhotos":
            MessageLookupByLibrary.simpleMessage("Conserver les photos"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Veuillez nous aider avec cette information"),
        "language": MessageLookupByLibrary.simpleMessage("Langue"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Dernière mise à jour"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Quitter l\'album"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Quitter l\'album partagé?"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Clair"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Lien copié dans le presse-papiers"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limite d\'appareil"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Activé"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expiré"),
        "linkExpiresOn": m26,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Expiration du lien"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Le lien a expiré"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Jamais"),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Chargement de la galerie..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Chargement de vos photos..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galerie locale"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Verrouiller"),
        "lockScreenEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Pour activer l\'écran de verrouillage, veuillez configurer le code d\'accès de l\'appareil ou le verrouillage de l\'écran dans les paramètres de votre système."),
        "lockscreen":
            MessageLookupByLibrary.simpleMessage("Ecran de vérouillage"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Se connecter"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Deconnexion..."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "En cliquant sur connecter, j\'accepte les <u-terms>conditions d\'utilisation</u-terms> et la <u-policy>politique de confidentialité</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Déconnexion"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Cela enverra des logs pour nous aider à déboguer votre problème. Veuillez noter que les noms de fichiers seront inclus pour aider à suivre les problèmes avec des fichiers spécifiques."),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Appareil perdu ?"),
        "manage": MessageLookupByLibrary.simpleMessage("Gérer"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Gérer le stockage de l\'appareil"),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Gérer la famille"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Gérer le lien"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Gérer"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Gérer l\'abonnement"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "maxDeviceLimitSpikeHandling": m27,
        "memoryCount": m28,
        "merchandise": MessageLookupByLibrary.simpleMessage("Marchandise"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Modéré"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensuel"),
        "moveItem": m29,
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Déplacer vers l\'album"),
        "movedSuccessfullyTo": m30,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Déplacé dans la corbeille"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Déplacement des fichiers vers l\'album..."),
        "name": MessageLookupByLibrary.simpleMessage("Nom"),
        "never": MessageLookupByLibrary.simpleMessage("Jamais"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nouvel album"),
        "newest": MessageLookupByLibrary.simpleMessage("Le plus récent"),
        "no": MessageLookupByLibrary.simpleMessage("Non"),
        "noAlbumsSharedByYouYet":
            MessageLookupByLibrary.simpleMessage("No albums shared by you yet"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Vous n\'avez pas de fichiers sur cet appareil qui peuvent être supprimés"),
        "noDuplicates": MessageLookupByLibrary.simpleMessage("✨ Aucun doublon"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Aucune clé de récupération?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "En raison de notre protocole de chiffrement de bout en bout, vos données ne peuvent pas être déchiffré sans votre mot de passe ou clé de récupération"),
        "noResults": MessageLookupByLibrary.simpleMessage("Aucun résultat"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("Nothing shared with you yet"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "oops": MessageLookupByLibrary.simpleMessage("Oups"),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
            "Oups, une erreur est arrivée"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Optionnel, aussi court que vous le souhaitez..."),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
            "Sélectionner un fichier existant"),
        "password": MessageLookupByLibrary.simpleMessage("Mot de passe"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Le mot de passe a été modifié"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Mot de passe verrou"),
        "passwordStrength": m31,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Nous ne stockons pas ce mot de passe, donc si vous l\'oubliez, <underline>nous ne pouvons pas déchiffrer vos données</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Détails de paiement"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Synchronisation en attente"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Personnes utilisant votre code"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Tous les éléments de la corbeille seront définitivement supprimés\n\nCette action ne peut pas être annulée"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Supprimer définitivement"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Supprimer définitivement de l\'appareil ?"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Taille de la grille photo"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("photo"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Les photos ajoutées par vous seront retirées de l\'album"),
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement au PlayStore"),
        "pleaseEmailUsAt": m34,
        "pleaseSendTheLogsTo": m35,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Veuillez réessayer"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Veuillez patienter..."),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Veuillez attendre quelque temps avant de réessayer"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Préparation des journaux..."),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Appuyez et maintenez enfoncé pour lire la vidéo"),
        "privacy": MessageLookupByLibrary.simpleMessage("Confidentialité"),
        "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
            "Politique de Confidentialité"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Lien public créé"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Lien public activé"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Évaluez-nous"),
        "rateUsOnStore": m36,
        "recover": MessageLookupByLibrary.simpleMessage("Restaurer"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Récupérer un compte"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Récupérer"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Clé de récupération"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Clé de récupération copiée dans le presse-papiers"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Si vous oubliez votre mot de passe, la seule façon de récupérer vos données sera grâce à cette clé."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Nous ne stockons pas cette clé, veuillez enregistrer cette clé de 24 mots dans un endroit sûr."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Génial ! Votre clé de récupération est valide. Merci de votre vérification.\n\nN\'oubliez pas de garder votre clé de récupération sauvegardée."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Clé de récupération vérifiée"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Votre clé de récupération est la seule façon de récupérer vos photos si vous oubliez votre mot de passe. Vous pouvez trouver votre clé de récupération dans Paramètres > Compte.\n\nVeuillez entrer votre clé de récupération ici pour vous assurer que vous l\'avez enregistrée correctement."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Récupération réussie !"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "L\'appareil actuel n\'est pas assez puissant pour vérifier votre mot de passe, mais nous pouvons régénérer d\'une manière qui fonctionne avec tous les appareils.\n\nVeuillez vous connecter à l\'aide de votre clé de récupération et régénérer votre mot de passe (vous pouvez réutiliser le même si vous le souhaitez)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Recréer le mot de passe"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Parrainez des amis et 2x votre abonnement"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Donnez ce code à vos amis"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Ils s\'inscrivent à une offre payante"),
        "referralStep3": m37,
        "referrals": MessageLookupByLibrary.simpleMessage("Parrainages"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Les recommandations sont actuellement en pause"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Également vide \"récemment supprimé\" de \"Paramètres\" -> \"Stockage\" pour réclamer l\'espace libéré"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Vide aussi votre \"Corbeille\" pour réclamer l\'espace libéré"),
        "remoteImages":
            MessageLookupByLibrary.simpleMessage("Images distantes"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Miniatures distantes"),
        "remoteVideos":
            MessageLookupByLibrary.simpleMessage("Vidéos distantes"),
        "remove": MessageLookupByLibrary.simpleMessage("Enlever"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Supprimer les doublons"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Retirer de l\'album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Retirer de l\'album ?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Retirer des favoris"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Supprimer le lien"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Supprimer le participant"),
        "removeParticipantBody": m38,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Supprimer le lien public"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Certains des objets que vous êtes en train de retirer ont été ajoutés par d\'autres personnes, vous perdrez l\'accès vers ces objets"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Enlever?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Suppression des favoris…"),
        "rename": MessageLookupByLibrary.simpleMessage("Renommer"),
        "renameAlbum":
            MessageLookupByLibrary.simpleMessage("Renommer l\'album"),
        "renameFile":
            MessageLookupByLibrary.simpleMessage("Renommer le fichier"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Renouveler l’abonnement"),
        "renewsOn": m39,
        "reportABug": MessageLookupByLibrary.simpleMessage("Signaler un bug"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Signaler un bug"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Renvoyer le courriel"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Réinitialiser les fichiers ignorés"),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
            "Réinitialiser le mot de passe"),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurer"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Restaurer vers l\'album"),
        "restoringFiles": MessageLookupByLibrary.simpleMessage(
            "Restauration des fichiers..."),
        "retry": MessageLookupByLibrary.simpleMessage("Réessayer"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Veuillez vérifier et supprimer les éléments que vous croyez dupliqués."),
        "saveKey": MessageLookupByLibrary.simpleMessage("Enregistrer la clé"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Enregistrez votre clé de récupération si vous ne l\'avez pas déjà fait"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scanner le code"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scannez ce code-barres avec\nvotre application d\'authentification"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Nom de l\'album"),
        "security": MessageLookupByLibrary.simpleMessage("Sécurité"),
        "selectAlbum":
            MessageLookupByLibrary.simpleMessage("Sélectionner album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Tout sélectionner"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Sélectionner les dossiers à sauvegarder"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Sélectionner une raison"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Sélectionner votre offre"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Les fichiers sélectionnés ne sont pas sur ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Les dossiers sélectionnés seront cryptés et sauvegardés"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Les éléments sélectionnés seront supprimés de tous les albums et déplacés dans la corbeille."),
        "selectedPhotos": m40,
        "selectedPhotosWithYours": m41,
        "send": MessageLookupByLibrary.simpleMessage("Envoyer"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Envoyer un e-mail"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Envoyer Invitations"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Envoyer le lien"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expirée"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Définir un mot de passe"),
        "setAs": MessageLookupByLibrary.simpleMessage("Définir comme"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Définir le mot de passe"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configuration fini"),
        "share": MessageLookupByLibrary.simpleMessage("Partager"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Partager le lien"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Ouvrez un album et appuyez sur le bouton de partage en haut à droite pour le partager."),
        "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage(
            "Partagez un album maintenant"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Partager le lien"),
        "shareMyVerificationID": m42,
        "shareTextConfirmOthersVerificationID": m43,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Téléchargez ente pour que nous puissions facilement partager des photos et des vidéos de qualité originale\n\nhttps://ente.io"),
        "shareTextReferralCode": m44,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Partager avec des utilisateurs non-ente"),
        "shareWithPeopleSectionTitle": m45,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Share your first album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Créez des albums partagés et collaboratifs avec d\'autres utilisateurs de ente, y compris des utilisateurs sur des plans gratuits."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Partagé par moi"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Shared by you"),
        "sharedWith": m46,
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Shared with you"),
        "sharing": MessageLookupByLibrary.simpleMessage("Partage..."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "J\'accepte les <u-terms>conditions d\'utilisation</u-terms> et la <u-policy>politique de confidentialité</u-policy>"),
        "singleFileDeleteFromDevice": m47,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Il sera supprimé de tous les albums."),
        "singleFileInBothLocalAndRemote": m48,
        "singleFileInRemoteOnly": m49,
        "skip": MessageLookupByLibrary.simpleMessage("Ignorer"),
        "social": MessageLookupByLibrary.simpleMessage("Réseaux Sociaux"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Certains éléments sont à la fois dans ente et votre appareil."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Certains des fichiers que vous essayez de supprimer ne sont disponibles que sur votre appareil et ne peuvent pas être récupérés s\'ils sont supprimés"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Quelqu\'un qui partage des albums avec vous devrait voir le même ID sur son appareil."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Un problème est survenu"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Quelque chose s\'est mal passé, veuillez recommencer"),
        "sorry": MessageLookupByLibrary.simpleMessage("Désolé"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Désolé, impossible d\'ajouter aux favoris !"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Désolé, impossible de supprimer des favoris !"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Désolé, nous n\'avons pas pu générer de clés sécurisées sur cet appareil.\n\nVeuillez vous inscrire depuis un autre appareil."),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Succès"),
        "storageInGB": m50,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Fort"),
        "subWillBeCancelledOn": m53,
        "subscribe": MessageLookupByLibrary.simpleMessage("S\'abonner"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Il semble que votre abonnement ait expiré. Veuillez vous abonner pour activer le partage."),
        "subscription": MessageLookupByLibrary.simpleMessage("Abonnement"),
        "success": MessageLookupByLibrary.simpleMessage("Succès"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Archivé avec succès"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Désarchivé avec succès"),
        "suggestFeatures": MessageLookupByLibrary.simpleMessage(
            "Suggérer des fonctionnalités"),
        "support": MessageLookupByLibrary.simpleMessage("Support"),
        "syncProgress": m54,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Synchronisation arrêtée ?"),
        "syncing": MessageLookupByLibrary.simpleMessage(
            "En cours de synchronisation..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Système"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("taper pour copier"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Appuyez pour entrer un code"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Il semble qu\'une erreur s\'est produite. Veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter notre équipe d\'assistance."),
        "terminate": MessageLookupByLibrary.simpleMessage("Quitte"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Quitter la session ?"),
        "terms": MessageLookupByLibrary.simpleMessage("Conditions"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Conditions d\'utilisation"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Merci"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("Merci de vous être abonné !"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Le téléchargement n\'a pas pu être terminé"),
        "theme": MessageLookupByLibrary.simpleMessage("Thème"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Ces éléments seront supprimés de votre appareil."),
        "theyAlsoGetXGb": m55,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Ils seront supprimés de tous les albums."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Cette action ne peut pas être annulée"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Cet album a déjà un lien collaboratif"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Cela peut être utilisé pour récupérer votre compte si vous perdez votre deuxième facteur"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Cet appareil"),
        "thisIsPersonVerificationId": m56,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Ceci est votre ID de vérification"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Cela vous déconnectera de l\'appareil suivant :"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Cela vous déconnectera de cet appareil !"),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Journaux du jour"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Taille totale"),
        "trash": MessageLookupByLibrary.simpleMessage("Corbeille"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Réessayer"),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 mois gratuits sur les forfaits annuels"),
        "twofactor":
            MessageLookupByLibrary.simpleMessage("Double authentification"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Authentification à deux facteurs"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Configuration de l\'authentification à deux facteurs"),
        "unarchive": MessageLookupByLibrary.simpleMessage("Désarchiver"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Désarchivage en cours..."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Aucune catégorie"),
        "unhide": MessageLookupByLibrary.simpleMessage("Dévoiler"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Afficher dans l\'album"),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Démasquage des fichiers vers l\'album"),
        "unselectAll":
            MessageLookupByLibrary.simpleMessage("Désélectionner tout"),
        "update": MessageLookupByLibrary.simpleMessage("Mise à jour"),
        "updateAvailable": MessageLookupByLibrary.simpleMessage(
            "Une mise à jour est disponible"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Mise à jour de la sélection du dossier..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Améliorer"),
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Envoi des fichiers vers l\'album..."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Le stockage utilisable est limité par votre offre actuelle. Le stockage excédentaire deviendra automatiquement utilisable lorsque vous mettez à niveau votre offre."),
        "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Utiliser des liens publics pour les personnes qui ne sont pas sur ente"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Utiliser la clé de récupération"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de vérification"),
        "verify": MessageLookupByLibrary.simpleMessage("Vérifier"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Vérifier l\'email"),
        "verifyEmailID": m58,
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Vérifier le mot de passe"),
        "verifying":
            MessageLookupByLibrary.simpleMessage("Validation en cours..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Vérification de la clé de récupération..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vidéo"),
        "viewActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Afficher les sessions actives"),
        "viewLogs":
            MessageLookupByLibrary.simpleMessage("Afficher les journaux"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Voir la clé de récupération"),
        "viewer": MessageLookupByLibrary.simpleMessage("Observateur"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Nous sommes open source !"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Nous ne prenons pas en charge l\'édition des photos et des albums que vous ne possédez pas encore"),
        "weakStrength": MessageLookupByLibrary.simpleMessage("Faible"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Bienvenue !"),
        "yearly": MessageLookupByLibrary.simpleMessage("Annuel"),
        "yearsAgo": m60,
        "yes": MessageLookupByLibrary.simpleMessage("Oui"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Oui, annuler"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Oui, convertir en observateur"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Oui, supprimer"),
        "yesLogout":
            MessageLookupByLibrary.simpleMessage("Oui, se déconnecter"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Oui, supprimer"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Oui, renouveler"),
        "you": MessageLookupByLibrary.simpleMessage("Vous"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Vous êtes sur la dernière version"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Vous pouvez au maximum doubler votre espace de stockage"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Vous pouvez gérer vos liens dans l\'onglet Partage."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Vous ne pouvez pas rétrograder vers cette offre"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Vous ne pouvez pas partager avec vous-même"),
        "youHaveSuccessfullyFreedUp": m61,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Votre compte a été supprimé"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Votre plan a été rétrogradé avec succès"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Votre offre a été mise à jour avec succès"),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
            "Votre achat a été effectué avec succès"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Vos informations de stockage n\'ont pas pu être récupérées"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Votre abonnement a été mis à jour avec succès"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Vous n\'avez aucun fichier dédupliqué pouvant être nettoyé"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Vous n\'avez pas de fichiers dans cet album qui peuvent être supprimés")
      };
}
