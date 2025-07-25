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

  static String m0(title) => "${title} (Moi)";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Ajouter un collaborateur', one: 'Ajouter un collaborateur', other: 'Ajouter des collaborateurs')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Ajouter un élément', other: 'Ajouter des éléments')}";

  static String m3(storageAmount, endDate) =>
      "Votre extension de ${storageAmount} est valable jusqu\'au ${endDate}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Ajouter un spectateur', one: 'Ajouter une spectateur', other: 'Ajouter des spectateurs')}";

  static String m5(emailOrName) => "Ajouté par ${emailOrName}";

  static String m6(albumName) => "Ajouté avec succès à  ${albumName}";

  static String m7(name) => "Admirant ${name}";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Aucun Participant', one: '1 Participant', other: '${count} Participants')}";

  static String m9(versionValue) => "Version : ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} libre";

  static String m11(name) => "Magnifiques vues avec ${name}";

  static String m12(paymentProvider) =>
      "Veuillez d\'abord annuler votre abonnement existant de ${paymentProvider}";

  static String m13(user) =>
      "${user} ne pourra pas ajouter plus de photos à cet album\n\nIl pourra toujours supprimer les photos existantes ajoutées par eux";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Votre famille a obtenu ${storageAmountInGb} Go jusqu\'à présent',
            'false':
                'Vous avez obtenu ${storageAmountInGb} Go jusqu\'à présent',
            'other':
                'Vous avez obtenu ${storageAmountInGb} Go jusqu\'à présent !'
          })}";

  static String m15(albumName) => "Lien collaboratif créé pour ${albumName}";

  static String m16(count) =>
      "${Intl.plural(count, zero: '0 collaborateur ajouté', one: '1 collaborateur ajouté', other: '${count} collaborateurs ajoutés')}";

  static String m17(email, numOfDays) =>
      "Vous êtes sur le point d\'ajouter ${email} en tant que contact sûr. Il pourra récupérer votre compte si vous êtes absent pendant ${numOfDays} jours.";

  static String m18(familyAdminEmail) =>
      "Veuillez contacter <green>${familyAdminEmail}</green> pour gérer votre abonnement";

  static String m19(provider) =>
      "Veuillez nous contacter à support@ente.io pour gérer votre abonnement ${provider}.";

  static String m20(endpoint) => "Connecté à ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Supprimer le fichier', other: 'Supprimer ${count} fichiers')}";

  static String m22(count) =>
      "Supprimer également les photos (et les vidéos) présentes dans ces ${count} albums de <bold>tous les</bold> autres albums dont ils font partie ?";

  static String m23(currentlyDeleting, totalCount) =>
      "Suppression de ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "Cela supprimera le lien public pour accéder à \"${albumName}\".";

  static String m25(supportEmail) =>
      "Veuillez envoyer un e-mail à ${supportEmail} depuis votre adresse enregistrée";

  static String m26(count, storageSaved) =>
      "Vous avez nettoyé ${Intl.plural(count, one: '${count} fichier dupliqué', other: '${count} fichiers dupliqués')}, en libérant (${storageSaved}!)";

  static String m27(count, formattedSize) =>
      "${count} fichiers, ${formattedSize} chacun";

  static String m28(name) => "Cet e-mail est déjà lié à ${name}.";

  static String m29(newEmail) => "L\'email a été changé par ${newEmail}";

  static String m30(email) => "${email} n\'a pas de compte Ente.";

  static String m31(email) =>
      "${email} n\'a pas de compte Ente.\n\nEnvoyez une invitation pour partager des photos.";

  static String m32(name) => "Embrasse ${name}";

  static String m33(text) => "Photos supplémentaires trouvées pour ${text}";

  static String m34(name) => "Fête avec ${name}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 fichier sur cet appareil a été sauvegardé en toute sécurité', other: '${formattedNumber} fichiers sur cet appareil ont été sauvegardés en toute sécurité')}";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 fichier dans cet album a été sauvegardé en toute sécurité', other: '${formattedNumber} fichiers dans cet album ont été sauvegardés en toute sécurité')}";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} Go chaque fois que quelqu\'un s\'inscrit à une offre payante et applique votre code";

  static String m38(endDate) => "Essai gratuit valide jusqu’au ${endDate}";

  static String m39(count) =>
      "Vous pouvez toujours ${Intl.plural(count, one: 'l\'', other: 'les')} accéder sur Ente tant que vous avez un abonnement actif";

  static String m40(sizeInMBorGB) => "Libérer ${sizeInMBorGB}";

  static String m41(count, formattedSize) =>
      "${Intl.plural(count, one: 'Il peut être supprimé de l\'appareil pour libérer ${formattedSize}', other: 'Ils peuvent être supprimés de l\'appareil pour libérer ${formattedSize}')}";

  static String m42(currentlyProcessing, totalCount) =>
      "Traitement en cours ${currentlyProcessing} / ${totalCount}";

  static String m43(name) => "Randonnée avec ${name}";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} objet', other: '${count} objets')}";

  static String m45(name) => "Dernière fois avec ${name}";

  static String m46(email) =>
      "${email} vous a invité à être un contact de confiance";

  static String m47(expiryTime) => "Le lien expirera le ${expiryTime}";

  static String m48(email) => "Associer la personne à ${email}";

  static String m49(personName, email) =>
      "Cela va associer ${personName} à ${email}";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'aucun souvenir', one: '${formattedCount} souvenir', other: '${formattedCount} souvenirs')}";

  static String m51(count) =>
      "${Intl.plural(count, one: 'Déplacer un élément', other: 'Déplacer des éléments')}";

  static String m52(albumName) => "Déplacé avec succès vers ${albumName}";

  static String m53(personName) => "Aucune suggestion pour ${personName}";

  static String m54(name) => "Pas ${name}?";

  static String m55(familyAdminEmail) =>
      "Veuillez contacter ${familyAdminEmail} pour modifier votre code.";

  static String m56(name) => "En soirée avec ${name}";

  static String m57(passwordStrengthValue) =>
      "Sécurité du mot de passe : ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Veuillez contacter le support ${providerName} si vous avez été facturé";

  static String m59(name, age) => "${name} a ${age}!";

  static String m60(name, age) => "${name} aura bientôt ${age}";

  static String m61(count) =>
      "${Intl.plural(count, zero: 'No photos', one: '1 photo', other: '${count} photos')}";

  static String m62(count) =>
      "${Intl.plural(count, zero: '0 photo', one: '1 photo', other: '${count} photos')}";

  static String m63(endDate) =>
      "Essai gratuit valable jusqu\'à ${endDate}.\nVous pouvez choisir un plan payant par la suite.";

  static String m64(toEmail) => "Merci de nous envoyer un email à ${toEmail}";

  static String m65(toEmail) => "Envoyez les logs à ${toEmail}";

  static String m66(name) => "Pose avec ${name}";

  static String m67(folderName) => "Traitement de ${folderName}...";

  static String m68(storeName) => "Laissez une note sur ${storeName}";

  static String m69(name) => "Vous a réassigné à ${name}";

  static String m70(days, email) =>
      "Vous pourrez accéder au compte d\'ici ${days} jours. Une notification sera envoyée à ${email}.";

  static String m71(email) =>
      "Vous pouvez maintenant récupérer le compte de ${email} en définissant un nouveau mot de passe.";

  static String m72(email) => "${email} tente de récupérer votre compte.";

  static String m73(storageInGB) =>
      "3. Vous recevez tous les deux ${storageInGB} Go* gratuits";

  static String m74(userEmail) =>
      "${userEmail} sera retiré de cet album partagé\n\nToutes les photos ajoutées par eux seront également retirées de l\'album";

  static String m75(endDate) => "Renouvellement le ${endDate}";

  static String m76(name) => "En route avec ${name}";

  static String m77(count) =>
      "${Intl.plural(count, one: '${count} résultat trouvé', other: '${count} résultats trouvés')}";

  static String m78(snapshotLength, searchLength) =>
      "Incompatibilité de longueur des sections : ${snapshotLength} != ${searchLength}";

  static String m79(count) => "${count} sélectionné(s)";

  static String m80(count) => "${count} sélectionné(s)";

  static String m81(count, yourCount) =>
      "${count} sélectionné(s) (${yourCount} à vous)";

  static String m82(name) => "Selfies avec ${name}";

  static String m83(verificationID) =>
      "Voici mon ID de vérification : ${verificationID} pour ente.io.";

  static String m84(verificationID) =>
      "Hé, pouvez-vous confirmer qu\'il s\'agit de votre ID de vérification ente.io : ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Code de parrainage Ente : ${referralCode} \n\nValidez le dans Paramètres → Général → Références pour obtenir ${referralStorageInGB} Go gratuitement après votre inscription à un plan payant\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Partagez avec des personnes spécifiques', one: 'Partagé avec 1 personne', other: 'Partagé avec ${numberOfPeople} personnes')}";

  static String m87(emailIDs) => "Partagé avec ${emailIDs}";

  static String m88(fileType) =>
      "Elle ${fileType} sera supprimée de votre appareil.";

  static String m89(fileType) =>
      "Cette ${fileType} est à la fois sur ente et sur votre appareil.";

  static String m90(fileType) => "Cette ${fileType} sera supprimée de l\'Ente.";

  static String m91(name) => "Sports avec ${name}";

  static String m92(name) => "Spotlight sur ${name}";

  static String m93(storageAmountInGB) => "${storageAmountInGB} Go";

  static String m94(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} sur ${totalAmount} ${totalStorageUnit} utilisés";

  static String m95(id) =>
      "Votre ${id} est déjà lié à un autre compte Ente.\nSi vous souhaitez utiliser votre ${id} avec ce compte, veuillez contacter notre support";

  static String m96(endDate) => "Votre abonnement sera annulé le ${endDate}";

  static String m97(completed, total) =>
      "${completed}/${total} souvenirs sauvegardés";

  static String m98(ignoreReason) =>
      "Appuyer pour envoyer, l\'envoi est actuellement ignoré en raison de ${ignoreReason}";

  static String m99(storageAmountInGB) =>
      "Ils obtiennent aussi ${storageAmountInGB} Go";

  static String m100(email) => "Ceci est l\'ID de vérification de ${email}";

  static String m101(count) =>
      "${Intl.plural(count, one: 'Cette semaine, ${count} il y a l\'année', other: 'Cette semaine, ${count} il y a des années')}";

  static String m102(dateFormat) => "${dateFormat} au fil des années";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Bientôt', one: '1 jour', other: '${count} jours')}";

  static String m104(year) => "Voyage en ${year}";

  static String m105(location) => "Voyage vers ${location}";

  static String m106(email) =>
      "Vous avez été invité(e) à être un(e) héritier(e) par ${email}.";

  static String m107(galleryType) =>
      "Les galeries de type \'${galleryType}\' ne peuvent être renommées";

  static String m108(ignoreReason) =>
      "L\'envoi est ignoré en raison de ${ignoreReason}";

  static String m109(count) => "Sauvegarde de ${count} souvenirs...";

  static String m110(endDate) => "Valable jusqu\'au ${endDate}";

  static String m111(email) => "Vérifier ${email}";

  static String m112(name) => "Voir ${name} pour délier";

  static String m113(count) =>
      "${Intl.plural(count, zero: '0 spectateur ajouté', one: 'Un spectateur ajouté', other: '${count} spectateurs ajoutés')}";

  static String m114(email) =>
      "Nous avons envoyé un email à <green>${email}</green>";

  static String m115(name) => "Souhaitez à ${name} un joyeux anniversaire ! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, one: 'il y a ${count} an', other: 'il y a ${count} ans')}";

  static String m117(name) => "Vous et ${name}";

  static String m118(storageSaved) =>
      "Vous avez libéré ${storageSaved} avec succès !";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
          "Une nouvelle version de Ente est disponible.",
        ),
        "about": MessageLookupByLibrary.simpleMessage("À propos d\'Ente"),
        "acceptTrustInvite": MessageLookupByLibrary.simpleMessage(
          "Accepter l\'invitation",
        ),
        "account": MessageLookupByLibrary.simpleMessage("Compte"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
          "Le compte est déjà configuré.",
        ),
        "accountOwnerPersonAppbarTitle": m0,
        "accountWelcomeBack": MessageLookupByLibrary.simpleMessage(
          "Bon retour parmi nous !",
        ),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
          "Je comprends que si je perds mon mot de passe, je perdrai mes données puisque mes données sont <underline>chiffrées de bout en bout</underline>.",
        ),
        "actionNotSupportedOnFavouritesAlbum":
            MessageLookupByLibrary.simpleMessage(
          "Action non prise en charge sur l\'album des Favoris",
        ),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessions actives"),
        "add": MessageLookupByLibrary.simpleMessage("Ajouter"),
        "addAName": MessageLookupByLibrary.simpleMessage("Ajouter un nom"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage(
          "Ajouter un nouvel email",
        ),
        "addAlbumWidgetPrompt": MessageLookupByLibrary.simpleMessage(
          "Ajoutez un gadget d\'album à votre écran d\'accueil et revenez ici pour le personnaliser.",
        ),
        "addCollaborator": MessageLookupByLibrary.simpleMessage(
          "Ajouter un collaborateur",
        ),
        "addCollaborators": m1,
        "addFiles":
            MessageLookupByLibrary.simpleMessage("Ajouter des fichiers"),
        "addFromDevice": MessageLookupByLibrary.simpleMessage(
          "Ajouter depuis l\'appareil",
        ),
        "addItem": m2,
        "addLocation": MessageLookupByLibrary.simpleMessage(
          "Ajouter la localisation",
        ),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Ajouter"),
        "addMemoriesWidgetPrompt": MessageLookupByLibrary.simpleMessage(
          "Ajoutez un gadget des souvenirs à votre écran d\'accueil et revenez ici pour le personnaliser.",
        ),
        "addMore": MessageLookupByLibrary.simpleMessage("Ajouter"),
        "addName": MessageLookupByLibrary.simpleMessage("Ajouter un nom"),
        "addNameOrMerge": MessageLookupByLibrary.simpleMessage(
          "Ajouter un nom ou fusionner",
        ),
        "addNew": MessageLookupByLibrary.simpleMessage("Ajouter un nouveau"),
        "addNewPerson": MessageLookupByLibrary.simpleMessage(
          "Ajouter une nouvelle personne",
        ),
        "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
          "Détails des modules complémentaires",
        ),
        "addOnValidTill": m3,
        "addOns":
            MessageLookupByLibrary.simpleMessage("Modules complémentaires"),
        "addParticipants": MessageLookupByLibrary.simpleMessage(
          "Ajouter des participants",
        ),
        "addPeopleWidgetPrompt": MessageLookupByLibrary.simpleMessage(
          "Ajoutez un gadget des personnes à votre écran d\'accueil et revenez ici pour le personnaliser.",
        ),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Ajouter des photos"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Ajouter la sélection"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Ajouter à l\'album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Ajouter à Ente"),
        "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
          "Ajouter à un album masqué",
        ),
        "addTrustedContact": MessageLookupByLibrary.simpleMessage(
          "Ajouter un contact de confiance",
        ),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Ajouter un observateur"),
        "addViewers": m4,
        "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
          "Ajoutez vos photos maintenant",
        ),
        "addedAs": MessageLookupByLibrary.simpleMessage("Ajouté comme"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
          "Ajout aux favoris...",
        ),
        "admiringThem": m7,
        "advanced": MessageLookupByLibrary.simpleMessage("Avancé"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Avancé"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Après 1 jour"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Après 1 heure"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Après 1 mois"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Après 1 semaine"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Après 1 an"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Propriétaire"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Titre de l\'album"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album mis à jour"),
        "albums": MessageLookupByLibrary.simpleMessage("Albums"),
        "albumsWidgetDesc": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez les personnes que vous souhaitez voir sur votre écran d\'accueil.",
        ),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Tout est effacé"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
          "Tous les souvenirs sont sauvegardés",
        ),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
          "Tous les groupements pour cette personne seront réinitialisés, et vous perdrez toutes les suggestions faites pour cette personne",
        ),
        "allUnnamedGroupsWillBeMergedIntoTheSelectedPerson":
            MessageLookupByLibrary.simpleMessage(
          "Tous les groupes sans nom seront fusionnés dans la personne sélectionnée. Cela peut toujours être annulé à partir de l\'historique des suggestions de la personne.",
        ),
        "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
          "C\'est la première dans le groupe. Les autres photos sélectionnées se déplaceront automatiquement en fonction de cette nouvelle date",
        ),
        "allow": MessageLookupByLibrary.simpleMessage("Autoriser"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
          "Autorisez les personnes ayant le lien à ajouter des photos dans l\'album partagé.",
        ),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
          "Autoriser l\'ajout de photos",
        ),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
          "Autoriser l\'application à ouvrir les liens d\'albums partagés",
        ),
        "allowDownloads": MessageLookupByLibrary.simpleMessage(
          "Autoriser les téléchargements",
        ),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
          "Autoriser les personnes à ajouter des photos",
        ),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
          "Veuillez autoriser dans les paramètres l\'accès à vos photos pour qu\'Ente puisse afficher et sauvegarder votre bibliothèque.",
        ),
        "allowPermTitle": MessageLookupByLibrary.simpleMessage(
          "Autoriser l\'accès aux photos",
        ),
        "androidBiometricHint": MessageLookupByLibrary.simpleMessage(
          "Vérifier l’identité",
        ),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
          "Reconnaissance impossible. Réessayez.",
        ),
        "androidBiometricRequiredTitle": MessageLookupByLibrary.simpleMessage(
          "Empreinte digitale requise",
        ),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Succès"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Annuler"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Identifiants requis"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage("Identifiants requis"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
          "L\'authentification biométrique n\'est pas configurée sur votre appareil. Allez dans \'Paramètres > Sécurité\' pour ajouter l\'authentification biométrique.",
        ),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
          "Android, iOS, Web, Ordinateur",
        ),
        "androidSignInTitle": MessageLookupByLibrary.simpleMessage(
          "Authentification requise",
        ),
        "appIcon": MessageLookupByLibrary.simpleMessage("Icône de l\'appli"),
        "appLock": MessageLookupByLibrary.simpleMessage(
          "Verrouillage de l\'application",
        ),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
          "Choisissez entre l\'écran de verrouillage par défaut de votre appareil et un écran de verrouillage personnalisé avec un code PIN ou un mot de passe.",
        ),
        "appVersion": m9,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Appliquer"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Utiliser le code"),
        "appstoreSubscription": MessageLookupByLibrary.simpleMessage(
          "Abonnement à l\'AppStore",
        ),
        "archive": MessageLookupByLibrary.simpleMessage("Archivée"),
        "archiveAlbum":
            MessageLookupByLibrary.simpleMessage("Archiver l\'album"),
        "archiving":
            MessageLookupByLibrary.simpleMessage("Archivage en cours..."),
        "areThey": MessageLookupByLibrary.simpleMessage("Vraiment"),
        "areYouSureRemoveThisFaceFromPerson":
            MessageLookupByLibrary.simpleMessage(
          "Êtes-vous sûr de vouloir retirer ce visage de cette personne ?",
        ),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
          "Êtes-vous certains de vouloir quitter le plan familial?",
        ),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
          "Es-tu sûre de vouloir annuler?",
        ),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
          "Êtes-vous certains de vouloir changer d\'offre ?",
        ),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
          "Êtes-vous sûr de vouloir quitter ?",
        ),
        "areYouSureYouWantToIgnoreThesePersons":
            MessageLookupByLibrary.simpleMessage(
          "Êtes-vous sûr de vouloir ignorer ces personnes ?",
        ),
        "areYouSureYouWantToIgnoreThisPerson":
            MessageLookupByLibrary.simpleMessage(
          "Êtes-vous sûr de vouloir ignorer cette personne ?",
        ),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
          "Voulez-vous vraiment vous déconnecter ?",
        ),
        "areYouSureYouWantToMergeThem": MessageLookupByLibrary.simpleMessage(
          "Êtes-vous sûr de vouloir les fusionner?",
        ),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
          "Êtes-vous sûr de vouloir renouveler ?",
        ),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
          "Êtes-vous certain de vouloir réinitialiser cette personne ?",
        ),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
          "Votre abonnement a été annulé. Souhaitez-vous partager la raison ?",
        ),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
          "Quelle est la principale raison pour laquelle vous supprimez votre compte ?",
        ),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
          "Demandez à vos proches de partager",
        ),
        "atAFalloutShelter": MessageLookupByLibrary.simpleMessage(
          "dans un abri antiatomique",
        ),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
          "Authentifiez-vous pour modifier l\'authentification à deux facteurs par email",
        ),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
          "Veuillez vous authentifier pour modifier les paramètres de l\'écran de verrouillage",
        ),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
          "Authentifiez-vous pour modifier votre adresse email",
        ),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
          "Veuillez vous authentifier pour modifier votre mot de passe",
        ),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
          "Veuillez vous authentifier pour configurer l\'authentification à deux facteurs",
        ),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
          "Veuillez vous authentifier pour débuter la suppression du compte",
        ),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
          "Veuillez vous authentifier pour gérer vos contacts de confiance",
        ),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
          "Veuillez vous authentifier pour afficher votre clé de récupération",
        ),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
          "Veuillez vous authentifier pour voir vos fichiers mis à la corbeille",
        ),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
          "Authentifiez-vous pour voir les connexions actives",
        ),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
          "Veuillez vous authentifier pour voir vos fichiers cachés",
        ),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
          "Authentifiez-vous pour voir vos souvenirs",
        ),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Veuillez vous authentifier pour afficher votre clé de récupération",
        ),
        "authenticating": MessageLookupByLibrary.simpleMessage(
          "Authentification...",
        ),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "L\'authentification a échouée, veuillez réessayer",
        ),
        "authenticationSuccessful": MessageLookupByLibrary.simpleMessage(
          "Authentification réussie!",
        ),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
          "Vous verrez ici les appareils Cast disponibles.",
        ),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
          "Assurez-vous que les autorisations de réseau local sont activées pour l\'application Ente Photos, dans les paramètres.",
        ),
        "autoLock": MessageLookupByLibrary.simpleMessage(
          "Verrouillage automatique",
        ),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
          "Délai après lequel l\'application se verrouille une fois qu\'elle est en arrière-plan",
        ),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
          "En raison d\'un problème technique, vous avez été déconnecté. Veuillez nous excuser pour le désagrément.",
        ),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Appairage automatique"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
          "L\'appairage automatique ne fonctionne qu\'avec les appareils qui prennent en charge Chromecast.",
        ),
        "available": MessageLookupByLibrary.simpleMessage("Disponible"),
        "availableStorageSpace": m10,
        "backedUpFolders": MessageLookupByLibrary.simpleMessage(
          "Dossiers sauvegardés",
        ),
        "backgroundWithThem": m11,
        "backup": MessageLookupByLibrary.simpleMessage("Sauvegarde"),
        "backupFailed": MessageLookupByLibrary.simpleMessage(
          "Échec de la sauvegarde",
        ),
        "backupFile": MessageLookupByLibrary.simpleMessage(
          "Sauvegarder le fichier",
        ),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
          "Sauvegarder avec les données mobiles",
        ),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
          "Paramètres de la sauvegarde",
        ),
        "backupStatus": MessageLookupByLibrary.simpleMessage(
          "État de la sauvegarde",
        ),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
          "Les éléments qui ont été sauvegardés apparaîtront ici",
        ),
        "backupVideos": MessageLookupByLibrary.simpleMessage(
          "Sauvegarde des vidéos",
        ),
        "beach": MessageLookupByLibrary.simpleMessage("Sable et mer"),
        "birthday": MessageLookupByLibrary.simpleMessage("Anniversaire"),
        "birthdayNotifications": MessageLookupByLibrary.simpleMessage(
          "Notifications d’anniversaire",
        ),
        "birthdays": MessageLookupByLibrary.simpleMessage("Anniversaires"),
        "blackFridaySale": MessageLookupByLibrary.simpleMessage(
          "Offre Black Friday",
        ),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cLDesc1": MessageLookupByLibrary.simpleMessage(
          "Derrière la version beta du streaming vidéo, tout en travaillant sur la reprise des chargements et téléchargements, nous avons maintenant augmenté la limite de téléchargement de fichiers à 10 Go. Ceci est maintenant disponible dans les applications bureau et mobiles.",
        ),
        "cLDesc2": MessageLookupByLibrary.simpleMessage(
          "Les chargements en arrière-plan sont maintenant pris en charge sur iOS, en plus des appareils Android. Inutile d\'ouvrir l\'application pour sauvegarder vos dernières photos et vidéos.",
        ),
        "cLDesc3": MessageLookupByLibrary.simpleMessage(
          "Nous avons apporté des améliorations significatives à l\'expérience des souvenirs, comme la lecture automatique, la glisse vers le souvenir suivant et bien plus encore.",
        ),
        "cLDesc4": MessageLookupByLibrary.simpleMessage(
          "Avec un tas d\'améliorations sous le capot, il est maintenant beaucoup plus facile de voir tous les visages détectés, mettre des commentaires sur des visages similaires, et ajouter/supprimer des visages depuis une seule photo.",
        ),
        "cLDesc5": MessageLookupByLibrary.simpleMessage(
          "Vous recevrez maintenant une notification de désinscription pour tous les anniversaires que vous avez enregistrés sur Ente, ainsi qu\'une collection de leurs meilleures photos.",
        ),
        "cLDesc6": MessageLookupByLibrary.simpleMessage(
          "Plus besoin d\'attendre la fin des chargements/téléchargements avant de pouvoir fermer l\'application. Tous peuvent maintenant être mis en pause en cours de route et reprendre à partir de là où ça s\'est arrêté.",
        ),
        "cLTitle1": MessageLookupByLibrary.simpleMessage(
          "Envoi de gros fichiers vidéo",
        ),
        "cLTitle2":
            MessageLookupByLibrary.simpleMessage("Charger en arrière-plan"),
        "cLTitle3": MessageLookupByLibrary.simpleMessage(
          "Lecture automatique des souvenirs",
        ),
        "cLTitle4": MessageLookupByLibrary.simpleMessage(
          "Amélioration de la reconnaissance faciale",
        ),
        "cLTitle5": MessageLookupByLibrary.simpleMessage(
          "Notifications d’anniversaire",
        ),
        "cLTitle6": MessageLookupByLibrary.simpleMessage(
          "Reprise des chargements et téléchargements",
        ),
        "cachedData": MessageLookupByLibrary.simpleMessage(
          "Données mises en cache",
        ),
        "calculating":
            MessageLookupByLibrary.simpleMessage("Calcul en cours..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
          "Désolé, cet album ne peut pas être ouvert dans l\'application.",
        ),
        "canNotOpenTitle": MessageLookupByLibrary.simpleMessage(
          "Impossible d\'ouvrir cet album",
        ),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
          "Impossible de télécharger dans les albums appartenant à d\'autres personnes",
        ),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
          "Ne peut créer de lien que pour les fichiers que vous possédez",
        ),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
          "Vous ne pouvez supprimer que les fichiers que vous possédez",
        ),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuler"),
        "cancelAccountRecovery": MessageLookupByLibrary.simpleMessage(
          "Annuler la récupération",
        ),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
          "Êtes-vous sûr de vouloir annuler la récupération ?",
        ),
        "cancelOtherSubscription": m12,
        "cancelSubscription": MessageLookupByLibrary.simpleMessage(
          "Annuler l\'abonnement",
        ),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
          "Les fichiers partagés ne peuvent pas être supprimés",
        ),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Caster l\'album"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
          "Veuillez vous assurer que vous êtes sur le même réseau que la TV.",
        ),
        "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
          "Échec de la diffusion de l\'album",
        ),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
          "Visitez cast.ente.io sur l\'appareil que vous voulez associer.\n\nEntrez le code ci-dessous pour lire l\'album sur votre TV.",
        ),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Point central"),
        "change": MessageLookupByLibrary.simpleMessage("Modifier"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Modifier l\'e-mail"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
          "Changer l\'emplacement des éléments sélectionnés ?",
        ),
        "changePassword": MessageLookupByLibrary.simpleMessage(
          "Modifier le mot de passe",
        ),
        "changePasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Modifier le mot de passe",
        ),
        "changePermissions": MessageLookupByLibrary.simpleMessage(
          "Modifier les permissions ?",
        ),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
          "Modifier votre code de parrainage",
        ),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage(
          "Vérifier les mises à jour",
        ),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
          "Consultez votre boîte de réception (et les indésirables) pour finaliser la vérification",
        ),
        "checkStatus":
            MessageLookupByLibrary.simpleMessage("Vérifier le statut"),
        "checking": MessageLookupByLibrary.simpleMessage("Vérification..."),
        "checkingModels": MessageLookupByLibrary.simpleMessage(
          "Vérification des modèles...",
        ),
        "city": MessageLookupByLibrary.simpleMessage("Dans la ville"),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
          "Obtenez du stockage gratuit",
        ),
        "claimMore": MessageLookupByLibrary.simpleMessage("Réclamez plus !"),
        "claimed": MessageLookupByLibrary.simpleMessage("Obtenu"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized": MessageLookupByLibrary.simpleMessage(
          "Effacer les éléments non classés",
        ),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
          "Supprimer tous les fichiers non-catégorisés étant présents dans d\'autres albums",
        ),
        "clearCaches":
            MessageLookupByLibrary.simpleMessage("Nettoyer le cache"),
        "clearIndexes":
            MessageLookupByLibrary.simpleMessage("Effacer les index"),
        "click": MessageLookupByLibrary.simpleMessage("• Cliquez sur"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
          "• Cliquez sur le menu de débordement",
        ),
        "clickToInstallOurBestVersionYet": MessageLookupByLibrary.simpleMessage(
          "Cliquez pour installer notre meilleure version",
        ),
        "close": MessageLookupByLibrary.simpleMessage("Fermer"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
          "Grouper par durée",
        ),
        "clubByFileName": MessageLookupByLibrary.simpleMessage(
          "Grouper par nom de fichier",
        ),
        "clusteringProgress": MessageLookupByLibrary.simpleMessage(
          "Progression du regroupement",
        ),
        "codeAppliedPageTitle": MessageLookupByLibrary.simpleMessage(
          "Code appliqué",
        ),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
          "Désolé, vous avez atteint la limite de changements de code.",
        ),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
          "Code copié dans le presse-papiers",
        ),
        "codeUsedByYou": MessageLookupByLibrary.simpleMessage(
          "Code utilisé par vous",
        ),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
          "Créez un lien pour permettre aux personnes d\'ajouter et de voir des photos dans votre album partagé sans avoir besoin d\'une application Ente ou d\'un compte. Idéal pour récupérer des photos d\'événement.",
        ),
        "collaborativeLink": MessageLookupByLibrary.simpleMessage(
          "Lien collaboratif",
        ),
        "collaborativeLinkCreatedFor": m15,
        "collaborator": MessageLookupByLibrary.simpleMessage("Collaborateur"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
          "Les collaborateurs peuvent ajouter des photos et des vidéos à l\'album partagé.",
        ),
        "collaboratorsSuccessfullyAdded": m16,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Disposition"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
          "Collage sauvegardé dans la galerie",
        ),
        "collect": MessageLookupByLibrary.simpleMessage("Récupérer"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
          "Collecter les photos d\'un événement",
        ),
        "collectPhotos": MessageLookupByLibrary.simpleMessage(
          "Récupérer les photos",
        ),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
          "Créez un lien où vos amis peuvent ajouter des photos en qualité originale.",
        ),
        "color": MessageLookupByLibrary.simpleMessage("Couleur "),
        "configuration": MessageLookupByLibrary.simpleMessage("Paramètres"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmer"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
          "Voulez-vous vraiment désactiver l\'authentification à deux facteurs ?",
        ),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
          "Confirmer la suppression du compte",
        ),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
          "Oui, je veux supprimer définitivement ce compte et ses données dans toutes les applications.",
        ),
        "confirmPassword": MessageLookupByLibrary.simpleMessage(
          "Confirmer le mot de passe",
        ),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
          "Confirmer le changement de l\'offre",
        ),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Confirmer la clé de récupération",
        ),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Confirmer la clé de récupération",
        ),
        "connectToDevice": MessageLookupByLibrary.simpleMessage(
          "Connexion à l\'appareil",
        ),
        "contactFamilyAdmin": m18,
        "contactSupport": MessageLookupByLibrary.simpleMessage(
          "Contacter l\'assistance",
        ),
        "contactToManageSubscription": m19,
        "contacts": MessageLookupByLibrary.simpleMessage("Contacts"),
        "contents": MessageLookupByLibrary.simpleMessage("Contenus"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuer"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
          "Poursuivre avec la version d\'essai gratuite",
        ),
        "convertToAlbum": MessageLookupByLibrary.simpleMessage(
          "Convertir en album",
        ),
        "copyEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Copier l’adresse email",
        ),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copier le lien"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Copiez-collez ce code\ndans votre application d\'authentification",
        ),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
          "Nous n\'avons pas pu sauvegarder vos données.\nNous allons réessayer plus tard.",
        ),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
          "Impossible de libérer de l\'espace",
        ),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
          "Impossible de mettre à jour l’abonnement",
        ),
        "count": MessageLookupByLibrary.simpleMessage("Total"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Rapport d\'erreur"),
        "create": MessageLookupByLibrary.simpleMessage("Créer"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Créer un compte"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
          "Appuyez longuement pour sélectionner des photos et cliquez sur + pour créer un album",
        ),
        "createCollaborativeLink": MessageLookupByLibrary.simpleMessage(
          "Créer un lien collaboratif",
        ),
        "createCollage":
            MessageLookupByLibrary.simpleMessage("Créez un collage"),
        "createNewAccount": MessageLookupByLibrary.simpleMessage(
          "Créer un nouveau compte",
        ),
        "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage(
          "Créez ou sélectionnez un album",
        ),
        "createPublicLink": MessageLookupByLibrary.simpleMessage(
          "Créer un lien public",
        ),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Création du lien..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
          "Mise à jour critique disponible",
        ),
        "crop": MessageLookupByLibrary.simpleMessage("Rogner"),
        "curatedMemories": MessageLookupByLibrary.simpleMessage(
          "Souvenirs conservés",
        ),
        "currentUsageIs": MessageLookupByLibrary.simpleMessage(
          "L\'utilisation actuelle est de ",
        ),
        "currentlyRunning": MessageLookupByLibrary.simpleMessage(
          "en cours d\'exécution",
        ),
        "custom": MessageLookupByLibrary.simpleMessage("Personnaliser"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Sombre"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Aujourd\'hui"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Hier"),
        "declineTrustInvite": MessageLookupByLibrary.simpleMessage(
          "Refuser l’invitation",
        ),
        "decrypting": MessageLookupByLibrary.simpleMessage(
          "Déchiffrement en cours...",
        ),
        "decryptingVideo": MessageLookupByLibrary.simpleMessage(
          "Déchiffrement de la vidéo...",
        ),
        "deduplicateFiles": MessageLookupByLibrary.simpleMessage(
          "Déduplication de fichiers",
        ),
        "delete": MessageLookupByLibrary.simpleMessage("Supprimer"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage(
          "Supprimer mon compte",
        ),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
          "Nous sommes désolés de vous voir partir. N\'hésitez pas à partager vos commentaires pour nous aider à nous améliorer.",
        ),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
          "Supprimer définitivement le compte",
        ),
        "deleteAlbum":
            MessageLookupByLibrary.simpleMessage("Supprimer l\'album"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
          "Supprimer aussi les photos (et vidéos) présentes dans cet album de <bold>tous</bold> les autres albums dont elles font partie ?",
        ),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
          "Ceci supprimera tous les albums vides. Ceci est utile lorsque vous voulez réduire l\'encombrement dans votre liste d\'albums.",
        ),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Tout Supprimer"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
          "Ce compte est lié à d\'autres applications Ente, si vous en utilisez une. Vos données téléchargées, dans toutes les applications ente, seront planifiées pour suppression, et votre compte sera définitivement supprimé.",
        ),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
          "Veuillez envoyer un e-mail à <warning>account-deletion@ente.io</warning> à partir de votre adresse e-mail enregistrée.",
        ),
        "deleteEmptyAlbums": MessageLookupByLibrary.simpleMessage(
          "Supprimer les albums vides",
        ),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage(
          "Supprimer les albums vides ?",
        ),
        "deleteFromBoth": MessageLookupByLibrary.simpleMessage(
          "Supprimer des deux",
        ),
        "deleteFromDevice": MessageLookupByLibrary.simpleMessage(
          "Supprimer de l\'appareil",
        ),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Supprimer de Ente"),
        "deleteItemCount": m21,
        "deleteLocation": MessageLookupByLibrary.simpleMessage(
          "Supprimer la localisation",
        ),
        "deleteMultipleAlbumDialog": m22,
        "deletePhotos": MessageLookupByLibrary.simpleMessage(
          "Supprimer des photos",
        ),
        "deleteProgress": m23,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
          "Il manque une fonction clé dont j\'ai besoin",
        ),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
          "L\'application ou une certaine fonctionnalité ne se comporte pas comme je pense qu\'elle devrait",
        ),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
          "J\'ai trouvé un autre service que je préfère",
        ),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
          "Ma raison n\'est pas listée",
        ),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
          "Votre demande sera traitée sous 72 heures.",
        ),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
          "Supprimer l\'album partagé ?",
        ),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
          "L\'album sera supprimé pour tout le monde\n\nVous perdrez l\'accès aux photos partagées dans cet album qui sont détenues par d\'autres personnes",
        ),
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Tout déselectionner"),
        "designedToOutlive": MessageLookupByLibrary.simpleMessage(
          "Conçu pour survivre",
        ),
        "details": MessageLookupByLibrary.simpleMessage("Détails"),
        "developerSettings": MessageLookupByLibrary.simpleMessage(
          "Paramètres du développeur",
        ),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
          "Êtes-vous sûr de vouloir modifier les paramètres du développeur ?",
        ),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Saisissez le code"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
          "Les fichiers ajoutés à cet album seront automatiquement téléchargés sur Ente.",
        ),
        "deviceLock": MessageLookupByLibrary.simpleMessage(
          "Verrouillage par défaut de l\'appareil",
        ),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
          "Désactiver le verrouillage de l\'écran lorsque Ente est au premier plan et qu\'une sauvegarde est en cours. Ce n\'est normalement pas nécessaire mais cela peut faciliter les gros téléchargements et les premières importations de grandes bibliothèques.",
        ),
        "deviceNotFound": MessageLookupByLibrary.simpleMessage(
          "Appareil non trouvé",
        ),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Le savais-tu ?"),
        "different": MessageLookupByLibrary.simpleMessage("Différent(e)"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
          "Désactiver le verrouillage automatique",
        ),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
          "Les observateurs peuvent toujours prendre des captures d\'écran ou enregistrer une copie de vos photos en utilisant des outils externes",
        ),
        "disableDownloadWarningTitle": MessageLookupByLibrary.simpleMessage(
          "Veuillez remarquer",
        ),
        "disableLinkMessage": m24,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
          "Désactiver l\'authentification à deux facteurs",
        ),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
          "Désactivation de l\'authentification à deux facteurs...",
        ),
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
        "discover_pets": MessageLookupByLibrary.simpleMessage(
          "Animaux de compagnie",
        ),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Recettes"),
        "discover_screenshots": MessageLookupByLibrary.simpleMessage(
          "Captures d\'écran ",
        ),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfies"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage(
          "Coucher du soleil",
        ),
        "discover_visiting_cards": MessageLookupByLibrary.simpleMessage(
          "Carte de Visite",
        ),
        "discover_wallpapers": MessageLookupByLibrary.simpleMessage(
          "Fonds d\'écran",
        ),
        "dismiss": MessageLookupByLibrary.simpleMessage("Rejeter"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage(
          "Ne pas se déconnecter",
        ),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Plus tard"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
          "Voulez-vous annuler les modifications que vous avez faites ?",
        ),
        "done": MessageLookupByLibrary.simpleMessage("Terminé"),
        "dontSave": MessageLookupByLibrary.simpleMessage("Ne pas enregistrer"),
        "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
          "Doublez votre espace de stockage",
        ),
        "download": MessageLookupByLibrary.simpleMessage("Télécharger"),
        "downloadFailed": MessageLookupByLibrary.simpleMessage(
          "Échec du téléchargement",
        ),
        "downloading": MessageLookupByLibrary.simpleMessage(
          "Téléchargement en cours...",
        ),
        "dropSupportEmail": m25,
        "duplicateFileCountWithStorageSaved": m26,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Éditer"),
        "editEmailAlreadyLinked": m28,
        "editLocation": MessageLookupByLibrary.simpleMessage(
          "Modifier l’emplacement",
        ),
        "editLocationTagTitle": MessageLookupByLibrary.simpleMessage(
          "Modifier l’emplacement",
        ),
        "editPerson":
            MessageLookupByLibrary.simpleMessage("Modifier la personne"),
        "editTime": MessageLookupByLibrary.simpleMessage("Modifier l\'heure"),
        "editsSaved": MessageLookupByLibrary.simpleMessage(
          "Modification sauvegardée",
        ),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
          "Les modifications de l\'emplacement ne seront visibles que dans Ente",
        ),
        "eligible": MessageLookupByLibrary.simpleMessage("éligible"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
          "Email déjà enregistré.",
        ),
        "emailChangedTo": m29,
        "emailDoesNotHaveEnteAccount": m30,
        "emailNoEnteAccount": m31,
        "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
          "E-mail non enregistré.",
        ),
        "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
          "Authentification à deux facteurs par email",
        ),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
          "Envoyez vos journaux par email",
        ),
        "embracingThem": m32,
        "emergencyContacts": MessageLookupByLibrary.simpleMessage(
          "Contacts d\'urgence",
        ),
        "empty": MessageLookupByLibrary.simpleMessage("Vider"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Vider la corbeille ?"),
        "enable": MessageLookupByLibrary.simpleMessage("Activer"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
          "Ente prend en charge l\'apprentissage automatique sur l\'appareil pour la reconnaissance des visages, la recherche magique et d\'autres fonctionnalités de recherche avancée",
        ),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
          "Activer l\'apprentissage automatique pour la reconnaissance des visages et la recherche magique",
        ),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Activer la carte"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
          "Vos photos seront affichées sur une carte du monde.\n\nCette carte est hébergée par Open Street Map, et les emplacements exacts de vos photos ne sont jamais partagés.\n\nVous pouvez désactiver cette fonction à tout moment dans les Paramètres.",
        ),
        "enabled": MessageLookupByLibrary.simpleMessage("Activé"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
          "Chiffrement de la sauvegarde...",
        ),
        "encryption": MessageLookupByLibrary.simpleMessage("Chiffrement"),
        "encryptionKeys": MessageLookupByLibrary.simpleMessage(
          "Clés de chiffrement",
        ),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
          "Point de terminaison mis à jour avec succès",
        ),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
          "Chiffrement de bout en bout par défaut",
        ),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
          "Ente peut chiffrer et conserver des fichiers que si vous leur accordez l\'accès",
        ),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
          "Ente <i>a besoin d\'une autorisation pour</i> préserver vos photos",
        ),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
          "Ente conserve vos souvenirs pour qu\'ils soient toujours disponible, même si vous perdez cet appareil.",
        ),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
          "Vous pouvez également ajouter votre famille à votre forfait.",
        ),
        "enterAlbumName": MessageLookupByLibrary.simpleMessage(
          "Saisir un nom d\'album",
        ),
        "enterCode": MessageLookupByLibrary.simpleMessage("Entrer le code"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
          "Entrez le code fourni par votre ami·e pour débloquer l\'espace de stockage gratuit",
        ),
        "enterDateOfBirth": MessageLookupByLibrary.simpleMessage(
          "Anniversaire (facultatif)",
        ),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Entrer un email"),
        "enterFileName": MessageLookupByLibrary.simpleMessage(
          "Entrez le nom du fichier",
        ),
        "enterName": MessageLookupByLibrary.simpleMessage("Saisir un nom"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
          "Saisissez votre nouveau mot de passe qui sera utilisé pour chiffrer vos données",
        ),
        "enterPassword": MessageLookupByLibrary.simpleMessage(
          "Saisissez le mot de passe",
        ),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
          "Entrez un mot de passe que nous pouvons utiliser pour chiffrer vos données",
        ),
        "enterPersonName": MessageLookupByLibrary.simpleMessage(
          "Entrez le nom d\'une personne",
        ),
        "enterPin": MessageLookupByLibrary.simpleMessage("Saisir le code PIN"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
          "Code de parrainage",
        ),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Entrez le code à 6 chiffres de\nvotre application d\'authentification",
        ),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
          "Veuillez entrer une adresse email valide.",
        ),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Entrez votre adresse e-mail",
        ),
        "enterYourNewEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Entrez votre nouvelle adresse e-mail",
        ),
        "enterYourPassword": MessageLookupByLibrary.simpleMessage(
          "Entrez votre mot de passe",
        ),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Entrez votre clé de récupération",
        ),
        "error": MessageLookupByLibrary.simpleMessage("Erreur"),
        "everywhere": MessageLookupByLibrary.simpleMessage("partout"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser": MessageLookupByLibrary.simpleMessage(
          "Utilisateur existant",
        ),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
          "Ce lien a expiré. Veuillez sélectionner un nouveau délai d\'expiration ou désactiver l\'expiration du lien.",
        ),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Exporter les logs"),
        "exportYourData": MessageLookupByLibrary.simpleMessage(
          "Exportez vos données",
        ),
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
          "Photos supplémentaires trouvées",
        ),
        "extraPhotosFoundFor": m33,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
          "Ce visage n\'a pas encore été regroupé, veuillez revenir plus tard",
        ),
        "faceRecognition": MessageLookupByLibrary.simpleMessage(
          "Reconnaissance faciale",
        ),
        "faceThumbnailGenerationFailed": MessageLookupByLibrary.simpleMessage(
          "Impossible de créer des miniatures de visage",
        ),
        "faces": MessageLookupByLibrary.simpleMessage("Visages"),
        "failed": MessageLookupByLibrary.simpleMessage("Échec"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
          "Impossible d\'appliquer le code",
        ),
        "failedToCancel": MessageLookupByLibrary.simpleMessage(
          "Échec de l\'annulation",
        ),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
          "Échec du téléchargement de la vidéo",
        ),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
          "Impossible de récupérer les connexions actives",
        ),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
          "Impossible de récupérer l\'original pour l\'édition",
        ),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
          "Impossible de récupérer les détails du parrainage. Veuillez réessayer plus tard.",
        ),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
          "Impossible de charger les albums",
        ),
        "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
          "Impossible de lire la vidéo",
        ),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
          "Impossible de rafraîchir l\'abonnement",
        ),
        "failedToRenew": MessageLookupByLibrary.simpleMessage(
          "Échec du renouvellement",
        ),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
          "Échec de la vérification du statut du paiement",
        ),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
          "Ajoutez 5 membres de votre famille à votre abonnement existant sans payer de supplément.\n\nChaque membre dispose de son propre espace privé et ne peut pas voir les fichiers des autres membres, sauf s\'ils sont partagés.\n\nLes abonnement familiaux sont disponibles pour les clients qui ont un abonnement Ente payant.\n\nAbonnez-vous maintenant pour commencer !",
        ),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Famille"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Abonnements famille"),
        "faq": MessageLookupByLibrary.simpleMessage("FAQ"),
        "faqs": MessageLookupByLibrary.simpleMessage("FAQ"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favori"),
        "feastingWithThem": m34,
        "feedback": MessageLookupByLibrary.simpleMessage("Commentaires"),
        "file": MessageLookupByLibrary.simpleMessage("Fichier"),
        "fileAnalysisFailed": MessageLookupByLibrary.simpleMessage(
          "Impossible d\'analyser le fichier",
        ),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
          "Échec de l\'enregistrement dans la galerie",
        ),
        "fileInfoAddDescHint": MessageLookupByLibrary.simpleMessage(
          "Ajouter une description...",
        ),
        "fileNotUploadedYet": MessageLookupByLibrary.simpleMessage(
          "Le fichier n\'a pas encore été envoyé",
        ),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
          "Fichier enregistré dans la galerie",
        ),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Types de fichiers"),
        "fileTypesAndNames": MessageLookupByLibrary.simpleMessage(
          "Types et noms de fichiers",
        ),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Fichiers supprimés"),
        "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
          "Fichiers enregistrés dans la galerie",
        ),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
          "Trouver des personnes rapidement par leur nom",
        ),
        "findThemQuickly": MessageLookupByLibrary.simpleMessage(
          "Trouvez-les rapidement",
        ),
        "flip": MessageLookupByLibrary.simpleMessage("Retourner"),
        "food": MessageLookupByLibrary.simpleMessage("Plaisir culinaire"),
        "forYourMemories": MessageLookupByLibrary.simpleMessage(
          "pour vos souvenirs",
        ),
        "forgotPassword": MessageLookupByLibrary.simpleMessage(
          "Mot de passe oublié",
        ),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Visages trouvés"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
          "Stockage gratuit obtenu",
        ),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
          "Stockage gratuit disponible",
        ),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Essai gratuit"),
        "freeTrialValidTill": m38,
        "freeUpAccessPostDelete": m39,
        "freeUpAmount": m40,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
          "Libérer de l\'espace sur l\'appareil",
        ),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
          "Économisez de l\'espace sur votre appareil en effaçant les fichiers qui ont déjà été sauvegardés.",
        ),
        "freeUpSpace":
            MessageLookupByLibrary.simpleMessage("Libérer de l\'espace"),
        "freeUpSpaceSaving": m41,
        "gallery": MessageLookupByLibrary.simpleMessage("Galerie"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
          "Jusqu\'à 1000 souvenirs affichés dans la galerie",
        ),
        "general": MessageLookupByLibrary.simpleMessage("Général"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
          "Génération des clés de chiffrement...",
        ),
        "genericProgress": m42,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Allez aux réglages"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage(
          "Identifiant Google Play",
        ),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
          "Veuillez autoriser l’accès à toutes les photos dans les paramètres",
        ),
        "grantPermission": MessageLookupByLibrary.simpleMessage(
          "Accorder la permission",
        ),
        "greenery": MessageLookupByLibrary.simpleMessage("La vie au vert"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
          "Grouper les photos à proximité",
        ),
        "guestView": MessageLookupByLibrary.simpleMessage("Vue invité"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
          "Pour activer la vue invité, veuillez configurer le code d\'accès de l\'appareil ou le verrouillage de l\'écran dans les paramètres de votre système.",
        ),
        "happyBirthday": MessageLookupByLibrary.simpleMessage(
          "Joyeux anniversaire ! 🥳",
        ),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
          "Nous ne suivons pas les installations d\'applications. Il serait utile que vous nous disiez comment vous nous avez trouvés !",
        ),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
          "Comment avez-vous entendu parler de Ente? (facultatif)",
        ),
        "help": MessageLookupByLibrary.simpleMessage("Documentation"),
        "hidden": MessageLookupByLibrary.simpleMessage("Masqué"),
        "hide": MessageLookupByLibrary.simpleMessage("Masquer"),
        "hideContent":
            MessageLookupByLibrary.simpleMessage("Masquer le contenu"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
          "Masque le contenu de l\'application dans le sélecteur d\'applications et désactive les captures d\'écran",
        ),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
          "Masque le contenu de l\'application dans le sélecteur d\'application",
        ),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
          "Masquer les éléments partagés avec vous dans la galerie",
        ),
        "hiding": MessageLookupByLibrary.simpleMessage("Masquage en cours..."),
        "hikingWithThem": m43,
        "hostedAtOsmFrance": MessageLookupByLibrary.simpleMessage(
          "Hébergé chez OSM France",
        ),
        "howItWorks": MessageLookupByLibrary.simpleMessage(
          "Comment cela fonctionne",
        ),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
          "Demandez-leur d\'appuyer longuement sur leur adresse email dans l\'écran des paramètres pour vérifier que les identifiants des deux appareils correspondent.",
        ),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
          "L\'authentification biométrique n\'est pas configurée sur votre appareil. Veuillez activer Touch ID ou Face ID sur votre téléphone.",
        ),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
          "L\'authentification biométrique est désactivée. Veuillez verrouiller et déverrouiller votre écran pour l\'activer.",
        ),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("Ok"),
        "ignore": MessageLookupByLibrary.simpleMessage("Ignorer"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorer"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignoré"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
          "Certains fichiers de cet album sont ignorés parce qu\'ils avaient été précédemment supprimés de Ente.",
        ),
        "imageNotAnalyzed": MessageLookupByLibrary.simpleMessage(
          "Image non analysée",
        ),
        "immediately": MessageLookupByLibrary.simpleMessage("Immédiatement"),
        "importing": MessageLookupByLibrary.simpleMessage(
          "Importation en cours...",
        ),
        "incorrectCode":
            MessageLookupByLibrary.simpleMessage("Code non valide"),
        "incorrectPasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Mot de passe incorrect",
        ),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Clé de récupération non valide",
        ),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
          "La clé de secours que vous avez entrée est incorrecte",
        ),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
          "Clé de secours non valide",
        ),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Éléments indexés"),
        "indexingPausedStatusDescription": MessageLookupByLibrary.simpleMessage(
          "L\'indexation est en pause. Elle reprendra automatiquement lorsque l\'appareil sera prêt. Celui-ci est considéré comme prêt lorsque le niveau de batterie, sa santé et son état thermique sont dans une plage saine.",
        ),
        "ineligible": MessageLookupByLibrary.simpleMessage("Non compatible"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage(
          "Appareil non sécurisé",
        ),
        "installManually": MessageLookupByLibrary.simpleMessage(
          "Installation manuelle",
        ),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Adresse e-mail invalide",
        ),
        "invalidEndpoint": MessageLookupByLibrary.simpleMessage(
          "Point de terminaison non valide",
        ),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
          "Désolé, le point de terminaison que vous avez entré n\'est pas valide. Veuillez en entrer un valide puis réessayez.",
        ),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Clé invalide"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "La clé de récupération que vous avez saisie n\'est pas valide. Veuillez vérifier qu\'elle contient 24 caractères et qu\'ils sont correctement orthographiés.\n\nSi vous avez saisi un ancien code de récupération, veuillez vérifier qu\'il contient 64 caractères et qu\'ils sont correctement orthographiés.",
        ),
        "invite": MessageLookupByLibrary.simpleMessage("Inviter"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage(
          "Inviter à rejoindre Ente",
        ),
        "inviteYourFriends": MessageLookupByLibrary.simpleMessage(
          "Parrainez vos ami·e·s",
        ),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
          "Invitez vos ami·e·s sur Ente",
        ),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
          "Il semble qu\'une erreur s\'est produite. Veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter notre équipe d\'assistance.",
        ),
        "itemCount": m44,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
          "Les éléments montrent le nombre de jours restants avant la suppression définitive",
        ),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
          "Les éléments sélectionnés seront supprimés de cet album",
        ),
        "join": MessageLookupByLibrary.simpleMessage("Rejoindre"),
        "joinAlbum": MessageLookupByLibrary.simpleMessage("Rejoindre l\'album"),
        "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
          "Rejoindre un album rendra votre e-mail visible à ses participants.",
        ),
        "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
          "pour afficher et ajouter vos photos",
        ),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
          "pour ajouter ceci aux albums partagés",
        ),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Rejoindre Discord"),
        "keepPhotos":
            MessageLookupByLibrary.simpleMessage("Conserver les photos"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
          "Merci de nous aider avec cette information",
        ),
        "language": MessageLookupByLibrary.simpleMessage("Langue"),
        "lastTimeWithThem": m45,
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Dernière mise à jour"),
        "lastYearsTrip": MessageLookupByLibrary.simpleMessage(
          "Voyage de l\'an dernier",
        ),
        "leave": MessageLookupByLibrary.simpleMessage("Quitter"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Quitter l\'album"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage(
          "Quitter le plan familial",
        ),
        "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
          "Quitter l\'album partagé?",
        ),
        "left": MessageLookupByLibrary.simpleMessage("Gauche"),
        "legacy": MessageLookupByLibrary.simpleMessage("Héritage"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Comptes hérités"),
        "legacyInvite": m46,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
          "L\'héritage permet aux contacts de confiance d\'accéder à votre compte en votre absence.",
        ),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
          "Ces contacts peuvent initier la récupération du compte et, s\'ils ne sont pas bloqués dans les 30 jours qui suivent, peuvent réinitialiser votre mot de passe et accéder à votre compte.",
        ),
        "light": MessageLookupByLibrary.simpleMessage("Clair"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Clair"),
        "link": MessageLookupByLibrary.simpleMessage("Lier"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
          "Lien copié dans le presse-papiers",
        ),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage(
          "Limite d\'appareil",
        ),
        "linkEmail": MessageLookupByLibrary.simpleMessage("Lier l\'email"),
        "linkEmailToContactBannerCaption": MessageLookupByLibrary.simpleMessage(
          "pour un partage plus rapide",
        ),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Activé"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expiré"),
        "linkExpiresOn": m47,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Expiration du lien"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Le lien a expiré"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Jamais"),
        "linkPerson": MessageLookupByLibrary.simpleMessage("Lier la personne"),
        "linkPersonCaption": MessageLookupByLibrary.simpleMessage(
          "pour une meilleure expérience de partage",
        ),
        "linkPersonToEmail": m48,
        "linkPersonToEmailConfirmation": m49,
        "livePhotos": MessageLookupByLibrary.simpleMessage("Photos en direct"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
          "Vous pouvez partager votre abonnement avec votre famille",
        ),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
          "Nous avons préservé plus de 200 millions de souvenirs jusqu\'à présent",
        ),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
          "Nous conservons 3 copies de vos données, l\'une dans un abri anti-atomique",
        ),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
          "Toutes nos applications sont open source",
        ),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
          "Notre code source et notre cryptographie ont été audités en externe",
        ),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
          "Vous pouvez partager des liens vers vos albums avec vos proches",
        ),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
          "Nos applications mobiles s\'exécutent en arrière-plan pour chiffrer et sauvegarder automatiquement les nouvelles photos que vous prenez",
        ),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
          "web.ente.io dispose d\'un outil de téléchargement facile à utiliser",
        ),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
          "Nous utilisons Xchacha20Poly1305 pour chiffrer vos données en toute sécurité",
        ),
        "loadingExifData": MessageLookupByLibrary.simpleMessage(
          "Chargement des données EXIF...",
        ),
        "loadingGallery": MessageLookupByLibrary.simpleMessage(
          "Chargement de la galerie...",
        ),
        "loadingMessage": MessageLookupByLibrary.simpleMessage(
          "Chargement de vos photos...",
        ),
        "loadingModel": MessageLookupByLibrary.simpleMessage(
          "Téléchargement des modèles...",
        ),
        "loadingYourPhotos": MessageLookupByLibrary.simpleMessage(
          "Chargement de vos photos...",
        ),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galerie locale"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Indexation locale"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
          "Il semble que quelque chose s\'est mal passé car la synchronisation des photos locales prend plus de temps que prévu. Veuillez contacter notre équipe d\'assistance",
        ),
        "location": MessageLookupByLibrary.simpleMessage("Emplacement"),
        "locationName": MessageLookupByLibrary.simpleMessage("Nom du lieu"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
          "Un tag d\'emplacement regroupe toutes les photos qui ont été prises dans un certain rayon d\'une photo",
        ),
        "locations": MessageLookupByLibrary.simpleMessage("Emplacements"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Verrouiller"),
        "lockscreen":
            MessageLookupByLibrary.simpleMessage("Écran de verrouillage"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Se connecter"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Deconnexion..."),
        "loginSessionExpired": MessageLookupByLibrary.simpleMessage(
          "Session expirée",
        ),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
          "Votre session a expiré. Veuillez vous reconnecter.",
        ),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
          "En cliquant sur connecter, j\'accepte les <u-terms>conditions d\'utilisation</u-terms> et la <u-policy>politique de confidentialité</u-policy>",
        ),
        "loginWithTOTP": MessageLookupByLibrary.simpleMessage(
          "Se connecter avec TOTP",
        ),
        "logout": MessageLookupByLibrary.simpleMessage("Déconnexion"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
          "Les journaux seront envoyés pour nous aider à déboguer votre problème. Les noms de fichiers seront inclus pour aider à identifier les problèmes.",
        ),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
          "Appuyez longuement sur un email pour vérifier le chiffrement de bout en bout.",
        ),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
          "Appuyez longuement sur un élément pour le voir en plein écran",
        ),
        "lookBackOnYourMemories": MessageLookupByLibrary.simpleMessage(
          "Regarde tes souvenirs passés 🌄",
        ),
        "loopVideoOff": MessageLookupByLibrary.simpleMessage(
          "Vidéo en boucle désactivée",
        ),
        "loopVideoOn": MessageLookupByLibrary.simpleMessage(
          "Vidéo en boucle activée",
        ),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Appareil perdu ?"),
        "machineLearning": MessageLookupByLibrary.simpleMessage(
          "Apprentissage automatique (IA locale)",
        ),
        "magicSearch":
            MessageLookupByLibrary.simpleMessage("Recherche magique"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
          "La recherche magique permet de rechercher des photos par leur contenu, par exemple \'fleur\', \'voiture rouge\', \'documents d\'identité\'",
        ),
        "manage": MessageLookupByLibrary.simpleMessage("Gérer"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
          "Gérer le cache de l\'appareil",
        ),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
          "Examiner et vider le cache.",
        ),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Gérer la famille"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Gérer le lien"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Gérer"),
        "manageSubscription": MessageLookupByLibrary.simpleMessage(
          "Gérer l\'abonnement",
        ),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
          "L\'appairage avec le code PIN fonctionne avec n\'importe quel écran sur lequel vous souhaitez voir votre album.",
        ),
        "map": MessageLookupByLibrary.simpleMessage("Carte"),
        "maps": MessageLookupByLibrary.simpleMessage("Carte"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "me": MessageLookupByLibrary.simpleMessage("Moi"),
        "memories": MessageLookupByLibrary.simpleMessage("Souvenirs"),
        "memoriesWidgetDesc": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez le type de souvenirs que vous souhaitez voir sur votre écran d\'accueil.",
        ),
        "memoryCount": m50,
        "merchandise": MessageLookupByLibrary.simpleMessage("Boutique"),
        "merge": MessageLookupByLibrary.simpleMessage("Fusionner"),
        "mergeWithExisting": MessageLookupByLibrary.simpleMessage(
          "Fusionner avec existant",
        ),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Photos fusionnées"),
        "mlConsent": MessageLookupByLibrary.simpleMessage(
          "Activer l\'apprentissage automatique",
        ),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
          "Je comprends et je souhaite activer l\'apprentissage automatique",
        ),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
          "Si vous activez l\'apprentissage automatique Ente extraira des informations comme la géométrie des visages, y compris dans les photos partagées avec vous. \nCela se fera localement sur votre appareil et avec un chiffrement bout-en-bout de toutes les données biométriques générées.",
        ),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
          "Veuillez cliquer ici pour plus de détails sur cette fonctionnalité dans notre politique de confidentialité",
        ),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
          "Activer l\'apprentissage automatique ?",
        ),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
          "Veuillez noter que l\'apprentissage automatique entraînera une augmentation de l\'utilisation de la connexion Internet et de la batterie jusqu\'à ce que tous les souvenirs soient indexés. \nVous pouvez utiliser l\'application de bureau Ente pour accélérer cette étape, tous les résultats seront synchronisés.",
        ),
        "mobileWebDesktop": MessageLookupByLibrary.simpleMessage(
          "Mobile, Web, Ordinateur",
        ),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moyen"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
          "Modifiez votre requête, ou essayez de rechercher",
        ),
        "moments": MessageLookupByLibrary.simpleMessage("Souvenirs"),
        "month": MessageLookupByLibrary.simpleMessage("mois"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensuel"),
        "moon": MessageLookupByLibrary.simpleMessage("Au clair de lune"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Plus de détails"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Les plus récents"),
        "mostRelevant":
            MessageLookupByLibrary.simpleMessage("Les plus pertinents"),
        "mountains":
            MessageLookupByLibrary.simpleMessage("Au-dessus des collines"),
        "moveItem": m51,
        "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
          "Déplacer les photos sélectionnées vers une date",
        ),
        "moveToAlbum": MessageLookupByLibrary.simpleMessage(
          "Déplacer vers l\'album",
        ),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
          "Déplacer vers un album masqué",
        ),
        "movedSuccessfullyTo": m52,
        "movedToTrash": MessageLookupByLibrary.simpleMessage(
          "Déplacé dans la corbeille",
        ),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
          "Déplacement des fichiers vers l\'album...",
        ),
        "name": MessageLookupByLibrary.simpleMessage("Nom"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Nommez l\'album"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
          "Impossible de se connecter à Ente, veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter le support.",
        ),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
          "Impossible de se connecter à Ente, veuillez vérifier vos paramètres réseau et contacter le support si l\'erreur persiste.",
        ),
        "never": MessageLookupByLibrary.simpleMessage("Jamais"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nouvel album"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Nouveau lieu"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Nouvelle personne"),
        "newPhotosEmoji": MessageLookupByLibrary.simpleMessage(" nouveau 📸"),
        "newRange": MessageLookupByLibrary.simpleMessage("Nouvelle plage"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Nouveau sur Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Le plus récent"),
        "next": MessageLookupByLibrary.simpleMessage("Suivant"),
        "no": MessageLookupByLibrary.simpleMessage("Non"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
          "Aucun album que vous avez partagé",
        ),
        "noDeviceFound": MessageLookupByLibrary.simpleMessage(
          "Aucun appareil trouvé",
        ),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Aucune"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
          "Vous n\'avez pas de fichiers sur cet appareil qui peuvent être supprimés",
        ),
        "noDuplicates": MessageLookupByLibrary.simpleMessage("✨ Aucun doublon"),
        "noEnteAccountExclamation": MessageLookupByLibrary.simpleMessage(
          "Aucun compte Ente !",
        ),
        "noExifData":
            MessageLookupByLibrary.simpleMessage("Aucune donnée EXIF"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage(
          "Aucun visage détecté",
        ),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
          "Aucune photo ou vidéo masquée",
        ),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
          "Aucune image avec localisation",
        ),
        "noInternetConnection": MessageLookupByLibrary.simpleMessage(
          "Aucune connexion internet",
        ),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
          "Aucune photo en cours de sauvegarde",
        ),
        "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage(
          "Aucune photo trouvée",
        ),
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
          "Aucun lien rapide sélectionné",
        ),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Aucune clé de récupération ?",
        ),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
          "En raison de notre protocole de chiffrement de bout en bout, vos données ne peuvent pas être déchiffré sans votre mot de passe ou clé de récupération",
        ),
        "noResults": MessageLookupByLibrary.simpleMessage("Aucun résultat"),
        "noResultsFound": MessageLookupByLibrary.simpleMessage(
          "Aucun résultat trouvé",
        ),
        "noSuggestionsForPerson": m53,
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
          "Aucun verrou système trouvé",
        ),
        "notPersonLabel": m54,
        "notThisPerson": MessageLookupByLibrary.simpleMessage(
          "Ce n\'est pas cette personne ?",
        ),
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
          "Rien n\'a encore été partagé avec vous",
        ),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
          "Il n\'y a encore rien à voir ici 👀",
        ),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Sur votre appareil"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
          "Sur <branding>Ente</branding>",
        ),
        "onTheRoad": MessageLookupByLibrary.simpleMessage(
          "De nouveau sur la route",
        ),
        "onThisDay": MessageLookupByLibrary.simpleMessage("Ce jour-ci"),
        "onThisDayMemories": MessageLookupByLibrary.simpleMessage(
          "Souvenirs du jour",
        ),
        "onThisDayNotificationExplanation":
            MessageLookupByLibrary.simpleMessage(
          "Recevoir des rappels sur les souvenirs de cette journée des années précédentes.",
        ),
        "onlyFamilyAdminCanChangeCode": m55,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Seulement eux"),
        "oops": MessageLookupByLibrary.simpleMessage("Oups"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
          "Oups, impossible d\'enregistrer les modifications",
        ),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
          "Oups, une erreur est arrivée",
        ),
        "openAlbumInBrowser": MessageLookupByLibrary.simpleMessage(
          "Ouvrir l\'album dans le navigateur",
        ),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
          "Veuillez utiliser l\'application web pour ajouter des photos à cet album",
        ),
        "openFile": MessageLookupByLibrary.simpleMessage("Ouvrir le fichier"),
        "openSettings": MessageLookupByLibrary.simpleMessage(
          "Ouvrir les paramètres",
        ),
        "openTheItem":
            MessageLookupByLibrary.simpleMessage("• Ouvrir l\'élément"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
          "Contributeurs d\'OpenStreetMap",
        ),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
          "Optionnel, aussi court que vous le souhaitez...",
        ),
        "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
          "Ou fusionner avec une personne existante",
        ),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
          "Ou sélectionner un email existant",
        ),
        "orPickFromYourContacts": MessageLookupByLibrary.simpleMessage(
          "ou choisissez parmi vos contacts",
        ),
        "otherDetectedFaces": MessageLookupByLibrary.simpleMessage(
          "Autres visages détectés",
        ),
        "pair": MessageLookupByLibrary.simpleMessage("Associer"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage(
          "Appairer avec le code PIN",
        ),
        "pairingComplete": MessageLookupByLibrary.simpleMessage(
          "Appairage terminé",
        ),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "partyWithThem": m56,
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
          "La vérification est toujours en attente",
        ),
        "passkey": MessageLookupByLibrary.simpleMessage(
          "Authentification à deux facteurs avec une clé de sécurité",
        ),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
          "Vérification de la clé de sécurité",
        ),
        "password": MessageLookupByLibrary.simpleMessage("Mot de passe"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
          "Le mot de passe a été modifié",
        ),
        "passwordLock": MessageLookupByLibrary.simpleMessage(
          "Verrouillage par mot de passe",
        ),
        "passwordStrength": m57,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
          "La force du mot de passe est calculée en tenant compte de la longueur du mot de passe, des caractères utilisés et du fait que le mot de passe figure ou non parmi les 10 000 mots de passe les plus utilisés",
        ),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
          "Nous ne stockons pas ce mot de passe, donc si vous l\'oubliez, <underline>nous ne pouvons pas déchiffrer vos données</underline>",
        ),
        "pastYearsMemories": MessageLookupByLibrary.simpleMessage(
          "Souvenirs de ces dernières années",
        ),
        "paymentDetails": MessageLookupByLibrary.simpleMessage(
          "Détails de paiement",
        ),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Échec du paiement"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
          "Malheureusement votre paiement a échoué. Veuillez contacter le support et nous vous aiderons !",
        ),
        "paymentFailedTalkToProvider": m58,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Éléments en attente"),
        "pendingSync": MessageLookupByLibrary.simpleMessage(
          "Synchronisation en attente",
        ),
        "people": MessageLookupByLibrary.simpleMessage("Personnes"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
          "Filleul·e·s utilisant votre code",
        ),
        "peopleWidgetDesc": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez les personnes que vous souhaitez voir sur votre écran d\'accueil.",
        ),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
          "Tous les éléments de la corbeille seront définitivement supprimés\n\nCette action ne peut pas être annulée",
        ),
        "permanentlyDelete": MessageLookupByLibrary.simpleMessage(
          "Supprimer définitivement",
        ),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
          "Supprimer définitivement de l\'appareil ?",
        ),
        "personIsAge": m59,
        "personName":
            MessageLookupByLibrary.simpleMessage("Nom de la personne"),
        "personTurningAge": m60,
        "pets":
            MessageLookupByLibrary.simpleMessage("Compagnons à quatre pattes"),
        "photoDescriptions": MessageLookupByLibrary.simpleMessage(
          "Descriptions de la photo",
        ),
        "photoGridSize": MessageLookupByLibrary.simpleMessage(
          "Taille de la grille photo",
        ),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("photo"),
        "photocountPhotos": m61,
        "photos": MessageLookupByLibrary.simpleMessage("Photos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
          "Les photos ajoutées par vous seront retirées de l\'album",
        ),
        "photosCount": m62,
        "photosKeepRelativeTimeDifference":
            MessageLookupByLibrary.simpleMessage(
          "Les photos gardent une différence de temps relative",
        ),
        "pickCenterPoint": MessageLookupByLibrary.simpleMessage(
          "Sélectionner le point central",
        ),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Épingler l\'album"),
        "pinLock": MessageLookupByLibrary.simpleMessage(
          "Verrouillage par code PIN",
        ),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Lire l\'album sur la TV"),
        "playOriginal":
            MessageLookupByLibrary.simpleMessage("Lire l\'original"),
        "playStoreFreeTrialValidTill": m63,
        "playStream": MessageLookupByLibrary.simpleMessage("Lire le stream"),
        "playstoreSubscription": MessageLookupByLibrary.simpleMessage(
          "Abonnement au PlayStore",
        ),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "S\'il vous plaît, vérifiez votre connexion à internet et réessayez.",
        ),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
          "Veuillez contacter support@ente.io et nous serons heureux de vous aider!",
        ),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
          "Merci de contacter l\'assistance si cette erreur persiste",
        ),
        "pleaseEmailUsAt": m64,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
          "Veuillez accorder la permission",
        ),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
          "Veuillez vous reconnecter",
        ),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
          "Veuillez sélectionner les liens rapides à supprimer",
        ),
        "pleaseSendTheLogsTo": m65,
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage(
          "Veuillez réessayer",
        ),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
          "Veuillez vérifier le code que vous avez entré",
        ),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Veuillez patienter..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
          "Veuillez patienter, suppression de l\'album",
        ),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
          "Veuillez attendre quelque temps avant de réessayer",
        ),
        "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
          "Veuillez patienter, cela prendra un peu de temps.",
        ),
        "posingWithThem": m66,
        "preparingLogs": MessageLookupByLibrary.simpleMessage(
          "Préparation des journaux...",
        ),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Conserver plus"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
          "Appuyez et maintenez enfoncé pour lire la vidéo",
        ),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
          "Maintenez appuyé sur l\'image pour lire la vidéo",
        ),
        "previous": MessageLookupByLibrary.simpleMessage("Précédent"),
        "privacy": MessageLookupByLibrary.simpleMessage(
          "Politique de confidentialité",
        ),
        "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
          "Politique de Confidentialité",
        ),
        "privateBackups": MessageLookupByLibrary.simpleMessage(
          "Sauvegardes privées",
        ),
        "privateSharing": MessageLookupByLibrary.simpleMessage("Partage privé"),
        "proceed": MessageLookupByLibrary.simpleMessage("Procéder"),
        "processed": MessageLookupByLibrary.simpleMessage("Appris"),
        "processing":
            MessageLookupByLibrary.simpleMessage("Traitement en cours"),
        "processingImport": m67,
        "processingVideos": MessageLookupByLibrary.simpleMessage(
          "Traitement des vidéos",
        ),
        "publicLinkCreated": MessageLookupByLibrary.simpleMessage(
          "Lien public créé",
        ),
        "publicLinkEnabled": MessageLookupByLibrary.simpleMessage(
          "Lien public activé",
        ),
        "questionmark": MessageLookupByLibrary.simpleMessage("?"),
        "queued": MessageLookupByLibrary.simpleMessage("En file d\'attente"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Liens rapides"),
        "radius": MessageLookupByLibrary.simpleMessage("Rayon"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Créer un ticket"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage(
          "Évaluer l\'application",
        ),
        "rateUs": MessageLookupByLibrary.simpleMessage("Évaluez-nous"),
        "rateUsOnStore": m68,
        "reassignMe":
            MessageLookupByLibrary.simpleMessage("Réassigner \"Moi\""),
        "reassignedToName": m69,
        "reassigningLoading": MessageLookupByLibrary.simpleMessage(
          "Réassignation...",
        ),
        "receiveRemindersOnBirthdays": MessageLookupByLibrary.simpleMessage(
          "Recevoir des rappels quand c\'est l\'anniversaire de quelqu\'un. Appuyer sur la notification vous amènera à des photos de son anniversaire.",
        ),
        "recover": MessageLookupByLibrary.simpleMessage("Récupérer"),
        "recoverAccount": MessageLookupByLibrary.simpleMessage(
          "Récupérer un compte",
        ),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Restaurer"),
        "recoveryAccount": MessageLookupByLibrary.simpleMessage(
          "Récupérer un compte",
        ),
        "recoveryInitiated": MessageLookupByLibrary.simpleMessage(
          "Récupération initiée",
        ),
        "recoveryInitiatedDesc": m70,
        "recoveryKey": MessageLookupByLibrary.simpleMessage("Clé de secours"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
          "Clé de secours copiée dans le presse-papiers",
        ),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
          "Si vous oubliez votre mot de passe, la seule façon de récupérer vos données sera grâce à cette clé.",
        ),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
          "Nous ne la stockons pas, veuillez la conserver en lieu endroit sûr.",
        ),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
          "Génial ! Votre clé de récupération est valide. Merci de votre vérification.\n\nN\'oubliez pas de garder votre clé de récupération sauvegardée.",
        ),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
          "Clé de récupération vérifiée",
        ),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
          "Votre clé de récupération est la seule façon de récupérer vos photos si vous oubliez votre mot de passe. Vous pouvez trouver votre clé de récupération dans Paramètres > Compte.\n\nVeuillez saisir votre clé de récupération ici pour vous assurer de l\'avoir enregistré correctement.",
        ),
        "recoveryReady": m71,
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
          "Restauration réussie !",
        ),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
          "Un contact de confiance tente d\'accéder à votre compte",
        ),
        "recoveryWarningBody": m72,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
          "L\'appareil actuel n\'est pas assez puissant pour vérifier votre mot de passe, mais nous pouvons le régénérer d\'une manière qui fonctionne avec tous les appareils.\n\nVeuillez vous connecter à l\'aide de votre clé de secours et régénérer votre mot de passe (vous pouvez réutiliser le même si vous le souhaitez).",
        ),
        "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Recréer le mot de passe",
        ),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword": MessageLookupByLibrary.simpleMessage(
          "Ressaisir le mot de passe",
        ),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("Ressaisir le code PIN"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
          "Parrainez vos ami·e·s et doublez votre stockage",
        ),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
          "1. Donnez ce code à vos ami·e·s",
        ),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
          "2. Ils souscrivent à une offre payante",
        ),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("Parrainages"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
          "Les recommandations sont actuellement en pause",
        ),
        "rejectRecovery": MessageLookupByLibrary.simpleMessage(
          "Rejeter la récupération",
        ),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
          "Également vide \"récemment supprimé\" de \"Paramètres\" -> \"Stockage\" pour réclamer l\'espace libéré",
        ),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
          "Vide aussi votre \"Corbeille\" pour réclamer l\'espace libéré",
        ),
        "remoteImages":
            MessageLookupByLibrary.simpleMessage("Images distantes"),
        "remoteThumbnails": MessageLookupByLibrary.simpleMessage(
          "Miniatures distantes",
        ),
        "remoteVideos":
            MessageLookupByLibrary.simpleMessage("Vidéos distantes"),
        "remove": MessageLookupByLibrary.simpleMessage("Supprimer"),
        "removeDuplicates": MessageLookupByLibrary.simpleMessage(
          "Supprimer les doublons",
        ),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
          "Examinez et supprimez les fichiers étant des doublons exacts.",
        ),
        "removeFromAlbum": MessageLookupByLibrary.simpleMessage(
          "Retirer de l\'album",
        ),
        "removeFromAlbumTitle": MessageLookupByLibrary.simpleMessage(
          "Retirer de l\'album ?",
        ),
        "removeFromFavorite": MessageLookupByLibrary.simpleMessage(
          "Retirer des favoris",
        ),
        "removeInvite": MessageLookupByLibrary.simpleMessage(
          "Supprimer l’Invitation",
        ),
        "removeLink": MessageLookupByLibrary.simpleMessage("Supprimer le lien"),
        "removeParticipant": MessageLookupByLibrary.simpleMessage(
          "Supprimer le participant",
        ),
        "removeParticipantBody": m74,
        "removePersonLabel": MessageLookupByLibrary.simpleMessage(
          "Supprimer le libellé d\'une personne",
        ),
        "removePublicLink": MessageLookupByLibrary.simpleMessage(
          "Supprimer le lien public",
        ),
        "removePublicLinks": MessageLookupByLibrary.simpleMessage(
          "Supprimer les liens publics",
        ),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
          "Certains des éléments que vous êtes en train de retirer ont été ajoutés par d\'autres personnes, vous perdrez l\'accès vers ces éléments",
        ),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Enlever?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
          "Retirez-vous comme contact de confiance",
        ),
        "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
          "Suppression des favoris…",
        ),
        "rename": MessageLookupByLibrary.simpleMessage("Renommer"),
        "renameAlbum":
            MessageLookupByLibrary.simpleMessage("Renommer l\'album"),
        "renameFile":
            MessageLookupByLibrary.simpleMessage("Renommer le fichier"),
        "renewSubscription": MessageLookupByLibrary.simpleMessage(
          "Renouveler l’abonnement",
        ),
        "renewsOn": m75,
        "reportABug": MessageLookupByLibrary.simpleMessage("Signaler un bogue"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Signaler un bogue"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Renvoyer l\'email"),
        "reset": MessageLookupByLibrary.simpleMessage("Réinitialiser"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
          "Réinitialiser les fichiers ignorés",
        ),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Réinitialiser le mot de passe",
        ),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Réinitialiser"),
        "resetToDefault": MessageLookupByLibrary.simpleMessage(
          "Réinitialiser aux valeurs par défaut",
        ),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurer"),
        "restoreToAlbum": MessageLookupByLibrary.simpleMessage(
          "Restaurer vers l\'album",
        ),
        "restoringFiles": MessageLookupByLibrary.simpleMessage(
          "Restauration des fichiers...",
        ),
        "resumableUploads": MessageLookupByLibrary.simpleMessage(
          "Reprise automatique des transferts",
        ),
        "retry": MessageLookupByLibrary.simpleMessage("Réessayer"),
        "review": MessageLookupByLibrary.simpleMessage("Suggestions"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
          "Veuillez vérifier et supprimer les éléments que vous croyez dupliqués.",
        ),
        "reviewSuggestions": MessageLookupByLibrary.simpleMessage(
          "Examiner les suggestions",
        ),
        "right": MessageLookupByLibrary.simpleMessage("Droite"),
        "roadtripWithThem": m76,
        "rotate": MessageLookupByLibrary.simpleMessage("Pivoter"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Pivoter à gauche"),
        "rotateRight": MessageLookupByLibrary.simpleMessage(
          "Faire pivoter à droite",
        ),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Stockage sécurisé"),
        "same": MessageLookupByLibrary.simpleMessage("Identique"),
        "sameperson": MessageLookupByLibrary.simpleMessage("Même personne ?"),
        "save": MessageLookupByLibrary.simpleMessage("Sauvegarder"),
        "saveAsAnotherPerson": MessageLookupByLibrary.simpleMessage(
          "Enregistrer comme une autre personne",
        ),
        "saveChangesBeforeLeavingQuestion":
            MessageLookupByLibrary.simpleMessage(
          "Enregistrer les modifications avant de quitter ?",
        ),
        "saveCollage": MessageLookupByLibrary.simpleMessage(
          "Enregistrer le collage",
        ),
        "saveCopy":
            MessageLookupByLibrary.simpleMessage("Enregistrer une copie"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Enregistrer la clé"),
        "savePerson": MessageLookupByLibrary.simpleMessage(
          "Enregistrer la personne",
        ),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
          "Enregistrez votre clé de récupération si vous ne l\'avez pas déjà fait",
        ),
        "saving": MessageLookupByLibrary.simpleMessage("Enregistrement..."),
        "savingEdits": MessageLookupByLibrary.simpleMessage(
          "Enregistrement des modifications...",
        ),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scanner le code"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Scannez ce code-barres avec\nvotre application d\'authentification",
        ),
        "search": MessageLookupByLibrary.simpleMessage("Rechercher"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Albums"),
        "searchByAlbumNameHint": MessageLookupByLibrary.simpleMessage(
          "Nom de l\'album",
        ),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
          "• Noms d\'albums (par exemple \"Caméra\")\n• Types de fichiers (par exemple \"Vidéos\", \".gif\")\n• Années et mois (par exemple \"2022\", \"Janvier\")\n• Vacances (par exemple \"Noël\")\n• Descriptions de photos (par exemple \"#fun\")",
        ),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
          "Ajoutez des descriptions comme \"#trip\" dans les infos photo pour les retrouver ici plus rapidement",
        ),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
          "Recherche par date, mois ou année",
        ),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
          "Les images seront affichées ici une fois le traitement terminé",
        ),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
          "Les personnes seront affichées ici une fois l\'indexation terminée",
        ),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage(
          "Types et noms de fichiers",
        ),
        "searchHint1": MessageLookupByLibrary.simpleMessage(
          "Recherche rapide, sur l\'appareil",
        ),
        "searchHint2": MessageLookupByLibrary.simpleMessage(
          "Dates des photos, descriptions",
        ),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
          "Albums, noms de fichiers et types",
        ),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Emplacement"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
          "Bientôt: Visages & recherche magique ✨",
        ),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
          "Grouper les photos qui sont prises dans un certain angle d\'une photo",
        ),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
          "Invitez quelqu\'un·e et vous verrez ici toutes les photos partagées",
        ),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
          "Les personnes seront affichées ici une fois le traitement terminé",
        ),
        "searchResultCount": m77,
        "searchSectionsLengthMismatch": m78,
        "security": MessageLookupByLibrary.simpleMessage("Sécurité"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
          "Ouvrir les liens des albums publics dans l\'application",
        ),
        "selectALocation": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez un emplacement",
        ),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez d\'abord un emplacement",
        ),
        "selectAlbum":
            MessageLookupByLibrary.simpleMessage("Sélectionner album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Tout sélectionner"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Tout"),
        "selectCoverPhoto": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez la photo de couverture",
        ),
        "selectDate":
            MessageLookupByLibrary.simpleMessage("Sélectionner la date"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
          "Dossiers à sauvegarder",
        ),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
          "Sélectionner les éléments à ajouter",
        ),
        "selectLanguage": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez une langue",
        ),
        "selectMailApp": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez l\'application mail",
        ),
        "selectMorePhotos": MessageLookupByLibrary.simpleMessage(
          "Sélectionner plus de photos",
        ),
        "selectOneDateAndTime": MessageLookupByLibrary.simpleMessage(
          "Sélectionner une date et une heure",
        ),
        "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez une date et une heure pour tous",
        ),
        "selectPersonToLink": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez la personne à associer",
        ),
        "selectReason": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez une raison",
        ),
        "selectStartOfRange": MessageLookupByLibrary.simpleMessage(
          "Sélectionner le début de la plage",
        ),
        "selectTime":
            MessageLookupByLibrary.simpleMessage("Sélectionner l\'heure"),
        "selectYourFace": MessageLookupByLibrary.simpleMessage(
          "Sélectionnez votre visage",
        ),
        "selectYourPlan": MessageLookupByLibrary.simpleMessage(
          "Sélectionner votre offre",
        ),
        "selectedAlbums": m79,
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
          "Les fichiers sélectionnés ne sont pas sur Ente",
        ),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
          "Les dossiers sélectionnés seront chiffrés et sauvegardés",
        ),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
          "Les éléments sélectionnés seront supprimés de tous les albums et déplacés dans la corbeille.",
        ),
        "selectedItemsWillBeRemovedFromThisPerson":
            MessageLookupByLibrary.simpleMessage(
          "Les éléments sélectionnés seront retirés de cette personne, mais pas supprimés de votre bibliothèque.",
        ),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "selfiesWithThem": m82,
        "send": MessageLookupByLibrary.simpleMessage("Envoyer"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Envoyer un e-mail"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Envoyer Invitations"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Envoyer le lien"),
        "serverEndpoint": MessageLookupByLibrary.simpleMessage(
          "Point de terminaison serveur",
        ),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expirée"),
        "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
          "Incompatibilité de l\'ID de session",
        ),
        "setAPassword": MessageLookupByLibrary.simpleMessage(
          "Définir un mot de passe",
        ),
        "setAs": MessageLookupByLibrary.simpleMessage("Définir comme"),
        "setCover":
            MessageLookupByLibrary.simpleMessage("Définir la couverture"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Définir"),
        "setNewPassword": MessageLookupByLibrary.simpleMessage(
          "Définir un nouveau mot de passe",
        ),
        "setNewPin": MessageLookupByLibrary.simpleMessage(
          "Définir un nouveau code PIN",
        ),
        "setPasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Définir le mot de passe",
        ),
        "setRadius": MessageLookupByLibrary.simpleMessage("Définir le rayon"),
        "setupComplete": MessageLookupByLibrary.simpleMessage(
          "Configuration terminée",
        ),
        "share": MessageLookupByLibrary.simpleMessage("Partager"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Partager le lien"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
          "Ouvrez un album et appuyez sur le bouton de partage en haut à droite pour le partager.",
        ),
        "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage(
          "Partagez un album maintenant",
        ),
        "shareLink": MessageLookupByLibrary.simpleMessage("Partager le lien"),
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
          "Partagez uniquement avec les personnes que vous souhaitez",
        ),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
          "Téléchargez Ente pour pouvoir facilement partager des photos et vidéos en qualité originale\n\nhttps://ente.io",
        ),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
          "Partager avec des utilisateurs non-Ente",
        ),
        "shareWithPeopleSectionTitle": m86,
        "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
          "Partagez votre premier album",
        ),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
          "Créez des albums partagés et collaboratifs avec d\'autres utilisateurs de Ente, y compris des utilisateurs ayant des plans gratuits.",
        ),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Partagé par moi"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Partagé par vous"),
        "sharedPhotoNotifications": MessageLookupByLibrary.simpleMessage(
          "Nouvelles photos partagées",
        ),
        "sharedPhotoNotificationsExplanation":
            MessageLookupByLibrary.simpleMessage(
          "Recevoir des notifications quand quelqu\'un·e ajoute une photo à un album partagé dont vous faites partie",
        ),
        "sharedWith": m87,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Partagés avec moi"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Partagé avec vous"),
        "sharing": MessageLookupByLibrary.simpleMessage("Partage..."),
        "shiftDatesAndTime": MessageLookupByLibrary.simpleMessage(
          "Dates et heure de décalage",
        ),
        "showLessFaces": MessageLookupByLibrary.simpleMessage(
          "Afficher moins de visages",
        ),
        "showMemories": MessageLookupByLibrary.simpleMessage(
          "Afficher les souvenirs",
        ),
        "showMoreFaces": MessageLookupByLibrary.simpleMessage(
          "Afficher plus de visages",
        ),
        "showPerson":
            MessageLookupByLibrary.simpleMessage("Montrer la personne"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
          "Se déconnecter d\'autres appareils",
        ),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
          "Si vous pensez que quelqu\'un peut connaître votre mot de passe, vous pouvez forcer tous les autres appareils utilisant votre compte à se déconnecter.",
        ),
        "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
          "Déconnecter les autres appareils",
        ),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
          "J\'accepte les <u-terms>conditions d\'utilisation</u-terms> et la <u-policy>politique de confidentialité</u-policy>",
        ),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
          "Elle sera supprimée de tous les albums.",
        ),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("Ignorer"),
        "smartMemories": MessageLookupByLibrary.simpleMessage(
          "Souvenirs intelligents",
        ),
        "social": MessageLookupByLibrary.simpleMessage("Retrouvez nous"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
          "Certains éléments sont à la fois sur Ente et votre appareil.",
        ),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
          "Certains des fichiers que vous essayez de supprimer ne sont disponibles que sur votre appareil et ne peuvent pas être récupérés s\'ils sont supprimés",
        ),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
          "Quelqu\'un qui partage des albums avec vous devrait voir le même ID sur son appareil.",
        ),
        "somethingWentWrong": MessageLookupByLibrary.simpleMessage(
          "Un problème est survenu",
        ),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "Quelque chose s\'est mal passé, veuillez recommencer",
        ),
        "sorry": MessageLookupByLibrary.simpleMessage("Désolé"),
        "sorryBackupFailedDesc": MessageLookupByLibrary.simpleMessage(
          "Désolé, nous n\'avons pas pu sauvegarder ce fichier maintenant, nous allons réessayer plus tard.",
        ),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
          "Désolé, impossible d\'ajouter aux favoris !",
        ),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
          "Désolé, impossible de supprimer des favoris !",
        ),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
          "Le code que vous avez saisi est incorrect",
        ),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
          "Désolé, nous n\'avons pas pu générer de clés sécurisées sur cet appareil.\n\nVeuillez vous inscrire depuis un autre appareil.",
        ),
        "sorryWeHadToPauseYourBackups": MessageLookupByLibrary.simpleMessage(
          "Désolé, nous avons dû mettre en pause vos sauvegardes",
        ),
        "sort": MessageLookupByLibrary.simpleMessage("Trier"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Trier par"),
        "sortNewestFirst": MessageLookupByLibrary.simpleMessage(
          "Plus récent en premier",
        ),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage(
          "Plus ancien en premier",
        ),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Succès"),
        "sportsWithThem": m91,
        "spotlightOnThem": m92,
        "spotlightOnYourself": MessageLookupByLibrary.simpleMessage(
          "Éclairage sur vous-même",
        ),
        "startAccountRecoveryTitle": MessageLookupByLibrary.simpleMessage(
          "Démarrer la récupération",
        ),
        "startBackup": MessageLookupByLibrary.simpleMessage(
          "Démarrer la sauvegarde",
        ),
        "status": MessageLookupByLibrary.simpleMessage("État"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
          "Voulez-vous arrêter la diffusion ?",
        ),
        "stopCastingTitle": MessageLookupByLibrary.simpleMessage(
          "Arrêter la diffusion",
        ),
        "storage": MessageLookupByLibrary.simpleMessage("Stockage"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Famille"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Vous"),
        "storageInGB": m93,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
          "Limite de stockage atteinte",
        ),
        "storageUsageInfo": m94,
        "streamDetails":
            MessageLookupByLibrary.simpleMessage("Détails du stream"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Forte"),
        "subAlreadyLinkedErrMessage": m95,
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("S\'abonner"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
          "Vous avez besoin d\'un abonnement payant actif pour activer le partage.",
        ),
        "subscription": MessageLookupByLibrary.simpleMessage("Abonnement"),
        "success": MessageLookupByLibrary.simpleMessage("Succès"),
        "successfullyArchived": MessageLookupByLibrary.simpleMessage(
          "Archivé avec succès",
        ),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Masquage réussi"),
        "successfullyUnarchived": MessageLookupByLibrary.simpleMessage(
          "Désarchivé avec succès",
        ),
        "successfullyUnhid": MessageLookupByLibrary.simpleMessage(
          "Masquage réussi",
        ),
        "suggestFeatures": MessageLookupByLibrary.simpleMessage(
          "Suggérer une fonctionnalité",
        ),
        "sunrise": MessageLookupByLibrary.simpleMessage("À l\'horizon"),
        "support": MessageLookupByLibrary.simpleMessage("Support"),
        "syncProgress": m97,
        "syncStopped": MessageLookupByLibrary.simpleMessage(
          "Synchronisation arrêtée ?",
        ),
        "syncing": MessageLookupByLibrary.simpleMessage(
          "En cours de synchronisation...",
        ),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Système"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("taper pour copier"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
          "Appuyez pour entrer le code",
        ),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage(
          "Appuyer pour déverrouiller",
        ),
        "tapToUpload":
            MessageLookupByLibrary.simpleMessage("Appuyer pour envoyer"),
        "tapToUploadIsIgnoredDue": m98,
        "tempErrorContactSupportIfPersists":
            MessageLookupByLibrary.simpleMessage(
          "Il semble qu\'une erreur s\'est produite. Veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter notre équipe d\'assistance.",
        ),
        "terminate": MessageLookupByLibrary.simpleMessage("Se déconnecter"),
        "terminateSession": MessageLookupByLibrary.simpleMessage(
          "Se déconnecter ?",
        ),
        "terms": MessageLookupByLibrary.simpleMessage("Conditions"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage(
          "Conditions d\'utilisation",
        ),
        "thankYou": MessageLookupByLibrary.simpleMessage("Merci"),
        "thankYouForSubscribing": MessageLookupByLibrary.simpleMessage(
          "Merci de vous être abonné !",
        ),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
          "Le téléchargement n\'a pas pu être terminé",
        ),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
          "Le lien que vous essayez d\'accéder a expiré.",
        ),
        "thePersonGroupsWillNotBeDisplayed":
            MessageLookupByLibrary.simpleMessage(
          "Les groupes de personnes ne seront plus affichés dans la section personnes. Les photos resteront intactes.",
        ),
        "thePersonWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
          "Les groupes de personnes ne seront plus affichés dans la section personnes. Les photos resteront intactes.",
        ),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
          "La clé de récupération que vous avez entrée est incorrecte",
        ),
        "theme": MessageLookupByLibrary.simpleMessage("Thème"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
          "Ces éléments seront supprimés de votre appareil.",
        ),
        "theyAlsoGetXGb": m99,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
          "Ils seront supprimés de tous les albums.",
        ),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
          "Cette action ne peut pas être annulée",
        ),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
          "Cet album a déjà un lien collaboratif",
        ),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
          "Cela peut être utilisé pour récupérer votre compte si vous perdez votre deuxième facteur",
        ),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Cet appareil"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
          "Cette adresse mail est déjà utilisé",
        ),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
          "Cette image n\'a pas de données exif",
        ),
        "thisIsMeExclamation":
            MessageLookupByLibrary.simpleMessage("C\'est moi !"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
          "Ceci est votre ID de vérification",
        ),
        "thisWeekThroughTheYears": MessageLookupByLibrary.simpleMessage(
          "Cette semaine au fil des années",
        ),
        "thisWeekXYearsAgo": m101,
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
          "Cela vous déconnectera de l\'appareil suivant :",
        ),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
          "Cela vous déconnectera de cet appareil !",
        ),
        "thisWillMakeTheDateAndTimeOfAllSelected":
            MessageLookupByLibrary.simpleMessage(
          "Cela rendra la date et l\'heure identique à toutes les photos sélectionnées.",
        ),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
          "Ceci supprimera les liens publics de tous les liens rapides sélectionnés.",
        ),
        "throughTheYears": m102,
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
          "Pour activer le verrouillage de l\'application vous devez configurer le code d\'accès de l\'appareil ou le verrouillage de l\'écran dans les paramètres de votre système.",
        ),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
          "Pour masquer une photo ou une vidéo:",
        ),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
          "Pour réinitialiser votre mot de passe, vérifiez d\'abord votre email.",
        ),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Journaux du jour"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
          "Trop de tentatives incorrectes",
        ),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Taille totale"),
        "trash": MessageLookupByLibrary.simpleMessage("Corbeille"),
        "trashDaysLeft": m103,
        "trim": MessageLookupByLibrary.simpleMessage("Recadrer"),
        "tripInYear": m104,
        "tripToLocation": m105,
        "trustedContacts": MessageLookupByLibrary.simpleMessage(
          "Contacts de confiance",
        ),
        "trustedInviteBody": m106,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Réessayer"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
          "Activez la sauvegarde pour charger automatiquement sur Ente les fichiers ajoutés à ce dossier de l\'appareil.",
        ),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
          "2 mois gratuits sur les forfaits annuels",
        ),
        "twofactor": MessageLookupByLibrary.simpleMessage(
          "Authentification à deux facteurs (A2F)",
        ),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
          "L\'authentification à deux facteurs a été désactivée",
        ),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
          "Authentification à deux facteurs (A2F)",
        ),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
          "L\'authentification à deux facteurs a été réinitialisée avec succès ",
        ),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
          "Configuration de l\'authentification à deux facteurs",
        ),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
        "unarchive": MessageLookupByLibrary.simpleMessage("Désarchiver"),
        "unarchiveAlbum": MessageLookupByLibrary.simpleMessage(
          "Désarchiver l\'album",
        ),
        "unarchiving": MessageLookupByLibrary.simpleMessage(
          "Désarchivage en cours...",
        ),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
          "Désolé, ce code n\'est pas disponible.",
        ),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Aucune catégorie"),
        "unhide": MessageLookupByLibrary.simpleMessage("Dévoiler"),
        "unhideToAlbum": MessageLookupByLibrary.simpleMessage(
          "Afficher dans l\'album",
        ),
        "unhiding":
            MessageLookupByLibrary.simpleMessage("Démasquage en cours..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
          "Démasquage des fichiers vers l\'album",
        ),
        "unlock": MessageLookupByLibrary.simpleMessage("Déverrouiller"),
        "unpinAlbum":
            MessageLookupByLibrary.simpleMessage("Désépingler l\'album"),
        "unselectAll":
            MessageLookupByLibrary.simpleMessage("Désélectionner tout"),
        "update": MessageLookupByLibrary.simpleMessage("Mise à jour"),
        "updateAvailable": MessageLookupByLibrary.simpleMessage(
          "Une mise à jour est disponible",
        ),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
          "Mise à jour de la sélection du dossier...",
        ),
        "upgrade": MessageLookupByLibrary.simpleMessage("Améliorer"),
        "uploadIsIgnoredDueToIgnorereason": m108,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
          "Envoi des fichiers vers l\'album...",
        ),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory": MessageLookupByLibrary.simpleMessage(
          "Sauvegarde d\'un souvenir...",
        ),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
          "Jusqu\'à 50% de réduction, jusqu\'au 4ème déc.",
        ),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
          "Le stockage gratuit possible est limité par votre offre actuelle. Vous pouvez au maximum doubler votre espace de stockage gratuitement, le stockage supplémentaire deviendra donc automatiquement utilisable lorsque vous mettrez à niveau votre offre.",
        ),
        "useAsCover": MessageLookupByLibrary.simpleMessage(
          "Utiliser comme couverture",
        ),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
          "Vous avez des difficultés pour lire cette vidéo ? Appuyez longuement ici pour essayer un autre lecteur.",
        ),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
          "Utilisez des liens publics pour les personnes qui ne sont pas sur Ente",
        ),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Utiliser la clé de secours",
        ),
        "useSelectedPhoto": MessageLookupByLibrary.simpleMessage(
          "Utiliser la photo sélectionnée",
        ),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Stockage utilisé"),
        "validTill": m110,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "La vérification a échouée, veuillez réessayer",
        ),
        "verificationId": MessageLookupByLibrary.simpleMessage(
          "ID de vérification",
        ),
        "verify": MessageLookupByLibrary.simpleMessage("Vérifier"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Vérifier l\'email"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Vérifier"),
        "verifyPasskey": MessageLookupByLibrary.simpleMessage(
          "Vérifier la clé de sécurité",
        ),
        "verifyPassword": MessageLookupByLibrary.simpleMessage(
          "Vérifier le mot de passe",
        ),
        "verifying":
            MessageLookupByLibrary.simpleMessage("Validation en cours..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Vérification de la clé de récupération...",
        ),
        "videoInfo": MessageLookupByLibrary.simpleMessage("Informations vidéo"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vidéo"),
        "videoStreaming": MessageLookupByLibrary.simpleMessage(
          "Vidéos diffusables",
        ),
        "videos": MessageLookupByLibrary.simpleMessage("Vidéos"),
        "viewActiveSessions": MessageLookupByLibrary.simpleMessage(
          "Afficher les connexions actives",
        ),
        "viewAddOnButton": MessageLookupByLibrary.simpleMessage(
          "Afficher les modules complémentaires",
        ),
        "viewAll": MessageLookupByLibrary.simpleMessage("Tout afficher"),
        "viewAllExifData": MessageLookupByLibrary.simpleMessage(
          "Visualiser toutes les données EXIF",
        ),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage(
          "Fichiers volumineux",
        ),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
          "Affichez les fichiers qui consomment le plus de stockage.",
        ),
        "viewLogs":
            MessageLookupByLibrary.simpleMessage("Afficher les journaux"),
        "viewPersonToUnlink": m112,
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Voir la clé de récupération",
        ),
        "viewer": MessageLookupByLibrary.simpleMessage("Observateur"),
        "viewersSuccessfullyAdded": m113,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
          "Vous pouvez gérer votre abonnement sur web.ente.io",
        ),
        "waitingForVerification": MessageLookupByLibrary.simpleMessage(
          "En attente de vérification...",
        ),
        "waitingForWifi": MessageLookupByLibrary.simpleMessage(
          "En attente de connexion Wi-Fi...",
        ),
        "warning": MessageLookupByLibrary.simpleMessage("Attention"),
        "weAreOpenSource": MessageLookupByLibrary.simpleMessage(
          "Nous sommes open source !",
        ),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
          "Nous ne prenons pas en charge l\'édition des photos et des albums que vous ne possédez pas encore",
        ),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Securité Faible"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Bienvenue !"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Nouveautés"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
          "Un contact de confiance peut vous aider à récupérer vos données.",
        ),
        "widgets": MessageLookupByLibrary.simpleMessage("Gadgets"),
        "wishThemAHappyBirthday": m115,
        "yearShort": MessageLookupByLibrary.simpleMessage("an"),
        "yearly": MessageLookupByLibrary.simpleMessage("Annuel"),
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("Oui"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Oui, annuler"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
          "Oui, convertir en observateur",
        ),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Oui, supprimer"),
        "yesDiscardChanges": MessageLookupByLibrary.simpleMessage(
          "Oui, ignorer les modifications",
        ),
        "yesIgnore": MessageLookupByLibrary.simpleMessage("Oui, ignorer"),
        "yesLogout":
            MessageLookupByLibrary.simpleMessage("Oui, se déconnecter"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Oui, supprimer"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Oui, renouveler"),
        "yesResetPerson": MessageLookupByLibrary.simpleMessage(
          "Oui, réinitialiser la personne",
        ),
        "you": MessageLookupByLibrary.simpleMessage("Vous"),
        "youAndThem": m117,
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
          "Vous êtes sur un plan familial !",
        ),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
          "Vous êtes sur la dernière version",
        ),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
          "* Vous pouvez au maximum doubler votre espace de stockage",
        ),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
          "Vous pouvez gérer vos liens dans l\'onglet Partage.",
        ),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
          "Vous pouvez essayer de rechercher une autre requête.",
        ),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
          "Vous ne pouvez pas rétrograder vers cette offre",
        ),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
          "Vous ne pouvez pas partager avec vous-même",
        ),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
          "Vous n\'avez aucun élément archivé.",
        ),
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
          "Votre compte a été supprimé",
        ),
        "yourMap": MessageLookupByLibrary.simpleMessage("Votre carte"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
          "Votre plan a été rétrogradé avec succès",
        ),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
          "Votre offre a été mise à jour avec succès",
        ),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
          "Votre achat a été effectué avec succès",
        ),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
          "Vos informations de stockage n\'ont pas pu être récupérées",
        ),
        "yourSubscriptionHasExpired": MessageLookupByLibrary.simpleMessage(
          "Votre abonnement a expiré",
        ),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
          "Votre abonnement a été mis à jour avec succès",
        ),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
          "Votre code de vérification a expiré",
        ),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
          "Vous n\'avez aucun fichier dupliqué pouvant être nettoyé",
        ),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
          "Vous n\'avez pas de fichiers dans cet album qui peuvent être supprimés",
        ),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
          "Zoom en arrière pour voir les photos",
        ),
      };
}
