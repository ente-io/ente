// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class StringsLocalizationsPt extends StringsLocalizations {
  StringsLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Não foi possível conectar-se ao Ente, verifique suas configurações de rede e entre em contato com o suporte se o erro persistir.';

  @override
  String get networkConnectionRefusedErr =>
      'Não foi possível conectar ao Ente, tente novamente após algum tempo. Se o erro persistir, entre em contato com o suporte.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Parece que algo deu errado. Tente novamente mais tarde. Se o erro persistir, entre em contato com nossa equipe de ajuda.';

  @override
  String get error => 'Erro';

  @override
  String get ok => 'Ok';

  @override
  String get faq => 'Perguntas frequentes';

  @override
  String get contactSupport => 'Contatar suporte';

  @override
  String get emailYourLogs => 'Enviar registros por e-mail';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Envie os logs para \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Copiar endereço de e-mail';

  @override
  String get exportLogs => 'Exportar logs';

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
  String get reportABug => 'Informar erro';

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
  String get save => 'Salvar';

  @override
  String get send => 'Enviar';

  @override
  String get saveOrSendDescription =>
      'Deseja mesmo salvar isso no armazenamento (pasta de Downloads por padrão) ou enviar a outros aplicativos?';

  @override
  String get saveOnlyDescription =>
      'Deseja mesmo salvar em seu armazenamento (pasta de Downloads por padrão)?';

  @override
  String get enterNewEmailHint => 'Insira seu novo e-mail';

  @override
  String get email => 'E-mail';

  @override
  String get verify => 'Verificar';

  @override
  String get invalidEmailTitle => 'Endereço de e-mail inválido';

  @override
  String get invalidEmailMessage => 'Insira um endereço de e-mail válido.';

  @override
  String get pleaseWait => 'Aguarde...';

  @override
  String get verifyPassword => 'Verificar senha';

  @override
  String get incorrectPasswordTitle => 'Senha incorreta';

  @override
  String get pleaseTryAgain => 'Tente novamente';

  @override
  String get enterPassword => 'Inserir senha';

  @override
  String get enterYourPasswordHint => 'Insira sua senha';

  @override
  String get activeSessions => 'Sessões ativas';

  @override
  String get oops => 'Opa';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Algo deu errado. Tente outra vez';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Isso fará com que você saia deste dispositivo!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Isso fará você sair do dispositivo a seguir:';

  @override
  String get terminateSession => 'Sair?';

  @override
  String get terminate => 'Encerrar';

  @override
  String get thisDevice => 'Esse dispositivo';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get weakStrength => 'Fraca';

  @override
  String get moderateStrength => 'Moderada';

  @override
  String get strongStrength => 'Forte';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get deleteAccountQuery =>
      'Estamos tristes por vê-lo sair. Você enfrentou algum problema?';

  @override
  String get yesSendFeedbackAction => 'Sim, enviar feedback';

  @override
  String get noDeleteAccountAction => 'Não, excluir conta';

  @override
  String get deleteAccountWarning =>
      'This will delete your Ente Auth, Ente Photos and Ente Locker account.';

  @override
  String get initiateAccountDeleteTitle =>
      'Autentique-se para iniciar a exclusão de conta';

  @override
  String get confirmAccountDeleteTitle => 'Confirmar exclusão de conta';

  @override
  String get confirmAccountDeleteMessage =>
      'Esta conta está vinculada a outros apps Ente, se você usa algum.\n\nSeus dados enviados, entre todos os apps Ente, serão marcados para exclusão, e sua conta será apagada permanentemente.';

  @override
  String get delete => 'Excluir';

  @override
  String get createNewAccount => 'Criar nova conta';

  @override
  String get password => 'Senha';

  @override
  String get confirmPassword => 'Confirmar senha';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Força da senha: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Como você descobriu o Ente? (opcional)';

  @override
  String get hearUsExplanation =>
      'Não rastreamos instalações. Ajudaria bastante se você contasse onde nos achou!';

  @override
  String get signUpTerms =>
      'Eu concordo com os <u-terms>termos de serviço</u-terms> e a <u-policy>política de privacidade</u-policy>';

  @override
  String get termsOfServicesTitle => 'Termos';

  @override
  String get privacyPolicyTitle => 'Política de Privacidade';

  @override
  String get ackPasswordLostWarning =>
      'Eu entendo que se eu perder minha senha, posso perder meus dados, já que meus dados são <underline>criptografados de ponta a ponta</underline>.';

  @override
  String get encryption => 'Criptografia';

  @override
  String get logInLabel => 'Entrar';

  @override
  String get welcomeBack => 'Bem-vindo(a) de volta!';

  @override
  String get loginTerms =>
      'Ao clicar em iniciar sessão, eu concordo com os <u-terms>termos de serviço</u-terms> e a <u-policy>política de privacidade</u-policy>';

  @override
  String get noInternetConnection => 'Não conectado à internet';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Verifique sua conexão com a internet e tente novamente.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Falhou na verificação. Tente novamente';

  @override
  String get recreatePasswordTitle => 'Redefinir senha';

  @override
  String get recreatePasswordBody =>
      'Não é possível verificar a sua senha no dispositivo atual, mas podemos regenerá-la para que funcione em todos os dispositivos. \n\nEntre com a sua chave de recuperação e regenere sua senha (você pode usar a mesma se quiser).';

  @override
  String get useRecoveryKey => 'Usar chave de recuperação';

  @override
  String get forgotPassword => 'Esqueci a senha';

  @override
  String get changeEmail => 'Alterar e-mail';

  @override
  String get verifyEmail => 'Verificar e-mail';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Enviamos um e-mail à <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Para redefinir sua senha, verifique seu e-mail primeiramente.';

  @override
  String get checkInboxAndSpamFolder =>
      'Verifique sua caixa de entrada (e spam) para concluir a verificação';

  @override
  String get tapToEnterCode => 'Toque para inserir código';

  @override
  String get sendEmail => 'Enviar e-mail';

  @override
  String get resendEmail => 'Reenviar e-mail';

  @override
  String get passKeyPendingVerification => 'A verificação ainda está pendente';

  @override
  String get loginSessionExpired => 'Sessão expirada';

  @override
  String get loginSessionExpiredDetails =>
      'Sua sessão expirou. Registre-se novamente.';

  @override
  String get passkeyAuthTitle => 'Verificação de chave de acesso';

  @override
  String get waitingForVerification => 'Aguardando verificação...';

  @override
  String get tryAgain => 'Tente novamente';

  @override
  String get checkStatus => 'Verificar status';

  @override
  String get loginWithTOTP => 'Registrar com TOTP';

  @override
  String get recoverAccount => 'Recuperar conta';

  @override
  String get setPasswordTitle => 'Definir senha';

  @override
  String get changePasswordTitle => 'Alterar senha';

  @override
  String get resetPasswordTitle => 'Redefinir senha';

  @override
  String get encryptionKeys => 'Chaves de criptografia';

  @override
  String get enterPasswordToEncrypt =>
      'Insira uma senha que podemos usar para criptografar seus dados';

  @override
  String get enterNewPasswordToEncrypt =>
      'Insira uma nova senha para criptografar seus dados';

  @override
  String get passwordWarning =>
      'Não salvamos esta senha, então se você esquecê-la, <underline>não podemos descriptografar seus dados</underline>';

  @override
  String get howItWorks => 'Como funciona';

  @override
  String get generatingEncryptionKeys => 'Gerando chaves de criptografia...';

  @override
  String get passwordChangedSuccessfully => 'A senha foi alterada';

  @override
  String get signOutFromOtherDevices => 'Sair da conta em outros dispositivos';

  @override
  String get signOutOtherBody =>
      'Se você acha que alguém possa saber da sua senha, você pode forçar desconectar sua conta de outros dispositivos.';

  @override
  String get signOutOtherDevices => 'Sair em outros dispositivos';

  @override
  String get doNotSignOut => 'Não sair';

  @override
  String get generatingEncryptionKeysTitle =>
      'Gerando chaves de criptografia...';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get insecureDevice => 'Dispositivo inseguro';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Desculpe, não foi possível gerar chaves de segurança nesse dispositivo.\n\ninicie sessão em um dispositivo diferente.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Chave de recuperação copiada para a área de transferência';

  @override
  String get recoveryKey => 'Chave de recuperação';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Caso esqueça sua senha, a única maneira de recuperar seus dados é com esta chave.';

  @override
  String get recoveryKeySaveDescription =>
      'Não armazenamos esta chave de 24 palavras. Salve-a em um lugar seguro.';

  @override
  String get doThisLater => 'Fazer isso depois';

  @override
  String get saveKey => 'Salvar chave';

  @override
  String get recoveryKeySaved =>
      'Chave de recuperação salva na pasta Downloads!';

  @override
  String get noRecoveryKeyTitle => 'Sem chave de recuperação?';

  @override
  String get twoFactorAuthTitle => 'Autenticação de dois fatores';

  @override
  String get enterCodeHint =>
      'Insira o código de 6 dígitos do aplicativo autenticador';

  @override
  String get lostDeviceTitle => 'Perdeu o dispositivo?';

  @override
  String get enterRecoveryKeyHint => 'Digite a chave de recuperação';

  @override
  String get recover => 'Recuperar';

  @override
  String get loggingOut => 'Desconectando...';

  @override
  String get immediately => 'Imediatamente';

  @override
  String get appLock => 'Bloqueio do aplicativo';

  @override
  String get autoLock => 'Bloqueio automático';

  @override
  String get noSystemLockFound => 'Nenhum bloqueio do sistema encontrado';

  @override
  String get deviceLockEnablePreSteps =>
      'Para ativar o bloqueio do dispositivo, configure a senha do dispositivo ou o bloqueio de tela nas configurações do seu sistema.';

  @override
  String get appLockDescription =>
      'Escolha entre a tela de bloqueio padrão do seu dispositivo e uma tela de bloqueio personalizada com PIN ou senha.';

  @override
  String get deviceLock => 'Bloqueio do dispositivo';

  @override
  String get pinLock => 'PIN de bloqueio';

  @override
  String get autoLockFeatureDescription =>
      'Tempo de bloqueio do aplicativo em segundo plano';

  @override
  String get hideContent => 'Ocultar conteúdo';

  @override
  String get hideContentDescriptionAndroid =>
      'Oculta o conteúdo do aplicativo no seletor de aplicativos e desativa as capturas de tela';

  @override
  String get hideContentDescriptioniOS =>
      'Oculta o conteúdo do seletor de aplicativos';

  @override
  String get tooManyIncorrectAttempts => 'Muitas tentativas incorretas';

  @override
  String get tapToUnlock => 'Toque para desbloquear';

  @override
  String get areYouSureYouWantToLogout => 'Deseja mesmo sair?';

  @override
  String get yesLogout => 'Sim, quero sair';

  @override
  String get authToViewSecrets => 'Autentique-se para ver suas chaves secretas';

  @override
  String get next => 'Avançar';

  @override
  String get setNewPassword => 'Defina a nova senha';

  @override
  String get enterPin => 'Inserir PIN';

  @override
  String get setNewPin => 'Definir novo PIN';

  @override
  String get confirm => 'Confirmar';

  @override
  String get reEnterPassword => 'Reinserir senha';

  @override
  String get reEnterPin => 'Reinserir PIN';

  @override
  String get androidBiometricHint => 'Verificar identidade';

  @override
  String get androidBiometricNotRecognized => 'Não reconhecido. Tente de novo.';

  @override
  String get androidBiometricSuccess => 'Sucesso';

  @override
  String get androidCancelButton => 'Cancelar';

  @override
  String get androidSignInTitle => 'Autenticação necessária';

  @override
  String get androidBiometricRequiredTitle => 'Biometria necessária';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Credenciais necessários do dispositivo';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Credenciais necessários do dispositivo';

  @override
  String get goToSettings => 'Ir para Opções';

  @override
  String get androidGoToSettingsDescription =>
      'A autenticação biométrica não está configurada no seu dispositivo. Vá em \'Configurações > Segurança\' para adicionar a autenticação biométrica.';

  @override
  String get iOSLockOut =>
      'A autenticação biométrica está desativada. Bloqueie e desbloqueie sua tela para ativá-la.';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'E-mail já registrado.';

  @override
  String get emailNotRegistered => 'E-mail não registrado.';

  @override
  String get thisEmailIsAlreadyInUse => 'Este e-mail já está em uso';

  @override
  String emailChangedTo(String newEmail) {
    return 'E-mail alterado para $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'A autenticação falhou. Tente novamente';

  @override
  String get authenticationSuccessful => 'Autenticado!';

  @override
  String get sessionExpired => 'Sessão expirada';

  @override
  String get incorrectRecoveryKey => 'Chave de recuperação incorreta';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'A chave de recuperação inserida está incorreta';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Autenticação de dois fatores redefinida com sucesso';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Seu código de verificação expirou';

  @override
  String get incorrectCode => 'Código incorreto';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'O código inserido está incorreto';

  @override
  String get developerSettings => 'Opções de Desenvolvedor';

  @override
  String get serverEndpoint => 'Endpoint do servidor';

  @override
  String get invalidEndpoint => 'Endpoint inválido';

  @override
  String get invalidEndpointMessage =>
      'Desculpe, o ponto de acesso inserido é inválido. Insira um ponto de acesso válido e tente novamente.';

  @override
  String get endpointUpdatedMessage => 'O endpoint foi atualizado';

  @override
  String get yes => 'Yes';

  @override
  String get remove => 'Remove';

  @override
  String get addMore => 'Add more';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get legacy => 'Legacy';

  @override
  String get recoveryWarning =>
      'A trusted contact is trying to access your account';

  @override
  String recoveryWarningBody(Object email) {
    return '$email is trying to recover your account.';
  }

  @override
  String get legacyPageDesc =>
      'Legacy allows trusted contacts to access your account in your absence.';

  @override
  String get legacyPageDesc2 =>
      'Trusted contacts can initiate account recovery, and if not blocked within 30 days, reset your password and access your account.';

  @override
  String get legacyAccounts => 'Legacy accounts';

  @override
  String get trustedContacts => 'Trusted contacts';

  @override
  String legacyInvite(String email) {
    return '$email has invited you to be a trusted contact';
  }

  @override
  String get acceptTrustInvite => 'Accept invite';

  @override
  String get addTrustedContact => 'Add Trusted Contact';

  @override
  String get removeInvite => 'Remove invite';

  @override
  String get rejectRecovery => 'Reject recovery';

  @override
  String get recoveryInitiated => 'Recovery initiated';

  @override
  String recoveryInitiatedDesc(int days, String email) {
    return 'You can access the account after $days days. A notification will be sent to $email.';
  }

  @override
  String get removeYourselfAsTrustedContact =>
      'Remove yourself as trusted contact';

  @override
  String get declineTrustInvite => 'Decline Invite';

  @override
  String get cancelAccountRecovery => 'Cancel recovery';

  @override
  String get recoveryAccount => 'Recover account';

  @override
  String get cancelAccountRecoveryBody =>
      'Are you sure you want to cancel recovery?';

  @override
  String get startAccountRecoveryTitle => 'Start recovery';

  @override
  String get whyAddTrustContact =>
      'Trusted contact can help in recovering your data.';

  @override
  String recoveryReady(String email) {
    return 'You can now recover $email\'s account by setting a new password.';
  }

  @override
  String get warning => 'Warning';

  @override
  String get proceed => 'Proceed';

  @override
  String get done => 'Done';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get verifyIDLabel => 'Verify';

  @override
  String get invalidEmailAddress => 'Invalid email address';

  @override
  String get enterValidEmail => 'Please enter a valid email address.';

  @override
  String get addANewEmail => 'Add a new email';

  @override
  String get orPickAnExistingOne => 'Or pick an existing one';

  @override
  String get shareTextRecommendUsingEnte =>
      'Download Ente so we can easily share original quality files\n\nhttps://ente.io';

  @override
  String get sendInvite => 'Send invite';

  @override
  String trustedInviteBody(Object email) {
    return 'You have been invited to be a legacy contact by $email.';
  }

  @override
  String verifyEmailID(Object email) {
    return 'Verify $email';
  }

  @override
  String get thisIsYourVerificationId => 'This is your Verification ID';

  @override
  String get someoneSharingAlbumsWithYouShouldSeeTheSameId =>
      'Someone sharing albums with you should see the same ID on their device.';

  @override
  String get howToViewShareeVerificationID =>
      'Please ask them to long-press their email address on the settings screen, and verify that the IDs on both devices match.';

  @override
  String thisIsPersonVerificationId(String email) {
    return 'This is $email\'s Verification ID';
  }

  @override
  String confirmAddingTrustedContact(String email, int numOfDays) {
    return 'You are about to add $email as a trusted contact. They will be able to recover your account if you are absent for $numOfDays days.';
  }

  @override
  String get youCannotShareWithYourself => 'You cannot share with yourself';

  @override
  String emailNoEnteAccount(Object email) {
    return '$email does not have an Ente account.\n\nSend them an invite to share files.';
  }

  @override
  String shareMyVerificationID(Object verificationID) {
    return 'Here\'s my verification ID: $verificationID for ente.io.';
  }

  @override
  String shareTextConfirmOthersVerificationID(Object verificationID) {
    return 'Hey, can you confirm that this is your ente.io verification ID: $verificationID';
  }

  @override
  String get inviteToEnte => 'Invite to Ente';
}
