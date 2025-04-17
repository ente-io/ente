// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a pt_PT locale. All the
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
  String get localeName => 'pt_PT';

  static String m0(storageAmount, endDate) =>
      "Seu addon ${storageAmount} é válido até o momento ${endDate}";

  static String m48(emailOrName) => "Adicionado por ${emailOrName}";

  static String m49(albumName) => "Adicionado com sucesso a ${albumName}";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Nenhum participante', one: '1 participante', other: '${count} participantes')}";

  static String m51(versionValue) => "Versão: ${versionValue}";

  static String m52(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} grátis";

  static String m2(paymentProvider) =>
      "Por favor, cancele primeiro a sua subscrição existente de ${paymentProvider}";

  static String m3(user) =>
      "${user} não será capaz de adicionar mais fotos a este álbum\n\nEles ainda serão capazes de remover fotos existentes adicionadas por eles";

  static String m4(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Sua família reinvidicou ${storageAmountInGb} GB até então',
            'false': 'Você reinvindicou ${storageAmountInGb} GB até então',
            'other': 'Você reinvindicou ${storageAmountInGb} GB até então!',
          })}";

  static String m54(albumName) => "Link colaborativo criado para ${albumName}";

  static String m55(count) =>
      "${Intl.plural(count, zero: 'Adicionado 0 colaboradores', one: 'Adicionado 1 colaborador', other: 'Adicionado ${count} colaboradores')}";

  static String m5(familyAdminEmail) =>
      "Contacte <green>${familyAdminEmail}</green> para gerir a sua subscrição";

  static String m6(provider) =>
      "Contacte-nos em support@ente.io para gerir a sua subscrição ${provider}";

  static String m57(endpoint) => "Conectado a ${endpoint}";

  static String m7(count) =>
      "${Intl.plural(count, one: 'Apagar ${count} item', other: 'Apagar ${count} itens')}";

  static String m58(currentlyDeleting, totalCount) =>
      "Apagar ${currentlyDeleting} / ${totalCount}";

  static String m8(albumName) =>
      "Isto removerá o link público para acessar \"${albumName}\".";

  static String m9(supportEmail) =>
      "Envie um e-mail para ${supportEmail} a partir do seu endereço de e-mail registado";

  static String m10(count, storageSaved) =>
      "Você limpou ${Intl.plural(count, one: '${count} arquivo duplicado', other: '${count} arquivos duplicados')}, guardando (${storageSaved}!)";

  static String m11(count, formattedSize) =>
      "${count} arquivos, ${formattedSize} cada";

  static String m59(newEmail) => "Email alterado para ${newEmail}";

  static String m12(email) =>
      "${email} não possui uma conta Ente.\n\nEnvie um convite para compartilhar fotos.";

  static String m62(text) => "Fotos extras encontradas para ${text}";

  static String m64(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 arquivo', other: '${formattedNumber} arquivos')} neste dispositivo teve um backup seguro";

  static String m65(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 arquivo', other: '${formattedNumber} arquivos')} neste álbum teve um backup seguro";

  static String m13(storageAmountInGB) =>
      "${storageAmountInGB} GB sempre que alguém se inscreve num plano pago e aplica o seu código";

  static String m14(endDate) => "Teste gratuito válido até ${endDate}";

  static String m67(sizeInMBorGB) => "Libertar ${sizeInMBorGB}";

  static String m69(currentlyProcessing, totalCount) =>
      "Processando ${currentlyProcessing} / ${totalCount}";

  static String m15(count) =>
      "${Intl.plural(count, one: '${count} item', other: '${count} itens')}";

  static String m16(expiryTime) => "O link expirará em ${expiryTime}";

  static String m77(albumName) => "Movido com sucesso para ${albumName}";

  static String m79(name) => "Não é ${name}?";

  static String m17(familyAdminEmail) =>
      "Entre em contato com ${familyAdminEmail} para alterar o seu código.";

  static String m18(passwordStrengthValue) =>
      "Força da palavra-passe: ${passwordStrengthValue}";

  static String m19(providerName) =>
      "Por favor, fale com o suporte ${providerName} se você foi cobrado";

  static String m20(endDate) =>
      "Teste gratuito válido até ${endDate}.\nVocê pode escolher um plano pago depois.";

  static String m85(toEmail) =>
      "Por favor, envie-nos um e-mail para ${toEmail}";

  static String m86(toEmail) => "Por favor, envie os logs para \n${toEmail}";

  static String m88(folderName) => "Processando ${folderName}...";

  static String m21(storeName) => "Avalie-nos em ${storeName}";

  static String m22(storageInGB) => "3. Ambos ganham ${storageInGB} GB* grátis";

  static String m23(userEmail) =>
      "${userEmail} será removido deste álbum compartilhado\n\nQuaisquer fotos adicionadas por elas também serão removidas do álbum";

  static String m24(endDate) => "A subscrição é renovada em ${endDate}";

  static String m94(count) =>
      "${Intl.plural(count, one: '${count} ano atrás', other: '${count} anos atrás')}";

  static String m25(count) => "${count} selecionado(s)";

  static String m26(count, yourCount) =>
      "${count} selecionado(s) (${yourCount} seus)";

  static String m27(verificationID) =>
      "Aqui está o meu ID de verificação: ${verificationID} para ente.io.";

  static String m28(verificationID) =>
      "Ei, você pode confirmar que este é seu ID de verificação do ente.io: ${verificationID}";

  static String m29(referralCode, referralStorageInGB) =>
      "Insira o código de referência: ${referralCode} \n\nAplique-o em Configurações → Geral → Indicações para obter ${referralStorageInGB} GB gratuitamente após a sua inscrição para um plano pago\n\nhttps://ente.io";

  static String m30(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Compartilhe com pessoas específicas', one: 'Compartilhado com 1 pessoa', other: 'Compartilhado com ${numberOfPeople} pessoas')}";

  static String m97(emailIDs) => "Partilhado com ${emailIDs}";

  static String m31(fileType) =>
      "Este ${fileType} será eliminado do seu dispositivo.";

  static String m32(fileType) =>
      "Este ${fileType} encontra-se tanto no Ente como no seu dispositivo.";

  static String m33(fileType) => "Este ${fileType} será eliminado do Ente.";

  static String m34(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m100(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} de ${totalAmount} ${totalStorageUnit} usado";

  static String m35(id) =>
      "Seu ${id} já está vinculado a outra conta Ente.\nSe você gostaria de usar seu ${id} com esta conta, por favor contate nosso suporte\'\'";

  static String m36(endDate) => "A sua subscrição será cancelada em ${endDate}";

  static String m101(completed, total) =>
      "${completed}/${total} memórias preservadas";

  static String m37(storageAmountInGB) =>
      "Eles também recebem ${storageAmountInGB} GB";

  static String m38(email) => "Este é o ID de verificação de ${email}";

  static String m105(count) =>
      "${Intl.plural(count, zero: 'Brevemente', one: '1 dia', other: '${count} dias')}";

  static String m109(galleryType) =>
      "Tipo de galeria ${galleryType} não é permitido para renomear";

  static String m110(ignoreReason) => "Envio ignorado devido à ${ignoreReason}";

  static String m111(count) => "Preservar ${count} memórias...";

  static String m39(endDate) => "Válido até ${endDate}";

  static String m40(email) => "Verificar e-mail";

  static String m41(email) => "Enviamos um e-mail para <green>${email}</green>";

  static String m42(count) =>
      "${Intl.plural(count, one: '${count} ano atrás', other: '${count} anos atrás')}";

  static String m43(storageSaved) =>
      "Você liberou ${storageSaved} com sucesso!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Está disponível uma nova versão do Ente."),
        "about": MessageLookupByLibrary.simpleMessage("Sobre"),
        "account": MessageLookupByLibrary.simpleMessage("Conta"),
        "accountIsAlreadyConfigured":
            MessageLookupByLibrary.simpleMessage("A conta já está ajustada."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bem-vindo de volta!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Eu entendo que se eu perder a minha palavra-passe, posso perder os meus dados já que esses dados são <underline> encriptados de ponta a ponta</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessões ativas"),
        "add": MessageLookupByLibrary.simpleMessage("Adicionar"),
        "addAName": MessageLookupByLibrary.simpleMessage("Adiciona um nome"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Adicionar um novo e-mail"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Adicionar colaborador"),
        "addFromDevice": MessageLookupByLibrary.simpleMessage(
            "Adicionar a partir do dispositivo"),
        "addLocation":
            MessageLookupByLibrary.simpleMessage("Adicionar localização"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Adicionar"),
        "addMore": MessageLookupByLibrary.simpleMessage("Adicionar mais"),
        "addName": MessageLookupByLibrary.simpleMessage("Adicionar pessoa"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Adicionar nome ou juntar"),
        "addNew": MessageLookupByLibrary.simpleMessage("Adicionar novo"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Adicionar nova pessoa"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Detalhes dos addons"),
        "addOnValidTill": m0,
        "addOns": MessageLookupByLibrary.simpleMessage("addons"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Adicionar fotos"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Adicionar selecionados"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Adicionar ao álbum"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Adicionar ao Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Adicionar a álbum oculto"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Adicionar visualizador"),
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Adicione suas fotos agora"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Adicionado como"),
        "addedBy": m48,
        "addedSuccessfullyTo": m49,
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
            "Adicionando aos favoritos..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Avançado"),
        "advancedSettings":
            MessageLookupByLibrary.simpleMessage("Definições avançadas"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Depois de 1 dia"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Depois de 1 Hora"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Depois de 1 mês"),
        "after1Week":
            MessageLookupByLibrary.simpleMessage("Depois de 1 semana"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Depois de 1 ano"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Dono"),
        "albumParticipantsCount": m1,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Título do álbum"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Álbum atualizado"),
        "albums": MessageLookupByLibrary.simpleMessage("Álbuns"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Tudo limpo"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
            "Todas as memórias preservadas"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Todos os agrupamentos para esta pessoa serão reiniciados e perderá todas as sugestões feitas para esta pessoa"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permitir que pessoas com o link também adicionem fotos ao álbum compartilhado."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Permitir adicionar fotos"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Permitir downloads"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Permitir que as pessoas adicionem fotos"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Verificar identidade"),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
            "Não reconhecido. Tente novamente."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Biometria necessária"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Sucesso"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Credenciais do dispositivo são necessárias"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Credenciais do dispositivo necessárias"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "A autenticação biométrica não está configurada no seu dispositivo. Vá a “Definições > Segurança” para adicionar a autenticação biométrica."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Desktop"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Autenticação necessária"),
        "appLock": MessageLookupByLibrary.simpleMessage("Bloqueio de app"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Escolha entre o ecrã de bloqueio predefinido do seu dispositivo e um ecrã de bloqueio personalizado com um PIN ou uma palavra-passe."),
        "appVersion": m51,
        "appleId": MessageLookupByLibrary.simpleMessage("ID da Apple"),
        "apply": MessageLookupByLibrary.simpleMessage("Aplicar"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Aplicar código"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Subscrição da AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("............"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Arquivar álbum"),
        "archiving": MessageLookupByLibrary.simpleMessage("Arquivar..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Tem certeza que deseja sair do plano familiar?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Tem a certeza de que quer cancelar?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Tem a certeza de que pretende alterar o seu plano?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Tem certeza de que deseja sair?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Tem certeza que deseja terminar a sessão?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Tem a certeza de que pretende renovar?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Tens a certeza de que queres repor esta pessoa?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "A sua subscrição foi cancelada. Gostaria de partilhar o motivo?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Qual o principal motivo pelo qual está a eliminar a conta?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Peça aos seus entes queridos para partilharem"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("em um abrigo avançado"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, autentique-se para alterar a verificação de e-mail"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para alterar a configuração da tela do ecrã de bloqueio"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para alterar o seu e-mail"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para alterar a palavra-passe"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, autentique para configurar a autenticação de dois fatores"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Autentique-se para iniciar a eliminação da conta"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Autentique-se para ver a sua chave de acesso"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para ver as suas sessões ativas"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique para ver seus arquivos ocultos"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para ver suas memórias"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para ver a chave de recuperação"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("A Autenticar..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Falha na autenticação, por favor tente novamente"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("Autenticação bem sucedida!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Verá os dispositivos Cast disponíveis aqui."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Certifique-se de que as permissões de Rede local estão activadas para a aplicação Ente Photos, nas Definições."),
        "autoLock": MessageLookupByLibrary.simpleMessage("Bloqueio automático"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Tempo após o qual a aplicação bloqueia depois de ser colocada em segundo plano"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Devido a uma falha técnica, a sua sessão foi encerrada. Pedimos desculpas pelo incómodo."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Emparelhamento automático"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "O pareamento automático funciona apenas com dispositivos que suportam o Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Disponível"),
        "availableStorageSpace": m52,
        "backedUpFolders": MessageLookupByLibrary.simpleMessage(
            "Pastas com cópia de segurança"),
        "backup": MessageLookupByLibrary.simpleMessage("Cópia de segurança"),
        "backupFailed": MessageLookupByLibrary.simpleMessage("Backup falhou"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Cópia de segurança através dos dados móveis"),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
            "Definições da cópia de segurança"),
        "backupStatus": MessageLookupByLibrary.simpleMessage(
            "Status da cópia de segurança"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Os itens que foram salvos com segurança aparecerão aqui"),
        "backupVideos": MessageLookupByLibrary.simpleMessage(
            "Cópia de segurança de vídeos"),
        "birthday": MessageLookupByLibrary.simpleMessage("Aniversário"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Promoção Black Friday"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Dados em cache"),
        "calculating": MessageLookupByLibrary.simpleMessage("Calcular..."),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Não é possível fazer upload para álbuns pertencentes a outros"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Só pode criar um link para arquivos pertencentes a você"),
        "canOnlyRemoveFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(""),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "cancelOtherSubscription": m2,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Cancelar subscrição"),
        "cannotAddMorePhotosAfterBecomingViewer": m3,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Não é possível eliminar ficheiros partilhados"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Certifique-se de estar na mesma rede que a TV."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("Falha ao transmitir álbum"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Visite cast.ente.io no dispositivo que pretende emparelhar.\n\n\nIntroduza o código abaixo para reproduzir o álbum na sua TV."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Ponto central"),
        "change": MessageLookupByLibrary.simpleMessage("Alterar"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Alterar e-mail"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Alterar a localização dos itens selecionados?"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Alterar palavra-passe"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Alterar palavra-passe"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Alterar permissões"),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
            "Alterar o código de referência"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Procurar atualizações"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Verifique a sua caixa de entrada (e spam) para concluir a verificação"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Verificar status"),
        "checking": MessageLookupByLibrary.simpleMessage("A verificar..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("A verificar modelos..."),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
            "Solicitar armazenamento gratuito"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Reclamar mais!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Reclamado"),
        "claimedStorageSoFar": m4,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Limpar sem categoria"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Remover todos os arquivos da Não Categorizados que estão presentes em outros álbuns"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Limpar cache"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Limpar índices"),
        "click": MessageLookupByLibrary.simpleMessage("Clique"),
        "clickOnTheOverflowMenu":
            MessageLookupByLibrary.simpleMessage("• Clique no menu adicional"),
        "close": MessageLookupByLibrary.simpleMessage("Fechar"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
            "Agrupar por tempo de captura"),
        "clubByFileName": MessageLookupByLibrary.simpleMessage(
            "Agrupar pelo nome de arquivo"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Progresso de agrupamento"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Código aplicado"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Desculpe, você atingiu o limite de alterações de código."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Código copiado para área de transferência"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Código usado por você"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Criar um link para permitir que as pessoas adicionem e visualizem fotos em seu álbum compartilhado sem precisar de um aplicativo Ente ou conta. Ótimo para coletar fotos do evento."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Link colaborativo"),
        "collaborativeLinkCreatedFor": m54,
        "collaborator": MessageLookupByLibrary.simpleMessage("Colaborador"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Os colaboradores podem adicionar fotos e vídeos ao álbum compartilhado."),
        "collaboratorsSuccessfullyAdded": m55,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Layout"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("Colagem guardada na galeria"),
        "collect": MessageLookupByLibrary.simpleMessage("Recolher"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Coletar fotos do evento"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Coletar fotos"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Crie um link onde seus amigos podem enviar fotos na qualidade original."),
        "color": MessageLookupByLibrary.simpleMessage("Cor"),
        "configuration": MessageLookupByLibrary.simpleMessage("Configuração"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Tem a certeza de que pretende desativar a autenticação de dois fatores?"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Confirmar eliminação de conta"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Sim, pretendo apagar permanentemente esta conta e os respetivos dados em todas as aplicações."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirmar palavra-passe"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Confirmar alteração de plano"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmar chave de recuperação"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmar chave de recuperação"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Ligar ao dispositivo"),
        "contactFamilyAdmin": m5,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contactar o suporte"),
        "contactToManageSubscription": m6,
        "contacts": MessageLookupByLibrary.simpleMessage("Contactos"),
        "contents": MessageLookupByLibrary.simpleMessage("Conteúdos"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuar"),
        "continueOnFreeTrial":
            MessageLookupByLibrary.simpleMessage("Continuar em teste gratuito"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Converter para álbum"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Copiar endereço de email"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copiar link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copie e cole este código\nno seu aplicativo de autenticação"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Não foi possível fazer o backup de seus dados.\nTentaremos novamente mais tarde."),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
            "Não foi possível libertar espaço"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Não foi possível atualizar a subscrição"),
        "count": MessageLookupByLibrary.simpleMessage("Contagem"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Relatório de falhas"),
        "create": MessageLookupByLibrary.simpleMessage("Criar"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Criar conta"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Pressione e segure para selecionar fotos e clique em + para criar um álbum"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Criar link colaborativo"),
        "createCollage": MessageLookupByLibrary.simpleMessage("Criar coleção"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Criar nova conta"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Criar ou selecionar álbum"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Criar link público"),
        "creatingLink": MessageLookupByLibrary.simpleMessage("Criar link..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Atualização crítica disponível"),
        "crop": MessageLookupByLibrary.simpleMessage("Recortar"),
        "curatedMemories":
            MessageLookupByLibrary.simpleMessage("Curated memories"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("O uso atual é "),
        "custom": MessageLookupByLibrary.simpleMessage("Personalizado"),
        "customEndpoint": m57,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Escuro"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Hoje"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Ontem"),
        "decrypting": MessageLookupByLibrary.simpleMessage("A desencriptar…"),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Descriptografando vídeo..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Arquivos duplicados"),
        "delete": MessageLookupByLibrary.simpleMessage("Apagar"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Eliminar conta"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Lamentamos a sua partida. Indique-nos a razão para podermos melhorar o serviço."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Excluir conta permanentemente"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Apagar álbum"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Eliminar também as fotos (e vídeos) presentes neste álbum de <bold>all</bold>  os outros álbuns de que fazem parte?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Esta ação elimina todos os álbuns vazios. Isto é útil quando pretende reduzir a confusão na sua lista de álbuns."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Apagar tudo"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Esta conta está ligada a outras aplicações Ente, se utilizar alguma. Os seus dados carregados, em todas as aplicações Ente, serão agendados para eliminação e a sua conta será permanentemente eliminada."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Envie um e-mail para <warning>accountt-deletion@ente.io</warning> a partir do seu endereço de email registrado."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Apagar álbuns vazios"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Apagar álbuns vazios?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Apagar de ambos"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Apagar do dispositivo"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Apagar do Ente"),
        "deleteItemCount": m7,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Apagar localização"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Apagar fotos"),
        "deleteProgress": m58,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Falta uma funcionalidade-chave de que eu necessito"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "O aplicativo ou um determinado recurso não se comportou como era suposto"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Encontrei outro serviço de que gosto mais"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("O motivo não está na lista"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "O seu pedido será processado dentro de 72 horas."),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Excluir álbum compartilhado?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "O álbum será apagado para todos\n\nVocê perderá o acesso a fotos compartilhadas neste álbum que são propriedade de outros"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar tudo"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Feito para ter longevidade"),
        "details": MessageLookupByLibrary.simpleMessage("Detalhes"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Definições do programador"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Tem a certeza de que pretende modificar as definições de programador?"),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Introduza o código"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Os ficheiros adicionados a este álbum de dispositivo serão automaticamente transferidos para o Ente."),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Bloqueio do dispositivo"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Desativar o bloqueio do ecrã do dispositivo quando o Ente estiver em primeiro plano e houver uma cópia de segurança em curso. Normalmente, isto não é necessário, mas pode ajudar a que os grandes carregamentos e as importações iniciais de grandes bibliotecas sejam concluídos mais rapidamente."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Dispositivo não encontrado"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Você sabia?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Desativar bloqueio automático"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Visualizadores ainda podem fazer capturas de tela ou salvar uma cópia das suas fotos usando ferramentas externas"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Por favor, observe"),
        "disableLinkMessage": m8,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Desativar autenticação de dois fatores"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Desativar a autenticação de dois factores..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Descobrir"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Bebés"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Comemorações"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Comida"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Vegetação"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Colinas"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identidade"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Memes"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Notas"),
        "discover_pets":
            MessageLookupByLibrary.simpleMessage("Animais de estimação"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Recibos"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Capturas de ecrã"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfies"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Pôr do sol"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Cartões de visita"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Papéis de parede"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Rejeitar"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut":
            MessageLookupByLibrary.simpleMessage("Não terminar a sessão"),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Fazer isto mais tarde"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Pretende eliminar as edições que efectuou?"),
        "done": MessageLookupByLibrary.simpleMessage("Concluído"),
        "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "Duplicar o seu armazenamento"),
        "download": MessageLookupByLibrary.simpleMessage("Download"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Falha no download"),
        "downloading": MessageLookupByLibrary.simpleMessage("A transferir..."),
        "dropSupportEmail": m9,
        "duplicateFileCountWithStorageSaved": m10,
        "duplicateItemsGroup": m11,
        "edit": MessageLookupByLibrary.simpleMessage("Editar"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Editar localização"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Editar localização"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Editar pessoa"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Edição guardada"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Edições para localização só serão vistas dentro do Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("elegível"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "emailChangedTo": m59,
        "emailNoEnteAccount": m12,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("Verificação por e-mail"),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("Enviar logs por e-mail"),
        "empty": MessageLookupByLibrary.simpleMessage("Esvaziar"),
        "emptyTrash": MessageLookupByLibrary.simpleMessage("Esvaziar lixo?"),
        "enable": MessageLookupByLibrary.simpleMessage("Ativar"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "O Ente suporta a aprendizagem automática no dispositivo para reconhecimento facial, pesquisa mágica e outras funcionalidades de pesquisa avançadas"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Habilitar aprendizagem automática para pesquisa mágica e reconhecimento de rosto"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Ativar mapas"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Esta opção mostra as suas fotografias num mapa do mundo.\n\n\nEste mapa é alojado pelo Open Street Map e as localizações exactas das suas fotografias nunca são partilhadas.\n\n\nPode desativar esta funcionalidade em qualquer altura nas Definições."),
        "enabled": MessageLookupByLibrary.simpleMessage("Ativado"),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Criptografando backup..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Encriptação"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Chaves de encriptação"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Endpoint atualizado com sucesso"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Criptografia de ponta a ponta por padrão"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente pode criptografar e preservar arquivos apenas se você conceder acesso a eles"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>precisa de permissão para</i> preservar suas fotos"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "O Ente preserva as suas memórias, para que estejam sempre disponíveis, mesmo que perca o seu dispositivo."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Sua família também pode ser adicionada ao seu plano."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Introduzir nome do álbum"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Insira o código"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Introduza o código fornecido pelo seu amigo para obter armazenamento gratuito para ambos"),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Aniversário (opcional)"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Digite o e-mail"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Inserir nome do arquivo"),
        "enterName": MessageLookupByLibrary.simpleMessage("Inserir nome"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Inserir uma nova palavra-passe para encriptar os seus dados"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Introduzir palavra-passe"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Inserir uma palavra-passe para encriptar os seus dados"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Inserir nome da pessoa"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Introduzir PIN"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
            "Insira o código de referência"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Introduzir o código de 6 dígitos da\nsua aplicação de autenticação"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Por favor, insira um endereço de email válido."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Insira o seu endereço de email"),
        "enterYourPassword": MessageLookupByLibrary.simpleMessage(
            "Introduza a sua palavra-passe"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Insira a sua chave de recuperação"),
        "error": MessageLookupByLibrary.simpleMessage("Erro"),
        "everywhere": MessageLookupByLibrary.simpleMessage("em todo o lado"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Utilizador existente"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Este link expirou. Por favor, selecione um novo tempo de expiração ou desabilite a expiração do link."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Exportar logs"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exportar os seus dados"),
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
            "Fotos adicionais encontradas"),
        "extraPhotosFoundFor": m62,
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Reconhecimento facial"),
        "faces": MessageLookupByLibrary.simpleMessage("Rostos"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Falha ao aplicar código"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Falhou ao cancelar"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
            "Falha ao fazer o download do vídeo"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Falha ao obter sessões em atividade"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Falha ao obter original para edição"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Não foi possível obter detalhes de indicação. Por favor, tente novamente mais tarde."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Falha ao carregar álbuns"),
        "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Falha ao reproduzir multimédia"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Falha ao atualizar subscrição"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Falhou ao renovar"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Falha ao verificar status do pagamento"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Adicione 5 membros da família ao seu plano existente sem pagar mais.\n\n\nCada membro tem o seu próprio espaço privado e não pode ver os ficheiros dos outros, a menos que sejam partilhados.\n\n\nOs planos familiares estão disponíveis para clientes que tenham uma subscrição paga do Ente.\n\n\nSubscreva agora para começar!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Família"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Planos familiares"),
        "faq": MessageLookupByLibrary.simpleMessage("Perguntas Frequentes"),
        "faqs": MessageLookupByLibrary.simpleMessage("Perguntas frequentes"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorito"),
        "feedback": MessageLookupByLibrary.simpleMessage("Opinião"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Falha ao guardar o ficheiro na galeria"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Acrescente uma descrição..."),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Arquivo guardado na galeria"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Tipos de arquivo"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Tipos de arquivo e nomes"),
        "filesBackedUpFromDevice": m64,
        "filesBackedUpInAlbum": m65,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Arquivos apagados"),
        "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Arquivos guardados na galeria"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Encontrar pessoas rapidamente pelo nome"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("Ache-os rapidamente"),
        "flip": MessageLookupByLibrary.simpleMessage("Inverter"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("para suas memórias"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage(
            "Esqueceu-se da palavra-passe"),
        "foundFaces":
            MessageLookupByLibrary.simpleMessage("Rostos encontrados"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Armazenamento gratuito reclamado"),
        "freeStorageOnReferralSuccess": m13,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Armazenamento livre utilizável"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Teste grátis"),
        "freeTrialValidTill": m14,
        "freeUpAmount": m67,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Libertar espaço no dispositivo"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Poupe espaço no seu dispositivo limpando ficheiros dos quais já foi feita uma cópia de segurança."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Libertar espaço"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Até 1000 memórias mostradas na galeria"),
        "general": MessageLookupByLibrary.simpleMessage("Geral"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Gerando chaves de encriptação..."),
        "genericProgress": m69,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Ir para as definições"),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("ID do Google Play"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Por favor, permita o acesso a todas as fotos nas definições do aplicativo"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Conceder permissão"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("Agrupar fotos próximas"),
        "guestView": MessageLookupByLibrary.simpleMessage("Visão de convidado"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Para ativar a vista de convidado, configure o código de acesso do dispositivo ou o bloqueio do ecrã nas definições do sistema."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Não monitorizamos as instalações de aplicações. Ajudaria se nos dissesse onde nos encontrou!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Como é que soube do Ente? (opcional)"),
        "help": MessageLookupByLibrary.simpleMessage("Ajuda"),
        "hidden": MessageLookupByLibrary.simpleMessage("Oculto"),
        "hide": MessageLookupByLibrary.simpleMessage("Ocultar"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Ocultar conteúdo"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Oculta o conteúdo da aplicação no alternador de aplicações e desactiva as capturas de ecrã"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Oculta o conteúdo da aplicação no alternador de aplicações"),
        "hiding": MessageLookupByLibrary.simpleMessage("Ocultando..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Hospedado na OSM France"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Como funciona"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Por favor, peça-lhes para pressionar longamente o endereço de e-mail na tela de configurações e verifique se os IDs de ambos os dispositivos coincidem."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "A autenticação biométrica não está configurada no seu dispositivo. Active o Touch ID ou o Face ID no seu telemóvel."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "A autenticação biométrica está desativada. Por favor, bloqueie e desbloqueie o ecrã para ativá-la."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorar"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Alguns ficheiros deste álbum não podem ser carregados porque foram anteriormente eliminados do Ente."),
        "immediately": MessageLookupByLibrary.simpleMessage("Imediatamente"),
        "importing": MessageLookupByLibrary.simpleMessage("A importar..."),
        "incorrectCode":
            MessageLookupByLibrary.simpleMessage("Código incorrecto"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Palavra-passe incorreta"),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Chave de recuperação incorreta"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "A chave de recuperação inserida está incorreta"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Chave de recuperação incorreta"),
        "indexedItems": MessageLookupByLibrary.simpleMessage("Itens indexados"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "A indexação está pausada, será retomada automaticamente quando o dispositivo estiver pronto."),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Dispositivo inseguro"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Instalar manualmente"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Endereço de email inválido"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Endpoint inválido"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Desculpe, o endpoint que introduziu é inválido. Introduza um ponto final válido e tente novamente."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Chave inválida"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "A chave de recuperação que inseriu não é válida. Por favor, certifique-se que ela contém 24 palavras e verifique a ortografia de cada uma.\n\nSe inseriu um código de recuperação mais antigo, certifique-se de que tem 64 caracteres e verifique cada um deles."),
        "invite": MessageLookupByLibrary.simpleMessage("Convidar"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Convidar para Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Convide os seus amigos"),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
            "Convide seus amigos para o Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Parece que algo correu mal. Por favor, tente novamente após algum tempo. Se o erro persistir, contacte a nossa equipa de apoio."),
        "itemCount": m15,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Os itens mostram o número de dias restantes antes da eliminação permanente"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Os itens selecionados serão removidos deste álbum"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Juntar-se ao Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Manter fotos"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Por favor, ajude-nos com esta informação"),
        "language": MessageLookupByLibrary.simpleMessage("Idioma"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Última atualização"),
        "leave": MessageLookupByLibrary.simpleMessage("Sair"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Sair do álbum"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Deixar plano famíliar"),
        "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Sair do álbum compartilhado?"),
        "left": MessageLookupByLibrary.simpleMessage("Esquerda"),
        "light": MessageLookupByLibrary.simpleMessage("Claro"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Claro"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Link copiado para a área de transferência"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limite de dispositivo"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Ativado"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expirado"),
        "linkExpiresOn": m16,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Link expirado"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("O link expirou"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Nunca"),
        "livePhotos":
            MessageLookupByLibrary.simpleMessage("Fotos Em Tempo Real"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Pode partilhar a sua subscrição com a sua família"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Nós preservamos mais de 30 milhões de memórias até agora"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Mantemos 3 cópias dos seus dados, uma em um abrigo subterrâneo"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Todos os nossos aplicativos são de código aberto"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Nosso código-fonte e criptografia foram auditadas externamente"),
        "loadMessage6":
            MessageLookupByLibrary.simpleMessage("Deixar o álbum partilhado?"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Nossos aplicativos móveis são executados em segundo plano para criptografar e fazer backup de quaisquer novas fotos que você clique"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io tem um envio mais rápido"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Nós usamos Xchacha20Poly1305 para criptografar seus dados com segurança"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Carregando dados EXIF..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Carregando galeria..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Carregar as suas fotos..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Transferindo modelos..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Carregar as suas fotos..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galeria local"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Indexação local"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Parece que algo correu mal, uma vez que a sincronização de fotografias locais está a demorar mais tempo do que o esperado. Contacte a nossa equipa de apoio"),
        "location": MessageLookupByLibrary.simpleMessage("Localização"),
        "locationName":
            MessageLookupByLibrary.simpleMessage("Nome da localização"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Uma etiqueta de localização agrupa todas as fotos que foram tiradas num determinado raio de uma fotografia"),
        "locations": MessageLookupByLibrary.simpleMessage("Localizações"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Bloquear"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Ecrã de bloqueio"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Iniciar sessão"),
        "loggingOut":
            MessageLookupByLibrary.simpleMessage("Terminar a sessão..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessão expirada"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "A sua sessão expirou. Por favor, inicie sessão novamente."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Ao clicar em iniciar sessão, eu concordo com os termos <u-terms>de serviço</u-terms> e <u-policy>política de privacidade</u-policy>"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("Iniciar sessão com TOTP"),
        "logout": MessageLookupByLibrary.simpleMessage("Terminar sessão"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Isto enviará os registos para nos ajudar a resolver o problema. Tenha em atenção que os nomes dos ficheiros serão incluídos para ajudar a localizar problemas com ficheiros específicos."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Pressione e segure um e-mail para verificar a criptografia de ponta a ponta."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Pressione e segure em um item para ver em tela cheia"),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("Repetir vídeo desligado"),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("Repetir vídeo ligado"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Perdeu o seu dispositívo?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Aprendizagem automática"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Pesquisa mágica"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "A pesquisa mágica permite pesquisar fotos por seu conteúdo, por exemplo, \'flor\', \'carro vermelho\', \'documentos de identidade\'"),
        "manage": MessageLookupByLibrary.simpleMessage("Gerir"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Reveja e limpe o armazenamento de cache local."),
        "manageFamily": MessageLookupByLibrary.simpleMessage("Gerir família"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Gerir link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Gerir"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Gerir subscrição"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Emparelhar com PIN funciona com qualquer ecrã onde pretenda ver o seu álbum."),
        "map": MessageLookupByLibrary.simpleMessage("Mapa"),
        "maps": MessageLookupByLibrary.simpleMessage("Mapas"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "merchandise": MessageLookupByLibrary.simpleMessage("Produtos"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Juntar com o existente"),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Fotos combinadas"),
        "mlConsent": MessageLookupByLibrary.simpleMessage(
            "Ativar aprendizagem automática"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Eu entendo, e desejo ativar a aprendizagem automática"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Se ativar a aprendizagem automática, o Ente extrairá informações como a geometria do rosto de ficheiros, incluindo os partilhados consigo.\n\n\nIsto acontecerá no seu dispositivo e todas as informações biométricas geradas serão encriptadas de ponta a ponta."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Por favor, clique aqui para mais detalhes sobre este recurso na nossa política de privacidade"),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
            "Ativar aprendizagem automática?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Tenha em atenção que a aprendizagem automática resultará numa maior utilização da largura de banda e da bateria até que todos os itens sejam indexados. Considere utilizar a aplicação de ambiente de trabalho para uma indexação mais rápida, todos os resultados serão sincronizados automaticamente."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobile, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderada"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Modifique a sua consulta ou tente pesquisar por"),
        "moments": MessageLookupByLibrary.simpleMessage("Momentos"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensal"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Mais detalhes"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Mais recente"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Mais relevante"),
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Mover para álbum"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Mover para álbum oculto"),
        "movedSuccessfullyTo": m77,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Mover para o lixo"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Mover arquivos para o álbum..."),
        "name": MessageLookupByLibrary.simpleMessage("Nome"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Nomear o álbum"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Não foi possível conectar ao Ente, tente novamente após algum tempo. Se o erro persistir, entre em contato com o suporte."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Não foi possível estabelecer ligação ao Ente. Verifique as definições de rede e contacte o serviço de apoio se o erro persistir."),
        "never": MessageLookupByLibrary.simpleMessage("Nunca"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Novo álbum"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Nova pessoa"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Novo no Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Recentes"),
        "next": MessageLookupByLibrary.simpleMessage("Seguinte"),
        "no": MessageLookupByLibrary.simpleMessage("Não"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Ainda não há álbuns partilhados por si"),
        "noDeviceFound": MessageLookupByLibrary.simpleMessage(
            "Nenhum dispositivo encontrado"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Nenhum"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Você não tem arquivos neste dispositivo que possam ser apagados"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Sem duplicados"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Sem dados EXIF"),
        "noHiddenPhotosOrVideos":
            MessageLookupByLibrary.simpleMessage("Sem fotos ou vídeos ocultos"),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
            "Nenhuma imagem com localização"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Sem ligação à internet"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "No momento não há backup de fotos sendo feito"),
        "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage(
            "Nenhuma foto encontrada aqui"),
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
            "Nenhum link rápido selecionado"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Não tem chave de recuperação?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Devido à natureza do nosso protocolo de criptografia de ponta a ponta, os seus dados não podem ser descriptografados sem a sua palavra-passe ou a sua chave de recuperação"),
        "noResults": MessageLookupByLibrary.simpleMessage("Nenhum resultado"),
        "noResultsFound": MessageLookupByLibrary.simpleMessage(
            "Não foram encontrados resultados"),
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
            "Nenhum bloqueio de sistema encontrado"),
        "notPersonLabel": m79,
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Ainda nada partilhado consigo"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Nada para ver aqui! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notificações"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("No dispositivo"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Em <branding>ente</branding>"),
        "onlyFamilyAdminCanChangeCode": m17,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Apenas eles"),
        "oops": MessageLookupByLibrary.simpleMessage("Oops"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Oops, não foi possível guardar as edições"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ops, algo deu errado"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Abrir Definições"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Abra o item"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
            "Contribuidores do OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Opcional, o mais breve que quiser..."),
        "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
            "Ou combinar com já existente"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Ou escolha um já existente"),
        "pair": MessageLookupByLibrary.simpleMessage("Emparelhar"),
        "pairWithPin":
            MessageLookupByLibrary.simpleMessage("Emparelhar com PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Emparelhamento concluído"),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "A verificação ainda está pendente"),
        "passkey": MessageLookupByLibrary.simpleMessage("Chave de acesso"),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
            "Verificação da chave de acesso"),
        "password": MessageLookupByLibrary.simpleMessage("Palavra-passe"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Palavra-passe alterada com sucesso"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Bloqueio da palavra-passe"),
        "passwordStrength": m18,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "A força da palavra-passe é calculada tendo em conta o comprimento da palavra-passe, os caracteres utilizados e se a palavra-passe aparece ou não nas 10.000 palavras-passe mais utilizadas"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Não armazenamos esta palavra-passe, se você a esquecer, <underline>não podemos desencriptar os seus dados</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Detalhes de pagamento"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("O pagamento falhou"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Infelizmente o seu pagamento falhou. Entre em contato com o suporte e nós ajudaremos você!"),
        "paymentFailedTalkToProvider": m19,
        "pendingItems": MessageLookupByLibrary.simpleMessage("Itens pendentes"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Sincronização pendente"),
        "people": MessageLookupByLibrary.simpleMessage("Pessoas"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Pessoas que utilizam seu código"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Todos os itens no lixo serão permanentemente eliminados\n\n\nEsta ação não pode ser anulada"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Eliminar permanentemente"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Apagar permanentemente do dispositivo?"),
        "personName": MessageLookupByLibrary.simpleMessage("Nome da pessoa"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Descrições das fotos"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Tamanho da grelha de fotos"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "photos": MessageLookupByLibrary.simpleMessage("Fotos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "As fotos adicionadas por si serão removidas do álbum"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Escolha o ponto central"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Fixar álbum"),
        "pinLock": MessageLookupByLibrary.simpleMessage("Bloqueio por PIN"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Reproduzir álbum na TV"),
        "playStoreFreeTrialValidTill": m20,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Subscrição da PlayStore"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, verifique a sua ligação à Internet e tente novamente."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, entre em contato com support@ente.io e nós ficaremos felizes em ajudar!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, contate o suporte se o problema persistir"),
        "pleaseEmailUsAt": m85,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
            "Por favor, conceda as permissões"),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
            "Por favor, inicie sessão novamente"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Selecione links rápidos para remover"),
        "pleaseSendTheLogsTo": m86,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Por favor, tente novamente"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, verifique se o código que você inseriu"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Por favor, aguarde ..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Por favor aguarde,  apagar o álbum"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, aguarde algum tempo antes de tentar novamente"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Preparando logs..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Preservar mais"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Pressione e segure para reproduzir o vídeo"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Pressione e segure na imagem para reproduzir o vídeo"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacidade"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Política de privacidade"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Backups privados"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Partilha privada"),
        "processingImport": m88,
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Link público criado"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Link público ativado"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Links rápidos"),
        "radius": MessageLookupByLibrary.simpleMessage("Raio"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Abrir ticket"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Avaliar aplicação"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Avalie-nos"),
        "rateUsOnStore": m21,
        "recover": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recuperar conta"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Chave de recuperação"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Chave de recuperação copiada para a área de transferência"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Se esquecer sua palavra-passe, a única maneira de recuperar os seus dados é com esta chave."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Não armazenamos essa chave, por favor, guarde esta chave de 24 palavras num lugar seguro."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Ótimo! A sua chave de recuperação é válida. Obrigado por verificar.\n\nLembre-se de manter cópia de segurança da sua chave de recuperação."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Chave de recuperação verificada"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "A sua chave de recuperação é a única forma de recuperar as suas fotografias se se esquecer da sua palavra-passe. Pode encontrar a sua chave de recuperação em Definições > Conta.\n\n\nIntroduza aqui a sua chave de recuperação para verificar se a guardou corretamente."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Recuperação bem sucedida!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "O dispositivo atual não é suficientemente poderoso para verificar a palavra-passe, mas podemos regenerar novamente de uma maneira que funcione no seu dispositivo.\n\nPor favor, iniciar sessão utilizando código de recuperação e gerar novamente a sua palavra-passe (pode utilizar a mesma se quiser)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Recriar palavra-passe"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword": MessageLookupByLibrary.simpleMessage(
            "Insira novamente a palavra-passe"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("Inserir PIN novamente"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Recomende amigos e duplique o seu plano"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Envie este código aos seus amigos"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Eles se inscrevem em um plano pago"),
        "referralStep3": m22,
        "referrals": MessageLookupByLibrary.simpleMessage("Referências"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "As referências estão atualmente em pausa"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Esvazie também a opção “Eliminados recentemente” em “Definições” -> “Armazenamento” para reclamar o espaço libertado"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Esvazie também o seu “Lixo” para reivindicar o espaço libertado"),
        "remoteImages": MessageLookupByLibrary.simpleMessage("Imagens remotas"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Miniaturas remotas"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Vídeos remotos"),
        "remove": MessageLookupByLibrary.simpleMessage("Remover"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Remover duplicados"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Rever e remover ficheiros que sejam duplicados exatos."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Remover do álbum"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Remover do álbum"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Remover dos favoritos"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Remover link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Remover participante"),
        "removeParticipantBody": m23,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Remover etiqueta da pessoa"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Remover link público"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Remover link público"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Alguns dos itens que você está removendo foram adicionados por outras pessoas, e você perderá o acesso a eles"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Remover?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Removendo dos favoritos..."),
        "rename": MessageLookupByLibrary.simpleMessage("Renomear"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Renomear álbum"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Renomear arquivo"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Renovar subscrição"),
        "renewsOn": m24,
        "reportABug": MessageLookupByLibrary.simpleMessage("Reporte um bug"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Reportar bug"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Reenviar e-mail"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("Repor ficheiros ignorados"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Redefinir palavra-passe"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Remover"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Redefinir para o padrão"),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurar"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Restaurar para álbum"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Restaurar arquivos..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("Uploads reenviados"),
        "retry": MessageLookupByLibrary.simpleMessage("Tentar novamente"),
        "review": MessageLookupByLibrary.simpleMessage("Rever"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Reveja e elimine os itens que considera serem duplicados."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Revisar sugestões"),
        "right": MessageLookupByLibrary.simpleMessage("Direita"),
        "rotate": MessageLookupByLibrary.simpleMessage("Rodar"),
        "rotateLeft":
            MessageLookupByLibrary.simpleMessage("Rodar para a esquerda"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Rodar para a direita"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Armazenado com segurança"),
        "save": MessageLookupByLibrary.simpleMessage("Guardar"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Guardar colagem"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Guardar cópia"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Guardar chave"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Guardar pessoa"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Guarde a sua chave de recuperação, caso ainda não o tenha feito"),
        "saving": MessageLookupByLibrary.simpleMessage("A gravar..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Gravando edições..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Ler código Qr"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Leia este código com a sua aplicação dois fatores."),
        "search": MessageLookupByLibrary.simpleMessage("Pesquisar"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Álbuns"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Nome do álbum"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Nomes de álbuns (ex: \"Câmera\")\n• Tipos de arquivos (ex.: \"Vídeos\", \".gif\")\n• Anos e meses (e.. \"2022\", \"Janeiro\")\n• Feriados (por exemplo, \"Natal\")\n• Descrições de fotos (por exemplo, \"#divertido\")"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Adicione descrições como \"#trip\" nas informações das fotos para encontrá-las aqui rapidamente"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Pesquisar por data, mês ou ano"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "As pessoas serão mostradas aqui quando a indexação estiver concluída"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Tipos de arquivo e nomes"),
        "searchHint1": MessageLookupByLibrary.simpleMessage(
            "Pesquisa rápida no dispositivo"),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("Datas das fotos, descrições"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Álbuns, nomes de arquivos e tipos"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Local"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Em breve: Rostos e pesquisa mágica ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Fotos de grupo que estão sendo tiradas em algum raio da foto"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Convide pessoas e verá todas as fotos partilhadas por elas aqui"),
        "searchResultCount": m94,
        "security": MessageLookupByLibrary.simpleMessage("Segurança"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Selecione uma localização"),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
            "Selecione uma localização primeiro"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Selecionar álbum"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Selecionar tudo"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Selecionar pastas para cópia de segurança"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Selecionar itens para adicionar"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Selecionar Idioma"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Selecionar mais fotos"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Selecionar motivo"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Selecione o seu plano"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Os arquivos selecionados não estão no Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "As pastas selecionadas serão encriptadas e guardadas como cópia de segurança"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Os itens selecionados serão eliminados de todos os álbuns e movidos para o lixo."),
        "selectedPhotos": m25,
        "selectedPhotosWithYours": m26,
        "send": MessageLookupByLibrary.simpleMessage("Enviar"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Enviar email"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Enviar convite"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Enviar link"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Endpoint do servidor"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessão expirada"),
        "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
            "Incompatibilidade de ID de sessão"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Definir uma palavra-passe"),
        "setAs": MessageLookupByLibrary.simpleMessage("Definir como"),
        "setCover": MessageLookupByLibrary.simpleMessage("Definir capa"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Definir"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Definir nova palavra-passe"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("Definir novo PIN"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Definir palavra-passe"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Definir raio"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configuração concluída"),
        "share": MessageLookupByLibrary.simpleMessage("Partilhar"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Partilhar um link"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Abra um álbum e toque no botão de partilha no canto superior direito para partilhar"),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Partilhar um álbum"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Partilhar link"),
        "shareMyVerificationID": m27,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Partilhar apenas com as pessoas que deseja"),
        "shareTextConfirmOthersVerificationID": m28,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Descarregue o Ente para poder partilhar facilmente fotografias e vídeos de qualidade original\n\n\nhttps://ente.io"),
        "shareTextReferralCode": m29,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Compartilhar com usuários que não usam Ente"),
        "shareWithPeopleSectionTitle": m30,
        "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
            "Partilhe o seu primeiro álbum"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Criar álbuns compartilhados e colaborativos com outros usuários da Ente, incluindo usuários em planos gratuitos."),
        "sharedByMe":
            MessageLookupByLibrary.simpleMessage("Partilhado por mim"),
        "sharedByYou":
            MessageLookupByLibrary.simpleMessage("Partilhado por si"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Novas fotos partilhadas"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Receber notificações quando alguém adiciona uma foto a um álbum partilhado do qual faz parte"),
        "sharedWith": m97,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Partilhado comigo"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Partilhado consigo"),
        "sharing": MessageLookupByLibrary.simpleMessage("Partilhar..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Mostrar memórias"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Mostrar pessoa"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Terminar sessão noutros dispositivos"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Se pensa que alguém pode saber a sua palavra-passe, pode forçar todos os outros dispositivos que utilizam a sua conta a terminar a sessão."),
        "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Terminar a sessão noutros dispositivos"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Eu concordo com os <u-terms>termos de serviço</u-terms> e <u-policy>política de privacidade</u-policy>"),
        "singleFileDeleteFromDevice": m31,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Será eliminado de todos os álbuns."),
        "singleFileInBothLocalAndRemote": m32,
        "singleFileInRemoteOnly": m33,
        "skip": MessageLookupByLibrary.simpleMessage("Pular"),
        "social": MessageLookupByLibrary.simpleMessage("Social"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Alguns itens estão tanto no Ente como no seu dispositivo."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Alguns dos ficheiros que está a tentar eliminar só estão disponíveis no seu dispositivo e não podem ser recuperados se forem eliminados"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Alguém compartilhando álbuns com você deve ver o mesmo ID no seu dispositivo."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ocorreu um erro"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Ocorreu um erro. Tente novamente"),
        "sorry": MessageLookupByLibrary.simpleMessage("Desculpe"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Desculpe, não foi possível adicionar aos favoritos!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Desculpe, não foi possível remover dos favoritos!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Desculpe, o código inserido está incorreto"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Desculpe, não foi possível gerar chaves seguras neste dispositivo.\n\npor favor iniciar sessão com um dispositivo diferente."),
        "sort": MessageLookupByLibrary.simpleMessage("Ordenar"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Ordenar por"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Mais recentes primeiro"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Mais antigos primeiro"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Sucesso"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Iniciar cópia de segurança"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Queres parar de fazer transmissão?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Parar transmissão"),
        "storage": MessageLookupByLibrary.simpleMessage("Armazenamento"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Família"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Tu"),
        "storageInGB": m34,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
            "Limite de armazenamento excedido"),
        "storageUsageInfo": m100,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Forte"),
        "subAlreadyLinkedErrMessage": m35,
        "subWillBeCancelledOn": m36,
        "subscribe": MessageLookupByLibrary.simpleMessage("Subscrever"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Você precisa de uma assinatura paga ativa para ativar o compartilhamento."),
        "subscription": MessageLookupByLibrary.simpleMessage("Subscrição"),
        "success": MessageLookupByLibrary.simpleMessage("Sucesso"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Arquivado com sucesso"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Ocultado com sucesso"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Desarquivado com sucesso"),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("Reexibido com sucesso"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Sugerir recursos"),
        "support": MessageLookupByLibrary.simpleMessage("Suporte"),
        "syncProgress": m101,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Sincronização interrompida"),
        "syncing": MessageLookupByLibrary.simpleMessage("Sincronizando..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistema"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("toque para copiar"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Toque para inserir código"),
        "tapToUnlock":
            MessageLookupByLibrary.simpleMessage("Toque para desbloquear"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Parece que algo correu mal. Por favor, tente novamente mais tarde. Se o erro persistir, entre em contacto com a nossa equipa de suporte."),
        "terminate": MessageLookupByLibrary.simpleMessage("Terminar"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Terminar sessão?"),
        "terms": MessageLookupByLibrary.simpleMessage("Termos"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Termos"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Obrigado"),
        "thankYouForSubscribing": MessageLookupByLibrary.simpleMessage(
            "Obrigado pela sua subscrição!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Não foi possível concluir o download."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "A chave de recuperação inserida está incorreta"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Estes itens serão eliminados do seu dispositivo."),
        "theyAlsoGetXGb": m37,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Serão eliminados de todos os álbuns."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Esta ação não pode ser desfeita"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Este álbum já tem um link colaborativo"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Isto pode ser usado para recuperar sua conta se você perder seu segundo fator"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Este dispositivo"),
        "thisEmailIsAlreadyInUse":
            MessageLookupByLibrary.simpleMessage("Este email já está em uso"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Esta imagem não tem dados exif"),
        "thisIsPersonVerificationId": m38,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Este é o seu ID de verificação"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Irá desconectar a sua conta do seguinte dispositivo:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Irá desconectar a sua conta do seu dispositivo!"),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Isto removerá links públicos de todos os links rápidos selecionados."),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Para ativar o bloqueio de aplicações, configure o código de acesso do dispositivo ou o bloqueio de ecrã nas definições do sistema."),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Para ocultar uma foto ou um vídeo"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Para redefinir a sua palavra-passe, verifique primeiro o seu e-mail."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Logs de hoje"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
            "Muitas tentativas incorretas"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Tamanho total"),
        "trash": MessageLookupByLibrary.simpleMessage("Lixo"),
        "trashDaysLeft": m105,
        "trim": MessageLookupByLibrary.simpleMessage("Cortar"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Tente novamente"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Ative o backup para enviar automaticamente arquivos adicionados a esta pasta do dispositivo para o Ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 meses grátis em planos anuais"),
        "twofactor": MessageLookupByLibrary.simpleMessage("Dois fatores"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "A autenticação de dois fatores foi desativada"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Autenticação de dois fatores"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Autenticação de dois fatores redefinida com êxito"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Configuração de dois fatores"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m109,
        "unarchive": MessageLookupByLibrary.simpleMessage("Desarquivar"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Desarquivar álbum"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("Desarquivar..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Desculpe, este código não está disponível."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Sem categoria"),
        "unhide": MessageLookupByLibrary.simpleMessage("Mostrar"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Mostrar para o álbum"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Reexibindo..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Desocultar ficheiros para o álbum"),
        "unlock": MessageLookupByLibrary.simpleMessage("Desbloquear"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Desafixar álbum"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar tudo"),
        "update": MessageLookupByLibrary.simpleMessage("Atualizar"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Atualização disponível"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Atualizando seleção de pasta..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Atualizar"),
        "uploadIsIgnoredDueToIgnorereason": m110,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Enviar ficheiros para o álbum..."),
        "uploadingMultipleMemories": m111,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Preservar 1 memória..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Até 50% de desconto, até 4 de dezembro."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "O armazenamento disponível é limitado pelo seu plano atual. O excesso de armazenamento reivindicado tornará automaticamente útil quando você atualizar seu plano."),
        "useAsCover": MessageLookupByLibrary.simpleMessage("Usar como capa"),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Usar links públicos para pessoas que não estão no Ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Usar chave de recuperação"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Utilizar foto selecionada"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Espaço utilizado"),
        "validTill": m39,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Falha na verificação, por favor tente novamente"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de Verificação"),
        "verify": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Verificar email"),
        "verifyEmailID": m40,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Verificar chave de acesso"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verificar palavra-passe"),
        "verifying": MessageLookupByLibrary.simpleMessage("A verificar…"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verificando chave de recuperação..."),
        "videoInfo":
            MessageLookupByLibrary.simpleMessage("Informação de Vídeo"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vídeo"),
        "videos": MessageLookupByLibrary.simpleMessage("Vídeos"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Ver sessões ativas"),
        "viewAddOnButton": MessageLookupByLibrary.simpleMessage("Ver addons"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Ver tudo"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Ver todos os dados EXIF"),
        "viewLargeFiles":
            MessageLookupByLibrary.simpleMessage("Ficheiros grandes"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Ver os ficheiros que estão a consumir a maior quantidade de armazenamento."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Ver logs"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ver chave de recuperação"),
        "viewer": MessageLookupByLibrary.simpleMessage("Visualizador"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Visite web.ente.io para gerir a sua subscrição"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Aguardando verificação..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Aguardando Wi-Fi..."),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Nós somos de código aberto!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Não suportamos a edição de fotos e álbuns que ainda não possui"),
        "weHaveSendEmailTo": m41,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Fraca"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Bem-vindo(a) de volta!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("O que há de novo"),
        "yearly": MessageLookupByLibrary.simpleMessage("Anual"),
        "yearsAgo": m42,
        "yes": MessageLookupByLibrary.simpleMessage("Sim"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Sim, cancelar"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Sim, converter para visualizador"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Sim, apagar"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Sim, rejeitar alterações"),
        "yesLogout":
            MessageLookupByLibrary.simpleMessage("Sim, terminar sessão"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Sim, remover"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Sim, Renovar"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Sim, repor pessoa"),
        "you": MessageLookupByLibrary.simpleMessage("Tu"),
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
            "Você está em um plano familiar!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Está a utilizar a versão mais recente"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Você pode duplicar seu armazenamento no máximo"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Pode gerir as suas ligações no separador partilhar."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Pode tentar pesquisar uma consulta diferente."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Não é possível fazer o downgrade para este plano"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Não podes partilhar contigo mesmo"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Não tem nenhum item arquivado."),
        "youHaveSuccessfullyFreedUp": m43,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("A sua conta foi eliminada"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Seu mapa"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "O seu plano foi rebaixado com sucesso"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "O seu plano foi atualizado com sucesso"),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
            "Sua compra foi realizada com sucesso"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Não foi possível obter os seus dados de armazenamento"),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("A sua subscrição expirou"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "A sua subscrição foi actualizada com sucesso"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "O seu código de verificação expirou"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Não existem ficheiros neste álbum que possam ser eliminados"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
            "Diminuir o zoom para ver fotos")
      };
}
