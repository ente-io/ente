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

  static String m0(count) =>
      "${Intl.plural(count, one: 'Agregar elemento', other: 'Agregar elementos')}}";

  static String m1(emailOrName) => "Añadido por ${emailOrName}";

  static String m2(albumName) => "Añadido exitosamente a  ${albumName}";

  static String m3(count) =>
      "${Intl.plural(count, zero: 'No hay Participantes', one: '1 Participante', other: '${count} Participantes')}";

  static String m4(versionValue) => "Versión: ${versionValue}";

  static String m5(paymentProvider) =>
      "Por favor, cancele primero su suscripción existente de ${paymentProvider}";

  static String m6(user) =>
      "${user} no podrá añadir más fotos a este álbum\n\nTodavía podrán eliminar las fotos ya añadidas por ellos";

  static String m7(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Su familia ha reclamado ${storageAmountInGb} GB hasta el momento',
            'false':
                'Tú has reclamado ${storageAmountInGb} GB hasta el momento',
            'other':
                '¡Tú has reclamado ${storageAmountInGb} GB hasta el momento!',
          })}";

  static String m8(albumName) => "Enlace colaborativo creado para ${albumName}";

  static String m9(familyAdminEmail) =>
      "Por favor contacta con <green>${familyAdminEmail}</green> para administrar tu suscripción";

  static String m10(provider) =>
      "Por favor, contáctenos en support@ente.io para gestionar su suscripción a ${provider}.";

  static String m11(currentlyDeleting, totalCount) =>
      "Borrando ${currentlyDeleting} / ${totalCount}";

  static String m12(albumName) =>
      "Esto eliminará el enlace público para acceder a \"${albumName}\".";

  static String m13(supportEmail) =>
      "Por favor, envíe un email a ${supportEmail} desde su dirección de correo electrónico registrada";

  static String m14(count, storageSaved) =>
      "¡Has limpiado ${Intl.plural(count, one: '${count} archivo duplicado', other: '${count} archivos duplicados')}, ahorrando (${storageSaved}!)";

  static String m15(newEmail) => "Correo cambiado a ${newEmail}";

  static String m16(email) =>
      "${email} no tiene una cuenta ente.\n\nEnvíale una invitación para compartir fotos.";

  static String m17(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 archivo', other: '${formattedNumber} archivos')} en este dispositivo han sido respaldados de forma segura";

  static String m18(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 archivo', other: '${formattedNumber} archivos')} en este álbum ha sido respaldado de forma segura";

  static String m19(storageAmountInGB) =>
      "${storageAmountInGB} GB cada vez que alguien se registra en un plan de pago y aplica tu código";

  static String m20(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} gratis";

  static String m21(endDate) => "Prueba gratuita válida hasta${endDate}";

  static String m22(count) =>
      "Aún puedes acceder ${Intl.plural(count, one: 'si', other: 'entonces')} en ente mientras mantengas una suscripción activa";

  static String m23(sizeInMBorGB) => "Liberar ${sizeInMBorGB}";

  static String m24(count, formattedSize) =>
      "${Intl.plural(count, one: 'Se puede eliminar del dispositivo para liberar ${formattedSize}', other: 'Se pueden eliminar del dispositivo para liberar ${formattedSize}')}";

  static String m25(count) =>
      "${Intl.plural(count, one: '${count} elemento', other: '${count} elementos')}";

  static String m26(expiryTime) => "El enlace caducará en ${expiryTime}";

  static String m27(maxValue) =>
      "Cuando se establece al máximo (${maxValue}), el límite del dispositivo se relajará para permitir picos temporales de un gran número de espectadores.";

  static String m28(count, formattedCount) =>
      "${Intl.plural(count, zero: 'no recuerdos', one: '${formattedCount} recuerdo', other: '${formattedCount} recuerdos')}\n";

  static String m29(count) =>
      "${Intl.plural(count, one: 'Mover elemento', other: 'Mover elementos')}";

  static String m30(albumName) => "Movido exitosamente a ${albumName}";

  static String m31(passwordStrengthValue) =>
      "Seguridad de la contraseña : ${passwordStrengthValue}";

  static String m32(providerName) =>
      "Por favor hable con el soporte de ${providerName} si se le cobró";

  static String m33(reason) =>
      "Lamentablemente tu pago falló debido a ${reason}";

  static String m34(toEmail) =>
      "Por favor, envíanos un correo electrónico a ${toEmail}";

  static String m35(toEmail) => "Por favor, envíe los registros a ${toEmail}";

  static String m36(storeName) => "Califícanos en ${storeName}";

  static String m37(storageInGB) =>
      "3. Ambos obtienen ${storageInGB} GB* gratis";

  static String m38(userEmail) =>
      "${userEmail} será eliminado de este álbum compartido\n\nCualquier foto añadida por ellos también será eliminada del álbum";

  static String m39(endDate) => "Se renueva el ${endDate}";

  static String m40(count) => "${count} seleccionados";

  static String m41(count, yourCount) =>
      "${count} seleccionados (${yourCount} tuyos)";

  static String m42(verificationID) =>
      "Aquí está mi ID de verificación: ${verificationID} para ente.io.";

  static String m43(verificationID) =>
      "Hola, ¿puedes confirmar que esta es tu ID de verificación ente.io: ${verificationID}?";

  static String m44(referralCode, referralStorageInGB) =>
      "ente código de referencia: ${referralCode} \n\nAplicarlo en Ajustes → General → Referencias para obtener ${referralStorageInGB} GB gratis después de registrarse en un plan de pago\n\nhttps://ente.io";

  static String m45(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Compartir con personas específicas', one: 'Compartido con 1 persona', other: 'Compartido con ${numberOfPeople} personas')}";

  static String m46(emailIDs) => "Compartido con ${emailIDs}";

  static String m47(fileType) =>
      "Este ${fileType} se eliminará de tu dispositivo.";

  static String m48(fileType) =>
      "Este ${fileType} está tanto en ente como en tu dispositivo.";

  static String m49(fileType) => "Este ${fileType} se eliminará de ente.";

  static String m50(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m51(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} de ${totalAmount} ${totalStorageUnit} usados";

  static String m52(id) =>
      "Su ${id} ya está vinculado a otra cuenta ente.\nSi desea utilizar su ${id} con esta cuenta, póngase en contacto con nuestro servicio de asistencia\'\'";

  static String m53(endDate) => "Tu suscripción se cancelará el ${endDate}";

  static String m54(completed, total) =>
      "${completed}/${total} recuerdos conservados";

  static String m55(storageAmountInGB) =>
      "También obtienen ${storageAmountInGB} GB";

  static String m56(email) => "Este es el ID de verificación de ${email}";

  static String m58(email) => "Verificar ${email}";

  static String m59(email) =>
      "Hemos enviado un correo a <green>${email}</green>";

  static String m60(count) =>
      "${Intl.plural(count, one: '${count} hace un año', other: '${count} hace años')}";

  static String m61(storageSaved) => "¡Has liberado ${storageSaved} con éxito!";

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
        "addItem": m0,
        "addLocation":
            MessageLookupByLibrary.simpleMessage("Agregar ubicación"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Añadir"),
        "addMore": MessageLookupByLibrary.simpleMessage("Añadir más"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Añadir al álbum"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Añadir a ente"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Añadir espectador"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Agregado como"),
        "addedBy": m1,
        "addedSuccessfullyTo": m2,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Añadiendo a favoritos..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Avanzado"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Avanzado"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Después de un día"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Después de 1 hora"),
        "after1Month":
            MessageLookupByLibrary.simpleMessage("Después de un mes"),
        "after1Week":
            MessageLookupByLibrary.simpleMessage("Después de una semana"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Después de un año"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Propietario"),
        "albumParticipantsCount": m3,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Título del álbum"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Álbum actualizado"),
        "albums": MessageLookupByLibrary.simpleMessage("Álbunes"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Todo limpio"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
            "Todos los recuerdos preservados"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permitir a las personas con el enlace añadir fotos al álbum compartido."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Permitir añadir fotos"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Permitir descargas"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Permitir que la gente añada fotos"),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
            "Android, iOS, Web, Computadora"),
        "appVersion": m4,
        "appleId": MessageLookupByLibrary.simpleMessage("ID de Apple"),
        "apply": MessageLookupByLibrary.simpleMessage("Aplicar"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Usar código"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Suscripción en la AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("Archivo"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Archivar álbum"),
        "archiving": MessageLookupByLibrary.simpleMessage("Archivando..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "¿Está seguro de que desea abandonar el plan familiar?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "¿Estás seguro de que quieres cancelar?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "¿Estás seguro de que quieres cambiar tu plan?"),
        "areYouSureYouWantToExit":
            MessageLookupByLibrary.simpleMessage("¿Seguro que quieres salir?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "¿Seguro que quiere cerrar la sesión?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "¿Estás seguro de que quieres renovar?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Tu suscripción ha sido cancelada. ¿Quieres compartir el motivo?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "¿Cuál es la razón principal por la que eliminas tu cuenta?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Pide a tus seres queridos que compartan"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("en un refugio blindado"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Por favor autentificar para cambiar la configuración de bloqueo de pantalla"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentifíquese para cambiar su correo electrónico"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentifíquese para cambiar su contraseña"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Por favor autentificar para configurar autenticación de dos factores"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentifíquese para iniciar la eliminación de la cuenta"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentifíquese para ver sus sesiones activas"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentifiquese para ver sus archivos ocultos"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Por favor autentifique para ver sus memorias"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentifíquese para ver su clave de recuperación"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Autenticando..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Error de autenticación, por favor inténtalo de nuevo"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("¡Autenticación exitosa!"),
        "available": MessageLookupByLibrary.simpleMessage("Disponible"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Carpetas respaldadas"),
        "backup": MessageLookupByLibrary.simpleMessage("Copia de respaldo"),
        "backupFailed": MessageLookupByLibrary.simpleMessage(
            "La copia de seguridad ha fallado"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Copia de seguridad usando datos móviles"),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
            "Ajustes de copia de seguridad"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Respaldar vídeos"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData":
            MessageLookupByLibrary.simpleMessage("Datos almacenados en caché"),
        "calculating": MessageLookupByLibrary.simpleMessage("Calculando..."),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "No se puede subir a álbumes propiedad de otros"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Sólo puedes crear un enlace para archivos de tu propiedad"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Sólo puede eliminar archivos de tu propiedad"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "cancelOtherSubscription": m5,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Cancelar suscripción"),
        "cannotAddMorePhotosAfterBecomingViewer": m6,
        "centerPoint": MessageLookupByLibrary.simpleMessage("Punto central"),
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
        "claimedStorageSoFar": m7,
        "clearCaches": MessageLookupByLibrary.simpleMessage("Limpiar caché"),
        "click": MessageLookupByLibrary.simpleMessage("• Click"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Haga clic en el menú desbordante"),
        "close": MessageLookupByLibrary.simpleMessage("Cerrar"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
            "Agrupar por tiempo de captura"),
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
        "collaborativeLinkCreatedFor": m8,
        "collaborator": MessageLookupByLibrary.simpleMessage("Colaborador"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Colaboradores pueden añadir fotos y videos al álbum compartido."),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Recopilar fotos del evento"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Recolectar fotos"),
        "color": MessageLookupByLibrary.simpleMessage("Color"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "¿Estás seguro de que desea deshabilitar la autenticación de doble factor?"),
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
        "contactFamilyAdmin": m9,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contactar con soporte"),
        "contactToManageSubscription": m10,
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuar"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Continuar con el plan gratuito"),
        "copyEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Copiar dirección de correo electrónico"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copiar enlace"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copiar y pegar este código\na su aplicación de autenticador"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "No pudimos hacer una copia de seguridad de tus datos.\nVolveremos a intentarlo más tarde."),
        "couldNotFreeUpSpace":
            MessageLookupByLibrary.simpleMessage("No se pudo liberar espacio"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "No se pudo actualizar la suscripción"),
        "count": MessageLookupByLibrary.simpleMessage("Cuenta"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Crear cuenta"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Mantenga presionado para seleccionar fotos y haga clic en + para crear un álbum"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Crear nueva cuenta"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Crear o seleccionar álbum"),
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
        "dayToday": MessageLookupByLibrary.simpleMessage("Hoy"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Ayer"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Descifrando..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Descifrando video..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Deduplicar archivos"),
        "delete": MessageLookupByLibrary.simpleMessage("Eliminar"),
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
        "deleteAll": MessageLookupByLibrary.simpleMessage("Borrar Todo"),
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
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Borrar la ubicación"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Borrar las fotos"),
        "deleteProgress": m11,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Falta una característica clave que necesito"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "La aplicación o una característica determinada no se comporta como creo que debería"),
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
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Deseleccionar todo"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Diseñado para sobrevivir"),
        "details": MessageLookupByLibrary.simpleMessage("Detalles"),
        "devAccountChanged": MessageLookupByLibrary.simpleMessage(
            "La cuenta de desarrollador que utilizamos para publicar ente en la App Store ha cambiado. Por eso, tendrás que iniciar sesión de nuevo.\n\nNuestras disculpas por las molestias, pero esto era inevitable."),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Los archivos añadidos a este álbum de dispositivo se subirán automáticamente a ente."),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Deshabilita el bloqueo de pantalla del dispositivo cuando ente está en primer plano y hay una copia de seguridad en curso. Normalmente esto no es necesario, pero puede ayudar a que las grandes cargas y las importaciones iniciales de grandes bibliotecas se completen más rápido."),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("¿Sabías que?"),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("Desactivar autobloqueo"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Los espectadores todavía pueden tomar capturas de pantalla o guardar una copia de sus fotos usando herramientas externas"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Por favor tenga en cuenta"),
        "disableLinkMessage": m12,
        "disableTwofactor":
            MessageLookupByLibrary.simpleMessage("Deshabilitar dos factores"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Deshabilitando la autenticación de dos factores..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Descartar"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Hacer esto más tarde"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "¿Quieres descartar las ediciones que has hecho?"),
        "done": MessageLookupByLibrary.simpleMessage("Hecho"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Duplica tu almacenamiento"),
        "download": MessageLookupByLibrary.simpleMessage("Descargar"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Descarga fallida"),
        "downloading": MessageLookupByLibrary.simpleMessage("Descargando..."),
        "dropSupportEmail": m13,
        "duplicateFileCountWithStorageSaved": m14,
        "edit": MessageLookupByLibrary.simpleMessage("Editar"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Editar la ubicación"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Ediciones guardadas"),
        "eligible": MessageLookupByLibrary.simpleMessage("elegible"),
        "email": MessageLookupByLibrary.simpleMessage("Correo electrónico"),
        "emailChangedTo": m15,
        "emailNoEnteAccount": m16,
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "Envíe sus registros por correo electrónico"),
        "empty": MessageLookupByLibrary.simpleMessage("Vaciar"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("¿Vaciar la papelera?"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
            "Cifrando copia de seguridad..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Cifrado"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Claves de cifrado"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Encriptado de extremo a extremo por defecto"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "ente puede cifrar y preservar archivos sólo si concede acceso a ellos"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "ente conserva tus recuerdos, así que siempre están disponibles para ti, incluso si pierdes tu dispositivo."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Tu familia también puede ser agregada a tu plan."),
        "enterAlbumName": MessageLookupByLibrary.simpleMessage(
            "Introduzca el nombre del álbum"),
        "enterCode":
            MessageLookupByLibrary.simpleMessage("Introduzca el código"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Introduce el código proporcionado por tu amigo para reclamar almacenamiento gratuito para ambos"),
        "enterEmail": MessageLookupByLibrary.simpleMessage(
            "Ingresar correo electrónico "),
        "enterFileName": MessageLookupByLibrary.simpleMessage(
            "Introduzca el nombre del archivo"),
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
        "error": MessageLookupByLibrary.simpleMessage("Error"),
        "everywhere": MessageLookupByLibrary.simpleMessage("todas partes"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Usuario existente"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Este enlace ha caducado. Por favor, seleccione una nueva fecha de caducidad o deshabilite la fecha de caducidad."),
        "exportLogs":
            MessageLookupByLibrary.simpleMessage("Exportar registros"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exportar tus datos"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Error al aplicar el código"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Error al cancelar"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Failed to download video"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "No se pudo obtener el original para editar"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "No se pueden obtener los detalles de la referencia. Por favor, inténtalo de nuevo más tarde."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Error al cargar álbumes"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Renovación fallida"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Error al verificar el estado de su pago"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Añada 5 familiares a su plan existente sin pagar más.\n\nCada miembro tiene su propio espacio privado y no puede ver los archivos del otro a menos que sean compartidos.\n\nLos planes familiares están disponibles para los clientes que tienen una suscripción de ente pagada.\n\n¡Suscríbete ahora para empezar!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Familia"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Planes familiares"),
        "faq": MessageLookupByLibrary.simpleMessage("Preguntas Frecuentes"),
        "faqs": MessageLookupByLibrary.simpleMessage("Preguntas frecuentes"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorito"),
        "feedback": MessageLookupByLibrary.simpleMessage("Sugerencias"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Añadir una descripción..."),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Archivo guardado en la galería"),
        "filesBackedUpFromDevice": m17,
        "filesBackedUpInAlbum": m18,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Archivos eliminados"),
        "flip": MessageLookupByLibrary.simpleMessage("Voltear"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("para tus recuerdos"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Olvidé mi contraseña"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Almacenamiento gratuito reclamado"),
        "freeStorageOnReferralSuccess": m19,
        "freeStorageSpace": m20,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Almacenamiento libre disponible"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Prueba gratuita"),
        "freeTrialValidTill": m21,
        "freeUpAccessPostDelete": m22,
        "freeUpAmount": m23,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Liberar espacio del dispositivo"),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Liberar espacio"),
        "freeUpSpaceSaving": m24,
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Hasta 1000 memorias mostradas en la galería"),
        "general": MessageLookupByLibrary.simpleMessage("General"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generando claves de encriptación..."),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("ID de Google Play"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Conceder permiso"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("Agrupar fotos cercanas"),
        "hidden": MessageLookupByLibrary.simpleMessage("Oculto"),
        "hide": MessageLookupByLibrary.simpleMessage("Ocultar"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Cómo funciona"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Por favor, pídeles que mantengan presionada su dirección de correo electrónico en la pantalla de ajustes, y verifique que los IDs de ambos dispositivos coincidan."),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Algunos archivos de este álbum son ignorados de la carga porque previamente habían sido borrados de ente."),
        "importing": MessageLookupByLibrary.simpleMessage("Importando...."),
        "incorrectCode":
            MessageLookupByLibrary.simpleMessage("Código incorrecto"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Contraseña incorrecta"),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Clave de recuperación incorrecta"),
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
        "invite": MessageLookupByLibrary.simpleMessage("Invitar"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Invitar a ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invita a tus amigos"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Invite your friends to ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Parece que algo salió mal. Por favor, vuelve a intentarlo después de algún tiempo. Si el error persiste, ponte en contacto con nuestro equipo de soporte."),
        "itemCount": m25,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Los artículos muestran el número de días restantes antes de ser borrados permanente"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Los elementos seleccionados serán removidos de este álbum"),
        "keepPhotos":
            MessageLookupByLibrary.simpleMessage("Conservar las fotos"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Por favor ayúdanos con esta información"),
        "language": MessageLookupByLibrary.simpleMessage("Idioma"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Última actualización"),
        "leave": MessageLookupByLibrary.simpleMessage("Abandonar"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Abandonar álbum"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Abandonar plan familiar"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("¿Dejar álbum compartido?"),
        "light": MessageLookupByLibrary.simpleMessage("Claro"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Claro"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Enlace copiado al portapapeles"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Límite del dispositivo"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Habilitado"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Vencido"),
        "linkExpiresOn": m26,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Enlace vence"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("El enlace ha caducado"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Nunca"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Puedes compartir tu suscripción con tu familia"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Hasta ahora hemos conservado más de 10 millones de recuerdos"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Guardamos 3 copias de sus datos, una en un refugio subterráneo"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Todas nuestras aplicaciones son de código abierto"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Nuestro código fuente y criptografía han sido auditados externamente"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Puedes compartir enlaces a tus álbumes con tus seres queridos"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Nuestras aplicaciones móviles se ejecutan en segundo plano para cifrar y hacer copias de seguridad de las nuevas fotos que hagas clic"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io tiene un cargador sofisticado"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Utilizamos Xchacha20Poly1305 para cifrar tus datos de forma segura"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Cargando datos EXIF..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Cargando galería..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Cargando tus fotos..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galería local"),
        "location": MessageLookupByLibrary.simpleMessage("Ubicación"),
        "locationName":
            MessageLookupByLibrary.simpleMessage("Nombre de la ubicación"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Una etiqueta de ubicación agrupa todas las fotos que fueron tomadas dentro de un radio de una foto"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Bloquear"),
        "lockScreenEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Para activar la pantalla de bloqueo, por favor configure el código de acceso del dispositivo o el bloqueo de pantalla en los ajustes de su sistema."),
        "lockscreen":
            MessageLookupByLibrary.simpleMessage("Pantalla de bloqueo"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Iniciar sesión"),
        "loggingOut":
            MessageLookupByLibrary.simpleMessage("Cerrando sesión..."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Al hacer clic en iniciar sesión, acepto los <u-terms>términos de servicio</u-terms> y <u-policy>la política de privacidad</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Cerrar sesión"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Esto enviará registros para ayudarnos a depurar su problema. Tenga en cuenta que los nombres de los archivos se incluirán para ayudar a rastrear problemas con archivos específicos."),
        "longpressOnAnItemToViewInFullscreen": MessageLookupByLibrary.simpleMessage(
            "Pulsación prolongada en un elemento para ver en pantalla completa"),
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
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "maxDeviceLimitSpikeHandling": m27,
        "memoryCount": m28,
        "merchandise": MessageLookupByLibrary.simpleMessage("Mercancías"),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Celular, Web, Computadora"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderada"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensual"),
        "moveItem": m29,
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Mover al álbum"),
        "movedSuccessfullyTo": m30,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Movido a la papelera"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Moviendo archivos al álbum..."),
        "name": MessageLookupByLibrary.simpleMessage("Nombre"),
        "never": MessageLookupByLibrary.simpleMessage("Nunca"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nuevo álbum"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Nuevo en ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Más reciente"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "noAlbumsSharedByYouYet":
            MessageLookupByLibrary.simpleMessage("No albums shared by you yet"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "No tienes archivos en este dispositivo que puedan ser borrados"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Sin duplicados"),
        "noExifData": MessageLookupByLibrary.simpleMessage("No hay datos EXIF"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "No hay fotos ni vídeos ocultos"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "No se están respaldando fotos ahora mismo"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("¿Sin clave de recuperación?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Debido a la naturaleza de nuestro protocolo de cifrado de extremo a extremo, sus datos no pueden ser descifrados sin su contraseña o clave de recuperación"),
        "noResults": MessageLookupByLibrary.simpleMessage("Sin resultados"),
        "noResultsFound": MessageLookupByLibrary.simpleMessage(
            "No se han encontrado resultados"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("Nothing shared with you yet"),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
            "¡No hay nada que ver aquí! 👀"),
        "ok": MessageLookupByLibrary.simpleMessage("Aceptar"),
        "onDevice": MessageLookupByLibrary.simpleMessage("En el dispositivo"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "En <branding>ente</branding>"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Ups, no se pudieron guardar las ediciónes"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ups, algo salió mal"),
        "openTheItem":
            MessageLookupByLibrary.simpleMessage("• Abrir el elemento"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Opcional, tan corto como quieras..."),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("O elige uno existente"),
        "password": MessageLookupByLibrary.simpleMessage("Contraseña"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Contraseña cambiada correctamente"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Bloqueo por contraseña"),
        "passwordStrength": m31,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "No almacenamos esta contraseña, así que si la olvidas, <underline>no podemos descifrar tus datos</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Detalles de pago"),
        "paymentFailed": MessageLookupByLibrary.simpleMessage("Pago fallido"),
        "paymentFailedTalkToProvider": m32,
        "paymentFailedWithReason": m33,
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Sincronización pendiente"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("Personas usando tu código"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Todos los elementos de la papelera serán eliminados permanentemente\n\nEsta acción no se puede deshacer"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Borrar permanentemente"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "¿Eliminar permanentemente del dispositivo?"),
        "photoGridSize": MessageLookupByLibrary.simpleMessage(
            "Tamaño de la cuadrícula de fotos"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Las fotos añadidas por ti serán removidas del álbum"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Elegir punto central"),
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Suscripción en la PlayStore"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "¡Por favor, contacta con support@ente.io y estaremos encantados de ayudar!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Por favor contacte a soporte técnico si el problema persiste"),
        "pleaseEmailUsAt": m34,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Por favor, concede permiso"),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
            "Por favor, vuelva a iniciar sesión"),
        "pleaseSendTheLogsTo": m35,
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage(
            "Por favor, inténtalo nuevamente"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Por favor verifique el código que ha introducido"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Por favor, espere..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Por favor espere, borrando álbum"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Por favor espere un momento antes de volver a intentarlo"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Preparando registros..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Preservar más"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Presiona y mantén presionado para reproducir el video"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacidad"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Política de Privacidad"),
        "privateBackups": MessageLookupByLibrary.simpleMessage(
            "Copias de seguridad privadas"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Compartir en privado"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Enlace público creado"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Enlace público habilitado"),
        "radius": MessageLookupByLibrary.simpleMessage("Radio"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Generar ticket"),
        "rateTheApp":
            MessageLookupByLibrary.simpleMessage("Evalúa la aplicación"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Califícanos"),
        "rateUsOnStore": m36,
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
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Refiere a amigos y 2x su plan"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Dale este código a tus amigos"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Se inscriben a un plan pagado"),
        "referralStep3": m37,
        "referrals": MessageLookupByLibrary.simpleMessage("Referidos"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Las referencias están actualmente en pausa"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "También vacía \"Eliminado Recientemente\" de \"Configuración\" -> \"Almacenamiento\" para reclamar el espacio libre"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "También vacía tu \"Papelera\" para reclamar el espacio liberado"),
        "remoteImages":
            MessageLookupByLibrary.simpleMessage("Imágenes remotas"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Miniaturas remotas"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Videos remotos"),
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
        "removeParticipantBody": m38,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Quitar enlace público"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Algunos de los elementos que estás eliminando fueron añadidos por otras personas, y perderás el acceso a ellos"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Quitar?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Quitando de favoritos..."),
        "rename": MessageLookupByLibrary.simpleMessage("Renombrar"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Renombrar álbum"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Renombrar archivo"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Renovar suscripción"),
        "renewsOn": m39,
        "reportABug": MessageLookupByLibrary.simpleMessage("Reportar un error"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Reportar error"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Reenviar correo electrónico"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Restablecer archivos ignorados"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Restablecer contraseña"),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurar"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Restaurar al álbum"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Restaurando los archivos..."),
        "retry": MessageLookupByLibrary.simpleMessage("Reintentar"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Por favor, revise y elimine los elementos que cree que están duplicados."),
        "rotateLeft":
            MessageLookupByLibrary.simpleMessage("Girar a la izquierda"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Girar a la derecha"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Almacenado con seguridad"),
        "save": MessageLookupByLibrary.simpleMessage("Guardar"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Guardar copia"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Guardar Clave"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Guarda tu clave de recuperación si aún no lo has hecho"),
        "saving": MessageLookupByLibrary.simpleMessage("Saving..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Escanear código"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Escanea este código QR con tu aplicación de autenticación"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Nombre del álbum"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Nombres de álbumes (por ejemplo, \"Cámara\")\n• Tipos de archivos (por ejemplo, \"Videos\", \".gif\")\n• Años y meses (por ejemplo, \"2022\", \"Enero\")\n• Vacaciones (por ejemplo, \"Navidad\")\n• Descripciones fotográficas (por ejemplo, \"#diversión\")"),
        "searchHintText": MessageLookupByLibrary.simpleMessage(
            "Álbunes, meses, días, años, ..."),
        "security": MessageLookupByLibrary.simpleMessage("Seguridad"),
        "selectAlbum":
            MessageLookupByLibrary.simpleMessage("Seleccionar álbum"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Seleccionar todos"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Seleccionar carpetas para el respaldo"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Seleccionar idioma"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Seleccionar motivo"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Elegir tu suscripción"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Los archivos seleccionados no están en ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Las carpetas seleccionadas se cifrarán y se respaldarán"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Los archivos seleccionados serán eliminados de todos los álbumes y movidos a la papelera."),
        "selectedPhotos": m40,
        "selectedPhotosWithYours": m41,
        "send": MessageLookupByLibrary.simpleMessage("Enviar"),
        "sendEmail":
            MessageLookupByLibrary.simpleMessage("Enviar correo electrónico"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Enviar invitación"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Enviar enlace"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("La sesión ha expirado"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Establecer una contraseña"),
        "setAs": MessageLookupByLibrary.simpleMessage("Establecer como"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Establecer"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Establecer contraseña"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Establecer radio"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configuración completa"),
        "share": MessageLookupByLibrary.simpleMessage("Compartir"),
        "shareALink":
            MessageLookupByLibrary.simpleMessage("Compartir un enlace"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Abre un álbum y pulsa el botón compartir en la parte superior derecha para compartir."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Compartir un álbum ahora"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Compartir enlace"),
        "shareMyVerificationID": m42,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Comparte sólo con la gente que quieres"),
        "shareTextConfirmOthersVerificationID": m43,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Descarga ente para que podamos compartir fácilmente fotos y videos en su calidad original\n\nhttps://ente.io"),
        "shareTextReferralCode": m44,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Compartir con usuarios no ente"),
        "shareWithPeopleSectionTitle": m45,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Comparte tu primer álbum"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Crear álbumes compartidos y colaborativos con otros usuarios ente, incluyendo usuarios en planes gratuitos."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Compartido por mí"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Shared by you"),
        "sharedWith": m46,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Compartido conmigo"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Shared with you"),
        "sharing": MessageLookupByLibrary.simpleMessage("Compartiendo..."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Estoy de acuerdo con los <u-terms>términos del servicio</u-terms> y <u-policy> la política de privacidad</u-policy>"),
        "singleFileDeleteFromDevice": m47,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Se borrará de todos los álbumes."),
        "singleFileInBothLocalAndRemote": m48,
        "singleFileInRemoteOnly": m49,
        "skip": MessageLookupByLibrary.simpleMessage("Omitir"),
        "social": MessageLookupByLibrary.simpleMessage("Social"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Algunos elementos están tanto en ente como en tu dispositivo."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Algunos de los archivos que estás intentando eliminar sólo están disponibles en tu dispositivo y no se pueden recuperar si se eliminan"),
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
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Lo sentimos, el código que ha introducido es incorrecto"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Lo sentimos, no hemos podido generar claves seguras en este dispositivo.\n\nRegístrate desde un dispositivo diferente."),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Éxito"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Iniciar copia de seguridad"),
        "storage": MessageLookupByLibrary.simpleMessage("Almacenamiento"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Familia"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Usted"),
        "storageInGB": m50,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Límite de datos excedido"),
        "storageUsageInfo": m51,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Segura"),
        "subAlreadyLinkedErrMessage": m52,
        "subWillBeCancelledOn": m53,
        "subscribe": MessageLookupByLibrary.simpleMessage("Suscribirse"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Parece que su suscripción ha caducado. Por favor, suscríbase para habilitar el compartir."),
        "subscription": MessageLookupByLibrary.simpleMessage("Suscripción"),
        "success": MessageLookupByLibrary.simpleMessage("Éxito"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Archivado correctamente"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Desarchivado correctamente"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Sugerir una característica"),
        "support": MessageLookupByLibrary.simpleMessage("Soporte"),
        "syncProgress": m54,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Sincronización detenida"),
        "syncing": MessageLookupByLibrary.simpleMessage("Sincronizando..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistema"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("toque para copiar"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Toca para introducir el código"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Parece que algo salió mal. Por favor, vuelve a intentarlo después de algún tiempo. Si el error persiste, ponte en contacto con nuestro equipo de soporte."),
        "terminate": MessageLookupByLibrary.simpleMessage("Terminar"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("¿Terminar sesión?"),
        "terms": MessageLookupByLibrary.simpleMessage("Términos"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Términos"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Gracias"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("¡Gracias por suscribirte!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "No se ha podido completar la descarga"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "La clave de recuperación introducida es incorrecta"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Estos elementos se eliminarán de tu dispositivo."),
        "theyAlsoGetXGb": m55,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Se borrarán de todos los álbumes."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Esta acción no se puede deshacer"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Este álbum ya tiene un enlace de colaboración"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Esto puede utilizarse para recuperar su cuenta si pierde su segundo factor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Este dispositivo"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Este correo electrónico ya está en uso"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Esta imagen no tiene datos exif"),
        "thisIsPersonVerificationId": m56,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Esta es tu ID de verificación"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Esto cerrará la sesión del siguiente dispositivo:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "¡Esto cerrará la sesión de este dispositivo!"),
        "time": MessageLookupByLibrary.simpleMessage("Tiempo"),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Para ocultar una foto o video"),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Registros de hoy"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Tamaño total"),
        "trash": MessageLookupByLibrary.simpleMessage("Papelera"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Inténtelo de nuevo"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Activar la copia de seguridad para subir automáticamente archivos añadidos a la carpeta de este dispositivo hacia ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 meses gratis en planes anuales"),
        "twofactor": MessageLookupByLibrary.simpleMessage("Dos factores"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "La autenticación de dos factores fue deshabilitada"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Autenticación en dos pasos"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Autenticación de doble factor restablecida con éxito"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Configuración de dos pasos"),
        "unarchive": MessageLookupByLibrary.simpleMessage("Desarchivar"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Desarchivar álbum"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("Desarchivando..."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Sin categorizar"),
        "unhide": MessageLookupByLibrary.simpleMessage("Dejar de ocultar"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Hacer visible al álbum"),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Desocultar archivos al álbum"),
        "unlock": MessageLookupByLibrary.simpleMessage("Desbloquear"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar todos"),
        "update": MessageLookupByLibrary.simpleMessage("Actualizar"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Actualizacion disponible"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Actualizando la selección de carpeta..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Mejorar"),
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Subiendo archivos al álbum..."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "El almacenamiento utilizable está limitado por su plan actual. El exceso de almacenamiento reclamado se volverá automáticamente utilizable cuando actualice su plan."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Usa enlaces públicos para personas que no están en ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Usar clave de recuperación"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Usar foto seleccionada"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Espacio usado"),
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verificación fallida, por favor intenta nuevamente"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de verificación"),
        "verify": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage(
            "Verificar correo electrónico"),
        "verifyEmailID": m58,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verificar contraseña"),
        "verifying": MessageLookupByLibrary.simpleMessage("Verificando..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verificando clave de recuperación..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vídeo"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Ver sesiones activas"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Ver todos los datos EXIF"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Ver Registros"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ver código de recuperación"),
        "viewer": MessageLookupByLibrary.simpleMessage("Espectador"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Por favor visite web.ente.io para administrar su suscripción"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("¡Somos de código abierto!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "No admitimos la edición de fotos y álbunes que aún no son tuyos"),
        "weHaveSendEmailTo": m59,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Poco segura"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("¡Bienvenido de nuevo!"),
        "yearly": MessageLookupByLibrary.simpleMessage("Anualmente"),
        "yearsAgo": m60,
        "yes": MessageLookupByLibrary.simpleMessage("Sí"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Sí, cancelar"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Sí, convertir a espectador"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Sí, eliminar"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Sí, descartar cambios"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Sí, cerrar sesión"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Sí, quitar"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Sí, Renovar"),
        "you": MessageLookupByLibrary.simpleMessage("Usted"),
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("¡Estás en un plan familiar!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Estás usando la última versión"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Puedes al máximo duplicar tu almacenamiento"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Puedes administrar tus enlaces en la pestaña compartir."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Puedes intentar buscar una consulta diferente."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "No puedes degradar a este plan"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "No puedes compartir contigo mismo"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "No tienes nada de elementos archivados."),
        "youHaveSuccessfullyFreedUp": m61,
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
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("Tu suscripción ha caducado"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Tu suscripción se ha actualizado con éxito"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Tu código de verificación ha expirado"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "No tienes archivos duplicados que puedan ser borrados"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "No tienes archivos en este álbum que puedan ser borrados")
      };
}
