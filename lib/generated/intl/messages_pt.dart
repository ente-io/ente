// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a pt locale. All the
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
  String get localeName => 'pt';

  static String m6(user) =>
      "${user} Não poderá adicionar mais fotos a este álbum\n\nEles ainda poderão remover as fotos existentes adicionadas por eles";

  static String m7(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Sua família reeinvindicou ${storageAmountInGb} GB até agora',
            'false': 'Você reeinvindicou ${storageAmountInGb} GB até agora',
            'other': 'Você reeinvindicou ${storageAmountInGb} GB até agora',
          })}";

  static String m12(albumName) =>
      "Isso removerá o link público para acessar \"${albumName}\".";

  static String m13(supportEmail) =>
      "Por favor, envie um e-mail para ${supportEmail} a partir do seu endereço de e-mail registrado";

  static String m19(storageAmountInGB) =>
      "${storageAmountInGB} GB cada vez que alguém se inscrever para um plano pago e aplica o seu código";

  static String m31(passwordStrengthValue) =>
      "Segurança da senha: ${passwordStrengthValue}";

  static String m37(storageInGB) => "3. Ambos ganham ${storageInGB} GB* grátis";

  static String m38(userEmail) =>
      "${userEmail} será removido deste álbum compartilhado\n\nQuaisquer fotos adicionadas por eles também serão removidas do álbum";

  static String m44(referralCode, referralStorageInGB) =>
      "Código de referência do ente: ${referralCode} \n\nAplique em Configurações → Geral → Indicações para obter ${referralStorageInGB} GB gratuitamente após a sua inscrição em um plano pago\n\nhttps://ente.io";

  static String m50(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m55(storageAmountInGB) =>
      "Eles também recebem ${storageAmountInGB} GB";

  static String m59(email) => "Enviamos um e-mail à <green>${email}</green>";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Uma nova versão do ente está disponível."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bem-vindo de volta!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Eu entendo que se eu perder minha senha, posso perder meus dados, já que meus dados são <underline>criptografados de ponta a ponta</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessões ativas"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Adicionar um novo email"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Adicionar colaborador"),
        "addMore": MessageLookupByLibrary.simpleMessage("Adicione mais"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Adicionar visualizador"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Adicionado como"),
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
            "Adicionando aos favoritos..."),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Proprietário"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permita que as pessoas com o link também adicionem fotos ao álbum compartilhado."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Permitir adicionar fotos"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Permitir transferências"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Você tem certeza que deseja encerrar a sessão?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Qual é o principal motivo para você excluir sua conta?"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para alterar seu e-mail"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para alterar sua senha"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para iniciar a exclusão de conta"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Só é possível remover arquivos de sua propriedade"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "cannotAddMorePhotosAfterBecomingViewer": m6,
        "changeEmail": MessageLookupByLibrary.simpleMessage("Mudar e-mail"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Mude sua senha"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Mude sua senha"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Alterar permissões?"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Verifique sua caixa de entrada (e ‘spam’) para concluir a verificação"),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
            "Solicitar armazenamento gratuito"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Reivindique mais!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Reivindicado"),
        "claimedStorageSoFar": m7,
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Código copiado para a área de transferência"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Código usado por você"),
        "collaborator": MessageLookupByLibrary.simpleMessage("Colaborador"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Os colaboradores podem adicionar fotos e vídeos ao álbum compartilhado."),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirme"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Confirmar exclusão da conta"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Sim, desejo excluir permanentemente esta conta e todos os seus dados."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirme sua senha"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirme a chave de recuperação"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirme sua chave de recuperação"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Falar com o suporte"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuar"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copie e cole este código\npara seu aplicativo autenticador"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Criar uma conta"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Criar nova conta"),
        "creatingLink": MessageLookupByLibrary.simpleMessage("Criando link..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Atualização crítica disponível"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("Descriptografando..."),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Deletar conta"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Lamentamos ver você partir. Por favor, compartilhe seus comentários para nos ajudar a melhorar."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Excluir conta permanentemente"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Excluir álbum"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Também excluir as fotos (e vídeos) presentes neste álbum de <bold>todos os</bold> outros álbuns dos quais eles fazem parte?"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Você está prestes a excluir permanentemente sua conta e todos os seus dados.\nEsta ação é irreversível."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Por favor, envie um e-mail para <warning>account-deletion@ente.io</warning> a partir do seu endereço de e-mail registrado."),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Excluir fotos"),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Está faltando um recurso-chave que eu preciso"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "O aplicativo ou um determinado recurso não está funcionando como eu acredito que deveria"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Encontrei outro serviço que gosto mais"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Meu motivo não está listado"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Sua solicitação será processada em até 72 horas."),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Excluir álbum compartilhado?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "O álbum será apagado para todos\n\nVocê perderá o acesso a fotos compartilhadas neste álbum que pertencem aos outros"),
        "details": MessageLookupByLibrary.simpleMessage("Detalhes"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Os espectadores ainda podem tirar screenshots ou salvar uma cópia de suas fotos usando ferramentas externas"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Observe"),
        "disableLinkMessage": m12,
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Fazer isso mais tarde"),
        "dropSupportEmail": m13,
        "eligible": MessageLookupByLibrary.simpleMessage("elegível"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "encryption": MessageLookupByLibrary.simpleMessage("Criptografia"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Chaves de criptografia"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Coloque o código"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Digite o email"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Insira uma senha nova para criptografar seus dados"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Insira a senha para criptografar seus dados"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Digite o código de 6 dígitos de\nseu aplicativo autenticador"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Por, favor insira um endereço de e-mail válido."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Insira o seu endereço de e-mail"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Insira sua senha"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Digite sua chave de recuperação"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exportar seus dados"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Failed to download video"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Não foi possível buscar informações do produto. Por favor, tente novamente mais tarde."),
        "faq": MessageLookupByLibrary.simpleMessage("Perguntas frequentes"),
        "feedback": MessageLookupByLibrary.simpleMessage("Opinião"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Esqueceu sua senha"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Armazenamento gratuito reivindicado"),
        "freeStorageOnReferralSuccess": m19,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Armazenamento livre utilizável"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Gerando chaves de criptografia..."),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Como funciona"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Senha incorreta"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "A chave de recuperação que você digitou está incorreta"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Chave de recuperação incorreta"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Dispositivo não seguro"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Instalar manualmente"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Endereço de e-mail invalido"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Chave inválida"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "A chave de recuperação que você digitou não é válida. Certifique-se de que contém 24 palavras e verifique a ortografia de cada uma.\n\nSe você inseriu um código de recuperação mais antigo, verifique se ele tem 64 caracteres e verifique cada um deles."),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Convidar para o ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Convide seus amigos"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Invite your friends to ente"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Os itens selecionados serão removidos deste álbum"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Manter fotos"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Ajude-nos com esta informação"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limite do dispositivo"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expirado"),
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Expiração do link"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Login"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Ao clicar em login, eu concordo com os <u-terms>termos de serviço</u-terms> e a <u-policy>política de privacidade</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Encerrar sessão"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Dispositivo perdido?"),
        "manage": MessageLookupByLibrary.simpleMessage("Gerenciar"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderada"),
        "noAlbumsSharedByYouYet":
            MessageLookupByLibrary.simpleMessage("No albums shared by you yet"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Nenhuma chave de recuperação?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Devido à natureza do nosso protocolo de criptografia de ponta a ponta, seus dados não podem ser descriptografados sem sua senha ou chave de recuperação"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("Nothing shared with you yet"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "oops": MessageLookupByLibrary.simpleMessage("Ops"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ops! Algo deu errado"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Ou escolha um existente"),
        "password": MessageLookupByLibrary.simpleMessage("Senha"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Senha alterada com sucesso"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Bloqueio de senha"),
        "passwordStrength": m31,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Nós não salvamos essa senha, se você esquecer <underline> nós não poderemos descriptografar seus dados</underline>"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("Pessoas que usam seu código"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Por favor, tente novamente"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Por favor, aguarde..."),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Política de Privacidade"),
        "recover": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recuperar conta"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Chave de recuperação"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Chaves de recuperação foram copiadas para a área de transferência"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Caso você esqueça sua senha, a única maneira de recuperar seus dados é com essa chave."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Não armazenamos essa chave, por favor, salve essa chave de 24 palavras em um lugar seguro."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Ótimo! Sua chave de recuperação é válida. Obrigado por verificar.\n\nLembre-se de manter o backup seguro de sua chave de recuperação."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Chave de recuperação verificada"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Sua chave de recuperação é a única maneira de recuperar suas fotos se você esquecer sua senha. Você pode encontrar sua chave de recuperação em Configurações > Conta.\n\nDigite sua chave de recuperação aqui para verificar se você a salvou corretamente."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Recuperação bem sucedida!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "O dispositivo atual não é poderoso o suficiente para verificar sua senha, mas podemos regenerar de uma forma que funcione com todos os dispositivos.\n\nPor favor, faça o login usando sua chave de recuperação e recrie sua senha (você pode usar o mesmo novamente se desejar)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Restabeleça sua senha"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "Envie esse código aos seus amigos"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Eles se inscrevem em um plano pago"),
        "referralStep3": m37,
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Referências estão atualmente pausadas"),
        "remove": MessageLookupByLibrary.simpleMessage("Remover"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Remover do álbum"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Remover do álbum?"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Remover participante"),
        "removeParticipantBody": m38,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Remover link público"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Alguns dos itens que você está removendo foram adicionados por outras pessoas, e você perderá o acesso a eles"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Excluir?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Removendo dos favoritos..."),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Reenviar e-mail"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Restabeleça sua senha"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Salvar chave"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Salve sua chave de recuperação, caso ainda não o tenha feito"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Escanear código"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Escaneie este código de barras com\nseu aplicativo autenticador"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Selecione o motivo"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Enviar e-mail"),
        "setPasswordTitle": MessageLookupByLibrary.simpleMessage(
            "Chave: definaSenha\n→ definaSenha"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configuração concluída"),
        "shareTextReferralCode": m44,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Share your first album"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Shared by you"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Shared with you"),
        "sharing": MessageLookupByLibrary.simpleMessage("Compartilhando..."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Eu concordo com os <u-terms>termos de serviço</u-terms> e a <u-policy>política de privacidade</u-policy>"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Algo deu errado. Por favor, tente outra vez"),
        "sorry": MessageLookupByLibrary.simpleMessage("Desculpe"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Desculpe, não foi possível adicionar aos favoritos!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Desculpe, não foi possível remover dos favoritos!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Desculpe, não foi possível gerar chaves seguras neste dispositivo.\n\npor favor, faça o login com um dispositivo diferente."),
        "storageInGB": m50,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Forte"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Inscrever-se"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Parece que sua assinatura expirou. Por favor inscreva-se para ativar o compartilhamento."),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("toque para copiar"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Clica para inserir código"),
        "terminate": MessageLookupByLibrary.simpleMessage("Terminar"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Encerrar sessão?"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Termos"),
        "theyAlsoGetXGb": m55,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Isso pode ser usado para recuperar sua conta se você perder seu segundo fator"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Este aparelho"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Isso fará com que você saia do seguinte dispositivo:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Isso fará com que você saia deste dispositivo!"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Tente novamente"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Autenticação de dois fatores"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Autenticação de dois fatores"),
        "update": MessageLookupByLibrary.simpleMessage("Atualização"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Atualização disponível"),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Armazenamento utilizável é limitado pelo seu plano atual. O armazenamento reivindicado em excesso se tornará utilizável automaticamente quando você fizer a melhoria do seu plano."),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Usar chave de recuperação"),
        "verify": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Verificar email"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verificar senha"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verificando chave de recuperação..."),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ver chave de recuperação"),
        "viewer": MessageLookupByLibrary.simpleMessage("Visualizador"),
        "weHaveSendEmailTo": m59,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Fraca"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Bem-vindo de volta!"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Sim, converter para visualizador"),
        "yesLogout":
            MessageLookupByLibrary.simpleMessage("Sim, terminar sessão"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Sim, excluir"),
        "you": MessageLookupByLibrary.simpleMessage("Você"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Você pode duplicar seu armazenamento no máximo"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Sua conta foi deletada")
      };
}
