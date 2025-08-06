// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class StringsLocalizationsEs extends StringsLocalizations {
  StringsLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'No se puede conectar a Ente. Por favor, comprueba tu configuración de red y ponte en contacto con el soporte técnico si el error persiste.';

  @override
  String get networkConnectionRefusedErr =>
      'No se puede conectar a Ente. Por favor, vuelve a intentarlo pasado un tiempo. Si el error persiste, ponte en contacto con el soporte técnico.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Parece que algo salió mal. Por favor, vuelve a intentarlo pasado un tiempo. Si el error persiste, ponte en contacto con nuestro equipo de soporte.';

  @override
  String get error => 'Error';

  @override
  String get ok => 'Ok';

  @override
  String get faq => 'Preguntas Frecuentes';

  @override
  String get contactSupport => 'Ponerse en contacto con el equipo de soporte';

  @override
  String get emailYourLogs => 'Envíe sus registros por correo electrónico';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Por favor, envíe los registros a $toEmail';
  }

  @override
  String get copyEmailAddress => 'Copiar dirección de correo electrónico';

  @override
  String get exportLogs => 'Exportar registros';

  @override
  String get cancel => 'Cancelar';

  @override
  String pleaseEmailUsAt(String toEmail) {
    return 'Email us at $toEmail';
  }

  @override
  String get emailAddressCopied => 'Email address copied';

  @override
  String get supportEmailSubject => '[Support]';

  @override
  String get clientDebugInfoLabel =>
      'Following information can help us in debugging if you are facing any issue';

  @override
  String get registeredEmailLabel => 'Registered email:';

  @override
  String get clientLabel => 'Client:';

  @override
  String get versionLabel => 'Version :';

  @override
  String get notAvailable => 'N/A';

  @override
  String get reportABug => 'Reportar un error';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Conectado a $endpoint';
  }

  @override
  String get save => 'Guardar';

  @override
  String get send => 'Enviar';

  @override
  String get saveOrSendDescription =>
      '¿Desea guardar el archivo en el almacenamiento (carpeta Descargas por defecto) o enviarlo a otras aplicaciones?';

  @override
  String get saveOnlyDescription =>
      '¿Desea guardar el archivo en el almacenamiento (carpeta Descargas por defecto)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'Correo electrónico';

  @override
  String get verify => 'Verificar';

  @override
  String get invalidEmailTitle => 'Dirección de correo electrónico no válida';

  @override
  String get invalidEmailMessage =>
      'Por favor, introduce una dirección de correo electrónico válida.';

  @override
  String get pleaseWait => 'Por favor, espere...';

  @override
  String get verifyPassword => 'Verificar contraseña';

  @override
  String get incorrectPasswordTitle => 'Contraseña incorrecta';

  @override
  String get pleaseTryAgain => 'Por favor, inténtalo de nuevo';

  @override
  String get enterPassword => 'Introduzca la contraseña';

  @override
  String get enterYourPasswordHint => 'Introduce tu contraseña';

  @override
  String get activeSessions => 'Sesiones activas';

  @override
  String get oops => 'Ups';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Algo ha ido mal, por favor, inténtelo de nuevo';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      '¡Esto cerrará la sesión de este dispositivo!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Esto cerrará la sesión del siguiente dispositivo:';

  @override
  String get terminateSession => '¿Terminar sesión?';

  @override
  String get terminate => 'Terminar';

  @override
  String get thisDevice => 'Este dispositivo';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get weakStrength => 'Poco segura';

  @override
  String get moderateStrength => 'Moderada';

  @override
  String get strongStrength => 'Segura';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountQuery =>
      'Lamentamos que te vayas. ¿Estás teniendo algún problema?';

  @override
  String get yesSendFeedbackAction => 'Sí, enviar comentarios';

  @override
  String get noDeleteAccountAction => 'No, eliminar cuenta';

  @override
  String get initiateAccountDeleteTitle =>
      'Por favor, autentícate para iniciar la eliminación de la cuenta';

  @override
  String get confirmAccountDeleteTitle => 'Confirmar eliminación de la cuenta';

  @override
  String get confirmAccountDeleteMessage =>
      'Esta cuenta está vinculada a otras aplicaciones de Ente, si utilizas alguna. \n\nSe programará la eliminación de los datos cargados en todas las aplicaciones de Ente, y tu cuenta se eliminará permanentemente.';

  @override
  String get delete => 'Borrar';

  @override
  String get createNewAccount => 'Crear cuenta nueva';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Fortaleza de la contraseña: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => '¿Cómo conoció Ente? (opcional)';

  @override
  String get hearUsExplanation =>
      'No rastreamos la instalación de las aplicaciones. ¡Nos ayudaría si nos dijera dónde nos encontró!';

  @override
  String get signUpTerms =>
      'Estoy de acuerdo con los <u-terms>términos del servicio</u-terms> y <u-policy> la política de privacidad</u-policy>';

  @override
  String get termsOfServicesTitle => 'Términos';

  @override
  String get privacyPolicyTitle => 'Política de Privacidad';

  @override
  String get ackPasswordLostWarning =>
      'Entiendo que si pierdo mi contraseña podría perder mis datos, ya que mis datos están <underline>cifrados de extremo a extremo</underline>.';

  @override
  String get encryption => 'Cifrado';

  @override
  String get logInLabel => 'Iniciar sesión';

  @override
  String get welcomeBack => '¡Te damos la bienvenida otra vez!';

  @override
  String get loginTerms =>
      'Al hacer clic en iniciar sesión, acepto los <u-terms>términos de servicio</u-terms> y <u-policy>la política de privacidad</u-policy>';

  @override
  String get noInternetConnection => 'No hay conexión a Internet';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Compruebe su conexión a Internet e inténtelo de nuevo.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Verificación fallida, por favor inténtalo de nuevo';

  @override
  String get recreatePasswordTitle => 'Recrear contraseña';

  @override
  String get recreatePasswordBody =>
      'El dispositivo actual no es lo suficientemente potente para verificar su contraseña, pero podemos regenerarla de manera que funcione con todos los dispositivos.\n\nPor favor inicie sesión usando su clave de recuperación y regenere su contraseña (puede volver a utilizar la misma si lo desea).';

  @override
  String get useRecoveryKey => 'Usar clave de recuperación';

  @override
  String get forgotPassword => 'Olvidé mi contraseña';

  @override
  String get changeEmail => 'Cambiar correo electrónico';

  @override
  String get verifyEmail => 'Verificar correo electrónico';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Hemos enviado un correo electrónico a <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Para restablecer tu contraseña, por favor verifica tu correo electrónico primero.';

  @override
  String get checkInboxAndSpamFolder =>
      'Por favor revisa tu bandeja de entrada (y spam) para completar la verificación';

  @override
  String get tapToEnterCode => 'Toca para introducir el código';

  @override
  String get sendEmail => 'Enviar correo electrónico';

  @override
  String get resendEmail => 'Reenviar correo electrónico';

  @override
  String get passKeyPendingVerification =>
      'La verificación todavía está pendiente';

  @override
  String get loginSessionExpired => 'La sesión ha expirado';

  @override
  String get loginSessionExpiredDetails =>
      'Tu sesión ha expirado. Por favor, vuelve a iniciar sesión.';

  @override
  String get passkeyAuthTitle => 'Verificación de clave de acceso';

  @override
  String get waitingForVerification => 'Esperando verificación...';

  @override
  String get tryAgain => 'Inténtelo de nuevo';

  @override
  String get checkStatus => 'Comprobar estado';

  @override
  String get loginWithTOTP => 'Inicio de sesión con TOTP';

  @override
  String get recoverAccount => 'Recuperar cuenta';

  @override
  String get setPasswordTitle => 'Establecer contraseña';

  @override
  String get changePasswordTitle => 'Cambiar contraseña';

  @override
  String get resetPasswordTitle => 'Restablecer contraseña';

  @override
  String get encryptionKeys => 'Claves de cifrado';

  @override
  String get enterPasswordToEncrypt =>
      'Introduzca una contraseña que podamos usar para cifrar sus datos';

  @override
  String get enterNewPasswordToEncrypt =>
      'Introduzca una contraseña nueva que podamos usar para cifrar sus datos';

  @override
  String get passwordWarning =>
      'No almacenamos esta contraseña, así que si la olvidas, <underline>no podremos descifrar tus datos</underline>';

  @override
  String get howItWorks => 'Cómo funciona';

  @override
  String get generatingEncryptionKeys => 'Generando claves de cifrado...';

  @override
  String get passwordChangedSuccessfully => 'Contraseña cambiada correctamente';

  @override
  String get signOutFromOtherDevices => 'Cerrar sesión en otros dispositivos';

  @override
  String get signOutOtherBody =>
      'Si crees que alguien puede conocer tu contraseña, puedes forzar a todos los demás dispositivos que usen tu cuenta a cerrar la sesión.';

  @override
  String get signOutOtherDevices => 'Cerrar la sesión en otros dispositivos';

  @override
  String get doNotSignOut => 'No cerrar la sesión';

  @override
  String get generatingEncryptionKeysTitle => 'Generando claves de cifrado...';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get insecureDevice => 'Dispositivo inseguro';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Lo sentimos, no hemos podido generar claves seguras en este dispositivo.\n\nRegístrate desde un dispositivo diferente.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Clave de recuperación copiada al portapapeles';

  @override
  String get recoveryKey => 'Clave de recuperación';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Si olvidas tu contraseña, la única forma de recuperar tus datos es con esta clave.';

  @override
  String get recoveryKeySaveDescription =>
      'Nosotros no almacenamos esta clave, por favor guarda esta clave de 24 palabras en un lugar seguro.';

  @override
  String get doThisLater => 'Hacer esto más tarde';

  @override
  String get saveKey => 'Guardar clave';

  @override
  String get recoveryKeySaved =>
      '¡Clave de recuperación guardada en la carpeta Descargas!';

  @override
  String get noRecoveryKeyTitle => '¿No tienes la clave de recuperación?';

  @override
  String get twoFactorAuthTitle => 'Autenticación de dos factores';

  @override
  String get enterCodeHint =>
      'Ingrese el código de seis dígitos de su aplicación de autenticación';

  @override
  String get lostDeviceTitle => '¿Dispositivo perdido?';

  @override
  String get enterRecoveryKeyHint => 'Introduce tu clave de recuperación';

  @override
  String get recover => 'Recuperar';

  @override
  String get loggingOut => 'Cerrando sesión...';

  @override
  String get immediately => 'Inmediatamente';

  @override
  String get appLock => 'Bloqueo de aplicación';

  @override
  String get autoLock => 'Bloqueo automático';

  @override
  String get noSystemLockFound => 'Bloqueo del sistema no encontrado';

  @override
  String get deviceLockEnablePreSteps =>
      'Para activar el bloqueo de la aplicación, por favor configura el código de acceso del dispositivo o el bloqueo de pantalla en los ajustes de tu sistema.';

  @override
  String get appLockDescription =>
      'Elija entre la pantalla de bloqueo por defecto de su dispositivo y una pantalla de bloqueo personalizada con un PIN o contraseña.';

  @override
  String get deviceLock => 'Bloqueo del dispositivo';

  @override
  String get pinLock => 'Bloqueo con PIN';

  @override
  String get autoLockFeatureDescription =>
      'Tiempo tras el cual la aplicación se bloquea después de ser colocada en segundo plano';

  @override
  String get hideContent => 'Ocultar contenido';

  @override
  String get hideContentDescriptionAndroid =>
      'Oculta el contenido de la aplicación en el selector de aplicaciones y desactiva las capturas de pantalla';

  @override
  String get hideContentDescriptioniOS =>
      'Ocultar el contenido de la aplicación en el selector de aplicaciones';

  @override
  String get tooManyIncorrectAttempts => 'Demasiados intentos incorrectos';

  @override
  String get tapToUnlock => 'Toca para desbloquear';

  @override
  String get areYouSureYouWantToLogout =>
      '¿Seguro que quieres cerrar la sesión?';

  @override
  String get yesLogout => 'Sí, cerrar la sesión';

  @override
  String get authToViewSecrets =>
      'Por favor, autentícate para ver tus secretos';

  @override
  String get next => 'Siguiente';

  @override
  String get setNewPassword => 'Establece una nueva contraseña';

  @override
  String get enterPin => 'Ingresa el PIN';

  @override
  String get setNewPin => 'Establecer nuevo PIN';

  @override
  String get confirm => 'Confirmar';

  @override
  String get reEnterPassword => 'Reescribe tu contraseña';

  @override
  String get reEnterPin => 'Reescribe tu PIN';

  @override
  String get androidBiometricHint => 'Verificar identidad';

  @override
  String get androidBiometricNotRecognized =>
      'No reconocido. Inténtalo de nuevo.';

  @override
  String get androidBiometricSuccess => 'Autenticación exitosa';

  @override
  String get androidCancelButton => 'Cancelar';

  @override
  String get androidSignInTitle => 'Se necesita autenticación biométrica';

  @override
  String get androidBiometricRequiredTitle =>
      'Se necesita autenticación biométrica';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Se necesitan credenciales de dispositivo';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Se necesitan credenciales de dispositivo';

  @override
  String get goToSettings => 'Ir a Ajustes';

  @override
  String get androidGoToSettingsDescription =>
      'La autenticación biométrica no está configurada en tu dispositivo. Ve a \'Ajustes > Seguridad\' para configurar la autenticación biométrica.';

  @override
  String get iOSLockOut =>
      'La autenticación biométrica está deshabilitada. Por favor bloquea y desbloquea la pantalla para habilitarla.';

  @override
  String get iOSOkButton => 'Aceptar';

  @override
  String get emailAlreadyRegistered => 'Correo electrónico ya registrado.';

  @override
  String get emailNotRegistered => 'Correo electrónico no registrado.';

  @override
  String get thisEmailIsAlreadyInUse =>
      'Este correo electrónico ya está en uso';

  @override
  String emailChangedTo(String newEmail) {
    return 'Correo electrónico cambiado a $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Error de autenticación, por favor inténtalo de nuevo';

  @override
  String get authenticationSuccessful => '¡Autenticación exitosa!';

  @override
  String get sessionExpired => 'La sesión ha expirado';

  @override
  String get incorrectRecoveryKey => 'Clave de recuperación incorrecta';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'La clave de recuperación introducida es incorrecta';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Autenticación de doble factor restablecida con éxito';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Tu código de verificación ha expirado';

  @override
  String get incorrectCode => 'Código incorrecto';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Lo sentimos, el código que has introducido es incorrecto';

  @override
  String get developerSettings => 'Ajustes de desarrollador';

  @override
  String get serverEndpoint => 'Endpoint del servidor';

  @override
  String get invalidEndpoint => 'Endpoint no válido';

  @override
  String get invalidEndpointMessage =>
      'Lo sentimos, el endpoint introducido no es válido. Por favor, introduce un endpoint válido y vuelve a intentarlo.';

  @override
  String get endpointUpdatedMessage => 'Endpoint actualizado con éxito';
}
