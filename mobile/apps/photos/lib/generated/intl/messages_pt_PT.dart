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

  static String m0(title) => "${title} (Eu)";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Adicionar colaborador', one: 'Adicionar colaborador', other: 'Adicionar colaboradores')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Adicionar item', other: 'Adicionar itens')}";

  static String m3(storageAmount, endDate) =>
      "Seu addon ${storageAmount} é válido até o momento ${endDate}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Adicionar visualizador', one: 'Adicionar visualizador', other: 'Adicionar vizualizadores')}";

  static String m5(emailOrName) => "Adicionado por ${emailOrName}";

  static String m6(albumName) => "Adicionado com sucesso a ${albumName}";

  static String m7(name) => "A admirar ${name}";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Nenhum participante', one: '1 participante', other: '${count} participantes')}";

  static String m9(versionValue) => "Versão: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} grátis";

  static String m11(name) => "Vistas deslumbrantes com ${name}";

  static String m12(paymentProvider) =>
      "Por favor, cancele primeiro a sua subscrição existente de ${paymentProvider}";

  static String m13(user) =>
      "${user} não será capaz de adicionar mais fotos a este álbum\n\nEles ainda serão capazes de remover fotos existentes adicionadas por eles";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Sua família reinvidicou ${storageAmountInGb} GB até então',
            'false': 'Você reinvindicou ${storageAmountInGb} GB até então',
            'other': 'Você reinvindicou ${storageAmountInGb} GB até então!'
          })}";

  static String m15(albumName) => "Link colaborativo criado para ${albumName}";

  static String m16(count) =>
      "${Intl.plural(count, zero: 'Adicionado 0 colaboradores', one: 'Adicionado 1 colaborador', other: 'Adicionado ${count} colaboradores')}";

  static String m17(email, numOfDays) =>
      "Está prestes a adicionar ${email} como contacto de confiança. Eles poderão recuperar a sua conta caso esteja inativo por ${numOfDays} dias.";

  static String m18(familyAdminEmail) =>
      "Contacte <green>${familyAdminEmail}</green> para gerir a sua subscrição";

  static String m19(provider) =>
      "Contacte-nos em support@ente.io para gerir a sua subscrição ${provider}";

  static String m20(endpoint) => "Conectado a ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Apagar ${count} item', other: 'Apagar ${count} itens')}";

  static String m22(count) =>
      "Também eliminar fotos (e vídeos) presentes em ${count} álbuns e de <bold>todos</bold> os outros álbuns que fazem parte?";

  static String m23(currentlyDeleting, totalCount) =>
      "Apagar ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "Isto removerá o link público para acessar \"${albumName}\".";

  static String m25(supportEmail) =>
      "Envie um e-mail para ${supportEmail} a partir do seu endereço de e-mail registado";

  static String m26(count, storageSaved) =>
      "Você limpou ${Intl.plural(count, one: '${count} arquivo duplicado', other: '${count} arquivos duplicados')}, guardando (${storageSaved}!)";

  static String m27(count, formattedSize) =>
      "${count} arquivos, ${formattedSize} cada";

  static String m28(name) => "Este e-mail já está ligado a ${name}.";

  static String m29(newEmail) => "Email alterado para ${newEmail}";

  static String m30(email) => "${email} não há uma conta no Ente.";

  static String m31(email) =>
      "${email} não possui uma conta Ente.\n\nEnvie um convite para compartilhar fotos.";

  static String m32(name) => "A abraçar ${name}";

  static String m33(text) => "Fotos extras encontradas para ${text}";

  static String m34(name) => "A comer com ${name}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 arquivo', other: '${formattedNumber} arquivos')} neste dispositivo teve um backup seguro";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 arquivo', other: '${formattedNumber} arquivos')} neste álbum teve um backup seguro";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB sempre que alguém se inscreve num plano pago e aplica o seu código";

  static String m38(endDate) => "Teste gratuito válido até ${endDate}";

  static String m39(count) =>
      "Ainda pode acessá${Intl.plural(count, one: '-lo', other: '-los')} no Ente contanto que tenha uma subscrição ativa";

  static String m40(sizeInMBorGB) => "Libertar ${sizeInMBorGB}";

  static String m41(count, formattedSize) =>
      "${Intl.plural(count, one: 'Pode eliminá-lo do aparelho para esvaziar ${formattedSize}', other: 'Pode eliminá-los do aparelho para esvaziar ${formattedSize}')}";

  static String m42(currentlyProcessing, totalCount) =>
      "Processando ${currentlyProcessing} / ${totalCount}";

  static String m43(name) => "Passeando com ${name}";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} item', other: '${count} itens')}";

  static String m45(name) => "Últimos momentos com ${name}";

  static String m46(email) =>
      "${email} convidou-lhe a ser um contacto de confiança";

  static String m47(expiryTime) => "O link expirará em ${expiryTime}";

  static String m48(email) => "Ligar pessoa a ${email}";

  static String m49(personName, email) =>
      "Isto ligará ${personName} a ${email}";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'não há memórias', one: '${formattedCount} memória', other: '${formattedCount} memórias')}";

  static String m51(count) =>
      "${Intl.plural(count, one: 'Mover item', other: 'Mover itens')}";

  static String m52(albumName) => "Movido com sucesso para ${albumName}";

  static String m53(personName) => "Sem sugestões para ${personName}";

  static String m54(name) => "Não é ${name}?";

  static String m55(familyAdminEmail) =>
      "Entre em contato com ${familyAdminEmail} para alterar o seu código.";

  static String m56(name) => "Tendo uma festa com ${name}";

  static String m57(passwordStrengthValue) =>
      "Força da palavra-passe: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Por favor, fale com o suporte ${providerName} se você foi cobrado";

  static String m59(name, age) => "${name} tem ${age} anos!";

  static String m60(name, age) => "${name} fará ${age} anos em breve";

  static String m61(count) =>
      "${Intl.plural(count, zero: 'Sem fotos', one: '1 foto', other: '${count} fotos')}";

  static String m62(count) =>
      "${Intl.plural(count, zero: '0 fotos', one: '1 foto', other: '${count} fotos')}";

  static String m63(endDate) =>
      "Teste gratuito válido até ${endDate}.\nVocê pode escolher um plano pago depois.";

  static String m64(toEmail) =>
      "Por favor, envie-nos um e-mail para ${toEmail}";

  static String m65(toEmail) => "Por favor, envie os logs para \n${toEmail}";

  static String m66(name) => "A posicionar com ${name}";

  static String m67(folderName) => "Processando ${folderName}...";

  static String m68(storeName) => "Avalie-nos em ${storeName}";

  static String m69(name) => "Retribuiu tu a ${name}";

  static String m70(days, email) =>
      "Pode acessar a conta após ${days} dias. Uma notificação será enviada para ${email}.";

  static String m71(email) =>
      "Agora pode recuperar a conta de ${email} definindo uma nova palavra-passe.";

  static String m72(email) => "${email} está a tentar recuperar a sua conta.";

  static String m73(storageInGB) => "3. Ambos ganham ${storageInGB} GB* grátis";

  static String m74(userEmail) =>
      "${userEmail} será removido deste álbum compartilhado\n\nQuaisquer fotos adicionadas por elas também serão removidas do álbum";

  static String m75(endDate) => "A subscrição é renovada em ${endDate}";

  static String m76(name) => "A viajar na rua com ${name}";

  static String m77(count) =>
      "${Intl.plural(count, one: '${count} ano atrás', other: '${count} anos atrás')}";

  static String m78(snapshotLength, searchLength) =>
      "Desigualdade de Largura entre Seções: ${snapshotLength} != ${searchLength}";

  static String m79(count) => "${count} selecionado(s)";

  static String m80(count) => "${count} selecionado(s)";

  static String m81(count, yourCount) =>
      "${count} selecionado(s) (${yourCount} seus)";

  static String m82(name) => "A captar selfies com ${name}";

  static String m83(verificationID) =>
      "Aqui está o meu ID de verificação: ${verificationID} para ente.io.";

  static String m84(verificationID) =>
      "Ei, você pode confirmar que este é seu ID de verificação do ente.io: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Insira o código de referência: ${referralCode} \n\nAplique-o em Configurações → Geral → Indicações para obter ${referralStorageInGB} GB gratuitamente após a sua inscrição para um plano pago\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Compartilhe com pessoas específicas', one: 'Compartilhado com 1 pessoa', other: 'Compartilhado com ${numberOfPeople} pessoas')}";

  static String m87(emailIDs) => "Partilhado com ${emailIDs}";

  static String m88(fileType) =>
      "Este ${fileType} será eliminado do seu dispositivo.";

  static String m89(fileType) =>
      "Este ${fileType} encontra-se tanto no Ente como no seu dispositivo.";

  static String m90(fileType) => "Este ${fileType} será eliminado do Ente.";

  static String m91(name) => "A praticar esportes com ${name}";

  static String m92(name) => "A dar destaque em ${name}";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m94(
    usedAmount,
    usedStorageUnit,
    totalAmount,
    totalStorageUnit,
  ) =>
      "${usedAmount} ${usedStorageUnit} de ${totalAmount} ${totalStorageUnit} usado";

  static String m95(id) =>
      "Seu ${id} já está vinculado a outra conta Ente.\nSe você gostaria de usar seu ${id} com esta conta, por favor contate nosso suporte\'\'";

  static String m96(endDate) => "A sua subscrição será cancelada em ${endDate}";

  static String m97(completed, total) =>
      "${completed}/${total} memórias preservadas";

  static String m98(ignoreReason) =>
      "Clique para enviar, o envio foi ignorado devido a ${ignoreReason}";

  static String m99(storageAmountInGB) =>
      "Eles também recebem ${storageAmountInGB} GB";

  static String m100(email) => "Este é o ID de verificação de ${email}";

  static String m101(count) =>
      "${Intl.plural(count, one: 'Esta semana, ${count} ano atrás', other: 'Esta semana, ${count} anos atrás')}";

  static String m102(dateFormat) => "${dateFormat} com o avanço dos anos";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Brevemente', one: '1 dia', other: '${count} dias')}";

  static String m104(year) => "Viajem em ${year}";

  static String m105(location) => "Viagem para ${location}";

  static String m106(email) =>
      "Foste convidado para ser um contacto revivido de ${email}.";

  static String m107(galleryType) =>
      "Tipo de galeria ${galleryType} não é permitido para renomear";

  static String m108(ignoreReason) => "Envio ignorado devido à ${ignoreReason}";

  static String m109(count) => "Preservar ${count} memórias...";

  static String m110(endDate) => "Válido até ${endDate}";

  static String m111(email) => "Verificar e-mail";

  static String m112(name) => "Ver ${name} para desligar";

  static String m113(count) =>
      "${Intl.plural(count, zero: 'Adicionado 0 vizualizadores', one: 'Adicionado 1 visualizador', other: 'Adicionado ${count} visualizadores')}";

  static String m114(email) =>
      "Enviamos um e-mail para <green>${email}</green>";

  static String m115(name) => "Envie um \"Felicidades\" a ${name}! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, one: '${count} ano atrás', other: '${count} anos atrás')}";

  static String m117(name) => "Tu e ${name}";

  static String m118(storageSaved) =>
      "Você liberou ${storageSaved} com sucesso!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
          "Está disponível uma nova versão do Ente.",
        ),
        "about": MessageLookupByLibrary.simpleMessage("Sobre"),
        "acceptTrustInvite": MessageLookupByLibrary.simpleMessage(
          "Aceite o Convite",
        ),
        "account": MessageLookupByLibrary.simpleMessage("Conta"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
          "A conta já está ajustada.",
        ),
        "accountOwnerPersonAppbarTitle": m0,
        "accountWelcomeBack": MessageLookupByLibrary.simpleMessage(
          "Boas-vindas de volta!",
        ),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
          "Eu entendo que se eu perder a minha palavra-passe, posso perder os meus dados já que esses dados são <underline> encriptados de ponta a ponta</underline>.",
        ),
        "actionNotSupportedOnFavouritesAlbum":
            MessageLookupByLibrary.simpleMessage(
          "Ação não suportada no álbum de Preferidos",
        ),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessões ativas"),
        "add": MessageLookupByLibrary.simpleMessage("Adicionar"),
        "addAName": MessageLookupByLibrary.simpleMessage("Adiciona um nome"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage(
          "Adicionar um novo e-mail",
        ),
        "addAlbumWidgetPrompt": MessageLookupByLibrary.simpleMessage(
          "Adiciona um widget de álbum no seu ecrã inicial e volte aqui para personalizar.",
        ),
        "addCollaborator": MessageLookupByLibrary.simpleMessage(
          "Adicionar colaborador",
        ),
        "addCollaborators": m1,
        "addFiles": MessageLookupByLibrary.simpleMessage("Adicionar Ficheiros"),
        "addFromDevice": MessageLookupByLibrary.simpleMessage(
          "Adicionar a partir do dispositivo",
        ),
        "addItem": m2,
        "addLocation": MessageLookupByLibrary.simpleMessage(
          "Adicionar localização",
        ),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Adicionar"),
        "addMemoriesWidgetPrompt": MessageLookupByLibrary.simpleMessage(
          "Adiciona um widget de memórias no seu ecrã inicial e volte aqui para personalizar.",
        ),
        "addMore": MessageLookupByLibrary.simpleMessage("Adicionar mais"),
        "addName": MessageLookupByLibrary.simpleMessage("Adicionar pessoa"),
        "addNameOrMerge": MessageLookupByLibrary.simpleMessage(
          "Adicionar nome ou juntar",
        ),
        "addNew": MessageLookupByLibrary.simpleMessage("Adicionar novo"),
        "addNewPerson": MessageLookupByLibrary.simpleMessage(
          "Adicionar nova pessoa",
        ),
        "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
          "Detalhes dos addons",
        ),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("addons"),
        "addParticipants": MessageLookupByLibrary.simpleMessage(
          "Adicionar participante",
        ),
        "addPeopleWidgetPrompt": MessageLookupByLibrary.simpleMessage(
          "Adiciona um widget de pessoas no seu ecrã inicial e volte aqui para personalizar.",
        ),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Adicionar fotos"),
        "addSelected": MessageLookupByLibrary.simpleMessage(
          "Adicionar selecionados",
        ),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Adicionar ao álbum"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Adicionar ao Ente"),
        "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
          "Adicionar a álbum oculto",
        ),
        "addTrustedContact": MessageLookupByLibrary.simpleMessage(
          "Adicionar Contacto de Confiança",
        ),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Adicionar visualizador"),
        "addViewers": m4,
        "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
          "Adicione suas fotos agora",
        ),
        "addedAs": MessageLookupByLibrary.simpleMessage("Adicionado como"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
          "Adicionando aos favoritos...",
        ),
        "admiringThem": m7,
        "advanced": MessageLookupByLibrary.simpleMessage("Avançado"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage(
          "Definições avançadas",
        ),
        "after1Day": MessageLookupByLibrary.simpleMessage("Depois de 1 dia"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Depois de 1 Hora"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Depois de 1 mês"),
        "after1Week":
            MessageLookupByLibrary.simpleMessage("Depois de 1 semana"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Depois de 1 ano"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Dono"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Título do álbum"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Álbum atualizado"),
        "albums": MessageLookupByLibrary.simpleMessage("Álbuns"),
        "albumsWidgetDesc": MessageLookupByLibrary.simpleMessage(
          "Seleciona os álbuns que adoraria ver no seu ecrã inicial.",
        ),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Tudo limpo"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
          "Todas as memórias preservadas",
        ),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
          "Todos os agrupamentos para esta pessoa serão reiniciados e perderá todas as sugestões feitas para esta pessoa",
        ),
        "allUnnamedGroupsWillBeMergedIntoTheSelectedPerson":
            MessageLookupByLibrary.simpleMessage(
          "Todos os grupos sem título serão fundidos na pessoa selecionada. Isso pode ser desfeito no histórico geral das sugestões da pessoa.",
        ),
        "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
          "Este é o primeiro neste grupo. Outras fotos selecionadas serão automaticamente alteradas para a nova data",
        ),
        "allow": MessageLookupByLibrary.simpleMessage("Permitir"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
          "Permitir que pessoas com o link também adicionem fotos ao álbum compartilhado.",
        ),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
          "Permitir adicionar fotos",
        ),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
          "Permitir Aplicação Abrir Ligações Partilhadas",
        ),
        "allowDownloads": MessageLookupByLibrary.simpleMessage(
          "Permitir downloads",
        ),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
          "Permitir que as pessoas adicionem fotos",
        ),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
          "Favor, permite acesso às fotos nas Definições para que Ente possa exibi-las e fazer backup na Fototeca.",
        ),
        "allowPermTitle": MessageLookupByLibrary.simpleMessage(
          "Garanta acesso às fotos",
        ),
        "androidBiometricHint": MessageLookupByLibrary.simpleMessage(
          "Verificar identidade",
        ),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
          "Não reconhecido. Tente novamente.",
        ),
        "androidBiometricRequiredTitle": MessageLookupByLibrary.simpleMessage(
          "Biometria necessária",
        ),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Sucesso"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
          "Credenciais do dispositivo são necessárias",
        ),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
          "Credenciais do dispositivo necessárias",
        ),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
          "A autenticação biométrica não está configurada no seu dispositivo. Vá a “Definições > Segurança” para adicionar a autenticação biométrica.",
        ),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
          "Android, iOS, Web, Desktop",
        ),
        "androidSignInTitle": MessageLookupByLibrary.simpleMessage(
          "Autenticação necessária",
        ),
        "appIcon": MessageLookupByLibrary.simpleMessage("Ícone da Aplicação"),
        "appLock": MessageLookupByLibrary.simpleMessage("Bloqueio de app"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
          "Escolha entre o ecrã de bloqueio predefinido do seu dispositivo e um ecrã de bloqueio personalizado com um PIN ou uma palavra-passe.",
        ),
        "appVersion": m9,
        "appleId": MessageLookupByLibrary.simpleMessage("ID da Apple"),
        "apply": MessageLookupByLibrary.simpleMessage("Aplicar"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Aplicar código"),
        "appstoreSubscription": MessageLookupByLibrary.simpleMessage(
          "Subscrição da AppStore",
        ),
        "archive": MessageLookupByLibrary.simpleMessage("............"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Arquivar álbum"),
        "archiving": MessageLookupByLibrary.simpleMessage("Arquivar..."),
        "areThey": MessageLookupByLibrary.simpleMessage("Eles são "),
        "areYouSureRemoveThisFaceFromPerson":
            MessageLookupByLibrary.simpleMessage(
          "Tem a certeza que queira remover o rosto desta pessoa?",
        ),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
          "Tem certeza que deseja sair do plano familiar?",
        ),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
          "Tem a certeza de que quer cancelar?",
        ),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
          "Tem a certeza de que pretende alterar o seu plano?",
        ),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
          "Tem certeza de que deseja sair?",
        ),
        "areYouSureYouWantToIgnoreThesePersons":
            MessageLookupByLibrary.simpleMessage(
          "Tem a certeza que quer ignorar estas pessoas?",
        ),
        "areYouSureYouWantToIgnoreThisPerson":
            MessageLookupByLibrary.simpleMessage(
          "Tem a certeza que quer ignorar esta pessoa?",
        ),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
          "Tem certeza que deseja terminar a sessão?",
        ),
        "areYouSureYouWantToMergeThem": MessageLookupByLibrary.simpleMessage(
          "Tem a certeza que quer fundi-los?",
        ),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
          "Tem a certeza de que pretende renovar?",
        ),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
          "Tens a certeza de que queres repor esta pessoa?",
        ),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
          "A sua subscrição foi cancelada. Gostaria de partilhar o motivo?",
        ),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
          "Por que quer eliminar a sua conta?",
        ),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
          "Peça aos seus entes queridos para partilharem",
        ),
        "atAFalloutShelter": MessageLookupByLibrary.simpleMessage(
          "em um abrigo avançado",
        ),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
          "Por favor, autentique-se para alterar a verificação de e-mail",
        ),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
          "Por favor, autentique-se para alterar a configuração da tela do ecrã de bloqueio",
        ),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
          "Por favor, autentique-se para alterar o seu e-mail",
        ),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
          "Por favor, autentique-se para alterar a palavra-passe",
        ),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
          "Por favor, autentique para configurar a autenticação de dois fatores",
        ),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
          "Autentique-se para iniciar a eliminação da conta",
        ),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
          "Autentica-se para gerir os seus contactos de confiança",
        ),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
          "Autentique-se para ver a sua chave de acesso",
        ),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
          "Autentica-se para visualizar os ficheiros na lata de lixo",
        ),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
          "Por favor, autentique-se para ver as suas sessões ativas",
        ),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
          "Por favor, autentique para ver seus arquivos ocultos",
        ),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
          "Por favor, autentique-se para ver suas memórias",
        ),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Por favor, autentique-se para ver a chave de recuperação",
        ),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("A Autenticar..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "Falha na autenticação, por favor tente novamente",
        ),
        "authenticationSuccessful": MessageLookupByLibrary.simpleMessage(
          "Autenticação bem sucedida!",
        ),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
          "Verá os dispositivos Cast disponíveis aqui.",
        ),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
          "Certifique-se de que as permissões de Rede local estão activadas para a aplicação Ente Photos, nas Definições.",
        ),
        "autoLock": MessageLookupByLibrary.simpleMessage("Bloqueio automático"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
          "Tempo após o qual a aplicação bloqueia depois de ser colocada em segundo plano",
        ),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
          "Devido a uma falha técnica, a sua sessão foi encerrada. Pedimos desculpas pelo incómodo.",
        ),
        "autoPair": MessageLookupByLibrary.simpleMessage(
          "Emparelhamento automático",
        ),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
          "O pareamento automático funciona apenas com dispositivos que suportam o Chromecast.",
        ),
        "available": MessageLookupByLibrary.simpleMessage("Disponível"),
        "availableStorageSpace": m10,
        "backedUpFolders": MessageLookupByLibrary.simpleMessage(
          "Pastas com cópia de segurança",
        ),
        "backgroundWithThem": m11,
        "backup": MessageLookupByLibrary.simpleMessage("Cópia de segurança"),
        "backupFailed": MessageLookupByLibrary.simpleMessage("Backup falhou"),
        "backupFile":
            MessageLookupByLibrary.simpleMessage("Backup de Ficheiro"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
          "Cópia de segurança através dos dados móveis",
        ),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
          "Definições da cópia de segurança",
        ),
        "backupStatus": MessageLookupByLibrary.simpleMessage(
          "Status da cópia de segurança",
        ),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
          "Os itens que foram salvos com segurança aparecerão aqui",
        ),
        "backupVideos": MessageLookupByLibrary.simpleMessage(
          "Cópia de segurança de vídeos",
        ),
        "beach": MessageLookupByLibrary.simpleMessage("A areia e o mar"),
        "birthday": MessageLookupByLibrary.simpleMessage("Aniversário"),
        "birthdayNotifications": MessageLookupByLibrary.simpleMessage(
          "Notificações de felicidades",
        ),
        "birthdays": MessageLookupByLibrary.simpleMessage("Aniversários"),
        "blackFridaySale": MessageLookupByLibrary.simpleMessage(
          "Promoção Black Friday",
        ),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cLDesc1": MessageLookupByLibrary.simpleMessage(
          "De volta aos vídeos em direto (beta), e a trabalhar em envios e transferências retomáveis, nós aumentamos o limite de envio de ficheiros para 10 GB. Isto está disponível para dispositivos Móveis e para Desktop.",
        ),
        "cLDesc2": MessageLookupByLibrary.simpleMessage(
          "Envios de fundo agora fornecerem suporte ao iOS. Para combinar com os aparelhos Android. Não precisa abrir a aplicação para fazer backup das fotos e vídeos recentes.",
        ),
        "cLDesc3": MessageLookupByLibrary.simpleMessage(
          "Nós fizemos melhorias significativas para a experiência das memórias, incluindo revisão automática, arrastar até a próxima memória e muito mais.",
        ),
        "cLDesc4": MessageLookupByLibrary.simpleMessage(
          "Junto a outras mudanças, agora facilitou a maneira de ver todos os rostos detetados, fornecer comentários para rostos similares, e adicionar ou remover rostos de uma foto única.",
        ),
        "cLDesc5": MessageLookupByLibrary.simpleMessage(
          "Ganhará uma notificação para todos os aniversários que salvaste no Ente, além de uma coleção das melhores fotos.",
        ),
        "cLDesc6": MessageLookupByLibrary.simpleMessage(
          "Sem mais aguardar até que os envios e transferências sejam concluídos para fechar a aplicação. Todos os envios e transferências podem ser pausados a qualquer momento, e retomar onde parou.",
        ),
        "cLTitle1": MessageLookupByLibrary.simpleMessage(
          "A Enviar Ficheiros de Vídeo Grandes",
        ),
        "cLTitle2": MessageLookupByLibrary.simpleMessage("Envio de Fundo"),
        "cLTitle3": MessageLookupByLibrary.simpleMessage(
          "Revisão automática de memórias",
        ),
        "cLTitle4": MessageLookupByLibrary.simpleMessage(
          "Reconhecimento Facial Melhorado",
        ),
        "cLTitle5": MessageLookupByLibrary.simpleMessage(
          "Notificações de Felicidade",
        ),
        "cLTitle6": MessageLookupByLibrary.simpleMessage(
          "Envios e transferências retomáveis",
        ),
        "cachedData": MessageLookupByLibrary.simpleMessage("Dados em cache"),
        "calculating": MessageLookupByLibrary.simpleMessage("Calcular..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
          "Perdão, portanto o álbum não pode ser aberto na aplicação.",
        ),
        "canNotOpenTitle": MessageLookupByLibrary.simpleMessage(
          "Não pôde abrir este álbum",
        ),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
          "Não é possível fazer upload para álbuns pertencentes a outros",
        ),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
          "Só pode criar um link para arquivos pertencentes a você",
        ),
        "canOnlyRemoveFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(""),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "cancelAccountRecovery": MessageLookupByLibrary.simpleMessage(
          "Cancelar recuperação",
        ),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
          "Quer mesmo cancelar a recuperação?",
        ),
        "cancelOtherSubscription": m12,
        "cancelSubscription": MessageLookupByLibrary.simpleMessage(
          "Cancelar subscrição",
        ),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
          "Não é possível eliminar ficheiros partilhados",
        ),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Transferir Álbum"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
          "Certifique-se de estar na mesma rede que a TV.",
        ),
        "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
          "Falha ao transmitir álbum",
        ),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
          "Visite cast.ente.io no dispositivo que pretende emparelhar.\n\n\nIntroduza o código abaixo para reproduzir o álbum na sua TV.",
        ),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Ponto central"),
        "change": MessageLookupByLibrary.simpleMessage("Alterar"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Alterar e-mail"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
          "Alterar a localização dos itens selecionados?",
        ),
        "changePassword": MessageLookupByLibrary.simpleMessage(
          "Alterar palavra-passe",
        ),
        "changePasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Alterar palavra-passe",
        ),
        "changePermissions": MessageLookupByLibrary.simpleMessage(
          "Alterar permissões",
        ),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
          "Alterar o código de referência",
        ),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage(
          "Procurar atualizações",
        ),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
          "Revê a sua caixa de entrada (e de spam) para concluir a verificação",
        ),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Verificar status"),
        "checking": MessageLookupByLibrary.simpleMessage("A verificar..."),
        "checkingModels": MessageLookupByLibrary.simpleMessage(
          "A verificar modelos...",
        ),
        "city": MessageLookupByLibrary.simpleMessage("Na cidade"),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
          "Solicitar armazenamento gratuito",
        ),
        "claimMore": MessageLookupByLibrary.simpleMessage("Reclamar mais!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Reclamado"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized": MessageLookupByLibrary.simpleMessage(
          "Limpar sem categoria",
        ),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
          "Remover todos os arquivos da Não Categorizados que estão presentes em outros álbuns",
        ),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Limpar cache"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Limpar índices"),
        "click": MessageLookupByLibrary.simpleMessage("Clique"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
          "• Clique no menu adicional",
        ),
        "clickToInstallOurBestVersionYet": MessageLookupByLibrary.simpleMessage(
          "Clica para transferir a melhor versão",
        ),
        "close": MessageLookupByLibrary.simpleMessage("Fechar"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
          "Agrupar por tempo de captura",
        ),
        "clubByFileName": MessageLookupByLibrary.simpleMessage(
          "Agrupar pelo nome de arquivo",
        ),
        "clusteringProgress": MessageLookupByLibrary.simpleMessage(
          "Progresso de agrupamento",
        ),
        "codeAppliedPageTitle": MessageLookupByLibrary.simpleMessage(
          "Código aplicado",
        ),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
          "Desculpe, você atingiu o limite de alterações de código.",
        ),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
          "Código copiado para área de transferência",
        ),
        "codeUsedByYou": MessageLookupByLibrary.simpleMessage(
          "Código usado por você",
        ),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
          "Criar um link para permitir que as pessoas adicionem e visualizem fotos em seu álbum compartilhado sem precisar de um aplicativo Ente ou conta. Ótimo para coletar fotos do evento.",
        ),
        "collaborativeLink": MessageLookupByLibrary.simpleMessage(
          "Link colaborativo",
        ),
        "collaborativeLinkCreatedFor": m15,
        "collaborator": MessageLookupByLibrary.simpleMessage("Colaborador"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
          "Os colaboradores podem adicionar fotos e vídeos ao álbum compartilhado.",
        ),
        "collaboratorsSuccessfullyAdded": m16,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Layout"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
          "Colagem guardada na galeria",
        ),
        "collect": MessageLookupByLibrary.simpleMessage("Recolher"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
          "Coletar fotos do evento",
        ),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Coletar fotos"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
          "Crie um link onde seus amigos podem enviar fotos na qualidade original.",
        ),
        "color": MessageLookupByLibrary.simpleMessage("Cor"),
        "configuration": MessageLookupByLibrary.simpleMessage("Configuração"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
          "Tem a certeza de que pretende desativar a autenticação de dois fatores?",
        ),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
          "Eliminar Conta",
        ),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
          "Sim, quero permanentemente eliminar esta conta com os dados.",
        ),
        "confirmPassword": MessageLookupByLibrary.simpleMessage(
          "Confirmar palavra-passe",
        ),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
          "Confirmar alteração de plano",
        ),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Confirmar chave de recuperação",
        ),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Confirmar chave de recuperação",
        ),
        "connectToDevice": MessageLookupByLibrary.simpleMessage(
          "Ligar ao dispositivo",
        ),
        "contactFamilyAdmin": m18,
        "contactSupport": MessageLookupByLibrary.simpleMessage(
          "Contactar o suporte",
        ),
        "contactToManageSubscription": m19,
        "contacts": MessageLookupByLibrary.simpleMessage("Contactos"),
        "contents": MessageLookupByLibrary.simpleMessage("Conteúdos"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuar"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
          "Continuar em teste gratuito",
        ),
        "convertToAlbum": MessageLookupByLibrary.simpleMessage(
          "Converter para álbum",
        ),
        "copyEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Copiar endereço de email",
        ),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copiar link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Copie e cole este código\nno seu aplicativo de autenticação",
        ),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
          "Não foi possível fazer o backup de seus dados.\nTentaremos novamente mais tarde.",
        ),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
          "Não foi possível libertar espaço",
        ),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
          "Não foi possível atualizar a subscrição",
        ),
        "count": MessageLookupByLibrary.simpleMessage("Contagem"),
        "crashReporting": MessageLookupByLibrary.simpleMessage(
          "Relatório de falhas",
        ),
        "create": MessageLookupByLibrary.simpleMessage("Criar"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Criar conta"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
          "Pressione e segure para selecionar fotos e clique em + para criar um álbum",
        ),
        "createCollaborativeLink": MessageLookupByLibrary.simpleMessage(
          "Criar link colaborativo",
        ),
        "createCollage": MessageLookupByLibrary.simpleMessage("Criar coleção"),
        "createNewAccount": MessageLookupByLibrary.simpleMessage(
          "Criar conta nova",
        ),
        "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage(
          "Criar ou selecionar álbum",
        ),
        "createPublicLink": MessageLookupByLibrary.simpleMessage(
          "Criar link público",
        ),
        "creatingLink": MessageLookupByLibrary.simpleMessage("Criar link..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
          "Atualização crítica disponível",
        ),
        "crop": MessageLookupByLibrary.simpleMessage("Recortar"),
        "curatedMemories":
            MessageLookupByLibrary.simpleMessage("Memórias curadas"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("O uso atual é "),
        "currentlyRunning": MessageLookupByLibrary.simpleMessage("em execução"),
        "custom": MessageLookupByLibrary.simpleMessage("Personalizado"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Escuro"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Hoje"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Ontem"),
        "declineTrustInvite": MessageLookupByLibrary.simpleMessage(
          "Dispense o Convite",
        ),
        "decrypting": MessageLookupByLibrary.simpleMessage("A desencriptar…"),
        "decryptingVideo": MessageLookupByLibrary.simpleMessage(
          "Descriptografando vídeo...",
        ),
        "deduplicateFiles": MessageLookupByLibrary.simpleMessage(
          "Arquivos duplicados",
        ),
        "delete": MessageLookupByLibrary.simpleMessage("Apagar"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Eliminar conta"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
          "Lamentável a sua ida. Favor, partilhe o seu comentário para ajudar-nos a aprimorar.",
        ),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
          "Eliminar Conta Permanentemente",
        ),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Apagar álbum"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
          "Eliminar também as fotos (e vídeos) presentes neste álbum de <bold>all</bold>  os outros álbuns de que fazem parte?",
        ),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
          "Esta ação elimina todos os álbuns vazios. Isto é útil quando pretende reduzir a confusão na sua lista de álbuns.",
        ),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Apagar tudo"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
          "Esta conta está ligada a outras aplicações Ente, se utilizar alguma. Os seus dados carregados, em todas as aplicações Ente, serão agendados para eliminação e a sua conta será permanentemente eliminada.",
        ),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
          "Favor, envie um e-mail a <warning>account-deletion@ente.io</warning> do e-mail registado.",
        ),
        "deleteEmptyAlbums": MessageLookupByLibrary.simpleMessage(
          "Apagar álbuns vazios",
        ),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage(
          "Apagar álbuns vazios?",
        ),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Apagar de ambos"),
        "deleteFromDevice": MessageLookupByLibrary.simpleMessage(
          "Apagar do dispositivo",
        ),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Apagar do Ente"),
        "deleteItemCount": m21,
        "deleteLocation": MessageLookupByLibrary.simpleMessage(
          "Apagar localização",
        ),
        "deleteMultipleAlbumDialog": m22,
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Apagar fotos"),
        "deleteProgress": m23,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
          "Necessita uma funcionalidade-chave que quero",
        ),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
          "A aplicação ou certa funcionalidade não comporta conforme o meu desejo",
        ),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
          "Possuo outro serviço que acho melhor",
        ),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
          "A razão não está listada",
        ),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
          "O pedido será revisto dentre 72 horas.",
        ),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
          "Excluir álbum compartilhado?",
        ),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
          "O álbum será apagado para todos\n\nVocê perderá o acesso a fotos compartilhadas neste álbum que são propriedade de outros",
        ),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar tudo"),
        "designedToOutlive": MessageLookupByLibrary.simpleMessage(
          "Feito para ter longevidade",
        ),
        "details": MessageLookupByLibrary.simpleMessage("Detalhes"),
        "developerSettings": MessageLookupByLibrary.simpleMessage(
          "Definições do programador",
        ),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
          "Tem a certeza de que pretende modificar as definições de programador?",
        ),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage(
          "Introduza o código",
        ),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
          "Os ficheiros adicionados a este álbum de dispositivo serão automaticamente transferidos para o Ente.",
        ),
        "deviceLock": MessageLookupByLibrary.simpleMessage(
          "Bloqueio do dispositivo",
        ),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
          "Desativar o bloqueio do ecrã do dispositivo quando o Ente estiver em primeiro plano e houver uma cópia de segurança em curso. Normalmente, isto não é necessário, mas pode ajudar a que os grandes carregamentos e as importações iniciais de grandes bibliotecas sejam concluídos mais rapidamente.",
        ),
        "deviceNotFound": MessageLookupByLibrary.simpleMessage(
          "Dispositivo não encontrado",
        ),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Você sabia?"),
        "different": MessageLookupByLibrary.simpleMessage("Diferente"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
          "Desativar bloqueio automático",
        ),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
          "Visualizadores ainda podem fazer capturas de tela ou salvar uma cópia das suas fotos usando ferramentas externas",
        ),
        "disableDownloadWarningTitle": MessageLookupByLibrary.simpleMessage(
          "Por favor, observe",
        ),
        "disableLinkMessage": m24,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
          "Desativar autenticação de dois fatores",
        ),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
          "Desativar a autenticação de dois factores...",
        ),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Descobrir"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Bebés"),
        "discover_celebrations": MessageLookupByLibrary.simpleMessage(
          "Comemorações",
        ),
        "discover_food": MessageLookupByLibrary.simpleMessage("Comida"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Vegetação"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Colinas"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identidade"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Memes"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Notas"),
        "discover_pets": MessageLookupByLibrary.simpleMessage(
          "Animais de estimação",
        ),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Recibos"),
        "discover_screenshots": MessageLookupByLibrary.simpleMessage(
          "Capturas de ecrã",
        ),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfies"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Pôr do sol"),
        "discover_visiting_cards": MessageLookupByLibrary.simpleMessage(
          "Cartões de visita",
        ),
        "discover_wallpapers": MessageLookupByLibrary.simpleMessage(
          "Papéis de parede",
        ),
        "dismiss": MessageLookupByLibrary.simpleMessage("Rejeitar"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage(
          "Não terminar a sessão",
        ),
        "doThisLater": MessageLookupByLibrary.simpleMessage(
          "Fazer isto mais tarde",
        ),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
          "Pretende eliminar as edições que efectuou?",
        ),
        "done": MessageLookupByLibrary.simpleMessage("Concluído"),
        "dontSave": MessageLookupByLibrary.simpleMessage("Não guarde"),
        "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
          "Duplicar o seu armazenamento",
        ),
        "download": MessageLookupByLibrary.simpleMessage("Download"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Falha no download"),
        "downloading": MessageLookupByLibrary.simpleMessage("A transferir..."),
        "dropSupportEmail": m25,
        "duplicateFileCountWithStorageSaved": m26,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Editar"),
        "editEmailAlreadyLinked": m28,
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Editar localização"),
        "editLocationTagTitle": MessageLookupByLibrary.simpleMessage(
          "Editar localização",
        ),
        "editPerson": MessageLookupByLibrary.simpleMessage("Editar pessoa"),
        "editTime": MessageLookupByLibrary.simpleMessage("Editar tempo"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Edição guardada"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
          "Edições para localização só serão vistas dentro do Ente",
        ),
        "eligible": MessageLookupByLibrary.simpleMessage("elegível"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
          "E-mail já em utilização.",
        ),
        "emailChangedTo": m29,
        "emailDoesNotHaveEnteAccount": m30,
        "emailNoEnteAccount": m31,
        "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
          "E-mail não em utilização.",
        ),
        "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
          "Verificação por e-mail",
        ),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
          "Enviar logs por e-mail",
        ),
        "embracingThem": m32,
        "emergencyContacts": MessageLookupByLibrary.simpleMessage(
          "Contactos de Emergência",
        ),
        "empty": MessageLookupByLibrary.simpleMessage("Esvaziar"),
        "emptyTrash": MessageLookupByLibrary.simpleMessage("Esvaziar lixo?"),
        "enable": MessageLookupByLibrary.simpleMessage("Ativar"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
          "O Ente suporta a aprendizagem automática no dispositivo para reconhecimento facial, pesquisa mágica e outras funcionalidades de pesquisa avançadas",
        ),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
          "Habilitar aprendizagem automática para pesquisa mágica e reconhecimento de rosto",
        ),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Ativar mapas"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
          "Esta opção mostra as suas fotografias num mapa do mundo.\n\n\nEste mapa é alojado pelo Open Street Map e as localizações exactas das suas fotografias nunca são partilhadas.\n\n\nPode desativar esta funcionalidade em qualquer altura nas Definições.",
        ),
        "enabled": MessageLookupByLibrary.simpleMessage("Ativado"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
          "Criptografando backup...",
        ),
        "encryption": MessageLookupByLibrary.simpleMessage("Encriptação"),
        "encryptionKeys": MessageLookupByLibrary.simpleMessage(
          "Chaves de encriptação",
        ),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
          "Endpoint atualizado com sucesso",
        ),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
          "Criptografia de ponta a ponta por padrão",
        ),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
          "Ente pode criptografar e preservar arquivos apenas se você conceder acesso a eles",
        ),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
          "Ente <i>precisa da permissão para</i> preservar as suas fotos",
        ),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
          "O Ente preserva as suas memórias, para que estejam sempre disponíveis, mesmo que perca o seu dispositivo.",
        ),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
          "Sua família também pode ser adicionada ao seu plano.",
        ),
        "enterAlbumName": MessageLookupByLibrary.simpleMessage(
          "Introduzir nome do álbum",
        ),
        "enterCode": MessageLookupByLibrary.simpleMessage("Insira o código"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
          "Introduza o código fornecido pelo seu amigo para obter armazenamento gratuito para ambos",
        ),
        "enterDateOfBirth": MessageLookupByLibrary.simpleMessage(
          "Aniversário (opcional)",
        ),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Digite o e-mail"),
        "enterFileName": MessageLookupByLibrary.simpleMessage(
          "Inserir nome do arquivo",
        ),
        "enterName": MessageLookupByLibrary.simpleMessage("Inserir nome"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
          "Inserir uma nova palavra-passe para encriptar os seus dados",
        ),
        "enterPassword": MessageLookupByLibrary.simpleMessage(
          "Introduzir palavra-passe",
        ),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
          "Inserir uma palavra-passe para encriptar os seus dados",
        ),
        "enterPersonName": MessageLookupByLibrary.simpleMessage(
          "Inserir nome da pessoa",
        ),
        "enterPin": MessageLookupByLibrary.simpleMessage("Introduzir PIN"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
          "Insira o código de referência",
        ),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Introduzir o código de 6 dígitos da\nsua aplicação de autenticação",
        ),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
          "Favor, introduz um e-mail válido.",
        ),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Introduza o seu e-mail",
        ),
        "enterYourNewEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Introduza o seu novo e-mail",
        ),
        "enterYourPassword": MessageLookupByLibrary.simpleMessage(
          "Introduza a sua palavra-passe",
        ),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Introduz a sua chave de recuperação",
        ),
        "error": MessageLookupByLibrary.simpleMessage("Erro"),
        "everywhere": MessageLookupByLibrary.simpleMessage("em todo o lado"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser": MessageLookupByLibrary.simpleMessage(
          "Utilizador existente",
        ),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
          "Este link expirou. Por favor, selecione um novo tempo de expiração ou desabilite a expiração do link.",
        ),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Exportar logs"),
        "exportYourData": MessageLookupByLibrary.simpleMessage(
          "Exportar os seus dados",
        ),
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
          "Fotos adicionais encontradas",
        ),
        "extraPhotosFoundFor": m33,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
          "Rosto não aglomerado ainda, retome mais tarde",
        ),
        "faceRecognition": MessageLookupByLibrary.simpleMessage(
          "Reconhecimento facial",
        ),
        "faceThumbnailGenerationFailed": MessageLookupByLibrary.simpleMessage(
          "Impossível gerar thumbnails de rosto",
        ),
        "faces": MessageLookupByLibrary.simpleMessage("Rostos"),
        "failed": MessageLookupByLibrary.simpleMessage("Falha"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
          "Falha ao aplicar código",
        ),
        "failedToCancel": MessageLookupByLibrary.simpleMessage(
          "Falhou ao cancelar",
        ),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
          "Falha ao fazer o download do vídeo",
        ),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
          "Falha ao obter sessões em atividade",
        ),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
          "Falha ao obter original para edição",
        ),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
          "Não foi possível obter detalhes de indicação. Por favor, tente novamente mais tarde.",
        ),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
          "Falha ao carregar álbuns",
        ),
        "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
          "Falha ao reproduzir multimédia",
        ),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
          "Falha ao atualizar subscrição",
        ),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Falhou ao renovar"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
          "Falha ao verificar status do pagamento",
        ),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
          "Adicione 5 membros da família ao seu plano existente sem pagar mais.\n\n\nCada membro tem o seu próprio espaço privado e não pode ver os ficheiros dos outros, a menos que sejam partilhados.\n\n\nOs planos familiares estão disponíveis para clientes que tenham uma subscrição paga do Ente.\n\n\nSubscreva agora para começar!",
        ),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Família"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Planos familiares"),
        "faq": MessageLookupByLibrary.simpleMessage("Perguntas Frequentes"),
        "faqs": MessageLookupByLibrary.simpleMessage("Perguntas frequentes"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorito"),
        "feastingWithThem": m34,
        "feedback": MessageLookupByLibrary.simpleMessage("Comentário"),
        "file": MessageLookupByLibrary.simpleMessage("Ficheiro"),
        "fileAnalysisFailed": MessageLookupByLibrary.simpleMessage(
          "Impossível analisar arquivo",
        ),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
          "Falha ao guardar o ficheiro na galeria",
        ),
        "fileInfoAddDescHint": MessageLookupByLibrary.simpleMessage(
          "Acrescente uma descrição...",
        ),
        "fileNotUploadedYet": MessageLookupByLibrary.simpleMessage(
          "Ficheiro não enviado ainda",
        ),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
          "Arquivo guardado na galeria",
        ),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Tipos de arquivo"),
        "fileTypesAndNames": MessageLookupByLibrary.simpleMessage(
          "Tipos de arquivo e nomes",
        ),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Arquivos apagados"),
        "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
          "Arquivos guardados na galeria",
        ),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
          "Encontrar pessoas rapidamente pelo nome",
        ),
        "findThemQuickly": MessageLookupByLibrary.simpleMessage(
          "Ache-os rapidamente",
        ),
        "flip": MessageLookupByLibrary.simpleMessage("Inverter"),
        "food": MessageLookupByLibrary.simpleMessage("Culinária saborosa"),
        "forYourMemories": MessageLookupByLibrary.simpleMessage(
          "para suas memórias",
        ),
        "forgotPassword": MessageLookupByLibrary.simpleMessage(
          "Não recordo a palavra-passe",
        ),
        "foundFaces":
            MessageLookupByLibrary.simpleMessage("Rostos encontrados"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
          "Armazenamento gratuito reclamado",
        ),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
          "Armazenamento livre utilizável",
        ),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Teste grátis"),
        "freeTrialValidTill": m38,
        "freeUpAccessPostDelete": m39,
        "freeUpAmount": m40,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
          "Libertar espaço no dispositivo",
        ),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
          "Poupe espaço no seu dispositivo limpando ficheiros dos quais já foi feita uma cópia de segurança.",
        ),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Libertar espaço"),
        "freeUpSpaceSaving": m41,
        "gallery": MessageLookupByLibrary.simpleMessage("Galeria"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
          "Até 1000 memórias mostradas na galeria",
        ),
        "general": MessageLookupByLibrary.simpleMessage("Geral"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
          "Gerando chaves de encriptação...",
        ),
        "genericProgress": m42,
        "goToSettings": MessageLookupByLibrary.simpleMessage(
          "Ir para as definições",
        ),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("ID do Google Play"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
          "Por favor, permita o acesso a todas as fotos nas definições do aplicativo",
        ),
        "grantPermission": MessageLookupByLibrary.simpleMessage(
          "Conceder permissão",
        ),
        "greenery": MessageLookupByLibrary.simpleMessage("A vida esverdeada"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
          "Agrupar fotos próximas",
        ),
        "guestView": MessageLookupByLibrary.simpleMessage("Visão de convidado"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
          "Para ativar a vista de convidado, configure o código de acesso do dispositivo ou o bloqueio do ecrã nas definições do sistema.",
        ),
        "happyBirthday":
            MessageLookupByLibrary.simpleMessage("Felicidades! 🥳"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
          "Não monitorizamos as instalações de aplicações. Ajudaria se nos dissesse onde nos encontrou!",
        ),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
          "Como é que soube do Ente? (opcional)",
        ),
        "help": MessageLookupByLibrary.simpleMessage("Ajuda"),
        "hidden": MessageLookupByLibrary.simpleMessage("Oculto"),
        "hide": MessageLookupByLibrary.simpleMessage("Ocultar"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Ocultar conteúdo"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
          "Oculta o conteúdo da aplicação no alternador de aplicações e desactiva as capturas de ecrã",
        ),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
          "Oculta o conteúdo da aplicação no alternador de aplicações",
        ),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
          "Esconder Itens Partilhados da Galeria Inicial",
        ),
        "hiding": MessageLookupByLibrary.simpleMessage("Ocultando..."),
        "hikingWithThem": m43,
        "hostedAtOsmFrance": MessageLookupByLibrary.simpleMessage(
          "Hospedado na OSM France",
        ),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Como funciona"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
          "Por favor, peça-lhes para pressionar longamente o endereço de e-mail na tela de configurações e verifique se os IDs de ambos os dispositivos coincidem.",
        ),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
          "A autenticação biométrica não está configurada no seu dispositivo. Active o Touch ID ou o Face ID no seu telemóvel.",
        ),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
          "A autenticação biométrica está desativada. Por favor, bloqueie e desbloqueie o ecrã para ativá-la.",
        ),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignore": MessageLookupByLibrary.simpleMessage("Ignorar"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorar"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignorado"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
          "Alguns ficheiros deste álbum não podem ser carregados porque foram anteriormente eliminados do Ente.",
        ),
        "imageNotAnalyzed": MessageLookupByLibrary.simpleMessage(
          "Imagem sem análise",
        ),
        "immediately": MessageLookupByLibrary.simpleMessage("Imediatamente"),
        "importing": MessageLookupByLibrary.simpleMessage("A importar..."),
        "incorrectCode":
            MessageLookupByLibrary.simpleMessage("Código incorrecto"),
        "incorrectPasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Palavra-passe incorreta",
        ),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Chave de recuperação incorreta",
        ),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
          "A chave de recuperação introduzida está incorreta",
        ),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
          "Chave de recuperação incorreta",
        ),
        "indexedItems": MessageLookupByLibrary.simpleMessage("Itens indexados"),
        "indexingPausedStatusDescription": MessageLookupByLibrary.simpleMessage(
          "A indexação foi interrompida. Ele será retomado se o dispositivo estiver pronto. O dispositivo é considerado pronto se o nível de bateria, saúde da bateria, e estado térmico esteja num estado saudável.",
        ),
        "ineligible": MessageLookupByLibrary.simpleMessage("Inelegível"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage(
          "Dispositivo inseguro",
        ),
        "installManually": MessageLookupByLibrary.simpleMessage(
          "Instalar manualmente",
        ),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
          "E-mail inválido",
        ),
        "invalidEndpoint": MessageLookupByLibrary.simpleMessage(
          "Endpoint inválido",
        ),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
          "Desculpe, o endpoint que introduziu é inválido. Introduza um ponto final válido e tente novamente.",
        ),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Chave inválida"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "A chave de recuperação que inseriu não é válida. Por favor, certifique-se que ela contém 24 palavras e verifique a ortografia de cada uma.\n\nSe inseriu um código de recuperação mais antigo, certifique-se de que tem 64 caracteres e verifique cada um deles.",
        ),
        "invite": MessageLookupByLibrary.simpleMessage("Convidar"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Convidar para Ente"),
        "inviteYourFriends": MessageLookupByLibrary.simpleMessage(
          "Convide os seus amigos",
        ),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
          "Convide seus amigos para o Ente",
        ),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
          "Parece que algo correu mal. Por favor, tente novamente após algum tempo. Se o erro persistir, contacte a nossa equipa de apoio.",
        ),
        "itemCount": m44,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
          "Os itens mostram o número de dias restantes antes da eliminação permanente",
        ),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
          "Os itens selecionados serão removidos deste álbum",
        ),
        "join": MessageLookupByLibrary.simpleMessage("Aderir"),
        "joinAlbum": MessageLookupByLibrary.simpleMessage("Aderir ao Álbum"),
        "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
          "Aderir a um álbum fará o seu e-mail visível aos participantes.",
        ),
        "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
          "para ver e adicionar as suas fotos",
        ),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
          "para adicionar isto aos álbuns partilhados",
        ),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Juntar-se ao Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Manter fotos"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
          "Ajude-nos com esta informação",
        ),
        "language": MessageLookupByLibrary.simpleMessage("Idioma"),
        "lastTimeWithThem": m45,
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Última atualização"),
        "lastYearsTrip": MessageLookupByLibrary.simpleMessage(
          "Viagem do ano passado",
        ),
        "leave": MessageLookupByLibrary.simpleMessage("Sair"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Sair do álbum"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage(
          "Deixar plano famíliar",
        ),
        "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
          "Sair do álbum compartilhado?",
        ),
        "left": MessageLookupByLibrary.simpleMessage("Esquerda"),
        "legacy": MessageLookupByLibrary.simpleMessage("Revivência"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Contas revividas"),
        "legacyInvite": m46,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
          "A Revivência permite que contactos de confiança acessem a sua conta na sua inatividade.",
        ),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
          "Contactos de confiança podem restaurar a sua conta, e se não lhes impedir em 30 dias, redefine a sua palavra-passe e acesse a sua conta.",
        ),
        "light": MessageLookupByLibrary.simpleMessage("Claro"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Claro"),
        "link": MessageLookupByLibrary.simpleMessage("Ligar"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
          "Link copiado para a área de transferência",
        ),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage(
          "Limite de dispositivo",
        ),
        "linkEmail": MessageLookupByLibrary.simpleMessage("Ligar e-mail"),
        "linkEmailToContactBannerCaption": MessageLookupByLibrary.simpleMessage(
          "para partilha ágil",
        ),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Ativado"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expirado"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Link expirado"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("O link expirou"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Nunca"),
        "linkPerson": MessageLookupByLibrary.simpleMessage("Ligar pessoa"),
        "linkPersonCaption": MessageLookupByLibrary.simpleMessage(
          "para melhor experiência de partilha",
        ),
        "linkPersonToEmail": m48,
        "linkPersonToEmailConfirmation": m49,
        "livePhotos":
            MessageLookupByLibrary.simpleMessage("Fotos Em Tempo Real"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
          "Pode partilhar a sua subscrição com a sua família",
        ),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
          "Já contivemos 200 milhões de memórias até o momento",
        ),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
          "Mantemos 3 cópias dos seus dados, uma em um abrigo subterrâneo",
        ),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
          "Todos os nossos aplicativos são de código aberto",
        ),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
          "Nosso código-fonte e criptografia foram auditadas externamente",
        ),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
          "Deixar o álbum partilhado?",
        ),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
          "Nossos aplicativos móveis são executados em segundo plano para criptografar e fazer backup de quaisquer novas fotos que você clique",
        ),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
          "web.ente.io tem um envio mais rápido",
        ),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
          "Nós usamos Xchacha20Poly1305 para criptografar seus dados com segurança",
        ),
        "loadingExifData": MessageLookupByLibrary.simpleMessage(
          "Carregando dados EXIF...",
        ),
        "loadingGallery": MessageLookupByLibrary.simpleMessage(
          "Carregando galeria...",
        ),
        "loadingMessage": MessageLookupByLibrary.simpleMessage(
          "Carregar as suas fotos...",
        ),
        "loadingModel": MessageLookupByLibrary.simpleMessage(
          "Transferindo modelos...",
        ),
        "loadingYourPhotos": MessageLookupByLibrary.simpleMessage(
          "Carregar as suas fotos...",
        ),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galeria local"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Indexação local"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
          "Parece que algo correu mal, uma vez que a sincronização de fotografias locais está a demorar mais tempo do que o esperado. Contacte a nossa equipa de apoio",
        ),
        "location": MessageLookupByLibrary.simpleMessage("Localização"),
        "locationName":
            MessageLookupByLibrary.simpleMessage("Nome da localização"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
          "Uma etiqueta de localização agrupa todas as fotos que foram tiradas num determinado raio de uma fotografia",
        ),
        "locations": MessageLookupByLibrary.simpleMessage("Localizações"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Bloquear"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Ecrã de bloqueio"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Iniciar sessão"),
        "loggingOut":
            MessageLookupByLibrary.simpleMessage("Terminar a sessão..."),
        "loginSessionExpired": MessageLookupByLibrary.simpleMessage(
          "Sessão expirada",
        ),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
          "A sua sessão expirou. Por favor, inicie sessão novamente.",
        ),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
          "Ao clicar em iniciar sessão, eu concordo com os termos <u-terms>de serviço</u-terms> e <u-policy>política de privacidade</u-policy>",
        ),
        "loginWithTOTP": MessageLookupByLibrary.simpleMessage(
          "Iniciar sessão com TOTP",
        ),
        "logout": MessageLookupByLibrary.simpleMessage("Terminar sessão"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
          "Isto enviará os registos para nos ajudar a resolver o problema. Tenha em atenção que os nomes dos ficheiros serão incluídos para ajudar a localizar problemas com ficheiros específicos.",
        ),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
          "Pressione e segure um e-mail para verificar a criptografia de ponta a ponta.",
        ),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
          "Pressione e segure em um item para ver em tela cheia",
        ),
        "lookBackOnYourMemories": MessageLookupByLibrary.simpleMessage(
          "Revê as suas memórias 🌄",
        ),
        "loopVideoOff": MessageLookupByLibrary.simpleMessage(
          "Repetir vídeo desligado",
        ),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("Repetir vídeo ligado"),
        "lostDevice": MessageLookupByLibrary.simpleMessage(
          "Perdeu o seu dispositívo?",
        ),
        "machineLearning": MessageLookupByLibrary.simpleMessage(
          "Aprendizagem automática",
        ),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Pesquisa mágica"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
          "A pesquisa mágica permite pesquisar fotos por seu conteúdo, por exemplo, \'flor\', \'carro vermelho\', \'documentos de identidade\'",
        ),
        "manage": MessageLookupByLibrary.simpleMessage("Gerir"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
          "Gerir cache do aparelho",
        ),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
          "Reveja e limpe o armazenamento de cache local.",
        ),
        "manageFamily": MessageLookupByLibrary.simpleMessage("Gerir família"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Gerir link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Gerir"),
        "manageSubscription": MessageLookupByLibrary.simpleMessage(
          "Gerir subscrição",
        ),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
          "Emparelhar com PIN funciona com qualquer ecrã onde pretenda ver o seu álbum.",
        ),
        "map": MessageLookupByLibrary.simpleMessage("Mapa"),
        "maps": MessageLookupByLibrary.simpleMessage("Mapas"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "me": MessageLookupByLibrary.simpleMessage("Eu"),
        "memories": MessageLookupByLibrary.simpleMessage("Memórias"),
        "memoriesWidgetDesc": MessageLookupByLibrary.simpleMessage(
          "Seleciona os tipos de memórias que adoraria ver no seu ecrã inicial.",
        ),
        "memoryCount": m50,
        "merchandise": MessageLookupByLibrary.simpleMessage("Produtos"),
        "merge": MessageLookupByLibrary.simpleMessage("Fundir"),
        "mergeWithExisting": MessageLookupByLibrary.simpleMessage(
          "Juntar com o existente",
        ),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Fotos combinadas"),
        "mlConsent": MessageLookupByLibrary.simpleMessage(
          "Ativar aprendizagem automática",
        ),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
          "Eu entendo, e desejo ativar a aprendizagem automática",
        ),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
          "Se ativar a aprendizagem automática, o Ente extrairá informações como a geometria do rosto de ficheiros, incluindo os partilhados consigo.\n\n\nIsto acontecerá no seu dispositivo e todas as informações biométricas geradas serão encriptadas de ponta a ponta.",
        ),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
          "Por favor, clique aqui para mais detalhes sobre este recurso na nossa política de privacidade",
        ),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
          "Ativar aprendizagem automática?",
        ),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
          "Tenha em atenção que a aprendizagem automática resultará numa maior utilização da largura de banda e da bateria até que todos os itens sejam indexados. Considere utilizar a aplicação de ambiente de trabalho para uma indexação mais rápida, todos os resultados serão sincronizados automaticamente.",
        ),
        "mobileWebDesktop": MessageLookupByLibrary.simpleMessage(
          "Mobile, Web, Desktop",
        ),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderada"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
          "Modifique a sua consulta ou tente pesquisar por",
        ),
        "moments": MessageLookupByLibrary.simpleMessage("Momentos"),
        "month": MessageLookupByLibrary.simpleMessage("mês"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensal"),
        "moon": MessageLookupByLibrary.simpleMessage("Na luz da lua"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Mais detalhes"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Mais recente"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Mais relevante"),
        "mountains": MessageLookupByLibrary.simpleMessage("Sobre as colinas"),
        "moveItem": m51,
        "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
          "Alterar datas de Fotos ao Selecionado",
        ),
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Mover para álbum"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
          "Mover para álbum oculto",
        ),
        "movedSuccessfullyTo": m52,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Mover para o lixo"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
          "Mover arquivos para o álbum...",
        ),
        "name": MessageLookupByLibrary.simpleMessage("Nome"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Nomear o álbum"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
          "Não foi possível conectar ao Ente, tente novamente após algum tempo. Se o erro persistir, entre em contato com o suporte.",
        ),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
          "Não foi possível estabelecer ligação ao Ente. Verifique as definições de rede e contacte o serviço de apoio se o erro persistir.",
        ),
        "never": MessageLookupByLibrary.simpleMessage("Nunca"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Novo álbum"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Novo Lugar"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Nova pessoa"),
        "newPhotosEmoji": MessageLookupByLibrary.simpleMessage(" novo 📸"),
        "newRange": MessageLookupByLibrary.simpleMessage("Novo intervalo"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Novo no Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Recentes"),
        "next": MessageLookupByLibrary.simpleMessage("Seguinte"),
        "no": MessageLookupByLibrary.simpleMessage("Não"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
          "Ainda não há álbuns partilhados por si",
        ),
        "noDeviceFound": MessageLookupByLibrary.simpleMessage(
          "Nenhum dispositivo encontrado",
        ),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Nenhum"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
          "Você não tem arquivos neste dispositivo que possam ser apagados",
        ),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Sem duplicados"),
        "noEnteAccountExclamation": MessageLookupByLibrary.simpleMessage(
          "Nenhuma conta do Ente!",
        ),
        "noExifData": MessageLookupByLibrary.simpleMessage("Sem dados EXIF"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage(
          "Nenhum rosto foi detetado",
        ),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
          "Sem fotos ou vídeos ocultos",
        ),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
          "Nenhuma imagem com localização",
        ),
        "noInternetConnection": MessageLookupByLibrary.simpleMessage(
          "Sem ligação à internet",
        ),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
          "No momento não há backup de fotos sendo feito",
        ),
        "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage(
          "Nenhuma foto encontrada aqui",
        ),
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
          "Nenhum link rápido selecionado",
        ),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Sem chave de recuperação?",
        ),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
          "Por conta da natureza do nosso protocolo de encriptação, os seus dados não podem ser desencriptados sem a sua palavra-passe ou chave de recuperação.",
        ),
        "noResults": MessageLookupByLibrary.simpleMessage("Nenhum resultado"),
        "noResultsFound": MessageLookupByLibrary.simpleMessage(
          "Não foram encontrados resultados",
        ),
        "noSuggestionsForPerson": m53,
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
          "Nenhum bloqueio de sistema encontrado",
        ),
        "notPersonLabel": m54,
        "notThisPerson":
            MessageLookupByLibrary.simpleMessage("Não é esta pessoa?"),
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
          "Ainda nada partilhado consigo",
        ),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
          "Nada para ver aqui! 👀",
        ),
        "notifications": MessageLookupByLibrary.simpleMessage("Notificações"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "onDevice": MessageLookupByLibrary.simpleMessage("No dispositivo"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
          "Em <branding>ente</branding>",
        ),
        "onTheRoad": MessageLookupByLibrary.simpleMessage("Na rua de novo"),
        "onThisDay": MessageLookupByLibrary.simpleMessage("Neste dia"),
        "onThisDayMemories": MessageLookupByLibrary.simpleMessage(
          "Memórias deste dia",
        ),
        "onThisDayNotificationExplanation":
            MessageLookupByLibrary.simpleMessage(
          "Obtém lembretes de memórias deste dia em anos passados.",
        ),
        "onlyFamilyAdminCanChangeCode": m55,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Apenas eles"),
        "oops": MessageLookupByLibrary.simpleMessage("Ops"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
          "Oops, não foi possível guardar as edições",
        ),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
          "Ops, algo deu errado",
        ),
        "openAlbumInBrowser": MessageLookupByLibrary.simpleMessage(
          "Abrir o Álbum em Navegador",
        ),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
          "Utilize a Aplicação de Web Sítio para adicionar fotos ao álbum",
        ),
        "openFile": MessageLookupByLibrary.simpleMessage("Abrir o Ficheiro"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Abrir Definições"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Abra o item"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
          "Contribuidores do OpenStreetMap",
        ),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
          "Opcional, o mais breve que quiser...",
        ),
        "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
          "Ou combinar com já existente",
        ),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
          "Ou escolha um já existente",
        ),
        "orPickFromYourContacts": MessageLookupByLibrary.simpleMessage(
          "ou selecione dos seus contactos",
        ),
        "otherDetectedFaces": MessageLookupByLibrary.simpleMessage(
          "Outros rostos detetados",
        ),
        "pair": MessageLookupByLibrary.simpleMessage("Emparelhar"),
        "pairWithPin":
            MessageLookupByLibrary.simpleMessage("Emparelhar com PIN"),
        "pairingComplete": MessageLookupByLibrary.simpleMessage(
          "Emparelhamento concluído",
        ),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "partyWithThem": m56,
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
          "A verificação ainda está pendente",
        ),
        "passkey": MessageLookupByLibrary.simpleMessage("Chave de acesso"),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
          "Verificação da chave de acesso",
        ),
        "password": MessageLookupByLibrary.simpleMessage("Palavra-passe"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
          "Palavra-passe alterada com sucesso",
        ),
        "passwordLock": MessageLookupByLibrary.simpleMessage(
          "Bloqueio da palavra-passe",
        ),
        "passwordStrength": m57,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
          "A força da palavra-passe é calculada tendo em conta o comprimento da palavra-passe, os caracteres utilizados e se a palavra-passe aparece ou não nas 10.000 palavras-passe mais utilizadas",
        ),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
          "Não armazenamos esta palavra-passe, se você a esquecer, <underline>não podemos desencriptar os seus dados</underline>",
        ),
        "pastYearsMemories": MessageLookupByLibrary.simpleMessage(
          "Memórias de anos passados",
        ),
        "paymentDetails": MessageLookupByLibrary.simpleMessage(
          "Detalhes de pagamento",
        ),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("O pagamento falhou"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
          "Infelizmente o seu pagamento falhou. Entre em contato com o suporte e nós ajudaremos você!",
        ),
        "paymentFailedTalkToProvider": m58,
        "pendingItems": MessageLookupByLibrary.simpleMessage("Itens pendentes"),
        "pendingSync": MessageLookupByLibrary.simpleMessage(
          "Sincronização pendente",
        ),
        "people": MessageLookupByLibrary.simpleMessage("Pessoas"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
          "Pessoas que utilizam seu código",
        ),
        "peopleWidgetDesc": MessageLookupByLibrary.simpleMessage(
          "Seleciona as pessoas que adoraria ver no seu ecrã inicial.",
        ),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
          "Todos os itens no lixo serão permanentemente eliminados\n\n\nEsta ação não pode ser anulada",
        ),
        "permanentlyDelete": MessageLookupByLibrary.simpleMessage(
          "Eliminar permanentemente",
        ),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
          "Apagar permanentemente do dispositivo?",
        ),
        "personIsAge": m59,
        "personName": MessageLookupByLibrary.simpleMessage("Nome da pessoa"),
        "personTurningAge": m60,
        "pets": MessageLookupByLibrary.simpleMessage("Acompanhantes peludos"),
        "photoDescriptions": MessageLookupByLibrary.simpleMessage(
          "Descrições das fotos",
        ),
        "photoGridSize": MessageLookupByLibrary.simpleMessage(
          "Tamanho da grelha de fotos",
        ),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "photocountPhotos": m61,
        "photos": MessageLookupByLibrary.simpleMessage("Fotos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
          "As fotos adicionadas por si serão removidas do álbum",
        ),
        "photosCount": m62,
        "photosKeepRelativeTimeDifference":
            MessageLookupByLibrary.simpleMessage(
          "As Fotos continuam com uma diferença de horário relativo",
        ),
        "pickCenterPoint": MessageLookupByLibrary.simpleMessage(
          "Escolha o ponto central",
        ),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Fixar álbum"),
        "pinLock": MessageLookupByLibrary.simpleMessage("Bloqueio por PIN"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Reproduzir álbum na TV"),
        "playOriginal": MessageLookupByLibrary.simpleMessage("Ver original"),
        "playStoreFreeTrialValidTill": m63,
        "playStream": MessageLookupByLibrary.simpleMessage("Ver em direto"),
        "playstoreSubscription": MessageLookupByLibrary.simpleMessage(
          "Subscrição da PlayStore",
        ),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "Por favor, verifique a sua ligação à Internet e tente novamente.",
        ),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
          "Por favor, entre em contato com support@ente.io e nós ficaremos felizes em ajudar!",
        ),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
          "Por favor, contate o suporte se o problema persistir",
        ),
        "pleaseEmailUsAt": m64,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
          "Por favor, conceda as permissões",
        ),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
          "Por favor, inicie sessão novamente",
        ),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
          "Selecione links rápidos para remover",
        ),
        "pleaseSendTheLogsTo": m65,
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage(
          "Por favor, tente novamente",
        ),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
          "Por favor, verifique se o código que você inseriu",
        ),
        "pleaseWait": MessageLookupByLibrary.simpleMessage(
          "Por favor, aguarde ...",
        ),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
          "Por favor aguarde,  apagar o álbum",
        ),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
          "Por favor, aguarde algum tempo antes de tentar novamente",
        ),
        "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
          "Espera um pouco, isto deve levar um tempo.",
        ),
        "posingWithThem": m66,
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Preparando logs..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Preservar mais"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
          "Pressione e segure para reproduzir o vídeo",
        ),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
          "Pressione e segure na imagem para reproduzir o vídeo",
        ),
        "previous": MessageLookupByLibrary.simpleMessage("Anterior"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacidade"),
        "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
          "Política de privacidade",
        ),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Backups privados"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Partilha privada"),
        "proceed": MessageLookupByLibrary.simpleMessage("Continuar"),
        "processed": MessageLookupByLibrary.simpleMessage("Processado"),
        "processing": MessageLookupByLibrary.simpleMessage("A processar"),
        "processingImport": m67,
        "processingVideos": MessageLookupByLibrary.simpleMessage(
          "A processar vídeos",
        ),
        "publicLinkCreated": MessageLookupByLibrary.simpleMessage(
          "Link público criado",
        ),
        "publicLinkEnabled": MessageLookupByLibrary.simpleMessage(
          "Link público ativado",
        ),
        "questionmark": MessageLookupByLibrary.simpleMessage("?"),
        "queued": MessageLookupByLibrary.simpleMessage("Em fila"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Links rápidos"),
        "radius": MessageLookupByLibrary.simpleMessage("Raio"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Abrir ticket"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Avaliar aplicação"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Avalie-nos"),
        "rateUsOnStore": m68,
        "reassignMe": MessageLookupByLibrary.simpleMessage("Retribua \"Mim\""),
        "reassignedToName": m69,
        "reassigningLoading": MessageLookupByLibrary.simpleMessage(
          "A retribuir...",
        ),
        "receiveRemindersOnBirthdays": MessageLookupByLibrary.simpleMessage(
          "Obtém lembretes de quando é aniversário de alguém. Apertar na notificação o levará às fotos do aniversariante.",
        ),
        "recover": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recuperar conta"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recuperar"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Recuperar Conta"),
        "recoveryInitiated": MessageLookupByLibrary.simpleMessage(
          "Recuperação iniciada",
        ),
        "recoveryInitiatedDesc": m70,
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Chave de recuperação"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
          "Chave de recuperação copiada para a área de transferência",
        ),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
          "Se esquecer sua palavra-passe, a única maneira de recuperar os seus dados é com esta chave.",
        ),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
          "Não armazenamos essa chave, por favor, guarde esta chave de 24 palavras num lugar seguro.",
        ),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
          "Ótimo! A sua chave de recuperação é válida. Obrigado por verificar.\n\nLembre-se de manter cópia de segurança da sua chave de recuperação.",
        ),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
          "Chave de recuperação verificada",
        ),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
          "A sua chave de recuperação é a única forma de recuperar as suas fotografias se se esquecer da sua palavra-passe. Pode encontrar a sua chave de recuperação em Definições > Conta.\n\n\nIntroduza aqui a sua chave de recuperação para verificar se a guardou corretamente.",
        ),
        "recoveryReady": m71,
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
          "Recuperação com êxito!",
        ),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
          "Um contacto de confiança está a tentar acessar a sua conta",
        ),
        "recoveryWarningBody": m72,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
          "O dispositivo atual não é suficientemente poderoso para verificar a palavra-passe, mas podemos regenerar novamente de uma maneira que funcione no seu dispositivo.\n\nPor favor, iniciar sessão utilizando código de recuperação e gerar novamente a sua palavra-passe (pode utilizar a mesma se quiser).",
        ),
        "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Recriar palavra-passe",
        ),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword": MessageLookupByLibrary.simpleMessage(
          "Insira novamente a palavra-passe",
        ),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("Inserir PIN novamente"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
          "Recomende amigos e duplique o seu plano",
        ),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
          "1. Envie este código aos seus amigos",
        ),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
          "2. Eles se inscrevem em um plano pago",
        ),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("Referências"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
          "As referências estão atualmente em pausa",
        ),
        "rejectRecovery": MessageLookupByLibrary.simpleMessage(
          "Recusar recuperação",
        ),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
          "Esvazie também a opção “Eliminados recentemente” em “Definições” -> “Armazenamento” para reclamar o espaço libertado",
        ),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
          "Esvazie também o seu “Lixo” para reivindicar o espaço libertado",
        ),
        "remoteImages": MessageLookupByLibrary.simpleMessage("Imagens remotas"),
        "remoteThumbnails": MessageLookupByLibrary.simpleMessage(
          "Miniaturas remotas",
        ),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Vídeos remotos"),
        "remove": MessageLookupByLibrary.simpleMessage("Remover"),
        "removeDuplicates": MessageLookupByLibrary.simpleMessage(
          "Remover duplicados",
        ),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
          "Rever e remover ficheiros que sejam duplicados exatos.",
        ),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Remover do álbum"),
        "removeFromAlbumTitle": MessageLookupByLibrary.simpleMessage(
          "Remover do álbum",
        ),
        "removeFromFavorite": MessageLookupByLibrary.simpleMessage(
          "Remover dos favoritos",
        ),
        "removeInvite": MessageLookupByLibrary.simpleMessage("Retirar convite"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Remover link"),
        "removeParticipant": MessageLookupByLibrary.simpleMessage(
          "Remover participante",
        ),
        "removeParticipantBody": m74,
        "removePersonLabel": MessageLookupByLibrary.simpleMessage(
          "Remover etiqueta da pessoa",
        ),
        "removePublicLink": MessageLookupByLibrary.simpleMessage(
          "Remover link público",
        ),
        "removePublicLinks": MessageLookupByLibrary.simpleMessage(
          "Remover link público",
        ),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
          "Alguns dos itens que você está removendo foram adicionados por outras pessoas, e você perderá o acesso a eles",
        ),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Remover?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
          "Retirar-vos dos contactos de confiança",
        ),
        "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
          "Removendo dos favoritos...",
        ),
        "rename": MessageLookupByLibrary.simpleMessage("Renomear"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Renomear álbum"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Renomear arquivo"),
        "renewSubscription": MessageLookupByLibrary.simpleMessage(
          "Renovar subscrição",
        ),
        "renewsOn": m75,
        "reportABug": MessageLookupByLibrary.simpleMessage("Reporte um bug"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Reportar bug"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Reenviar e-mail"),
        "reset": MessageLookupByLibrary.simpleMessage("Redefinir"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
          "Repor ficheiros ignorados",
        ),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Redefinir palavra-passe",
        ),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Remover"),
        "resetToDefault": MessageLookupByLibrary.simpleMessage(
          "Redefinir para o padrão",
        ),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurar"),
        "restoreToAlbum": MessageLookupByLibrary.simpleMessage(
          "Restaurar para álbum",
        ),
        "restoringFiles": MessageLookupByLibrary.simpleMessage(
          "Restaurar arquivos...",
        ),
        "resumableUploads": MessageLookupByLibrary.simpleMessage(
          "Uploads reenviados",
        ),
        "retry": MessageLookupByLibrary.simpleMessage("Tentar novamente"),
        "review": MessageLookupByLibrary.simpleMessage("Rever"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
          "Reveja e elimine os itens que considera serem duplicados.",
        ),
        "reviewSuggestions": MessageLookupByLibrary.simpleMessage(
          "Revisar sugestões",
        ),
        "right": MessageLookupByLibrary.simpleMessage("Direita"),
        "roadtripWithThem": m76,
        "rotate": MessageLookupByLibrary.simpleMessage("Rodar"),
        "rotateLeft":
            MessageLookupByLibrary.simpleMessage("Rodar para a esquerda"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Rodar para a direita"),
        "safelyStored": MessageLookupByLibrary.simpleMessage(
          "Armazenado com segurança",
        ),
        "same": MessageLookupByLibrary.simpleMessage("Igual"),
        "sameperson": MessageLookupByLibrary.simpleMessage("A mesma pessoa?"),
        "save": MessageLookupByLibrary.simpleMessage("Guardar"),
        "saveAsAnotherPerson": MessageLookupByLibrary.simpleMessage(
          "Guardar como outra pessoa",
        ),
        "saveChangesBeforeLeavingQuestion":
            MessageLookupByLibrary.simpleMessage(
          "Guardar as alterações antes de sair?",
        ),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Guardar colagem"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Guardar cópia"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Guardar chave"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Guardar pessoa"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
          "Guarde a sua chave de recuperação, caso ainda não o tenha feito",
        ),
        "saving": MessageLookupByLibrary.simpleMessage("A gravar..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Gravando edições..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Ler código Qr"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Leia este código com a sua aplicação dois fatores.",
        ),
        "search": MessageLookupByLibrary.simpleMessage("Pesquisar"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Álbuns"),
        "searchByAlbumNameHint": MessageLookupByLibrary.simpleMessage(
          "Nome do álbum",
        ),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
          "• Nomes de álbuns (ex: \"Câmera\")\n• Tipos de arquivos (ex.: \"Vídeos\", \".gif\")\n• Anos e meses (e.. \"2022\", \"Janeiro\")\n• Feriados (por exemplo, \"Natal\")\n• Descrições de fotos (por exemplo, \"#divertido\")",
        ),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
          "Adicione descrições como \"#trip\" nas informações das fotos para encontrá-las aqui rapidamente",
        ),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
          "Pesquisar por data, mês ou ano",
        ),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
          "As imagens aparecerão aqui caso o processamento e sincronização for concluído",
        ),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
          "As pessoas serão mostradas aqui quando a indexação estiver concluída",
        ),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage(
          "Tipos de arquivo e nomes",
        ),
        "searchHint1": MessageLookupByLibrary.simpleMessage(
          "Pesquisa rápida no dispositivo",
        ),
        "searchHint2": MessageLookupByLibrary.simpleMessage(
          "Datas das fotos, descrições",
        ),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
          "Álbuns, nomes de arquivos e tipos",
        ),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Local"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
          "Em breve: Rostos e pesquisa mágica ✨",
        ),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
          "Fotos de grupo que estão sendo tiradas em algum raio da foto",
        ),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
          "Convide pessoas e verá todas as fotos partilhadas por elas aqui",
        ),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
          "As pessoas aparecerão aqui caso o processamento e sincronização for concluído",
        ),
        "searchResultCount": m77,
        "searchSectionsLengthMismatch": m78,
        "security": MessageLookupByLibrary.simpleMessage("Segurança"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
          "Ver Ligações Públicas na Aplicação",
        ),
        "selectALocation": MessageLookupByLibrary.simpleMessage(
          "Selecione uma localização",
        ),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
          "Selecione uma localização primeiro",
        ),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Selecionar álbum"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Selecionar tudo"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Tudo"),
        "selectCoverPhoto": MessageLookupByLibrary.simpleMessage(
          "Selecionar Foto para Capa",
        ),
        "selectDate": MessageLookupByLibrary.simpleMessage("Selecionar data"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
          "Selecionar pastas para cópia de segurança",
        ),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
          "Selecionar itens para adicionar",
        ),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Selecionar Idioma"),
        "selectMailApp": MessageLookupByLibrary.simpleMessage(
          "Selecione Aplicação de Correios",
        ),
        "selectMorePhotos": MessageLookupByLibrary.simpleMessage(
          "Selecionar mais fotos",
        ),
        "selectOneDateAndTime": MessageLookupByLibrary.simpleMessage(
          "Selecione uma Data e Hora",
        ),
        "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
          "Selecionar uma data e hora a todos",
        ),
        "selectPersonToLink": MessageLookupByLibrary.simpleMessage(
          "Selecione uma pessoa para ligar-se",
        ),
        "selectReason": MessageLookupByLibrary.simpleMessage("Diz a razão"),
        "selectStartOfRange": MessageLookupByLibrary.simpleMessage(
          "Selecionar início de intervalo",
        ),
        "selectTime": MessageLookupByLibrary.simpleMessage("Selecionar tempo"),
        "selectYourFace": MessageLookupByLibrary.simpleMessage(
          "Selecionar o seu rosto",
        ),
        "selectYourPlan": MessageLookupByLibrary.simpleMessage(
          "Selecione o seu plano",
        ),
        "selectedAlbums": m79,
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
          "Os arquivos selecionados não estão no Ente",
        ),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
          "As pastas selecionadas serão encriptadas e guardadas como cópia de segurança",
        ),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
          "Os itens selecionados serão eliminados de todos os álbuns e movidos para o lixo.",
        ),
        "selectedItemsWillBeRemovedFromThisPerson":
            MessageLookupByLibrary.simpleMessage(
          "Os itens em seleção serão removidos desta pessoa, mas não da sua biblioteca.",
        ),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "selfiesWithThem": m82,
        "send": MessageLookupByLibrary.simpleMessage("Enviar"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Enviar e-mail"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Enviar convite"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Enviar link"),
        "serverEndpoint": MessageLookupByLibrary.simpleMessage(
          "Endpoint do servidor",
        ),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessão expirada"),
        "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
          "Incompatibilidade de ID de sessão",
        ),
        "setAPassword": MessageLookupByLibrary.simpleMessage(
          "Definir uma palavra-passe",
        ),
        "setAs": MessageLookupByLibrary.simpleMessage("Definir como"),
        "setCover": MessageLookupByLibrary.simpleMessage("Definir capa"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Definir"),
        "setNewPassword": MessageLookupByLibrary.simpleMessage(
          "Definir nova palavra-passe",
        ),
        "setNewPin": MessageLookupByLibrary.simpleMessage("Definir novo PIN"),
        "setPasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Definir palavra-passe",
        ),
        "setRadius": MessageLookupByLibrary.simpleMessage("Definir raio"),
        "setupComplete": MessageLookupByLibrary.simpleMessage(
          "Configuração concluída",
        ),
        "share": MessageLookupByLibrary.simpleMessage("Partilhar"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Partilhar um link"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
          "Abra um álbum e toque no botão de partilha no canto superior direito para partilhar",
        ),
        "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage(
          "Partilhar um álbum",
        ),
        "shareLink": MessageLookupByLibrary.simpleMessage("Partilhar link"),
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
          "Partilhar apenas com as pessoas que deseja",
        ),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
          "Descarregue o Ente para poder partilhar facilmente fotografias e vídeos de qualidade original\n\n\nhttps://ente.io",
        ),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
          "Compartilhar com usuários que não usam Ente",
        ),
        "shareWithPeopleSectionTitle": m86,
        "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
          "Partilhe o seu primeiro álbum",
        ),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
          "Criar álbuns compartilhados e colaborativos com outros usuários da Ente, incluindo usuários em planos gratuitos.",
        ),
        "sharedByMe":
            MessageLookupByLibrary.simpleMessage("Partilhado por mim"),
        "sharedByYou":
            MessageLookupByLibrary.simpleMessage("Partilhado por si"),
        "sharedPhotoNotifications": MessageLookupByLibrary.simpleMessage(
          "Novas fotos partilhadas",
        ),
        "sharedPhotoNotificationsExplanation":
            MessageLookupByLibrary.simpleMessage(
          "Receber notificações quando alguém adiciona uma foto a um álbum partilhado do qual faz parte",
        ),
        "sharedWith": m87,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Partilhado comigo"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Partilhado consigo"),
        "sharing": MessageLookupByLibrary.simpleMessage("Partilhar..."),
        "shiftDatesAndTime": MessageLookupByLibrary.simpleMessage(
          "Mude as Datas e Horas",
        ),
        "showLessFaces": MessageLookupByLibrary.simpleMessage(
          "Mostrar menos rostos",
        ),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Mostrar memórias"),
        "showMoreFaces": MessageLookupByLibrary.simpleMessage(
          "Mostrar mais rostos",
        ),
        "showPerson": MessageLookupByLibrary.simpleMessage("Mostrar pessoa"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
          "Terminar sessão noutros dispositivos",
        ),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
          "Se pensa que alguém pode saber a sua palavra-passe, pode forçar todos os outros dispositivos que utilizam a sua conta a terminar a sessão.",
        ),
        "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
          "Terminar a sessão noutros dispositivos",
        ),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
          "Eu concordo com os <u-terms>termos de serviço</u-terms> e <u-policy>política de privacidade</u-policy>",
        ),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
          "Será eliminado de todos os álbuns.",
        ),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("Pular"),
        "smartMemories": MessageLookupByLibrary.simpleMessage(
          "Memórias inteligentes",
        ),
        "social": MessageLookupByLibrary.simpleMessage("Social"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
          "Alguns itens estão tanto no Ente como no seu dispositivo.",
        ),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
          "Alguns dos ficheiros que está a tentar eliminar só estão disponíveis no seu dispositivo e não podem ser recuperados se forem eliminados",
        ),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
          "Alguém compartilhando álbuns com você deve ver o mesmo ID no seu dispositivo.",
        ),
        "somethingWentWrong": MessageLookupByLibrary.simpleMessage(
          "Ocorreu um erro",
        ),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "Algo correu mal. Favor, tentar de novo",
        ),
        "sorry": MessageLookupByLibrary.simpleMessage("Desculpe"),
        "sorryBackupFailedDesc": MessageLookupByLibrary.simpleMessage(
          "Perdão, mas não podemos fazer backup deste ficheiro agora, tentaremos mais tarde.",
        ),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
          "Desculpe, não foi possível adicionar aos favoritos!",
        ),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
          "Desculpe, não foi possível remover dos favoritos!",
        ),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
          "Desculpe, o código inserido está incorreto",
        ),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
          "Desculpe, não foi possível gerar chaves seguras neste dispositivo.\n\npor favor iniciar sessão com um dispositivo diferente.",
        ),
        "sorryWeHadToPauseYourBackups": MessageLookupByLibrary.simpleMessage(
          "Perdão, precisamos parar seus backups",
        ),
        "sort": MessageLookupByLibrary.simpleMessage("Ordenar"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Ordenar por"),
        "sortNewestFirst": MessageLookupByLibrary.simpleMessage(
          "Mais recentes primeiro",
        ),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage(
          "Mais antigos primeiro",
        ),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Sucesso"),
        "sportsWithThem": m91,
        "spotlightOnThem": m92,
        "spotlightOnYourself": MessageLookupByLibrary.simpleMessage(
          "A dar destaque em vos",
        ),
        "startAccountRecoveryTitle": MessageLookupByLibrary.simpleMessage(
          "Começar Recuperação",
        ),
        "startBackup": MessageLookupByLibrary.simpleMessage(
          "Iniciar cópia de segurança",
        ),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
          "Queres parar de fazer transmissão?",
        ),
        "stopCastingTitle": MessageLookupByLibrary.simpleMessage(
          "Parar transmissão",
        ),
        "storage": MessageLookupByLibrary.simpleMessage("Armazenamento"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Família"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Tu"),
        "storageInGB": m93,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
          "Limite de armazenamento excedido",
        ),
        "storageUsageInfo": m94,
        "streamDetails": MessageLookupByLibrary.simpleMessage(
          "Detalhes do em direto",
        ),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Forte"),
        "subAlreadyLinkedErrMessage": m95,
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("Subscrever"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
          "Você precisa de uma assinatura paga ativa para ativar o compartilhamento.",
        ),
        "subscription": MessageLookupByLibrary.simpleMessage("Subscrição"),
        "success": MessageLookupByLibrary.simpleMessage("Sucesso"),
        "successfullyArchived": MessageLookupByLibrary.simpleMessage(
          "Arquivado com sucesso",
        ),
        "successfullyHid": MessageLookupByLibrary.simpleMessage(
          "Ocultado com sucesso",
        ),
        "successfullyUnarchived": MessageLookupByLibrary.simpleMessage(
          "Desarquivado com sucesso",
        ),
        "successfullyUnhid": MessageLookupByLibrary.simpleMessage(
          "Reexibido com sucesso",
        ),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Sugerir recursos"),
        "sunrise": MessageLookupByLibrary.simpleMessage("No horizonte"),
        "support": MessageLookupByLibrary.simpleMessage("Suporte"),
        "syncProgress": m97,
        "syncStopped": MessageLookupByLibrary.simpleMessage(
          "Sincronização interrompida",
        ),
        "syncing": MessageLookupByLibrary.simpleMessage("Sincronizando..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistema"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("toque para copiar"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
          "Tocar para introduzir código",
        ),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage(
          "Toque para desbloquear",
        ),
        "tapToUpload":
            MessageLookupByLibrary.simpleMessage("Clique para enviar"),
        "tapToUploadIsIgnoredDue": m98,
        "tempErrorContactSupportIfPersists":
            MessageLookupByLibrary.simpleMessage(
          "Parece que algo correu mal. Por favor, tente novamente mais tarde. Se o erro persistir, entre em contacto com a nossa equipa de suporte.",
        ),
        "terminate": MessageLookupByLibrary.simpleMessage("Desconectar"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Desconectar?"),
        "terms": MessageLookupByLibrary.simpleMessage("Termos"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Termos"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Obrigado"),
        "thankYouForSubscribing": MessageLookupByLibrary.simpleMessage(
          "Obrigado pela sua subscrição!",
        ),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
          "Não foi possível concluir o download.",
        ),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
          "A ligação que está a tentar acessar já expirou.",
        ),
        "thePersonGroupsWillNotBeDisplayed":
            MessageLookupByLibrary.simpleMessage(
          "Os grupos de pessoa não aparecerão mais na secção de pessoas. As Fotos permanecerão intocadas.",
        ),
        "thePersonWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
          "As pessoas não aparecerão mais na secção de pessoas. As fotos permanecerão intocadas.",
        ),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
          "A chave de recuperação inserida está incorreta",
        ),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
          "Estes itens serão eliminados do seu dispositivo.",
        ),
        "theyAlsoGetXGb": m99,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
          "Serão eliminados de todos os álbuns.",
        ),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
          "Esta ação não pode ser desfeita",
        ),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
          "Este álbum já tem um link colaborativo",
        ),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
          "Isto pode ser usado para recuperar sua conta se você perder seu segundo fator",
        ),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Este aparelho"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
          "Este email já está em uso",
        ),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
          "Esta imagem não tem dados exif",
        ),
        "thisIsMeExclamation":
            MessageLookupByLibrary.simpleMessage("Este sou eu!"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
          "Este é o seu ID de verificação",
        ),
        "thisWeekThroughTheYears": MessageLookupByLibrary.simpleMessage(
          "Esta semana com o avanço dos anos",
        ),
        "thisWeekXYearsAgo": m101,
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
          "Isto desconectará-vos dos aparelhos a seguir:",
        ),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
          "Isto desconectará-vos deste aparelho!",
        ),
        "thisWillMakeTheDateAndTimeOfAllSelected":
            MessageLookupByLibrary.simpleMessage(
          "Isto fará a data e hora de todas as fotos o mesmo.",
        ),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
          "Isto removerá links públicos de todos os links rápidos selecionados.",
        ),
        "throughTheYears": m102,
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
          "Para ativar o bloqueio de aplicações, configure o código de acesso do dispositivo ou o bloqueio de ecrã nas definições do sistema.",
        ),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
          "Para ocultar uma foto ou um vídeo",
        ),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
          "Para redefinir a palavra-passe, favor, verifique o seu e-mail.",
        ),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Logs de hoje"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
          "Muitas tentativas incorretas",
        ),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Tamanho total"),
        "trash": MessageLookupByLibrary.simpleMessage("Lixo"),
        "trashDaysLeft": m103,
        "trim": MessageLookupByLibrary.simpleMessage("Cortar"),
        "tripInYear": m104,
        "tripToLocation": m105,
        "trustedContacts": MessageLookupByLibrary.simpleMessage(
          "Contactos de Confiança",
        ),
        "trustedInviteBody": m106,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Tente novamente"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
          "Ative o backup para enviar automaticamente arquivos adicionados a esta pasta do dispositivo para o Ente.",
        ),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
          "2 meses grátis em planos anuais",
        ),
        "twofactor": MessageLookupByLibrary.simpleMessage("Dois fatores"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
          "A autenticação de dois fatores foi desativada",
        ),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
          "Autenticação de dois fatores",
        ),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
          "Autenticação de dois fatores redefinida com êxito",
        ),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
          "Configuração de dois fatores",
        ),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
        "unarchive": MessageLookupByLibrary.simpleMessage("Desarquivar"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Desarquivar álbum"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("Desarquivar..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
          "Desculpe, este código não está disponível.",
        ),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Sem categoria"),
        "unhide": MessageLookupByLibrary.simpleMessage("Mostrar"),
        "unhideToAlbum": MessageLookupByLibrary.simpleMessage(
          "Mostrar para o álbum",
        ),
        "unhiding": MessageLookupByLibrary.simpleMessage("Reexibindo..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
          "Desocultar ficheiros para o álbum",
        ),
        "unlock": MessageLookupByLibrary.simpleMessage("Desbloquear"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Desafixar álbum"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar tudo"),
        "update": MessageLookupByLibrary.simpleMessage("Atualizar"),
        "updateAvailable": MessageLookupByLibrary.simpleMessage(
          "Atualização disponível",
        ),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
          "Atualizando seleção de pasta...",
        ),
        "upgrade": MessageLookupByLibrary.simpleMessage("Atualizar"),
        "uploadIsIgnoredDueToIgnorereason": m108,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
          "Enviar ficheiros para o álbum...",
        ),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory": MessageLookupByLibrary.simpleMessage(
          "Preservar 1 memória...",
        ),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
          "Até 50% de desconto, até 4 de dezembro.",
        ),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
          "O armazenamento disponível é limitado pelo seu plano atual. O excesso de armazenamento reivindicado tornará automaticamente útil quando você atualizar seu plano.",
        ),
        "useAsCover": MessageLookupByLibrary.simpleMessage("Usar como capa"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
          "A ter problemas reproduzindo este vídeo? Prima aqui para tentar outro reprodutor.",
        ),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
          "Usar links públicos para pessoas que não estão no Ente",
        ),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Usar chave de recuperação",
        ),
        "useSelectedPhoto": MessageLookupByLibrary.simpleMessage(
          "Utilizar foto selecionada",
        ),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Espaço utilizado"),
        "validTill": m110,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "Falha na verificação, por favor tente novamente",
        ),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de Verificação"),
        "verify": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Verificar e-mail"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verificar"),
        "verifyPasskey": MessageLookupByLibrary.simpleMessage(
          "Verificar chave de acesso",
        ),
        "verifyPassword": MessageLookupByLibrary.simpleMessage(
          "Verificar palavra-passe",
        ),
        "verifying": MessageLookupByLibrary.simpleMessage("A verificar…"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Verificando chave de recuperação...",
        ),
        "videoInfo":
            MessageLookupByLibrary.simpleMessage("Informação de Vídeo"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vídeo"),
        "videoStreaming": MessageLookupByLibrary.simpleMessage(
          "Vídeos transmissíveis",
        ),
        "videos": MessageLookupByLibrary.simpleMessage("Vídeos"),
        "viewActiveSessions": MessageLookupByLibrary.simpleMessage(
          "Ver sessões ativas",
        ),
        "viewAddOnButton": MessageLookupByLibrary.simpleMessage("Ver addons"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Ver tudo"),
        "viewAllExifData": MessageLookupByLibrary.simpleMessage(
          "Ver todos os dados EXIF",
        ),
        "viewLargeFiles":
            MessageLookupByLibrary.simpleMessage("Ficheiros grandes"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
          "Ver os ficheiros que estão a consumir a maior quantidade de armazenamento.",
        ),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Ver logs"),
        "viewPersonToUnlink": m112,
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Ver chave de recuperação",
        ),
        "viewer": MessageLookupByLibrary.simpleMessage("Visualizador"),
        "viewersSuccessfullyAdded": m113,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
          "Visite web.ente.io para gerir a sua subscrição",
        ),
        "waitingForVerification": MessageLookupByLibrary.simpleMessage(
          "Aguardando verificação...",
        ),
        "waitingForWifi": MessageLookupByLibrary.simpleMessage(
          "Aguardando Wi-Fi...",
        ),
        "warning": MessageLookupByLibrary.simpleMessage("Alerta"),
        "weAreOpenSource": MessageLookupByLibrary.simpleMessage(
          "Nós somos de código aberto!",
        ),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
          "Não suportamos a edição de fotos e álbuns que ainda não possui",
        ),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Fraca"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage(
          "Bem-vindo(a) de volta!",
        ),
        "whatsNew": MessageLookupByLibrary.simpleMessage("O que há de novo"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
          "O contacto de confiança pode ajudar na recuperação dos seus dados.",
        ),
        "widgets": MessageLookupByLibrary.simpleMessage("Widgets"),
        "wishThemAHappyBirthday": m115,
        "yearShort": MessageLookupByLibrary.simpleMessage("ano"),
        "yearly": MessageLookupByLibrary.simpleMessage("Anual"),
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("Sim"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Sim, cancelar"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
          "Sim, converter para visualizador",
        ),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Sim, apagar"),
        "yesDiscardChanges": MessageLookupByLibrary.simpleMessage(
          "Sim, rejeitar alterações",
        ),
        "yesIgnore": MessageLookupByLibrary.simpleMessage("Sim, ignorar"),
        "yesLogout":
            MessageLookupByLibrary.simpleMessage("Sim, terminar sessão"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Sim, remover"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Sim, Renovar"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Sim, repor pessoa"),
        "you": MessageLookupByLibrary.simpleMessage("Tu"),
        "youAndThem": m117,
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
          "Você está em um plano familiar!",
        ),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
          "Está a utilizar a versão mais recente",
        ),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
          "* Você pode duplicar seu armazenamento no máximo",
        ),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
          "Pode gerir as suas ligações no separador partilhar.",
        ),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
          "Pode tentar pesquisar uma consulta diferente.",
        ),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
          "Não é possível fazer o downgrade para este plano",
        ),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
          "Não podes partilhar contigo mesmo",
        ),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
          "Não tem nenhum item arquivado.",
        ),
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
          "A sua conta foi eliminada",
        ),
        "yourMap": MessageLookupByLibrary.simpleMessage("Seu mapa"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
          "O seu plano foi rebaixado com sucesso",
        ),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
          "O seu plano foi atualizado com sucesso",
        ),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
          "Sua compra foi realizada com sucesso",
        ),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
          "Não foi possível obter os seus dados de armazenamento",
        ),
        "yourSubscriptionHasExpired": MessageLookupByLibrary.simpleMessage(
          "A sua subscrição expirou",
        ),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
          "A sua subscrição foi actualizada com sucesso",
        ),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
          "O seu código de verificação expirou",
        ),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
          "Não tem nenhum ficheiro duplicado que possa ser eliminado",
        ),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
          "Não existem ficheiros neste álbum que possam ser eliminados",
        ),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
          "Diminuir o zoom para ver fotos",
        ),
      };
}
