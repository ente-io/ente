// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a es locale. All the
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
  String get localeName => 'es';

  static String m0(paymentProvider) =>
      "Por favor, cancele primero su suscripción existente de ${paymentProvider}";

  static String m1(user) =>
      "${user} no podrá añadir más fotos a este álbum\n\nTodavía podrán eliminar las fotos ya añadidas por ellos";

  static String m2(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Su familia ha reclamado ${storageAmountInGb} Gb hasta el momento',
            'false':
                'Tú has reclamado ${storageAmountInGb} Gb hasta el momento',
            'other':
                '¡Tú has reclamado ${storageAmountInGb} Gb hasta el momento!',
          })}";

  static String m3(provider) =>
      "Por favor, contáctenos en support@ente.io para gestionar su suscripción a ${provider}.";

  static String m42(currentlyDeleting, totalCount) =>
      "Borrando ${currentlyDeleting} / ${totalCount}";

  static String m4(albumName) =>
      "Esto eliminará el enlace público para acceder a \"${albumName}\".";

  static String m5(supportEmail) =>
      "Por favor, envíe un email a ${supportEmail} desde su dirección de correo electrónico registrada";

  static String m7(email) =>
      "${email} no tiene una cuenta ente.\n\nEnvíale una invitación para compartir fotos.";

  static String m8(storageAmountInGB) =>
      "${storageAmountInGB} GB cada vez que alguien se registra en un plan de pago y aplica tu código";

  static String m9(endDate) => "Prueba gratuita válida hasta${endDate}";

  static String m10(count) =>
      "${Intl.plural(count, one: '${count} elemento', other: '${count} elementos')}";

  static String m11(expiryTime) => "El enlace caducará en ${expiryTime}";

  static String m12(maxValue) =>
      "Cuando se establece al máximo (${maxValue}), el límite del dispositivo se relajará para permitir picos temporales de un gran número de espectadores.";

  static String m13(count) =>
      "${Intl.plural(count, zero: 'no recuerdos', one: '${count} recuerdo', other: '${count} recuerdos')}\n";

  static String m14(passwordStrengthValue) =>
      "Seguridad de la contraseña : ${passwordStrengthValue}";

  static String m16(storageInGB) =>
      "3. Ambos obtienen ${storageInGB} GB* gratis";

  static String m17(userEmail) =>
      "${userEmail} será eliminado de este álbum compartido\n\nCualquier foto añadida por ellos también será eliminada del álbum";

  static String m18(endDate) => "Se renueva el ${endDate}";

  static String m19(count) => "${count} seleccionados";

  static String m20(count, yourCount) =>
      "${count} seleccionados (${yourCount} tuyos)";

  static String m21(verificationID) =>
      "Aquí está mi ID de verificación: ${verificationID} para ente.io.";

  static String m22(verificationID) =>
      "Hola, ¿puedes confirmar que esta es tu ID de verificación ente.io: ${verificationID}?";

  static String m23(referralCode, referralStorageInGB) =>
      "ente código de referencia: ${referralCode} \n\nAplicarlo en Ajustes → General → Referencias para obtener ${referralStorageInGB} GB gratis después de registrarse en un plan de pago\n\nhttps://ente.io";

  static String m24(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Compartir con personas específicas', one: 'Compartido con 1 persona', other: 'Compartido con ${numberOfPeople} personas')}";

  static String m25(fileType) =>
      "Este ${fileType} se eliminará de tu dispositivo.";

  static String m26(fileType) =>
      "Este ${fileType} está tanto en ente como en tu dispositivo.";

  static String m27(fileType) => "Este ${fileType} se eliminará de ente.";

  static String m28(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m30(endDate) => "Tu suscripción se cancelará el ${endDate}";

  static String m32(storageAmountInGB) =>
      "También obtienen ${storageAmountInGB} GB";

  static String m33(email) => "Este es el ID de verificación de ${email}";

  static String m34(email) => "Verificar ${email}";

  static String m35(count) =>
      "${Intl.plural(count, one: '${count} hace un año', other: '${count} hace años')}";

  static String m36(storageSaved) => "¡Has liberado ${storageSaved} con éxito!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Hay una nueva versión de ente disponible."),
        "about": MessageLookupByLibrary.simpleMessage("Acerca de"),
        "account": MessageLookupByLibrary.simpleMessage("Cuenta"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("¡Bienvenido de nuevo!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Entiendo que si pierdo mi contraseña podría perder mis datos, ya que mis datos están <underline>cifrados de extremo a extremo</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sesiónes activas"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage(
            "Agregar nuevo correo electrónico"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Agregar colaborador"),
        "addMore": MessageLookupByLibrary.simpleMessage("Añadir más"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Añadir a ente"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Añadir espectador"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Agregado como"),
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Añadiendo a favoritos..."),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Avanzado"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Después de un día"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Después de 1 hora"),
        "after1Month":
            MessageLookupByLibrary.simpleMessage("Después de un mes"),
        "after1Week":
            MessageLookupByLibrary.simpleMessage("Después de una semana"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Después de un año"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Propietario"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Álbum actualizado"),
        "albums": MessageLookupByLibrary.simpleMessage("Álbunes"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Todo limpio"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permitir a las personas con el enlace añadir fotos al álbum compartido."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Permitir añadir fotos"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Permitir descargas"),
        "appleId": MessageLookupByLibrary.simpleMessage("ID de Apple"),
        "apply": MessageLookupByLibrary.simpleMessage("Aplicar"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Usar código"),
        "archive": MessageLookupByLibrary.simpleMessage("Archivo"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "¿Estás seguro de que quieres cancelar?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "¿Estás seguro de que quieres cambiar tu plan?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "¿Seguro que quiere cerrar la sesión?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "¿Estás seguro de que quieres renovar?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Tu suscripción ha sido cancelada. ¿Quieres compartir el motivo?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "¿Cuál es la razón principal por la que eliminas tu cuenta?"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentifíquese para cambiar su correo electrónico"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentifíquese para cambiar su contraseña"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentifíquese para iniciar la eliminación de la cuenta"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentifiquese para ver sus archivos ocultos"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Carpetas respaldadas"),
        "backup": MessageLookupByLibrary.simpleMessage("Copia de respaldo"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Copia de seguridad usando datos móviles"),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
            "Ajustes de copia de seguridad"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Respaldar vídeos"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Sólo puedes crear un enlace para archivos de tu propiedad"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Sólo puede eliminar archivos de tu propiedad"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "cancelOtherSubscription": m0,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Cancelar suscripción"),
        "cannotAddMorePhotosAfterBecomingViewer": m1,
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Cambiar correo electrónico"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Cambiar contraseña"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Cambiar contraseña"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("¿Cambiar permisos?"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Comprobar actualizaciónes"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Revisa tu bandeja de entrada (y spam) para completar la verificación"),
        "checking": MessageLookupByLibrary.simpleMessage("Comprobando..."),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
            "Reclamar almacenamiento gratis"),
        "claimMore": MessageLookupByLibrary.simpleMessage("¡Reclama más!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Reclamado"),
        "claimedStorageSoFar": m2,
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Código aplicado"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Código copiado al portapapeles"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Código usado por ti"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Crea un enlace para que la gente pueda añadir y ver fotos en tu álbum compartido sin necesidad de la aplicación ente o una cuenta. Genial para recolectar fotos de eventos."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Enlace colaborativo"),
        "collaborator": MessageLookupByLibrary.simpleMessage("Colaborador"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Colaboradores pueden añadir fotos y videos al álbum compartido."),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Recopilar fotos del evento"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Recolectar fotos"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Corfirmar borrado de cuenta"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Sí, quiero eliminar permanentemente esta cuenta y todos sus datos."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirmar contraseña"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Confirmar los cambios en el plan"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmar clave de recuperación"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirme su clave de recuperación"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contactar con soporte"),
        "contactToManageSubscription": m3,
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuar"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copiar enlace"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copiar y pegar este código\na su aplicación de autenticador"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Crear cuenta"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Mantenga presionado para seleccionar fotos y haga clic en + para crear un álbum"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Crear nueva cuenta"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Crear enlace público"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Creando enlace..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Actualización crítica disponible"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("El uso actual es "),
        "custom": MessageLookupByLibrary.simpleMessage("Personalizado"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("Oscuro"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Descifrando..."),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Eliminar cuenta"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Lamentamos que te vayas. Por favor, explícanos el motivo para ayudarnos a mejorar."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Eliminar Cuenta Permanentemente"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Borrar álbum"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "¿También eliminar las fotos (y los vídeos) presentes en este álbum de <bold>todos</bold> los otros álbumes de los que forman parte?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Esto eliminará todos los álbunes vacíos. Esto es útil cuando quieres reducir el desorden en tu lista de álbumes."),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Está a punto de eliminar permanentemente su cuenta y todos sus datos.\nEsta acción es irreversible."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Por favor, envíe un correo electrónico a <warning>account-deletion@ente.io</warning> desde su dirección de correo electrónico registrada."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Eliminar álbunes vacíos"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("¿Eliminar álbunes vacíos?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Eliminar de ambos"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Eliminar del dispositivo"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Eliminar de ente"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Borrar las fotos"),
        "deleteProgress": m42,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Falta una característica clave que necesito"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "La aplicación o una característica determinada no \nse comporta como creo que debería"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "He encontrado otro servicio que me gusta más"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
            "Mi motivo no se encuentra en la lista"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Su solicitud será procesada dentro de 72 horas."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("¿Borrar álbum compartido?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "El álbum se eliminará para todos\n\nPerderás el acceso a las fotos compartidas en este álbum que son propiedad de otros"),
        "details": MessageLookupByLibrary.simpleMessage("Detalles"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Deshabilita el bloqueo de pantalla del dispositivo cuando ente está en primer plano y hay una copia de seguridad en curso. Normalmente esto no es necesario, pero puede ayudar a que las grandes cargas y las importaciones iniciales de grandes bibliotecas se completen más rápido."),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("Desactivar autobloqueo"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Los espectadores todavía pueden tomar capturas de pantalla o guardar una copia de sus fotos usando herramientas externas"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Por favor tenga en cuenta"),
        "disableLinkMessage": m4,
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Hacer esto más tarde"),
        "done": MessageLookupByLibrary.simpleMessage("Hecho"),
        "downloading": MessageLookupByLibrary.simpleMessage("Descargando..."),
        "dropSupportEmail": m5,
        "eligible": MessageLookupByLibrary.simpleMessage("elegible"),
        "email": MessageLookupByLibrary.simpleMessage("Correo electrónico"),
        "emailNoEnteAccount": m7,
        "encryption": MessageLookupByLibrary.simpleMessage("Cifrado"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Claves de cifrado"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "ente conserva tus recuerdos, así que siempre están disponibles para ti, incluso si pierdes tu dispositivo."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Tu familia también puede ser agregada a tu plan."),
        "enterCode":
            MessageLookupByLibrary.simpleMessage("Introduzca el código"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Introduce el código proporcionado por tu amigo para reclamar almacenamiento gratuito para ambos"),
        "enterEmail": MessageLookupByLibrary.simpleMessage(
            "Ingresar correo electrónico "),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Introduzca una nueva contraseña que podamos usar para cifrar sus datos"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Introduzca contraseña"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Introduzca una contraseña que podamos usar para cifrar sus datos"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
            "Ingresar código de referencia"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Ingrese el código de seis dígitos de su aplicación de autenticación"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Por favor, introduzca una dirección de correo electrónico válida."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Escribe tu correo electrónico"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Ingrese su contraseña"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Introduzca su clave de recuperación"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Este enlace ha caducado. Por favor, seleccione una nueva fecha de caducidad o deshabilite la fecha de caducidad."),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exportar tus datos"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Error al aplicar el código"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Error al cancelar"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "No se pueden obtener los detalles de la referencia. Por favor, inténtalo de nuevo más tarde."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Error al cargar álbumes"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Renovación fallida"),
        "faq": MessageLookupByLibrary.simpleMessage("Preguntas Frecuentes"),
        "faqs": MessageLookupByLibrary.simpleMessage("Preguntas frecuentes"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorito"),
        "feedback": MessageLookupByLibrary.simpleMessage("Sugerencias"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Olvidé mi contraseña"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Almacenamiento gratuito reclamado"),
        "freeStorageOnReferralSuccess": m8,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Almacenamiento libre disponible"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Prueba gratuita"),
        "freeTrialValidTill": m9,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Liberar espacio del dispositivo"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generando claves de encriptación..."),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("ID de Google Play"),
        "hidden": MessageLookupByLibrary.simpleMessage("Oculto"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Cómo funciona"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Por favor, pídeles que mantengan presionada su dirección de correo electrónico en la pantalla de ajustes, y verifique que los IDs de ambos dispositivos coincidan."),
        "importing": MessageLookupByLibrary.simpleMessage("Importando...."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Contraseña incorrecta"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "La clave de recuperación introducida es incorrecta"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Clave de recuperación incorrecta"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Dispositivo inseguro"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Instalar manualmente"),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Dirección de correo electrónico no válida"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Clave inválida"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "La clave de recuperación introducida no es válida. Por favor, asegúrese de que contiene 24 palabras y compruebe la ortografía de cada una.\n\nSi ha introducido un código de recuperación antiguo, asegúrese de que tiene 64 caracteres de largo y compruebe cada uno de ellos."),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Invitar a ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invita a tus amigos"),
        "itemCount": m10,
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Los elementos seleccionados serán removidos de este álbum"),
        "keepPhotos":
            MessageLookupByLibrary.simpleMessage("Conservar las fotos"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Por favor ayúdanos con esta información"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Última actualización"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Claro"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Enlace copiado al portapapeles"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Límite del dispositivo"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Habilitado"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Vencido"),
        "linkExpiresOn": m11,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Enlace vence"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("El enlace ha caducado"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Nunca"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Bloquear"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Iniciar sesión"),
        "loggingOut":
            MessageLookupByLibrary.simpleMessage("Cerrando sesión..."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Al hacer clic en iniciar sesión, acepto los <u-terms>términos de servicio</u-terms> y <u-policy>la política de privacidad</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Cerrar sesión"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("¿Perdió su dispositivo?"),
        "manage": MessageLookupByLibrary.simpleMessage("Administrar"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Administrar almacenamiento del dispositivo"),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Administrar familia"),
        "manageLink":
            MessageLookupByLibrary.simpleMessage("Administrar enlace"),
        "manageParticipants":
            MessageLookupByLibrary.simpleMessage("Administrar"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Administrar tu suscripción"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "maxDeviceLimitSpikeHandling": m12,
        "memoryCount": m13,
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderada"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensual"),
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Mover al álbum"),
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Movido a la papelera"),
        "name": MessageLookupByLibrary.simpleMessage("Nombre"),
        "never": MessageLookupByLibrary.simpleMessage("Nunca"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nuevo álbum"),
        "newest": MessageLookupByLibrary.simpleMessage("Más reciente"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "No tienes archivos en este dispositivo que puedan ser borrados"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Sin duplicados"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("¿Sin clave de recuperación?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Debido a la naturaleza de nuestro protocolo de cifrado de extremo a extremo, sus datos no pueden ser descifrados sin su contraseña o clave de recuperación"),
        "ok": MessageLookupByLibrary.simpleMessage("Aceptar"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ups, algo salió mal"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Opcional, tan corto como quieras..."),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("O elige uno existente"),
        "password": MessageLookupByLibrary.simpleMessage("Contraseña"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Contraseña cambiada correctamente"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Bloqueo por contraseña"),
        "passwordStrength": m14,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "No almacenamos esta contraseña, así que si la olvidas, <underline>no podemos descifrar tus datos</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Detalles de pago"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("Personas usando tu código"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Borrar permanentemente"),
        "photoGridSize": MessageLookupByLibrary.simpleMessage(
            "Tamaño de la cuadrícula de fotos"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage(
            "Por favor, inténtalo nuevamente"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Por favor, espere..."),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacidad"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Política de Privacidad"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Enlace público creado"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Enlace público habilitado"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Califícanos"),
        "recover": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recuperar cuenta"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Clave de recuperación"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Clave de recuperación copiada al portapapeles"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Si olvida su contraseña, la única forma de recuperar sus datos es con esta clave."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Nosotros no almacenamos esta clave, por favor guarde dicha clave de 24 palabras en un lugar seguro."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "¡Genial! Su clave de recuperación es válida. Gracias por verificar.\n\nPor favor, recuerde mantener su clave de recuperación segura."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Clave de recuperación verificada"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Su clave de recuperación es la única forma de recuperar sus fotos si olvida su contraseña. Puede encontrar su clave de recuperación en Ajustes > Cuenta.\n\nPor favor, introduzca su clave de recuperación aquí para verificar que la ha guardado correctamente."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("¡Recuperación exitosa!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "El dispositivo actual no es lo suficientemente potente para verificar su contraseña, pero podemos regenerarla de una manera que funcione con todos los dispositivos.\n\nPor favor inicie sesión usando su clave de recuperación y regenere su contraseña (puede volver a utilizar la misma si lo desea)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Recrear contraseña"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Dale este código a tus amigos"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Se inscriben a un plan pagado"),
        "referralStep3": m16,
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Las referencias están actualmente en pausa"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "También vacía \"Eliminado Recientemente\" de \"Configuración\" -> \"Almacenamiento\" para reclamar el espacio libre"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "También vacía tu \"Papelera\" para reclamar el espacio liberado"),
        "remove": MessageLookupByLibrary.simpleMessage("Quitar"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Eliminar duplicados"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Quitar del álbum"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("¿Quitar del álbum?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Quitar de favoritos"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Eliminar enlace"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Quitar participante"),
        "removeParticipantBody": m17,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Quitar enlace público"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Algunos de los elementos que estás eliminando fueron añadidos por otras personas, y perderás el acceso a ellos"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Quitar?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Quitando de favoritos..."),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Renovar suscripción"),
        "renewsOn": m18,
        "reportABug": MessageLookupByLibrary.simpleMessage("Reportar un error"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Reportar error"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Reenviar correo electrónico"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Restablecer contraseña"),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurar"),
        "retry": MessageLookupByLibrary.simpleMessage("Reintentar"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Guardar Clave"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Guarda tu clave de recuperación si aún no lo has hecho"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Escanear código"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Escanea este código QR con tu aplicación de autenticación"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Seleccionar todos"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Seleccionar carpetas para el respaldo"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Seleccionar motivo"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Elegir tu suscripción"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Las carpetas seleccionadas se cifrarán y se respaldarán"),
        "selectedPhotos": m19,
        "selectedPhotosWithYours": m20,
        "send": MessageLookupByLibrary.simpleMessage("Enviar"),
        "sendEmail":
            MessageLookupByLibrary.simpleMessage("Enviar correo electrónico"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Enviar invitación"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Enviar enlace"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("La sesión ha expirado"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Establecer una contraseña"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Establecer contraseña"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configuración completa"),
        "shareALink":
            MessageLookupByLibrary.simpleMessage("Compartir un enlace"),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Compartir un álbum ahora"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Compartir enlace"),
        "shareMyVerificationID": m21,
        "shareTextConfirmOthersVerificationID": m22,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Descarga ente para que podamos compartir fácilmente fotos y videos en su calidad original\n\nhttps://ente.io/#download"),
        "shareTextReferralCode": m23,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Compartir con usuarios no ente"),
        "shareWithPeopleSectionTitle": m24,
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Crear álbumes compartidos y colaborativos con otros usuarios ente, incluyendo usuarios en planes gratuitos."),
        "sharing": MessageLookupByLibrary.simpleMessage("Compartiendo..."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Estoy de acuerdo con los <u-terms>términos del servicio</u-terms> y <u-policy> la política de privacidad</u-policy>"),
        "singleFileDeleteFromDevice": m25,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Se borrará de todos los álbumes."),
        "singleFileInBothLocalAndRemote": m26,
        "singleFileInRemoteOnly": m27,
        "skip": MessageLookupByLibrary.simpleMessage("Omitir"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Alguien compartiendo álbumes con usted debería ver el mismo ID en su dispositivo."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Algo salió mal"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Algo salió mal, por favor inténtalo de nuevo"),
        "sorry": MessageLookupByLibrary.simpleMessage("Lo sentimos"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "¡Lo sentimos, no se pudo añadir a favoritos!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "¡Lo sentimos, no se pudo quitar de favoritos!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Lo sentimos, no hemos podido generar claves seguras en este dispositivo.\n\nRegístrate desde un dispositivo diferente."),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Éxito"),
        "storageInGB": m28,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Segura"),
        "subWillBeCancelledOn": m30,
        "subscribe": MessageLookupByLibrary.simpleMessage("Suscribirse"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Parece que su suscripción ha caducado. Por favor, suscríbase para habilitar el compartir."),
        "subscription": MessageLookupByLibrary.simpleMessage("Suscripción"),
        "success": MessageLookupByLibrary.simpleMessage("Éxito"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Sugerir una característica"),
        "support": MessageLookupByLibrary.simpleMessage("Soporte"),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistema"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("toque para copiar"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Toca para introducir el código"),
        "terminate": MessageLookupByLibrary.simpleMessage("Terminar"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("¿Terminar sesión?"),
        "terms": MessageLookupByLibrary.simpleMessage("Términos"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Términos"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("¡Gracias por suscribirte!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "No se ha podido completar la descarga"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theyAlsoGetXGb": m32,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Esto puede utilizarse para recuperar su cuenta si pierde su segundo factor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Este dispositivo"),
        "thisIsPersonVerificationId": m33,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Esta es tu ID de verificación"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Esto cerrará la sesión del siguiente dispositivo:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "¡Esto cerrará la sesión de este dispositivo!"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "trash": MessageLookupByLibrary.simpleMessage("Papelera"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Inténtelo de nuevo"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 meses gratis en planes anuales"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Autenticación en dos pasos"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Configuración de dos pasos"),
        "unarchive": MessageLookupByLibrary.simpleMessage("Desarchivar"),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Sin categorizar"),
        "unhide": MessageLookupByLibrary.simpleMessage("Dejar de ocultar"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar todos"),
        "update": MessageLookupByLibrary.simpleMessage("Actualizar"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Actualizacion disponible"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Actualizando la selección de carpeta..."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "El almacenamiento utilizable está limitado por su plan actual. El exceso de almacenamiento reclamado se volverá automáticamente utilizable cuando actualice su plan."),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Usar clave de recuperación"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de verificación"),
        "verify": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage(
            "Verificar correo electrónico"),
        "verifyEmailID": m34,
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verificar contraseña"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verificando clave de recuperación..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vídeo"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ver código de recuperación"),
        "viewer": MessageLookupByLibrary.simpleMessage("Espectador"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("¡Somos de código abierto!"),
        "weakStrength": MessageLookupByLibrary.simpleMessage("Poco segura"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("¡Bienvenido de nuevo!"),
        "yearly": MessageLookupByLibrary.simpleMessage("Anualmente"),
        "yearsAgo": m35,
        "yesCancel": MessageLookupByLibrary.simpleMessage("Sí, cancelar"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Sí, convertir a espectador"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Sí, eliminar"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Sí, cerrar sesión"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Sí, quitar"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Sí, Renovar"),
        "you": MessageLookupByLibrary.simpleMessage("Usted"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Estás usando la última versión"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Puedes al máximo duplicar tu almacenamiento"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Puedes administrar tus enlaces en la pestaña compartir."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "No puedes degradar a este plan"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "No puedes compartir contigo mismo"),
        "youHaveSuccessfullyFreedUp": m36,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Su cuenta ha sido eliminada"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Tu plan ha sido degradado con éxito"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Tu plan se ha actualizado correctamente"),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("Tu compra ha sido exitosa"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Tus datos de almacenamiento no se han podido obtener"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Tu suscripción se ha actualizado con éxito"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "No tienes archivos duplicados que puedan ser borrados")
      };
}
