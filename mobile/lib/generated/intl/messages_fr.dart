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
      "${Intl.plural(count, zero: 'Add collaborator', one: 'Add collaborator', other: 'Add collaborators')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Ajoutez un objet', other: 'Ajoutez des objets')}";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Add viewer', one: 'Add viewer', other: 'Add viewers')}";

  static String m4(emailOrName) => "Ajouté par ${emailOrName}";

  static String m5(albumName) => "Ajouté avec succès à  ${albumName}";

  static String m6(count) =>
      "${Intl.plural(count, zero: 'Aucun Participant', one: '1 Participant', other: '${count} Participants')}";

  static String m7(versionValue) => "Version : ${versionValue}";

  static String m8(paymentProvider) =>
      "Veuillez d\'abord annuler votre abonnement existant de ${paymentProvider}";

  static String m9(user) =>
      "${user} ne pourra pas ajouter plus de photos à cet album\n\nIl pourrait toujours supprimer les photos existantes ajoutées par eux";

  static String m10(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Votre famille a demandé ${storageAmountInGb} GB jusqu\'à présent',
            'false':
                'Vous avez réclamé ${storageAmountInGb} GB jusqu\'à présent',
            'other':
                'Vous avez réclamé ${storageAmountInGb} GB jusqu\'à présent!',
          })}";

  static String m11(albumName) => "Lien collaboratif créé pour ${albumName}";

  static String m12(familyAdminEmail) =>
      "Veuillez contacter <green>${familyAdminEmail}</green> pour gérer votre abonnement";

  static String m13(provider) =>
      "Veuillez nous contacter à support@ente.io pour gérer votre abonnement ${provider}.";

  static String m14(count) =>
      "${Intl.plural(count, one: 'Supprimer le fichier', other: 'Supprimer ${count} fichiers')}";

  static String m15(currentlyDeleting, totalCount) =>
      "Suppression de ${currentlyDeleting} / ${totalCount}";

  static String m16(albumName) =>
      "Cela supprimera le lien public pour accéder à \"${albumName}\".";

  static String m17(supportEmail) =>
      "Veuillez envoyer un e-mail à ${supportEmail} depuis votre adresse enregistrée";

  static String m18(count, storageSaved) =>
      "Vous avez nettoyé ${Intl.plural(count, one: '${count} fichier dupliqué', other: '${count} fichiers dupliqués')}, sauvegarde (${storageSaved}!)";

  static String m19(count, formattedSize) =>
      "${count} fichiers, ${formattedSize} chacun";

  static String m20(newEmail) => "L\'e-mail a été changé en ${newEmail}";

  static String m21(email) =>
      "${email} n\'a pas de compte ente.\n\nEnvoyez une invitation pour partager des photos.";

  static String m22(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 fichier sur cet appareil a été sauvegardé en toute sécurité', other: '${formattedNumber} fichiers sur cet appareil ont été sauvegardés en toute sécurité')}";

  static String m23(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 fichier dans cet album a été sauvegardé en toute sécurité', other: '${formattedNumber} fichiers dans cet album ont été sauvegardés en toute sécurité')}";

  static String m24(storageAmountInGB) =>
      "${storageAmountInGB} Go chaque fois que quelqu\'un s\'inscrit à une offre payante et applique votre code";

  static String m25(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} libre";

  static String m26(endDate) => "Essai gratuit valide jusqu’au ${endDate}";

  static String m27(count) =>
      "Vous pouvez toujours ${Intl.plural(count, one: 'y', other: 'y')} accéder sur ente tant que vous avez un abonnement actif";

  static String m28(sizeInMBorGB) => "Libérer ${sizeInMBorGB}";

  static String m29(count, formattedSize) =>
      "${Intl.plural(count, one: 'Peut être supprimé de l\'appareil pour libérer ${formattedSize}', other: 'Peuvent être supprimés de l\'appareil pour libérer ${formattedSize}')}";

  static String m31(count) =>
      "${Intl.plural(count, one: '${count} objet', other: '${count} objets')}";

  static String m32(expiryTime) => "Le lien expirera le ${expiryTime}";

  static String m33(count, formattedCount) =>
      "${Intl.plural(count, one: '${formattedCount} mémoire', other: '${formattedCount} souvenirs')}";

  static String m34(count) =>
      "${Intl.plural(count, one: 'Déplacez l\'objet', other: 'Déplacez des objets')}";

  static String m35(albumName) => "Déplacé avec succès vers ${albumName}";

  static String m36(passwordStrengthValue) =>
      "Sécurité du mot de passe : ${passwordStrengthValue}";

  static String m37(providerName) =>
      "Veuillez contacter le support ${providerName} si vous avez été facturé";

  static String m38(endDate) =>
      "Essai gratuit valable jusqu\'à ${endDate}.\nVous pouvez choisir un plan payant par la suite.";

  static String m39(toEmail) => "Merci de nous envoyer un e-mail à ${toEmail}";

  static String m40(toEmail) => "Envoyez les logs à ${toEmail}";

  static String m41(storeName) => "Notez-nous sur ${storeName}";

  static String m42(storageInGB) =>
      "3. Vous recevez tous les deux ${storageInGB} GB* gratuits";

  static String m43(userEmail) =>
      "${userEmail} sera retiré de cet album partagé\n\nToutes les photos ajoutées par eux seront également retirées de l\'album";

  static String m44(endDate) => "Renouvellement le ${endDate}";

  static String m45(count) =>
      "${Intl.plural(count, one: '${count} résultat trouvé', other: '${count} résultats trouvés')}";

  static String m46(count) => "${count} sélectionné(s)";

  static String m47(count, yourCount) =>
      "${count} sélectionné(s) (${yourCount} à vous)";

  static String m48(verificationID) =>
      "Voici mon ID de vérification : ${verificationID} pour ente.io.";

  static String m49(verificationID) =>
      "Hé, pouvez-vous confirmer qu\'il s\'agit de votre ID de vérification ente.io : ${verificationID}";

  static String m50(referralCode, referralStorageInGB) =>
      "code de parrainage ente : ${referralCode} \n\nAppliquez le dans Paramètres → Général → Références pour obtenir ${referralStorageInGB} Go gratuitement après votre inscription à un plan payant\n\nhttps://ente.io";

  static String m51(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Partagez avec des personnes spécifiques', one: 'Partagé avec 1 personne', other: 'Partagé avec ${numberOfPeople} des gens')}";

  static String m52(emailIDs) => "Partagé avec ${emailIDs}";

  static String m53(fileType) =>
      "Elle ${fileType} sera supprimée de votre appareil.";

  static String m54(fileType) =>
      "Cette ${fileType} est à la fois sur ente et sur votre appareil.";

  static String m55(fileType) => "Ce ${fileType} sera supprimé de ente.";

  static String m56(storageAmountInGB) => "${storageAmountInGB} Go";

  static String m57(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} sur ${totalAmount} ${totalStorageUnit} utilisé";

  static String m58(id) =>
      "Votre ${id} est déjà lié à un autre compte ente.\nSi vous souhaitez utiliser votre ${id} avec ce compte, veuillez contacter notre support";

  static String m59(endDate) => "Votre abonnement sera annulé le ${endDate}";

  static String m60(completed, total) =>
      "${completed}/${total} souvenirs préservés";

  static String m61(storageAmountInGB) =>
      "Ils obtiennent aussi ${storageAmountInGB} Go";

  static String m62(email) => "Ceci est l\'ID de vérification de ${email}";

  static String m63(count) =>
      "${Intl.plural(count, zero: '0 jour', one: '1 jour', other: '${count} jours')}";

  static String m64(endDate) => "Valable jusqu\'au ${endDate}";

  static String m65(email) => "Vérifier ${email}";

  static String m66(email) =>
      "Nous avons envoyé un e-mail à <green>${email}</green>";

  static String m67(count) =>
      "${Intl.plural(count, one: 'il y a ${count} an', other: 'il y a ${count} ans')}";

  static String m68(storageSaved) =>
      "Vous avez libéré ${storageSaved} avec succès !";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Une nouvelle version de ente est disponible."),
        "about": MessageLookupByLibrary.simpleMessage("À propos"),
        "account": MessageLookupByLibrary.simpleMessage("Compte"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bienvenue !"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Je comprends que si je perds mon mot de passe, je perdrai mes données puisque mes données sont <underline>chiffrées de bout en bout</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessions actives"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Ajouter un nouvel email"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Ajouter un collaborateur"),
        "addCollaborators": m0,
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Ajouter depuis l\'appareil"),
        "addItem": m2,
        "addLocation":
            MessageLookupByLibrary.simpleMessage("Ajouter la localisation"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Ajouter"),
        "addMore": MessageLookupByLibrary.simpleMessage("Ajouter Plus"),
        "addNew": MessageLookupByLibrary.simpleMessage("Ajouter un nouveau"),
        "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
            "Détails des modules complémentaires"),
        "addOns":
            MessageLookupByLibrary.simpleMessage("Modules complémentaires"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Ajouter des photos"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Ajouter la sélection"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Ajouter à l\'album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Ajouter à ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Ajouter à un album masqué"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Ajouter un observateur"),
        "addViewers": m1,
        "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
            "Ajoutez vos photos maintenant"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Ajouté comme"),
        "addedBy": m4,
        "addedSuccessfullyTo": m5,
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
        "albumParticipantsCount": m6,
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
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Vérifier l’identité"),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
            "Reconnaissance impossible. Réessayez."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Empreinte digitale requise"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Succès"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Annuler"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Identifiants requis"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage("Identifiants requis"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "L\'authentification biométrique n\'est pas configurée sur votre appareil. Allez dans \'Paramètres > Sécurité\' pour ajouter l\'authentification biométrique."),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
            "Android, iOS, Web, Ordinateur"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Authentification requise"),
        "appVersion": m7,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Appliquer"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Utiliser le code"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement à l\'AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("Archiver"),
        "archiveAlbum":
            MessageLookupByLibrary.simpleMessage("Archiver l\'album"),
        "archiving":
            MessageLookupByLibrary.simpleMessage("Archivage en cours..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Êtes-vous certains de vouloir quitter le plan familial?"),
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
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("dans un abri antiatomique"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Veuillez vous authentifier pour modifier votre adresse e-mail"),
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
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour voir vos souvenirs"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour afficher votre clé de récupération"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Authentification..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "L\'authentification a échouée, veuillez réessayer"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("Authentification réussie!"),
        "available": MessageLookupByLibrary.simpleMessage("Disponible"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Dossiers sauvegardés"),
        "backup": MessageLookupByLibrary.simpleMessage("Sauvegarde"),
        "backupFailed":
            MessageLookupByLibrary.simpleMessage("Échec de la sauvegarde"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Sauvegarde sur données mobiles"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Paramètres de la sauvegarde"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Sauvegarde des vidéos"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Offre Black Friday"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData":
            MessageLookupByLibrary.simpleMessage("Données mises en cache"),
        "calculating":
            MessageLookupByLibrary.simpleMessage("Calcul en cours..."),
        "canNotUploadToAlbumsOwnedByOthers": MessageLookupByLibrary.simpleMessage(
            "Impossible de télécharger dans les albums appartenant à d\'autres personnes"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Ne peut créer de lien que pour les fichiers que vous possédez"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Vous ne pouvez supprimer que les fichiers que vous possédez"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuler"),
        "cancelOtherSubscription": m8,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Annuler l\'abonnement"),
        "cannotAddMorePhotosAfterBecomingViewer": m9,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Les fichiers partagés ne peuvent pas être supprimés"),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Point central"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Modifier l\'e-mail"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Change location of selected items?"),
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
        "claimedStorageSoFar": m10,
        "clearCaches":
            MessageLookupByLibrary.simpleMessage("Nettoyer le cache"),
        "click": MessageLookupByLibrary.simpleMessage("• Click"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Cliquez sur le menu de débordement"),
        "close": MessageLookupByLibrary.simpleMessage("Fermer"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Grouper par durée"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Grouper par nom de fichier"),
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
        "collaborativeLinkCreatedFor": m11,
        "collaborator": MessageLookupByLibrary.simpleMessage("Collaborateur"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Les collaborateurs peuvent ajouter des photos et des vidéos à l\'album partagé."),
        "collageLayout": MessageLookupByLibrary.simpleMessage("Disposition"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
            "Collage sauvegardé dans la galerie"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
            "Collecter des photos de l\'événement"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Récupérer les photos"),
        "color": MessageLookupByLibrary.simpleMessage("Couleur "),
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
        "contactFamilyAdmin": m12,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contacter l\'assistance"),
        "contactToManageSubscription": m13,
        "contacts": MessageLookupByLibrary.simpleMessage("Contacts"),
        "contents": MessageLookupByLibrary.simpleMessage("Contenus"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuer"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Poursuivre avec la version d\'essai gratuite"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Convertir en album"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Copier l’adresse e-mail"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copier le lien"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copiez-collez ce code\ndans votre application d\'authentification"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Nous n\'avons pas pu sauvegarder vos données.\nNous allons réessayer plus tard."),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
            "Impossible de libérer de l\'espace"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Impossible de mettre à jour l’abonnement"),
        "count": MessageLookupByLibrary.simpleMessage("Total"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Rapports d\'erreurs"),
        "create": MessageLookupByLibrary.simpleMessage("Créer"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Créer un compte"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Appuyez longuement pour sélectionner des photos et cliquez sur + pour créer un album"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Create collaborative link"),
        "createCollage":
            MessageLookupByLibrary.simpleMessage("Créez un collage"),
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
        "dayToday": MessageLookupByLibrary.simpleMessage("Aujourd\'hui"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Hier"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("Déchiffrement en cours..."),
        "decryptingVideo": MessageLookupByLibrary.simpleMessage(
            "Déchiffrement de la vidéo..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Déduplication de fichiers"),
        "delete": MessageLookupByLibrary.simpleMessage("Supprimer"),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Supprimer le compte"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Nous sommes désolés de vous voir partir. S\'il vous plaît partagez vos commentaires pour nous aider à améliorer le service."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Supprimer définitivement le compte"),
        "deleteAlbum":
            MessageLookupByLibrary.simpleMessage("Supprimer l\'album"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Supprimer aussi les photos (et vidéos) présentes dans cet album de <bold>tous</bold> les autres albums dont elles font partie ?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Ceci supprimera tous les albums vides. Ceci est utile lorsque vous voulez réduire l\'encombrement dans votre liste d\'albums."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Tout Supprimer"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Ce compte est lié à d\'autres applications ente, si vous en utilisez une.\\n\\nVos données téléchargées, dans toutes les applications ente, seront planifiées pour suppression, et votre compte sera définitivement supprimé."),
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
        "deleteItemCount": m14,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Supprimer la localisation"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Supprimer des photos"),
        "deleteProgress": m15,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Il manque une fonction clé dont j\'ai besoin"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "L\'application ou une fonctionnalité particulière ne se comporte pas comme je pense qu\'elle devrait"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "J\'ai trouvé un autre service que je préfère"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Ma raison n\'est pas listée"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Votre demande sera traitée sous 72 heures."),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Supprimer l\'album partagé ?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "L\'album sera supprimé pour tout le monde\n\nVous perdrez l\'accès aux photos partagées dans cet album qui sont détenues par d\'autres personnes"),
        "descriptions": MessageLookupByLibrary.simpleMessage("Descriptions"),
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Tout déselectionner"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Conçu pour survivre"),
        "details": MessageLookupByLibrary.simpleMessage("Détails"),
        "devAccountChanged": MessageLookupByLibrary.simpleMessage(
            "Le compte développeur que nous utilisons pour publier ente sur l\'App Store a changé. Pour cette raison, vous devrez vous connecter à nouveau.\n\nNous nous excusons pour la gêne occasionnée, mais cela était inévitable."),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Les fichiers ajoutés à cet album seront automatiquement téléchargés sur ente."),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Désactiver le verrouillage de l\'écran de l\'appareil lorsque ente est au premier plan et il y a une sauvegarde en cours. Ce n\'est normalement pas nécessaire, mais peut aider les gros téléchargements et les premières importations de grandes bibliothèques plus rapidement."),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Le savais-tu ?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Désactiver le verrouillage automatique"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Les téléspectateurs peuvent toujours prendre des captures d\'écran ou enregistrer une copie de vos photos en utilisant des outils externes"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Veuillez remarquer"),
        "disableLinkMessage": m16,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Désactiver la double-authentification"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Désactiver la double-authentification..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Rejeter"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Plus tard"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Voulez-vous annuler les modifications que vous avez faites ?"),
        "done": MessageLookupByLibrary.simpleMessage("Terminé"),
        "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "Doubler votre espace de stockage"),
        "download": MessageLookupByLibrary.simpleMessage("Télécharger"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Échec du téléchargement"),
        "downloading":
            MessageLookupByLibrary.simpleMessage("Téléchargement en cours..."),
        "dropSupportEmail": m17,
        "duplicateFileCountWithStorageSaved": m18,
        "duplicateItemsGroup": m19,
        "edit": MessageLookupByLibrary.simpleMessage("Éditer"),
        "editLocation": MessageLookupByLibrary.simpleMessage("Edit location"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Modifier l’emplacement"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Modification sauvegardée"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Edits to location will only be seen within Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("éligible"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailChangedTo": m20,
        "emailNoEnteAccount": m21,
        "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
            "Vérification de l\'adresse e-mail"),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("Envoyez vos logs par e-mail"),
        "empty": MessageLookupByLibrary.simpleMessage("Vide"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Vider la corbeille ?"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Activer la carte"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Vos photos seront affichées sur une carte du monde.\n\nCette carte est hébergée par Open Street Map, et les emplacements exacts de vos photos ne sont jamais partagés.\n\nVous pouvez désactiver cette fonction à tout moment dans les Paramètres."),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
            "Chiffrement de la sauvegarde..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Chiffrement"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Clés de chiffrement"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Chiffrement de bout en bout par défaut"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "ente peut chiffrer et conserver des fichiers que si vous leur accordez l\'accès"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "ente <i>a besoin d\'une autorisation pour</i> préserver vos photos"),
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
        "everywhere": MessageLookupByLibrary.simpleMessage("partout"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Utilisateur existant"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Ce lien a expiré. Veuillez sélectionner un nouveau délai d\'expiration ou désactiver l\'expiration du lien."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Exporter les logs"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exportez vos données"),
        "faces": MessageLookupByLibrary.simpleMessage("Visages"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
            "Impossible d\'appliquer le code"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Échec de l\'annulation"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
            "Échec du téléchargement de la vidéo"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Impossible de récupérer l\'original pour l\'édition"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Impossible de récupérer les détails du parrainage. Veuillez réessayer plus tard."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Impossible de charger les albums"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Échec du renouvellement"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Échec de la vérification du statut du paiement"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Ajoutez 5 membres de votre famille à votre abonnement existant sans payer de supplément.\n\nChaque membre dispose de son propre espace privé et ne peut pas voir les fichiers des autres membres, sauf s\'ils sont partagés.\n\nLes abonnement familiaux sont disponibles pour les clients qui ont un abonnement ente payant.\n\nAbonnez-vous maintenant pour commencer !"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Famille"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Forfaits famille"),
        "faq": MessageLookupByLibrary.simpleMessage("FAQ"),
        "faqs": MessageLookupByLibrary.simpleMessage("FAQ"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favori"),
        "feedback": MessageLookupByLibrary.simpleMessage("Commentaires"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Échec de l\'enregistrement dans la galerie"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Ajouter une description..."),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Fichier enregistré dans la galerie"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Types de fichiers"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Types et noms de fichiers"),
        "filesBackedUpFromDevice": m22,
        "filesBackedUpInAlbum": m23,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Fichiers supprimés"),
        "flip": MessageLookupByLibrary.simpleMessage("Retourner"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("pour vos souvenirs"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Mot de passe oublié"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Stockage gratuit réclamé"),
        "freeStorageOnReferralSuccess": m24,
        "freeStorageSpace": m25,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Stockage gratuit utilisable"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Essai gratuit"),
        "freeTrialValidTill": m26,
        "freeUpAccessPostDelete": m27,
        "freeUpAmount": m28,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Libérer de l\'espace sur l\'appareil"),
        "freeUpSpace":
            MessageLookupByLibrary.simpleMessage("Libérer de l\'espace"),
        "freeUpSpaceSaving": m29,
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Jusqu\'à 1000 souvenirs affichés dans la galerie"),
        "general": MessageLookupByLibrary.simpleMessage("Général"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Génération des clés de chiffrement..."),
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Allez aux réglages"),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("Identifiant Google Play"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Veuillez autoriser l’accès à toutes les photos dans les paramètres"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Accorder la permission"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
            "Grouper les photos à proximité"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Nous ne suivons pas les installations d\'applications. Il serait utile que vous nous disiez comment vous nous avez trouvés !"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Comment avez-vous entendu parler de Ente? (facultatif)"),
        "hidden": MessageLookupByLibrary.simpleMessage("Masqué"),
        "hide": MessageLookupByLibrary.simpleMessage("Masquer"),
        "hiding": MessageLookupByLibrary.simpleMessage("Masquage en cours..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Hébergé chez OSM France"),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("Comment ça fonctionne"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Demandez-leur d\'appuyer longuement sur leur adresse e-mail sur l\'écran des paramètres et de vérifier que les identifiants des deux appareils correspondent."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "L\'authentification biométrique n\'est pas configurée sur votre appareil. Veuillez activer Touch ID ou Face ID sur votre téléphone."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "L\'authentification biométrique est désactivée. Veuillez verrouiller et déverrouiller votre écran pour l\'activer."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("Ok"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorer"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Certains fichiers de cet album sont ignorés parce qu\'ils avaient été précédemment supprimés de ente."),
        "importing":
            MessageLookupByLibrary.simpleMessage("Importation en cours..."),
        "incorrectCode":
            MessageLookupByLibrary.simpleMessage("Code non valide"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Mot de passe incorrect"),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Clé de récupération non valide"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "La clé de secours que vous avez entrée est incorrecte"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Clé de secours non valide"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Appareil non sécurisé"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Installation manuelle"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Adresse e-mail invalide"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Clé invalide"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "La clé de récupération que vous avez saisie n\'est pas valide. Veuillez vous assurer qu\'elle "),
        "invite": MessageLookupByLibrary.simpleMessage("Inviter"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Inviter à ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invite tes ami(e)s"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Invitez vos amis sur ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Il semble qu\'une erreur s\'est produite. Veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter notre équipe d\'assistance."),
        "itemCount": m31,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Les éléments montrent le nombre de jours restants avant la suppression définitive"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Les éléments sélectionnés seront supprimés de cet album"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("Join Discord"),
        "keepPhotos":
            MessageLookupByLibrary.simpleMessage("Conserver les photos"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Merci de nous aider avec cette information"),
        "language": MessageLookupByLibrary.simpleMessage("Langue"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Dernière mise à jour"),
        "leave": MessageLookupByLibrary.simpleMessage("Quitter"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Quitter l\'album"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Quitter le plan familial"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Quitter l\'album partagé?"),
        "light": MessageLookupByLibrary.simpleMessage("Clair"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Clair"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Lien copié dans le presse-papiers"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limite d\'appareil"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Activé"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expiré"),
        "linkExpiresOn": m32,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Expiration du lien"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Le lien a expiré"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Jamais"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("Photos en direct"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Vous pouvez partager votre abonnement avec votre famille"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Nous avons conservé plus de 30 millions de souvenirs jusqu\'à présent"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Nous conservons 3 copies de vos données, l\'une dans un abri anti-atomique"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Toutes nos applications sont open source"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Notre code source et notre cryptographie ont été audités en externe"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Vous pouvez partager des liens vers vos albums avec vos proches"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Nos applications mobiles s\'exécutent en arrière-plan pour chiffrer et sauvegarder automatiquement les nouvelles photos que vous prenez"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io dispose d\'un outil de téléchargement facile à utiliser"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Nous utilisons Xchacha20Poly1305 pour chiffrer vos données en toute sécurité"),
        "loadingExifData": MessageLookupByLibrary.simpleMessage(
            "Chargement des données EXIF..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Chargement de la galerie..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Chargement de vos photos..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galerie locale"),
        "location": MessageLookupByLibrary.simpleMessage("Emplacement"),
        "locationName": MessageLookupByLibrary.simpleMessage("Nom du lieu"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Un tag d\'emplacement regroupe toutes les photos qui ont été prises dans un certain rayon d\'une photo"),
        "locations": MessageLookupByLibrary.simpleMessage("Locations"),
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
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Long press an email to verify end to end encryption."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Appuyez longuement sur un élément pour le voir en plein écran"),
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
        "map": MessageLookupByLibrary.simpleMessage("Carte"),
        "maps": MessageLookupByLibrary.simpleMessage("Cartes"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m33,
        "merchandise": MessageLookupByLibrary.simpleMessage("Marchandise"),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobile, Web, Ordinateur"),
        "moderateStrength":
            MessageLookupByLibrary.simpleMessage("Sécurité moyenne"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Modifiez votre requête, ou essayez de rechercher"),
        "moments": MessageLookupByLibrary.simpleMessage("Souvenirs"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensuel"),
        "moveItem": m34,
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Déplacer vers l\'album"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Déplacer vers un album masqué"),
        "movedSuccessfullyTo": m35,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Déplacé dans la corbeille"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Déplacement des fichiers vers l\'album..."),
        "name": MessageLookupByLibrary.simpleMessage("Nom"),
        "never": MessageLookupByLibrary.simpleMessage("Jamais"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nouvel album"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Nouveau sur ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Le plus récent"),
        "no": MessageLookupByLibrary.simpleMessage("Non"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Aucun album que vous avez partagé"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Aucune"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Vous n\'avez pas de fichiers sur cet appareil qui peuvent être supprimés"),
        "noDuplicates": MessageLookupByLibrary.simpleMessage("✨ Aucun doublon"),
        "noExifData":
            MessageLookupByLibrary.simpleMessage("Aucune donnée EXIF"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Aucune photo ou vidéo cachée"),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
            "Aucune image avec localisation"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Aucune photo en cours de sauvegarde"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("Aucune photo trouvée"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Aucune clé de récupération?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "En raison de notre protocole de chiffrement de bout en bout, vos données ne peuvent pas être déchiffré sans votre mot de passe ou clé de récupération"),
        "noResults": MessageLookupByLibrary.simpleMessage("Aucun résultat"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Aucun résultat trouvé"),
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Rien n\'a encore été partagé avec vous"),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
            "Il n\'y a encore rien à voir ici 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Sur l\'appareil"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Sur <branding>ente</branding>"),
        "oops": MessageLookupByLibrary.simpleMessage("Oups"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Oups, impossible d\'enregistrer les modifications"),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
            "Oups, une erreur est arrivée"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Ouvrir les paramètres"),
        "openTheItem":
            MessageLookupByLibrary.simpleMessage("• Ouvrir l\'élément"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
            "Contributeurs d\'OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Optionnel, aussi court que vous le souhaitez..."),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
            "Sélectionner un fichier existant"),
        "password": MessageLookupByLibrary.simpleMessage("Mot de passe"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Le mot de passe a été modifié"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Mot de passe verrou"),
        "passwordStrength": m36,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Nous ne stockons pas ce mot de passe, donc si vous l\'oubliez, <underline>nous ne pouvons pas déchiffrer vos données</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Détails de paiement"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Échec du paiement"),
        "paymentFailedTalkToProvider": m37,
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
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Descriptions de la photo"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Taille de la grille photo"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("photo"),
        "photos": MessageLookupByLibrary.simpleMessage("Photos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Les photos ajoutées par vous seront retirées de l\'album"),
        "pickCenterPoint": MessageLookupByLibrary.simpleMessage(
            "Sélectionner le point central"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Épingler l\'album"),
        "playStoreFreeTrialValidTill": m38,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement au PlayStore"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Veuillez contacter support@ente.io et nous serons heureux de vous aider!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Merci de contacter l\'assistance si cette erreur persiste"),
        "pleaseEmailUsAt": m39,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
            "Veuillez accorder la permission"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Veuillez vous reconnecter"),
        "pleaseSendTheLogsTo": m40,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Veuillez réessayer"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Veuillez vérifier le code que vous avez entré"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Veuillez patienter..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Veuillez patienter, suppression de l\'album"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Veuillez attendre quelque temps avant de réessayer"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Préparation des journaux..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Conserver plus"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Appuyez et maintenez enfoncé pour lire la vidéo"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Maintenez appuyé sur l\'image pour lire la vidéo"),
        "privacy": MessageLookupByLibrary.simpleMessage("Confidentialité"),
        "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
            "Politique de Confidentialité"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Sauvegardes privées"),
        "privateSharing": MessageLookupByLibrary.simpleMessage("Partage privé"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Lien public créé"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Lien public activé"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Liens rapides"),
        "radius": MessageLookupByLibrary.simpleMessage("Rayon"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Créer un ticket"),
        "rateTheApp":
            MessageLookupByLibrary.simpleMessage("Évaluer l\'application"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Évaluez-nous"),
        "rateUsOnStore": m41,
        "recover": MessageLookupByLibrary.simpleMessage("Récupérer"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Récupérer un compte"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Restaurer"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage("Clé de secours"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Clé de secours copiée dans le presse-papiers"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Si vous oubliez votre mot de passe, la seule façon de récupérer vos données sera grâce à cette clé."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Nous ne stockons pas cette clé, veuillez garder cette clé de 24 mots dans un endroit sûr."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Génial ! Votre clé de récupération est valide. Merci de votre vérification.\n\nN\'oubliez pas de garder votre clé de récupération sauvegardée."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Clé de récupération vérifiée"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Votre clé de récupération est la seule façon de récupérer vos photos si vous oubliez votre mot de passe. Vous pouvez trouver votre clé de récupération dans Paramètres > Compte.\n\nVeuillez entrer votre clé de récupération ici pour vous assurer que vous l\'avez enregistrée correctement."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Restauration réussie !"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "L\'appareil actuel n\'est pas assez puissant pour vérifier votre mot de passe, mais nous pouvons le régénérer d\'une manière qui fonctionne avec tous les appareils.\n\nVeuillez vous connecter à l\'aide de votre clé de secours et régénérer votre mot de passe (vous pouvez réutiliser le même si vous le souhaitez)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Recréer le mot de passe"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Parrainez des amis et 2x votre abonnement"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Donnez ce code à vos amis"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Ils s\'inscrivent à une offre payante"),
        "referralStep3": m42,
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
        "removeParticipantBody": m43,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Supprimer le lien public"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Certains des éléments que vous êtes en train de retirer ont été ajoutés par d\'autres personnes, vous perdrez l\'accès vers ces éléments"),
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
        "renewsOn": m44,
        "reportABug": MessageLookupByLibrary.simpleMessage("Signaler un bug"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Signaler un bug"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Renvoyer l\'e-mail"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Réinitialiser les fichiers ignorés"),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
            "Réinitialiser le mot de passe"),
        "resetToDefault": MessageLookupByLibrary.simpleMessage(
            "Réinitialiser aux valeurs par défaut"),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurer"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Restaurer vers l\'album"),
        "restoringFiles": MessageLookupByLibrary.simpleMessage(
            "Restauration des fichiers..."),
        "retry": MessageLookupByLibrary.simpleMessage("Réessayer"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Veuillez vérifier et supprimer les éléments que vous croyez dupliqués."),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Pivoter à gauche"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Faire pivoter à droite"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Stockage sécurisé"),
        "save": MessageLookupByLibrary.simpleMessage("Sauvegarder"),
        "saveCollage":
            MessageLookupByLibrary.simpleMessage("Enregistrer le collage"),
        "saveCopy":
            MessageLookupByLibrary.simpleMessage("Enregistrer une copie"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Enregistrer la clé"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Enregistrez votre clé de récupération si vous ne l\'avez pas déjà fait"),
        "saving": MessageLookupByLibrary.simpleMessage("Enregistrement..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scanner le code"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scannez ce code-barres avec\nvotre application d\'authentification"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Albums"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Nom de l\'album"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Noms d\'albums (par exemple \"Caméra\")\n• Types de fichiers (par exemple \"Vidéos\", \".gif\")\n• Années et mois (par exemple \"2022\", \"Janvier\")\n• Vacances (par exemple \"Noël\")\n• Descriptions de photos (par exemple \"#fun\")"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Ajoutez des descriptions comme \"#trip\" dans les infos photo pour les retrouver ici plus rapidement"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Recherche par date, mois ou année"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Trouver toutes les photos d\'une personne"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Types et noms de fichiers"),
        "searchHint1": MessageLookupByLibrary.simpleMessage(
            "Recherche rapide, sur l\'appareil"),
        "searchHint2": MessageLookupByLibrary.simpleMessage(
            "Dates des photos, descriptions"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Albums, noms de fichiers et types"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Emplacement"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Bientôt: Visages & recherche magique ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Grouper les photos qui sont prises dans un certain angle d\'une photo"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Invitez des gens, et vous verrez ici toutes les photos qu\'ils partagent"),
        "searchResultCount": m45,
        "security": MessageLookupByLibrary.simpleMessage("Sécurité"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Select a location"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Select a location first"),
        "selectAlbum":
            MessageLookupByLibrary.simpleMessage("Sélectionner album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Tout sélectionner"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Sélectionner les dossiers à sauvegarder"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Sélectionner les éléments à ajouter"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Sélectionner une langue"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Sélectionner plus de photos"),
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
        "selectedPhotos": m46,
        "selectedPhotosWithYours": m47,
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
        "setCover":
            MessageLookupByLibrary.simpleMessage("Définir la couverture"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Définir"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Définir le mot de passe"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Définir le rayon"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configuration fini"),
        "share": MessageLookupByLibrary.simpleMessage("Partager"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Partager le lien"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Ouvrez un album et appuyez sur le bouton de partage en haut à droite pour le partager."),
        "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage(
            "Partagez un album maintenant"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Partager le lien"),
        "shareMyVerificationID": m48,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Partager uniquement avec les personnes que vous voulez"),
        "shareTextConfirmOthersVerificationID": m49,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Téléchargez ente pour que nous puissions facilement partager des photos et des vidéos de qualité originale\n\nhttps://ente.io"),
        "shareTextReferralCode": m50,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Partager avec des utilisateurs non-ente"),
        "shareWithPeopleSectionTitle": m51,
        "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
            "Partagez votre premier album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Créez des albums partagés et collaboratifs avec d\'autres utilisateurs de ente, y compris des utilisateurs sur des plans gratuits."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Partagé par moi"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Partagé par vous"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Nouvelles photos partagées"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Recevoir des notifications quand quelqu\'un ajoute une photo à un album partagé dont vous faites partie"),
        "sharedWith": m52,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Partagés avec moi"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Partagé avec vous"),
        "sharing": MessageLookupByLibrary.simpleMessage("Partage..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Montrer les souvenirs"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "J\'accepte les <u-terms>conditions d\'utilisation</u-terms> et la <u-policy>politique de confidentialité</u-policy>"),
        "singleFileDeleteFromDevice": m53,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Elle sera supprimée de tous les albums."),
        "singleFileInBothLocalAndRemote": m54,
        "singleFileInRemoteOnly": m55,
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
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Le code que vous avez saisi est incorrect"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Désolé, nous n\'avons pas pu générer de clés sécurisées sur cet appareil.\n\nVeuillez vous inscrire depuis un autre appareil."),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Trier par"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Plus récent en premier"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Plus ancien en premier"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Succès"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Démarrer la sauvegarde"),
        "storage": MessageLookupByLibrary.simpleMessage("Stockage"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Famille"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Vous"),
        "storageInGB": m56,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Limite de stockage atteinte"),
        "storageUsageInfo": m57,
        "strongStrength":
            MessageLookupByLibrary.simpleMessage("Securité forte"),
        "subAlreadyLinkedErrMessage": m58,
        "subWillBeCancelledOn": m59,
        "subscribe": MessageLookupByLibrary.simpleMessage("S\'abonner"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Il semble que votre abonnement ait expiré. Veuillez vous abonner pour activer le partage."),
        "subscription": MessageLookupByLibrary.simpleMessage("Abonnement"),
        "success": MessageLookupByLibrary.simpleMessage("Succès"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Archivé avec succès"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Masquage réussi"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Désarchivé avec succès"),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("Masquage réussi"),
        "suggestFeatures": MessageLookupByLibrary.simpleMessage(
            "Suggérer des fonctionnalités"),
        "support": MessageLookupByLibrary.simpleMessage("Support"),
        "syncProgress": m60,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Synchronisation arrêtée ?"),
        "syncing": MessageLookupByLibrary.simpleMessage(
            "En cours de synchronisation..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Système"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("taper pour copier"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Appuyez pour entrer le code"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Il semble qu\'une erreur s\'est produite. Veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter notre équipe d\'assistance."),
        "terminate": MessageLookupByLibrary.simpleMessage("Se déconnecter"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Se déconnecter ?"),
        "terms": MessageLookupByLibrary.simpleMessage("Conditions"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Conditions d\'utilisation"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Merci"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("Merci de vous être abonné !"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Le téléchargement n\'a pas pu être terminé"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "La clé de récupération que vous avez entrée est incorrecte"),
        "theme": MessageLookupByLibrary.simpleMessage("Thème"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Ces éléments seront supprimés de votre appareil."),
        "theyAlsoGetXGb": m61,
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
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Cette adresse mail est déjà utilisé"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Cette image n\'a pas de données exif"),
        "thisIsPersonVerificationId": m62,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Ceci est votre ID de vérification"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Cela vous déconnectera de l\'appareil suivant :"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Cela vous déconnectera de cet appareil !"),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Cacher une photo ou une vidéo"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Pour réinitialiser votre mot de passe, veuillez d\'abord vérifier votre e-mail."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Journaux du jour"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Taille totale"),
        "trash": MessageLookupByLibrary.simpleMessage("Corbeille"),
        "trashDaysLeft": m63,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Réessayer"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Activez la sauvegarde pour télécharger automatiquement les fichiers ajoutés à ce dossier de l\'appareil sur ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 mois gratuits sur les forfaits annuels"),
        "twofactor":
            MessageLookupByLibrary.simpleMessage("Double authentification"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "L\'authentification à deux facteurs a été désactivée"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Authentification à deux facteurs"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "L\'authentification à deux facteurs a été réinitialisée avec succès "),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Configuration de l\'authentification à deux facteurs"),
        "unarchive": MessageLookupByLibrary.simpleMessage("Désarchiver"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Désarchiver l\'album"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Désarchivage en cours..."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Aucune catégorie"),
        "unhide": MessageLookupByLibrary.simpleMessage("Dévoiler"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Afficher dans l\'album"),
        "unhiding":
            MessageLookupByLibrary.simpleMessage("Démasquage en cours..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Démasquage des fichiers vers l\'album"),
        "unlock": MessageLookupByLibrary.simpleMessage("Déverrouiller"),
        "unpinAlbum":
            MessageLookupByLibrary.simpleMessage("Désépingler l\'album"),
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
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Jusqu\'à 50% de réduction, jusqu\'au 4ème déc."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Le stockage utilisable est limité par votre offre actuelle. Le stockage excédentaire deviendra automatiquement utilisable lorsque vous mettez à niveau votre offre."),
        "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Utiliser des liens publics pour les personnes qui ne sont pas sur ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Utiliser la clé de secours"),
        "useSelectedPhoto": MessageLookupByLibrary.simpleMessage(
            "Utiliser la photo sélectionnée"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Mémoire utilisée"),
        "validTill": m64,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "La vérification a échouée, veuillez réessayer"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de vérification"),
        "verify": MessageLookupByLibrary.simpleMessage("Vérifier"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Vérifier l\'email"),
        "verifyEmailID": m65,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Vérifier"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Vérifier le mot de passe"),
        "verifying":
            MessageLookupByLibrary.simpleMessage("Validation en cours..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Vérification de la clé de récupération..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vidéo"),
        "videos": MessageLookupByLibrary.simpleMessage("Vidéos"),
        "viewActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Afficher les sessions actives"),
        "viewAddOnButton": MessageLookupByLibrary.simpleMessage(
            "Afficher les modules complémentaires"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Tout afficher"),
        "viewAllExifData": MessageLookupByLibrary.simpleMessage(
            "Visualiser toutes les données EXIF"),
        "viewLogs":
            MessageLookupByLibrary.simpleMessage("Afficher les journaux"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Voir la clé de récupération"),
        "viewer": MessageLookupByLibrary.simpleMessage("Observateur"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Veuillez visiter web.ente.io pour gérer votre abonnement"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Nous sommes open source !"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Nous ne prenons pas en charge l\'édition des photos et des albums que vous ne possédez pas encore"),
        "weHaveSendEmailTo": m66,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Securité Faible"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Bienvenue !"),
        "yearly": MessageLookupByLibrary.simpleMessage("Annuel"),
        "yearsAgo": m67,
        "yes": MessageLookupByLibrary.simpleMessage("Oui"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Oui, annuler"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Oui, convertir en observateur"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Oui, supprimer"),
        "yesDiscardChanges": MessageLookupByLibrary.simpleMessage(
            "Oui, ignorer les modifications"),
        "yesLogout":
            MessageLookupByLibrary.simpleMessage("Oui, se déconnecter"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Oui, supprimer"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Oui, renouveler"),
        "you": MessageLookupByLibrary.simpleMessage("Vous"),
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
            "Vous êtes sur un plan familial !"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Vous êtes sur la dernière version"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Vous pouvez au maximum doubler votre espace de stockage"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Vous pouvez gérer vos liens dans l\'onglet Partage."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Vous pouvez essayer de rechercher une autre requête."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Vous ne pouvez pas rétrograder vers cette offre"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Vous ne pouvez pas partager avec vous-même"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Vous n\'avez aucun élément archivé."),
        "youHaveSuccessfullyFreedUp": m68,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Votre compte a été supprimé"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Votre carte"),
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
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("Votre abonnement a expiré"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Votre abonnement a été mis à jour avec succès"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Votre code de vérification a expiré"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Vous n\'avez aucun fichier dédupliqué pouvant être nettoyé"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Vous n\'avez pas de fichiers dans cet album qui peuvent être supprimés"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
            "Zoom en arrière pour voir les photos")
      };
}
