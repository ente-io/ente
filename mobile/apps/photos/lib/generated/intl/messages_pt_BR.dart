// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a pt_BR locale. All the
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
  String get localeName => 'pt_BR';

  static String m0(title) => "${title} (Eu)";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Adicionar colaborador', one: 'Adicionar colaborador', other: 'Adicionar colaboradores')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Adicionar item', other: 'Adicionar itens')}";

  static String m3(storageAmount, endDate) =>
      "Seu complemento ${storageAmount} é válido até ${endDate}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Adicionar visualizador', one: 'Adicionar visualizador', other: 'Adicionar vizualizadores')}";

  static String m5(emailOrName) => "Adicionado por ${emailOrName}";

  static String m6(albumName) => "Adicionado com sucesso a  ${albumName}";

  static String m7(name) => "Admirando ${name}";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Nenhum participante', one: '1 participante', other: '${count} participantes')}";

  static String m9(versionValue) => "Versão: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} livre";

  static String m11(name) => "Vistas bonitas com ${name}";

  static String m12(paymentProvider) =>
      "Primeiramente cancele sua assinatura existente do ${paymentProvider}";

  static String m13(user) =>
      "${user} Não poderá adicionar mais fotos a este álbum\n\nEles ainda conseguirão remover fotos existentes adicionadas por eles";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Sua família reinvidicou ${storageAmountInGb} GB até então',
            'false': 'Você reinvindicou ${storageAmountInGb} GB até então',
            'other': 'Você reinvindicou ${storageAmountInGb} GB até então!',
          })}";

  static String m15(albumName) => "Link colaborativo criado para ${albumName}";

  static String m16(count) =>
      "${Intl.plural(count, zero: 'Adicionado 0 colaboradores', one: 'Adicionado 1 colaborador', other: 'Adicionado ${count} colaboradores')}";

  static String m17(email, numOfDays) =>
      "Você está prestes a adicionar ${email} como contato confiável. Eles poderão recuperar sua conta se você estiver ausente por ${numOfDays} dias.";

  static String m18(familyAdminEmail) =>
      "Entre em contato com <green>${familyAdminEmail}</green> para gerenciar sua assinatura";

  static String m19(provider) =>
      "Entre em contato conosco em support@ente.io para gerenciar sua assinatura ${provider}.";

  static String m20(endpoint) => "Conectado à ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Excluir ${count} item', other: 'Excluir ${count} itens')}";

  static String m22(count) =>
      "E também excluir todas as fotos (e vídeos) presente dentro desses ${count} álbuns e de <bold>todos</bold> os álbuns que eles fazem parte?";

  static String m23(currentlyDeleting, totalCount) =>
      "Excluindo ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "Isso removerá o link público para acessar \"${albumName}\".";

  static String m25(supportEmail) =>
      "Envie um e-mail para ${supportEmail} a partir do e-mail registrado";

  static String m26(count, storageSaved) =>
      "Você limpou ${Intl.plural(count, one: '${count} arquivo duplicado', other: '${count} arquivos duplicados')}, salvando (${storageSaved}!)";

  static String m27(count, formattedSize) =>
      "${count} arquivos, ${formattedSize} cada";

  static String m28(name) => "Este e-mail já está vinculado a ${name}.";

  static String m29(newEmail) => "E-mail alterado para ${newEmail}";

  static String m30(email) => "${email} não possui uma conta Ente.";

  static String m31(email) =>
      "${email} não tem uma conta Ente.\n\nEnvie-os um convite para compartilhar fotos.";

  static String m32(name) => "Abraçando ${name}";

  static String m33(text) => "Fotos adicionais encontradas para ${text}";

  static String m34(name) => "Tendo banquete com ${name}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 arquivo', other: '${formattedNumber} arquivos')} deste dispositivo foi(ram) salvos em segurança";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 arquivo', other: '${formattedNumber} arquivos')} deste álbum foi(ram) salvo(s) em segurança";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB toda vez que alguém utilizar seu código num plano pago";

  static String m38(endDate) => "A avaliação grátis acaba em ${endDate}";

  static String m39(count) =>
      "Você ainda pode acessá${Intl.plural(count, one: '-lo', other: '-los')} no Ente se você tiver uma assinatura ativa";

  static String m40(sizeInMBorGB) => "Liberar ${sizeInMBorGB}";

  static String m41(count, formattedSize) =>
      "${Intl.plural(count, one: 'Ele pode excluído do dispositivo para liberar ${formattedSize}', other: 'Eles podem ser excluídos do dispositivo para liberar ${formattedSize}')}";

  static String m42(currentlyProcessing, totalCount) =>
      "Processando ${currentlyProcessing} / ${totalCount}";

  static String m43(name) => "Caminhando com ${name}";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} item', other: '${count} itens')}";

  static String m45(name) => "Últimos momentos com ${name}";

  static String m46(email) =>
      "${email} convidou você para ser um contato confiável";

  static String m47(expiryTime) => "O link expirará em ${expiryTime}";

  static String m48(email) => "Vincular pessoa a ${email}";

  static String m49(personName, email) =>
      "Isso vinculará ${personName} a ${email}";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'sem memórias', one: '${formattedCount} memória', other: '${formattedCount} memórias')}";

  static String m51(count) =>
      "${Intl.plural(count, one: 'Mover item', other: 'Mover itens')}";

  static String m52(albumName) => "Movido com sucesso para ${albumName}";

  static String m53(personName) => "Sem sugestões para ${personName}";

  static String m54(name) => "Não é ${name}?";

  static String m55(familyAdminEmail) =>
      "Entre em contato com ${familyAdminEmail} para alterar o seu código.";

  static String m56(name) => "Festejando com ${name}";

  static String m57(passwordStrengthValue) =>
      "Força da senha: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Fale com o suporte ${providerName} se você foi cobrado";

  static String m59(name, age) => "${name} tem ${age} anos!";

  static String m60(name, age) => "${name} terá ${age} em breve";

  static String m61(count) =>
      "${Intl.plural(count, zero: 'Sem fotos', one: '1 foto', other: '${count} fotos')}";

  static String m62(count) =>
      "${Intl.plural(count, zero: '0 fotos', one: '1 foto', other: '${count} fotos')}";

  static String m63(endDate) =>
      "Avaliação grátis válida até ${endDate}.\nVocê pode alterar para um plano pago depois.";

  static String m64(toEmail) => "Envie-nos um e-mail para ${toEmail}";

  static String m65(toEmail) => "Envie os registros para \n${toEmail}";

  static String m66(name) => "Fazendo pose com ${name}";

  static String m67(folderName) => "Processando ${folderName}...";

  static String m68(storeName) => "Avalie-nos no ${storeName}";

  static String m69(name) => "Atribuído a ${name}";

  static String m70(days, email) =>
      "Você poderá acessar a conta após ${days} dias.  Uma notificação será enviada para ${email}.";

  static String m71(email) =>
      "Você pode recuperar a conta com e-mail ${email} por definir uma nova senha.";

  static String m72(email) => "${email} está tentando recuperar sua conta.";

  static String m73(storageInGB) => "3. Ambos ganham ${storageInGB} GB* grátis";

  static String m74(userEmail) =>
      "${userEmail} será removido do álbum compartilhado\n\nQualquer foto adicionada por ele será removida.";

  static String m75(endDate) => "Renovação de assinatura em ${endDate}";

  static String m76(name) => "Viajando de carro com ${name}";

  static String m77(count) =>
      "${Intl.plural(count, one: '${count} resultado encontrado', other: '${count} resultados encontrados')}";

  static String m78(snapshotLength, searchLength) =>
      "Incompatibilidade de comprimento de seções: ${snapshotLength} != ${searchLength}";

  static String m79(count) => "${count} selecionado(s)";

  static String m80(count) => "${count} selecionado(s)";

  static String m81(count, yourCount) =>
      "${count} selecionado(s) (${yourCount} seus)";

  static String m82(name) => "Tirando selfies com ${name}";

  static String m83(verificationID) =>
      "Aqui está meu ID de verificação para o ente.io: ${verificationID}";

  static String m84(verificationID) =>
      "Ei, você pode confirmar se este ID de verificação do ente.io é seu?: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Código de referência Ente: ${referralCode} \n\nAplique-o em Opções → Geral → Referências para obter ${referralStorageInGB} GB grátis após a inscrição num plano pago\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Compartilhe com pessoas específicas', one: 'Compartilhado com 1 pessoa', other: 'Compartilhado com ${numberOfPeople} pessoas')}";

  static String m87(emailIDs) => "Compartilhado com ${emailIDs}";

  static String m88(fileType) =>
      "Este ${fileType} será excluído do dispositivo.";

  static String m89(fileType) =>
      "Este ${fileType} está no Ente e em seu dispositivo.";

  static String m90(fileType) => "Este ${fileType} será excluído do Ente.";

  static String m91(name) => "Jogando esportes com ${name}";

  static String m92(name) => "Destacar ${name}";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m94(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} de ${totalAmount} ${totalStorageUnit} usado";

  static String m95(id) =>
      "Seu ${id} já está vinculado a outra conta Ente. Se você gostaria de usar seu ${id} com esta conta, entre em contato conosco\"";

  static String m96(endDate) => "Sua assinatura será cancelada em ${endDate}";

  static String m97(completed, total) =>
      "${completed}/${total} memórias preservadas";

  static String m98(ignoreReason) =>
      "Toque para enviar, atualmente o envio é ignorado devido a ${ignoreReason}";

  static String m99(storageAmountInGB) =>
      "Eles também recebem ${storageAmountInGB} GB";

  static String m100(email) => "Este é o ID de verificação de ${email}";

  static String m101(count) =>
      "${Intl.plural(count, one: 'Esta semana, ${count} ano atrás', other: 'Esta semana, ${count} anos atrás')}";

  static String m102(dateFormat) => "${dateFormat} com o passar dos anos";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Em breve', one: '1 dia', other: '${count} dias')}";

  static String m104(year) => "Viajem em ${year}";

  static String m105(location) => "Viajem à ${location}";

  static String m106(email) =>
      "Você foi convidado para ser um contato legado por ${email}.";

  static String m107(galleryType) =>
      "O tipo de galeria ${galleryType} não é suportado para renomear";

  static String m108(ignoreReason) =>
      "O envio é ignorado devido a ${ignoreReason}";

  static String m109(count) => "Preservando ${count} memórias...";

  static String m110(endDate) => "Válido até ${endDate}";

  static String m111(email) => "Verificar ${email}";

  static String m112(name) => "Visualizar ${name} para desvincular";

  static String m113(count) =>
      "${Intl.plural(count, zero: 'Adicionado 0 vizualizadores', one: 'Adicionado 1 visualizador', other: 'Adicionado ${count} visualizadores')}";

  static String m114(email) => "Enviamos um e-mail à <green>${email}</green>";

  static String m115(name) => "Deseje um feliz aniversário a ${name}! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, one: '${count} ano atrás', other: '${count} anos atrás')}";

  static String m117(name) => "Você e ${name}";

  static String m118(storageSaved) =>
      "Você liberou ${storageSaved} com sucesso!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Uma nova versão do Ente está disponível."),
        "about": MessageLookupByLibrary.simpleMessage("Sobre"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Aceitar convite"),
        "account": MessageLookupByLibrary.simpleMessage("Conta"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "A conta já está configurada."),
        "accountOwnerPersonAppbarTitle": m0,
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bem-vindo(a) de volta!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Eu entendo que se eu perder minha senha, posso perder meus dados, já que meus dados são <underline>criptografados de ponta a ponta</underline>."),
        "actionNotSupportedOnFavouritesAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Ação não suportada em álbum favorito"),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessões ativas"),
        "add": MessageLookupByLibrary.simpleMessage("Adicionar"),
        "addAName": MessageLookupByLibrary.simpleMessage("Adicione um nome"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Adicionar um novo e-mail"),
        "addAlbumWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Adicione um widget de álbum a sua tela inicial e volte aqui para personalizar."),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Adicionar colaborador"),
        "addCollaborators": m1,
        "addFiles": MessageLookupByLibrary.simpleMessage("Adicionar arquivos"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Adicionar do dispositivo"),
        "addItem": m2,
        "addLocation":
            MessageLookupByLibrary.simpleMessage("Adicionar localização"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Adicionar"),
        "addMemoriesWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Adicione um widget de memória a sua tela inicial e volte aqui para personalizar."),
        "addMore": MessageLookupByLibrary.simpleMessage("Adicionar mais"),
        "addName": MessageLookupByLibrary.simpleMessage("Adicionar pessoa"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Adicionar nome ou juntar"),
        "addNew": MessageLookupByLibrary.simpleMessage("Adicionar novo"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Adicionar nova pessoa"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Detalhes dos complementos"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Complementos"),
        "addParticipants":
            MessageLookupByLibrary.simpleMessage("Adicionar participante"),
        "addPeopleWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Adicione um widget de pessoas a sua tela inicial e volte aqui para personalizar."),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Adicionar fotos"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Adicionar selecionado"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Adicionar ao álbum"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Adicionar ao Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Adicionar ao álbum oculto"),
        "addTrustedContact":
            MessageLookupByLibrary.simpleMessage("Adicionar contato confiável"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Adicionar visualizador"),
        "addViewers": m4,
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Adicione suas fotos agora"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Adicionado como"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
            "Adicionando aos favoritos..."),
        "admiringThem": m7,
        "advanced": MessageLookupByLibrary.simpleMessage("Avançado"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Avançado"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Após 1 dia"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Após 1 hora"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Após 1 mês"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Após 1 semana"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Após 1 ano"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Proprietário"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Título do álbum"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Álbum atualizado"),
        "albums": MessageLookupByLibrary.simpleMessage("Álbuns"),
        "albumsWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Selecione os álbuns que deseje vê-los na sua tela inicial."),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Tudo limpo"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
            "Todas as memórias preservadas"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Todos os agrupamentos dessa pessoa serão redefinidos, e você perderá todas as sugestões feitas por essa pessoa."),
        "allUnnamedGroupsWillBeMergedIntoTheSelectedPerson":
            MessageLookupByLibrary.simpleMessage(
                "Todos os grupos sem nome serão mesclados numa pessoa selecionada. Isso ainda pode ser desfeito no histórico de sugestões da pessoa."),
        "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
            "Este é o primeiro do grupo. As outras fotos selecionadas serão automaticamente alteradas para esta nova data"),
        "allow": MessageLookupByLibrary.simpleMessage("Permitir"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permitir que as pessoas com link também adicionem fotos ao álbum compartilhado."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Permitir adicionar fotos"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "Permitir aplicativo abrir links de álbum compartilhado"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Permitir downloads"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Permitir que pessoas adicionem fotos"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Permita o acesso a suas fotos nas Opções para que Ente exiba e salva em segurança sua fototeca."),
        "allowPermTitle":
            MessageLookupByLibrary.simpleMessage("Permita acesso às Fotos"),
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
            MessageLookupByLibrary.simpleMessage("Credenciais necessários"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage("Credenciais necessários"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "A autenticação biométrica não está definida no dispositivo. Vá em \'Opções > Segurança\' para adicionar a autenticação biométrica."),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
            "Android, iOS, Web, Computador"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Autenticação necessária"),
        "appIcon": MessageLookupByLibrary.simpleMessage("Ícone do aplicativo"),
        "appLock":
            MessageLookupByLibrary.simpleMessage("Bloqueio do aplicativo"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Escolha entre a tela de bloqueio padrão do seu dispositivo e uma tela de bloqueio personalizada com PIN ou senha."),
        "appVersion": m9,
        "appleId": MessageLookupByLibrary.simpleMessage("ID da Apple"),
        "apply": MessageLookupByLibrary.simpleMessage("Aplicar"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Aplicar código"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Assinatura da AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("Arquivo"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Arquivar álbum"),
        "archiving": MessageLookupByLibrary.simpleMessage("Arquivando..."),
        "areThey": MessageLookupByLibrary.simpleMessage("Eles são "),
        "areYouSureRemoveThisFaceFromPerson":
            MessageLookupByLibrary.simpleMessage(
                "Deseja mesmo remover o rosto desta pessoa?"),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Você tem certeza que queira sair do plano familiar?"),
        "areYouSureYouWantToCancel":
            MessageLookupByLibrary.simpleMessage("Deseja cancelar?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage("Deseja trocar de plano?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Tem certeza de que queira sair?"),
        "areYouSureYouWantToIgnoreThesePersons":
            MessageLookupByLibrary.simpleMessage(
                "Você deseja mesmo ignorar estas pessoas?"),
        "areYouSureYouWantToIgnoreThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Você deseja mesmo ignorar esta pessoa?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Você tem certeza que quer encerrar sessão?"),
        "areYouSureYouWantToMergeThem": MessageLookupByLibrary.simpleMessage(
            "Você desejar mesmo mesclá-los?"),
        "areYouSureYouWantToRenew":
            MessageLookupByLibrary.simpleMessage("Deseja renovar?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Deseja redefinir esta pessoa?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Sua assinatura foi cancelada. Deseja compartilhar o motivo?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Por que você quer excluir sua conta?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Peça que seus entes queridos compartilhem"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("em um abrigo avançado"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Autentique-se para alterar o e-mail de verificação"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Autentique para alterar a configuração da tela de bloqueio"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Por favor, autentique-se para alterar o seu e-mail"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Autentique para alterar sua senha"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Autentique para configurar a autenticação de dois fatores"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Autentique para iniciar a exclusão de conta"),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Autentique-se para gerenciar seus contatos confiáveis"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Autentique-se para ver sua chave de acesso"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Autentique-se para ver seus arquivos excluídos"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Autentique para ver as sessões ativas"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Autentique-se para visualizar seus arquivos ocultos"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Autentique-se para ver suas memórias"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Autentique para ver sua chave de recuperação"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Autenticando..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Falha na autenticação. Tente novamente"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("Autenticado com sucesso!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Você verá dispositivos de transmissão disponível aqui."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Certifique-se que as permissões da internet local estejam ligadas para o Ente Photos App, em opções."),
        "autoLock": MessageLookupByLibrary.simpleMessage("Bloqueio automático"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Tempo após o qual o aplicativo bloqueia após ser colocado em segundo plano"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Devido ao ocorrido de erros técnicos, você foi desconectado. Pedimos desculpas pela inconveniência."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Pareamento automático"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "O pareamento automático só funciona com dispositivos que suportam o Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Disponível"),
        "availableStorageSpace": m10,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Pastas salvas em segurança"),
        "backgroundWithThem": m11,
        "backup": MessageLookupByLibrary.simpleMessage("Salvar em segurança"),
        "backupFailed": MessageLookupByLibrary.simpleMessage(
            "Falhou ao salvar em segurança"),
        "backupFile":
            MessageLookupByLibrary.simpleMessage("Salvar arquivo em segurança"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Salvar fotos com dados móveis"),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
            "Ajustes de salvar em segurança"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("Estado das mídias salvas"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Os itens salvos em segurança aparecerão aqui"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Salvar vídeos em segurança"),
        "beach": MessageLookupByLibrary.simpleMessage("Areia e o mar"),
        "birthday": MessageLookupByLibrary.simpleMessage("Aniversário"),
        "birthdayNotifications":
            MessageLookupByLibrary.simpleMessage("Notificações de aniversário"),
        "birthdays": MessageLookupByLibrary.simpleMessage("Aniversários"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Promoção Black Friday"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cLDesc1": MessageLookupByLibrary.simpleMessage(
            "De volta na transmissão de vídeo beta, e trabalhando em envios e downloads retomáveis, nós aumentamos o limite de envio de arquivos para 10 GB. Isso está disponível em ambos a versão móvel e a versão para desktop."),
        "cLDesc2": MessageLookupByLibrary.simpleMessage(
            "Envios de fundo agora são suportados no iOS também, para assemelhar-se aos dispositivos Android. Não precisa abrir o aplicativo para salvar em segurança as fotos e vídeos mais recentes."),
        "cLDesc3": MessageLookupByLibrary.simpleMessage(
            "Fizemos melhorias significantes para a experiência de memórias, incluindo reprodução automática, deslizar para a próxima memória e mais."),
        "cLDesc4": MessageLookupByLibrary.simpleMessage(
            "Ao lado de outras melhorias, agora ficou mais fácil para detectar rostos, fornecer comentários em rostos similares, e adicionar/remover rostos de uma foto."),
        "cLDesc5": MessageLookupByLibrary.simpleMessage(
            "Você receberá uma notificação opcional para todos os aniversários salvos no Ente, além de uma coleção de melhores fotos."),
        "cLDesc6": MessageLookupByLibrary.simpleMessage(
            "Nada de esperar os envios/downloads terminarem para fechar o aplicativo. Todos os envios e downloads agora possuem a habilidade de ser pausado na metade do processo, e retomar de onde você parou."),
        "cLTitle1": MessageLookupByLibrary.simpleMessage(
            "Enviando arquivos de vídeo grandes"),
        "cLTitle2": MessageLookupByLibrary.simpleMessage("Envio de fundo"),
        "cLTitle3":
            MessageLookupByLibrary.simpleMessage("Reproduzir memórias auto."),
        "cLTitle4": MessageLookupByLibrary.simpleMessage(
            "Reconhecimento Facial Melhorado"),
        "cLTitle5":
            MessageLookupByLibrary.simpleMessage("Notificações de aniversário"),
        "cLTitle6": MessageLookupByLibrary.simpleMessage(
            "Envios e downloads retomáveis"),
        "cachedData":
            MessageLookupByLibrary.simpleMessage("Dados armazenados em cache"),
        "calculating": MessageLookupByLibrary.simpleMessage("Calculando..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Desculpe, este álbum não pode ser aberto no aplicativo."),
        "canNotOpenTitle":
            MessageLookupByLibrary.simpleMessage("Não pôde abrir este álbum"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Não é possível enviar para álbuns pertencentes a outros"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Só é possível criar um link para arquivos pertencentes a você"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Só pode remover arquivos de sua propriedade"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Cancelar recuperação"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "Deseja mesmo cancelar a recuperação de conta?"),
        "cancelOtherSubscription": m12,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Cancelar assinatura"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Não é possível excluir arquivos compartilhados"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Transferir álbum"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Certifique-se de estar na mesma internet que a TV."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("Falhou ao transmitir álbum"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Acesse cast.ente.io no dispositivo desejado para parear.\n\nInsira o código abaixo para reproduzir o álbum na sua TV."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Ponto central"),
        "change": MessageLookupByLibrary.simpleMessage("Alterar"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Alterar e-mail"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Alterar a localização dos itens selecionados?"),
        "changePassword": MessageLookupByLibrary.simpleMessage("Alterar senha"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Alterar senha"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Alterar permissões?"),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
            "Alterar código de referência"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Buscar atualizações"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Verifique sua caixa de entrada (e spam) para concluir a verificação"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Verificar estado"),
        "checking": MessageLookupByLibrary.simpleMessage("Verificando..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Verificando modelos..."),
        "city": MessageLookupByLibrary.simpleMessage("Na cidade"),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Reivindique armaz. grátis"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Reivindique mais!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Reivindicado"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Limpar não categorizado"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Remover todos os arquivos não categorizados que estão presentes em outros álbuns"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Limpar cache"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Limpar índices"),
        "click": MessageLookupByLibrary.simpleMessage("• Clique"),
        "clickOnTheOverflowMenu":
            MessageLookupByLibrary.simpleMessage("• Clique no menu adicional"),
        "clickToInstallOurBestVersionYet": MessageLookupByLibrary.simpleMessage(
            "Clique para instalar a nossa melhor versão até então"),
        "close": MessageLookupByLibrary.simpleMessage("Fechar"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
            "Agrupar por tempo de captura"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Agrupar por nome do arquivo"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Progresso de agrupamento"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Código aplicado"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Desculpe, você atingiu o limite de mudanças de código."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Código copiado para a área de transferência"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Código usado por você"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Crie um link para permitir que as pessoas adicionem e vejam fotos no seu álbum compartilhado sem a necessidade do aplicativo ou uma conta Ente. Ótimo para colecionar fotos de eventos."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Link colaborativo"),
        "collaborativeLinkCreatedFor": m15,
        "collaborator": MessageLookupByLibrary.simpleMessage("Colaborador"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Colaboradores podem adicionar fotos e vídeos ao álbum compartilhado."),
        "collaboratorsSuccessfullyAdded": m16,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Layout"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("Colagem salva na galeria"),
        "collect": MessageLookupByLibrary.simpleMessage("Coletar"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Coletar fotos de evento"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Coletar fotos"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Crie um link onde seus amigos podem enviar fotos na qualidade original."),
        "color": MessageLookupByLibrary.simpleMessage("Cor"),
        "configuration": MessageLookupByLibrary.simpleMessage("Configuração"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Você tem certeza que queira desativar a autenticação de dois fatores?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Confirmar exclusão da conta"),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Sim, eu quero permanentemente excluir esta conta e os dados em todos os aplicativos."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirmar senha"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("Confirmar mudança de plano"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmar chave de recuperação"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirme sua chave de recuperação"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Conectar ao dispositivo"),
        "contactFamilyAdmin": m18,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contatar suporte"),
        "contactToManageSubscription": m19,
        "contacts": MessageLookupByLibrary.simpleMessage("Contatos"),
        "contents": MessageLookupByLibrary.simpleMessage("Conteúdos"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuar"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Continuar com a avaliação grátis"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Converter para álbum"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Copiar e-mail"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copiar link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copie e cole o código no aplicativo autenticador"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Nós não podemos salvar seus dados.\nNós tentaremos novamente mais tarde."),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
            "Não foi possível liberar espaço"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Não foi possível atualizar a assinatura"),
        "count": MessageLookupByLibrary.simpleMessage("Contagem"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Relatório de erros"),
        "create": MessageLookupByLibrary.simpleMessage("Criar"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Criar conta"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Pressione para selecionar fotos e clique em + para criar um álbum"),
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
        "crop": MessageLookupByLibrary.simpleMessage("Cortar"),
        "curatedMemories":
            MessageLookupByLibrary.simpleMessage("Memórias restauradas"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("O uso atual é "),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("Atualmente executando"),
        "custom": MessageLookupByLibrary.simpleMessage("Personalizado"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Escuro"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Hoje"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Ontem"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Recusar convite"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("Descriptografando..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Descriptografando vídeo..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Arquivos duplicados"),
        "delete": MessageLookupByLibrary.simpleMessage("Excluir"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Excluir conta"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Lamentamos você ir. Compartilhe seu feedback para ajudar-nos a melhorar."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Excluir conta permanentemente"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Excluir álbum"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Também excluir as fotos (e vídeos) presentes neste álbum de <bold>todos</bold> os outros álbuns que eles fazem parte?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Isso excluirá todos os álbuns vazios. Isso é útil quando você quiser reduzir a desordem no seu álbum."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Excluir tudo"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Esta conta está vinculada aos outros aplicativos do Ente, se você usar algum. Seus dados baixados, entre todos os aplicativos do Ente, serão programados para exclusão, e sua conta será permanentemente excluída."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Por favor, envie um e-mail a <warning>account-deletion@ente.io</warning> do seu e-mail registrado."),
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
        "deleteItemCount": m21,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Excluir localização"),
        "deleteMultipleAlbumDialog": m22,
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Excluir fotos"),
        "deleteProgress": m23,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Está faltando um recurso-chave que eu preciso"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "O aplicativo ou um certo recurso não funciona da maneira que eu acredito que deveria funcionar"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Encontrei outro serviço que considero melhor"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Meu motivo não está listado"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Sua solicitação será revisada em até 72 horas."),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Excluir álbum compartilhado?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "O álbum será apagado para todos\n\nVocê perderá o acesso a fotos compartilhadas neste álbum que pertencem aos outros"),
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Deselecionar tudo"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Feito para reviver memórias"),
        "details": MessageLookupByLibrary.simpleMessage("Detalhes"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Opções de desenvolvedor"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Deseja modificar as Opções de Desenvolvedor?"),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Insira o código"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Arquivos adicionados ao álbum do dispositivo serão automaticamente enviados para o Ente."),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Bloqueio do dispositivo"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Desativa o bloqueio de tela se o Ente estiver de fundo e uma cópia de segurança ainda estiver em andamento. Às vezes, isso não é necessário, mas ajuda a agilizar envios grandes e importações iniciais de bibliotecas maiores."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Dispositivo não encontrado"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Você sabia?"),
        "different": MessageLookupByLibrary.simpleMessage("Diferente"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Desativar bloqueio automático"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Os visualizadores podem fazer capturas de tela ou salvar uma cópia de suas fotos usando ferramentas externas"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Por favor, saiba que"),
        "disableLinkMessage": m24,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Desativar autenticação de dois fatores"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Desativando a autenticação de dois fatores..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Explorar"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Bebês"),
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
            MessageLookupByLibrary.simpleMessage("Capturas de tela"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfies"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Pôr do sol"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Cartões de visita"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Papéis de parede"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Descartar"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Não sair"),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Fazer isso depois"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Você quer descartar as edições que você fez?"),
        "done": MessageLookupByLibrary.simpleMessage("Concluído"),
        "dontSave": MessageLookupByLibrary.simpleMessage("Não salvar"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Duplique seu armazenamento"),
        "download": MessageLookupByLibrary.simpleMessage("Baixar"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Falhou ao baixar"),
        "downloading": MessageLookupByLibrary.simpleMessage("Baixando..."),
        "dropSupportEmail": m25,
        "duplicateFileCountWithStorageSaved": m26,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Editar"),
        "editEmailAlreadyLinked": m28,
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Editar localização"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Editar localização"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Editar pessoa"),
        "editTime": MessageLookupByLibrary.simpleMessage("Editar tempo"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Edições salvas"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Edições à localização serão apenas vistos no Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("elegível"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailAlreadyRegistered":
            MessageLookupByLibrary.simpleMessage("E-mail já registrado."),
        "emailChangedTo": m29,
        "emailDoesNotHaveEnteAccount": m30,
        "emailNoEnteAccount": m31,
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("E-mail não registrado."),
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("Verificação por e-mail"),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("Enviar registros por e-mail"),
        "embracingThem": m32,
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Contatos de emergência"),
        "empty": MessageLookupByLibrary.simpleMessage("Esvaziar"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Esvaziar a lixeira?"),
        "enable": MessageLookupByLibrary.simpleMessage("Ativar"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente fornece aprendizado automático no dispositivo para reconhecimento facial, busca mágica e outros recursos de busca avançados."),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Ativar o aprendizado automático para busca mágica e reconhecimento facial"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Ativar mapas"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Isso exibirá suas fotos em um mapa mundial.\n\nEste mapa é hospedado por Open Street Map, e as exatas localizações das fotos nunca serão compartilhadas.\n\nVocê pode desativar esta função a qualquer momento em Opções."),
        "enabled": MessageLookupByLibrary.simpleMessage("Ativado"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
            "Criptografando salvar em segurança..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Criptografia"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Chaves de criptografia"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Ponto final atualizado com sucesso"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Criptografado de ponta a ponta por padrão"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente pode criptografar e preservar arquivos apenas se você conceder acesso a eles"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>precisa de permissão para</i> preservar suas fotos"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "O Ente preserva suas memórias, então eles sempre estão disponíveis para você, mesmo se você perder o dispositivo."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Sua família também poderá ser adicionada ao seu plano."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Inserir nome do álbum"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Inserir código"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Insira o código fornecido por um amigo para reivindicar armazenamento grátis para ambos"),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Aniversário (opcional)"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Inserir e-mail"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Inserir nome do arquivo"),
        "enterName": MessageLookupByLibrary.simpleMessage("Inserir nome"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Insira uma senha nova para criptografar seus dados"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Inserir senha"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Insira uma senha que podemos usar para criptografar seus dados"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Inserir nome da pessoa"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Inserir PIN"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
            "Inserir código de referência"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Digite o código de 6 dígitos do\naplicativo autenticador"),
        "enterValidEmail":
            MessageLookupByLibrary.simpleMessage("Insira um e-mail válido."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Insira seu e-mail"),
        "enterYourNewEmailAddress":
            MessageLookupByLibrary.simpleMessage("Insira seu novo e-mail"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Insira sua senha"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Insira sua chave de recuperação"),
        "error": MessageLookupByLibrary.simpleMessage("Erro"),
        "everywhere":
            MessageLookupByLibrary.simpleMessage("em todas as partes"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Usuário existente"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "O link expirou. Selecione um novo tempo de expiração ou desative a expiração do link."),
        "exportLogs":
            MessageLookupByLibrary.simpleMessage("Exportar registros"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exportar dados"),
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
            "Fotos adicionais encontradas"),
        "extraPhotosFoundFor": m33,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Rosto não agrupado ainda, volte aqui mais tarde"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Reconhecimento facial"),
        "faces": MessageLookupByLibrary.simpleMessage("Rostos"),
        "failed": MessageLookupByLibrary.simpleMessage("Falhou"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Falhou ao aplicar código"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Falhou ao cancelar"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Falhou ao baixar vídeo"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Falhou ao obter sessões ativas"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Falhou ao obter original para edição"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Não foi possível buscar os detalhes de referência. Tente novamente mais tarde."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Falhou ao carregar álbuns"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Falhou ao reproduzir vídeo"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Falhou ao atualizar assinatura"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Falhou ao renovar"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Falhou ao verificar estado do pagamento"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Adicione 5 familiares para seu plano existente sem pagar nenhum custo adicional.\n\nCada membro ganha seu espaço privado, significando que eles não podem ver os arquivos dos outros a menos que eles sejam compartilhados.\n\nOs planos familiares estão disponíveis para clientes que já tem uma assinatura paga do Ente.\n\nAssine agora para iniciar!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Família"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Planos familiares"),
        "faq": MessageLookupByLibrary.simpleMessage("Perguntas frequentes"),
        "faqs": MessageLookupByLibrary.simpleMessage("Perguntas frequentes"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorito"),
        "feastingWithThem": m34,
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "file": MessageLookupByLibrary.simpleMessage("Arquivo"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Falhou ao salvar arquivo na galeria"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Adicionar descrição..."),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("Arquivo ainda não enviado"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Arquivo salvo na galeria"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Tipos de arquivo"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Tipos de arquivo e nomes"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Arquivos excluídos"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Arquivos salvos na galeria"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Busque pessoas facilmente pelo nome"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("Busque-os rapidamente"),
        "flip": MessageLookupByLibrary.simpleMessage("Inverter"),
        "food": MessageLookupByLibrary.simpleMessage("Delícias de cozinha"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("para suas memórias"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Esqueci a senha"),
        "foundFaces":
            MessageLookupByLibrary.simpleMessage("Rostos encontrados"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Armaz. grátis reivindicado"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Armazenamento disponível"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Avaliação grátis"),
        "freeTrialValidTill": m38,
        "freeUpAccessPostDelete": m39,
        "freeUpAmount": m40,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Liberar espaço no dispositivo"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Economize espaço em seu dispositivo por limpar arquivos já salvos com segurança."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Liberar espaço"),
        "freeUpSpaceSaving": m41,
        "gallery": MessageLookupByLibrary.simpleMessage("Galeria"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Até 1.000 memórias exibidas na galeria"),
        "general": MessageLookupByLibrary.simpleMessage("Geral"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Gerando chaves de criptografia..."),
        "genericProgress": m42,
        "goToSettings": MessageLookupByLibrary.simpleMessage("Ir às opções"),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("ID do Google Play"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Permita o acesso a todas as fotos nas opções do aplicativo"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Conceder permissões"),
        "greenery": MessageLookupByLibrary.simpleMessage("A vegetação verde"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("Agrupar fotos próximas"),
        "guestView": MessageLookupByLibrary.simpleMessage("Vista do convidado"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Para ativar a vista do convidado, defina uma senha de acesso no dispositivo ou bloqueie sua tela nas opções do sistema."),
        "happyBirthday":
            MessageLookupByLibrary.simpleMessage("Feliz aniversário! 🥳"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Não rastreamos instalações de aplicativo. Seria útil se você contasse onde nos encontrou!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Como você soube do Ente? (opcional)"),
        "help": MessageLookupByLibrary.simpleMessage("Ajuda"),
        "hidden": MessageLookupByLibrary.simpleMessage("Oculto"),
        "hide": MessageLookupByLibrary.simpleMessage("Ocultar"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Ocultar conteúdo"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Oculta os conteúdos do aplicativo no seletor de aplicativos e desativa capturas de tela"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Oculta o conteúdo no seletor de aplicativos"),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "Ocultar itens compartilhados da galeria inicial"),
        "hiding": MessageLookupByLibrary.simpleMessage("Ocultando..."),
        "hikingWithThem": m43,
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Hospedado em OSM France"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Como funciona"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Peça-os para pressionarem no e-mail a partir das Opções, e verifique-se os IDs de ambos os dispositivos correspondem."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "A autenticação biométrica não está definida no dispositivo. Ative o Touch ID ou Face ID no dispositivo."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "A autenticação biométrica está desativada. Bloqueie e desbloqueie sua tela para ativá-la."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignore": MessageLookupByLibrary.simpleMessage("Ignorar"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorar"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignorado"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Alguns arquivos neste álbum são ignorados do envio porque eles foram anteriormente excluídos do Ente."),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Imagem não analisada"),
        "immediately": MessageLookupByLibrary.simpleMessage("Imediatamente"),
        "importing": MessageLookupByLibrary.simpleMessage("Importando...."),
        "incorrectCode":
            MessageLookupByLibrary.simpleMessage("Código incorreto"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Senha incorreta"),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Chave de recuperação incorreta"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "A chave de recuperação inserida está incorreta"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Chave de recuperação incorreta"),
        "indexedItems": MessageLookupByLibrary.simpleMessage("Itens indexados"),
        "indexingPausedStatusDescription": MessageLookupByLibrary.simpleMessage(
            "A indexação foi pausada. Ela retomará automaticamente quando o dispositivo estiver pronto. O dispositivo é considerado pronto quando o nível de bateria, saúde da bateria, e estado térmico estejam num alcance saudável."),
        "ineligible": MessageLookupByLibrary.simpleMessage("Inelegível"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Dispositivo inseguro"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Instalar manualmente"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("E-mail inválido"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Ponto final inválido"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Desculpe, o ponto final inserido é inválido. Insira um ponto final válido e tente novamente."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Chave inválida"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "A chave de recuperação que você inseriu não é válida. Certifique-se de conter 24 caracteres, e verifique a ortografia de cada um deles.\n\nSe você inseriu um código de recuperação mais antigo, verifique se ele tem 64 caracteres e verifique cada um deles."),
        "invite": MessageLookupByLibrary.simpleMessage("Convidar"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Convidar ao Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Convide seus amigos"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Convide seus amigos ao Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Parece que algo deu errado. Tente novamente mais tarde. Caso o erro persistir, por favor, entre em contato com nossa equipe."),
        "itemCount": m44,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Os itens exibem o número de dias restantes antes da exclusão permanente"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Os itens selecionados serão removidos deste álbum"),
        "join": MessageLookupByLibrary.simpleMessage("Unir-se"),
        "joinAlbum": MessageLookupByLibrary.simpleMessage("Unir-se ao álbum"),
        "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
            "Unir-se ao álbum fará que seu e-mail seja visível a todos do álbum."),
        "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
            "para visualizar e adicionar suas fotos"),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
            "para adicionar isso aos álbuns compartilhados"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Junte-se ao Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Manter fotos"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Ajude-nos com esta informação"),
        "language": MessageLookupByLibrary.simpleMessage("Idioma"),
        "lastTimeWithThem": m45,
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Última atualização"),
        "lastYearsTrip":
            MessageLookupByLibrary.simpleMessage("Viajem do ano passado"),
        "leave": MessageLookupByLibrary.simpleMessage("Sair"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Sair do álbum"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Sair do plano familiar"),
        "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Sair do álbum compartilhado?"),
        "left": MessageLookupByLibrary.simpleMessage("Esquerda"),
        "legacy": MessageLookupByLibrary.simpleMessage("Legado"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Contas legadas"),
        "legacyInvite": m46,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "O legado permite que contatos confiáveis acessem sua conta em sua ausência."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Contatos confiáveis podem iniciar recuperação de conta. Se não cancelado dentro de 30 dias, redefina sua senha e acesse sua conta."),
        "light": MessageLookupByLibrary.simpleMessage("Brilho"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Claro"),
        "link": MessageLookupByLibrary.simpleMessage("Vincular"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Link copiado para a área de transferência"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limite do dispositivo"),
        "linkEmail": MessageLookupByLibrary.simpleMessage("Vincular e-mail"),
        "linkEmailToContactBannerCaption":
            MessageLookupByLibrary.simpleMessage("para compartilhar rápido"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Ativado"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expirado"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Expiração do link"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("O link expirou"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Nunca"),
        "linkPerson": MessageLookupByLibrary.simpleMessage("Vincular pessoa"),
        "linkPersonCaption": MessageLookupByLibrary.simpleMessage(
            "para melhorar o compartilhamento"),
        "linkPersonToEmail": m48,
        "linkPersonToEmailConfirmation": m49,
        "livePhotos": MessageLookupByLibrary.simpleMessage("Fotos animadas"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Você pode compartilhar sua assinatura com seus familiares"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Preservamos mais de 200 milhões de memórias até então"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Mantemos 3 cópias dos seus dados, uma em um abrigo subterrâneo"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Todos os nossos aplicativos são de código aberto"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Nosso código-fonte e criptografia foram auditadas externamente"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Você pode compartilhar links para seus álbuns com seus entes queridos"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Nossos aplicativos móveis são executados em segundo plano para criptografar e salvar em segurança quaisquer fotos novas que você acessar"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io tem um enviador mais rápido"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Nós usamos Xchacha20Poly1305 para criptografar seus dados com segurança"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Carregando dados EXIF..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Carregando galeria..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Carregando suas fotos..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Baixando modelos..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Carregando suas fotos..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galeria local"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Indexação local"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Ocorreu um erro devido à sincronização de localização das fotos estar levando mais tempo que o esperado. Entre em contato conosco."),
        "location": MessageLookupByLibrary.simpleMessage("Localização"),
        "locationName":
            MessageLookupByLibrary.simpleMessage("Nome da localização"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Uma etiqueta de localização agrupa todas as fotos fotografadas em algum raio de uma foto"),
        "locations": MessageLookupByLibrary.simpleMessage("Localizações"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Bloquear"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Tela de bloqueio"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Entrar"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Desconectando..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessão expirada"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Sua sessão expirou. Registre-se novamente."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Ao clicar em entrar, eu concordo com os <u-terms>termos de serviço</u-terms> e a <u-policy>política de privacidade</u-policy>"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("Registrar com TOTP"),
        "logout": MessageLookupByLibrary.simpleMessage("Encerrar sessão"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Isso enviará através dos registros para ajudar-nos a resolver seu problema. Saiba que, nome de arquivos serão incluídos para ajudar a buscar problemas com arquivos específicos."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Pressione um e-mail para verificar a criptografia ponta a ponta."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Mantenha pressionado em um item para visualizá-lo em tela cheia"),
        "lookBackOnYourMemories":
            MessageLookupByLibrary.simpleMessage("Revise suas memórias 🌄"),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("Repetir vídeo desativado"),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("Repetir vídeo ativado"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Perdeu o dispositivo?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Aprendizado automático"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Busca mágica"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "A busca mágica permite buscar fotos pelo conteúdo, p. e.x. \'flor\', \'carro vermelho\', \'identidade\'"),
        "manage": MessageLookupByLibrary.simpleMessage("Gerenciar"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Gerenciar cache do dispositivo"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Reveja e limpe o armazenamento de cache local."),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Gerenciar família"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Gerenciar link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Gerenciar"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Gerenciar assinatura"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Parear com PIN funciona com qualquer tela que queira visualizar seu álbum."),
        "map": MessageLookupByLibrary.simpleMessage("Mapa"),
        "maps": MessageLookupByLibrary.simpleMessage("Mapas"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "me": MessageLookupByLibrary.simpleMessage("Eu"),
        "memories": MessageLookupByLibrary.simpleMessage("Memórias"),
        "memoriesWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Selecione os tipos de memórias que deseje vê-las na sua tela inicial."),
        "memoryCount": m50,
        "merchandise": MessageLookupByLibrary.simpleMessage("Produtos"),
        "merge": MessageLookupByLibrary.simpleMessage("Mesclar"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Juntar com o existente"),
        "mergedPhotos": MessageLookupByLibrary.simpleMessage("Fotos mescladas"),
        "mlConsent": MessageLookupByLibrary.simpleMessage(
            "Ativar o aprendizado automático"),
        "mlConsentConfirmation":
            MessageLookupByLibrary.simpleMessage("Concordo e desejo ativá-lo"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Se ativar o aprendizado automático, Ente extrairá informações de geometria facial dos arquivos, incluindo aqueles compartilhados consigo.\n\nIsso acontecerá em seu dispositivo, e qualquer informação biométrica gerada será criptografada de ponta a ponta."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Clique aqui para mais detalhes sobre este recurso na política de privacidade"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("Ativar aprendizado auto.?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Saiba que o aprendizado automático afetará a bateria do dispositivo negativamente até todos os itens serem indexados. Utilize a versão para computadores para melhor indexação, todos os resultados se auto-sincronizaram."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Celular, Web, Computador"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderado"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Altere o termo de busca ou tente consultar"),
        "moments": MessageLookupByLibrary.simpleMessage("Momentos"),
        "month": MessageLookupByLibrary.simpleMessage("mês"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensal"),
        "moon": MessageLookupByLibrary.simpleMessage("Na luz do luar"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Mais detalhes"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Mais recente"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Mais relevante"),
        "mountains": MessageLookupByLibrary.simpleMessage("Sob as montanhas"),
        "moveItem": m51,
        "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
            "Mover fotos selecionadas para uma data"),
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Mover para o álbum"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Mover ao álbum oculto"),
        "movedSuccessfullyTo": m52,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Movido para a lixeira"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Movendo arquivos para o álbum..."),
        "name": MessageLookupByLibrary.simpleMessage("Nome"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Nomear álbum"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Não foi possível conectar ao Ente, tente novamente mais tarde. Se o erro persistir, entre em contato com o suporte."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Não foi possível conectar-se ao Ente, verifique suas configurações de rede e entre em contato com o suporte se o erro persistir."),
        "never": MessageLookupByLibrary.simpleMessage("Nunca"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Novo álbum"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Nova localização"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Nova pessoa"),
        "newPhotosEmoji": MessageLookupByLibrary.simpleMessage(" novo 📸"),
        "newRange": MessageLookupByLibrary.simpleMessage("Novo intervalo"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Novo no Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Mais recente"),
        "next": MessageLookupByLibrary.simpleMessage("Próximo"),
        "no": MessageLookupByLibrary.simpleMessage("Não"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Nenhum álbum compartilhado por você ainda"),
        "noDeviceFound": MessageLookupByLibrary.simpleMessage(
            "Nenhum dispositivo encontrado"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Nenhum"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Você não tem arquivos neste dispositivo que possam ser excluídos"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Sem duplicatas"),
        "noEnteAccountExclamation":
            MessageLookupByLibrary.simpleMessage("Nenhuma conta Ente!"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Sem dados EXIF"),
        "noFacesFound":
            MessageLookupByLibrary.simpleMessage("Nenhum rosto encontrado"),
        "noHiddenPhotosOrVideos":
            MessageLookupByLibrary.simpleMessage("Sem fotos ou vídeos ocultos"),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
            "Nenhuma imagem com localização"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Sem conexão à internet"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "No momento não há fotos sendo salvas em segurança"),
        "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage(
            "Nenhuma foto encontrada aqui"),
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
            "Nenhum link rápido selecionado"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Sem chave de recuperação?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Devido à natureza do nosso protocolo de criptografia de ponta a ponta, seus dados não podem ser descriptografados sem sua senha ou chave de recuperação"),
        "noResults": MessageLookupByLibrary.simpleMessage("Nenhum resultado"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Nenhum resultado encontrado"),
        "noSuggestionsForPerson": m53,
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
            "Nenhum bloqueio do sistema encontrado"),
        "notPersonLabel": m54,
        "notThisPerson":
            MessageLookupByLibrary.simpleMessage("Não é esta pessoa?"),
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Nada compartilhado com você ainda"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Nada para ver aqui! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notificações"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "onDevice": MessageLookupByLibrary.simpleMessage("No dispositivo"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "No <branding>ente</branding>"),
        "onTheRoad":
            MessageLookupByLibrary.simpleMessage("Na estrada novamente"),
        "onThisDay": MessageLookupByLibrary.simpleMessage("Neste dia"),
        "onThisDayMemories":
            MessageLookupByLibrary.simpleMessage("Memórias deste dia"),
        "onThisDayNotificationExplanation":
            MessageLookupByLibrary.simpleMessage(
                "Receba lembretes de memórias deste dia em anos passados."),
        "onlyFamilyAdminCanChangeCode": m55,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Apenas eles"),
        "oops": MessageLookupByLibrary.simpleMessage("Ops"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Opa! Não foi possível salvar as edições"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ops, algo deu errado"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("Abrir álbum no navegador"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Use o aplicativo da web para adicionar fotos a este álbum"),
        "openFile": MessageLookupByLibrary.simpleMessage("Abrir arquivo"),
        "openSettings": MessageLookupByLibrary.simpleMessage("Abrir opções"),
        "openTheItem":
            MessageLookupByLibrary.simpleMessage("• Abra a foto ou vídeo"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
            "Contribuidores do OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Opcional, tão curto como quiser..."),
        "orMergeWithExistingPerson":
            MessageLookupByLibrary.simpleMessage("Ou mesclar com existente"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Ou escolha um existente"),
        "orPickFromYourContacts": MessageLookupByLibrary.simpleMessage(
            "ou escolher dos seus contatos"),
        "otherDetectedFaces":
            MessageLookupByLibrary.simpleMessage("Outros rostos detectados"),
        "pair": MessageLookupByLibrary.simpleMessage("Parear"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("Parear com PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Pareamento concluído"),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "partyWithThem": m56,
        "passKeyPendingVerification":
            MessageLookupByLibrary.simpleMessage("Verificação pendente"),
        "passkey": MessageLookupByLibrary.simpleMessage("Chave de acesso"),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
            "Verificação de chave de acesso"),
        "password": MessageLookupByLibrary.simpleMessage("Senha"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Senha alterada com sucesso"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Bloqueio por senha"),
        "passwordStrength": m57,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "A força da senha é calculada considerando o comprimento dos dígitos, carácteres usados, e se ou não a senha aparece nas 10.000 senhas usadas."),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Nós não armazenamos esta senha, se você esquecer, <underline>nós não poderemos descriptografar seus dados</underline>"),
        "pastYearsMemories":
            MessageLookupByLibrary.simpleMessage("Memórias dos anos passados"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Detalhes de pagamento"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("O pagamento falhou"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Infelizmente o pagamento falhou. Entre em contato com o suporte e nós ajudaremos você!"),
        "paymentFailedTalkToProvider": m58,
        "pendingItems": MessageLookupByLibrary.simpleMessage("Itens pendentes"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Sincronização pendente"),
        "people": MessageLookupByLibrary.simpleMessage("Pessoas"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("Pessoas que usou o código"),
        "peopleWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Selecione as pessoas que deseje vê-las na sua tela inicial."),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Todos os itens na lixeira serão excluídos permanentemente\n\nEsta ação não pode ser desfeita"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Excluir permanentemente"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Excluir permanentemente do dispositivo?"),
        "personIsAge": m59,
        "personName": MessageLookupByLibrary.simpleMessage("Nome da pessoa"),
        "personTurningAge": m60,
        "pets": MessageLookupByLibrary.simpleMessage("Companhias peludas"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Descrições das fotos"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Tamanho da grade de fotos"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "photocountPhotos": m61,
        "photos": MessageLookupByLibrary.simpleMessage("Fotos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Suas fotos adicionadas serão removidas do álbum"),
        "photosCount": m62,
        "photosKeepRelativeTimeDifference":
            MessageLookupByLibrary.simpleMessage(
                "As fotos mantêm a diferença de tempo relativo"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Escolha o ponto central"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Fixar álbum"),
        "pinLock": MessageLookupByLibrary.simpleMessage("Bloqueio por PIN"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Reproduzir álbum na TV"),
        "playOriginal":
            MessageLookupByLibrary.simpleMessage("Reproduzir original"),
        "playStoreFreeTrialValidTill": m63,
        "playStream":
            MessageLookupByLibrary.simpleMessage("Reproduzir transmissão"),
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Assinatura da PlayStore"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verifique sua conexão com a internet e tente novamente."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Entre em contato com support@ente.io e nós ficaremos felizes em ajudar!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, contate o suporte se o problema persistir"),
        "pleaseEmailUsAt": m64,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
            "Por favor, conceda as permissões"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Registre-se novamente"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Selecione links rápidos para remover"),
        "pleaseSendTheLogsTo": m65,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Tente novamente"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage("Verifique o código inserido"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Aguarde..."),
        "pleaseWaitDeletingAlbum":
            MessageLookupByLibrary.simpleMessage("Aguarde, excluindo álbum"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Por favor, aguarde mais algum tempo antes de tentar novamente"),
        "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
            "Aguarde um pouco, isso talvez leve um tempo."),
        "posingWithThem": m66,
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Preparando registros..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Preservar mais"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Pressione e segure para reproduzir o vídeo"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Pressione e segure na imagem para reproduzir o vídeo"),
        "previous": MessageLookupByLibrary.simpleMessage("Anterior"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacidade"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Política de Privacidade"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Cópias privadas"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Compartilha privada"),
        "proceed": MessageLookupByLibrary.simpleMessage("Continuar"),
        "processed": MessageLookupByLibrary.simpleMessage("Processado"),
        "processing": MessageLookupByLibrary.simpleMessage("Processando"),
        "processingImport": m67,
        "processingVideos":
            MessageLookupByLibrary.simpleMessage("Processando vídeos"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Link público criado"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Link público ativo"),
        "questionmark": MessageLookupByLibrary.simpleMessage("?"),
        "queued": MessageLookupByLibrary.simpleMessage("Na fila"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Links rápidos"),
        "radius": MessageLookupByLibrary.simpleMessage("Raio"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Abrir ticket"),
        "rateTheApp":
            MessageLookupByLibrary.simpleMessage("Avalie o aplicativo"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Avaliar"),
        "rateUsOnStore": m68,
        "reassignMe": MessageLookupByLibrary.simpleMessage("Reatribuir \"Eu\""),
        "reassignedToName": m69,
        "reassigningLoading":
            MessageLookupByLibrary.simpleMessage("Reatribuindo..."),
        "receiveRemindersOnBirthdays": MessageLookupByLibrary.simpleMessage(
            "Receba notificações quando alguém fizer um aniversário. Tocar na notificação o levará às fotos do aniversariante."),
        "recover": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recuperar conta"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Recuperar conta"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("A recuperação iniciou"),
        "recoveryInitiatedDesc": m70,
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Chave de recuperação"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Chave de recuperação copiada para a área de transferência"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Caso você esqueça sua senha, a única maneira de recuperar seus dados é com esta chave."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Não armazenamos esta chave, salve esta chave de 24 palavras em um lugar seguro."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Ótimo! Sua chave de recuperação é válida. Obrigada por verificar.\n\nLembre-se de manter sua chave de recuperação salva em segurança."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Chave de recuperação verificada"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Sua chave de recuperação é a única maneira de recuperar suas fotos se você esqueceu sua senha. Você pode encontrar sua chave de recuperação em Opções > Conta.\n\nInsira sua chave de recuperação aqui para verificar se você a salvou corretamente."),
        "recoveryReady": m71,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Recuperação com sucesso!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "Um contato confiável está tentando acessar sua conta"),
        "recoveryWarningBody": m72,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "O dispositivo atual não é poderoso o suficiente para verificar sua senha, no entanto, nós podemos regenerar numa maneira que funciona em todos os dispositivos.\n\nEntre usando a chave de recuperação e regenere sua senha (você pode usar a mesma novamente se desejar)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Redefinir senha"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Reinserir senha"),
        "reenterPin": MessageLookupByLibrary.simpleMessage("Reinserir PIN"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Recomende seus amigos e duplique seu plano"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Envie este código aos seus amigos"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Eles então se inscrevem num plano pago"),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("Referências"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "As referências estão atualmente pausadas"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Rejeitar recuperação"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Também esvazie o \"Excluído Recentemente\" das \"Opções\" -> \"Armazenamento\" para liberar espaço"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Também esvazie sua \"Lixeira\" para reivindicar o espaço liberado"),
        "remoteImages": MessageLookupByLibrary.simpleMessage("Imagens remotas"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Miniaturas remotas"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Vídeos remotos"),
        "remove": MessageLookupByLibrary.simpleMessage("Remover"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Excluir duplicatas"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Revise e remova arquivos que são duplicatas exatas."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Remover do álbum"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Remover do álbum?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Desfavoritar"),
        "removeInvite": MessageLookupByLibrary.simpleMessage("Remover convite"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Remover link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Remover participante"),
        "removeParticipantBody": m74,
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
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Remover si mesmo dos contatos confiáveis"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Removendo dos favoritos..."),
        "rename": MessageLookupByLibrary.simpleMessage("Renomear"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Renomear álbum"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Renomear arquivo"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Renovar assinatura"),
        "renewsOn": m75,
        "reportABug": MessageLookupByLibrary.simpleMessage("Informar um erro"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Informar erro"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Reenviar e-mail"),
        "reset": MessageLookupByLibrary.simpleMessage("Redefinir"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Redefinir arquivos ignorados"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Redefinir senha"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Remover"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Redefinir para o padrão"),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurar"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Restaurar para álbum"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Restaurando arquivos..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("Envios retomáveis"),
        "retry": MessageLookupByLibrary.simpleMessage("Tentar novamente"),
        "review": MessageLookupByLibrary.simpleMessage("Revisar"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Reveja e exclua os itens que você acredita serem duplicados."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Revisar sugestões"),
        "right": MessageLookupByLibrary.simpleMessage("Direita"),
        "roadtripWithThem": m76,
        "rotate": MessageLookupByLibrary.simpleMessage("Girar"),
        "rotateLeft":
            MessageLookupByLibrary.simpleMessage("Girar para a esquerda"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Girar para a direita"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Armazenado com segurança"),
        "same": MessageLookupByLibrary.simpleMessage("Igual"),
        "sameperson": MessageLookupByLibrary.simpleMessage("Mesma pessoa?"),
        "save": MessageLookupByLibrary.simpleMessage("Salvar"),
        "saveAsAnotherPerson":
            MessageLookupByLibrary.simpleMessage("Salvar como outra pessoa"),
        "saveChangesBeforeLeavingQuestion":
            MessageLookupByLibrary.simpleMessage(
                "Salvar mudanças antes de sair?"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Salvar colagem"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Salvar cópia"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Salvar chave"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Salvar pessoa"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Salve sua chave de recuperação, se você ainda não fez"),
        "saving": MessageLookupByLibrary.simpleMessage("Salvando..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Salvando edições..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Escanear código"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Escaneie este código de barras com\no aplicativo autenticador"),
        "search": MessageLookupByLibrary.simpleMessage("Buscar"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Álbuns"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Nome do álbum"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Nomes de álbuns (ex: \"Câmera\")\n• Tipos de arquivos (ex.: \"Vídeos\", \".gif\")\n• Anos e meses (ex.: \"2022\", \"Janeiro\")\n• Temporadas (ex.: \"Natal\")\n• Tags (ex.: \"#divertido\")"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Adicione marcações como \"#viagem\" nas informações das fotos para encontrá-las aqui com facilidade"),
        "searchDatesEmptySection":
            MessageLookupByLibrary.simpleMessage("Buscar por data, mês ou ano"),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "As imagens serão exibidas aqui quando o processamento e sincronização for concluído"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "As pessoas apareceram aqui quando a indexação for concluída"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Tipos de arquivo e nomes"),
        "searchHint1":
            MessageLookupByLibrary.simpleMessage("busca rápida no dispositivo"),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("Descrições e data das fotos"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Álbuns, nomes de arquivos e tipos"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Localização"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Em breve: Busca mágica e rostos ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Fotos de grupo que estão sendo tiradas em algum raio da foto"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Convide pessoas e você verá todas as fotos compartilhadas por elas aqui"),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "As pessoas serão exibidas aqui quando o processamento e sincronização for concluído"),
        "searchResultCount": m77,
        "searchSectionsLengthMismatch": m78,
        "security": MessageLookupByLibrary.simpleMessage("Segurança"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "Ver links de álbum compartilhado no aplicativo"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Selecionar localização"),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
            "Primeiramente selecione uma localização"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Selecionar álbum"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Selecionar tudo"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Tudo"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Selecionar foto da capa"),
        "selectDate": MessageLookupByLibrary.simpleMessage("Selecionar data"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Selecione as pastas para salvá-las"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Selecionar itens para adicionar"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Selecionar idioma"),
        "selectMailApp": MessageLookupByLibrary.simpleMessage(
            "Selecionar aplicativo de e-mail"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Selecionar mais fotos"),
        "selectOneDateAndTime":
            MessageLookupByLibrary.simpleMessage("Selecionar data e hora"),
        "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
            "Selecione uma data e hora para todos"),
        "selectPersonToLink": MessageLookupByLibrary.simpleMessage(
            "Selecione a pessoa para vincular"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Diga o motivo"),
        "selectStartOfRange": MessageLookupByLibrary.simpleMessage(
            "Selecionar início de intervalo"),
        "selectTime": MessageLookupByLibrary.simpleMessage("Selecionar tempo"),
        "selectYourFace":
            MessageLookupByLibrary.simpleMessage("Selecione seu rosto"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Selecione seu plano"),
        "selectedAlbums": m79,
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Os arquivos selecionados não estão no Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "As pastas selecionadas serão criptografadas e salvas em segurança"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Os itens selecionados serão excluídos de todos os álbuns e movidos para a lixeira."),
        "selectedItemsWillBeRemovedFromThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Os itens selecionados serão removidos desta pessoa, entretanto não serão excluídos da sua biblioteca."),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "selfiesWithThem": m82,
        "send": MessageLookupByLibrary.simpleMessage("Enviar"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Enviar e-mail"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Enviar convite"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Enviar link"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Ponto final do servidor"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessão expirada"),
        "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
            "Incompatibilidade de ID de sessão"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Definir senha"),
        "setAs": MessageLookupByLibrary.simpleMessage("Definir como"),
        "setCover": MessageLookupByLibrary.simpleMessage("Definir capa"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Definir"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Definir nova senha"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("Definir PIN novo"),
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
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Compartilhar apenas com as pessoas que você quiser"),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Baixe o Ente para que nós possamos compartilhar com facilidade fotos e vídeos de qualidade original\n\nhttps://ente.io"),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Compartilhar com usuários não ente"),
        "shareWithPeopleSectionTitle": m86,
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
            "Receba notificações caso alguém adicione uma foto a um álbum compartilhado que você faz parte"),
        "sharedWith": m87,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Compartilhado comigo"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Compartilhado com você"),
        "sharing": MessageLookupByLibrary.simpleMessage("Compartilhando..."),
        "shiftDatesAndTime":
            MessageLookupByLibrary.simpleMessage("Alterar as datas e horas"),
        "showLessFaces":
            MessageLookupByLibrary.simpleMessage("Exibir menos rostos"),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Mostrar memórias"),
        "showMoreFaces":
            MessageLookupByLibrary.simpleMessage("Exibir mais rostos"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Mostrar pessoa"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Sair da conta em outros dispositivos"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Se você acha que alguém possa saber da sua senha, você pode forçar desconectar sua conta de outros dispositivos."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Sair em outros dispositivos"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Eu concordo com os <u-terms>termos de serviço</u-terms> e a <u-policy>política de privacidade</u-policy>"),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Ele será excluído de todos os álbuns."),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("Pular"),
        "smartMemories":
            MessageLookupByLibrary.simpleMessage("Memórias inteligentes"),
        "social": MessageLookupByLibrary.simpleMessage("Redes sociais"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Alguns itens estão em ambos o Ente quanto no seu dispositivo."),
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
                "Algo deu errado. Tente outra vez"),
        "sorry": MessageLookupByLibrary.simpleMessage("Desculpe"),
        "sorryBackupFailedDesc": MessageLookupByLibrary.simpleMessage(
            "Desculpe, não podemos salvar em segurança este arquivo no momento, nós tentaremos mais tarde."),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Desculpe, não foi possível adicionar aos favoritos!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Desculpe, não foi possível remover dos favoritos!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "O código inserido está incorreto"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Desculpe, não foi possível gerar chaves seguras neste dispositivo.\n\ninicie sessão com um dispositivo diferente."),
        "sorryWeHadToPauseYourBackups": MessageLookupByLibrary.simpleMessage(
            "Desculpe, tivemos que pausar os salvamentos em segurança"),
        "sort": MessageLookupByLibrary.simpleMessage("Ordenar"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Ordenar por"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Recentes primeiro"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Antigos primeiro"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Sucesso"),
        "sportsWithThem": m91,
        "spotlightOnThem": m92,
        "spotlightOnYourself":
            MessageLookupByLibrary.simpleMessage("Destacar si mesmo"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Iniciar recuperação"),
        "startBackup": MessageLookupByLibrary.simpleMessage(
            "Iniciar a salvar em segurança"),
        "status": MessageLookupByLibrary.simpleMessage("Estado"),
        "stopCastingBody":
            MessageLookupByLibrary.simpleMessage("Deseja parar a transmissão?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Parar transmissão"),
        "storage": MessageLookupByLibrary.simpleMessage("Armazenamento"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Família"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Você"),
        "storageInGB": m93,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
            "Limite de armazenamento excedido"),
        "storageUsageInfo": m94,
        "streamDetails":
            MessageLookupByLibrary.simpleMessage("Detalhes da transmissão"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Forte"),
        "subAlreadyLinkedErrMessage": m95,
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("Inscrever-se"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Você precisa de uma inscrição paga ativa para ativar o compartilhamento."),
        "subscription": MessageLookupByLibrary.simpleMessage("Assinatura"),
        "success": MessageLookupByLibrary.simpleMessage("Sucesso"),
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
        "sunrise": MessageLookupByLibrary.simpleMessage("No horizonte"),
        "support": MessageLookupByLibrary.simpleMessage("Suporte"),
        "syncProgress": m97,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Sincronização interrompida"),
        "syncing": MessageLookupByLibrary.simpleMessage("Sincronizando..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistema"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("toque para copiar"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Toque para inserir código"),
        "tapToUnlock":
            MessageLookupByLibrary.simpleMessage("Toque para desbloquear"),
        "tapToUpload":
            MessageLookupByLibrary.simpleMessage("Toque para enviar"),
        "tapToUploadIsIgnoredDue": m98,
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Parece que algo deu errado. Tente novamente mais tarde. Caso o erro persistir, por favor, entre em contato com nossa equipe."),
        "terminate": MessageLookupByLibrary.simpleMessage("Encerrar"),
        "terminateSession": MessageLookupByLibrary.simpleMessage("Sair?"),
        "terms": MessageLookupByLibrary.simpleMessage("Termos"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Termos"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Obrigado"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("Obrigado por assinar!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "A instalação não pôde ser concluída"),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "O link que você está tentando acessar já expirou."),
        "thePersonGroupsWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
            "Os grupos de pessoa não serão exibidos na seção de pessoa. As fotos permanecerão intactas."),
        "thePersonWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
            "A pessoa não será exibida na seção de pessoas. As fotos permanecerão intactas."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "A chave de recuperação inserida está incorreta"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Estes itens serão excluídos do seu dispositivo."),
        "theyAlsoGetXGb": m99,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Eles serão excluídos de todos os álbuns."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Esta ação não pode ser desfeita"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Este álbum já tem um link colaborativo"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Isso pode ser usado para recuperar sua conta se você perder seu segundo fator"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Este dispositivo"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Este e-mail já está sendo usado"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Esta imagem não possui dados EXIF"),
        "thisIsMeExclamation":
            MessageLookupByLibrary.simpleMessage("Este é você!"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Este é o seu ID de verificação"),
        "thisWeekThroughTheYears": MessageLookupByLibrary.simpleMessage(
            "Esta semana com o passar dos anos"),
        "thisWeekXYearsAgo": m101,
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Isso fará você sair do dispositivo a seguir:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Isso fará você sair deste dispositivo!"),
        "thisWillMakeTheDateAndTimeOfAllSelected":
            MessageLookupByLibrary.simpleMessage(
                "Isso fará que a data e hora de todas as fotos selecionadas fiquem iguais."),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Isto removerá links públicos de todos os links rápidos selecionados."),
        "throughTheYears": m102,
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Para ativar o bloqueio do aplicativo, defina uma senha de acesso no dispositivo ou bloqueie sua tela nas opções do sistema."),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Para ocultar uma foto ou vídeo"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Para redefinir sua senha, verifique seu e-mail primeiramente."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Registros de hoje"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
            "Muitas tentativas incorretas"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Tamanho total"),
        "trash": MessageLookupByLibrary.simpleMessage("Lixeira"),
        "trashDaysLeft": m103,
        "trim": MessageLookupByLibrary.simpleMessage("Recortar"),
        "tripInYear": m104,
        "tripToLocation": m105,
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Contatos confiáveis"),
        "trustedInviteBody": m106,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Tente novamente"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Ative o salvamento em segurança para automaticamente enviar arquivos adicionados à pasta do dispositivo para o Ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter/X"),
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
        "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
        "unarchive": MessageLookupByLibrary.simpleMessage("Desarquivar"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Desarquivar álbum"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("Desarquivando..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Desculpe, este código está indisponível."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Sem categoria"),
        "unhide": MessageLookupByLibrary.simpleMessage("Desocultar"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Desocultar para o álbum"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Reexibindo..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Desocultando arquivos para o álbum"),
        "unlock": MessageLookupByLibrary.simpleMessage("Desbloquear"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Desafixar álbum"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar tudo"),
        "update": MessageLookupByLibrary.simpleMessage("Atualizar"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Atualização disponível"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Atualizando seleção de pasta..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Atualizar"),
        "uploadIsIgnoredDueToIgnorereason": m108,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Enviando arquivos para o álbum..."),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Preservando 1 memória..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Com 50% de desconto, até 4 de dezembro"),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "O armazenamento disponível é limitado devido ao seu plano atual. O armazenamento adicional será aplicado quando você atualizar seu plano."),
        "useAsCover": MessageLookupByLibrary.simpleMessage("Usar como capa"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "Enfrentando problemas ao reproduzir este vídeo? Mantenha pressionado aqui para tentar outro reprodutor de vídeo"),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Usar links públicos para pessoas que não estão no Ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Usar chave de recuperação"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Usar foto selecionada"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Espaço usado"),
        "validTill": m110,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Falha na verificação. Tente novamente"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de verificação"),
        "verify": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Verificar e-mail"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Verificar chave de acesso"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verificar senha"),
        "verifying": MessageLookupByLibrary.simpleMessage("Verificando..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verificando chave de recuperação..."),
        "videoInfo":
            MessageLookupByLibrary.simpleMessage("Informações do vídeo"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vídeo"),
        "videoStreaming":
            MessageLookupByLibrary.simpleMessage("Vídeos transmissíveis"),
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
            "Ver arquivos que consumem a maior parte do armazenamento."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Ver registros"),
        "viewPersonToUnlink": m112,
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ver chave de recuperação"),
        "viewer": MessageLookupByLibrary.simpleMessage("Visualizador"),
        "viewersSuccessfullyAdded": m113,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Visite o web.ente.io para gerenciar sua assinatura"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Esperando verificação..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Aguardando Wi-Fi..."),
        "warning": MessageLookupByLibrary.simpleMessage("Aviso"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Nós somos de código aberto!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Não suportamos a edição de fotos e álbuns que você ainda não possui"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Fraca"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Bem-vindo(a) de volta!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("O que há de novo"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Um contato confiável pode ajudá-lo em recuperar seus dados."),
        "widgets": MessageLookupByLibrary.simpleMessage("Widgets"),
        "wishThemAHappyBirthday": m115,
        "yearShort": MessageLookupByLibrary.simpleMessage("ano"),
        "yearly": MessageLookupByLibrary.simpleMessage("Anual"),
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("Sim"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Sim"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Sim, converter para visualizador"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Sim, excluir"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Sim, descartar alterações"),
        "yesIgnore": MessageLookupByLibrary.simpleMessage("Sim, ignorar"),
        "yesLogout":
            MessageLookupByLibrary.simpleMessage("Sim, encerrar sessão"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Sim, excluir"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Sim"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Sim, redefinir pessoa"),
        "you": MessageLookupByLibrary.simpleMessage("Você"),
        "youAndThem": m117,
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
            "Você está em um plano familiar!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Você está na versão mais recente"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Você pode duplicar seu armazenamento ao máximo"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Você pode gerenciar seus links na aba de compartilhamento."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Você pode tentar buscar por outra consulta."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Você não pode rebaixar para este plano"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Não é possível compartilhar consigo mesmo"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Você não tem nenhum item arquivado."),
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Sua conta foi excluída"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Seu mapa"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Seu plano foi rebaixado com sucesso"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Seu plano foi atualizado com sucesso"),
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
                "Você não possui nenhum arquivo duplicado que possa ser excluído"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Você não tem arquivos neste álbum que possam ser excluídos"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
            "Reduzir ampliação para ver as fotos")
      };
}
