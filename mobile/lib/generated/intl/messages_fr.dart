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

  static String m9(count) =>
      "${Intl.plural(count, zero: 'Ajouter un collaborateur', one: 'Ajouter un collaborateur', other: 'Ajouter des collaborateurs')}";

  static String m10(count) =>
      "${Intl.plural(count, one: 'Ajoutez un objet', other: 'Ajoutez des objets')}";

  static String m11(storageAmount, endDate) =>
      "Votre extension de ${storageAmount} est valable jusqu\'au ${endDate}";

  static String m12(count) =>
      "${Intl.plural(count, zero: 'Ajouter un observateur', one: 'Ajouter un observateur', other: 'Ajouter des observateurs')}";

  static String m13(emailOrName) => "Ajouté par ${emailOrName}";

  static String m14(albumName) => "Ajouté avec succès à  ${albumName}";

  static String m15(count) =>
      "${Intl.plural(count, zero: 'Aucun Participant', one: '1 Participant', other: '${count} Participants')}";

  static String m16(versionValue) => "Version : ${versionValue}";

  static String m17(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} libre";

  static String m18(paymentProvider) =>
      "Veuillez d\'abord annuler votre abonnement existant de ${paymentProvider}";

  static String m3(user) =>
      "${user} ne pourra pas ajouter plus de photos à cet album\n\nIl pourra toujours supprimer les photos existantes ajoutées par eux";

  static String m19(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Votre famille a demandé ${storageAmountInGb} GB jusqu\'à présent',
            'false':
                'Vous avez réclamé ${storageAmountInGb} GB jusqu\'à présent',
            'other':
                'Vous avez réclamé ${storageAmountInGb} GB jusqu\'à présent!',
          })}";

  static String m20(albumName) => "Lien collaboratif créé pour ${albumName}";

  static String m21(count) =>
      "${Intl.plural(count, zero: '0 collaborateur ajouté', one: '1 collaborateur ajouté', other: '${count} collaborateurs ajoutés')}";

  static String m22(email, numOfDays) =>
      "Vous êtes sur le point d\'ajouter ${email} en tant que contact sûr. Il pourra récupérer votre compte si vous êtes absent pendant ${numOfDays} jours.";

  static String m23(familyAdminEmail) =>
      "Veuillez contacter <green>${familyAdminEmail}</green> pour gérer votre abonnement";

  static String m24(provider) =>
      "Veuillez nous contacter à support@ente.io pour gérer votre abonnement ${provider}.";

  static String m25(endpoint) => "Connecté à ${endpoint}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'Supprimer le fichier', other: 'Supprimer ${count} fichiers')}";

  static String m27(currentlyDeleting, totalCount) =>
      "Suppression de ${currentlyDeleting} / ${totalCount}";

  static String m28(albumName) =>
      "Cela supprimera le lien public pour accéder à \"${albumName}\".";

  static String m29(supportEmail) =>
      "Veuillez envoyer un e-mail à ${supportEmail} depuis votre adresse enregistrée";

  static String m30(count, storageSaved) =>
      "Vous avez nettoyé ${Intl.plural(count, one: '${count} fichier dupliqué', other: '${count} fichiers dupliqués')}, en libérant (${storageSaved}!)";

  static String m31(count, formattedSize) =>
      "${count} fichiers, ${formattedSize} chacun";

  static String m32(newEmail) => "L\'e-mail a été changé en ${newEmail}";

  static String m33(email) =>
      "${email} n\'a pas de compte Ente.\n\nEnvoyez une invitation pour partager des photos.";

  static String m34(text) => "Photos supplémentaires trouvées pour ${text}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 fichier sur cet appareil a été sauvegardé en toute sécurité', other: '${formattedNumber} fichiers sur cet appareil ont été sauvegardés en toute sécurité')}";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 fichier dans cet album a été sauvegardé en toute sécurité', other: '${formattedNumber} fichiers dans cet album ont été sauvegardés en toute sécurité')}";

  static String m4(storageAmountInGB) =>
      "${storageAmountInGB} Go chaque fois que quelqu\'un s\'inscrit à une offre payante et applique votre code";

  static String m37(endDate) => "Essai gratuit valide jusqu’au ${endDate}";

  static String m38(count) =>
      "Vous pouvez toujours ${Intl.plural(count, one: 'y', other: 'y')} accéder sur Ente tant que vous avez un abonnement actif";

  static String m39(sizeInMBorGB) => "Libérer ${sizeInMBorGB}";

  static String m40(count, formattedSize) =>
      "${Intl.plural(count, one: 'Il peut être supprimé de l\'appareil pour libérer ${formattedSize}', other: 'Ils peuvent être supprimés de l\'appareil pour libérer ${formattedSize}')}";

  static String m41(currentlyProcessing, totalCount) =>
      "Traitement en cours ${currentlyProcessing} / ${totalCount}";

  static String m42(count) =>
      "${Intl.plural(count, one: '${count} objet', other: '${count} objets')}";

  static String m43(email) =>
      "${email} vous a invité à être un contact de confiance";

  static String m44(expiryTime) => "Le lien expirera le ${expiryTime}";

  static String m5(count, formattedCount) =>
      "${Intl.plural(count, one: '${formattedCount} souvenir', other: '${formattedCount} souvenirs')}";

  static String m45(count) =>
      "${Intl.plural(count, one: 'Déplacez l\'objet', other: 'Déplacez des objets')}";

  static String m46(albumName) => "Déplacé avec succès vers ${albumName}";

  static String m47(personName) => "Aucune suggestion pour ${personName}";

  static String m48(name) => "Pas ${name}?";

  static String m49(familyAdminEmail) =>
      "Veuillez contacter ${familyAdminEmail} pour modifier votre code.";

  static String m0(passwordStrengthValue) =>
      "Sécurité du mot de passe : ${passwordStrengthValue}";

  static String m50(providerName) =>
      "Veuillez contacter le support ${providerName} si vous avez été facturé";

  static String m51(count) =>
      "${Intl.plural(count, zero: '0 photo', one: '1 photo', other: '${count} photos')}";

  static String m52(endDate) =>
      "Essai gratuit valable jusqu\'à ${endDate}.\nVous pouvez choisir un plan payant par la suite.";

  static String m53(toEmail) => "Merci de nous envoyer un e-mail à ${toEmail}";

  static String m54(toEmail) => "Envoyez les logs à ${toEmail}";

  static String m55(folderName) => "Traitement de ${folderName}...";

  static String m56(storeName) => "Notez-nous sur ${storeName}";

  static String m57(days, email) =>
      "Vous pourrez accéder au compte d\'ici ${days} jours. Une notification sera envoyée à ${email}.";

  static String m58(email) =>
      "Vous pouvez maintenant récupérer le compte de ${email} en définissant un nouveau mot de passe.";

  static String m59(email) => "${email} tente de récupérer votre compte.";

  static String m60(storageInGB) =>
      "3. Vous recevez tous les deux ${storageInGB} GB* gratuits";

  static String m61(userEmail) =>
      "${userEmail} sera retiré de cet album partagé\n\nToutes les photos ajoutées par eux seront également retirées de l\'album";

  static String m62(endDate) => "Renouvellement le ${endDate}";

  static String m63(count) =>
      "${Intl.plural(count, one: '${count} résultat trouvé', other: '${count} résultats trouvés')}";

  static String m64(snapshotLength, searchLength) =>
      "Incompatibilité de longueur des sections : ${snapshotLength} != ${searchLength}";

  static String m6(count) => "${count} sélectionné(s)";

  static String m65(count, yourCount) =>
      "${count} sélectionné(s) (${yourCount} à vous)";

  static String m66(verificationID) =>
      "Voici mon ID de vérification : ${verificationID} pour ente.io.";

  static String m7(verificationID) =>
      "Hé, pouvez-vous confirmer qu\'il s\'agit de votre ID de vérification ente.io : ${verificationID}";

  static String m67(referralCode, referralStorageInGB) =>
      "Code de parrainage Ente : ${referralCode} \n\nValidez le dans Paramètres → Général → Références pour obtenir ${referralStorageInGB} Go gratuitement après votre inscription à un plan payant\n\nhttps://ente.io";

  static String m68(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Partagez avec des personnes spécifiques', one: 'Partagé avec 1 personne', other: 'Partagé avec ${numberOfPeople} personnes')}";

  static String m69(emailIDs) => "Partagé avec ${emailIDs}";

  static String m70(fileType) =>
      "Elle ${fileType} sera supprimée de votre appareil.";

  static String m71(fileType) =>
      "Cette ${fileType} est à la fois sur ente et sur votre appareil.";

  static String m72(fileType) => "Cette ${fileType} sera supprimée de l\'Ente.";

  static String m1(storageAmountInGB) => "${storageAmountInGB} Go";

  static String m73(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} sur ${totalAmount} ${totalStorageUnit} utilisés";

  static String m74(id) =>
      "Votre ${id} est déjà lié à un autre compte Ente.\nSi vous souhaitez utiliser votre ${id} avec ce compte, veuillez contacter notre support";

  static String m75(endDate) => "Votre abonnement sera annulé le ${endDate}";

  static String m76(completed, total) =>
      "${completed}/${total} souvenirs conservés";

  static String m77(ignoreReason) =>
      "Appuyer pour envoyer, l\'envoi est actuellement ignoré en raison de ${ignoreReason}";

  static String m8(storageAmountInGB) =>
      "Ils obtiennent aussi ${storageAmountInGB} Go";

  static String m78(email) => "Ceci est l\'ID de vérification de ${email}";

  static String m79(count) =>
      "${Intl.plural(count, zero: 'Bientôt', one: '1 jour', other: '${count} jours')}";

  static String m80(email) =>
      "Vous avez été invité(e) à être un(e) héritier(e) par ${email}.";

  static String m81(galleryType) =>
      "Les galeries de type \'${galleryType}\' ne peuvent être renommées";

  static String m82(ignoreReason) =>
      "L\'envoi est ignoré en raison de ${ignoreReason}";

  static String m83(count) => "Sauvegarde ${count} souvenirs...";

  static String m84(endDate) => "Valable jusqu\'au ${endDate}";

  static String m85(email) => "Vérifier ${email}";

  static String m86(count) =>
      "${Intl.plural(count, zero: '0 observateur ajouté', one: '1 observateur ajouté', other: '${count} observateurs ajoutés')}";

  static String m2(email) =>
      "Nous avons envoyé un e-mail à <green>${email}</green>";

  static String m87(count) =>
      "${Intl.plural(count, one: 'il y a ${count} an', other: 'il y a ${count} ans')}";

  static String m88(storageSaved) =>
      "Vous avez libéré ${storageSaved} avec succès !";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Une nouvelle version de Ente est disponible."),
        "about": MessageLookupByLibrary.simpleMessage("À propos"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Accepter l\'invitation"),
        "account": MessageLookupByLibrary.simpleMessage("Compte"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Le compte est déjà configuré."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bon retour parmi nous !"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Je comprends que si je perds mon mot de passe, je perdrai mes données puisque mes données sont <underline>chiffrées de bout en bout</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessions actives"),
        "add": MessageLookupByLibrary.simpleMessage("Ajouter"),
        "addAName": MessageLookupByLibrary.simpleMessage("Ajouter un nom"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Ajouter un nouvel email"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Ajouter un collaborateur"),
        "addCollaborators": m9,
        "addFiles":
            MessageLookupByLibrary.simpleMessage("Ajouter des fichiers"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Ajouter depuis l\'appareil"),
        "addItem": m10,
        "addLocation":
            MessageLookupByLibrary.simpleMessage("Ajouter la localisation"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Ajouter"),
        "addMore": MessageLookupByLibrary.simpleMessage("Ajouter"),
        "addName": MessageLookupByLibrary.simpleMessage("Ajouter un nom"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Ajouter un nom ou fusionner"),
        "addNew": MessageLookupByLibrary.simpleMessage("Ajouter un nouveau"),
        "addNewPerson": MessageLookupByLibrary.simpleMessage(
            "Ajouter une nouvelle personne"),
        "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
            "Détails des modules complémentaires"),
        "addOnValidTill": m11,
        "addOns":
            MessageLookupByLibrary.simpleMessage("Modules complémentaires"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Ajouter des photos"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Ajouter la sélection"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Ajouter à l\'album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Ajouter à Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Ajouter à un album masqué"),
        "addTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Ajouter un contact de confiance"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Ajouter un observateur"),
        "addViewers": m12,
        "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
            "Ajoutez vos photos maintenant"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Ajouté comme"),
        "addedBy": m13,
        "addedSuccessfullyTo": m14,
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
        "albumParticipantsCount": m15,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Titre de l\'album"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album mis à jour"),
        "albums": MessageLookupByLibrary.simpleMessage("Albums"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Tout est effacé"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
            "Tous les souvenirs sont conservés"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Tous les groupements pour cette personne seront réinitialisés, et vous perdrez toutes les suggestions faites pour cette personne"),
        "allow": MessageLookupByLibrary.simpleMessage("Autoriser"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Autorisez les personnes ayant le lien à ajouter des photos dans l\'album partagé."),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
            "Autoriser l\'ajout de photos"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "Autoriser l\'application à ouvrir les liens d\'albums partagés"),
        "allowDownloads": MessageLookupByLibrary.simpleMessage(
            "Autoriser les téléchargements"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Autoriser les personnes à ajouter des photos"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Veuillez autoriser dans les paramètres l\'accès à vos photos pour qu\'Ente puisse afficher et sauvegarder votre bibliothèque."),
        "allowPermTitle": MessageLookupByLibrary.simpleMessage(
            "Autoriser l\'accès aux photos"),
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
        "appLock": MessageLookupByLibrary.simpleMessage(
            "Verrouillage de l\'application"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Choisissez entre l\'écran de verrouillage par défaut de votre appareil et un écran de verrouillage personnalisé avec un code PIN ou un mot de passe."),
        "appVersion": m16,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Appliquer"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Utiliser le code"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement à l\'AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("Archivée"),
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
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Êtes-vous certain de vouloir réinitialiser cette personne ?"),
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
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour gérer vos contacts de confiance"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour afficher votre clé de récupération"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous authentifier pour voir vos fichiers mis à la corbeille"),
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
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Vous verrez ici les appareils Cast disponibles."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Assurez-vous que les autorisations de réseau local sont activées pour l\'application Ente Photos, dans les paramètres."),
        "autoLock":
            MessageLookupByLibrary.simpleMessage("Verrouillage automatique"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Délai après lequel l\'application se verrouille une fois qu\'elle a été mise en arrière-plan"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "En raison d\'un problème technique, vous avez été déconnecté. Veuillez nous excuser pour le désagrément."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Appairage automatique"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "L\'appairage automatique ne fonctionne qu\'avec les appareils qui prennent en charge Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Disponible"),
        "availableStorageSpace": m17,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Dossiers sauvegardés"),
        "backup": MessageLookupByLibrary.simpleMessage("Sauvegarde"),
        "backupFailed":
            MessageLookupByLibrary.simpleMessage("Échec de la sauvegarde"),
        "backupFile":
            MessageLookupByLibrary.simpleMessage("Sauvegarder le fichier"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Sauvegarder avec les données mobiles"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Paramètres de la sauvegarde"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("État de la sauvegarde"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Les éléments qui ont été sauvegardés apparaîtront ici"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Sauvegarde des vidéos"),
        "birthday": MessageLookupByLibrary.simpleMessage("Anniversaire"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Offre Black Friday"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData":
            MessageLookupByLibrary.simpleMessage("Données mises en cache"),
        "calculating":
            MessageLookupByLibrary.simpleMessage("Calcul en cours..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Désolé, cet album ne peut pas être ouvert dans l\'application."),
        "canNotOpenTitle": MessageLookupByLibrary.simpleMessage(
            "Impossible d\'ouvrir cet album"),
        "canNotUploadToAlbumsOwnedByOthers": MessageLookupByLibrary.simpleMessage(
            "Impossible de télécharger dans les albums appartenant à d\'autres personnes"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Ne peut créer de lien que pour les fichiers que vous possédez"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Vous ne pouvez supprimer que les fichiers que vous possédez"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuler"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Annuler la récupération"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "Êtes-vous sûr de vouloir annuler la récupération ?"),
        "cancelOtherSubscription": m18,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Annuler l\'abonnement"),
        "cannotAddMorePhotosAfterBecomingViewer": m3,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Les fichiers partagés ne peuvent pas être supprimés"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Caster l\'album"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Veuillez vous assurer que vous êtes sur le même réseau que la TV."),
        "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
            "Échec de la diffusion de l\'album"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Visitez cast.ente.io sur l\'appareil que vous voulez associer.\n\nEntrez le code ci-dessous pour lire l\'album sur votre TV."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Point central"),
        "change": MessageLookupByLibrary.simpleMessage("Modifier"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Modifier l\'e-mail"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Changer l\'emplacement des éléments sélectionnés ?"),
        "changeLogBackupStatusContent": MessageLookupByLibrary.simpleMessage(
            "Nous avons ajouté un journal de tous les fichiers qui ont été envoyés vers Ente, y compris les échecs et la file d\'attente."),
        "changeLogBackupStatusTitle":
            MessageLookupByLibrary.simpleMessage("Statut de la Sauvegarde"),
        "changeLogDiscoverContent": MessageLookupByLibrary.simpleMessage(
            "Vous cherchez des photos de vos cartes d\'identité, des notes ou même des memes? Allez dans l\'onglet de recherche et découvrez Découverte. Sur la base de notre recherche sémantique, vous trouverez des photos qui pourraient être importantes pour vous.\\n\\nUniquement disponible si vous avez activé l\'apprentissage automatique."),
        "changeLogDiscoverTitle":
            MessageLookupByLibrary.simpleMessage("Découverte"),
        "changeLogMagicSearchImprovementContent":
            MessageLookupByLibrary.simpleMessage(
                "Nous avons amélioré la recherche magique pour qu\'elle soit beaucoup plus rapide. N\'attendez plus pour trouver ce que vous cherchez."),
        "changeLogMagicSearchImprovementTitle":
            MessageLookupByLibrary.simpleMessage(
                "Amélioration de la recherche magique"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Modifier le mot de passe"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Modifier le mot de passe"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Modifier les permissions ?"),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
            "Modifier votre code de parrainage"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Vérifier les mises à jour"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Veuillez consulter votre boîte de réception (ainsi que les indésirables) pour compléter la vérification"),
        "checkStatus":
            MessageLookupByLibrary.simpleMessage("Vérifier le statut"),
        "checking": MessageLookupByLibrary.simpleMessage("Vérification..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Vérification des modèles..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Stockage gratuit obtenu"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Réclamez plus !"),
        "claimed": MessageLookupByLibrary.simpleMessage("Obtenu"),
        "claimedStorageSoFar": m19,
        "cleanUncategorized": MessageLookupByLibrary.simpleMessage(
            "Effacer les éléments non classés"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Supprimer tous les fichiers non-catégorisés étant présents dans d\'autres albums"),
        "clearCaches":
            MessageLookupByLibrary.simpleMessage("Nettoyer le cache"),
        "clearIndexes":
            MessageLookupByLibrary.simpleMessage("Effacer les index"),
        "click": MessageLookupByLibrary.simpleMessage("• Cliquez sur"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Cliquez sur le menu de débordement"),
        "close": MessageLookupByLibrary.simpleMessage("Fermer"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Grouper par durée"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Grouper par nom de fichier"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Progression du regroupement"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Code appliqué"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Désolé, vous avez atteint la limite de changements de code."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Code copié dans le presse-papiers"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Code utilisé par vous"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Créez un lien pour permettre aux personnes d\'ajouter et de voir des photos dans votre album partagé sans avoir besoin d\'une application Ente ou d\'un compte. Idéal pour récupérer des photos d\'événement."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Lien collaboratif"),
        "collaborativeLinkCreatedFor": m20,
        "collaborator": MessageLookupByLibrary.simpleMessage("Collaborateur"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Les collaborateurs peuvent ajouter des photos et des vidéos à l\'album partagé."),
        "collaboratorsSuccessfullyAdded": m21,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Disposition"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
            "Collage sauvegardé dans la galerie"),
        "collect": MessageLookupByLibrary.simpleMessage("Récupérer"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
            "Collecter les photos d\'un événement"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Récupérer les photos"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Créez un lien où vos amis peuvent ajouter des photos en qualité originale."),
        "color": MessageLookupByLibrary.simpleMessage("Couleur "),
        "configuration": MessageLookupByLibrary.simpleMessage("Paramètres"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmer"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Voulez-vous vraiment désactiver l\'authentification à deux facteurs ?"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Confirmer la suppression du compte"),
        "confirmAddingTrustedContact": m22,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Oui, je veux supprimer définitivement ce compte et ses données dans toutes les applications."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirmer le mot de passe"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Confirmer le changement de l\'offre"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmer la clé de récupération"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmer la clé de récupération"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Connexion à l\'appareil"),
        "contactFamilyAdmin": m23,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contacter l\'assistance"),
        "contactToManageSubscription": m24,
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
            MessageLookupByLibrary.simpleMessage("Créer un lien collaboratif"),
        "createCollage":
            MessageLookupByLibrary.simpleMessage("Créez un collage"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Créer un nouveau compte"),
        "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage(
            "Créez ou sélectionnez un album"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Créer un lien public"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Création du lien..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Mise à jour critique disponible"),
        "crop": MessageLookupByLibrary.simpleMessage("Rogner"),
        "currentUsageIs": MessageLookupByLibrary.simpleMessage(
            "L\'utilisation actuelle est de "),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("en cours d\'exécution"),
        "custom": MessageLookupByLibrary.simpleMessage("Personnaliser"),
        "customEndpoint": m25,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Sombre"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Aujourd\'hui"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Hier"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Refuser l’invitation"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("Déchiffrement en cours..."),
        "decryptingVideo": MessageLookupByLibrary.simpleMessage(
            "Déchiffrement de la vidéo..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Déduplication de fichiers"),
        "delete": MessageLookupByLibrary.simpleMessage("Supprimer"),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Supprimer mon compte"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Nous sommes désolés de vous voir partir. N\'hésitez pas à partager vos commentaires pour nous aider à nous améliorer."),
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
            "Ce compte est lié à d\'autres applications Ente, si vous en utilisez une. Vos données téléchargées, dans toutes les applications ente, seront planifiées pour suppression, et votre compte sera définitivement supprimé."),
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
            MessageLookupByLibrary.simpleMessage("Supprimer de Ente"),
        "deleteItemCount": m26,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Supprimer la localisation"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Supprimer des photos"),
        "deleteProgress": m27,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Il manque une fonction clé dont j\'ai besoin"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "L\'application ou une certaine fonctionnalité ne se comporte pas comme je pense qu\'elle devrait"),
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
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Tout déselectionner"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Conçu pour survivre"),
        "details": MessageLookupByLibrary.simpleMessage("Détails"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Paramètres du développeur"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Êtes-vous sûr de vouloir modifier les paramètres du développeur ?"),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Saisissez le code"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Les fichiers ajoutés à cet album seront automatiquement téléchargés sur Ente."),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Verrouillage de l\'appareil"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Désactiver le verrouillage de l\'écran de l\'appareil lorsque ente est au premier plan et il y a une sauvegarde en cours. Ce n\'est normalement pas nécessaire, mais peut aider les gros téléchargements et les premières importations de grandes bibliothèques plus rapidement."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Appareil non trouvé"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Le savais-tu ?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Désactiver le verrouillage automatique"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Les observateurs peuvent toujours prendre des captures d\'écran ou enregistrer une copie de vos photos en utilisant des outils externes"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Veuillez remarquer"),
        "disableLinkMessage": m28,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Désactiver la double-authentification"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Désactiver la double-authentification..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Découverte"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Bébés"),
        "discover_celebrations": MessageLookupByLibrary.simpleMessage("Fêtes"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Alimentation"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Plantes"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Montagnes"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identité"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Mèmes"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Notes"),
        "discover_pets":
            MessageLookupByLibrary.simpleMessage("Animaux de compagnie"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Recettes"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Captures d\'écran "),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfies"),
        "discover_sunset":
            MessageLookupByLibrary.simpleMessage("Coucher du soleil"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Carte de Visite"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Fonds d\'écran"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Rejeter"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut":
            MessageLookupByLibrary.simpleMessage("Ne pas se déconnecter"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Plus tard"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Voulez-vous annuler les modifications que vous avez faites ?"),
        "done": MessageLookupByLibrary.simpleMessage("Terminé"),
        "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "Doublez votre espace de stockage"),
        "download": MessageLookupByLibrary.simpleMessage("Télécharger"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Échec du téléchargement"),
        "downloading":
            MessageLookupByLibrary.simpleMessage("Téléchargement en cours..."),
        "dropSupportEmail": m29,
        "duplicateFileCountWithStorageSaved": m30,
        "duplicateItemsGroup": m31,
        "edit": MessageLookupByLibrary.simpleMessage("Éditer"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Modifier l’emplacement"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Modifier l’emplacement"),
        "editPerson":
            MessageLookupByLibrary.simpleMessage("Modifier la personne"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Modification sauvegardée"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Les modifications de l\'emplacement ne seront visibles que dans Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("éligible"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailAlreadyRegistered":
            MessageLookupByLibrary.simpleMessage("E-mail déjà enregistré."),
        "emailChangedTo": m32,
        "emailNoEnteAccount": m33,
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("E-mail non enregistré."),
        "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
            "Vérification de l\'adresse e-mail"),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("Envoyez vos logs par e-mail"),
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Contacts d\'urgence"),
        "empty": MessageLookupByLibrary.simpleMessage("Vider"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Vider la corbeille ?"),
        "enable": MessageLookupByLibrary.simpleMessage("Activer"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente prend en charge l\'apprentissage automatique sur l\'appareil pour la reconnaissance faciale, la recherche magique et d\'autres fonctionnalités de recherche avancée"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Activer l\'apprentissage automatique pour la recherche magique et la reconnaissance faciale"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Activer la carte"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Vos photos seront affichées sur une carte du monde.\n\nCette carte est hébergée par Open Street Map, et les emplacements exacts de vos photos ne sont jamais partagés.\n\nVous pouvez désactiver cette fonction à tout moment dans les Paramètres."),
        "enabled": MessageLookupByLibrary.simpleMessage("Activé"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
            "Chiffrement de la sauvegarde..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Chiffrement"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Clés de chiffrement"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Point de terminaison mis à jour avec succès"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Chiffrement de bout en bout par défaut"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente peut chiffrer et conserver des fichiers que si vous leur accordez l\'accès"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>a besoin d\'une autorisation pour</i> préserver vos photos"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente conserve vos souvenirs, ils sont donc toujours disponibles pour vous, même si vous perdez votre appareil."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Vous pouvez également ajouter votre famille à votre forfait."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Saisir un nom d\'album"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Entrer le code"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Entrez le code fourni par votre ami pour réclamer de l\'espace de stockage gratuit pour vous deux"),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Anniversaire (facultatif)"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Entrer e-mail"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Entrez le nom du fichier"),
        "enterName": MessageLookupByLibrary.simpleMessage("Saisir un nom"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Saisir un nouveau mot de passe pour l\'utiliser pour chiffrer vos données"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Saisissez le mot de passe"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Entrez un mot de passe que nous pouvons utiliser pour chiffrer vos données"),
        "enterPersonName": MessageLookupByLibrary.simpleMessage(
            "Entrez le nom d\'une personne"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Saisir le code PIN"),
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
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
            "Photos supplémentaires trouvées"),
        "extraPhotosFoundFor": m34,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Ce visage n\'a pas encore été regroupé, veuillez revenir plus tard"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Reconnaissance faciale"),
        "faces": MessageLookupByLibrary.simpleMessage("Visages"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
            "Impossible d\'appliquer le code"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Échec de l\'annulation"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
            "Échec du téléchargement de la vidéo"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Impossible de récupérer les sessions actives"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Impossible de récupérer l\'original pour l\'édition"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Impossible de récupérer les détails du parrainage. Veuillez réessayer plus tard."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Impossible de charger les albums"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Impossible de lire la vidéo"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Impossible de rafraîchir l\'abonnement"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Échec du renouvellement"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Échec de la vérification du statut du paiement"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Ajoutez 5 membres de votre famille à votre abonnement existant sans payer de supplément.\n\nChaque membre dispose de son propre espace privé et ne peut pas voir les fichiers des autres membres, sauf s\'ils sont partagés.\n\nLes abonnement familiaux sont disponibles pour les clients qui ont un abonnement Ente payant.\n\nAbonnez-vous maintenant pour commencer !"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Famille"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Abonnements famille"),
        "faq": MessageLookupByLibrary.simpleMessage("FAQ"),
        "faqs": MessageLookupByLibrary.simpleMessage("FAQ"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favori"),
        "feedback": MessageLookupByLibrary.simpleMessage("Commentaires"),
        "file": MessageLookupByLibrary.simpleMessage("Fichier"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Échec de l\'enregistrement dans la galerie"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Ajouter une description..."),
        "fileNotUploadedYet": MessageLookupByLibrary.simpleMessage(
            "Le fichier n\'a pas encore été envoyé"),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Fichier enregistré dans la galerie"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Types de fichiers"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Types et noms de fichiers"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Fichiers supprimés"),
        "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Fichiers enregistrés dans la galerie"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Trouver des personnes rapidement par leur nom"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("Trouvez-les rapidement"),
        "flip": MessageLookupByLibrary.simpleMessage("Retourner"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("pour vos souvenirs"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Mot de passe oublié"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Visages trouvés"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Stockage gratuit obtenu"),
        "freeStorageOnReferralSuccess": m4,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Stockage gratuit utilisable"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Essai gratuit"),
        "freeTrialValidTill": m37,
        "freeUpAccessPostDelete": m38,
        "freeUpAmount": m39,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Libérer de l\'espace sur l\'appareil"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Économisez de l\'espace sur votre appareil en effaçant les fichiers qui ont déjà été sauvegardés."),
        "freeUpSpace":
            MessageLookupByLibrary.simpleMessage("Libérer de l\'espace"),
        "freeUpSpaceSaving": m40,
        "gallery": MessageLookupByLibrary.simpleMessage("Galerie"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Jusqu\'à 1000 souvenirs affichés dans la galerie"),
        "general": MessageLookupByLibrary.simpleMessage("Général"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Génération des clés de chiffrement..."),
        "genericProgress": m41,
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
        "guestView": MessageLookupByLibrary.simpleMessage("Vue invité"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Pour activer la vue invité, veuillez configurer le code d\'accès de l\'appareil ou le verrouillage de l\'écran dans les paramètres de votre système."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Nous ne suivons pas les installations d\'applications. Il serait utile que vous nous disiez comment vous nous avez trouvés !"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Comment avez-vous entendu parler de Ente? (facultatif)"),
        "help": MessageLookupByLibrary.simpleMessage("Aide"),
        "hidden": MessageLookupByLibrary.simpleMessage("Masqué"),
        "hide": MessageLookupByLibrary.simpleMessage("Masquer"),
        "hideContent":
            MessageLookupByLibrary.simpleMessage("Masquer le contenu"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Masque le contenu de l\'application dans le sélecteur d\'applications et désactive les captures d\'écran"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Masque le contenu de l\'application dans le sélecteur d\'application"),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "Masquer les éléments partagés de la galerie d\'accueil"),
        "hiding": MessageLookupByLibrary.simpleMessage("Masquage en cours..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Hébergé chez OSM France"),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("Comment cela fonctionne"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Demandez-leur d\'appuyer longuement sur leur adresse e-mail sur l\'écran des paramètres et de vérifier que les identifiants des deux appareils correspondent."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "L\'authentification biométrique n\'est pas configurée sur votre appareil. Veuillez activer Touch ID ou Face ID sur votre téléphone."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "L\'authentification biométrique est désactivée. Veuillez verrouiller et déverrouiller votre écran pour l\'activer."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("Ok"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorer"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignoré"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Certains fichiers de cet album sont ignorés parce qu\'ils avaient été précédemment supprimés de Ente."),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Image non analysée"),
        "immediately": MessageLookupByLibrary.simpleMessage("Immédiatement"),
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
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Éléments indexés"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "L\'indexation est en pause. Elle reprendra automatiquement lorsque l\'appareil sera prêt."),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Appareil non sécurisé"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Installation manuelle"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Adresse e-mail invalide"),
        "invalidEndpoint": MessageLookupByLibrary.simpleMessage(
            "Point de terminaison non valide"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Désolé, le point de terminaison que vous avez entré n\'est pas valide. Veuillez en entrer un valide puis réessayez."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Clé invalide"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "La clé de récupération que vous avez saisie n\'est pas valide. Veuillez vérifier qu\'elle contient 24 caractères et qu\'ils sont correctement orthographiés.\n\nSi vous avez saisi un ancien code de récupération, veuillez vérifier qu\'il contient 64 caractères et qu\'ils sont correctement orthographiés."),
        "invite": MessageLookupByLibrary.simpleMessage("Inviter"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Inviter à rejoindre Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invitez vos ami(e)s"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Invitez vos amis sur Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Il semble qu\'une erreur s\'est produite. Veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter notre équipe d\'assistance."),
        "itemCount": m42,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Les éléments montrent le nombre de jours restants avant la suppression définitive"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Les éléments sélectionnés seront supprimés de cet album"),
        "join": MessageLookupByLibrary.simpleMessage("Rejoindre"),
        "joinAlbum": MessageLookupByLibrary.simpleMessage("Rejoindre l\'album"),
        "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
            "pour afficher et ajouter vos photos"),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
            "pour ajouter ceci aux albums partagés"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Rejoindre Discord"),
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
        "left": MessageLookupByLibrary.simpleMessage("Gauche"),
        "legacy": MessageLookupByLibrary.simpleMessage("Héritage"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Comptes hérités"),
        "legacyInvite": m43,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "L\'héritage permet aux contacts de confiance d\'accéder à votre compte en votre absence."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Les contacts de confiance peuvent initier la récupération du compte et, s\'ils ne sont pas bloqués dans les 30 jours qui suivent, peuvent réinitialiser votre mot de passe et accéder à votre compte."),
        "light": MessageLookupByLibrary.simpleMessage("Clair"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Clair"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Lien copié dans le presse-papiers"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limite d\'appareil"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Activé"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expiré"),
        "linkExpiresOn": m44,
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
        "loadingModel": MessageLookupByLibrary.simpleMessage(
            "Téléchargement des modèles..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Chargement de vos photos..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galerie locale"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Indexation locale"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Il semble que quelque chose s\'est mal passé car la synchronisation des photos locales prend plus de temps que prévu. Veuillez contacter notre équipe d\'assistance"),
        "location": MessageLookupByLibrary.simpleMessage("Emplacement"),
        "locationName": MessageLookupByLibrary.simpleMessage("Nom du lieu"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Un tag d\'emplacement regroupe toutes les photos qui ont été prises dans un certain rayon d\'une photo"),
        "locations": MessageLookupByLibrary.simpleMessage("Emplacements"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Verrouiller"),
        "lockscreen":
            MessageLookupByLibrary.simpleMessage("Écran de verrouillage"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Se connecter"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Deconnexion..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expirée"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Votre session a expiré. Veuillez vous reconnecter."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "En cliquant sur connecter, j\'accepte les <u-terms>conditions d\'utilisation</u-terms> et la <u-policy>politique de confidentialité</u-policy>"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("Se connecter avec TOTP"),
        "logout": MessageLookupByLibrary.simpleMessage("Déconnexion"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Cela enverra des logs pour nous aider à déboguer votre problème. Veuillez noter que les noms de fichiers seront inclus pour aider à suivre les problèmes avec des fichiers spécifiques."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Appuyez longuement sur un e-mail pour vérifier le chiffrement de bout en bout."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Appuyez longuement sur un élément pour le voir en plein écran"),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("Vidéo en boucle désactivée"),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("Vidéo en boucle activée"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Appareil perdu ?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Apprentissage automatique"),
        "magicSearch":
            MessageLookupByLibrary.simpleMessage("Recherche magique"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "La recherche magique permet de rechercher des photos par leur contenu, par exemple \'fleur\', \'voiture rouge\', \'documents d\'identité\'"),
        "manage": MessageLookupByLibrary.simpleMessage("Gérer"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Gérer le cache de l\'appareil"),
        "manageDeviceStorageDesc":
            MessageLookupByLibrary.simpleMessage("Examiner et vider le cache."),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Gérer la famille"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Gérer le lien"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Gérer"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Gérer l\'abonnement"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "L\'appairage avec le code PIN fonctionne avec n\'importe quel écran sur lequel vous souhaitez voir votre album."),
        "map": MessageLookupByLibrary.simpleMessage("Carte"),
        "maps": MessageLookupByLibrary.simpleMessage("Cartes"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m5,
        "merchandise": MessageLookupByLibrary.simpleMessage("Boutique"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Fusionner avec existant"),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Photos fusionnées"),
        "mlConsent": MessageLookupByLibrary.simpleMessage(
            "Activer l\'apprentissage automatique"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Je comprends, et souhaite activer l\'apprentissage automatique"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Si vous activez l\'apprentissage automatique, Ente extraira des informations comme la géométrie des visages, incluant les photos partagées avec vous. \nCela se fera sur votre appareil, avec un cryptage de bout-en-bout de toutes les données biométriques générées."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Veuillez cliquer ici pour plus de détails sur cette fonctionnalité dans notre politique de confidentialité"),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
            "Activer l\'apprentissage automatique ?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Veuillez noter que l\'apprentissage automatique entraînera une augmentation de l\'utilisation de la bande passante et de la batterie, jusqu\'à ce que tous les éléments soient indexés. \nEnvisagez d\'utiliser l\'application de bureau pour une indexation plus rapide, tous les résultats seront automatiquement synchronisés."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobile, Web, Ordinateur"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moyen"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Modifiez votre requête, ou essayez de rechercher"),
        "moments": MessageLookupByLibrary.simpleMessage("Souvenirs"),
        "month": MessageLookupByLibrary.simpleMessage("mois"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensuel"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Plus de détails"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Les plus récents"),
        "mostRelevant":
            MessageLookupByLibrary.simpleMessage("Les plus pertinents"),
        "moveItem": m45,
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Déplacer vers l\'album"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Déplacer vers un album masqué"),
        "movedSuccessfullyTo": m46,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Déplacé dans la corbeille"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Déplacement des fichiers vers l\'album..."),
        "name": MessageLookupByLibrary.simpleMessage("Nom"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Nommez l\'album"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Impossible de se connecter à Ente, veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter le support."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Impossible de se connecter à Ente, veuillez vérifier vos paramètres réseau et contacter le support si l\'erreur persiste."),
        "never": MessageLookupByLibrary.simpleMessage("Jamais"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nouvel album"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Nouveau lieu"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Nouvelle personne"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Nouveau sur Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Le plus récent"),
        "next": MessageLookupByLibrary.simpleMessage("Suivant"),
        "no": MessageLookupByLibrary.simpleMessage("Non"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Aucun album que vous avez partagé"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Aucun appareil trouvé"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Aucune"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Vous n\'avez pas de fichiers sur cet appareil qui peuvent être supprimés"),
        "noDuplicates": MessageLookupByLibrary.simpleMessage("✨ Aucun doublon"),
        "noExifData":
            MessageLookupByLibrary.simpleMessage("Aucune donnée EXIF"),
        "noFacesFound":
            MessageLookupByLibrary.simpleMessage("Aucun visage détecté"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Aucune photo ou vidéo masquée"),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
            "Aucune image avec localisation"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Aucune connexion internet"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Aucune photo en cours de sauvegarde"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("Aucune photo trouvée"),
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
            "Aucun lien rapide sélectionné"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Aucune clé de récupération ?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "En raison de notre protocole de chiffrement de bout en bout, vos données ne peuvent pas être déchiffré sans votre mot de passe ou clé de récupération"),
        "noResults": MessageLookupByLibrary.simpleMessage("Aucun résultat"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Aucun résultat trouvé"),
        "noSuggestionsForPerson": m47,
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("Aucun verrou système trouvé"),
        "notPersonLabel": m48,
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Rien n\'a encore été partagé avec vous"),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
            "Il n\'y a encore rien à voir ici 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Sur votre appareil"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Sur <branding>Ente</branding>"),
        "onlyFamilyAdminCanChangeCode": m49,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Seulement eux"),
        "oops": MessageLookupByLibrary.simpleMessage("Oups"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Oups, impossible d\'enregistrer les modifications"),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
            "Oups, une erreur est arrivée"),
        "openAlbumInBrowser": MessageLookupByLibrary.simpleMessage(
            "Ouvrir l\'album dans le navigateur"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Veuillez utiliser l\'application web pour ajouter des photos à cet album"),
        "openFile": MessageLookupByLibrary.simpleMessage("Ouvrir le fichier"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Ouvrir les paramètres"),
        "openTheItem":
            MessageLookupByLibrary.simpleMessage("• Ouvrir l\'élément"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
            "Contributeurs d\'OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Optionnel, aussi court que vous le souhaitez..."),
        "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
            "Ou fusionner avec une personne existante"),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
            "Ou sélectionner un email existant"),
        "pair": MessageLookupByLibrary.simpleMessage("Associer"),
        "pairWithPin":
            MessageLookupByLibrary.simpleMessage("Appairer avec le code PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Appairage terminé"),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "La vérification est toujours en attente"),
        "passkey": MessageLookupByLibrary.simpleMessage("Code d\'accès"),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
            "Vérification du code d\'accès"),
        "password": MessageLookupByLibrary.simpleMessage("Mot de passe"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Le mot de passe a été modifié"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Mot de passe verrou"),
        "passwordStrength": m0,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "La force du mot de passe est calculée en tenant compte de la longueur du mot de passe, des caractères utilisés et du fait que le mot de passe figure ou non parmi les 10 000 mots de passe les plus utilisés"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Nous ne stockons pas ce mot de passe, donc si vous l\'oubliez, <underline>nous ne pouvons pas déchiffrer vos données</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Détails de paiement"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Échec du paiement"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Malheureusement votre paiement a échoué. Veuillez contacter le support et nous vous aiderons !"),
        "paymentFailedTalkToProvider": m50,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Éléments en attente"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Synchronisation en attente"),
        "people": MessageLookupByLibrary.simpleMessage("Personnes"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Personnes utilisant votre code"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Tous les éléments de la corbeille seront définitivement supprimés\n\nCette action ne peut pas être annulée"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Supprimer définitivement"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Supprimer définitivement de l\'appareil ?"),
        "personName":
            MessageLookupByLibrary.simpleMessage("Nom de la personne"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Descriptions de la photo"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Taille de la grille photo"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("photo"),
        "photos": MessageLookupByLibrary.simpleMessage("Photos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Les photos ajoutées par vous seront retirées de l\'album"),
        "photosCount": m51,
        "pickCenterPoint": MessageLookupByLibrary.simpleMessage(
            "Sélectionner le point central"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Épingler l\'album"),
        "pinLock":
            MessageLookupByLibrary.simpleMessage("Verrouillage du code PIN"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Lire l\'album sur la TV"),
        "playStoreFreeTrialValidTill": m52,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement au PlayStore"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "S\'il vous plaît, vérifiez votre connexion à internet et réessayez."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Veuillez contacter support@ente.io et nous serons heureux de vous aider!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Merci de contacter l\'assistance si cette erreur persiste"),
        "pleaseEmailUsAt": m53,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
            "Veuillez accorder la permission"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Veuillez vous reconnecter"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Veuillez sélectionner les liens rapides à supprimer"),
        "pleaseSendTheLogsTo": m54,
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
        "proceed": MessageLookupByLibrary.simpleMessage("Procéder"),
        "processed": MessageLookupByLibrary.simpleMessage("Traité"),
        "processingImport": m55,
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
        "rateUsOnStore": m56,
        "recover": MessageLookupByLibrary.simpleMessage("Récupérer"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Récupérer un compte"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Restaurer"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Récupérer un compte"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("Récupération initiée"),
        "recoveryInitiatedDesc": m57,
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
            "Votre clé de récupération est la seule façon de récupérer vos photos si vous oubliez votre mot de passe. Vous pouvez trouver votre clé de récupération dans Paramètres > Compte.\n\nVeuillez saisir votre clé de récupération ici pour vous assurer de l\'avoir enregistré correctement."),
        "recoveryReady": m58,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Restauration réussie !"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "Un contact de confiance tente d\'accéder à votre compte"),
        "recoveryWarningBody": m59,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "L\'appareil actuel n\'est pas assez puissant pour vérifier votre mot de passe, mais nous pouvons le régénérer d\'une manière qui fonctionne avec tous les appareils.\n\nVeuillez vous connecter à l\'aide de votre clé de secours et régénérer votre mot de passe (vous pouvez réutiliser le même si vous le souhaitez)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Recréer le mot de passe"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Ressaisir le mot de passe"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("Ressaisir le code PIN"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Parrainez des amis et doublez votre abonnement"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Donnez ce code à vos amis"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Ils s\'inscrivent à une offre payante"),
        "referralStep3": m60,
        "referrals": MessageLookupByLibrary.simpleMessage("Parrainages"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Les recommandations sont actuellement en pause"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Rejeter la récupération"),
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
        "remove": MessageLookupByLibrary.simpleMessage("Supprimer"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Supprimer les doublons"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Examinez et supprimez les fichiers étant des doublons exacts."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Retirer de l\'album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Retirer de l\'album ?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Retirer des favoris"),
        "removeInvite":
            MessageLookupByLibrary.simpleMessage("Supprimer l’Invitation"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Supprimer le lien"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Supprimer le participant"),
        "removeParticipantBody": m61,
        "removePersonLabel": MessageLookupByLibrary.simpleMessage(
            "Supprimer le libellé d\'une personne"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Supprimer le lien public"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Supprimer les liens publics"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Certains des éléments que vous êtes en train de retirer ont été ajoutés par d\'autres personnes, vous perdrez l\'accès vers ces éléments"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Enlever?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Retirez-vous comme contact de confiance"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Suppression des favoris…"),
        "rename": MessageLookupByLibrary.simpleMessage("Renommer"),
        "renameAlbum":
            MessageLookupByLibrary.simpleMessage("Renommer l\'album"),
        "renameFile":
            MessageLookupByLibrary.simpleMessage("Renommer le fichier"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Renouveler l’abonnement"),
        "renewsOn": m62,
        "reportABug": MessageLookupByLibrary.simpleMessage("Signaler un bug"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Signaler un bug"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Renvoyer l\'e-mail"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Réinitialiser les fichiers ignorés"),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
            "Réinitialiser le mot de passe"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Réinitialiser"),
        "resetToDefault": MessageLookupByLibrary.simpleMessage(
            "Réinitialiser aux valeurs par défaut"),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurer"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Restaurer vers l\'album"),
        "restoringFiles": MessageLookupByLibrary.simpleMessage(
            "Restauration des fichiers..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("Reprise des chargements"),
        "retry": MessageLookupByLibrary.simpleMessage("Réessayer"),
        "review": MessageLookupByLibrary.simpleMessage("Suggestions"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Veuillez vérifier et supprimer les éléments que vous croyez dupliqués."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Examiner les suggestions"),
        "right": MessageLookupByLibrary.simpleMessage("Droite"),
        "rotate": MessageLookupByLibrary.simpleMessage("Pivoter"),
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
        "savePerson":
            MessageLookupByLibrary.simpleMessage("Enregistrer la personne"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Enregistrez votre clé de récupération si vous ne l\'avez pas déjà fait"),
        "saving": MessageLookupByLibrary.simpleMessage("Enregistrement..."),
        "savingEdits": MessageLookupByLibrary.simpleMessage(
            "Enregistrement des modifications..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scanner le code"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scannez ce code-barres avec\nvotre application d\'authentification"),
        "search": MessageLookupByLibrary.simpleMessage("Rechercher"),
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
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "Les images seront affichées ici une fois le traitement terminé"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Les personnes seront affichées ici une fois l\'indexation terminée"),
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
            "Invitez des personnes, et vous verrez ici toutes les photos qu\'elles partagent"),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "Les personnes seront affichées ici une fois le traitement terminé"),
        "searchResultCount": m63,
        "searchSectionsLengthMismatch": m64,
        "security": MessageLookupByLibrary.simpleMessage("Sécurité"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "Ouvrir les liens des albums publics dans l\'application"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Sélectionnez un emplacement"),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
            "Sélectionnez d\'abord un emplacement"),
        "selectAlbum":
            MessageLookupByLibrary.simpleMessage("Sélectionner album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Tout sélectionner"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Tout"),
        "selectCoverPhoto": MessageLookupByLibrary.simpleMessage(
            "Sélectionnez la photo de couverture"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Sélectionnez les dossiers à sauvegarder"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Sélectionner les éléments à ajouter"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Sélectionnez une langue"),
        "selectMailApp": MessageLookupByLibrary.simpleMessage(
            "Sélectionnez l\'application mail"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Sélectionner plus de photos"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Sélectionnez une raison"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Sélectionner votre offre"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Les fichiers sélectionnés ne sont pas sur Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Les dossiers sélectionnés seront cryptés et sauvegardés"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Les éléments sélectionnés seront supprimés de tous les albums et déplacés dans la corbeille."),
        "selectedPhotos": m6,
        "selectedPhotosWithYours": m65,
        "send": MessageLookupByLibrary.simpleMessage("Envoyer"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Envoyer un e-mail"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Envoyer Invitations"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Envoyer le lien"),
        "serverEndpoint": MessageLookupByLibrary.simpleMessage(
            "Point de terminaison serveur"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expirée"),
        "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
            "Incompatibilité de l\'ID de session"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Définir un mot de passe"),
        "setAs": MessageLookupByLibrary.simpleMessage("Définir comme"),
        "setCover":
            MessageLookupByLibrary.simpleMessage("Définir la couverture"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Définir"),
        "setNewPassword": MessageLookupByLibrary.simpleMessage(
            "Définir un nouveau mot de passe"),
        "setNewPin":
            MessageLookupByLibrary.simpleMessage("Définir un nouveau code PIN"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Définir le mot de passe"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Définir le rayon"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configuration terminée"),
        "share": MessageLookupByLibrary.simpleMessage("Partager"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Partager le lien"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Ouvrez un album et appuyez sur le bouton de partage en haut à droite pour le partager."),
        "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage(
            "Partagez un album maintenant"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Partager le lien"),
        "shareMyVerificationID": m66,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Partagez uniquement avec les personnes que vous souhaitez"),
        "shareTextConfirmOthersVerificationID": m7,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Téléchargez Ente pour pouvoir facilement partager des photos et vidéos en qualité originale\n\nhttps://ente.io"),
        "shareTextReferralCode": m67,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Partager avec des utilisateurs non-Ente"),
        "shareWithPeopleSectionTitle": m68,
        "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
            "Partagez votre premier album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Créez des albums partagés et collaboratifs avec d\'autres utilisateurs de Ente, y compris des utilisateurs ayant des plans gratuits."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Partagé par moi"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Partagé par vous"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Nouvelles photos partagées"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Recevoir des notifications quand quelqu\'un ajoute une photo à un album partagé dont vous faites partie"),
        "sharedWith": m69,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Partagés avec moi"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Partagé avec vous"),
        "sharing": MessageLookupByLibrary.simpleMessage("Partage..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Montrer les souvenirs"),
        "showPerson":
            MessageLookupByLibrary.simpleMessage("Montrer la personne"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Se déconnecter d\'autres appareils"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Si vous pensez que quelqu\'un peut connaître votre mot de passe, vous pouvez forcer tous les autres appareils utilisant votre compte à se déconnecter."),
        "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Déconnecter les autres appareils"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "J\'accepte les <u-terms>conditions d\'utilisation</u-terms> et la <u-policy>politique de confidentialité</u-policy>"),
        "singleFileDeleteFromDevice": m70,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Elle sera supprimée de tous les albums."),
        "singleFileInBothLocalAndRemote": m71,
        "singleFileInRemoteOnly": m72,
        "skip": MessageLookupByLibrary.simpleMessage("Ignorer"),
        "social": MessageLookupByLibrary.simpleMessage("Réseaux sociaux"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Certains éléments sont à la fois sur Ente et votre appareil."),
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
        "sort": MessageLookupByLibrary.simpleMessage("Trier"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Trier par"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Plus récent en premier"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Plus ancien en premier"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Succès"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Démarrer la récupération"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Démarrer la sauvegarde"),
        "status": MessageLookupByLibrary.simpleMessage("État"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Voulez-vous arrêter la diffusion ?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Arrêter la diffusion"),
        "storage": MessageLookupByLibrary.simpleMessage("Stockage"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Famille"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Vous"),
        "storageInGB": m1,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Limite de stockage atteinte"),
        "storageUsageInfo": m73,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Forte"),
        "subAlreadyLinkedErrMessage": m74,
        "subWillBeCancelledOn": m75,
        "subscribe": MessageLookupByLibrary.simpleMessage("S\'abonner"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Vous avez besoin d\'un abonnement payant actif pour activer le partage."),
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
        "syncProgress": m76,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Synchronisation arrêtée ?"),
        "syncing": MessageLookupByLibrary.simpleMessage(
            "En cours de synchronisation..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Système"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("taper pour copier"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Appuyez pour entrer le code"),
        "tapToUnlock":
            MessageLookupByLibrary.simpleMessage("Appuyer pour déverrouiller"),
        "tapToUpload":
            MessageLookupByLibrary.simpleMessage("Appuyer pour envoyer"),
        "tapToUploadIsIgnoredDue": m77,
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
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "Le lien que vous essayez d\'accéder a expiré."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "La clé de récupération que vous avez entrée est incorrecte"),
        "theme": MessageLookupByLibrary.simpleMessage("Thème"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Ces éléments seront supprimés de votre appareil."),
        "theyAlsoGetXGb": m8,
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
        "thisIsPersonVerificationId": m78,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Ceci est votre ID de vérification"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Cela vous déconnectera de l\'appareil suivant :"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Cela vous déconnectera de cet appareil !"),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Ceci supprimera les liens publics de tous les liens rapides sélectionnés."),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Pour activer le verrouillage d\'application, veuillez configurer le code d\'accès de l\'appareil ou le verrouillage de l\'écran dans les paramètres de votre système."),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Pour masquer une photo ou une vidéo:"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Pour réinitialiser votre mot de passe, veuillez d\'abord vérifier votre e-mail."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Journaux du jour"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
            "Trop de tentatives incorrectes"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Taille totale"),
        "trash": MessageLookupByLibrary.simpleMessage("Corbeille"),
        "trashDaysLeft": m79,
        "trim": MessageLookupByLibrary.simpleMessage("Recadrer"),
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Contacts de confiance"),
        "trustedInviteBody": m80,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Réessayer"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Activez la sauvegarde pour charger automatiquement sur Ente les fichiers ajoutés à ce dossier de l\'appareil."),
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
        "typeOfGallerGallerytypeIsNotSupportedForRename": m81,
        "unarchive": MessageLookupByLibrary.simpleMessage("Désarchiver"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Désarchiver l\'album"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Désarchivage en cours..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Désolé, ce code n\'est pas disponible."),
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
        "uploadIsIgnoredDueToIgnorereason": m82,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Envoi des fichiers vers l\'album..."),
        "uploadingMultipleMemories": m83,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Sauvegarde 1 souvenir..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Jusqu\'à 50% de réduction, jusqu\'au 4ème déc."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Le stockage utilisable est limité par votre offre actuelle. Le stockage excédentaire deviendra automatiquement utilisable lorsque vous mettez à niveau votre offre."),
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Utiliser comme couverture"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "Vous avez des difficultés pour lire cette vidéo ? Appuyez longuement ici pour essayer un autre lecteur."),
        "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Utilisez des liens publics pour les personnes qui ne sont pas sur Ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Utiliser la clé de secours"),
        "useSelectedPhoto": MessageLookupByLibrary.simpleMessage(
            "Utiliser la photo sélectionnée"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Stockage utilisé"),
        "validTill": m84,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "La vérification a échouée, veuillez réessayer"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de vérification"),
        "verify": MessageLookupByLibrary.simpleMessage("Vérifier"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Vérifier l\'e-mail"),
        "verifyEmailID": m85,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Vérifier"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Vérifier le code d\'accès"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Vérifier le mot de passe"),
        "verifying":
            MessageLookupByLibrary.simpleMessage("Validation en cours..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Vérification de la clé de récupération..."),
        "videoInfo": MessageLookupByLibrary.simpleMessage("Informations vidéo"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vidéo"),
        "videos": MessageLookupByLibrary.simpleMessage("Vidéos"),
        "viewActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Afficher les sessions actives"),
        "viewAddOnButton": MessageLookupByLibrary.simpleMessage(
            "Afficher les modules complémentaires"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Tout afficher"),
        "viewAllExifData": MessageLookupByLibrary.simpleMessage(
            "Visualiser toutes les données EXIF"),
        "viewLargeFiles":
            MessageLookupByLibrary.simpleMessage("Fichiers volumineux"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Affichez les fichiers qui consomment le plus de stockage."),
        "viewLogs":
            MessageLookupByLibrary.simpleMessage("Afficher les journaux"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Voir la clé de récupération"),
        "viewer": MessageLookupByLibrary.simpleMessage("Observateur"),
        "viewersSuccessfullyAdded": m86,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Veuillez visiter web.ente.io pour gérer votre abonnement"),
        "waitingForVerification": MessageLookupByLibrary.simpleMessage(
            "En attente de vérification..."),
        "waitingForWifi": MessageLookupByLibrary.simpleMessage(
            "En attente de connexion Wi-Fi..."),
        "warning": MessageLookupByLibrary.simpleMessage("Attention"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Nous sommes open source !"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Nous ne prenons pas en charge l\'édition des photos et des albums que vous ne possédez pas encore"),
        "weHaveSendEmailTo": m2,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Securité Faible"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Bienvenue !"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Nouveautés"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Un contact de confiance peut vous aider à récupérer vos données."),
        "yearShort": MessageLookupByLibrary.simpleMessage("an"),
        "yearly": MessageLookupByLibrary.simpleMessage("Annuel"),
        "yearsAgo": m87,
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
        "yesResetPerson": MessageLookupByLibrary.simpleMessage(
            "Oui, réinitialiser la personne"),
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
        "youHaveSuccessfullyFreedUp": m88,
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
