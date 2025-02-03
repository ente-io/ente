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

  static String m9(count) =>
      "${Intl.plural(count, zero: 'Añadir colaborador', one: 'Añadir colaborador', other: 'Añadir colaboradores')}";

  static String m10(count) =>
      "${Intl.plural(count, one: 'Agregar elemento', other: 'Agregar elementos')}";

  static String m11(storageAmount, endDate) =>
      "Tu ${storageAmount} adicional es válido hasta ${endDate}";

  static String m12(count) =>
      "${Intl.plural(count, zero: 'Añadir espectador', one: 'Añadir espectador', other: 'Añadir espectadores')}";

  static String m13(emailOrName) => "Añadido por ${emailOrName}";

  static String m14(albumName) => "Añadido exitosamente a  ${albumName}";

  static String m15(count) =>
      "${Intl.plural(count, zero: 'No hay Participantes', one: '1 Participante', other: '${count} Participantes')}";

  static String m16(versionValue) => "Versión: ${versionValue}";

  static String m17(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} gratis";

  static String m18(paymentProvider) =>
      "Por favor, cancela primero tu suscripción existente de ${paymentProvider}";

  static String m3(user) =>
      "${user} no podrá añadir más fotos a este álbum\n\nTodavía podrán eliminar las fotos ya añadidas por ellos";

  static String m19(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Tu familia ha obtenido ${storageAmountInGb} GB hasta el momento',
            'false': 'Tú has obtenido ${storageAmountInGb} GB hasta el momento',
            'other':
                '¡Tú has obtenido ${storageAmountInGb} GB hasta el momento!',
          })}";

  static String m20(albumName) =>
      "Enlace colaborativo creado para ${albumName}";

  static String m21(count) =>
      "${Intl.plural(count, zero: '0 colaboradores añadidos', one: '1 colaborador añadido', other: '${count} colaboradores añadidos')}";

  static String m22(email, numOfDays) =>
      "Estás a punto de añadir ${email} como un contacto de confianza. Esta persona podrá recuperar tu cuenta si no estás durante ${numOfDays} días.";

  static String m23(familyAdminEmail) =>
      "Por favor contacta con <green>${familyAdminEmail}</green> para administrar tu suscripción";

  static String m24(provider) =>
      "Por favor, contáctanos en support@ente.io para gestionar tu suscripción a ${provider}.";

  static String m25(endpoint) => "Conectado a ${endpoint}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'Elimina ${count} elemento', other: 'Elimina ${count} elementos')}";

  static String m27(currentlyDeleting, totalCount) =>
      "Borrando ${currentlyDeleting} / ${totalCount}";

  static String m28(albumName) =>
      "Esto eliminará el enlace público para acceder a \"${albumName}\".";

  static String m29(supportEmail) =>
      "Por favor, envía un correo electrónico a ${supportEmail} desde tu dirección de correo electrónico que usó para registrarse";

  static String m30(count, storageSaved) =>
      "¡Has limpiado ${Intl.plural(count, one: '${count} archivo duplicado', other: '${count} archivos duplicados')}, ahorrando (${storageSaved}!)";

  static String m31(count, formattedSize) =>
      "${count} archivos, ${formattedSize} cada uno";

  static String m32(newEmail) => "Correo cambiado a ${newEmail}";

  static String m33(email) =>
      "${email} no tiene una cuente en Ente.\n\nEnvíale una invitación para compartir fotos.";

  static String m34(text) => "Fotos adicionales encontradas para ${text}";

  static String m35(count, formattedNumber) =>
      "Se ha realizado la copia de seguridad de ${Intl.plural(count, one: '1 archivo', other: '${formattedNumber} archivos')} de este dispositivo de forma segura";

  static String m36(count, formattedNumber) =>
      "Se ha realizado la copia de seguridad de ${Intl.plural(count, one: '1 archivo', other: '${formattedNumber} archivos')} de este álbum de forma segura";

  static String m4(storageAmountInGB) =>
      "${storageAmountInGB} GB cada vez que alguien se registra en un plan de pago y aplica tu código";

  static String m37(endDate) => "Prueba gratuita válida hasta ${endDate}";

  static String m38(count) =>
      "Aún puedes acceder ${Intl.plural(count, one: 'a él', other: 'a ellos')} en Ente mientras tengas una suscripción activa";

  static String m39(sizeInMBorGB) => "Liberar ${sizeInMBorGB}";

  static String m40(count, formattedSize) =>
      "${Intl.plural(count, one: 'Se puede eliminar del dispositivo para liberar ${formattedSize}', other: 'Se pueden eliminar del dispositivo para liberar ${formattedSize}')}";

  static String m41(currentlyProcessing, totalCount) =>
      "Procesando ${currentlyProcessing} / ${totalCount}";

  static String m42(count) =>
      "${Intl.plural(count, one: '${count} elemento', other: '${count} elementos')}";

  static String m43(email) =>
      "${email} te ha invitado a ser un contacto de confianza";

  static String m44(expiryTime) => "El enlace caducará en ${expiryTime}";

  static String m5(count, formattedCount) =>
      "${Intl.plural(count, zero: 'sin recuerdos', one: '${formattedCount} recuerdo', other: '${formattedCount} recuerdos')}";

  static String m45(count) =>
      "${Intl.plural(count, one: 'Mover elemento', other: 'Mover elementos')}";

  static String m46(albumName) => "Movido exitosamente a ${albumName}";

  static String m47(personName) => "No hay sugerencias para ${personName}";

  static String m48(name) => "¿No es ${name}?";

  static String m49(familyAdminEmail) =>
      "Por favor, contacta a ${familyAdminEmail} para cambiar tu código.";

  static String m0(passwordStrengthValue) =>
      "Seguridad de la contraseña: ${passwordStrengthValue}";

  static String m50(providerName) =>
      "Por favor, habla con el soporte de ${providerName} si se te cobró";

  static String m51(count) =>
      "${Intl.plural(count, zero: '0 fotos', one: '1 foto', other: '${count} fotos')}";

  static String m52(endDate) =>
      "Prueba gratuita válida hasta ${endDate}.\nPuedes elegir un plan de pago después.";

  static String m53(toEmail) =>
      "Por favor, envíanos un correo electrónico a ${toEmail}";

  static String m54(toEmail) => "Por favor, envía los registros a ${toEmail}";

  static String m55(folderName) => "Procesando ${folderName}...";

  static String m56(storeName) => "Puntúanos en ${storeName}";

  static String m57(days, email) =>
      "Puedes acceder a la cuenta después de ${days} días. Se enviará una notificación a ${email}.";

  static String m58(email) =>
      "Ahora puedes recuperar la cuenta de ${email} estableciendo una nueva contraseña.";

  static String m59(email) => "${email} está intentando recuperar tu cuenta.";

  static String m60(storageInGB) =>
      "3. Ambos obtienen ${storageInGB} GB* gratis";

  static String m61(userEmail) =>
      "${userEmail} será eliminado de este álbum compartido\n\nCualquier foto añadida por ellos también será eliminada del álbum";

  static String m62(endDate) => "La suscripción se renueva el ${endDate}";

  static String m63(count) =>
      "${Intl.plural(count, one: '${count} resultado encontrado', other: '${count} resultados encontrados')}";

  static String m64(snapshotLength, searchLength) =>
      "La longitud de las secciones no coincide: ${snapshotLength} != ${searchLength}";

  static String m6(count) => "${count} seleccionados";

  static String m65(count, yourCount) =>
      "${count} seleccionados (${yourCount} tuyos)";

  static String m66(verificationID) =>
      "Aquí está mi ID de verificación: ${verificationID} para ente.io.";

  static String m7(verificationID) =>
      "Hola, ¿puedes confirmar que esta es tu ID de verificación ente.io: ${verificationID}?";

  static String m67(referralCode, referralStorageInGB) =>
      "Código de referido de Ente: ${referralCode} \n\nAñádelo en Ajustes → General → Referidos para obtener ${referralStorageInGB} GB gratis tras comprar un plan de pago.\n\nhttps://ente.io";

  static String m68(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Compartir con personas específicas', one: 'Compartido con 1 persona', other: 'Compartido con ${numberOfPeople} personas')}";

  static String m69(emailIDs) => "Compartido con ${emailIDs}";

  static String m70(fileType) =>
      "Este ${fileType} se eliminará de tu dispositivo.";

  static String m71(fileType) =>
      "Este ${fileType} está tanto en Ente como en tu dispositivo.";

  static String m72(fileType) => "Este ${fileType} será eliminado de Ente.";

  static String m1(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m73(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} de ${totalAmount} ${totalStorageUnit} usados";

  static String m74(id) =>
      "Tu ${id} ya está vinculada a otra cuenta de Ente.\nSi deseas utilizar tu ${id} con esta cuenta, ponte en contacto con nuestro servicio de asistencia\'\'";

  static String m75(endDate) => "Tu suscripción se cancelará el ${endDate}";

  static String m76(completed, total) =>
      "${completed}/${total} recuerdos conservados";

  static String m77(ignoreReason) =>
      "Toca para subir, la subida se está ignorando debido a ${ignoreReason}";

  static String m8(storageAmountInGB) =>
      "También obtienen ${storageAmountInGB} GB";

  static String m78(email) => "Este es el ID de verificación de ${email}";

  static String m79(count) =>
      "${Intl.plural(count, zero: 'Pronto', one: '1 día', other: '${count} días')}";

  static String m80(email) =>
      "Has sido invitado a ser un contacto legado por ${email}.";

  static String m81(galleryType) =>
      "El tipo de galería ${galleryType} no es compatible con el renombrado";

  static String m82(ignoreReason) =>
      "La subida se ignoró debido a ${ignoreReason}";

  static String m83(count) => "Preservando ${count} memorias...";

  static String m84(endDate) => "Válido hasta ${endDate}";

  static String m85(email) => "Verificar ${email}";

  static String m86(count) =>
      "${Intl.plural(count, zero: '0 espectadores añadidos', one: '1 espectador añadido', other: '${count} espectadores añadidos')}";

  static String m2(email) =>
      "Hemos enviado un correo a <green>${email}</green>";

  static String m87(count) =>
      "${Intl.plural(count, one: 'Hace ${count} año', other: 'Hace ${count} años')}";

  static String m88(storageSaved) => "¡Has liberado ${storageSaved} con éxito!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Hay una nueva versión de Ente disponible."),
        "about": MessageLookupByLibrary.simpleMessage("Acerca de"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Aceptar invitación"),
        "account": MessageLookupByLibrary.simpleMessage("Cuenta"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "La cuenta ya está configurada."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("¡Bienvenido de nuevo!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Entiendo que si pierdo mi contraseña podría perder mis datos, ya que mis datos están <underline>cifrados de extremo a extremo</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sesiones activas"),
        "add": MessageLookupByLibrary.simpleMessage("Añadir"),
        "addAName": MessageLookupByLibrary.simpleMessage("Añade un nombre"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage(
            "Agregar nuevo correo electrónico"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Agregar colaborador"),
        "addCollaborators": m9,
        "addFiles": MessageLookupByLibrary.simpleMessage("Añadir archivos"),
        "addFromDevice": MessageLookupByLibrary.simpleMessage(
            "Agregar desde el dispositivo"),
        "addItem": m10,
        "addLocation":
            MessageLookupByLibrary.simpleMessage("Agregar ubicación"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Añadir"),
        "addMore": MessageLookupByLibrary.simpleMessage("Añadir más"),
        "addName": MessageLookupByLibrary.simpleMessage("Añadir nombre"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Añadir nombre o combinar"),
        "addNew": MessageLookupByLibrary.simpleMessage("Añadir nuevo"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Añadir nueva persona"),
        "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
            "Detalles de los complementos"),
        "addOnValidTill": m11,
        "addOns": MessageLookupByLibrary.simpleMessage("Complementos"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Agregar fotos"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Agregar selección"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Añadir al álbum"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Añadir a Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Añadir al álbum oculto"),
        "addTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Añadir contacto de confianza"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Añadir espectador"),
        "addViewers": m12,
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Añade tus fotos ahora"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Agregado como"),
        "addedBy": m13,
        "addedSuccessfullyTo": m14,
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
        "albumParticipantsCount": m15,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Título del álbum"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Álbum actualizado"),
        "albums": MessageLookupByLibrary.simpleMessage("Álbumes"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Todo limpio"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
            "Todos los recuerdos preservados"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Se eliminarán todas las agrupaciones para esta persona, y se eliminarán todas sus sugerencias"),
        "allow": MessageLookupByLibrary.simpleMessage("Permitir"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permitir a las personas con el enlace añadir fotos al álbum compartido."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Permitir añadir fotos"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "Permitir a la aplicación abrir enlaces de álbum compartidos"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Permitir descargas"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Permitir que la gente añada fotos"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Por favor, permite el acceso a tus fotos desde Ajustes para que Ente pueda mostrar y hacer una copia de seguridad de tu biblioteca."),
        "allowPermTitle": MessageLookupByLibrary.simpleMessage(
            "Permitir el acceso a las fotos"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Verificar identidad"),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
            "No reconocido. Inténtelo nuevamente."),
        "androidBiometricRequiredTitle": MessageLookupByLibrary.simpleMessage(
            "Autenticación biométrica necesaria"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Listo"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Se necesitan credenciales de dispositivo"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Se necesitan credenciales de dispositivo"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "La autenticación biométrica no está configurada en su dispositivo. \'Ve a Ajustes > Seguridad\' para añadir autenticación biométrica."),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
            "Android, iOS, Web, Computadora"),
        "androidSignInTitle": MessageLookupByLibrary.simpleMessage(
            "Se necesita autenticación biométrica"),
        "appLock":
            MessageLookupByLibrary.simpleMessage("Bloqueo de aplicación"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Escoge entre la pantalla de bloqueo por defecto de tu dispositivo y una pantalla de bloqueo personalizada con un PIN o contraseña."),
        "appVersion": m16,
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
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "¿Estás seguro de que deseas salir?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "¿Estás seguro de que quieres cerrar la sesión?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "¿Estás seguro de que quieres renovar?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "¿Seguro que desea eliminar esta persona?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Tu suscripción ha sido cancelada. ¿Quieres compartir el motivo?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "¿Cuál es la razón principal por la que eliminas tu cuenta?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Pide a tus seres queridos que compartan"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("en un refugio blindado"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, autentícate para cambiar la verificación por correo electrónico"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentícate para cambiar la configuración de la pantalla de bloqueo"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentícate para cambiar tu correo electrónico"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentícate para cambiar tu contraseña"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, autentícate para configurar la autenticación de dos factores"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentícate para iniciar la eliminación de la cuenta"),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentícate para administrar tus contactos de confianza"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentícate para ver tu clave de acceso"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentícate para ver los archivos enviados a la papelera"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentícate para ver tus sesiones activas"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentícate para ver tus archivos ocultos"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentícate para ver tus recuerdos"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentícate para ver tu clave de recuperación"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Autenticando..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Error de autenticación, por favor inténtalo de nuevo"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("¡Autenticación exitosa!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Aquí verás los dispositivos de transmisión disponibles."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Asegúrate de que los permisos de la red local están activados para la aplicación Ente Fotos, en Configuración."),
        "autoLock": MessageLookupByLibrary.simpleMessage("Bloqueo automático"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Tiempo después de que la aplicación esté en segundo plano"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Debido a un fallo técnico, has sido desconectado. Nuestras disculpas por las molestias."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Emparejamiento automático"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "El emparejamiento automático funciona sólo con dispositivos compatibles con Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Disponible"),
        "availableStorageSpace": m17,
        "backedUpFolders": MessageLookupByLibrary.simpleMessage(
            "Carpetas con copia de seguridad"),
        "backup": MessageLookupByLibrary.simpleMessage("Copia de seguridad"),
        "backupFailed": MessageLookupByLibrary.simpleMessage(
            "La copia de seguridad ha fallado"),
        "backupFile": MessageLookupByLibrary.simpleMessage(
            "Archivo de copia de seguridad"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Copia de seguridad usando datos móviles"),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
            "Ajustes de copia de seguridad"),
        "backupStatus": MessageLookupByLibrary.simpleMessage(
            "Estado de la copia de seguridad"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Los elementos con copia seguridad aparecerán aquí"),
        "backupVideos": MessageLookupByLibrary.simpleMessage(
            "Copia de seguridad de vídeos"),
        "birthday": MessageLookupByLibrary.simpleMessage("Cumpleaños"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Oferta del Black Friday"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData":
            MessageLookupByLibrary.simpleMessage("Datos almacenados en caché"),
        "calculating": MessageLookupByLibrary.simpleMessage("Calculando..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Lo sentimos, este álbum no se puede abrir en la aplicación."),
        "canNotOpenTitle": MessageLookupByLibrary.simpleMessage(
            "No es posible abrir este álbum"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "No se puede subir a álbumes que sean propiedad de otros"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Sólo puedes crear un enlace para archivos de tu propiedad"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Sólo puede eliminar archivos de tu propiedad"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Cancelar la recuperación"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "¿Estás seguro de que quieres cancelar la recuperación?"),
        "cancelOtherSubscription": m18,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Cancelar suscripción"),
        "cannotAddMorePhotosAfterBecomingViewer": m3,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "No se pueden eliminar los archivos compartidos"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Enviar álbum"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Por favor, asegúrate de estar en la misma red que el televisor."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("Error al transmitir álbum"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Visita cast.ente.io en el dispositivo que quieres emparejar.\n\nIntroduce el código de abajo para reproducir el álbum en tu TV."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Punto central"),
        "change": MessageLookupByLibrary.simpleMessage("Cambiar"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Cambiar correo electrónico"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "¿Cambiar la ubicación de los elementos seleccionados?"),
        "changeLogBackupStatusContent": MessageLookupByLibrary.simpleMessage(
            "Hemos añadido un registro de todos los archivos que han sido subidos a Ente, incluyendo los fallos y los que están en cola."),
        "changeLogBackupStatusTitle": MessageLookupByLibrary.simpleMessage(
            "Estado de la copia de seguridad"),
        "changeLogDiscoverContent": MessageLookupByLibrary.simpleMessage(
            "¿Buscas fotos de tus documentos de identidad, notas o incluso memes? Ve a la pestaña de búsqueda y consulta Descubrir. Según nuestra búsqueda semántica, es un lugar para encontrar fotos que podrían ser importantes para ti.\\n\\nSolo disponible si has activado el aprendizaje automático."),
        "changeLogDiscoverTitle":
            MessageLookupByLibrary.simpleMessage("Descubrir"),
        "changeLogMagicSearchImprovementContent":
            MessageLookupByLibrary.simpleMessage(
                "Hemos mejorado la búsqueda mágica para que sea mucho más rápida, así no tienes que esperar para encontrar lo que estás buscando."),
        "changeLogMagicSearchImprovementTitle":
            MessageLookupByLibrary.simpleMessage(
                "Mejora de la búsqueda mágica"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Cambiar contraseña"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Cambiar contraseña"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("¿Cambiar permisos?"),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
            "Cambiar tu código de referido"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Comprobar actualizaciónes"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Revisa tu bandeja de entrada (y spam) para completar la verificación"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Comprobar estado"),
        "checking": MessageLookupByLibrary.simpleMessage("Comprobando..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Comprobando modelos..."),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
            "Obtén almacenamiento gratuito"),
        "claimMore": MessageLookupByLibrary.simpleMessage("¡Obtén más!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Obtenido"),
        "claimedStorageSoFar": m19,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Limpiar sin categorizar"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Elimina todos los archivos de Sin categorizar que están presentes en otros álbumes"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Limpiar cachés"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Limpiar índices"),
        "click": MessageLookupByLibrary.simpleMessage("• Clic"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Haga clic en el menú desbordante"),
        "close": MessageLookupByLibrary.simpleMessage("Cerrar"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
            "Agrupar por tiempo de captura"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Club por nombre de archivo"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Proceso de agrupación"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Código aplicado"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Lo sentimos, has alcanzado el límite de cambios de códigos."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Código copiado al portapapeles"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Código usado por ti"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Crea un enlace para permitir que otros pueda añadir y ver fotos en tu álbum compartido sin necesitar la aplicación Ente o una cuenta. Genial para recolectar fotos de eventos."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Enlace colaborativo"),
        "collaborativeLinkCreatedFor": m20,
        "collaborator": MessageLookupByLibrary.simpleMessage("Colaborador"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Colaboradores pueden añadir fotos y videos al álbum compartido."),
        "collaboratorsSuccessfullyAdded": m21,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Disposición"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
            "Collage guardado en la galería"),
        "collect": MessageLookupByLibrary.simpleMessage("Recolectar"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Recopilar fotos del evento"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Recolectar fotos"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Crea un enlace donde tus amigos pueden subir fotos en su calidad original."),
        "color": MessageLookupByLibrary.simpleMessage("Color"),
        "configuration": MessageLookupByLibrary.simpleMessage("Configuración"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "¿Estás seguro de que deseas deshabilitar la autenticación de doble factor?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Confirmar borrado de cuenta"),
        "confirmAddingTrustedContact": m22,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Sí, quiero eliminar permanentemente esta cuenta y todos sus datos en todas las aplicaciones."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirmar contraseña"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Confirmar los cambios en el plan"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmar clave de recuperación"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirma tu clave de recuperación"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Conectar a dispositivo"),
        "contactFamilyAdmin": m23,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contactar con soporte"),
        "contactToManageSubscription": m24,
        "contacts": MessageLookupByLibrary.simpleMessage("Contactos"),
        "contents": MessageLookupByLibrary.simpleMessage("Contenidos"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuar"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Continuar con el plan gratuito"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Convertir a álbum"),
        "copyEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Copiar dirección de correo electrónico"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copiar enlace"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copia y pega este código\na tu aplicación de autenticador"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "No pudimos hacer una copia de seguridad de tus datos.\nVolveremos a intentarlo más tarde."),
        "couldNotFreeUpSpace":
            MessageLookupByLibrary.simpleMessage("No se pudo liberar espacio"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "No se pudo actualizar la suscripción"),
        "count": MessageLookupByLibrary.simpleMessage("Cuenta"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Reporte de errores"),
        "create": MessageLookupByLibrary.simpleMessage("Crear"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Crear cuenta"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Manten presionado para seleccionar fotos y haz clic en + para crear un álbum"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Crear enlace colaborativo"),
        "createCollage":
            MessageLookupByLibrary.simpleMessage("Crear un collage"),
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
        "crop": MessageLookupByLibrary.simpleMessage("Ajustar encuadre"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("El uso actual es de "),
        "currentlyRunning": MessageLookupByLibrary.simpleMessage("ejecutando"),
        "custom": MessageLookupByLibrary.simpleMessage("Personalizado"),
        "customEndpoint": m25,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Oscuro"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Hoy"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Ayer"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Rechazar invitación"),
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
            "Eliminar cuenta permanentemente"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Borrar álbum"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "¿También eliminar las fotos (y los vídeos) presentes en este álbum de <bold>todos</bold> los otros álbumes de los que forman parte?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Esto eliminará todos los álbumes vacíos. Esto es útil cuando quieres reducir el desorden en tu lista de álbumes."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Borrar Todo"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Esta cuenta está vinculada a otras aplicaciones de Ente, si utilizas alguna. Se programará la eliminación de los datos cargados en todas las aplicaciones de Ente, y tu cuenta se eliminará permanentemente."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Por favor, envía un correo electrónico a <warning>account-deletion@ente.io</warning> desde la dirección de correo electrónico que usó para registrarse."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Eliminar álbumes vacíos"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("¿Eliminar álbumes vacíos?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Eliminar de ambos"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Eliminar del dispositivo"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Eliminar de Ente"),
        "deleteItemCount": m26,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Borrar la ubicación"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Borrar las fotos"),
        "deleteProgress": m27,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Falta una característica clave que necesito"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "La aplicación o una característica determinada no se comporta como creo que debería"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "He encontrado otro servicio que me gusta más"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
            "Mi motivo no se encuentra en la lista"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Tu solicitud será procesada dentro de las siguientes 72 horas."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("¿Borrar álbum compartido?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "El álbum se eliminará para todos\n\nPerderás el acceso a las fotos compartidas en este álbum que son propiedad de otros"),
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Deseleccionar todo"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Diseñado para sobrevivir"),
        "details": MessageLookupByLibrary.simpleMessage("Detalles"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Ajustes de desarrollador"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "¿Estás seguro de que quieres modificar los ajustes de desarrollador?"),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Introduce el código"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Los archivos añadidos a este álbum de dispositivo se subirán automáticamente a Ente."),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Bloqueo del dispositivo"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Deshabilita el bloqueo de pantalla del dispositivo cuando Ente está en primer plano y haya una copia de seguridad en curso. Normalmente esto no es necesario, pero puede ayudar a que las grandes cargas y las importaciones iniciales de grandes bibliotecas se completen más rápido."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Dispositivo no encontrado"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("¿Sabías que?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Desactivar bloqueo automático"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Los espectadores todavía pueden tomar capturas de pantalla o guardar una copia de tus fotos usando herramientas externas"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Por favor, ten en cuenta"),
        "disableLinkMessage": m28,
        "disableTwofactor":
            MessageLookupByLibrary.simpleMessage("Deshabilitar dos factores"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Deshabilitando la autenticación de dos factores..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Descubrir"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Bebés"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Celebraciones"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Comida"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Verdor"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Colinas"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identidad"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Memes"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Notas"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Mascotas"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Recibos"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Capturas de pantalla"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfies"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Atardecer"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Tarjetas de visita"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Fondos de pantalla"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Descartar"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut":
            MessageLookupByLibrary.simpleMessage("No cerrar la sesión"),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Hacerlo más tarde"),
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
        "dropSupportEmail": m29,
        "duplicateFileCountWithStorageSaved": m30,
        "duplicateItemsGroup": m31,
        "edit": MessageLookupByLibrary.simpleMessage("Editar"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Editar la ubicación"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Editar la ubicación"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Editar persona"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Ediciones guardadas"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Las ediciones a la ubicación sólo se verán dentro de Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("elegible"),
        "email": MessageLookupByLibrary.simpleMessage("Correo electrónico"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
            "Correo electrónico ya registrado."),
        "emailChangedTo": m32,
        "emailNoEnteAccount": m33,
        "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
            "Correo electrónico no registrado."),
        "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
            "Verificación por correo electrónico"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "Envía tus registros por correo electrónico"),
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Contactos de emergencia"),
        "empty": MessageLookupByLibrary.simpleMessage("Vaciar"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("¿Vaciar la papelera?"),
        "enable": MessageLookupByLibrary.simpleMessage("Habilitar"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente soporta aprendizaje automático en el dispositivo para la detección de caras, búsqueda mágica y otras características de búsqueda avanzada"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Activar aprendizaje automático para búsqueda mágica y reconocimiento facial"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Activar Mapas"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Esto mostrará tus fotos en el mapa mundial.\n\nEste mapa está gestionado por Open Street Map, y la ubicación exacta de tus fotos nunca se comparte.\n\nPuedes deshabilitar esta función en cualquier momento en Ajustes."),
        "enabled": MessageLookupByLibrary.simpleMessage("Habilitado"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
            "Cifrando copia de seguridad..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Cifrado"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Claves de cifrado"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Punto final actualizado con éxito"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Encriptado de extremo a extremo por defecto"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente puede cifrar y preservar archivos solo si concedes acceso a ellos"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>necesita permiso para</i> preservar tus fotos"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente conserva tus recuerdos, así que siempre están disponibles para ti, incluso si pierdes tu dispositivo."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Tu familia también puede ser agregada a tu plan."),
        "enterAlbumName": MessageLookupByLibrary.simpleMessage(
            "Introduce el nombre del álbum"),
        "enterCode":
            MessageLookupByLibrary.simpleMessage("Introduce el código"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Introduce el código proporcionado por tu amigo para reclamar almacenamiento gratuito para ambos"),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Cumpleaños (opcional)"),
        "enterEmail": MessageLookupByLibrary.simpleMessage(
            "Ingresar correo electrónico "),
        "enterFileName": MessageLookupByLibrary.simpleMessage(
            "Introduce el nombre del archivo"),
        "enterName": MessageLookupByLibrary.simpleMessage("Introducir nombre"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Introduce una nueva contraseña que podamos usar para cifrar tus datos"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Introduzca contraseña"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Introduce una contraseña que podamos usar para cifrar tus datos"),
        "enterPersonName": MessageLookupByLibrary.simpleMessage(
            "Ingresar el nombre de una persona"),
        "enterPin":
            MessageLookupByLibrary.simpleMessage("Ingresa tu contraseña"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
            "Introduce el código de referido"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Ingresa el código de seis dígitos de tu aplicación de autenticación"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Por favor, introduce una dirección de correo electrónico válida."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Escribe tu correo electrónico"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Ingresa tu contraseña"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Introduce tu clave de recuperación"),
        "error": MessageLookupByLibrary.simpleMessage("Error"),
        "everywhere": MessageLookupByLibrary.simpleMessage("todas partes"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Usuario existente"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Este enlace ha caducado. Por favor, selecciona una nueva fecha de caducidad o deshabilita la fecha de caducidad."),
        "exportLogs":
            MessageLookupByLibrary.simpleMessage("Exportar registros"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exportar tus datos"),
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
            "Fotos adicionales encontradas"),
        "extraPhotosFoundFor": m34,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Cara no agrupada todavía, por favor vuelve más tarde"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Reconocimiento facial"),
        "faces": MessageLookupByLibrary.simpleMessage("Caras"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Error al aplicar el código"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Error al cancelar"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Error al descargar el vídeo"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Error al recuperar las sesiones activas"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "No se pudo obtener el original para editar"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "No se pueden obtener los detalles de la referencia. Por favor, inténtalo de nuevo más tarde."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Error al cargar álbumes"),
        "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Error al reproducir el video"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Error al actualizar la suscripción"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Renovación fallida"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Error al verificar el estado de tu pago"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Añade 5 familiares a tu plan existente sin pagar más.\n\nCada miembro tiene su propio espacio privado y no puede ver los archivos del otro a menos que sean compartidos.\n\nLos planes familiares están disponibles para los clientes que tienen una suscripción de Ente pagada.\n\n¡Suscríbete ahora para empezar!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Familia"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Planes familiares"),
        "faq": MessageLookupByLibrary.simpleMessage("Preguntas Frecuentes"),
        "faqs": MessageLookupByLibrary.simpleMessage("Preguntas frecuentes"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorito"),
        "feedback": MessageLookupByLibrary.simpleMessage("Sugerencias"),
        "file": MessageLookupByLibrary.simpleMessage("Archivo"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "No se pudo guardar el archivo en la galería"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Añadir descripción..."),
        "fileNotUploadedYet": MessageLookupByLibrary.simpleMessage(
            "El archivo aún no se ha subido"),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Archivo guardado en la galería"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Tipos de archivos"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Tipos de archivo y nombres"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Archivos eliminados"),
        "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Archivo guardado en la galería"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Encuentra gente rápidamente por su nombre"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("Encuéntralos rápidamente"),
        "flip": MessageLookupByLibrary.simpleMessage("Voltear"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("para tus recuerdos"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Olvidé mi contraseña"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Caras encontradas"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Almacenamiento gratuito obtenido"),
        "freeStorageOnReferralSuccess": m4,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Almacenamiento libre disponible"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Prueba gratuita"),
        "freeTrialValidTill": m37,
        "freeUpAccessPostDelete": m38,
        "freeUpAmount": m39,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Liberar espacio del dispositivo"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Ahorra espacio en tu dispositivo limpiando archivos que tienen copia de seguridad."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Liberar espacio"),
        "freeUpSpaceSaving": m40,
        "gallery": MessageLookupByLibrary.simpleMessage("Galería"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Hasta 1000 memorias mostradas en la galería"),
        "general": MessageLookupByLibrary.simpleMessage("General"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generando claves de cifrado..."),
        "genericProgress": m41,
        "goToSettings": MessageLookupByLibrary.simpleMessage("Ir a Ajustes"),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("ID de Google Play"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Por favor, permite el acceso a todas las fotos en Ajustes"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Conceder permiso"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("Agrupar fotos cercanas"),
        "guestView": MessageLookupByLibrary.simpleMessage("Vista de invitado"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Para habilitar la vista de invitados, por favor configure el código de acceso del dispositivo o el bloqueo de pantalla en los ajustes de su sistema."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "No rastreamos las aplicaciones instaladas. ¡Nos ayudarías si nos dijeras dónde nos encontraste!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "¿Cómo escuchaste acerca de Ente? (opcional)"),
        "help": MessageLookupByLibrary.simpleMessage("Ayuda"),
        "hidden": MessageLookupByLibrary.simpleMessage("Oculto"),
        "hide": MessageLookupByLibrary.simpleMessage("Ocultar"),
        "hideContent":
            MessageLookupByLibrary.simpleMessage("Ocultar contenido"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Oculta el contenido de la aplicación en el selector de aplicaciones y desactivar capturas de pantalla"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Ocultar el contenido de la aplicación en el selector de aplicaciones"),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "Ocultar elementos compartidos de la galería de inicio"),
        "hiding": MessageLookupByLibrary.simpleMessage("Ocultando..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Alojado en OSM France"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Cómo funciona"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Por favor, pídeles que mantengan presionada su dirección de correo electrónico en la pantalla de ajustes, y verifica que los identificadores de ambos dispositivos coincidan."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "La autenticación biométrica no está configurada en tu dispositivo. Por favor, activa Touch ID o Face ID en tu teléfono."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "La autenticación biométrica está deshabilitada. Por favor, bloquea y desbloquea la pantalla para habilitarla."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("Aceptar"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorar"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignorado"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Algunos archivos de este álbum son ignorados de la carga porque previamente habían sido borrados de Ente."),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Imagen no analizada"),
        "immediately": MessageLookupByLibrary.simpleMessage("Inmediatamente"),
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
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Elementos indexados"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "La indexación está pausada. Se reanudará automáticamente cuando el dispositivo esté listo."),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Dispositivo inseguro"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Instalar manualmente"),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Dirección de correo electrónico no válida"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Punto final no válido"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Lo sentimos, el punto final introducido no es válido. Por favor, introduce un punto final válido y vuelve a intentarlo."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Clave inválida"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "La clave de recuperación introducida no es válida. Por favor, asegúrate de que contenga 24 palabras y comprueba la ortografía de cada una.\n\nSi has introducido un código de recuperación antiguo, asegúrate de que tiene 64 caracteres de largo y comprueba cada uno de ellos."),
        "invite": MessageLookupByLibrary.simpleMessage("Invitar"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Invitar a Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invita a tus amigos"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Invita a tus amigos a Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Parece que algo salió mal. Por favor, vuelve a intentarlo después de algún tiempo. Si el error persiste, ponte en contacto con nuestro equipo de soporte."),
        "itemCount": m42,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Los artículos muestran el número de días restantes antes de ser borrados permanente"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Los elementos seleccionados serán eliminados de este álbum"),
        "join": MessageLookupByLibrary.simpleMessage("Unir"),
        "joinAlbum": MessageLookupByLibrary.simpleMessage("Unir álbum"),
        "joinAlbumSubtext":
            MessageLookupByLibrary.simpleMessage("para ver y añadir tus fotos"),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
            "para añadir esto a los álbumes compartidos"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("Únete al Discord"),
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
        "left": MessageLookupByLibrary.simpleMessage("Izquierda"),
        "legacy": MessageLookupByLibrary.simpleMessage("Legado"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Cuentas legadas"),
        "legacyInvite": m43,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "Legado permite a los contactos de confianza acceder a su cuenta en su ausencia."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Los contactos de confianza pueden iniciar la recuperación de la cuenta, y si no están bloqueados en un plazo de 30 días, restablecer su contraseña y acceder a su cuenta."),
        "light": MessageLookupByLibrary.simpleMessage("Brillo"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Claro"),
        "link": MessageLookupByLibrary.simpleMessage("Enlace"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Enlace copiado al portapapeles"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Límite del dispositivo"),
        "linkEmail":
            MessageLookupByLibrary.simpleMessage("Vincular correo electrónico"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Habilitado"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Vencido"),
        "linkExpiresOn": m44,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Enlace vence"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("El enlace ha caducado"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Nunca"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("Foto en vivo"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Puedes compartir tu suscripción con tu familia"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Hasta ahora hemos conservado más de 30 millones de recuerdos"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Guardamos 3 copias de tus datos, una en un refugio subterráneo"),
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
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Descargando modelos..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Cargando tus fotos..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galería local"),
        "localIndexing": MessageLookupByLibrary.simpleMessage("Indexado local"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Parece que algo salió mal ya que la sincronización de fotos locales está tomando más tiempo del esperado. Por favor contacta con nuestro equipo de soporte"),
        "location": MessageLookupByLibrary.simpleMessage("Ubicación"),
        "locationName":
            MessageLookupByLibrary.simpleMessage("Nombre de la ubicación"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Una etiqueta de ubicación agrupa todas las fotos que fueron tomadas dentro de un radio de una foto"),
        "locations": MessageLookupByLibrary.simpleMessage("Ubicaciones"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Bloquear"),
        "lockscreen":
            MessageLookupByLibrary.simpleMessage("Pantalla de bloqueo"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Iniciar sesión"),
        "loggingOut":
            MessageLookupByLibrary.simpleMessage("Cerrando sesión..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("La sesión ha expirado"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Tu sesión ha expirado. Por favor, vuelve a iniciar sesión."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Al hacer clic en iniciar sesión, acepto los <u-terms>términos de servicio</u-terms> y <u-policy>la política de privacidad</u-policy>"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("Iniciar sesión con TOTP"),
        "logout": MessageLookupByLibrary.simpleMessage("Cerrar sesión"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Esto enviará registros para ayudarnos a depurar su problema. Ten en cuenta que los nombres de los archivos se incluirán para ayudar a rastrear problemas con archivos específicos."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Mantén pulsado un correo electrónico para verificar el cifrado de extremo a extremo."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Manten presionado un elemento para ver en pantalla completa"),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("Vídeo en bucle desactivado"),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("Vídeo en bucle activado"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("¿Perdiste tu dispositivo?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Aprendizaje automático"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Búsqueda mágica"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "La búsqueda mágica permite buscar fotos por su contenido. Por ejemplo, \"flor\", \"coche rojo\", \"documentos de identidad\""),
        "manage": MessageLookupByLibrary.simpleMessage("Administrar"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Gestionar almacenamiento caché del dispositivo"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Revisar y borrar almacenamiento caché local."),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Administrar familia"),
        "manageLink":
            MessageLookupByLibrary.simpleMessage("Administrar enlace"),
        "manageParticipants":
            MessageLookupByLibrary.simpleMessage("Administrar"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Administrar tu suscripción"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "El emparejamiento con PIN funciona con cualquier pantalla en la que desees ver tu álbum."),
        "map": MessageLookupByLibrary.simpleMessage("Mapa"),
        "maps": MessageLookupByLibrary.simpleMessage("Mapas"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m5,
        "merchandise": MessageLookupByLibrary.simpleMessage("Mercancías"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Combinar con existente"),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Fotos combinadas"),
        "mlConsent": MessageLookupByLibrary.simpleMessage(
            "Habilitar aprendizaje automático"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Entiendo y deseo habilitar el aprendizaje automático"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Si habilitas el aprendizaje automático, Ente extraerá información como la geometría de la cara de los archivos, incluyendo aquellos compartidos contigo.\n\nEsto sucederá en tu dispositivo, y cualquier información biométrica generada será encriptada de extremo a extremo."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Por favor, haz clic aquí para más detalles sobre esta característica en nuestra política de privacidad"),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
            "¿Habilitar aprendizaje automático?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Por favor ten en cuenta que el aprendizaje automático dará como resultado un mayor consumo de ancho de banda y de batería hasta que todos los elementos estén indexados. Considera usar la aplicación de escritorio para una indexación más rápida. Todos los resultados se sincronizarán automáticamente."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Celular, Web, Computadora"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderada"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Modifica tu consulta o intenta buscar"),
        "moments": MessageLookupByLibrary.simpleMessage("Momentos"),
        "month": MessageLookupByLibrary.simpleMessage("mes"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensualmente"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Más detalles"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Más reciente"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Más relevante"),
        "moveItem": m45,
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Mover al álbum"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Mover al álbum oculto"),
        "movedSuccessfullyTo": m46,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Movido a la papelera"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Moviendo archivos al álbum..."),
        "name": MessageLookupByLibrary.simpleMessage("Nombre"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Nombre el álbum"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "No se puede conectar a Ente. Por favor, vuelve a intentarlo pasado un tiempo. Si el error persiste, ponte en contacto con el soporte técnico."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "No se puede conectar a Ente. Por favor, comprueba tu configuración de red y ponte en contacto con el soporte técnico si el error persiste."),
        "never": MessageLookupByLibrary.simpleMessage("Nunca"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nuevo álbum"),
        "newLocation":
            MessageLookupByLibrary.simpleMessage("Nueva localización"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Nueva persona"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Nuevo en Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Más reciente"),
        "next": MessageLookupByLibrary.simpleMessage("Siguiente"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Aún no has compartido ningún álbum"),
        "noDeviceFound": MessageLookupByLibrary.simpleMessage(
            "No se encontró ningún dispositivo"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Ninguno"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "No tienes archivos en este dispositivo que puedan ser borrados"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Sin duplicados"),
        "noEnteAccountExclamation": MessageLookupByLibrary.simpleMessage(
            "¡No existe una cuenta de Ente!"),
        "noExifData": MessageLookupByLibrary.simpleMessage("No hay datos EXIF"),
        "noFacesFound":
            MessageLookupByLibrary.simpleMessage("No se han encontrado caras"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "No hay fotos ni vídeos ocultos"),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
            "No hay imágenes con ubicación"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("No hay conexión al Internet"),
        "noPhotosAreBeingBackedUpRightNow": MessageLookupByLibrary.simpleMessage(
            "No se están realizando copias de seguridad de ninguna foto en este momento"),
        "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage(
            "No se encontró ninguna foto aquí"),
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
            "No se han seleccionado enlaces rápidos"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("¿Sin clave de recuperación?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Debido a la naturaleza de nuestro protocolo de cifrado de extremo a extremo, tus datos no pueden ser descifrados sin tu contraseña o clave de recuperación"),
        "noResults": MessageLookupByLibrary.simpleMessage("Sin resultados"),
        "noResultsFound": MessageLookupByLibrary.simpleMessage(
            "No se han encontrado resultados"),
        "noSuggestionsForPerson": m47,
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
            "Bloqueo de sistema no encontrado"),
        "notPersonLabel": m48,
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Aún no hay nada compartido contigo"),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
            "¡No hay nada que ver aquí! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notificaciones"),
        "ok": MessageLookupByLibrary.simpleMessage("Aceptar"),
        "onDevice": MessageLookupByLibrary.simpleMessage("En el dispositivo"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "En <branding>ente</branding>"),
        "onlyFamilyAdminCanChangeCode": m49,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Solo ellos"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Ups, no se pudieron guardar las ediciónes"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ups, algo salió mal"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("Abrir álbum en el navegador"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Por favor, utiliza la aplicación web para añadir fotos a este álbum"),
        "openFile": MessageLookupByLibrary.simpleMessage("Abrir archivo"),
        "openSettings": MessageLookupByLibrary.simpleMessage("Abrir Ajustes"),
        "openTheItem":
            MessageLookupByLibrary.simpleMessage("• Abrir el elemento"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
            "Contribuidores de OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Opcional, tan corto como quieras..."),
        "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
            "O combinar con persona existente"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("O elige uno existente"),
        "pair": MessageLookupByLibrary.simpleMessage("Emparejar"),
        "pairWithPin":
            MessageLookupByLibrary.simpleMessage("Emparejar con PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Emparejamiento completo"),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "La verificación aún está pendiente"),
        "passkey": MessageLookupByLibrary.simpleMessage("Clave de acceso"),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
            "Verificación de clave de acceso"),
        "password": MessageLookupByLibrary.simpleMessage("Contraseña"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Contraseña cambiada correctamente"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Bloqueo con contraseña"),
        "passwordStrength": m0,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "La fortaleza de la contraseña se calcula teniendo en cuenta la longitud de la contraseña, los caracteres utilizados, y si la contraseña aparece o no en el top 10.000 de contraseñas más usadas"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "No almacenamos esta contraseña, así que si la olvidas, <underline>no podremos descifrar tus datos</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Detalles de pago"),
        "paymentFailed": MessageLookupByLibrary.simpleMessage("Pago fallido"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Lamentablemente tu pago falló. Por favor, ¡contacta con el soporte técnico y te ayudaremos!"),
        "paymentFailedTalkToProvider": m50,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Elementos pendientes"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Sincronización pendiente"),
        "people": MessageLookupByLibrary.simpleMessage("Personas"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("Personas usando tu código"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Todos los elementos de la papelera serán eliminados permanentemente\n\nEsta acción no se puede deshacer"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Borrar permanentemente"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "¿Eliminar permanentemente del dispositivo?"),
        "personName":
            MessageLookupByLibrary.simpleMessage("Nombre de la persona"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Descripciones de fotos"),
        "photoGridSize": MessageLookupByLibrary.simpleMessage(
            "Tamaño de la cuadrícula de fotos"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "photos": MessageLookupByLibrary.simpleMessage("Fotos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Las fotos añadidas por ti serán removidas del álbum"),
        "photosCount": m51,
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Elegir punto central"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Fijar álbum"),
        "pinLock": MessageLookupByLibrary.simpleMessage("Bloqueo con Pin"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Reproducir álbum en TV"),
        "playStoreFreeTrialValidTill": m52,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Suscripción en la PlayStore"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, revisa tu conexión a Internet e inténtalo otra vez."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "¡Por favor, contacta con support@ente.io y estaremos encantados de ayudar!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, contacta a soporte técnico si el problema persiste"),
        "pleaseEmailUsAt": m53,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Por favor, concede permiso"),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
            "Por favor, vuelve a iniciar sesión"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Por favor, selecciona enlaces rápidos para eliminar"),
        "pleaseSendTheLogsTo": m54,
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage(
            "Por favor, inténtalo nuevamente"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, verifica el código que has introducido"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Por favor, espera..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Por favor espera. Borrando el álbum"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, espera un momento antes de volver a intentarlo"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Preparando registros..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Preservar más"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Presiona y mantén presionado para reproducir el video"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Mantén pulsada la imagen para reproducir el video"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacidad"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Política de Privacidad"),
        "privateBackups": MessageLookupByLibrary.simpleMessage(
            "Copias de seguridad privadas"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Compartir en privado"),
        "proceed": MessageLookupByLibrary.simpleMessage("Continuar"),
        "processed": MessageLookupByLibrary.simpleMessage("Procesado"),
        "processingImport": m55,
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Enlace público creado"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Enlace público habilitado"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Acceso rápido"),
        "radius": MessageLookupByLibrary.simpleMessage("Radio"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Generar ticket"),
        "rateTheApp":
            MessageLookupByLibrary.simpleMessage("Evalúa la aplicación"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Califícanos"),
        "rateUsOnStore": m56,
        "recover": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recuperar cuenta"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Recuperar cuenta"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("Recuperación iniciada"),
        "recoveryInitiatedDesc": m57,
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Clave de recuperación"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Clave de recuperación copiada al portapapeles"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Si olvidas tu contraseña, la única forma de recuperar tus datos es con esta clave."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Nosotros no almacenamos esta clave. Por favor, guarda esta clave de 24 palabras en un lugar seguro."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "¡Genial! Tu clave de recuperación es válida. Gracias por verificar.\n\nPor favor, recuerda mantener tu clave de recuperación segura."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Clave de recuperación verificada"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Tu clave de recuperación es la única forma de recuperar tus fotos si olvidas tu contraseña. Puedes encontrar tu clave de recuperación en Ajustes > Cuenta.\n\nPor favor, introduce tu clave de recuperación aquí para verificar que la has guardado correctamente."),
        "recoveryReady": m58,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("¡Recuperación exitosa!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "Un contacto de confianza está intentando acceder a tu cuenta"),
        "recoveryWarningBody": m59,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "El dispositivo actual no es lo suficientemente potente para verificar su contraseña, pero podemos regenerarla de una manera que funcione con todos los dispositivos.\n\nPor favor inicie sesión usando su clave de recuperación y regenere su contraseña (puede volver a utilizar la misma si lo desea)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Recrear contraseña"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Rescribe tu contraseña"),
        "reenterPin": MessageLookupByLibrary.simpleMessage("Rescribe tu PIN"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Refiere a amigos y 2x su plan"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Dale este código a tus amigos"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Se suscriben a un plan de pago"),
        "referralStep3": m60,
        "referrals": MessageLookupByLibrary.simpleMessage("Referidos"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Las referencias están actualmente en pausa"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Rechazar la recuperación"),
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
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Revisar y eliminar archivos que son duplicados exactos."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Eliminar del álbum"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("¿Eliminar del álbum?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Remover desde favoritos"),
        "removeInvite":
            MessageLookupByLibrary.simpleMessage("Eliminar invitación"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Eliminar enlace"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Quitar participante"),
        "removeParticipantBody": m61,
        "removePersonLabel": MessageLookupByLibrary.simpleMessage(
            "Eliminar etiqueta de persona"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Quitar enlace público"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Eliminar enlaces públicos"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Algunos de los elementos que estás eliminando fueron añadidos por otras personas, y perderás el acceso a ellos"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Quitar?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Quitarse como contacto de confianza"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Quitando de favoritos..."),
        "rename": MessageLookupByLibrary.simpleMessage("Renombrar"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Renombrar álbum"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Renombrar archivo"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Renovar suscripción"),
        "renewsOn": m62,
        "reportABug": MessageLookupByLibrary.simpleMessage("Reportar un error"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Reportar error"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Reenviar correo electrónico"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Restablecer archivos ignorados"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Restablecer contraseña"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Eliminar"),
        "resetToDefault": MessageLookupByLibrary.simpleMessage(
            "Restablecer valores predeterminados"),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurar"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Restaurar al álbum"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Restaurando los archivos..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("Subidas reanudables"),
        "retry": MessageLookupByLibrary.simpleMessage("Reintentar"),
        "review": MessageLookupByLibrary.simpleMessage("Revisar"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Por favor, revisa y elimina los elementos que crees que están duplicados."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Revisar sugerencias"),
        "right": MessageLookupByLibrary.simpleMessage("Derecha"),
        "rotate": MessageLookupByLibrary.simpleMessage("Girar"),
        "rotateLeft":
            MessageLookupByLibrary.simpleMessage("Girar a la izquierda"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Girar a la derecha"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Almacenado con seguridad"),
        "save": MessageLookupByLibrary.simpleMessage("Guardar"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Guardar collage"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Guardar copia"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Guardar Clave"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Guardar persona"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Guarda tu clave de recuperación si aún no lo has hecho"),
        "saving": MessageLookupByLibrary.simpleMessage("Saving..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Guardando las ediciones..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Escanear código"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Escanea este código QR con tu aplicación de autenticación"),
        "search": MessageLookupByLibrary.simpleMessage("Buscar"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Álbumes"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Nombre del álbum"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Nombres de álbumes (por ejemplo, \"Cámara\")\n• Tipos de archivos (por ejemplo, \"Videos\", \".gif\")\n• Años y meses (por ejemplo, \"2022\", \"Enero\")\n• Vacaciones (por ejemplo, \"Navidad\")\n• Descripciones fotográficas (por ejemplo, \"#diversión\")"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Agrega descripciones como \"#viaje\" en la información de la foto para encontrarlas aquí rápidamente"),
        "searchDatesEmptySection":
            MessageLookupByLibrary.simpleMessage("Buscar por fecha, mes o año"),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "Las imágenes se mostrarán aquí cuando se complete el procesado y la sincronización"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Las personas se mostrarán aquí una vez que se haya hecho la indexación"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Tipos y nombres de archivo"),
        "searchHint1": MessageLookupByLibrary.simpleMessage(
            "Búsqueda rápida en el dispositivo"),
        "searchHint2": MessageLookupByLibrary.simpleMessage(
            "Fechas de fotos, descripciones"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Álbumes, nombres de archivos y tipos"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Ubicación"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Próximamente: Caras y búsqueda mágica ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Agrupar las fotos que se tomaron cerca de la localización de una foto"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Invita a gente y verás todas las fotos compartidas aquí"),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "Las personas se mostrarán aquí cuando se complete el procesado y la sincronización"),
        "searchResultCount": m63,
        "searchSectionsLengthMismatch": m64,
        "security": MessageLookupByLibrary.simpleMessage("Seguridad"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "Ver enlaces del álbum público en la aplicación"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Seleccionar una ubicación"),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
            "Primero, selecciona una ubicación"),
        "selectAlbum":
            MessageLookupByLibrary.simpleMessage("Seleccionar álbum"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Seleccionar todos"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Todas"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Seleccionar foto de portada"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Seleccionar carpetas para la copia de seguridad"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Selecciona elementos para agregar"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Seleccionar idioma"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Seleccionar app de correo"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Seleccionar más fotos"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Seleccionar motivo"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Elegir tu suscripción"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Los archivos seleccionados no están en Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Las carpetas seleccionadas se cifrarán y se realizará una copia de seguridad"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Los archivos seleccionados serán eliminados de todos los álbumes y movidos a la papelera."),
        "selectedPhotos": m6,
        "selectedPhotosWithYours": m65,
        "send": MessageLookupByLibrary.simpleMessage("Enviar"),
        "sendEmail":
            MessageLookupByLibrary.simpleMessage("Enviar correo electrónico"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Enviar invitación"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Enviar enlace"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Punto final del servidor"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("La sesión ha expirado"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("El ID de sesión no coincide"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Establecer una contraseña"),
        "setAs": MessageLookupByLibrary.simpleMessage("Establecer como"),
        "setCover": MessageLookupByLibrary.simpleMessage("Definir portada"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Establecer"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Ingresa tu nueva contraseña"),
        "setNewPin":
            MessageLookupByLibrary.simpleMessage("Ingresa tu nuevo PIN"),
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
        "shareMyVerificationID": m66,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Comparte sólo con la gente que quieres"),
        "shareTextConfirmOthersVerificationID": m7,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Descarga Ente para que podamos compartir fácilmente fotos y videos en calidad original.\n\nhttps://ente.io"),
        "shareTextReferralCode": m67,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Compartir con usuarios fuera de Ente"),
        "shareWithPeopleSectionTitle": m68,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Comparte tu primer álbum"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Crea álbumes compartidos y colaborativos con otros usuarios de Ente, incluyendo usuarios de planes gratuitos."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Compartido por mí"),
        "sharedByYou":
            MessageLookupByLibrary.simpleMessage("Compartido por ti"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Nuevas fotos compartidas"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Recibir notificaciones cuando alguien agrega una foto a un álbum compartido contigo"),
        "sharedWith": m69,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Compartido conmigo"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Compartido contigo"),
        "sharing": MessageLookupByLibrary.simpleMessage("Compartiendo..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Mostrar recuerdos"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Mostrar persona"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Cerrar sesión de otros dispositivos"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Si crees que alguien puede conocer tu contraseña, puedes forzar a todos los demás dispositivos que usan tu cuenta a cerrar la sesión."),
        "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Cerrar la sesión de otros dispositivos"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Estoy de acuerdo con los <u-terms>términos del servicio</u-terms> y <u-policy> la política de privacidad</u-policy>"),
        "singleFileDeleteFromDevice": m70,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Se borrará de todos los álbumes."),
        "singleFileInBothLocalAndRemote": m71,
        "singleFileInRemoteOnly": m72,
        "skip": MessageLookupByLibrary.simpleMessage("Omitir"),
        "social": MessageLookupByLibrary.simpleMessage("Social"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Algunos elementos están tanto en Ente como en tu dispositivo."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Algunos de los archivos que estás intentando eliminar sólo están disponibles en tu dispositivo y no pueden ser recuperados si se eliminan"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Alguien que comparta álbumes contigo debería ver el mismo ID en su dispositivo."),
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
                "Lo sentimos, el código que has introducido es incorrecto"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Lo sentimos, no hemos podido generar claves seguras en este dispositivo.\n\nPor favor, regístrate desde un dispositivo diferente."),
        "sort": MessageLookupByLibrary.simpleMessage("Ordenar"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Ordenar por"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Más recientes primero"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Más antiguos primero"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Éxito"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Iniciar la recuperación"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Iniciar copia de seguridad"),
        "status": MessageLookupByLibrary.simpleMessage("Estado"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "¿Quieres dejar de transmitir?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Detener la transmisión"),
        "storage": MessageLookupByLibrary.simpleMessage("Almacenamiento"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Familia"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Usted"),
        "storageInGB": m1,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Límite de datos excedido"),
        "storageUsageInfo": m73,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Segura"),
        "subAlreadyLinkedErrMessage": m74,
        "subWillBeCancelledOn": m75,
        "subscribe": MessageLookupByLibrary.simpleMessage("Suscribirse"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Necesitas una suscripción activa de pago para habilitar el compartir."),
        "subscription": MessageLookupByLibrary.simpleMessage("Suscripción"),
        "success": MessageLookupByLibrary.simpleMessage("Éxito"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Archivado correctamente"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Ocultado con éxito"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Desarchivado correctamente"),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("Desocultado con éxito"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Sugerir una característica"),
        "support": MessageLookupByLibrary.simpleMessage("Soporte"),
        "syncProgress": m76,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Sincronización detenida"),
        "syncing": MessageLookupByLibrary.simpleMessage("Sincronizando..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistema"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("toca para copiar"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Toca para introducir el código"),
        "tapToUnlock":
            MessageLookupByLibrary.simpleMessage("Toca para desbloquear"),
        "tapToUpload": MessageLookupByLibrary.simpleMessage("Toca para subir"),
        "tapToUploadIsIgnoredDue": m77,
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
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "El enlace al que intenta acceder ha caducado."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "La clave de recuperación introducida es incorrecta"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Estos elementos se eliminarán de tu dispositivo."),
        "theyAlsoGetXGb": m8,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Se borrarán de todos los álbumes."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Esta acción no se puede deshacer"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Este álbum ya tiene un enlace de colaboración"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Esto puede utilizarse para recuperar tu cuenta si pierdes tu segundo factor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Este dispositivo"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Este correo electrónico ya está en uso"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Esta imagen no tiene datos exif"),
        "thisIsPersonVerificationId": m78,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Esta es tu ID de verificación"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Esto cerrará la sesión del siguiente dispositivo:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "¡Esto cerrará la sesión de este dispositivo!"),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Esto eliminará los enlaces públicos de todos los enlaces rápidos seleccionados."),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Para habilitar el bloqueo de la aplicación, por favor configura el código de acceso del dispositivo o el bloqueo de pantalla en los ajustes del sistema."),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Para ocultar una foto o video"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Para restablecer tu contraseña, por favor verifica tu correo electrónico primero."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Registros de hoy"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
            "Demasiados intentos incorrectos"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Tamaño total"),
        "trash": MessageLookupByLibrary.simpleMessage("Papelera"),
        "trashDaysLeft": m79,
        "trim": MessageLookupByLibrary.simpleMessage("Ajustar duración"),
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Contactos de confianza"),
        "trustedInviteBody": m80,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Inténtalo de nuevo"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Activar la copia de seguridad para subir automáticamente archivos añadidos a la carpeta de este dispositivo a Ente."),
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
        "typeOfGallerGallerytypeIsNotSupportedForRename": m81,
        "unarchive": MessageLookupByLibrary.simpleMessage("Desarchivar"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Desarchivar álbum"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("Desarchivando..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Lo sentimos, este código no está disponible."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Sin categorizar"),
        "unhide": MessageLookupByLibrary.simpleMessage("Dejar de ocultar"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Hacer visible al álbum"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Desocultando..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Desocultando archivos del álbum"),
        "unlock": MessageLookupByLibrary.simpleMessage("Desbloquear"),
        "unpinAlbum":
            MessageLookupByLibrary.simpleMessage("Dejar de fijar álbum"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar todos"),
        "update": MessageLookupByLibrary.simpleMessage("Actualizar"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Actualizacion disponible"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Actualizando la selección de carpeta..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Mejorar"),
        "uploadIsIgnoredDueToIgnorereason": m82,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Subiendo archivos al álbum..."),
        "uploadingMultipleMemories": m83,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Preservando 1 memoria..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Hasta el 50% de descuento, hasta el 4 de diciembre."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "El almacenamiento utilizable está limitado por tu plan actual. El exceso de almacenamiento que obtengas se volverá automáticamente utilizable cuando actualices tu plan."),
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Usar como cubierta"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "¿Tienes problemas para reproducir este video? Mantén pulsado aquí para probar un reproductor diferente."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Usar enlaces públicos para personas que no están en Ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Usar clave de recuperación"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Usar foto seleccionada"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Espacio usado"),
        "validTill": m84,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verificación fallida, por favor inténtalo de nuevo"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de verificación"),
        "verify": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage(
            "Verificar correo electrónico"),
        "verifyEmailID": m85,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Verificar clave de acceso"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verificar contraseña"),
        "verifying": MessageLookupByLibrary.simpleMessage("Verificando..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verificando clave de recuperación..."),
        "videoInfo":
            MessageLookupByLibrary.simpleMessage("Información de video"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vídeo"),
        "videos": MessageLookupByLibrary.simpleMessage("Vídeos"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Ver sesiones activas"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Ver complementos"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Ver todo"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Ver todos los datos EXIF"),
        "viewLargeFiles":
            MessageLookupByLibrary.simpleMessage("Archivos grandes"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Ver los archivos que consumen la mayor cantidad de almacenamiento."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Ver Registros"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ver código de recuperación"),
        "viewer": MessageLookupByLibrary.simpleMessage("Espectador"),
        "viewersSuccessfullyAdded": m86,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Por favor, visita web.ente.io para administrar tu suscripción"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Esperando verificación..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Esperando WiFi..."),
        "warning": MessageLookupByLibrary.simpleMessage("Advertencia"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("¡Somos de código abierto!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "No admitimos la edición de fotos y álbumes que aún no son tuyos"),
        "weHaveSendEmailTo": m2,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Poco segura"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("¡Bienvenido de nuevo!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Qué hay de nuevo"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Un contacto de confianza puede ayudar a recuperar sus datos."),
        "yearShort": MessageLookupByLibrary.simpleMessage("año"),
        "yearly": MessageLookupByLibrary.simpleMessage("Anualmente"),
        "yearsAgo": m87,
        "yes": MessageLookupByLibrary.simpleMessage("Sí"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Sí, cancelar"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Sí, convertir a espectador"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Sí, eliminar"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Sí, descartar cambios"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Sí, cerrar sesión"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Sí, quitar"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Sí, renovar"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Si, eliminar persona"),
        "you": MessageLookupByLibrary.simpleMessage("Tu"),
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("¡Estás en un plan familiar!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Estás usando la última versión"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Como máximo puedes duplicar tu almacenamiento"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Puedes administrar tus enlaces en la pestaña compartir."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Puedes intentar buscar una consulta diferente."),
        "youCannotDowngradeToThisPlan":
            MessageLookupByLibrary.simpleMessage("No puedes bajar a este plan"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "No puedes compartir contigo mismo"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "No tienes ningún elemento archivado."),
        "youHaveSuccessfullyFreedUp": m88,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Tu cuenta ha sido eliminada"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Tu mapa"),
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
                "No tienes archivos en este álbum que puedan ser borrados"),
        "zoomOutToSeePhotos":
            MessageLookupByLibrary.simpleMessage("Alejar para ver las fotos")
      };
}
