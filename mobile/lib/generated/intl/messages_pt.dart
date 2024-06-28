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

  static String m0(count) =>
      "${Intl.plural(count, zero: 'Adicionar colaborador', one: 'Adicionar coloborador', other: 'Adicionar colaboradores')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Adicionar item', other: 'Adicionar itens')}";

  static String m3(storageAmount, endDate) =>
      "Seu complemento ${storageAmount} é válido até o dia ${endDate}";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Adicionar visualizador', one: 'Adicionar visualizador', other: 'Adicionar Visualizadores')}";

  static String m4(emailOrName) => "Adicionado por ${emailOrName}";

  static String m5(albumName) => "Adicionado com sucesso a  ${albumName}";

  static String m6(count) =>
      "${Intl.plural(count, zero: 'Nenhum Participante', one: '1 Participante', other: '${count} Participantes')}";

  static String m7(versionValue) => "Versão: ${versionValue}";

  static String m8(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} livre";

  static String m9(paymentProvider) =>
      "Por favor, cancele sua assinatura existente do ${paymentProvider} primeiro";

  static String m10(user) =>
      "${user} Não poderá adicionar mais fotos a este álbum\n\nEles ainda poderão remover as fotos existentes adicionadas por eles";

  static String m11(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Sua família reeinvindicou ${storageAmountInGb} GB até agora',
            'false': 'Você reeinvindicou ${storageAmountInGb} GB até agora',
            'other': 'Você reeinvindicou ${storageAmountInGb} GB até agora',
          })}";

  static String m12(albumName) => "Link colaborativo criado para ${albumName}";

  static String m13(familyAdminEmail) =>
      "Entre em contato com <green>${familyAdminEmail}</green> para gerenciar sua assinatura";

  static String m14(provider) =>
      "Entre em contato conosco pelo e-mail support@ente.io para gerenciar sua assinatura ${provider}.";

  static String m15(endpoint) => "Conectado a ${endpoint}";

  static String m16(count) =>
      "${Intl.plural(count, one: 'Excluir ${count} item', other: 'Excluir ${count} itens')}";

  static String m17(currentlyDeleting, totalCount) =>
      "Excluindo ${currentlyDeleting} / ${totalCount}";

  static String m18(albumName) =>
      "Isso removerá o link público para acessar \"${albumName}\".";

  static String m19(supportEmail) =>
      "Por favor, envie um e-mail para ${supportEmail} a partir do seu endereço de e-mail registrado";

  static String m20(count, storageSaved) =>
      "Você limpou ${Intl.plural(count, one: '${count} arquivo duplicado', other: '${count} arquivos duplicados')}, salvando (${storageSaved}!)";

  static String m21(count, formattedSize) =>
      "${count} Arquivos, ${formattedSize} cada";

  static String m22(newEmail) => "E-mail alterado para ${newEmail}";

  static String m23(email) =>
      "${email} não possui uma conta Ente.\n\nEnvie um convite para compartilhar fotos.";

  static String m24(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 arquivo', other: '${formattedNumber} arquivos')} neste dispositivo teve um backup seguro";

  static String m25(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 arquivo', other: '${formattedNumber} arquivos')} neste álbum teve um backup seguro";

  static String m26(storageAmountInGB) =>
      "${storageAmountInGB} GB cada vez que alguém se inscrever para um plano pago e aplica o seu código";

  static String m27(endDate) => "Teste gratuito acaba em ${endDate}";

  static String m28(count) =>
      "Você ainda pode acessar ${Intl.plural(count, one: 'ele', other: 'eles')} no Ente contanto que você tenha uma assinatura ativa";

  static String m29(sizeInMBorGB) => "Liberar ${sizeInMBorGB}";

  static String m30(count, formattedSize) =>
      "${Intl.plural(count, one: 'Pode ser excluído do dispositivo para liberar ${formattedSize}', other: 'Eles podem ser excluídos do dispositivo para liberar ${formattedSize}')}";

  static String m31(currentlyProcessing, totalCount) =>
      "Processando ${currentlyProcessing} / ${totalCount}";

  static String m32(count) =>
      "${Intl.plural(count, one: '${count} item', other: '${count} items')}";

  static String m33(expiryTime) => "O link irá expirar em ${expiryTime}";

  static String m34(count, formattedCount) =>
      "${Intl.plural(count, zero: 'sem memórias', one: '${formattedCount} memória', other: '${formattedCount} memórias')}";

  static String m35(count) =>
      "${Intl.plural(count, one: 'Mover item', other: 'Mover itens')}";

  static String m36(albumName) => "Movido com sucesso para ${albumName}";

  static String m37(passwordStrengthValue) =>
      "Segurança da senha: ${passwordStrengthValue}";

  static String m38(providerName) =>
      "Por favor, fale com o suporte ${providerName} se você foi cobrado";

  static String m39(endDate) =>
      "Teste gratuito válido até ${endDate}.\nVocê pode escolher um plano pago depois.";

  static String m40(toEmail) =>
      "Por favor, envie-nos um e-mail para ${toEmail}";

  static String m41(toEmail) => "Por favor, envie os logs para \n${toEmail}";

  static String m42(storeName) => "Avalie-nos em ${storeName}";

  static String m43(storageInGB) => "3. Ambos ganham ${storageInGB} GB* grátis";

  static String m44(userEmail) =>
      "${userEmail} será removido deste álbum compartilhado\n\nQuaisquer fotos adicionadas por eles também serão removidas do álbum";

  static String m45(endDate) => "Renovação de assinatura em ${endDate}";

  static String m46(count) =>
      "${Intl.plural(count, one: '${count} resultado encontrado', other: '${count} resultado encontrado')}";

  static String m47(count) => "${count} Selecionados";

  static String m48(count, yourCount) =>
      "${count} Selecionado (${yourCount} seus)";

  static String m49(verificationID) =>
      "Aqui está meu ID de verificação para o Ente.io: ${verificationID}";

  static String m50(verificationID) =>
      "Ei, você pode confirmar que este é seu ID de verificação do Ente.io? ${verificationID}";

  static String m51(referralCode, referralStorageInGB) =>
      "Código de referência do ente: ${referralCode} \n\nAplique em Configurações → Geral → Indicações para obter ${referralStorageInGB} GB gratuitamente após a sua inscrição em um plano pago\n\nhttps://ente.io";

  static String m52(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Compartilhe com pessoas específicas', one: 'Compartilhado com 1 pessoa', other: 'Compartilhado com ${numberOfPeople} pessoas')}";

  static String m53(emailIDs) => "Compartilhado com ${emailIDs}";

  static String m54(fileType) =>
      "Este(a) ${fileType} será excluído(a) do seu dispositivo.";

  static String m55(fileType) =>
      "Este(a) ${fileType} está tanto no Ente quanto no seu dispositivo.";

  static String m56(fileType) =>
      "Este(a) ${fileType} será excluído(a) do Ente.";

  static String m57(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m58(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} de ${totalAmount} ${totalStorageUnit} usado";

  static String m59(id) =>
      "Seu ${id} já está vinculado a outra conta Ente.\nSe você gostaria de usar seu ${id} com esta conta, por favor contate nosso suporte\'\'";

  static String m60(endDate) => "Sua assinatura será cancelada em ${endDate}";

  static String m61(completed, total) =>
      "${completed}/${total} memórias preservadas";

  static String m62(storageAmountInGB) =>
      "Eles também recebem ${storageAmountInGB} GB";

  static String m63(email) => "Este é o ID de verificação de ${email}";

  static String m64(count) =>
      "${Intl.plural(count, zero: '', one: '1 dia', other: '${count} dias')}";

  static String m65(endDate) => "Válido até ${endDate}";

  static String m66(email) => "Verificar ${email}";

  static String m67(email) => "Enviamos um e-mail à <green>${email}</green>";

  static String m68(count) =>
      "${Intl.plural(count, one: '${count} anos atrás', other: '${count} anos atrás')}";

  static String m69(storageSaved) =>
      "Você liberou ${storageSaved} com sucesso!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Uma nova versão do Ente está disponível."),
        "about": MessageLookupByLibrary.simpleMessage("Sobre"),
        "account": MessageLookupByLibrary.simpleMessage("Conta"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bem-vindo de volta!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Eu entendo que se eu perder minha senha, posso perder meus dados, já que meus dados são <underline>criptografados de ponta a ponta</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessões ativas"),
        "addAName": MessageLookupByLibrary.simpleMessage("Adicione um nome"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Adicionar um novo email"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Adicionar colaborador"),
        "addCollaborators": m0,
        "addFromDevice": MessageLookupByLibrary.simpleMessage(
            "Adicionar a partir do dispositivo"),
        "addItem": m2,
        "addLocation": MessageLookupByLibrary.simpleMessage("Adicionar local"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Adicionar"),
        "addMore": MessageLookupByLibrary.simpleMessage("Adicione mais"),
        "addNew": MessageLookupByLibrary.simpleMessage("Adicionar novo"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Detalhes dos complementos"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Complementos"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Adicionar fotos"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Adicionar selecionado"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Adicionar ao álbum"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Adicionar ao Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Adicionar a álbum oculto"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Adicionar visualizador"),
        "addViewers": m1,
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Adicione suas fotos agora"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Adicionado como"),
        "addedBy": m4,
        "addedSuccessfullyTo": m5,
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
            "Adicionando aos favoritos..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Avançado"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Avançado"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Após 1 dia"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Após 1 hora"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Após 1 mês"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Após 1 semana"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Após 1 ano"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Proprietário"),
        "albumParticipantsCount": m6,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Título do álbum"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Álbum atualizado"),
        "albums": MessageLookupByLibrary.simpleMessage("Álbuns"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Tudo limpo"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
            "Todas as memórias preservadas"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permita que as pessoas com o link também adicionem fotos ao álbum compartilhado."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Permitir adicionar fotos"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Permitir downloads"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Permitir que pessoas adicionem fotos"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Verificar identidade"),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
            "Não reconhecido. Tente novamente."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Biométrica necessária"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Sucesso"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Credenciais do dispositivo necessárias"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Credenciais do dispositivo necessárias"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "A autenticação biométrica não está configurada no seu dispositivo. Vá em \'Configurações > Segurança\' para adicionar autenticação biométrica."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Desktop"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Autenticação necessária"),
        "appVersion": m7,
        "appleId": MessageLookupByLibrary.simpleMessage("ID da Apple"),
        "apply": MessageLookupByLibrary.simpleMessage("Aplicar"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Aplicar código"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Assinatura da AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("Arquivar"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Arquivar álbum"),
        "archiving": MessageLookupByLibrary.simpleMessage("Arquivando..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Tem certeza que deseja sair do plano familiar?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Tem certeza que deseja cancelar?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Tem certeza que deseja trocar de plano?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Tem certeza de que deseja sair?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Você tem certeza que deseja encerrar a sessão?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Tem certeza de que deseja renovar?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Sua assinatura foi cancelada. Gostaria de compartilhar o motivo?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Qual é o principal motivo para você excluir sua conta?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Peça que seus entes queridos compartilhem"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("em um abrigo avançado"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, autentique-se para alterar seu e-mail"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para alterar a configuração da tela de bloqueio"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para alterar seu e-mail"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para alterar sua senha"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, autentique-se para configurar a autenticação de dois fatores"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para iniciar a exclusão de conta"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para ver as sessões ativas"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Autentique-se para visualizar seus arquivos ocultos"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para ver suas memórias"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para visualizar sua chave de recuperação"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Autenticando..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Falha na autenticação. Por favor, tente novamente"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("Autenticação bem-sucedida!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Você verá dispositivos disponíveis para transmitir aqui."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Certifique-se de que as permissões de Rede local estão ativadas para o aplicativo de Fotos Ente, em Configurações."),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Devido a erros técnicos, você foi desconectado. Pedimos desculpas pelo inconveniente."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Pareamento automático"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "O pareamento automático funciona apenas com dispositivos que suportam o Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Disponível"),
        "availableStorageSpace": m8,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Backup de pastas concluído"),
        "backup": MessageLookupByLibrary.simpleMessage("Backup"),
        "backupFailed":
            MessageLookupByLibrary.simpleMessage("Erro ao efetuar o backup"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("Backup usando dados móveis"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Configurações de backup"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Backup de vídeos"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Promoção da Black Friday"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Dados em cache"),
        "calculating": MessageLookupByLibrary.simpleMessage("Calculando..."),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Não é possível enviar para álbuns pertencentes a outros"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Só é possível criar um link para arquivos pertencentes a você"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Só é possível remover arquivos de sua propriedade"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "cancelOtherSubscription": m9,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Cancelar assinatura"),
        "cannotAddMorePhotosAfterBecomingViewer": m10,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Não é possível excluir arquivos compartilhados"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Certifique-se de estar na mesma rede que a TV."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("Falha ao transmitir álbum"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Visite cast.ente.io no dispositivo que você deseja parear.\n\ndigite o código abaixo para reproduzir o álbum em sua TV."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Ponto central"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Mudar e-mail"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Alterar o local dos itens selecionados?"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Mude sua senha"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Alterar senha"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Alterar permissões?"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Verificar por atualizações"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Verifique sua caixa de entrada (e ‘spam’) para concluir a verificação"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Verificar status"),
        "checking": MessageLookupByLibrary.simpleMessage("Verificando..."),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
            "Reivindicar armazenamento gratuito"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Reivindique mais!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Reivindicado"),
        "claimedStorageSoFar": m11,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Limpar Sem Categoria"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Remover todos os arquivos de Não Categorizados que estão presentes em outros álbuns"),
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
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Código copiado para a área de transferência"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Código usado por você"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Crie um link para permitir que as pessoas adicionem e vejam fotos no seu álbum compartilhado sem a necessidade do aplicativo ou uma conta Ente. Ótimo para colecionar fotos de eventos."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Link Colaborativo"),
        "collaborativeLinkCreatedFor": m12,
        "collaborator": MessageLookupByLibrary.simpleMessage("Colaborador"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Os colaboradores podem adicionar fotos e vídeos ao álbum compartilhado."),
        "collageLayout": MessageLookupByLibrary.simpleMessage("Layout"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("Colagem salva na galeria"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Coletar fotos do evento"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Colete fotos"),
        "color": MessageLookupByLibrary.simpleMessage("Cor"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirme"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Você tem certeza de que deseja desativar a autenticação de dois fatores?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Confirmar exclusão da conta"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Sim, desejo excluir permanentemente esta conta e todos os seus dados."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirme sua senha"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("Confirmar mudança de plano"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirme a chave de recuperação"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirme sua chave de recuperação"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Conectar ao dispositivo"),
        "contactFamilyAdmin": m13,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contate o suporte"),
        "contactToManageSubscription": m14,
        "contacts": MessageLookupByLibrary.simpleMessage("Contatos"),
        "contents": MessageLookupByLibrary.simpleMessage("Conteúdos"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuar"),
        "continueOnFreeTrial":
            MessageLookupByLibrary.simpleMessage("Continuar em teste gratuito"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Converter para álbum"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Copiar endereço de e-mail"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copiar link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copie e cole este código\npara seu aplicativo autenticador"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Não foi possível fazer o backup de seus dados.\nTentaremos novamente mais tarde."),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
            "Não foi possível liberar espaço"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Não foi possível atualizar a assinatura"),
        "count": MessageLookupByLibrary.simpleMessage("Contagem"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Relatório de falhas"),
        "create": MessageLookupByLibrary.simpleMessage("Criar"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Criar uma conta"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Pressione e segure para selecionar fotos e clique em + para criar um álbum"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Criar link colaborativo"),
        "createCollage": MessageLookupByLibrary.simpleMessage("Criar colagem"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Criar nova conta"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Criar ou selecionar álbum"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Criar link público"),
        "creatingLink": MessageLookupByLibrary.simpleMessage("Criando link..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Atualização crítica disponível"),
        "crop": MessageLookupByLibrary.simpleMessage("Recortar"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("O uso atual é "),
        "custom": MessageLookupByLibrary.simpleMessage("Personalizado"),
        "customEndpoint": m15,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Escuro"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Hoje"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Ontem"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("Descriptografando..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Descriptografando vídeo..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Arquivos duplicados"),
        "delete": MessageLookupByLibrary.simpleMessage("Excluir"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Excluir conta"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Lamentamos ver você partir. Por favor, compartilhe seus comentários para nos ajudar a melhorar."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Excluir conta permanentemente"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Excluir álbum"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Também excluir as fotos (e vídeos) presentes neste álbum de <bold>todos os</bold> outros álbuns dos quais eles fazem parte?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Isto irá apagar todos os álbuns vazios. Isso é útil quando você deseja reduzir a bagunça na sua lista de álbuns."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Excluir Tudo"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Esta conta está vinculada a outros aplicativos Ente, se você usar algum. Seus dados enviados, em todos os aplicativos Ente, serão agendados para exclusão, e sua conta será excluída permanentemente."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Por favor, envie um e-mail para <warning>account-deletion@ente.io</warning> a partir do seu endereço de e-mail registrado."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Excluir álbuns vazios"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Excluir álbuns vazios?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Excluir de ambos"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Excluir do dispositivo"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Excluir do Ente"),
        "deleteItemCount": m16,
        "deleteLocation": MessageLookupByLibrary.simpleMessage("Excluir Local"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Excluir fotos"),
        "deleteProgress": m17,
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
        "descriptions": MessageLookupByLibrary.simpleMessage("Descrições"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar todos"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Feito para ter longevidade"),
        "details": MessageLookupByLibrary.simpleMessage("Detalhes"),
        "developerSettings": MessageLookupByLibrary.simpleMessage(
            "Configurações de desenvolvedor"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Tem certeza de que deseja modificar as configurações de Desenvolvedor?"),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Insira o código"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Arquivos adicionados a este álbum do dispositivo serão automaticamente enviados para o Ente."),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Desative o bloqueio de tela do dispositivo quando o Ente estiver em primeiro plano e houver um backup em andamento. Isso normalmente não é necessário, mas pode ajudar nos envios grandes e importações iniciais de grandes bibliotecas a serem concluídos mais rapidamente."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Dispositivo não encontrado"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Você sabia?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Desativar bloqueio automático"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Os espectadores ainda podem tirar screenshots ou salvar uma cópia de suas fotos usando ferramentas externas"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Observe"),
        "disableLinkMessage": m18,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Desativar autenticação de dois fatores"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Desativando a autenticação de dois fatores..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Descartar"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut":
            MessageLookupByLibrary.simpleMessage("Não encerrar sessão"),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Fazer isso mais tarde"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Você quer descartar as edições que você fez?"),
        "done": MessageLookupByLibrary.simpleMessage("Pronto"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Dobre seu armazenamento"),
        "download": MessageLookupByLibrary.simpleMessage("Baixar"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Falha no download"),
        "downloading":
            MessageLookupByLibrary.simpleMessage("Fazendo download..."),
        "dropSupportEmail": m19,
        "duplicateFileCountWithStorageSaved": m20,
        "duplicateItemsGroup": m21,
        "edit": MessageLookupByLibrary.simpleMessage("Editar"),
        "editLocation": MessageLookupByLibrary.simpleMessage("Editar local"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Editar local"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Edições salvas"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Edições para local só serão vistas dentro do Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("elegível"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailChangedTo": m22,
        "emailNoEnteAccount": m23,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("Verificação de e-mail"),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("Enviar por email seus logs"),
        "empty": MessageLookupByLibrary.simpleMessage("Vazio"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Esvaziar a lixeira?"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Habilitar mapa"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Isto mostrará suas fotos em um mapa do mundo.\n\nEste mapa é hospedado pelo OpenStreetMap, e os exatos locais de suas fotos nunca são compartilhados.\n\nVocê pode desativar esse recurso a qualquer momento nas Configurações."),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Criptografando backup..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Criptografia"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Chaves de criptografia"),
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
            "O Ente preserva suas memórias, então eles estão sempre disponíveis para você, mesmo se você perder o seu dispositivo."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Sua família também pode ser adicionada ao seu plano."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Digite o nome do álbum"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Coloque o código"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Digite o código fornecido pelo seu amigo para reivindicar o armazenamento gratuito para vocês dois"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Insira o e-mail"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Digite o nome do arquivo"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Insira uma senha nova para criptografar seus dados"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Digite a senha"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Insira a senha para criptografar seus dados"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Inserir nome da pessoa"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
            "Insira o código de referência"),
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
        "error": MessageLookupByLibrary.simpleMessage("Erro"),
        "everywhere":
            MessageLookupByLibrary.simpleMessage("em todos os lugares"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Usuário existente"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Este link expirou. Por favor, selecione um novo tempo de expiração ou desabilite a expiração do link."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Exportar logs"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exportar seus dados"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Reconhecimento facial"),
        "faces": MessageLookupByLibrary.simpleMessage("Rostos"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Falha ao aplicar o código"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Falha ao cancelar"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
            "Falha ao fazer download do vídeo"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Falha ao obter original para edição"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Não foi possível buscar informações do produto. Por favor, tente novamente mais tarde."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Falha ao carregar álbuns"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Falha ao renovar"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Falha ao verificar status do pagamento"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Adicione 5 membros da família ao seu plano existente sem pagar a mais.\n\nCada membro recebe seu próprio espaço privado, e nenhum membro pode ver os arquivos uns dos outros a menos que sejam compartilhados.\n\nPlanos de família estão disponíveis para os clientes que têm uma assinatura do Ente paga.\n\nAssine agora para começar!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Família"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Plano familiar"),
        "faq": MessageLookupByLibrary.simpleMessage("Perguntas frequentes"),
        "faqs": MessageLookupByLibrary.simpleMessage("Perguntas frequentes"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorito"),
        "feedback": MessageLookupByLibrary.simpleMessage("Comentários"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Falha ao salvar o arquivo na galeria"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Adicionar descrição..."),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Vídeo salvo na galeria"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Tipos de arquivo"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Tipos de arquivo e nomes"),
        "filesBackedUpFromDevice": m24,
        "filesBackedUpInAlbum": m25,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Arquivos excluídos"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Arquivos salvos na galeria"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Encontre pessoas rapidamente por nome"),
        "flip": MessageLookupByLibrary.simpleMessage("Inverter"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("para suas memórias"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Esqueceu sua senha"),
        "foundFaces":
            MessageLookupByLibrary.simpleMessage("Rostos encontrados"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Armazenamento gratuito reivindicado"),
        "freeStorageOnReferralSuccess": m26,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Armazenamento livre utilizável"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Teste gratuito"),
        "freeTrialValidTill": m27,
        "freeUpAccessPostDelete": m28,
        "freeUpAmount": m29,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Liberar espaço no dispositivo"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Economize espaço no seu dispositivo limpando arquivos que já foram salvos em backup."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Liberar espaço"),
        "freeUpSpaceSaving": m30,
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Até 1000 memórias mostradas na galeria"),
        "general": MessageLookupByLibrary.simpleMessage("Geral"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Gerando chaves de criptografia..."),
        "genericProgress": m31,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Ir para Configurações"),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("ID da Google Play"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Por favor, permita o acesso a todas as fotos nas configurações do aplicativo"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Conceder permissão"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("Agrupar fotos próximas"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Não rastreamos instalações do aplicativo. Seria útil se você nos contasse onde nos encontrou!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Como você ouviu sobre o Ente? (opcional)"),
        "help": MessageLookupByLibrary.simpleMessage("Ajuda"),
        "hidden": MessageLookupByLibrary.simpleMessage("Oculto"),
        "hide": MessageLookupByLibrary.simpleMessage("Ocultar"),
        "hiding": MessageLookupByLibrary.simpleMessage("Ocultando..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Hospedado na OSM France"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Como funciona"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Por favor, peça-lhes para pressionar longamente o endereço de e-mail na tela de configurações e verifique se os IDs de ambos os dispositivos correspondem."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "A autenticação biométrica não está configurada no seu dispositivo. Por favor, ative o Touch ID ou o Face ID no seu telefone."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "A Autenticação Biométrica está desativada. Por favor, bloqueie e desbloqueie sua tela para ativá-la."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("Tudo bem"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorar"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Alguns arquivos neste álbum são ignorados do envio porque eles tinham sido anteriormente excluídos do Ente."),
        "importing": MessageLookupByLibrary.simpleMessage("Importando...."),
        "incorrectCode":
            MessageLookupByLibrary.simpleMessage("Código incorreto"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Senha incorreta"),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Chave de recuperação incorreta"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "A chave de recuperação que você digitou está incorreta"),
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
            MessageLookupByLibrary.simpleMessage("Endereço de e-mail invalido"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Endpoint inválido"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Desculpe, o endpoint que você inseriu é inválido. Por favor, insira um endpoint válido e tente novamente."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Chave inválida"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "A chave de recuperação que você digitou não é válida. Certifique-se de que contém 24 palavras e verifique a ortografia de cada uma.\n\nSe você inseriu um código de recuperação mais antigo, verifique se ele tem 64 caracteres e verifique cada um deles."),
        "invite": MessageLookupByLibrary.simpleMessage("Convidar"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Convidar para o Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Convide seus amigos"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Convide seus amigos ao Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Parece que algo deu errado. Por favor, tente novamente mais tarde. Se o erro persistir, entre em contato com nossa equipe de suporte."),
        "itemCount": m32,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Os itens mostram o número de dias restantes antes da exclusão permanente"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Os itens selecionados serão removidos deste álbum"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Junte-se ao Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Manter fotos"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Ajude-nos com esta informação"),
        "language": MessageLookupByLibrary.simpleMessage("Idioma"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Última atualização"),
        "leave": MessageLookupByLibrary.simpleMessage("Sair"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Sair do álbum"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("Sair da família"),
        "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Sair do álbum compartilhado?"),
        "left": MessageLookupByLibrary.simpleMessage("Esquerda"),
        "light": MessageLookupByLibrary.simpleMessage("Claro"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Claro"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Link copiado para a área de transferência"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limite do dispositivo"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Ativado"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expirado"),
        "linkExpiresOn": m33,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Expiração do link"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("O link expirou"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Nunca"),
        "livePhotos":
            MessageLookupByLibrary.simpleMessage("Fotos em movimento"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Você pode compartilhar sua assinatura com sua família"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Nós preservamos mais de 30 milhões de memórias até agora"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Mantemos 3 cópias dos seus dados, uma em um abrigo subterrâneo"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Todos os nossos aplicativos são de código aberto"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Nosso código-fonte e criptografia foram auditadas externamente"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Você pode compartilhar links para seus álbuns com seus entes queridos"),
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
            MessageLookupByLibrary.simpleMessage("Carregando suas fotos..."),
        "loadingModel": MessageLookupByLibrary.simpleMessage(
            "Fazendo download de modelos..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galeria local"),
        "location": MessageLookupByLibrary.simpleMessage("Local"),
        "locationName": MessageLookupByLibrary.simpleMessage("Nome do Local"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Uma tag em grupo de todas as fotos que foram tiradas dentro de algum raio de uma foto"),
        "locations": MessageLookupByLibrary.simpleMessage("Locais"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Bloquear"),
        "lockScreenEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Para ativar o bloqueio de tela, por favor ative um método de autenticação nas configurações do sistema do seu dispositivo."),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Tela de bloqueio"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Login"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Desconectando..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessão expirada"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Sua sessão expirou. Por favor, entre novamente."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Ao clicar em login, eu concordo com os <u-terms>termos de serviço</u-terms> e a <u-policy>política de privacidade</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Encerrar sessão"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Isso enviará através dos logs para nos ajudar a depurar o seu problema. Por favor, note que nomes de arquivos serão incluídos para ajudar a rastrear problemas com arquivos específicos."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Pressione e segure um e-mail para verificar a criptografia de ponta a ponta."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Pressione e segure em um item para exibir em tela cheia"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Dispositivo perdido?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Aprendizagem de máquina"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Busca mágica"),
        "manage": MessageLookupByLibrary.simpleMessage("Gerenciar"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Gerenciar o armazenamento do dispositivo"),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Gerenciar Família"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Gerenciar link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Gerenciar"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Gerenciar assinatura"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Parear com o PIN funciona com qualquer tela que você deseja ver o seu álbum ativado."),
        "map": MessageLookupByLibrary.simpleMessage("Mapa"),
        "maps": MessageLookupByLibrary.simpleMessage("Mapas"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m34,
        "merchandise": MessageLookupByLibrary.simpleMessage("Produtos"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Por favor, note que isso resultará em uma largura de banda maior e uso de bateria até que todos os itens sejam indexados."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobile, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderada"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Modifique sua consulta ou tente procurar por"),
        "moments": MessageLookupByLibrary.simpleMessage("Momentos"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensal"),
        "moveItem": m35,
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Mover para álbum"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Mover para álbum oculto"),
        "movedSuccessfullyTo": m36,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Movido para a lixeira"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Enviando arquivos para o álbum..."),
        "name": MessageLookupByLibrary.simpleMessage("Nome"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Não foi possível conectar ao Ente, tente novamente após algum tempo. Se o erro persistir, entre em contato com o suporte."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Não foi possível conectar-se ao Ente, verifique suas configurações de rede e entre em contato com o suporte se o erro persistir."),
        "never": MessageLookupByLibrary.simpleMessage("Nunca"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Novo álbum"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Novo no Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Mais recente"),
        "no": MessageLookupByLibrary.simpleMessage("Não"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Nenhum álbum compartilhado por você ainda"),
        "noDeviceFound": MessageLookupByLibrary.simpleMessage(
            "Nenhum dispositivo encontrado"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Nenhum"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Você não tem nenhum arquivo neste dispositivo que pode ser excluído"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Sem duplicados"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Sem dados EXIF"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Nenhuma foto ou vídeos ocultos"),
        "noImagesWithLocation":
            MessageLookupByLibrary.simpleMessage("Nenhuma imagem com local"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Sem conexão à internet"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "No momento não há backup de fotos sendo feito"),
        "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage(
            "Nenhuma foto encontrada aqui"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Nenhuma chave de recuperação?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Devido à natureza do nosso protocolo de criptografia de ponta a ponta, seus dados não podem ser descriptografados sem sua senha ou chave de recuperação"),
        "noResults": MessageLookupByLibrary.simpleMessage("Nenhum resultado"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Nenhum resultado encontrado"),
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Nada compartilhado com você ainda"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Nada para ver aqui! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notificações"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "onDevice": MessageLookupByLibrary.simpleMessage("No dispositivo"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Em <branding>ente</branding>"),
        "oops": MessageLookupByLibrary.simpleMessage("Opa"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Ops, não foi possível salvar edições"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ops! Algo deu errado"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Abrir Configurações"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Abra o item"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
            "Contribuidores do OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Opcional, tão curta quanto quiser..."),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Ou escolha um existente"),
        "pair": MessageLookupByLibrary.simpleMessage("Parear"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("Parear com PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Pareamento concluído"),
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "A verificação ainda está pendente"),
        "passkey": MessageLookupByLibrary.simpleMessage("Chave de acesso"),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
            "Autenticação via Chave de acesso"),
        "password": MessageLookupByLibrary.simpleMessage("Senha"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Senha alterada com sucesso"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Bloqueio de senha"),
        "passwordStrength": m37,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Nós não salvamos essa senha, se você esquecer <underline> nós não poderemos descriptografar seus dados</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Detalhes de pagamento"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Falha no pagamento"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Infelizmente o seu pagamento falhou. Entre em contato com o suporte e nós ajudaremos você!"),
        "paymentFailedTalkToProvider": m38,
        "pendingItems": MessageLookupByLibrary.simpleMessage("Itens pendentes"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Sincronização pendente"),
        "people": MessageLookupByLibrary.simpleMessage("Pessoas"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("Pessoas que usam seu código"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Todos os itens na lixeira serão excluídos permanentemente\n\nEsta ação não pode ser desfeita"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Excluir permanentemente"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Excluir permanentemente do dispositivo?"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Descrições das fotos"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Tamanho da grade de fotos"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "photos": MessageLookupByLibrary.simpleMessage("Fotos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "As fotos adicionadas por você serão removidas do álbum"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Escolha o ponto central"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Fixar álbum"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Reproduzir álbum na TV"),
        "playStoreFreeTrialValidTill": m39,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Assinatura da PlayStore"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verifique sua conexão com a internet e tente novamente."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, entre em contato com support@ente.io e nós ficaremos felizes em ajudar!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, contate o suporte se o problema persistir"),
        "pleaseEmailUsAt": m40,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
            "Por favor, conceda as permissões"),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
            "Por favor, faça login novamente"),
        "pleaseSendTheLogsTo": m41,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Por favor, tente novamente"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, verifique o código que você inseriu"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Por favor, aguarde..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Por favor, aguarde, excluindo álbum"),
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
            MessageLookupByLibrary.simpleMessage("Política de Privacidade"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Backups privados"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Compartilhamento privado"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Link público criado"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Link público ativado"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Links rápidos"),
        "radius": MessageLookupByLibrary.simpleMessage("Raio"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Abrir ticket"),
        "rateTheApp":
            MessageLookupByLibrary.simpleMessage("Avalie o aplicativo"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Avalie-nos"),
        "rateUsOnStore": m42,
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
            MessageLookupByLibrary.simpleMessage("Redefinir senha"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Indique amigos e 2x seu plano"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "Envie esse código aos seus amigos"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Eles se inscreveram para um plano pago"),
        "referralStep3": m43,
        "referrals": MessageLookupByLibrary.simpleMessage("Referências"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Referências estão atualmente pausadas"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Também vazio \"Excluído Recentemente\" de \"Configurações\" -> \"Armazenamento\" para reivindicar o espaço livre"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Também esvazie sua \"Lixeira\" para reivindicar o espaço liberado"),
        "remoteImages": MessageLookupByLibrary.simpleMessage("Imagens remotas"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Miniaturas remotas"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Vídeos remotos"),
        "remove": MessageLookupByLibrary.simpleMessage("Remover"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Excluir duplicados"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Revise e remova arquivos que sejam duplicatas exatas."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Remover do álbum"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Remover do álbum?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Remover dos favoritos"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Remover link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Remover participante"),
        "removeParticipantBody": m44,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Remover etiqueta da pessoa"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Remover link público"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Alguns dos itens que você está removendo foram adicionados por outras pessoas, e você perderá o acesso a eles"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Excluir?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Removendo dos favoritos..."),
        "rename": MessageLookupByLibrary.simpleMessage("Renomear"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Renomear álbum"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Renomear arquivo"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Renovar assinatura"),
        "renewsOn": m45,
        "reportABug":
            MessageLookupByLibrary.simpleMessage("Reportar um problema"),
        "reportBug":
            MessageLookupByLibrary.simpleMessage("Reportar um problema"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Reenviar e-mail"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Redefinir arquivos ignorados"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Redefinir senha"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Redefinir para o padrão"),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurar"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Restaurar para álbum"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Restaurando arquivos..."),
        "retry": MessageLookupByLibrary.simpleMessage("Tentar novamente"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Por favor, reveja e exclua os itens que você acredita serem duplicados."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Revisar sugestões"),
        "right": MessageLookupByLibrary.simpleMessage("Direita"),
        "rotate": MessageLookupByLibrary.simpleMessage("Girar"),
        "rotateLeft":
            MessageLookupByLibrary.simpleMessage("Girar para a esquerda"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Girar para a direita"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Armazenado com segurança"),
        "save": MessageLookupByLibrary.simpleMessage("Salvar"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Salvar colagem"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Salvar cópia"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Salvar chave"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Salve sua chave de recuperação, caso ainda não o tenha feito"),
        "saving": MessageLookupByLibrary.simpleMessage("Salvando..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Salvando edições..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Escanear código"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Escaneie este código de barras com\nseu aplicativo autenticador"),
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
            "Pessoas serão exibidas aqui uma vez que a indexação é feita"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Tipos de arquivo e nomes"),
        "searchHint1": MessageLookupByLibrary.simpleMessage(
            "Rápido, pesquisa no dispositivo"),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("Datas das fotos, descrições"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Álbuns, nomes de arquivos e tipos"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Local"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Em breve: Rostos e busca mágica ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Fotos de grupo que estão sendo tiradas em algum raio da foto"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Convide pessoas e você verá todas as fotos compartilhadas por elas aqui"),
        "searchResultCount": m46,
        "security": MessageLookupByLibrary.simpleMessage("Segurança"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Selecionar um local"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Selecione um local primeiro"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Selecionar álbum"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Selecionar tudo"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Selecione pastas para backup"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Selecionar itens para adicionar"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Selecionar Idioma"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Selecionar mais fotos"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Selecione o motivo"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Selecione seu plano"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Os arquivos selecionados não estão no Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "As pastas selecionadas serão criptografadas e armazenadas em backup"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Os itens selecionados serão excluídos de todos os álbuns e movidos para a lixeira."),
        "selectedPhotos": m47,
        "selectedPhotosWithYours": m48,
        "send": MessageLookupByLibrary.simpleMessage("Enviar"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Enviar e-mail"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Enviar convite"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Enviar link"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Servidor endpoint"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessão expirada"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Defina uma senha"),
        "setAs": MessageLookupByLibrary.simpleMessage("Definir como"),
        "setCover": MessageLookupByLibrary.simpleMessage("Definir capa"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Aplicar"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Definir senha"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Definir raio"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configuração concluída"),
        "share": MessageLookupByLibrary.simpleMessage("Compartilhar"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Compartilhar link"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Abra um álbum e toque no botão compartilhar no canto superior direito para compartilhar."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Compartilhar um álbum agora"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Compartilhar link"),
        "shareMyVerificationID": m49,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Compartilhar apenas com as pessoas que você quiser"),
        "shareTextConfirmOthersVerificationID": m50,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Baixe o Ente para que possamos compartilhar facilmente fotos e vídeos de qualidade original\n\nhttps://ente.io"),
        "shareTextReferralCode": m51,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Compartilhar com usuários não-Ente"),
        "shareWithPeopleSectionTitle": m52,
        "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
            "Compartilhar seu primeiro álbum"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Criar álbuns compartilhados e colaborativos com outros usuários Ente, incluindo usuários em planos gratuitos."),
        "sharedByMe":
            MessageLookupByLibrary.simpleMessage("Compartilhada por mim"),
        "sharedByYou":
            MessageLookupByLibrary.simpleMessage("Compartilhado por você"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Novas fotos compartilhadas"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Receber notificações quando alguém adicionar uma foto em um álbum compartilhado que você faz parte"),
        "sharedWith": m53,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Compartilhado comigo"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Compartilhado com você"),
        "sharing": MessageLookupByLibrary.simpleMessage("Compartilhando..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Mostrar memórias"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Encerrar sessão em outros dispositivos"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Se você acha que alguém pode saber sua senha, você pode forçar todos os outros dispositivos que estão com sua conta a desconectar."),
        "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Encerrar sessão em outros dispositivos"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Eu concordo com os <u-terms>termos de serviço</u-terms> e a <u-policy>política de privacidade</u-policy>"),
        "singleFileDeleteFromDevice": m54,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Será excluído de todos os álbuns."),
        "singleFileInBothLocalAndRemote": m55,
        "singleFileInRemoteOnly": m56,
        "skip": MessageLookupByLibrary.simpleMessage("Pular"),
        "social": MessageLookupByLibrary.simpleMessage("Redes sociais"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Alguns itens estão tanto no Ente quanto no seu dispositivo."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Alguns dos arquivos que você está tentando excluir só estão disponíveis no seu dispositivo e não podem ser recuperados se forem excluídos"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Alguém compartilhando álbuns com você deve ver o mesmo ID no dispositivo."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Algo deu errado"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Algo deu errado. Por favor, tente outra vez"),
        "sorry": MessageLookupByLibrary.simpleMessage("Desculpe"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Desculpe, não foi possível adicionar aos favoritos!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Desculpe, não foi possível remover dos favoritos!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Desculpe, o código que você inseriu está incorreto"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Desculpe, não foi possível gerar chaves seguras neste dispositivo.\n\npor favor, faça o login com um dispositivo diferente."),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Ordenar por"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Mais recentes primeiro"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Mais antigos primeiro"),
        "sparkleSuccess":
            MessageLookupByLibrary.simpleMessage("✨ Bem-sucedido"),
        "startBackup": MessageLookupByLibrary.simpleMessage("Iniciar backup"),
        "status": MessageLookupByLibrary.simpleMessage("Estado"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Você quer parar a transmissão?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Parar transmissão"),
        "storage": MessageLookupByLibrary.simpleMessage("Armazenamento"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Família"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Você"),
        "storageInGB": m57,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
            "Limite de armazenamento excedido"),
        "storageUsageInfo": m58,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Forte"),
        "subAlreadyLinkedErrMessage": m59,
        "subWillBeCancelledOn": m60,
        "subscribe": MessageLookupByLibrary.simpleMessage("Assinar"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Parece que sua assinatura expirou. Por favor inscreva-se para ativar o compartilhamento."),
        "subscription": MessageLookupByLibrary.simpleMessage("Assinatura"),
        "success": MessageLookupByLibrary.simpleMessage("Bem-sucedido"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Arquivado com sucesso"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Ocultado com sucesso"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Desarquivado com sucesso"),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("Desocultado com sucesso"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Sugerir recurso"),
        "support": MessageLookupByLibrary.simpleMessage("Suporte"),
        "syncProgress": m61,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Sincronização interrompida"),
        "syncing": MessageLookupByLibrary.simpleMessage("Sincronizando..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistema"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("toque para copiar"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Toque para inserir código"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Parece que algo deu errado. Por favor, tente novamente mais tarde. Se o erro persistir, entre em contato com nossa equipe de suporte."),
        "terminate": MessageLookupByLibrary.simpleMessage("Encerrar"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Encerrar sessão?"),
        "terms": MessageLookupByLibrary.simpleMessage("Termos"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Termos"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Obrigado"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("Obrigado por assinar!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Não foi possível concluir o download"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "A chave de recuperação inserida está incorreta"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Estes itens serão excluídos do seu dispositivo."),
        "theyAlsoGetXGb": m62,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Eles(a) serão excluídos(as) de todos os álbuns."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Esta ação não pode ser desfeita"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Este álbum já tem um link colaborativo"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Isso pode ser usado para recuperar sua conta se você perder seu segundo fator"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Este aparelho"),
        "thisEmailIsAlreadyInUse":
            MessageLookupByLibrary.simpleMessage("Este e-mail já está em uso"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Esta imagem não tem dados exif"),
        "thisIsPersonVerificationId": m63,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Este é o seu ID de verificação"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Isso fará com que você saia do seguinte dispositivo:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Isso fará com que você saia deste dispositivo!"),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Para ocultar uma foto ou vídeo"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Para redefinir a sua senha, por favor verifique o seu email primeiro."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Logs de hoje"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Tamanho total"),
        "trash": MessageLookupByLibrary.simpleMessage("Lixeira"),
        "trashDaysLeft": m64,
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
                "Autenticação de dois fatores redefinida com sucesso"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Configuração de dois fatores"),
        "unarchive": MessageLookupByLibrary.simpleMessage("Desarquivar"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Desarquivar álbum"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("Desarquivando..."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Sem categoria"),
        "unhide": MessageLookupByLibrary.simpleMessage("Reexibir"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Reexibir para o álbum"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Reexibindo..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Reexibindo arquivos para o álbum"),
        "unlock": MessageLookupByLibrary.simpleMessage("Desbloquear"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Desafixar álbum"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar tudo"),
        "update": MessageLookupByLibrary.simpleMessage("Atualização"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Atualização disponível"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Atualizando seleção de pasta..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Aprimorar"),
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Enviando arquivos para o álbum..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Até 50% de desconto, até 4 de dezembro."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Armazenamento utilizável é limitado pelo seu plano atual. O armazenamento reivindicado em excesso se tornará utilizável automaticamente quando você fizer a melhoria do seu plano."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Usar links públicos para pessoas que não estão no Ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Usar chave de recuperação"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Utilizar foto selecionada"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Espaço em uso"),
        "validTill": m65,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Falha na verificação, por favor, tente novamente"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de Verificação"),
        "verify": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Verificar e-mail"),
        "verifyEmailID": m66,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Verificar chave de acesso"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verificar senha"),
        "verifying": MessageLookupByLibrary.simpleMessage("Verificando..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verificando chave de recuperação..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vídeo"),
        "videos": MessageLookupByLibrary.simpleMessage("Vídeos"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Ver sessões ativas"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Ver complementos"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Ver tudo"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Ver todos os dados EXIF"),
        "viewLargeFiles":
            MessageLookupByLibrary.simpleMessage("Arquivos grandes"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Ver arquivos que estão consumindo mais espaço de armazenamento"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Ver logs"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ver chave de recuperação"),
        "viewer": MessageLookupByLibrary.simpleMessage("Visualizador"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Por favor visite web.ente.io para gerenciar sua assinatura"),
        "waitingForVerification": MessageLookupByLibrary.simpleMessage(
            "Esperando por verificação..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Esperando por Wi-Fi..."),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Somos de código aberto!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Não suportamos a edição de fotos e álbuns que você ainda não possui"),
        "weHaveSendEmailTo": m67,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Fraca"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Bem-vindo de volta!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("O que há de novo"),
        "yearly": MessageLookupByLibrary.simpleMessage("Anual"),
        "yearsAgo": m68,
        "yes": MessageLookupByLibrary.simpleMessage("Sim"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Sim, cancelar"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Sim, converter para visualizador"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Sim, excluir"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Sim, descartar alterações"),
        "yesLogout":
            MessageLookupByLibrary.simpleMessage("Sim, encerrar sessão"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Sim, excluir"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Sim, Renovar"),
        "you": MessageLookupByLibrary.simpleMessage("Você"),
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
            "Você está em um plano familiar!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Você está usando a versão mais recente"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Você pode duplicar seu armazenamento no máximo"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Você pode gerenciar seus links na aba de compartilhamento."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Você pode tentar procurar uma consulta diferente."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Você não pode fazer o downgrade para este plano"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Você não pode compartilhar consigo mesmo"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Você não tem nenhum item arquivado."),
        "youHaveSuccessfullyFreedUp": m69,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Sua conta foi excluída"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Seu mapa"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Seu plano foi reduzido com sucesso"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Seu plano foi aumentado com sucesso"),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
            "Sua compra foi efetuada com sucesso"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Seus detalhes de armazenamento não puderam ser obtidos"),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("A sua assinatura expirou"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Sua assinatura foi atualizada com sucesso"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "O código de verificação expirou"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Você não tem arquivos duplicados que possam ser limpos"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Você não tem arquivos neste álbum que possam ser excluídos"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
            "Diminuir o zoom para ver fotos")
      };
}
