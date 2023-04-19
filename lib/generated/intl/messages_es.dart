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

  static String m4(albumName) =>
      "Esto eliminará el enlace público para acceder a \"${albumName}\".";

  static String m5(supportEmail) =>
      "Por favor, envíe un email a ${supportEmail} desde su dirección de correo electrónico registrada";

  static String m7(email) =>
      "${email} no tiene una cuenta ente.\n\nEnvíale una invitación para compartir fotos.";

  static String m8(storageAmountInGB) =>
      "${storageAmountInGB} GB cada vez que alguien se registra en un plan de pago y aplica tu código";

  static String m11(expiryTime) => "El enlace caducará en ${expiryTime}";

  static String m12(maxValue) =>
      "Cuando se establece al máximo (${maxValue}), el límite del dispositivo se relajará para permitir picos temporales de un gran número de espectadores.";

  static String m14(passwordStrengthValue) => "Seguridad de la contraseña :";

  static String m16(storageInGB) =>
      "3. Ambos obtienen ${storageInGB} GB* gratis";

  static String m17(userEmail) =>
      "${userEmail} será eliminado de este álbum compartido\n\nCualquier foto añadida por ellos también será eliminada del álbum";

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

  static String m32(storageAmountInGB) =>
      "También obtienen ${storageAmountInGB} GB";

  static String m33(email) => "Este es el ID de verificación de ${email}";

  static String m34(email) => "Verificar ${email}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
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
        "addViewer": MessageLookupByLibrary.simpleMessage("Añadir espectador"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Agregado como"),
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Añadiendo a favoritos..."),
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
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permitir a las personas con el enlace añadir fotos al álbum compartido."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Permitir añadir fotos"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Permitir descargas"),
        "apply": MessageLookupByLibrary.simpleMessage("Aplicar"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Usar código"),
        "archive": MessageLookupByLibrary.simpleMessage("Archivo"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "¿Cuál es la razón principal por la que eliminas tu cuenta?"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentifiquese para ver sus archivos ocultos"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Sólo puede eliminar archivos de tu propiedad"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "cannotAddMorePhotosAfterBecomingViewer": m1,
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Cambiar correo electrónico"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Cambiar contraseña"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("¿Cambiar permisos?"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Revisa tu bandeja de entrada (y spam) para completar la verificación"),
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
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Recolectar fotos"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Corfirmar borrado de cuenta"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Sí, quiero eliminar permanentemente esta cuenta y todos sus datos."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirmar contraseña"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmar clave de recuperación"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirme su clave de recuperación"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contactar con soporte"),
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
        "custom": MessageLookupByLibrary.simpleMessage("Personalizado"),
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
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Está a punto de eliminar permanentemente su cuenta y todos sus datos.\nEsta acción es irreversible."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Por favor, envíe un correo electrónico a <warning>account-deletion@ente.io</warning> desde su dirección de correo electrónico registrada."),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Eliminar de ambos"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Eliminar del dispositivo"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Eliminar de ente"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Borrar las fotos"),
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
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Los espectadores todavía pueden tomar capturas de pantalla o guardar una copia de sus fotos usando herramientas externas"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Por favor tenga en cuenta"),
        "disableLinkMessage": m4,
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Hacer esto más tarde"),
        "done": MessageLookupByLibrary.simpleMessage("Hecho"),
        "dropSupportEmail": m5,
        "eligible": MessageLookupByLibrary.simpleMessage("elegible"),
        "email": MessageLookupByLibrary.simpleMessage("Correo electrónico"),
        "emailNoEnteAccount": m7,
        "encryption": MessageLookupByLibrary.simpleMessage("Cifrado"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Claves de cifrado"),
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
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Error al aplicar el código"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "No se pueden obtener los detalles de la referencia. Por favor, inténtalo de nuevo más tarde."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Error al cargar álbumes"),
        "faq": MessageLookupByLibrary.simpleMessage("Preguntas Frecuentes"),
        "feedback": MessageLookupByLibrary.simpleMessage("Sugerencias"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Olvidé mi contraseña"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Almacenamiento gratuito reclamado"),
        "freeStorageOnReferralSuccess": m8,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Almacenamiento libre disponible"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generando claves de encriptación..."),
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
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Dirección de correo electrónico no válida"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Clave inválida"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "La clave de recuperación introducida no es válida. Por favor, asegúrese de que contiene 24 palabras y compruebe la ortografía de cada una.\n\nSi ha introducido un código de recuperación antiguo, asegúrese de que tiene 64 caracteres de largo y compruebe cada uno de ellos."),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Invitar a ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invita a tus amigos"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Los elementos seleccionados serán removidos de este álbum"),
        "keepPhotos":
            MessageLookupByLibrary.simpleMessage("Conservar las fotos"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Por favor ayúdanos con esta información"),
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
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Al hacer clic en iniciar sesión, acepto los <u-terms>términos de servicio</u-terms> y <u-policy>la política de privacidad</u-policy>"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("¿Perdió su dispositivo?"),
        "manage": MessageLookupByLibrary.simpleMessage("Administrar"),
        "manageLink":
            MessageLookupByLibrary.simpleMessage("Administrar enlace"),
        "manageParticipants":
            MessageLookupByLibrary.simpleMessage("Administrar"),
        "maxDeviceLimitSpikeHandling": m12,
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderada"),
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Movido a la papelera"),
        "never": MessageLookupByLibrary.simpleMessage("Nunca"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nuevo álbum"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("¿Sin clave de recuperación?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Debido a la naturaleza de nuestro protocolo de cifrado de extremo a extremo, sus datos no pueden ser descifrados sin su contraseña o clave de recuperación"),
        "ok": MessageLookupByLibrary.simpleMessage("Aceptar"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ups, algo salió mal"),
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
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("Personas usando tu código"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage(
            "Por favor, inténtalo nuevamente"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Por favor, espere..."),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Política de Privacidad"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Enlace público habilitado"),
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
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Dale este código a tus amigos"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Se inscriben a un plan pagado"),
        "referralStep3": m16,
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Las referencias están actualmente en pausa"),
        "remove": MessageLookupByLibrary.simpleMessage("Quitar"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Quitar del álbum"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("¿Quitar del álbum?"),
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
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Reenviar correo electrónico"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Restablecer contraseña"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Guardar Clave"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Guarda tu clave de recuperación si aún no lo has hecho"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Escanear código"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Escanea este código QR con tu aplicación de autenticación"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Seleccionar motivo"),
        "sendEmail":
            MessageLookupByLibrary.simpleMessage("Enviar correo electrónico"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Enviar invitación"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Enviar enlace"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Establecer una contraseña"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Establecer contraseña"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configuración completa"),
        "shareALink":
            MessageLookupByLibrary.simpleMessage("Compartir un enlace"),
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
        "storageInGB": m28,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Segura"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Suscribirse"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Parece que su suscripción ha caducado. Por favor, suscríbase para habilitar el compartir."),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("toque para copiar"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Toca para introducir el código"),
        "terminate": MessageLookupByLibrary.simpleMessage("Terminar"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("¿Terminar sesión?"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Términos"),
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
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Autenticación en dos pasos"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Configuración de dos pasos"),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Sin categorizar"),
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
        "weakStrength": MessageLookupByLibrary.simpleMessage("Poco segura"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("¡Bienvenido de nuevo!"),
        "weveSentAMailTo": MessageLookupByLibrary.simpleMessage(
            "Enviamos un correo electrónico a"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Sí, convertir a espectador"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Sí, eliminar"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Sí, quitar"),
        "you": MessageLookupByLibrary.simpleMessage("Usted"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Puedes al máximo duplicar tu almacenamiento"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "No puedes compartir contigo mismo"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Su cuenta ha sido eliminada")
      };
}
