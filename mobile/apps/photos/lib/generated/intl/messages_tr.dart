// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a tr locale. All the
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
  String get localeName => 'tr';

  static String m0(title) => "${title} (Ben)";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Ortak çalışan ekle', one: 'Ortak çalışan ekle', other: 'Ortak çalışan ekle')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Öğe ekle', other: 'Öğeler ekle')}";

  static String m3(storageAmount, endDate) =>
      "${storageAmount} eklentiniz ${endDate} tarihine kadar geçerlidir";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Görüntüleyen ekle', one: 'Görüntüleyen ekle', other: 'Görüntüleyen ekle')}";

  static String m5(emailOrName) => "${emailOrName} tarafından eklendi";

  static String m6(albumName) => "${albumName} albümüne başarıyla eklendi";

  static String m7(name) => "${name}\'e hayran kalmak";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Katılımcı Yok', one: '1 Katılımcı', other: '${count} Katılımcı')}";

  static String m9(versionValue) => "Sürüm: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} ücretsiz";

  static String m11(name) => "${name} ile güzel manzaralar";

  static String m12(paymentProvider) =>
      "Lütfen önce mevcut aboneliğinizi ${paymentProvider} adresinden iptal edin";

  static String m13(user) =>
      "${user}, bu albüme daha fazla fotoğraf ekleyemeyecek.\n\nAncak, kendi eklediği mevcut fotoğrafları kaldırmaya devam edebilecektir";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {'true': 'Şu ana kadar aileniz ${storageAmountInGb} GB aldı', 'false': 'Şu ana kadar ${storageAmountInGb} GB aldınız', 'other': 'Şu ana kadar ${storageAmountInGb} GB aldınız!'})}";

  static String m15(albumName) =>
      "${albumName} için ortak çalışma bağlantısı oluşturuldu";

  static String m16(count) =>
      "${Intl.plural(count, zero: '0 işbirlikçi eklendi', one: '1 işbirlikçi eklendi', other: '${count} işbirlikçi eklendi')}";

  static String m17(email, numOfDays) =>
      "Güvenilir bir kişi olarak ${email} eklemek üzeresiniz. Eğer ${numOfDays} gün boyunca yoksanız hesabınızı kurtarabilecekler.";

  static String m18(familyAdminEmail) =>
      "Aboneliğinizi yönetmek için lütfen <green>${familyAdminEmail}</green> ile iletişime geçin";

  static String m19(provider) =>
      "Lütfen ${provider} aboneliğinizi yönetmek için support@ente.io adresinden bizimle iletişime geçin.";

  static String m20(endpoint) => "${endpoint}\'e bağlanıldı";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Delete ${count} item', other: 'Delete ${count} items')}";

  static String m22(count) =>
      "Ayrıca bu ${count} albümde bulunan fotoğrafları (ve videoları) parçası oldukları <bold>tüm</bold> diğer albümlerden silmek istiyor musunuz?";

  static String m23(currentlyDeleting, totalCount) =>
      "Siliniyor ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "Bu, \"${albumName}\"e erişim için olan genel bağlantıyı kaldıracaktır.";

  static String m25(supportEmail) =>
      "Lütfen kayıtlı e-posta adresinizden ${supportEmail} adresine bir e-posta gönderin";

  static String m26(count, storageSaved) =>
      "You have cleaned up ${Intl.plural(count, one: '${count} duplicate file', other: '${count} duplicate files')}, saving (${storageSaved}!)";

  static String m27(count, formattedSize) =>
      "${count} dosyalar, ${formattedSize} her biri";

  static String m28(name) => "Bu e-posta zaten ${name} kişisine bağlı.";

  static String m29(newEmail) => "E-posta ${newEmail} olarak değiştirildi";

  static String m30(email) => "${email} bir Ente hesabına sahip değil";

  static String m31(email) =>
      "${email}, Ente hesabı bulunmamaktadır.\n\nOnlarla fotoğraf paylaşımı için bir davet gönder.";

  static String m32(name) => "${name}\'e sarılmak";

  static String m33(text) => "${text} için ekstra fotoğraflar bulundu";

  static String m34(name) => "${name} ile ziyafet";

  static String m35(count, formattedNumber) =>
      "Bu cihazdaki ${Intl.plural(count, one: '1 file', other: '${formattedNumber} dosya')} güvenli bir şekilde yedeklendi";

  static String m36(count, formattedNumber) =>
      "Bu albümdeki ${Intl.plural(count, one: '1 file', other: '${formattedNumber} dosya')} güvenli bir şekilde yedeklendi";

  static String m37(storageAmountInGB) =>
      "Birisinin davet kodunuzu uygulayıp ücretli hesap açtığı her seferede ${storageAmountInGB} GB";

  static String m38(endDate) => "Ücretsiz deneme ${endDate} sona erir";

  static String m39(count) =>
      "Aktif bir aboneliğiniz olduğu sürece Ente üzerinden ${Intl.plural(count, one: 'ona', other: 'onlara')} hâlâ erişebilirsiniz";

  static String m40(sizeInMBorGB) => "${sizeInMBorGB} yer açın";

  static String m41(count, formattedSize) =>
      "${Intl.plural(count, one: 'Cihazdan silinerek ${formattedSize} boşaltılabilir', other: 'Cihazdan silinerek ${formattedSize} boşaltılabilirler')}";

  static String m42(currentlyProcessing, totalCount) =>
      "Siliniyor ${currentlyProcessing} / ${totalCount}";

  static String m43(name) => "${name} ile doğa yürüyüşü";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} öğe', other: '${count} öğeler')}";

  static String m45(name) => "${name} ile son an";

  static String m46(email) =>
      "${email} sizi güvenilir bir kişi olmaya davet etti";

  static String m47(expiryTime) =>
      "Bu bağlantı ${expiryTime} tarihinden itibaren geçersiz olacaktır";

  static String m48(email) => "Kişiyi ${email} adresine bağlayın";

  static String m49(personName, email) =>
      "Bu, ${personName} ile ${email} arasında bağlantı kuracaktır.";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'hiç anı yok', one: '${formattedCount} anı', other: '${formattedCount} anı')}";

  static String m51(count) =>
      "${Intl.plural(count, one: 'Öğeyi taşı', other: 'Öğeleri taşı')}";

  static String m52(albumName) => "${albumName} adlı albüme başarıyla taşındı";

  static String m53(personName) => "${personName} için öneri yok";

  static String m54(name) => "${name} değil mi?";

  static String m55(familyAdminEmail) =>
      "Kodunuzu değiştirmek için lütfen ${familyAdminEmail} ile iletişime geçin.";

  static String m56(name) => "${name} ile parti";

  static String m57(passwordStrengthValue) =>
      "Şifrenin güçlülük seviyesi: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Sizden ücret alındıysa lütfen ${providerName} destek ekibiyle görüşün";

  static String m59(name, age) => "${name} ${age} yaşında!";

  static String m60(name, age) => "${name} yakında ${age} yaşına giriyor";

  static String m61(count) =>
      "${Intl.plural(count, zero: 'Fotoğraf yok', one: '1 fotoğraf', other: '${count} fotoğraf')}";

  static String m62(count) =>
      "${Intl.plural(count, zero: '0 fotoğraf', one: '1 fotoğraf', other: '${count} fotoğraf')}";

  static String m63(endDate) =>
      "Ücretsiz deneme süresi ${endDate} tarihine kadar geçerlidir.\nDaha sonra ücretli bir plan seçebilirsiniz.";

  static String m64(toEmail) => "Lütfen bize ${toEmail} adresinden ulaşın";

  static String m65(toEmail) =>
      "Lütfen kayıtları şu adrese gönderin\n${toEmail}";

  static String m66(name) => "${name} ile poz verme";

  static String m67(folderName) => "İşleniyor ${folderName}...";

  static String m68(storeName) => "Bizi ${storeName} üzerinden değerlendirin";

  static String m69(name) => "Sizi ${name}\'e yeniden atadı";

  static String m70(days, email) =>
      "Hesabınıza ${days} gün sonra erişebilirsiniz. ${email} adresine bir bildirim gönderilecektir.";

  static String m71(email) =>
      "Artık yeni bir parola belirleyerek ${email} hesabını kurtarabilirsiniz.";

  static String m72(email) => "${email} hesabınızı kurtarmaya çalışıyor.";

  static String m73(storageInGB) => "3. İkinizde bedava ${storageInGB} GB alın";

  static String m74(userEmail) =>
      "${userEmail} bu paylaşılan albümden kaldırılacaktır\n\nOnlar tarafından eklenen tüm fotoğraflar da albümden kaldırılacaktır";

  static String m75(endDate) => "Abonelik ${endDate} tarihinde yenilenir";

  static String m76(name) => "${name} ile yolculuk";

  static String m77(count) =>
      "${Intl.plural(count, one: '${count} yıl önce', other: '${count} yıl önce')}";

  static String m78(snapshotLength, searchLength) =>
      "Bölüm uzunluğu uyuşmazlığı: ${snapshotLength} != ${searchLength}";

  static String m79(count) => "${count} seçildi";

  static String m80(count) => "${count} seçildi";

  static String m81(count, yourCount) =>
      "Seçilenler: ${count} (${yourCount} sizin seçiminiz)";

  static String m82(name) => "${name} ile selfieler";

  static String m83(verificationID) =>
      "İşte ente.io için doğrulama kimliğim: ${verificationID}.";

  static String m84(verificationID) =>
      "Merhaba, bu ente.io doğrulama kimliğinizin doğruluğunu onaylayabilir misiniz: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Ente davet kodu: ${referralCode} \n\nÜcretli hesaba başvurduktan sonra ${referralStorageInGB} GB bedava almak için \nAyarlar → Genel → Davetlerde bu kodu girin\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Belirli kişilerle paylaş', one: '1 kişiyle paylaşıldı', other: '${numberOfPeople} kişiyle paylaşıldı')}";

  static String m87(emailIDs) => "${emailIDs} ile paylaşıldı";

  static String m88(fileType) => "Bu ${fileType}, cihazınızdan silinecek.";

  static String m89(fileType) =>
      "${fileType} Ente ve cihazınızdan silinecektir.";

  static String m90(fileType) => "${fileType} Ente\'den silinecektir.";

  static String m91(name) => "${name} ile spor";

  static String m92(name) => "Sahne ${name}\'in";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m94(
    usedAmount,
    usedStorageUnit,
    totalAmount,
    totalStorageUnit,
  ) =>
      "${usedAmount} ${usedStorageUnit} / ${totalAmount} ${totalStorageUnit} kullanıldı";

  static String m95(id) =>
      "${id}\'niz zaten başka bir ente hesabına bağlı.\n${id} numaranızı bu hesapla kullanmak istiyorsanız lütfen desteğimizle iletişime geçin\'\'";

  static String m96(endDate) =>
      "Aboneliğiniz ${endDate} tarihinde iptal edilecektir";

  static String m97(completed, total) => "${completed}/${total} anı korundu";

  static String m98(ignoreReason) =>
      "Yüklemek için dokunun, yükleme şu anda ${ignoreReason} nedeniyle yok sayılıyor";

  static String m99(storageAmountInGB) =>
      "Aynı zamanda ${storageAmountInGB} GB alıyorlar";

  static String m100(email) => "Bu, ${email}\'in Doğrulama Kimliği";

  static String m101(count) =>
      "${Intl.plural(count, one: 'Bu hafta, ${count} yıl önce', other: 'Bu hafta, ${count} yıl önce')}";

  static String m102(dateFormat) => "${dateFormat} yıllar boyunca";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Yakında', one: '1 gün', other: '${count} gün')}";

  static String m104(year) => "${year} yılındaki gezi";

  static String m105(location) => "${location}\'a gezi";

  static String m106(email) =>
      "${email} ile eski bir irtibat kişisi olmaya davet edildiniz.";

  static String m107(galleryType) =>
      "Galeri türü ${galleryType} yeniden adlandırma için desteklenmiyor";

  static String m108(ignoreReason) =>
      "Yükleme ${ignoreReason} nedeniyle yok sayıldı";

  static String m109(count) => "${count} anı korunuyor...";

  static String m110(endDate) => "${endDate} tarihine kadar geçerli";

  static String m111(email) => "${email} doğrula";

  static String m112(name) =>
      "Bağlantıyı kaldırmak için ${name} kişisini görüntüle";

  static String m113(count) =>
      "${Intl.plural(count, zero: '0 izleyici eklendi', one: '1 izleyici eklendi', other: '${count} izleyici eklendi')}";

  static String m114(email) =>
      "E-postayı <green>${email}</green> adresine gönderdik";

  static String m115(name) => "${name} doğum günü kutlu olsun! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, one: '${count} yıl önce', other: '${count} yıl önce')}";

  static String m117(name) => "Sen ve ${name}";

  static String m118(storageSaved) =>
      "Başarılı bir şekilde ${storageSaved} alanını boşalttınız!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
      "Ente için yeni bir sürüm mevcut.",
    ),
    "about": MessageLookupByLibrary.simpleMessage("Hakkında"),
    "acceptTrustInvite": MessageLookupByLibrary.simpleMessage(
      "Daveti Kabul Et",
    ),
    "account": MessageLookupByLibrary.simpleMessage("Hesap"),
    "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
      "Hesap zaten yapılandırılmıştır.",
    ),
    "accountOwnerPersonAppbarTitle": m0,
    "accountWelcomeBack": MessageLookupByLibrary.simpleMessage(
      "Tekrar hoş geldiniz!",
    ),
    "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
      "Şifremi kaybedersem, verilerim <underline>uçtan uca şifrelendiği</underline> için verilerimi kaybedebileceğimi farkındayım.",
    ),
    "actionNotSupportedOnFavouritesAlbum": MessageLookupByLibrary.simpleMessage(
      "Favoriler albümünde eylem desteklenmiyor",
    ),
    "activeSessions": MessageLookupByLibrary.simpleMessage("Aktif oturumlar"),
    "add": MessageLookupByLibrary.simpleMessage("Ekle"),
    "addAName": MessageLookupByLibrary.simpleMessage("Bir Ad Ekle"),
    "addANewEmail": MessageLookupByLibrary.simpleMessage("Yeni e-posta ekle"),
    "addAlbumWidgetPrompt": MessageLookupByLibrary.simpleMessage(
      "Ana ekranınıza bir albüm widget\'ı ekleyin ve özelleştirmek için buraya geri dönün.",
    ),
    "addCollaborator": MessageLookupByLibrary.simpleMessage("Düzenleyici ekle"),
    "addCollaborators": m1,
    "addFiles": MessageLookupByLibrary.simpleMessage("Dosyaları Ekle"),
    "addFromDevice": MessageLookupByLibrary.simpleMessage("Cihazdan ekle"),
    "addItem": m2,
    "addLocation": MessageLookupByLibrary.simpleMessage("Konum Ekle"),
    "addLocationButton": MessageLookupByLibrary.simpleMessage("Ekle"),
    "addMemoriesWidgetPrompt": MessageLookupByLibrary.simpleMessage(
      "Ana ekranınıza bir anılar widget\'ı ekleyin ve özelleştirmek için buraya geri dönün.",
    ),
    "addMore": MessageLookupByLibrary.simpleMessage("Daha fazla ekle"),
    "addName": MessageLookupByLibrary.simpleMessage("İsim Ekle"),
    "addNameOrMerge": MessageLookupByLibrary.simpleMessage(
      "İsim ekleyin veya birleştirin",
    ),
    "addNew": MessageLookupByLibrary.simpleMessage("Yeni ekle"),
    "addNewPerson": MessageLookupByLibrary.simpleMessage("Yeni kişi ekle"),
    "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
      "Eklentilerin ayrıntıları",
    ),
    "addOnValidTill": m3,
    "addOns": MessageLookupByLibrary.simpleMessage("Eklentiler"),
    "addParticipants": MessageLookupByLibrary.simpleMessage("Katılımcı ekle"),
    "addPeopleWidgetPrompt": MessageLookupByLibrary.simpleMessage(
      "Ana ekranınıza bir kişiler widget\'ı ekleyin ve özelleştirmek için buraya geri dönün.",
    ),
    "addPhotos": MessageLookupByLibrary.simpleMessage("Fotoğraf ekle"),
    "addSelected": MessageLookupByLibrary.simpleMessage("Seçileni ekle"),
    "addToAlbum": MessageLookupByLibrary.simpleMessage("Albüme ekle"),
    "addToEnte": MessageLookupByLibrary.simpleMessage("Ente\'ye ekle"),
    "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
      "Gizli albüme ekle",
    ),
    "addTrustedContact": MessageLookupByLibrary.simpleMessage(
      "Güvenilir kişi ekle",
    ),
    "addViewer": MessageLookupByLibrary.simpleMessage("Görüntüleyici ekle"),
    "addViewers": m4,
    "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
      "Fotoğraflarınızı şimdi ekleyin",
    ),
    "addedAs": MessageLookupByLibrary.simpleMessage("Eklendi"),
    "addedBy": m5,
    "addedSuccessfullyTo": m6,
    "addingToFavorites": MessageLookupByLibrary.simpleMessage(
      "Favorilere ekleniyor...",
    ),
    "admiringThem": m7,
    "advanced": MessageLookupByLibrary.simpleMessage("Gelişmiş"),
    "advancedSettings": MessageLookupByLibrary.simpleMessage("Gelişmiş"),
    "after1Day": MessageLookupByLibrary.simpleMessage("1 gün sonra"),
    "after1Hour": MessageLookupByLibrary.simpleMessage("1 saat sonra"),
    "after1Month": MessageLookupByLibrary.simpleMessage("1 ay sonra"),
    "after1Week": MessageLookupByLibrary.simpleMessage("1 hafta sonra"),
    "after1Year": MessageLookupByLibrary.simpleMessage("1 yıl sonra"),
    "albumOwner": MessageLookupByLibrary.simpleMessage("Sahip"),
    "albumParticipantsCount": m8,
    "albumTitle": MessageLookupByLibrary.simpleMessage("Albüm Başlığı"),
    "albumUpdated": MessageLookupByLibrary.simpleMessage("Albüm güncellendi"),
    "albums": MessageLookupByLibrary.simpleMessage("Albümler"),
    "albumsWidgetDesc": MessageLookupByLibrary.simpleMessage(
      "Ana ekranınızda görmek istediğiniz albümleri seçin.",
    ),
    "allClear": MessageLookupByLibrary.simpleMessage("✨ Tümü temizlendi"),
    "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
      "Tüm anılar saklandı",
    ),
    "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
      "Bu kişi için tüm gruplamalar sıfırlanacak ve bu kişi için yaptığınız tüm önerileri kaybedeceksiniz",
    ),
    "allUnnamedGroupsWillBeMergedIntoTheSelectedPerson":
        MessageLookupByLibrary.simpleMessage(
          "Tüm isimsiz gruplar seçilen kişiyle birleştirilecektir. Bu, kişinin öneri geçmişine genel bakışından hala geri alınabilir.",
        ),
    "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
      "Bu, gruptaki ilk fotoğraftır. Seçilen diğer fotoğraflar otomatik olarak bu yeni tarihe göre kaydırılacaktır",
    ),
    "allow": MessageLookupByLibrary.simpleMessage("İzin ver"),
    "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
      "Bağlantıya sahip olan kişilerin paylaşılan albüme fotoğraf eklemelerine izin ver.",
    ),
    "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
      "Fotoğraf eklemeye izin ver",
    ),
    "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
      "Uygulamanın paylaşılan albüm bağlantılarını açmasına izin ver",
    ),
    "allowDownloads": MessageLookupByLibrary.simpleMessage(
      "İndirmeye izin ver",
    ),
    "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
      "Kullanıcıların fotoğraf eklemesine izin ver",
    ),
    "allowPermBody": MessageLookupByLibrary.simpleMessage(
      "Ente\'nin kitaplığınızı görüntüleyebilmesi ve yedekleyebilmesi için lütfen Ayarlar\'dan fotoğraflarınıza erişime izin verin.",
    ),
    "allowPermTitle": MessageLookupByLibrary.simpleMessage(
      "Fotoğraflara erişime izin verin",
    ),
    "androidBiometricHint": MessageLookupByLibrary.simpleMessage(
      "Kimliği doğrula",
    ),
    "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
      "Tanınmadı. Tekrar deneyin.",
    ),
    "androidBiometricRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "Biyometrik gerekli",
    ),
    "androidBiometricSuccess": MessageLookupByLibrary.simpleMessage("Başarılı"),
    "androidCancelButton": MessageLookupByLibrary.simpleMessage("İptal et"),
    "androidDeviceCredentialsRequiredTitle":
        MessageLookupByLibrary.simpleMessage("Cihaz kimlik bilgileri gerekli"),
    "androidDeviceCredentialsSetupDescription":
        MessageLookupByLibrary.simpleMessage(
          "Cihaz kimlik bilgileri gerekmekte",
        ),
    "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Biyometrik kimlik doğrulama cihazınızda ayarlanmamış. Biyometrik kimlik doğrulama eklemek için \'Ayarlar > Güvenlik\' bölümüne gidin.",
    ),
    "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
      "Android, iOS, Web, Masaüstü",
    ),
    "androidSignInTitle": MessageLookupByLibrary.simpleMessage(
      "Kimlik doğrulaması gerekli",
    ),
    "appIcon": MessageLookupByLibrary.simpleMessage("Uygulama simgesi"),
    "appLock": MessageLookupByLibrary.simpleMessage("Uygulama kilidi"),
    "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
      "Cihazınızın varsayılan kilit ekranı ile PIN veya parola içeren özel bir kilit ekranı arasında seçim yapın.",
    ),
    "appVersion": m9,
    "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
    "apply": MessageLookupByLibrary.simpleMessage("Uygula"),
    "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Kodu girin"),
    "appstoreSubscription": MessageLookupByLibrary.simpleMessage(
      "AppStore aboneliği",
    ),
    "archive": MessageLookupByLibrary.simpleMessage("Arşiv"),
    "archiveAlbum": MessageLookupByLibrary.simpleMessage("Albümü arşivle"),
    "archiving": MessageLookupByLibrary.simpleMessage("Arşivleniyor..."),
    "areThey": MessageLookupByLibrary.simpleMessage("Onlar mı "),
    "areYouSureRemoveThisFaceFromPerson": MessageLookupByLibrary.simpleMessage(
      "Bu yüzü bu kişiden çıkarmak istediğine emin misin?",
    ),
    "areYouSureThatYouWantToLeaveTheFamily":
        MessageLookupByLibrary.simpleMessage(
          "Aile planından ayrılmak istediğinize emin misiniz?",
        ),
    "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
      "İptal etmek istediğinize emin misiniz?",
    ),
    "areYouSureYouWantToChangeYourPlan": MessageLookupByLibrary.simpleMessage(
      "Planı değistirmek istediğinize emin misiniz?",
    ),
    "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
      "Çıkmak istediğinden emin misiniz?",
    ),
    "areYouSureYouWantToIgnoreThesePersons":
        MessageLookupByLibrary.simpleMessage(
          "Bu insanları görmezden gelmek istediğine emin misiniz?",
        ),
    "areYouSureYouWantToIgnoreThisPerson": MessageLookupByLibrary.simpleMessage(
      "Bu kişiyi görmezden gelmek istediğine emin misin?",
    ),
    "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
      "Çıkış yapmak istediğinize emin misiniz?",
    ),
    "areYouSureYouWantToMergeThem": MessageLookupByLibrary.simpleMessage(
      "Onları birleştirmek istediğine emin misiniz?",
    ),
    "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
      "Yenilemek istediğinize emin misiniz?",
    ),
    "areYouSureYouWantToResetThisPerson": MessageLookupByLibrary.simpleMessage(
      "Bu kişiyi sıfırlamak istediğinden emin misiniz?",
    ),
    "askCancelReason": MessageLookupByLibrary.simpleMessage(
      "Aboneliğiniz iptal edilmiştir. Bunun sebebini paylaşmak ister misiniz?",
    ),
    "askDeleteReason": MessageLookupByLibrary.simpleMessage(
      "Hesabınızı silme sebebiniz nedir?",
    ),
    "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
      "Sevdiklerinizden paylaşmalarını isteyin",
    ),
    "atAFalloutShelter": MessageLookupByLibrary.simpleMessage(
      "serpinti sığınağında",
    ),
    "authToChangeEmailVerificationSetting": MessageLookupByLibrary.simpleMessage(
      "E-posta doğrulamasını değiştirmek için lütfen kimlik doğrulaması yapın",
    ),
    "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
      "Kilit ekranı ayarını değiştirmek için lütfen kimliğinizi doğrulayın",
    ),
    "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
      "E-postanızı değiştirmek için lütfen kimlik doğrulaması yapın",
    ),
    "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
      "Şifrenizi değiştirmek için lütfen kimlik doğrulaması yapın",
    ),
    "authToConfigureTwofactorAuthentication": MessageLookupByLibrary.simpleMessage(
      "İki faktörlü kimlik doğrulamayı yapılandırmak için lütfen kimlik doğrulaması yapın",
    ),
    "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
      "Hesap silme işlemini başlatmak için lütfen kimlik doğrulaması yapın",
    ),
    "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
      "Güvenilir kişilerinizi yönetmek için lütfen kimlik doğrulaması yapın",
    ),
    "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
      "Geçiş anahtarınızı görüntülemek için lütfen kimlik doğrulaması yapın",
    ),
    "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
      "Çöp dosyalarınızı görüntülemek için lütfen kimlik doğrulaması yapın",
    ),
    "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
      "Aktif oturumlarınızı görüntülemek için lütfen kimliğinizi doğrulayın",
    ),
    "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
      "Gizli dosyalarınızı görüntülemek için kimlik doğrulama yapınız",
    ),
    "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
      "Kodlarınızı görmek için lütfen kimlik doğrulaması yapın",
    ),
    "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Kurtarma anahtarınızı görmek için lütfen kimliğinizi doğrulayın",
    ),
    "authenticating": MessageLookupByLibrary.simpleMessage(
      "Kimlik doğrulanıyor...",
    ),
    "authenticationFailedPleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Kimlik doğrulama başarısız oldu, lütfen tekrar deneyin",
    ),
    "authenticationSuccessful": MessageLookupByLibrary.simpleMessage(
      "Kimlik doğrulama başarılı!",
    ),
    "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
      "Mevcut Cast cihazlarını burada görebilirsiniz.",
    ),
    "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
      "Ayarlar\'da Ente Photos uygulaması için Yerel Ağ izinlerinin açık olduğundan emin olun.",
    ),
    "autoLock": MessageLookupByLibrary.simpleMessage("Otomatik Kilit"),
    "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
      "Uygulama arka plana geçtikten sonra kilitleneceği süre",
    ),
    "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
      "Teknik aksaklık nedeniyle oturumunuz kapatıldı. Verdiğimiz rahatsızlıktan dolayı özür dileriz.",
    ),
    "autoPair": MessageLookupByLibrary.simpleMessage("Otomatik eşle"),
    "autoPairDesc": MessageLookupByLibrary.simpleMessage(
      "Otomatik eşleştirme yalnızca Chromecast destekleyen cihazlarla çalışır.",
    ),
    "available": MessageLookupByLibrary.simpleMessage("Mevcut"),
    "availableStorageSpace": m10,
    "backedUpFolders": MessageLookupByLibrary.simpleMessage(
      "Yedeklenmiş klasörler",
    ),
    "backgroundWithThem": m11,
    "backup": MessageLookupByLibrary.simpleMessage("Yedekle"),
    "backupFailed": MessageLookupByLibrary.simpleMessage(
      "Yedekleme başarısız oldu",
    ),
    "backupFile": MessageLookupByLibrary.simpleMessage("Yedek Dosyası"),
    "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
      "Mobil veri ile yedekle",
    ),
    "backupSettings": MessageLookupByLibrary.simpleMessage(
      "Yedekleme seçenekleri",
    ),
    "backupStatus": MessageLookupByLibrary.simpleMessage("Yedekleme durumu"),
    "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Eklenen öğeler burada görünecek",
    ),
    "backupVideos": MessageLookupByLibrary.simpleMessage("Videoları yedekle"),
    "beach": MessageLookupByLibrary.simpleMessage("Kum ve deniz"),
    "birthday": MessageLookupByLibrary.simpleMessage("Doğum Günü"),
    "birthdayNotifications": MessageLookupByLibrary.simpleMessage(
      "Doğum günü bildirimleri",
    ),
    "birthdays": MessageLookupByLibrary.simpleMessage("Doğum Günleri"),
    "blackFridaySale": MessageLookupByLibrary.simpleMessage(
      "Muhteşem Cuma kampanyası",
    ),
    "blog": MessageLookupByLibrary.simpleMessage("Blog"),
    "cLDesc1": MessageLookupByLibrary.simpleMessage(
      "Video akışı beta sürümünün arkasında ve devam ettirilebilir yüklemeler ve indirmeler üzerinde çalışırken, artık dosya yükleme sınırını 10 GB\'a çıkardık. Bu artık hem masaüstü hem de mobil uygulamalarda kullanılabilir.",
    ),
    "cLDesc2": MessageLookupByLibrary.simpleMessage(
      "Arka plan yüklemeleri artık Android cihazlara ek olarak iOS\'ta da destekleniyor. En son fotoğraflarınızı ve videolarınızı yedeklemek için uygulamayı açmanıza gerek yok.",
    ),
    "cLDesc3": MessageLookupByLibrary.simpleMessage(
      "Otomatik oynatma, bir sonraki belleğe kaydırma ve çok daha fazlası dahil olmak üzere bellek deneyimimizde önemli iyileştirmeler yaptık.",
    ),
    "cLDesc4": MessageLookupByLibrary.simpleMessage(
      "Bazı arka plandaki iyileştirmelere ek olarak, artık tespit edilen tüm yüzleri görmek, benzer yüzler hakkında geri bildirimde bulunmak ve tek bir fotoğraftan yüz ekleyip çıkarmak çok daha kolay.",
    ),
    "cLDesc5": MessageLookupByLibrary.simpleMessage(
      "Ente’ye kaydettiğiniz tüm doğum günleri için artık en iyi fotoğraflarından oluşan bir koleksiyonla birlikte, devre dışı bırakabileceğiniz bir bildirim alacaksınız.",
    ),
    "cLDesc6": MessageLookupByLibrary.simpleMessage(
      "Uygulamayı kapatmadan önce yüklemelerin / indirmelerin tamamlanmasını beklemenize gerek yok. Tüm yüklemeler ve indirmeler artık yarıda duraklatma ve kaldığınız yerden devam etme özelliğine sahip.",
    ),
    "cLTitle1": MessageLookupByLibrary.simpleMessage(
      "Büyük Video Dosyalarını Yükleme",
    ),
    "cLTitle2": MessageLookupByLibrary.simpleMessage("Arka Plan Yükleme"),
    "cLTitle3": MessageLookupByLibrary.simpleMessage(
      "Otomatik Oynatma Anıları",
    ),
    "cLTitle4": MessageLookupByLibrary.simpleMessage(
      "Geliştirilmiş Yüz Tanıma",
    ),
    "cLTitle5": MessageLookupByLibrary.simpleMessage("Doğum Günü Bildirimleri"),
    "cLTitle6": MessageLookupByLibrary.simpleMessage(
      "Devam Ettirilebilir Yüklemeler ve İndirmeler",
    ),
    "cachedData": MessageLookupByLibrary.simpleMessage(
      "Önbelleğe alınmış veriler",
    ),
    "calculating": MessageLookupByLibrary.simpleMessage("Hesaplanıyor..."),
    "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
      "Üzgünüz, Bu albüm uygulama içinde açılamadı.",
    ),
    "canNotOpenTitle": MessageLookupByLibrary.simpleMessage("Albüm açılamadı"),
    "canNotUploadToAlbumsOwnedByOthers": MessageLookupByLibrary.simpleMessage(
      "Başkalarına ait albümlere yüklenemez",
    ),
    "canOnlyCreateLinkForFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
      "Yalnızca size ait dosyalar için bağlantı oluşturabilir",
    ),
    "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
      "Yalnızca size ait dosyaları kaldırabilir",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("İptal et"),
    "cancelAccountRecovery": MessageLookupByLibrary.simpleMessage(
      "Kurtarma işlemini iptal et",
    ),
    "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
      "Kurtarmayı iptal etmek istediğinize emin misiniz?",
    ),
    "cancelOtherSubscription": m12,
    "cancelSubscription": MessageLookupByLibrary.simpleMessage(
      "Abonelik iptali",
    ),
    "cannotAddMorePhotosAfterBecomingViewer": m13,
    "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
      "Dosyalar silinemiyor",
    ),
    "castAlbum": MessageLookupByLibrary.simpleMessage("Yayın albümü"),
    "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
      "Lütfen TV ile aynı ağda olduğunuzdan emin olun.",
    ),
    "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
      "Albüm yüklenirken hata oluştu",
    ),
    "castInstruction": MessageLookupByLibrary.simpleMessage(
      "Eşleştirmek istediğiniz cihazda cast.ente.io adresini ziyaret edin.\n\nAlbümü TV\'nizde oynatmak için aşağıdaki kodu girin.",
    ),
    "centerPoint": MessageLookupByLibrary.simpleMessage("Merkez noktası"),
    "change": MessageLookupByLibrary.simpleMessage("Değiştir"),
    "changeEmail": MessageLookupByLibrary.simpleMessage(
      "E-posta adresini değiştir",
    ),
    "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
      "Seçilen öğelerin konumu değiştirilsin mi?",
    ),
    "changePassword": MessageLookupByLibrary.simpleMessage(
      "Şifrenizi değiştirin",
    ),
    "changePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Parolanızı değiştirin",
    ),
    "changePermissions": MessageLookupByLibrary.simpleMessage(
      "İzinleri değiştir?",
    ),
    "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
      "Referans kodunuzu değiştirin",
    ),
    "checkForUpdates": MessageLookupByLibrary.simpleMessage(
      "Güncellemeleri kontol et",
    ),
    "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
      "Lütfen doğrulama işlemini tamamlamak için gelen kutunuzu (ve spam klasörünüzü) kontrol edin",
    ),
    "checkStatus": MessageLookupByLibrary.simpleMessage("Durumu kontrol edin"),
    "checking": MessageLookupByLibrary.simpleMessage("Kontrol ediliyor..."),
    "checkingModels": MessageLookupByLibrary.simpleMessage(
      "Modeller kontrol ediliyor...",
    ),
    "city": MessageLookupByLibrary.simpleMessage("Şehirde"),
    "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
      "Bedava alan kazanın",
    ),
    "claimMore": MessageLookupByLibrary.simpleMessage("Arttır!"),
    "claimed": MessageLookupByLibrary.simpleMessage("Alındı"),
    "claimedStorageSoFar": m14,
    "cleanUncategorized": MessageLookupByLibrary.simpleMessage("Temiz Genel"),
    "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
      "Diğer albümlerde bulunan Kategorilenmemiş tüm dosyaları kaldırın",
    ),
    "clearCaches": MessageLookupByLibrary.simpleMessage("Önbelleği temizle"),
    "clearIndexes": MessageLookupByLibrary.simpleMessage("Dizinleri temizle"),
    "click": MessageLookupByLibrary.simpleMessage("• Tıklamak"),
    "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
      "• Taşma menüsüne tıklayın",
    ),
    "clickToInstallOurBestVersionYet": MessageLookupByLibrary.simpleMessage(
      "Bugüne kadarki en iyi sürümümüzü yüklemek için tıklayın",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Kapat"),
    "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
      "Yakalama zamanına göre kulüp",
    ),
    "clubByFileName": MessageLookupByLibrary.simpleMessage(
      "Dosya adına göre kulüp",
    ),
    "clusteringProgress": MessageLookupByLibrary.simpleMessage(
      "Kümeleme ilerlemesi",
    ),
    "codeAppliedPageTitle": MessageLookupByLibrary.simpleMessage(
      "Kod kabul edildi",
    ),
    "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
      "Üzgünüz, kod değişikliklerinin sınırına ulaştınız.",
    ),
    "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Kodunuz panoya kopyalandı",
    ),
    "codeUsedByYou": MessageLookupByLibrary.simpleMessage(
      "Sizin kullandığınız kod",
    ),
    "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
      "Ente aplikasyonu veya hesabı olmadan insanların paylaşılan albümde fotoğraf ekleyip görüntülemelerine izin vermek için bir bağlantı oluşturun. Grup veya etkinlik fotoğraflarını toplamak için harika bir seçenek.",
    ),
    "collaborativeLink": MessageLookupByLibrary.simpleMessage("Ortak bağlantı"),
    "collaborativeLinkCreatedFor": m15,
    "collaborator": MessageLookupByLibrary.simpleMessage("Düzenleyici"),
    "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
        MessageLookupByLibrary.simpleMessage(
          "Düzenleyiciler, paylaşılan albüme fotoğraf ve videolar ekleyebilir.",
        ),
    "collaboratorsSuccessfullyAdded": m16,
    "collageLayout": MessageLookupByLibrary.simpleMessage("Düzen"),
    "collageSaved": MessageLookupByLibrary.simpleMessage(
      "Kolajınız galeriye kaydedildi",
    ),
    "collect": MessageLookupByLibrary.simpleMessage("Topla"),
    "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
      "Etkinlik fotoğraflarını topla",
    ),
    "collectPhotos": MessageLookupByLibrary.simpleMessage("Fotoğrafları topla"),
    "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
      "Arkadaşlarınızın orijinal kalitede fotoğraf yükleyebileceği bir bağlantı oluşturun.",
    ),
    "color": MessageLookupByLibrary.simpleMessage("Renk"),
    "configuration": MessageLookupByLibrary.simpleMessage("Yapılandırma"),
    "confirm": MessageLookupByLibrary.simpleMessage("Onayla"),
    "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
      "İki adımlı kimlik doğrulamasını devre dışı bırakmak istediğinize emin misiniz?",
    ),
    "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
      "Hesap silme işlemini onayla",
    ),
    "confirmAddingTrustedContact": m17,
    "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
      "Evet, bu hesabı ve verilerini tüm uygulamalardan kalıcı olarak silmek istiyorum.",
    ),
    "confirmPassword": MessageLookupByLibrary.simpleMessage(
      "Şifrenizi onaylayın",
    ),
    "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
      "Plan değişikliğini onaylayın",
    ),
    "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Kurtarma anahtarını doğrula",
    ),
    "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Kurtarma anahtarını doğrulayın",
    ),
    "connectToDevice": MessageLookupByLibrary.simpleMessage("Cihaza bağlanın"),
    "contactFamilyAdmin": m18,
    "contactSupport": MessageLookupByLibrary.simpleMessage(
      "Destek ile iletişim",
    ),
    "contactToManageSubscription": m19,
    "contacts": MessageLookupByLibrary.simpleMessage("Kişiler"),
    "contents": MessageLookupByLibrary.simpleMessage("İçerikler"),
    "continueLabel": MessageLookupByLibrary.simpleMessage("Devam edin"),
    "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
      "Ücretsiz denemeye devam et",
    ),
    "convertToAlbum": MessageLookupByLibrary.simpleMessage("Albüme taşı"),
    "copyEmailAddress": MessageLookupByLibrary.simpleMessage(
      "E-posta adresini kopyala",
    ),
    "copyLink": MessageLookupByLibrary.simpleMessage("Bağlantıyı kopyala"),
    "copypasteThisCodentoYourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Bu kodu kopyalayın ve kimlik doğrulama uygulamanıza yapıştırın",
        ),
    "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
      "Verilerinizi yedekleyemedik.\nDaha sonra tekrar deneyeceğiz.",
    ),
    "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
      "Yer boşaltılamadı",
    ),
    "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
      "Abonelikler kaydedilemedi",
    ),
    "count": MessageLookupByLibrary.simpleMessage("Miktar"),
    "crashReporting": MessageLookupByLibrary.simpleMessage("Çökme raporlaması"),
    "create": MessageLookupByLibrary.simpleMessage("Oluştur"),
    "createAccount": MessageLookupByLibrary.simpleMessage("Hesap oluşturun"),
    "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
      "Fotoğrafları seçmek için uzun basın ve + düğmesine tıklayarak bir albüm oluşturun",
    ),
    "createCollaborativeLink": MessageLookupByLibrary.simpleMessage(
      "Ortak bağlantı oluşturun",
    ),
    "createCollage": MessageLookupByLibrary.simpleMessage("Kolaj oluştur"),
    "createNewAccount": MessageLookupByLibrary.simpleMessage(
      "Yeni bir hesap oluşturun",
    ),
    "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage(
      "Albüm oluştur veya seç",
    ),
    "createPublicLink": MessageLookupByLibrary.simpleMessage(
      "Herkese açık bir bağlantı oluştur",
    ),
    "creatingLink": MessageLookupByLibrary.simpleMessage(
      "Bağlantı oluşturuluyor...",
    ),
    "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Kritik güncelleme mevcut",
    ),
    "crop": MessageLookupByLibrary.simpleMessage("Kırp"),
    "curatedMemories": MessageLookupByLibrary.simpleMessage("Seçilmiş anılar"),
    "currentUsageIs": MessageLookupByLibrary.simpleMessage(
      "Güncel kullanımınız ",
    ),
    "currentlyRunning": MessageLookupByLibrary.simpleMessage(
      "şu anda çalışıyor",
    ),
    "custom": MessageLookupByLibrary.simpleMessage("Özel"),
    "customEndpoint": m20,
    "darkTheme": MessageLookupByLibrary.simpleMessage("Karanlık"),
    "dayToday": MessageLookupByLibrary.simpleMessage("Bugün"),
    "dayYesterday": MessageLookupByLibrary.simpleMessage("Dün"),
    "declineTrustInvite": MessageLookupByLibrary.simpleMessage("Daveti Reddet"),
    "decrypting": MessageLookupByLibrary.simpleMessage("Şifre çözülüyor..."),
    "decryptingVideo": MessageLookupByLibrary.simpleMessage(
      "Videonun şifresi çözülüyor...",
    ),
    "deduplicateFiles": MessageLookupByLibrary.simpleMessage(
      "Dosyaları Tekilleştirme",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Sil"),
    "deleteAccount": MessageLookupByLibrary.simpleMessage("Hesabı sil"),
    "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
      "Gittiğini gördüğümüze üzüldük. Lütfen gelişmemize yardımcı olmak için neden ayrıldığınızı açıklayın.",
    ),
    "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
      "Hesabımı kalıcı olarak sil",
    ),
    "deleteAlbum": MessageLookupByLibrary.simpleMessage("Albümü sil"),
    "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
      "Ayrıca bu albümde bulunan fotoğrafları (ve videoları) parçası oldukları <bold>tüm</bold> diğer albümlerden silebilir miyim?",
    ),
    "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
      "Bu, tüm boş albümleri silecektir. Bu, albüm listenizdeki dağınıklığı azaltmak istediğinizde kullanışlıdır.",
    ),
    "deleteAll": MessageLookupByLibrary.simpleMessage("Hepsini Sil"),
    "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
      "Kullandığınız Ente uygulamaları varsa bu hesap diğer Ente uygulamalarıyla bağlantılıdır. Tüm Ente uygulamalarına yüklediğiniz veriler ve hesabınız kalıcı olarak silinecektir.",
    ),
    "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
      "Lütfen kayıtlı e-posta adresinizden <warning> account-deletion@ente.io</warning>\'ya e-posta gönderiniz.",
    ),
    "deleteEmptyAlbums": MessageLookupByLibrary.simpleMessage(
      "Boş albümleri sil",
    ),
    "deleteEmptyAlbumsWithQuestionMark": MessageLookupByLibrary.simpleMessage(
      "Boş albümler silinsin mi?",
    ),
    "deleteFromBoth": MessageLookupByLibrary.simpleMessage(
      "Her ikisinden de sil",
    ),
    "deleteFromDevice": MessageLookupByLibrary.simpleMessage(
      "Cihazınızdan silin",
    ),
    "deleteFromEnte": MessageLookupByLibrary.simpleMessage("Ente\'den Sil"),
    "deleteItemCount": m21,
    "deleteLocation": MessageLookupByLibrary.simpleMessage("Konumu sil"),
    "deleteMultipleAlbumDialog": m22,
    "deletePhotos": MessageLookupByLibrary.simpleMessage("Fotoğrafları sil"),
    "deleteProgress": m23,
    "deleteReason1": MessageLookupByLibrary.simpleMessage(
      "İhtiyacım olan önemli bir özellik eksik",
    ),
    "deleteReason2": MessageLookupByLibrary.simpleMessage(
      "Uygulama veya bir özellik olması gerektiğini düşündüğüm gibi çalışmıyor",
    ),
    "deleteReason3": MessageLookupByLibrary.simpleMessage(
      "Daha çok sevdiğim başka bir hizmet buldum",
    ),
    "deleteReason4": MessageLookupByLibrary.simpleMessage(
      "Nedenim listede yok",
    ),
    "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
      "İsteğiniz 72 saat içinde gerçekleştirilecek.",
    ),
    "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
      "Paylaşılan albüm silinsin mi?",
    ),
    "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
      "Albüm herkes için silinecek\n\nBu albümdeki başkalarına ait paylaşılan fotoğraflara erişiminizi kaybedeceksiniz",
    ),
    "deselectAll": MessageLookupByLibrary.simpleMessage("Tüm seçimi kaldır"),
    "designedToOutlive": MessageLookupByLibrary.simpleMessage(
      "Hayatta kalmak için tasarlandı",
    ),
    "details": MessageLookupByLibrary.simpleMessage("Ayrıntılar"),
    "developerSettings": MessageLookupByLibrary.simpleMessage(
      "Geliştirici ayarları",
    ),
    "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
      "Geliştirici ayarlarını değiştirmek istediğinizden emin misiniz?",
    ),
    "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Kodu girin"),
    "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
      "Bu cihazın albümüne eklenen dosyalar otomatik olarak ente\'ye yüklenecektir.",
    ),
    "deviceLock": MessageLookupByLibrary.simpleMessage("Cihaz kilidi"),
    "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
      "Ente uygulaması önplanda calıştığında ve bir yedekleme işlemi devam ettiğinde, cihaz ekran kilidini devre dışı bırakın. Bu genellikle gerekli olmasa da, büyük dosyaların yüklenmesi ve büyük kütüphanelerin başlangıçta içe aktarılması sürecini hızlandırabilir.",
    ),
    "deviceNotFound": MessageLookupByLibrary.simpleMessage("Cihaz bulunamadı"),
    "didYouKnow": MessageLookupByLibrary.simpleMessage("Biliyor musun?"),
    "different": MessageLookupByLibrary.simpleMessage("Farklı"),
    "disableAutoLock": MessageLookupByLibrary.simpleMessage(
      "Otomatik kilidi devre dışı bırak",
    ),
    "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
      "Görüntüleyiciler, hala harici araçlar kullanarak ekran görüntüsü alabilir veya fotoğraflarınızın bir kopyasını kaydedebilir. Lütfen bunu göz önünde bulundurunuz",
    ),
    "disableDownloadWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Lütfen dikkate alın",
    ),
    "disableLinkMessage": m24,
    "disableTwofactor": MessageLookupByLibrary.simpleMessage(
      "İki Aşamalı Doğrulamayı Devre Dışı Bırak",
    ),
    "disablingTwofactorAuthentication": MessageLookupByLibrary.simpleMessage(
      "İki aşamalı doğrulamayı devre dışı bırak...",
    ),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "discover": MessageLookupByLibrary.simpleMessage("Keşfet"),
    "discover_babies": MessageLookupByLibrary.simpleMessage("Bebek"),
    "discover_celebrations": MessageLookupByLibrary.simpleMessage(
      "Kutlamalar ",
    ),
    "discover_food": MessageLookupByLibrary.simpleMessage("Yiyecek"),
    "discover_greenery": MessageLookupByLibrary.simpleMessage("Yeşillik"),
    "discover_hills": MessageLookupByLibrary.simpleMessage("Tepeler"),
    "discover_identity": MessageLookupByLibrary.simpleMessage("Kimlik"),
    "discover_memes": MessageLookupByLibrary.simpleMessage("Mimler"),
    "discover_notes": MessageLookupByLibrary.simpleMessage("Notlar"),
    "discover_pets": MessageLookupByLibrary.simpleMessage("Evcil Hayvanlar"),
    "discover_receipts": MessageLookupByLibrary.simpleMessage("Makbuzlar"),
    "discover_screenshots": MessageLookupByLibrary.simpleMessage(
      "Ekran Görüntüleri",
    ),
    "discover_selfies": MessageLookupByLibrary.simpleMessage("Özçekimler"),
    "discover_sunset": MessageLookupByLibrary.simpleMessage("Gün batımı"),
    "discover_visiting_cards": MessageLookupByLibrary.simpleMessage(
      "Ziyaret Kartları",
    ),
    "discover_wallpapers": MessageLookupByLibrary.simpleMessage(
      "Duvar Kağıtları",
    ),
    "dismiss": MessageLookupByLibrary.simpleMessage("Reddet"),
    "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
    "doNotSignOut": MessageLookupByLibrary.simpleMessage("Çıkış yapma"),
    "doThisLater": MessageLookupByLibrary.simpleMessage("Sonra yap"),
    "doYouWantToDiscardTheEditsYouHaveMade":
        MessageLookupByLibrary.simpleMessage(
          "Yaptığınız düzenlemeleri silmek istiyor musunuz?",
        ),
    "done": MessageLookupByLibrary.simpleMessage("Bitti"),
    "dontSave": MessageLookupByLibrary.simpleMessage("Kaydetme"),
    "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
      "Depolama alanınızı ikiye katlayın",
    ),
    "download": MessageLookupByLibrary.simpleMessage("İndir"),
    "downloadFailed": MessageLookupByLibrary.simpleMessage("İndirme başarısız"),
    "downloading": MessageLookupByLibrary.simpleMessage("İndiriliyor..."),
    "dropSupportEmail": m25,
    "duplicateFileCountWithStorageSaved": m26,
    "duplicateItemsGroup": m27,
    "edit": MessageLookupByLibrary.simpleMessage("Düzenle"),
    "editEmailAlreadyLinked": m28,
    "editLocation": MessageLookupByLibrary.simpleMessage("Konumu düzenle"),
    "editLocationTagTitle": MessageLookupByLibrary.simpleMessage(
      "Konumu düzenle",
    ),
    "editPerson": MessageLookupByLibrary.simpleMessage("Kişiyi düzenle"),
    "editTime": MessageLookupByLibrary.simpleMessage("Zamanı düzenle"),
    "editsSaved": MessageLookupByLibrary.simpleMessage("Düzenleme kaydedildi"),
    "editsToLocationWillOnlyBeSeenWithinEnte":
        MessageLookupByLibrary.simpleMessage(
          "Konumda yapılan düzenlemeler yalnızca Ente\'de görülecektir",
        ),
    "eligible": MessageLookupByLibrary.simpleMessage("uygun"),
    "email": MessageLookupByLibrary.simpleMessage("E-Posta"),
    "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
      "E-posta zaten kayıtlı.",
    ),
    "emailChangedTo": m29,
    "emailDoesNotHaveEnteAccount": m30,
    "emailNoEnteAccount": m31,
    "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
      "E-posta kayıtlı değil.",
    ),
    "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
      "E-posta doğrulama",
    ),
    "emailYourLogs": MessageLookupByLibrary.simpleMessage(
      "Kayıtlarınızı e-postayla gönderin",
    ),
    "embracingThem": m32,
    "emergencyContacts": MessageLookupByLibrary.simpleMessage(
      "Acil Durum İletişim Bilgileri",
    ),
    "empty": MessageLookupByLibrary.simpleMessage("Boşalt"),
    "emptyTrash": MessageLookupByLibrary.simpleMessage(
      "Çöp kutusu boşaltılsın mı?",
    ),
    "enable": MessageLookupByLibrary.simpleMessage("Etkinleştir"),
    "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
      "Ente, yüz tanıma, sihirli arama ve diğer gelişmiş arama özellikleri için cihaz üzerinde çalışan makine öğrenimini kullanır",
    ),
    "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
      "Sihirli arama ve yüz tanıma için makine öğrenimini etkinleştirin",
    ),
    "enableMaps": MessageLookupByLibrary.simpleMessage(
      "Haritaları Etkinleştir",
    ),
    "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
      "Bu, fotoğraflarınızı bir dünya haritasında gösterecektir.\n\nBu harita Open Street Map tarafından barındırılmaktadır ve fotoğraflarınızın tam konumları hiçbir zaman paylaşılmaz.\n\nBu özelliği istediğiniz zaman Ayarlar\'dan devre dışı bırakabilirsiniz.",
    ),
    "enabled": MessageLookupByLibrary.simpleMessage("Etkin"),
    "encryptingBackup": MessageLookupByLibrary.simpleMessage(
      "Yedekleme şifreleniyor...",
    ),
    "encryption": MessageLookupByLibrary.simpleMessage("Şifreleme"),
    "encryptionKeys": MessageLookupByLibrary.simpleMessage(
      "Şifreleme anahtarı",
    ),
    "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
      "Fatura başarıyla güncellendi",
    ),
    "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
      "Varsayılan olarak uçtan uca şifrelenmiş",
    ),
    "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
        MessageLookupByLibrary.simpleMessage(
          "Ente dosyaları yalnızca erişim izni verdiğiniz takdirde şifreleyebilir ve koruyabilir",
        ),
    "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
      "Ente fotoğrafları saklamak için <i>iznine ihtiyaç duyuyor</i>",
    ),
    "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
      "Ente anılarınızı korur, böylece cihazınızı kaybetseniz bile anılarınıza her zaman ulaşabilirsiniz.",
    ),
    "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
      "Aileniz de planınıza eklenebilir.",
    ),
    "enterAlbumName": MessageLookupByLibrary.simpleMessage(
      "Bir albüm adı girin",
    ),
    "enterCode": MessageLookupByLibrary.simpleMessage("Kodu giriniz"),
    "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
      "İkiniz için de ücretsiz depolama alanı talep etmek için arkadaşınız tarafından sağlanan kodu girin",
    ),
    "enterDateOfBirth": MessageLookupByLibrary.simpleMessage(
      "Doğum Günü (isteğe bağlı)",
    ),
    "enterEmail": MessageLookupByLibrary.simpleMessage("E-postanızı giriniz"),
    "enterFileName": MessageLookupByLibrary.simpleMessage("Dosya adını girin"),
    "enterName": MessageLookupByLibrary.simpleMessage("İsim girin"),
    "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
      "Verilerinizi şifrelemek için kullanabileceğimiz yeni bir şifre girin",
    ),
    "enterPassword": MessageLookupByLibrary.simpleMessage("Şifrenizi girin"),
    "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
      "Verilerinizi şifrelemek için kullanabileceğimiz bir şifre girin",
    ),
    "enterPersonName": MessageLookupByLibrary.simpleMessage(
      "Kişi ismini giriniz",
    ),
    "enterPin": MessageLookupByLibrary.simpleMessage("PIN Girin"),
    "enterReferralCode": MessageLookupByLibrary.simpleMessage(
      "Davet kodunuzu girin",
    ),
    "enterThe6digitCodeFromnyourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Doğrulama uygulamasındaki 6 basamaklı kodu giriniz",
        ),
    "enterValidEmail": MessageLookupByLibrary.simpleMessage(
      "Lütfen geçerli bir e-posta adresi girin.",
    ),
    "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
      "E-posta adresinizi girin",
    ),
    "enterYourNewEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Yeni e-posta adresinizi girin",
    ),
    "enterYourPassword": MessageLookupByLibrary.simpleMessage(
      "Lütfen şifrenizi giriniz",
    ),
    "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Kurtarma kodunuzu girin",
    ),
    "error": MessageLookupByLibrary.simpleMessage("Hata"),
    "everywhere": MessageLookupByLibrary.simpleMessage("her yerde"),
    "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
    "existingUser": MessageLookupByLibrary.simpleMessage("Mevcut kullanıcı"),
    "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
      "Bu bağlantının süresi dolmuştur. Lütfen yeni bir süre belirleyin veya bağlantı süresini devre dışı bırakın.",
    ),
    "exportLogs": MessageLookupByLibrary.simpleMessage("Günlüğü dışa aktar"),
    "exportYourData": MessageLookupByLibrary.simpleMessage(
      "Veriyi dışarı aktar",
    ),
    "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
      "Ekstra fotoğraflar bulundu",
    ),
    "extraPhotosFoundFor": m33,
    "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
      "Yüz henüz kümelenmedi, lütfen daha sonra tekrar gelin",
    ),
    "faceRecognition": MessageLookupByLibrary.simpleMessage("Yüz Tanıma"),
    "faces": MessageLookupByLibrary.simpleMessage("Yüzler"),
    "failed": MessageLookupByLibrary.simpleMessage("Başarısız oldu"),
    "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
      "Uygulanırken hata oluştu",
    ),
    "failedToCancel": MessageLookupByLibrary.simpleMessage(
      "İptal edilirken sorun oluştu",
    ),
    "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
      "Video indirilemedi",
    ),
    "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
      "Etkin oturumlar getirilemedi",
    ),
    "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
      "Düzenleme için orijinal getirilemedi",
    ),
    "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
      "Davet ayrıntıları çekilemedi. Iütfen daha sonra deneyin.",
    ),
    "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
      "Albüm yüklenirken hata oluştu",
    ),
    "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
      "Video oynatılamadı",
    ),
    "failedToRefreshStripeSubscription": MessageLookupByLibrary.simpleMessage(
      "Abonelik yenilenemedi",
    ),
    "failedToRenew": MessageLookupByLibrary.simpleMessage(
      "Abonelik yenilenirken hata oluştu",
    ),
    "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
      "Ödeme durumu doğrulanamadı",
    ),
    "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
      "Ekstra ödeme yapmadan mevcut planınıza 5 aile üyesi ekleyin.\n\nHer üyenin kendine ait özel alanı vardır ve paylaşılmadıkça birbirlerinin dosyalarını göremezler.\n\nAile planları ücretli ente aboneliğine sahip müşteriler tarafından kullanılabilir.\n\nBaşlamak için şimdi abone olun!",
    ),
    "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("Aile"),
    "familyPlans": MessageLookupByLibrary.simpleMessage("Aile Planı"),
    "faq": MessageLookupByLibrary.simpleMessage("Sık sorulan sorular"),
    "faqs": MessageLookupByLibrary.simpleMessage("Sık Sorulan Sorular"),
    "favorite": MessageLookupByLibrary.simpleMessage("Favori"),
    "feastingWithThem": m34,
    "feedback": MessageLookupByLibrary.simpleMessage("Geri Bildirim"),
    "file": MessageLookupByLibrary.simpleMessage("Dosya"),
    "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
      "Dosya galeriye kaydedilemedi",
    ),
    "fileInfoAddDescHint": MessageLookupByLibrary.simpleMessage(
      "Bir açıklama ekle...",
    ),
    "fileNotUploadedYet": MessageLookupByLibrary.simpleMessage(
      "Dosya henüz yüklenmedi",
    ),
    "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Video galeriye kaydedildi",
    ),
    "fileTypes": MessageLookupByLibrary.simpleMessage("Dosya türü"),
    "fileTypesAndNames": MessageLookupByLibrary.simpleMessage(
      "Dosya türleri ve adları",
    ),
    "filesBackedUpFromDevice": m35,
    "filesBackedUpInAlbum": m36,
    "filesDeleted": MessageLookupByLibrary.simpleMessage("Dosyalar silinmiş"),
    "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Dosyalar galeriye kaydedildi",
    ),
    "findPeopleByName": MessageLookupByLibrary.simpleMessage(
      "Kişileri isimlerine göre bulun",
    ),
    "findThemQuickly": MessageLookupByLibrary.simpleMessage("Çabucak bulun"),
    "flip": MessageLookupByLibrary.simpleMessage("Çevir"),
    "food": MessageLookupByLibrary.simpleMessage("Yemek keyfi"),
    "forYourMemories": MessageLookupByLibrary.simpleMessage("anılarınız için"),
    "forgotPassword": MessageLookupByLibrary.simpleMessage("Şifremi unuttum"),
    "foundFaces": MessageLookupByLibrary.simpleMessage("Yüzler bulundu"),
    "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
      "Alınan bedava alan",
    ),
    "freeStorageOnReferralSuccess": m37,
    "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
      "Kullanılabilir bedava alan",
    ),
    "freeTrial": MessageLookupByLibrary.simpleMessage("Ücretsiz deneme"),
    "freeTrialValidTill": m38,
    "freeUpAccessPostDelete": m39,
    "freeUpAmount": m40,
    "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
      "Cihaz alanını boşaltın",
    ),
    "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
      "Zaten yedeklenmiş dosyaları temizleyerek cihazınızda yer kazanın.",
    ),
    "freeUpSpace": MessageLookupByLibrary.simpleMessage("Boş alan"),
    "freeUpSpaceSaving": m41,
    "gallery": MessageLookupByLibrary.simpleMessage("Galeri"),
    "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
      "Galeride 1000\'e kadar anı gösterilir",
    ),
    "general": MessageLookupByLibrary.simpleMessage("Genel"),
    "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
      "Şifreleme anahtarı oluşturuluyor...",
    ),
    "genericProgress": m42,
    "goToSettings": MessageLookupByLibrary.simpleMessage("Ayarlara git"),
    "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
    "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
      "Lütfen Ayarlar uygulamasında tüm fotoğraflara erişime izin verin",
    ),
    "grantPermission": MessageLookupByLibrary.simpleMessage(
      "İzinleri değiştir",
    ),
    "greenery": MessageLookupByLibrary.simpleMessage("Yeşil yaşam"),
    "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
      "Yakındaki fotoğrafları gruplandır",
    ),
    "guestView": MessageLookupByLibrary.simpleMessage("Misafir Görünümü"),
    "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
      "Misafir görünümünü etkinleştirmek için lütfen sistem ayarlarınızda cihaz şifresi veya ekran kilidi ayarlayın.",
    ),
    "happyBirthday": MessageLookupByLibrary.simpleMessage(
      "Doğum günün kutlu olsun! 🥳",
    ),
    "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
      "Biz uygulama kurulumlarını takip etmiyoruz. Bizi nereden duyduğunuzdan bahsetmeniz bize çok yardımcı olacak!",
    ),
    "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
      "Ente\'yi nereden duydunuz? (isteğe bağlı)",
    ),
    "help": MessageLookupByLibrary.simpleMessage("Yardım"),
    "hidden": MessageLookupByLibrary.simpleMessage("Gizle"),
    "hide": MessageLookupByLibrary.simpleMessage("Gizle"),
    "hideContent": MessageLookupByLibrary.simpleMessage("İçeriği gizle"),
    "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
      "Uygulama değiştiricide bulunan uygulama içeriğini gizler ve ekran görüntülerini devre dışı bırakır",
    ),
    "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
      "Uygulama değiştiricideki uygulama içeriğini gizler",
    ),
    "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
      "Paylaşılan öğeleri ana galeriden gizle",
    ),
    "hiding": MessageLookupByLibrary.simpleMessage("Gizleniyor..."),
    "hikingWithThem": m43,
    "hostedAtOsmFrance": MessageLookupByLibrary.simpleMessage(
      "OSM Fransa\'da ağırlandı",
    ),
    "howItWorks": MessageLookupByLibrary.simpleMessage("Nasıl çalışır"),
    "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
      "Lütfen onlardan ayarlar ekranında e-posta adresine uzun süre basmalarını ve her iki cihazdaki kimliklerin eşleştiğini doğrulamalarını isteyin.",
    ),
    "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Cihazınızda biyometrik kimlik doğrulama ayarlanmamış. Lütfen telefonunuzda Touch ID veya Face ID\'yi etkinleştirin.",
    ),
    "iOSLockOut": MessageLookupByLibrary.simpleMessage(
      "Biyometrik kimlik doğrulama devre dışı. Etkinleştirmek için lütfen ekranınızı kilitleyin ve kilidini açın.",
    ),
    "iOSOkButton": MessageLookupByLibrary.simpleMessage("Tamam"),
    "ignore": MessageLookupByLibrary.simpleMessage("Yoksay"),
    "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Yoksay"),
    "ignored": MessageLookupByLibrary.simpleMessage("yoksayıldı"),
    "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
      "Bu albümdeki bazı dosyalar daha önce ente\'den silindiğinden yükleme işleminde göz ardı edildi.",
    ),
    "imageNotAnalyzed": MessageLookupByLibrary.simpleMessage(
      "Görüntü analiz edilmedi",
    ),
    "immediately": MessageLookupByLibrary.simpleMessage("Hemen"),
    "importing": MessageLookupByLibrary.simpleMessage("İçeri aktarılıyor...."),
    "incorrectCode": MessageLookupByLibrary.simpleMessage("Yanlış kod"),
    "incorrectPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Yanlış şifre",
    ),
    "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Yanlış kurtarma kodu",
    ),
    "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
      "Girdiğiniz kurtarma kod yanlış",
    ),
    "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
      "Yanlış kurtarma kodu",
    ),
    "indexedItems": MessageLookupByLibrary.simpleMessage("Dizinlenmiş öğeler"),
    "indexingPausedStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Dizin oluşturma duraklatıldı. Cihaz hazır olduğunda otomatik olarak devam edecektir. Cihaz, pil seviyesi, pil sağlığı ve termal durumu sağlıklı bir aralıkta olduğunda hazır kabul edilir.",
    ),
    "ineligible": MessageLookupByLibrary.simpleMessage("Uygun Değil"),
    "info": MessageLookupByLibrary.simpleMessage("Bilgi"),
    "insecureDevice": MessageLookupByLibrary.simpleMessage(
      "Güvenilir olmayan cihaz",
    ),
    "installManually": MessageLookupByLibrary.simpleMessage("Manuel kurulum"),
    "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Geçersiz e-posta adresi",
    ),
    "invalidEndpoint": MessageLookupByLibrary.simpleMessage(
      "Geçersiz uç nokta",
    ),
    "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
      "Üzgünüz, girdiğiniz uç nokta geçersiz. Lütfen geçerli bir uç nokta girin ve tekrar deneyin.",
    ),
    "invalidKey": MessageLookupByLibrary.simpleMessage("Gecersiz anahtar"),
    "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Girdiğiniz kurtarma anahtarı geçerli değil. Lütfen anahtarın 24 kelime içerdiğinden ve her bir kelimenin doğru şekilde yazıldığından emin olun.\n\nEğer eski bir kurtarma kodu girdiyseniz, o zaman kodun 64 karakter uzunluğunda olduğunu kontrol edin.",
    ),
    "invite": MessageLookupByLibrary.simpleMessage("Davet et"),
    "inviteToEnte": MessageLookupByLibrary.simpleMessage("Ente\'ye davet edin"),
    "inviteYourFriends": MessageLookupByLibrary.simpleMessage(
      "Arkadaşlarını davet et",
    ),
    "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
      "Katılmaları için arkadaşlarınızı davet edin",
    ),
    "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
        MessageLookupByLibrary.simpleMessage(
          "Bir şeyler ters gitmiş gibi görünüyor. Lütfen bir süre sonra tekrar deneyin. Hata devam ederse, lütfen destek ekibimizle iletişime geçin.",
        ),
    "itemCount": m44,
    "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
        MessageLookupByLibrary.simpleMessage(
          "Öğeler kalıcı olarak silinmeden önce kalan gün sayısını gösterir",
        ),
    "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
      "Seçilen öğeler bu albümden kaldırılacak",
    ),
    "join": MessageLookupByLibrary.simpleMessage("Katıl"),
    "joinAlbum": MessageLookupByLibrary.simpleMessage("Albüme Katılın"),
    "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
      "Bir albüme katılmak, e-postanızın katılımcılar tarafından görülebilmesini sağlayacaktır.",
    ),
    "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
      "fotoğraflarınızı görüntülemek ve eklemek için",
    ),
    "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
      "bunu paylaşılan albümlere eklemek için",
    ),
    "joinDiscord": MessageLookupByLibrary.simpleMessage("Discord\'a Katıl"),
    "keepPhotos": MessageLookupByLibrary.simpleMessage("Fotoğrafları sakla"),
    "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
    "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
      "Lütfen bu bilgilerle bize yardımcı olun",
    ),
    "language": MessageLookupByLibrary.simpleMessage("Dil"),
    "lastTimeWithThem": m45,
    "lastUpdated": MessageLookupByLibrary.simpleMessage("En son güncellenen"),
    "lastYearsTrip": MessageLookupByLibrary.simpleMessage("Geçen yılki gezi"),
    "leave": MessageLookupByLibrary.simpleMessage("Ayrıl"),
    "leaveAlbum": MessageLookupByLibrary.simpleMessage(
      "Albümü yeniden adlandır",
    ),
    "leaveFamily": MessageLookupByLibrary.simpleMessage("Aile planından ayrıl"),
    "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
      "Paylaşılan albüm silinsin mi?",
    ),
    "left": MessageLookupByLibrary.simpleMessage("Sol"),
    "legacy": MessageLookupByLibrary.simpleMessage("Geleneksel"),
    "legacyAccounts": MessageLookupByLibrary.simpleMessage(
      "Geleneksel hesaplar",
    ),
    "legacyInvite": m46,
    "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
      "Geleneksel yol, güvendiğiniz kişilerin yokluğunuzda hesabınıza erişmesine olanak tanır.",
    ),
    "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
      "Güvenilir kişiler hesap kurtarma işlemini başlatabilir ve 30 gün içinde engellenmezse şifrenizi sıfırlayabilir ve hesabınıza erişebilir.",
    ),
    "light": MessageLookupByLibrary.simpleMessage("Aydınlık"),
    "lightTheme": MessageLookupByLibrary.simpleMessage("Aydınlık"),
    "link": MessageLookupByLibrary.simpleMessage("Bağlantı"),
    "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Link panoya kopyalandı",
    ),
    "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Cihaz sınırı"),
    "linkEmail": MessageLookupByLibrary.simpleMessage("E-posta bağlantısı"),
    "linkEmailToContactBannerCaption": MessageLookupByLibrary.simpleMessage(
      "daha hızlı paylaşım için",
    ),
    "linkEnabled": MessageLookupByLibrary.simpleMessage("Geçerli"),
    "linkExpired": MessageLookupByLibrary.simpleMessage("Süresi dolmuş"),
    "linkExpiresOn": m47,
    "linkExpiry": MessageLookupByLibrary.simpleMessage("Bağlantı geçerliliği"),
    "linkHasExpired": MessageLookupByLibrary.simpleMessage(
      "Bağlantının süresi dolmuş",
    ),
    "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Asla"),
    "linkPerson": MessageLookupByLibrary.simpleMessage("Kişiyi bağla"),
    "linkPersonCaption": MessageLookupByLibrary.simpleMessage(
      "daha iyi paylaşım deneyimi için",
    ),
    "linkPersonToEmail": m48,
    "linkPersonToEmailConfirmation": m49,
    "livePhotos": MessageLookupByLibrary.simpleMessage("Canlı Fotoğraf"),
    "loadMessage1": MessageLookupByLibrary.simpleMessage(
      "Aboneliğinizi ailenizle paylaşabilirsiniz",
    ),
    "loadMessage2": MessageLookupByLibrary.simpleMessage(
      "Şimdiye kadar 200 milyondan fazla anıyı koruduk",
    ),
    "loadMessage3": MessageLookupByLibrary.simpleMessage(
      "Verilerinizin 3 kopyasını saklıyoruz, biri yer altı serpinti sığınağında",
    ),
    "loadMessage4": MessageLookupByLibrary.simpleMessage(
      "Tüm uygulamalarımız açık kaynaktır",
    ),
    "loadMessage5": MessageLookupByLibrary.simpleMessage(
      "Kaynak kodumuz ve şifrelememiz harici olarak denetlenmiştir",
    ),
    "loadMessage6": MessageLookupByLibrary.simpleMessage(
      "Albümlerinizin bağlantılarını sevdiklerinizle paylaşabilirsiniz",
    ),
    "loadMessage7": MessageLookupByLibrary.simpleMessage(
      "Mobil uygulamalarımız, tıkladığınız yeni fotoğrafları şifrelemek ve yedeklemek için arka planda çalışır",
    ),
    "loadMessage8": MessageLookupByLibrary.simpleMessage(
      "web.ente.io\'nun mükemmel bir yükleyicisi var",
    ),
    "loadMessage9": MessageLookupByLibrary.simpleMessage(
      "Verilerinizi güvenli bir şekilde şifrelemek için Xchacha20Poly1305 kullanıyoruz",
    ),
    "loadingExifData": MessageLookupByLibrary.simpleMessage(
      "EXIF verileri yükleniyor...",
    ),
    "loadingGallery": MessageLookupByLibrary.simpleMessage(
      "Galeri yükleniyor...",
    ),
    "loadingMessage": MessageLookupByLibrary.simpleMessage(
      "Fotoğraflarınız yükleniyor...",
    ),
    "loadingModel": MessageLookupByLibrary.simpleMessage(
      "Modeller indiriliyor...",
    ),
    "loadingYourPhotos": MessageLookupByLibrary.simpleMessage(
      "Fotoğraflarınız yükleniyor...",
    ),
    "localGallery": MessageLookupByLibrary.simpleMessage("Yerel galeri"),
    "localIndexing": MessageLookupByLibrary.simpleMessage("Yerel dizinleme"),
    "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
      "Yerel fotoğraf senkronizasyonu beklenenden daha uzun sürdüğü için bir şeyler ters gitmiş gibi görünüyor. Lütfen destek ekibimize ulaşın",
    ),
    "location": MessageLookupByLibrary.simpleMessage("Konum"),
    "locationName": MessageLookupByLibrary.simpleMessage("Konum Adı"),
    "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
      "Bir fotoğrafın belli bir yarıçapında çekilen fotoğrafları gruplandırın",
    ),
    "locations": MessageLookupByLibrary.simpleMessage("Konum"),
    "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Kilit"),
    "lockscreen": MessageLookupByLibrary.simpleMessage("Kilit ekranı"),
    "logInLabel": MessageLookupByLibrary.simpleMessage("Giriş yap"),
    "loggingOut": MessageLookupByLibrary.simpleMessage("Çıkış yapılıyor..."),
    "loginSessionExpired": MessageLookupByLibrary.simpleMessage(
      "Oturum süresi doldu",
    ),
    "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
      "Oturum süreniz doldu. Tekrar giriş yapın.",
    ),
    "loginTerms": MessageLookupByLibrary.simpleMessage(
      "\"Giriş yap\" düğmesine tıklayarak, <u-terms>Hizmet Şartları</u-terms>\'nı ve <u-policy>Gizlilik Politikası</u-policy>\'nı kabul ediyorum",
    ),
    "loginWithTOTP": MessageLookupByLibrary.simpleMessage("TOTP ile giriş yap"),
    "logout": MessageLookupByLibrary.simpleMessage("Çıkış yap"),
    "logsDialogBody": MessageLookupByLibrary.simpleMessage(
      "Bu, sorununuzu gidermemize yardımcı olmak için kayıtları gönderecektir. Belirli dosyalarla ilgili sorunların izlenmesine yardımcı olmak için dosya adlarının ekleneceğini lütfen unutmayın.",
    ),
    "longPressAnEmailToVerifyEndToEndEncryption":
        MessageLookupByLibrary.simpleMessage(
          "Uçtan uca şifrelemeyi doğrulamak için bir e-postaya uzun basın.",
        ),
    "longpressOnAnItemToViewInFullscreen": MessageLookupByLibrary.simpleMessage(
      "Tam ekranda görüntülemek için bir öğeye uzun basın",
    ),
    "lookBackOnYourMemories": MessageLookupByLibrary.simpleMessage(
      "Anılarına bir bak 🌄",
    ),
    "loopVideoOff": MessageLookupByLibrary.simpleMessage(
      "Video Döngüsü Kapalı",
    ),
    "loopVideoOn": MessageLookupByLibrary.simpleMessage("Video Döngüsü Açık"),
    "lostDevice": MessageLookupByLibrary.simpleMessage(
      "Cihazınızı mı kaybettiniz?",
    ),
    "machineLearning": MessageLookupByLibrary.simpleMessage("Makine öğrenimi"),
    "magicSearch": MessageLookupByLibrary.simpleMessage("Sihirli arama"),
    "magicSearchHint": MessageLookupByLibrary.simpleMessage(
      "Sihirli arama, fotoğrafları içeriklerine göre aramanıza olanak tanır, örneğin \'çiçek\', \'kırmızı araba\', \'kimlik belgeleri\'",
    ),
    "manage": MessageLookupByLibrary.simpleMessage("Yönet"),
    "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
      "Cihaz Önbelliğini Yönet",
    ),
    "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
      "Yerel önbellek depolama alanını gözden geçirin ve temizleyin.",
    ),
    "manageFamily": MessageLookupByLibrary.simpleMessage("Aileyi yönet"),
    "manageLink": MessageLookupByLibrary.simpleMessage("Bağlantıyı yönet"),
    "manageParticipants": MessageLookupByLibrary.simpleMessage("Yönet"),
    "manageSubscription": MessageLookupByLibrary.simpleMessage(
      "Abonelikleri yönet",
    ),
    "manualPairDesc": MessageLookupByLibrary.simpleMessage(
      "PIN ile eşleştirme, albümünüzü görüntülemek istediğiniz herhangi bir ekranla çalışır.",
    ),
    "map": MessageLookupByLibrary.simpleMessage("Harita"),
    "maps": MessageLookupByLibrary.simpleMessage("Haritalar"),
    "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
    "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
    "me": MessageLookupByLibrary.simpleMessage("Ben"),
    "memories": MessageLookupByLibrary.simpleMessage("Anılar"),
    "memoriesWidgetDesc": MessageLookupByLibrary.simpleMessage(
      "Ana ekranınızda görmek istediğiniz anı türünü seçin.",
    ),
    "memoryCount": m50,
    "merchandise": MessageLookupByLibrary.simpleMessage("Ürünler"),
    "merge": MessageLookupByLibrary.simpleMessage("Birleştir"),
    "mergeWithExisting": MessageLookupByLibrary.simpleMessage(
      "Var olan ile birleştir.",
    ),
    "mergedPhotos": MessageLookupByLibrary.simpleMessage(
      "Birleştirilmiş fotoğraflar",
    ),
    "mlConsent": MessageLookupByLibrary.simpleMessage(
      "Makine öğrenimini etkinleştir",
    ),
    "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
      "Anladım, ve makine öğrenimini etkinleştirmek istiyorum",
    ),
    "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
      "Makine öğrenimini etkinleştirirseniz, Ente sizinle paylaşılanlar da dahil olmak üzere dosyalardan yüz geometrisi gibi bilgileri çıkarır.\n\nBu, cihazınızda gerçekleşecek ve oluşturulan tüm biyometrik bilgiler uçtan uca şifrelenecektir.",
    ),
    "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
      "Gizlilik politikamızdaki bu özellik hakkında daha fazla ayrıntı için lütfen buraya tıklayın",
    ),
    "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
      "Makine öğrenimi etkinleştirilsin mi?",
    ),
    "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
      "Makine öğreniminin, tüm öğeler dizine eklenene kadar daha yüksek bant genişliği ve pil kullanımıyla sonuçlanacağını lütfen unutmayın. Daha hızlı dizinleme için masaüstü uygulamasını kullanmayı deneyin, tüm sonuçlar otomatik olarak senkronize edilir.",
    ),
    "mobileWebDesktop": MessageLookupByLibrary.simpleMessage(
      "Mobil, Web, Masaüstü",
    ),
    "moderateStrength": MessageLookupByLibrary.simpleMessage("Ilımlı"),
    "modifyYourQueryOrTrySearchingFor": MessageLookupByLibrary.simpleMessage(
      "Sorgunuzu değiştirin veya aramayı deneyin",
    ),
    "moments": MessageLookupByLibrary.simpleMessage("Anlar"),
    "month": MessageLookupByLibrary.simpleMessage("ay"),
    "monthly": MessageLookupByLibrary.simpleMessage("Aylık"),
    "moon": MessageLookupByLibrary.simpleMessage("Ay ışığında"),
    "moreDetails": MessageLookupByLibrary.simpleMessage("Daha fazla detay"),
    "mostRecent": MessageLookupByLibrary.simpleMessage("En son"),
    "mostRelevant": MessageLookupByLibrary.simpleMessage("En alakalı"),
    "mountains": MessageLookupByLibrary.simpleMessage("Tepelerin ötesinde"),
    "moveItem": m51,
    "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
      "Seçilen fotoğrafları bir tarihe taşıma",
    ),
    "moveToAlbum": MessageLookupByLibrary.simpleMessage("Albüme taşı"),
    "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
      "Gizli albüme ekle",
    ),
    "movedSuccessfullyTo": m52,
    "movedToTrash": MessageLookupByLibrary.simpleMessage("Cöp kutusuna taşı"),
    "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
      "Dosyalar albüme taşınıyor...",
    ),
    "name": MessageLookupByLibrary.simpleMessage("İsim"),
    "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Albüm İsmi"),
    "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
      "Ente\'ye bağlanılamıyor. Lütfen bir süre sonra tekrar deneyin. Hata devam ederse lütfen desteğe başvurun.",
    ),
    "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
      "Ente\'ye bağlanılamıyor. Lütfen ağ ayarlarınızı kontrol edin ve hata devam ederse destek ekibiyle iletişime geçin.",
    ),
    "never": MessageLookupByLibrary.simpleMessage("Asla"),
    "newAlbum": MessageLookupByLibrary.simpleMessage("Yeni albüm"),
    "newLocation": MessageLookupByLibrary.simpleMessage("Yeni konum"),
    "newPerson": MessageLookupByLibrary.simpleMessage("Yeni Kişi"),
    "newPhotosEmoji": MessageLookupByLibrary.simpleMessage(" yeni 📸"),
    "newRange": MessageLookupByLibrary.simpleMessage("Yeni aralık"),
    "newToEnte": MessageLookupByLibrary.simpleMessage("Ente\'de yeniyim"),
    "newest": MessageLookupByLibrary.simpleMessage("En yeni"),
    "next": MessageLookupByLibrary.simpleMessage("Sonraki"),
    "no": MessageLookupByLibrary.simpleMessage("Hayır"),
    "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
      "Henüz paylaştığınız albüm yok",
    ),
    "noDeviceFound": MessageLookupByLibrary.simpleMessage("Aygıt bulunamadı"),
    "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Yok"),
    "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
      "Her şey zaten temiz, silinecek dosya kalmadı",
    ),
    "noDuplicates": MessageLookupByLibrary.simpleMessage(
      "Yinelenenleri kaldır",
    ),
    "noEnteAccountExclamation": MessageLookupByLibrary.simpleMessage(
      "Ente hesabı yok!",
    ),
    "noExifData": MessageLookupByLibrary.simpleMessage("EXIF verisi yok"),
    "noFacesFound": MessageLookupByLibrary.simpleMessage("Yüz bulunamadı"),
    "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
      "Gizli fotoğraf veya video yok",
    ),
    "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
      "Konum içeren resim yok",
    ),
    "noInternetConnection": MessageLookupByLibrary.simpleMessage(
      "İnternet bağlantısı yok",
    ),
    "noPhotosAreBeingBackedUpRightNow": MessageLookupByLibrary.simpleMessage(
      "Şu anda hiçbir fotoğraf yedeklenmiyor",
    ),
    "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage(
      "Burada fotoğraf bulunamadı",
    ),
    "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
      "Hızlı bağlantılar seçilmedi",
    ),
    "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Kurtarma anahtarınız yok mu?",
    ),
    "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
      "Uçtan uca şifreleme protokolümüzün doğası gereği, verileriniz şifreniz veya kurtarma anahtarınız olmadan çözülemez",
    ),
    "noResults": MessageLookupByLibrary.simpleMessage("Sonuç bulunamadı"),
    "noResultsFound": MessageLookupByLibrary.simpleMessage(
      "Hiçbir sonuç bulunamadı",
    ),
    "noSuggestionsForPerson": m53,
    "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
      "Sistem kilidi bulunamadı",
    ),
    "notPersonLabel": m54,
    "notThisPerson": MessageLookupByLibrary.simpleMessage("Bu kişi değil mi?"),
    "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
      "Henüz sizinle paylaşılan bir şey yok",
    ),
    "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
      "Burada görülecek bir şey yok! 👀",
    ),
    "notifications": MessageLookupByLibrary.simpleMessage("Bildirimler"),
    "ok": MessageLookupByLibrary.simpleMessage("Tamam"),
    "onDevice": MessageLookupByLibrary.simpleMessage("Cihazda"),
    "onEnte": MessageLookupByLibrary.simpleMessage(
      "<branding>ente</branding> üzerinde",
    ),
    "onTheRoad": MessageLookupByLibrary.simpleMessage("Yeniden yollarda"),
    "onThisDay": MessageLookupByLibrary.simpleMessage("Bu günde"),
    "onThisDayMemories": MessageLookupByLibrary.simpleMessage("Bugün anılar"),
    "onThisDayNotificationExplanation": MessageLookupByLibrary.simpleMessage(
      "Önceki yıllarda bu günden anılar hakkında hatırlatıcılar alın.",
    ),
    "onlyFamilyAdminCanChangeCode": m55,
    "onlyThem": MessageLookupByLibrary.simpleMessage("Sadece onlar"),
    "oops": MessageLookupByLibrary.simpleMessage("Hay aksi"),
    "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
      "Hata! Düzenlemeler kaydedilemedi",
    ),
    "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
      "Hoop, Birşeyler yanlış gitti",
    ),
    "openAlbumInBrowser": MessageLookupByLibrary.simpleMessage(
      "Albümü tarayıcıda aç",
    ),
    "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
      "Bu albüme fotoğraf eklemek için lütfen web uygulamasını kullanın",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Dosyayı aç"),
    "openSettings": MessageLookupByLibrary.simpleMessage("Ayarları Açın"),
    "openTheItem": MessageLookupByLibrary.simpleMessage("• Öğeyi açın"),
    "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
      "OpenStreetMap katkıda bululanlar",
    ),
    "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
      "İsteğe bağlı, istediğiniz kadar kısa...",
    ),
    "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
      "Ya da mevcut olan ile birleştirin",
    ),
    "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
      "Veya mevcut birini seçiniz",
    ),
    "orPickFromYourContacts": MessageLookupByLibrary.simpleMessage(
      "veya kişilerinizden birini seçin",
    ),
    "otherDetectedFaces": MessageLookupByLibrary.simpleMessage(
      "Tespit edilen diğer yüzler",
    ),
    "pair": MessageLookupByLibrary.simpleMessage("Eşleştir"),
    "pairWithPin": MessageLookupByLibrary.simpleMessage("PIN ile eşleştirin"),
    "pairingComplete": MessageLookupByLibrary.simpleMessage(
      "Eşleştirme tamamlandı",
    ),
    "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
    "partyWithThem": m56,
    "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
      "Doğrulama hala bekliyor",
    ),
    "passkey": MessageLookupByLibrary.simpleMessage("Geçiş anahtarı"),
    "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
      "Geçiş anahtarı doğrulaması",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Şifre"),
    "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Şifreniz başarılı bir şekilde değiştirildi",
    ),
    "passwordLock": MessageLookupByLibrary.simpleMessage("Şifre kilidi"),
    "passwordStrength": m57,
    "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
      "Parola gücü, parolanın uzunluğu, kullanılan karakterler ve parolanın en çok kullanılan ilk 10.000 parola arasında yer alıp almadığı dikkate alınarak hesaplanır",
    ),
    "passwordWarning": MessageLookupByLibrary.simpleMessage(
      "Şifrelerinizi saklamıyoruz, bu yüzden unutursanız, <underline>verilerinizi deşifre edemeyiz</underline>",
    ),
    "pastYearsMemories": MessageLookupByLibrary.simpleMessage(
      "Geçmiş yılların anıları",
    ),
    "paymentDetails": MessageLookupByLibrary.simpleMessage("Ödeme detayları"),
    "paymentFailed": MessageLookupByLibrary.simpleMessage(
      "Ödeme başarısız oldu",
    ),
    "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
      "Maalesef ödemeniz başarısız oldu. Lütfen destekle iletişime geçin, size yardımcı olacağız!",
    ),
    "paymentFailedTalkToProvider": m58,
    "pendingItems": MessageLookupByLibrary.simpleMessage("Bekleyen Öğeler"),
    "pendingSync": MessageLookupByLibrary.simpleMessage(
      "Bekleyen Senkronizasyonlar",
    ),
    "people": MessageLookupByLibrary.simpleMessage("Kişiler"),
    "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
      "Kodunuzu kullananlar",
    ),
    "peopleWidgetDesc": MessageLookupByLibrary.simpleMessage(
      "Ana ekranınızda görmek istediğiniz kişileri seçin.",
    ),
    "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
      "Çöp kutusundaki tüm öğeler kalıcı olarak silinecek\n\nBu işlem geri alınamaz",
    ),
    "permanentlyDelete": MessageLookupByLibrary.simpleMessage(
      "Kalıcı olarak sil",
    ),
    "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
      "Cihazdan kalıcı olarak silinsin mi?",
    ),
    "personIsAge": m59,
    "personName": MessageLookupByLibrary.simpleMessage("Kişi Adı"),
    "personTurningAge": m60,
    "pets": MessageLookupByLibrary.simpleMessage("Tüylü dostlar"),
    "photoDescriptions": MessageLookupByLibrary.simpleMessage(
      "Fotoğraf Açıklaması",
    ),
    "photoGridSize": MessageLookupByLibrary.simpleMessage("Izgara boyutu"),
    "photoSmallCase": MessageLookupByLibrary.simpleMessage("fotoğraf"),
    "photocountPhotos": m61,
    "photos": MessageLookupByLibrary.simpleMessage("Fotoğraflar"),
    "photosAddedByYouWillBeRemovedFromTheAlbum":
        MessageLookupByLibrary.simpleMessage(
          "Eklediğiniz fotoğraflar albümden kaldırılacak",
        ),
    "photosCount": m62,
    "photosKeepRelativeTimeDifference": MessageLookupByLibrary.simpleMessage(
      "Fotoğraflar göreli zaman farkını korur",
    ),
    "pickCenterPoint": MessageLookupByLibrary.simpleMessage(
      "Merkez noktasını seçin",
    ),
    "pinAlbum": MessageLookupByLibrary.simpleMessage("Albümü sabitle"),
    "pinLock": MessageLookupByLibrary.simpleMessage("Pin kilidi"),
    "playOnTv": MessageLookupByLibrary.simpleMessage("Albümü TV\'de oynat"),
    "playOriginal": MessageLookupByLibrary.simpleMessage("Orijinali oynat"),
    "playStoreFreeTrialValidTill": m63,
    "playStream": MessageLookupByLibrary.simpleMessage("Akışı oynat"),
    "playstoreSubscription": MessageLookupByLibrary.simpleMessage(
      "PlayStore aboneliği",
    ),
    "pleaseCheckYourInternetConnectionAndTryAgain":
        MessageLookupByLibrary.simpleMessage(
          "Lütfen internet bağlantınızı kontrol edin ve yeniden deneyin.",
        ),
    "pleaseContactSupportAndWeWillBeHappyToHelp":
        MessageLookupByLibrary.simpleMessage(
          "Lütfen support@ente.io ile iletişime geçin; size yardımcı olmaktan memnuniyet duyarız!",
        ),
    "pleaseContactSupportIfTheProblemPersists":
        MessageLookupByLibrary.simpleMessage(
          "Bu hata devam ederse lütfen desteğe başvurun",
        ),
    "pleaseEmailUsAt": m64,
    "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
      "Lütfen izin ver",
    ),
    "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
      "Lütfen tekrar giriş yapın",
    ),
    "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
      "Lütfen kaldırmak için hızlı bağlantıları seçin",
    ),
    "pleaseSendTheLogsTo": m65,
    "pleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Lütfen tekrar deneyiniz",
    ),
    "pleaseVerifyTheCodeYouHaveEntered": MessageLookupByLibrary.simpleMessage(
      "Lütfen girdiğiniz kodu doğrulayın",
    ),
    "pleaseWait": MessageLookupByLibrary.simpleMessage("Lütfen bekleyiniz..."),
    "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
      "Lütfen bekleyin, albüm siliniyor",
    ),
    "pleaseWaitForSometimeBeforeRetrying": MessageLookupByLibrary.simpleMessage(
      "Tekrar denemeden önce lütfen bir süre bekleyin",
    ),
    "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
      "Lütfen bekleyin, bu biraz zaman alabilir.",
    ),
    "posingWithThem": m66,
    "preparingLogs": MessageLookupByLibrary.simpleMessage(
      "Kayıtlar hazırlanıyor...",
    ),
    "preserveMore": MessageLookupByLibrary.simpleMessage(
      "Daha fazlasını koruyun",
    ),
    "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
      "Videoları yönetmek için basılı tutun",
    ),
    "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
      "Videoyu oynatmak için resmi basılı tutun",
    ),
    "previous": MessageLookupByLibrary.simpleMessage("Önceki"),
    "privacy": MessageLookupByLibrary.simpleMessage("Gizlilik"),
    "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
      "Mahremiyet Politikası",
    ),
    "privateBackups": MessageLookupByLibrary.simpleMessage("Özel yedeklemeler"),
    "privateSharing": MessageLookupByLibrary.simpleMessage("Özel paylaşım"),
    "proceed": MessageLookupByLibrary.simpleMessage("Devam edin"),
    "processed": MessageLookupByLibrary.simpleMessage("İşlenen"),
    "processing": MessageLookupByLibrary.simpleMessage("İşleniyor"),
    "processingImport": m67,
    "processingVideos": MessageLookupByLibrary.simpleMessage(
      "Videolar işleniyor",
    ),
    "publicLinkCreated": MessageLookupByLibrary.simpleMessage(
      "Herkese açık bağlantı oluşturuldu",
    ),
    "publicLinkEnabled": MessageLookupByLibrary.simpleMessage(
      "Herkese açık bağlantı aktive edildi",
    ),
    "questionmark": MessageLookupByLibrary.simpleMessage("?"),
    "queued": MessageLookupByLibrary.simpleMessage("Kuyrukta"),
    "quickLinks": MessageLookupByLibrary.simpleMessage("Hızlı Erişim"),
    "radius": MessageLookupByLibrary.simpleMessage("Yarıçap"),
    "raiseTicket": MessageLookupByLibrary.simpleMessage("Bileti artır"),
    "rateTheApp": MessageLookupByLibrary.simpleMessage("Uygulamayı puanlayın"),
    "rateUs": MessageLookupByLibrary.simpleMessage("Bizi değerlendirin"),
    "rateUsOnStore": m68,
    "reassignMe": MessageLookupByLibrary.simpleMessage(
      "\"Ben\"i yeniden atayın",
    ),
    "reassignedToName": m69,
    "reassigningLoading": MessageLookupByLibrary.simpleMessage(
      "Yeniden atanıyor...",
    ),
    "receiveRemindersOnBirthdays": MessageLookupByLibrary.simpleMessage(
      "Birinin doğum günü olduğunda hatırlatıcılar alın. Bildirime dokunmak sizi doğum günü kişisinin fotoğraflarına götürecektir.",
    ),
    "recover": MessageLookupByLibrary.simpleMessage("Kurtarma"),
    "recoverAccount": MessageLookupByLibrary.simpleMessage("Hesabı kurtar"),
    "recoverButton": MessageLookupByLibrary.simpleMessage("Kurtar"),
    "recoveryAccount": MessageLookupByLibrary.simpleMessage("Hesabı kurtar"),
    "recoveryInitiated": MessageLookupByLibrary.simpleMessage(
      "Kurtarma başlatıldı",
    ),
    "recoveryInitiatedDesc": m70,
    "recoveryKey": MessageLookupByLibrary.simpleMessage("Kurtarma anahtarı"),
    "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Kurtarma anahtarınız panoya kopyalandı",
    ),
    "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
      "Şifrenizi unutursanız, verilerinizi kurtarmanın tek yolu bu anahtar olacaktır.",
    ),
    "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
      "Bu anahtarı saklamıyoruz, lütfen bu 24 kelime anahtarı güvenli bir yerde saklayın.",
    ),
    "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
      "Harika! Kurtarma anahtarınız geçerlidir. Doğrulama için teşekkür ederim.\n\nLütfen kurtarma anahtarınızı güvenli bir şekilde yedeklediğinizden emin olun.",
    ),
    "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
      "Kurtarma kodu doğrulandı",
    ),
    "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
      "Kurtarma anahtarınız, şifrenizi unutmanız durumunda fotoğraflarınızı kurtarmanın tek yoludur. Kurtarma anahtarınızı Ayarlar > Hesap bölümünde bulabilirsiniz.\n\nDoğru kaydettiğinizi doğrulamak için lütfen kurtarma anahtarınızı buraya girin.",
    ),
    "recoveryReady": m71,
    "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
      "Kurtarma başarılı!",
    ),
    "recoveryWarning": MessageLookupByLibrary.simpleMessage(
      "Güvenilir bir kişi hesabınıza erişmeye çalışıyor",
    ),
    "recoveryWarningBody": m72,
    "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
      "Cihazınız, şifrenizi doğrulamak için yeterli güce sahip değil, ancak tüm cihazlarda çalışacak şekilde yeniden oluşturabiliriz.\n\nLütfen kurtarma anahtarınızı kullanarak giriş yapın ve şifrenizi yeniden oluşturun (istediğiniz takdirde aynı şifreyi tekrar kullanabilirsiniz).",
    ),
    "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Şifrenizi tekrardan oluşturun",
    ),
    "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
    "reenterPassword": MessageLookupByLibrary.simpleMessage(
      "Şifrenizi tekrar girin",
    ),
    "reenterPin": MessageLookupByLibrary.simpleMessage(
      "PIN\'inizi tekrar girin",
    ),
    "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
      "Arkadaşlarınıza önerin ve planınızı 2 katına çıkarın",
    ),
    "referralStep1": MessageLookupByLibrary.simpleMessage(
      "1. Bu kodu arkadaşlarınıza verin",
    ),
    "referralStep2": MessageLookupByLibrary.simpleMessage(
      "2. Ücretli bir plan için kaydolsunlar",
    ),
    "referralStep3": m73,
    "referrals": MessageLookupByLibrary.simpleMessage("Arkadaşını davet et"),
    "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
      "Davetler şu anda durmuş durumda",
    ),
    "rejectRecovery": MessageLookupByLibrary.simpleMessage("Kurtarmayı reddet"),
    "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
      "Ayrıca boş alanı kazanmak için \"Ayarlar\" > \"Depolama\" bölümünden \"Son Silinenler\" klasörünü de boşaltın",
    ),
    "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
      "Ayrıca boşalan alana sahip olmak için \"Çöp Kutunuzu\" boşaltın",
    ),
    "remoteImages": MessageLookupByLibrary.simpleMessage("Uzak Görseller"),
    "remoteThumbnails": MessageLookupByLibrary.simpleMessage(
      "Uzak Küçük Resimler",
    ),
    "remoteVideos": MessageLookupByLibrary.simpleMessage("Uzak Videolar"),
    "remove": MessageLookupByLibrary.simpleMessage("Kaldır"),
    "removeDuplicates": MessageLookupByLibrary.simpleMessage(
      "Yinelenenleri kaldır",
    ),
    "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
      "Aynı olan dosyaları gözden geçirin ve kaldırın.",
    ),
    "removeFromAlbum": MessageLookupByLibrary.simpleMessage("Albümden çıkar"),
    "removeFromAlbumTitle": MessageLookupByLibrary.simpleMessage(
      "Albümden çıkarılsın mı?",
    ),
    "removeFromFavorite": MessageLookupByLibrary.simpleMessage(
      "Favorilerden Kaldır",
    ),
    "removeInvite": MessageLookupByLibrary.simpleMessage("Davetiyeyi kaldır"),
    "removeLink": MessageLookupByLibrary.simpleMessage("Bağlantıyı kaldır"),
    "removeParticipant": MessageLookupByLibrary.simpleMessage(
      "Katılımcıyı kaldır",
    ),
    "removeParticipantBody": m74,
    "removePersonLabel": MessageLookupByLibrary.simpleMessage(
      "Kişi etiketini kaldırın",
    ),
    "removePublicLink": MessageLookupByLibrary.simpleMessage(
      "Herkese açık bağlantıyı kaldır",
    ),
    "removePublicLinks": MessageLookupByLibrary.simpleMessage(
      "Herkese açık bağlantıları kaldır",
    ),
    "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
      "Kaldırdığınız öğelerden bazıları başkaları tarafından eklenmiştir ve bunlara erişiminizi kaybedeceksiniz",
    ),
    "removeWithQuestionMark": MessageLookupByLibrary.simpleMessage(
      "Kaldırılsın mı?",
    ),
    "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
      "Kendinizi güvenilir kişi olarak kaldırın",
    ),
    "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
      "Favorilerimden kaldır...",
    ),
    "rename": MessageLookupByLibrary.simpleMessage("Yeniden adlandır"),
    "renameAlbum": MessageLookupByLibrary.simpleMessage(
      "Albümü yeniden adlandır",
    ),
    "renameFile": MessageLookupByLibrary.simpleMessage(
      "Dosyayı yeniden adlandır",
    ),
    "renewSubscription": MessageLookupByLibrary.simpleMessage(
      "Abonelik yenileme",
    ),
    "renewsOn": m75,
    "reportABug": MessageLookupByLibrary.simpleMessage("Hata bildir"),
    "reportBug": MessageLookupByLibrary.simpleMessage("Hata bildir"),
    "resendEmail": MessageLookupByLibrary.simpleMessage(
      "E-postayı yeniden gönder",
    ),
    "reset": MessageLookupByLibrary.simpleMessage("Sıfırla"),
    "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
      "Yok sayılan dosyaları sıfırla",
    ),
    "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Parolanızı sıfırlayın",
    ),
    "resetPerson": MessageLookupByLibrary.simpleMessage("Kaldır"),
    "resetToDefault": MessageLookupByLibrary.simpleMessage(
      "Varsayılana sıfırla",
    ),
    "restore": MessageLookupByLibrary.simpleMessage("Geri yükle"),
    "restoreToAlbum": MessageLookupByLibrary.simpleMessage("Albümü yenile"),
    "restoringFiles": MessageLookupByLibrary.simpleMessage(
      "Dosyalar geri yükleniyor...",
    ),
    "resumableUploads": MessageLookupByLibrary.simpleMessage(
      "Devam edilebilir yüklemeler",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Tekrar dene"),
    "review": MessageLookupByLibrary.simpleMessage("Gözden Geçir"),
    "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
      "Lütfen kopya olduğunu düşündüğünüz öğeleri inceleyin ve silin.",
    ),
    "reviewSuggestions": MessageLookupByLibrary.simpleMessage(
      "Önerileri inceleyin",
    ),
    "right": MessageLookupByLibrary.simpleMessage("Sağ"),
    "roadtripWithThem": m76,
    "rotate": MessageLookupByLibrary.simpleMessage("Döndür"),
    "rotateLeft": MessageLookupByLibrary.simpleMessage("Sola döndür"),
    "rotateRight": MessageLookupByLibrary.simpleMessage("Sağa döndür"),
    "safelyStored": MessageLookupByLibrary.simpleMessage("Güvenle saklanır"),
    "same": MessageLookupByLibrary.simpleMessage("Aynı"),
    "sameperson": MessageLookupByLibrary.simpleMessage("Aynı kişi mi?"),
    "save": MessageLookupByLibrary.simpleMessage("Kaydet"),
    "saveAsAnotherPerson": MessageLookupByLibrary.simpleMessage(
      "Başka bir kişi olarak kaydet",
    ),
    "saveChangesBeforeLeavingQuestion": MessageLookupByLibrary.simpleMessage(
      "Çıkmadan önce değişiklikler kaydedilsin mi?",
    ),
    "saveCollage": MessageLookupByLibrary.simpleMessage("Kolajı kaydet"),
    "saveCopy": MessageLookupByLibrary.simpleMessage("Kopyasını kaydet"),
    "saveKey": MessageLookupByLibrary.simpleMessage("Anahtarı kaydet"),
    "savePerson": MessageLookupByLibrary.simpleMessage("Kişiyi kaydet"),
    "saveYourRecoveryKeyIfYouHaventAlready":
        MessageLookupByLibrary.simpleMessage(
          "Henüz yapmadıysanız kurtarma anahtarınızı kaydetmeyi unutmayın",
        ),
    "saving": MessageLookupByLibrary.simpleMessage("Kaydediliyor..."),
    "savingEdits": MessageLookupByLibrary.simpleMessage(
      "Düzenlemeler kaydediliyor...",
    ),
    "scanCode": MessageLookupByLibrary.simpleMessage("Kodu tarayın"),
    "scanThisBarcodeWithnyourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Kimlik doğrulama uygulamanız ile kodu tarayın",
        ),
    "search": MessageLookupByLibrary.simpleMessage("Ara"),
    "searchAlbumsEmptySection": MessageLookupByLibrary.simpleMessage(
      "Albümler",
    ),
    "searchByAlbumNameHint": MessageLookupByLibrary.simpleMessage("Albüm adı"),
    "searchByExamples": MessageLookupByLibrary.simpleMessage(
      "• Albüm adları (ör. \"Kamera\")\n• Dosya türleri (ör. \"Videolar\", \".gif\")\n• Yıllar ve aylar (ör. \"2022\", \"Ocak\")\n• Tatiller (ör. \"Noel\")\n• Fotoğraf açıklamaları (ör. \"#eğlence\")",
    ),
    "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
      "Fotoğraf bilgilerini burada hızlı bir şekilde bulmak için \"#trip\" gibi açıklamalar ekleyin",
    ),
    "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
      "Tarihe, aya veya yıla göre arama yapın",
    ),
    "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
      "İşleme ve senkronizasyon tamamlandığında görüntüler burada gösterilecektir",
    ),
    "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
      "Dizinleme yapıldıktan sonra insanlar burada gösterilecek",
    ),
    "searchFileTypesAndNamesEmptySection": MessageLookupByLibrary.simpleMessage(
      "Dosya türleri ve adları",
    ),
    "searchHint1": MessageLookupByLibrary.simpleMessage(
      "Hızlı, cihaz üzerinde arama",
    ),
    "searchHint2": MessageLookupByLibrary.simpleMessage(
      "Fotoğraf tarihleri, açıklamalar",
    ),
    "searchHint3": MessageLookupByLibrary.simpleMessage(
      "Albümler, dosya adları ve türleri",
    ),
    "searchHint4": MessageLookupByLibrary.simpleMessage("Konum"),
    "searchHint5": MessageLookupByLibrary.simpleMessage(
      "Çok yakında: Yüzler ve sihirli arama ✨",
    ),
    "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
      "Bir fotoğrafın belli bir yarıçapında çekilen fotoğrafları gruplandırın",
    ),
    "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
      "İnsanları davet ettiğinizde onların paylaştığı tüm fotoğrafları burada göreceksiniz",
    ),
    "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
      "İşleme ve senkronizasyon tamamlandığında kişiler burada gösterilecektir",
    ),
    "searchResultCount": m77,
    "searchSectionsLengthMismatch": m78,
    "security": MessageLookupByLibrary.simpleMessage("Güvenlik"),
    "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
      "Uygulamadaki herkese açık albüm bağlantılarını görün",
    ),
    "selectALocation": MessageLookupByLibrary.simpleMessage("Bir konum seçin"),
    "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
      "Önce yeni yer seçin",
    ),
    "selectAlbum": MessageLookupByLibrary.simpleMessage("Albüm seçin"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Hepsini seç"),
    "selectAllShort": MessageLookupByLibrary.simpleMessage("Tümü"),
    "selectCoverPhoto": MessageLookupByLibrary.simpleMessage(
      "Kapak fotoğrafı seçin",
    ),
    "selectDate": MessageLookupByLibrary.simpleMessage("Tarih seç"),
    "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
      "Yedekleme için klasörleri seçin",
    ),
    "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
      "Eklenecek eşyaları seçin",
    ),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Dil Seçin"),
    "selectMailApp": MessageLookupByLibrary.simpleMessage(
      "Mail Uygulamasını Seç",
    ),
    "selectMorePhotos": MessageLookupByLibrary.simpleMessage(
      "Daha Fazla Fotoğraf Seç",
    ),
    "selectOneDateAndTime": MessageLookupByLibrary.simpleMessage(
      "Bir tarih ve saat seçin",
    ),
    "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
      "Tümü için tek bir tarih ve saat seçin",
    ),
    "selectPersonToLink": MessageLookupByLibrary.simpleMessage(
      "Bağlantı kurulacak kişiyi seçin",
    ),
    "selectReason": MessageLookupByLibrary.simpleMessage(
      "Ayrılma nedeninizi seçin",
    ),
    "selectStartOfRange": MessageLookupByLibrary.simpleMessage(
      "Aralık başlangıcını seçin",
    ),
    "selectTime": MessageLookupByLibrary.simpleMessage("Zaman Seç"),
    "selectYourFace": MessageLookupByLibrary.simpleMessage("Yüzünüzü seçin"),
    "selectYourPlan": MessageLookupByLibrary.simpleMessage("Planınızı seçin"),
    "selectedAlbums": m79,
    "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
      "Seçilen dosyalar Ente\'de değil",
    ),
    "selectedFoldersWillBeEncryptedAndBackedUp":
        MessageLookupByLibrary.simpleMessage(
          "Seçilen klasörler şifrelenecek ve yedeklenecektir",
        ),
    "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
        MessageLookupByLibrary.simpleMessage(
          "Seçilen öğeler tüm albümlerden silinecek ve çöp kutusuna taşınacak.",
        ),
    "selectedItemsWillBeRemovedFromThisPerson":
        MessageLookupByLibrary.simpleMessage(
          "Seçili öğeler bu kişiden silinir, ancak kitaplığınızdan silinmez.",
        ),
    "selectedPhotos": m80,
    "selectedPhotosWithYours": m81,
    "selfiesWithThem": m82,
    "send": MessageLookupByLibrary.simpleMessage("Gönder"),
    "sendEmail": MessageLookupByLibrary.simpleMessage("E-posta gönder"),
    "sendInvite": MessageLookupByLibrary.simpleMessage("Davet kodu gönder"),
    "sendLink": MessageLookupByLibrary.simpleMessage("Bağlantıyı gönder"),
    "serverEndpoint": MessageLookupByLibrary.simpleMessage("Sunucu uç noktası"),
    "sessionExpired": MessageLookupByLibrary.simpleMessage(
      "Oturum süresi doldu",
    ),
    "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
      "Oturum kimliği uyuşmazlığı",
    ),
    "setAPassword": MessageLookupByLibrary.simpleMessage("Şifre ayarla"),
    "setAs": MessageLookupByLibrary.simpleMessage("Şu şekilde ayarla"),
    "setCover": MessageLookupByLibrary.simpleMessage("Kapak Belirle"),
    "setLabel": MessageLookupByLibrary.simpleMessage("Ayarla"),
    "setNewPassword": MessageLookupByLibrary.simpleMessage(
      "Yeni şifre belirle",
    ),
    "setNewPin": MessageLookupByLibrary.simpleMessage("Yeni PIN belirleyin"),
    "setPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Parola ayarlayın",
    ),
    "setRadius": MessageLookupByLibrary.simpleMessage("Yarıçapı ayarla"),
    "setupComplete": MessageLookupByLibrary.simpleMessage(
      "Ayarlama işlemi başarılı",
    ),
    "share": MessageLookupByLibrary.simpleMessage("Paylaş"),
    "shareALink": MessageLookupByLibrary.simpleMessage("Bir bağlantı paylaş"),
    "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
      "Bir albüm açın ve paylaşmak için sağ üstteki paylaş düğmesine dokunun.",
    ),
    "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage(
      "Şimdi bir albüm paylaşın",
    ),
    "shareLink": MessageLookupByLibrary.simpleMessage("Bağlantıyı paylaş"),
    "shareMyVerificationID": m83,
    "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
      "Yalnızca istediğiniz kişilerle paylaşın",
    ),
    "shareTextConfirmOthersVerificationID": m84,
    "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
      "Orijinal kalitede fotoğraf ve videoları kolayca paylaşabilmemiz için Ente\'yi indirin\n\nhttps://ente.io",
    ),
    "shareTextReferralCode": m85,
    "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
      "Ente kullanıcısı olmayanlar için paylaş",
    ),
    "shareWithPeopleSectionTitle": m86,
    "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
      "İlk albümünüzü paylaşın",
    ),
    "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
      "Diğer Ente kullanıcılarıyla paylaşılan ve topluluk albümleri oluşturun, bu arada ücretsiz planlara sahip kullanıcıları da içerir.",
    ),
    "sharedByMe": MessageLookupByLibrary.simpleMessage("Benim paylaştıklarım"),
    "sharedByYou": MessageLookupByLibrary.simpleMessage("Paylaştıklarınız"),
    "sharedPhotoNotifications": MessageLookupByLibrary.simpleMessage(
      "Paylaşılan fotoğrafları ekle",
    ),
    "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
      "Birisi parçası olduğunuz paylaşılan bir albüme fotoğraf eklediğinde bildirim alın",
    ),
    "sharedWith": m87,
    "sharedWithMe": MessageLookupByLibrary.simpleMessage("Benimle paylaşılan"),
    "sharedWithYou": MessageLookupByLibrary.simpleMessage("Sizinle paylaşıldı"),
    "sharing": MessageLookupByLibrary.simpleMessage("Paylaşılıyor..."),
    "shiftDatesAndTime": MessageLookupByLibrary.simpleMessage(
      "Vardiya tarihleri ve saati",
    ),
    "showLessFaces": MessageLookupByLibrary.simpleMessage("Daha az yüz göster"),
    "showMemories": MessageLookupByLibrary.simpleMessage("Anıları göster"),
    "showMoreFaces": MessageLookupByLibrary.simpleMessage(
      "Daha fazla yüz göster",
    ),
    "showPerson": MessageLookupByLibrary.simpleMessage("Kişiyi Göster"),
    "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
      "Diğer cihazlardan çıkış yap",
    ),
    "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
      "Eğer başka birisinin parolanızı bildiğini düşünüyorsanız, diğer tüm cihazları hesabınızdan çıkışa zorlayabilirsiniz.",
    ),
    "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
      "Diğer cihazlardan çıkış yap",
    ),
    "signUpTerms": MessageLookupByLibrary.simpleMessage(
      "<u-terms>Hizmet Şartları</u-terms>\'nı ve <u-policy>Gizlilik Politikası</u-policy>\'nı kabul ediyorum",
    ),
    "singleFileDeleteFromDevice": m88,
    "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
      "Tüm albümlerden silinecek.",
    ),
    "singleFileInBothLocalAndRemote": m89,
    "singleFileInRemoteOnly": m90,
    "skip": MessageLookupByLibrary.simpleMessage("Geç"),
    "smartMemories": MessageLookupByLibrary.simpleMessage("Akıllı anılar"),
    "social": MessageLookupByLibrary.simpleMessage("Sosyal Medya"),
    "someItemsAreInBothEnteAndYourDevice": MessageLookupByLibrary.simpleMessage(
      "Bazı öğeler hem Ente\'de hem de cihazınızda bulunur.",
    ),
    "someOfTheFilesYouAreTryingToDeleteAre": MessageLookupByLibrary.simpleMessage(
      "Silmeye çalıştığınız dosyalardan bazıları yalnızca cihazınızda mevcuttur ve silindiği takdirde kurtarılamaz",
    ),
    "someoneSharingAlbumsWithYouShouldSeeTheSameId":
        MessageLookupByLibrary.simpleMessage(
          "Size albümleri paylaşan biri, kendi cihazında aynı kimliği görmelidir.",
        ),
    "somethingWentWrong": MessageLookupByLibrary.simpleMessage(
      "Bazı şeyler yanlış gitti",
    ),
    "somethingWentWrongPleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Bir şeyler ters gitti, lütfen tekrar deneyin",
    ),
    "sorry": MessageLookupByLibrary.simpleMessage("Üzgünüz"),
    "sorryBackupFailedDesc": MessageLookupByLibrary.simpleMessage(
      "Üzgünüz, bu dosya şu anda yedeklenemedi. Daha sonra tekrar deneyeceğiz.",
    ),
    "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
      "Üzgünüm, favorilere ekleyemedim!",
    ),
    "sorryCouldNotRemoveFromFavorites": MessageLookupByLibrary.simpleMessage(
      "Üzgünüm, favorilere ekleyemedim!",
    ),
    "sorryTheCodeYouveEnteredIsIncorrect": MessageLookupByLibrary.simpleMessage(
      "Üzgünüz, girdiğiniz kod yanlış",
    ),
    "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
        MessageLookupByLibrary.simpleMessage(
          "Üzgünüm, bu cihazda güvenli anahtarlarını oluşturamadık.\n\nLütfen başka bir cihazdan giriş yapmayı deneyiniz.",
        ),
    "sorryWeHadToPauseYourBackups": MessageLookupByLibrary.simpleMessage(
      "Üzgünüm, yedeklemenizi duraklatmak zorunda kaldık",
    ),
    "sort": MessageLookupByLibrary.simpleMessage("Sırala"),
    "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sırala"),
    "sortNewestFirst": MessageLookupByLibrary.simpleMessage("Yeniden eskiye"),
    "sortOldestFirst": MessageLookupByLibrary.simpleMessage("Önce en eski"),
    "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Başarılı"),
    "sportsWithThem": m91,
    "spotlightOnThem": m92,
    "spotlightOnYourself": MessageLookupByLibrary.simpleMessage("Sahne senin"),
    "startAccountRecoveryTitle": MessageLookupByLibrary.simpleMessage(
      "Kurtarmayı başlat",
    ),
    "startBackup": MessageLookupByLibrary.simpleMessage("Yedeklemeyi başlat"),
    "status": MessageLookupByLibrary.simpleMessage("Durum"),
    "stopCastingBody": MessageLookupByLibrary.simpleMessage(
      "Yansıtmayı durdurmak istiyor musunuz?",
    ),
    "stopCastingTitle": MessageLookupByLibrary.simpleMessage("Yayını durdur"),
    "storage": MessageLookupByLibrary.simpleMessage("Depolama"),
    "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Aile"),
    "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Sen"),
    "storageInGB": m93,
    "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
      "Depolama sınırı aşıldı",
    ),
    "storageUsageInfo": m94,
    "streamDetails": MessageLookupByLibrary.simpleMessage("Akış detayları"),
    "strongStrength": MessageLookupByLibrary.simpleMessage("Güçlü"),
    "subAlreadyLinkedErrMessage": m95,
    "subWillBeCancelledOn": m96,
    "subscribe": MessageLookupByLibrary.simpleMessage("Abone ol"),
    "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
      "Paylaşımı etkinleştirmek için aktif bir ücretli aboneliğe ihtiyacınız var.",
    ),
    "subscription": MessageLookupByLibrary.simpleMessage("Abonelik"),
    "success": MessageLookupByLibrary.simpleMessage("Başarılı"),
    "successfullyArchived": MessageLookupByLibrary.simpleMessage(
      "Başarıyla arşivlendi",
    ),
    "successfullyHid": MessageLookupByLibrary.simpleMessage(
      "Başarıyla saklandı",
    ),
    "successfullyUnarchived": MessageLookupByLibrary.simpleMessage(
      "Başarıyla arşivden çıkarıldı",
    ),
    "successfullyUnhid": MessageLookupByLibrary.simpleMessage(
      "Başarıyla arşivden çıkarıldı",
    ),
    "suggestFeatures": MessageLookupByLibrary.simpleMessage("Özellik önerin"),
    "sunrise": MessageLookupByLibrary.simpleMessage("Ufukta"),
    "support": MessageLookupByLibrary.simpleMessage("Destek"),
    "syncProgress": m97,
    "syncStopped": MessageLookupByLibrary.simpleMessage(
      "Senkronizasyon durduruldu",
    ),
    "syncing": MessageLookupByLibrary.simpleMessage("Eşitleniyor..."),
    "systemTheme": MessageLookupByLibrary.simpleMessage("Sistem"),
    "tapToCopy": MessageLookupByLibrary.simpleMessage(
      "kopyalamak için dokunun",
    ),
    "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
      "Kodu girmek icin tıklayın",
    ),
    "tapToUnlock": MessageLookupByLibrary.simpleMessage("Açmak için dokun"),
    "tapToUpload": MessageLookupByLibrary.simpleMessage(
      "Yüklemek için tıklayın",
    ),
    "tapToUploadIsIgnoredDue": m98,
    "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
      "Bir şeyler ters gitmiş gibi görünüyor. Lütfen bir süre sonra tekrar deneyin. Hata devam ederse, lütfen destek ekibimizle iletişime geçin.",
    ),
    "terminate": MessageLookupByLibrary.simpleMessage("Sonlandır"),
    "terminateSession": MessageLookupByLibrary.simpleMessage(
      "Oturum sonlandırılsın mı?",
    ),
    "terms": MessageLookupByLibrary.simpleMessage("Şartlar"),
    "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Şartlar"),
    "thankYou": MessageLookupByLibrary.simpleMessage("Teşekkürler"),
    "thankYouForSubscribing": MessageLookupByLibrary.simpleMessage(
      "Abone olduğunuz için teşekkürler!",
    ),
    "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
      "İndirme işlemi tamamlanamadı",
    ),
    "theLinkYouAreTryingToAccessHasExpired":
        MessageLookupByLibrary.simpleMessage(
          "Erişmeye çalıştığınız bağlantının süresi dolmuştur.",
        ),
    "thePersonGroupsWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
      "Kişi grupları artık kişiler bölümünde görüntülenmeyecek. Fotoğraflar dokunulmadan kalacaktır.",
    ),
    "thePersonWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
      "Kişi artık kişiler bölümünde görüntülenmeyecek. Fotoğraflar dokunulmadan kalacaktır.",
    ),
    "theRecoveryKeyYouEnteredIsIncorrect": MessageLookupByLibrary.simpleMessage(
      "Girdiğiniz kurtarma kodu yanlış",
    ),
    "theme": MessageLookupByLibrary.simpleMessage("Tema"),
    "theseItemsWillBeDeletedFromYourDevice":
        MessageLookupByLibrary.simpleMessage(
          "Bu öğeler cihazınızdan silinecektir.",
        ),
    "theyAlsoGetXGb": m99,
    "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
      "Tüm albümlerden silinecek.",
    ),
    "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
      "Bu eylem geri alınamaz",
    ),
    "thisAlbumAlreadyHDACollaborativeLink":
        MessageLookupByLibrary.simpleMessage(
          "Bu albümde zaten bir ortak çalışma bağlantısı var",
        ),
    "thisCanBeUsedToRecoverYourAccountIfYou": MessageLookupByLibrary.simpleMessage(
      "Bu, iki faktörünüzü kaybederseniz hesabınızı kurtarmak için kullanılabilir",
    ),
    "thisDevice": MessageLookupByLibrary.simpleMessage("Bu cihaz"),
    "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
      "Bu e-posta zaten kullanılıyor",
    ),
    "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
      "Bu görselde exif verisi yok",
    ),
    "thisIsMeExclamation": MessageLookupByLibrary.simpleMessage("Bu benim!"),
    "thisIsPersonVerificationId": m100,
    "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
      "Doğrulama kimliğiniz",
    ),
    "thisWeekThroughTheYears": MessageLookupByLibrary.simpleMessage(
      "Yıllar boyunca bu hafta",
    ),
    "thisWeekXYearsAgo": m101,
    "thisWillLogYouOutOfTheFollowingDevice":
        MessageLookupByLibrary.simpleMessage(
          "Bu, sizi aşağıdaki cihazdan çıkış yapacak:",
        ),
    "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
      "Bu cihazdaki oturumunuz kapatılacak!",
    ),
    "thisWillMakeTheDateAndTimeOfAllSelected":
        MessageLookupByLibrary.simpleMessage(
          "Bu, seçilen tüm fotoğrafların tarih ve saatini aynı yapacaktır.",
        ),
    "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
        MessageLookupByLibrary.simpleMessage(
          "Bu, seçilen tüm hızlı bağlantıların genel bağlantılarını kaldıracaktır.",
        ),
    "throughTheYears": m102,
    "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
        MessageLookupByLibrary.simpleMessage(
          "Uygulama kilidini etkinleştirmek için lütfen sistem ayarlarınızda cihaz şifresi veya ekran kilidi ayarlayın.",
        ),
    "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
      "Bir fotoğrafı veya videoyu gizlemek için",
    ),
    "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
      "Şifrenizi sıfılamak için lütfen e-postanızı girin.",
    ),
    "todaysLogs": MessageLookupByLibrary.simpleMessage("Bugünün kayıtları"),
    "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
      "Çok fazla hatalı deneme",
    ),
    "total": MessageLookupByLibrary.simpleMessage("total"),
    "totalSize": MessageLookupByLibrary.simpleMessage("Toplam boyut"),
    "trash": MessageLookupByLibrary.simpleMessage("Cöp kutusu"),
    "trashDaysLeft": m103,
    "trim": MessageLookupByLibrary.simpleMessage("Kes"),
    "tripInYear": m104,
    "tripToLocation": m105,
    "trustedContacts": MessageLookupByLibrary.simpleMessage(
      "Güvenilir kişiler",
    ),
    "trustedInviteBody": m106,
    "tryAgain": MessageLookupByLibrary.simpleMessage("Tekrar deneyiniz"),
    "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
      "Bu cihaz klasörüne eklenen dosyaları otomatik olarak ente\'ye yüklemek için yedeklemeyi açın.",
    ),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
      "Yıllık planlarda 2 ay ücretsiz",
    ),
    "twofactor": MessageLookupByLibrary.simpleMessage("İki faktörlü doğrulama"),
    "twofactorAuthenticationHasBeenDisabled":
        MessageLookupByLibrary.simpleMessage(
          "İki faktörlü kimlik doğrulama devre dışı",
        ),
    "twofactorAuthenticationPageTitle": MessageLookupByLibrary.simpleMessage(
      "İki faktörlü doğrulama",
    ),
    "twofactorAuthenticationSuccessfullyReset":
        MessageLookupByLibrary.simpleMessage(
          "İki faktörlü kimlik doğrulama başarıyla sıfırlandı",
        ),
    "twofactorSetup": MessageLookupByLibrary.simpleMessage(
      "İki faktörlü kurulum",
    ),
    "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
    "unarchive": MessageLookupByLibrary.simpleMessage("Arşivden cıkar"),
    "unarchiveAlbum": MessageLookupByLibrary.simpleMessage("Arşivden Çıkar"),
    "unarchiving": MessageLookupByLibrary.simpleMessage(
      "Arşivden çıkarılıyor...",
    ),
    "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
      "Üzgünüz, bu kod mevcut değil.",
    ),
    "uncategorized": MessageLookupByLibrary.simpleMessage("Kategorisiz"),
    "unhide": MessageLookupByLibrary.simpleMessage("Gizleme"),
    "unhideToAlbum": MessageLookupByLibrary.simpleMessage("Albümü gizleme"),
    "unhiding": MessageLookupByLibrary.simpleMessage("Gösteriliyor..."),
    "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
      "Albümdeki dosyalar gösteriliyor",
    ),
    "unlock": MessageLookupByLibrary.simpleMessage("Kilidi aç"),
    "unpinAlbum": MessageLookupByLibrary.simpleMessage(
      "Albümün sabitlemesini kaldır",
    ),
    "unselectAll": MessageLookupByLibrary.simpleMessage(
      "Tümünün seçimini kaldır",
    ),
    "update": MessageLookupByLibrary.simpleMessage("Güncelle"),
    "updateAvailable": MessageLookupByLibrary.simpleMessage(
      "Güncelleme mevcut",
    ),
    "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
      "Klasör seçimi güncelleniyor...",
    ),
    "upgrade": MessageLookupByLibrary.simpleMessage("Yükselt"),
    "uploadIsIgnoredDueToIgnorereason": m108,
    "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
      "Dosyalar albüme taşınıyor...",
    ),
    "uploadingMultipleMemories": m109,
    "uploadingSingleMemory": MessageLookupByLibrary.simpleMessage(
      "1 anı korunuyor...",
    ),
    "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
      "4 Aralık\'a kadar %50\'ye varan indirim.",
    ),
    "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
      "Kullanılabilir depolama alanı mevcut planınızla sınırlıdır. Talep edilen fazla depolama alanı, planınızı yükselttiğinizde otomatik olarak kullanılabilir hale gelecektir.",
    ),
    "useAsCover": MessageLookupByLibrary.simpleMessage("Kapak olarak kullanın"),
    "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
      "Bu videoyu oynatmakta sorun mu yaşıyorsunuz? Farklı bir oynatıcı denemek için buraya uzun basın.",
    ),
    "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
      "Ente\'de olmayan kişiler için genel bağlantıları kullanın",
    ),
    "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Kurtarma anahtarını kullan",
    ),
    "useSelectedPhoto": MessageLookupByLibrary.simpleMessage(
      "Seçilen fotoğrafı kullan",
    ),
    "usedSpace": MessageLookupByLibrary.simpleMessage("Kullanılan alan"),
    "validTill": m110,
    "verificationFailedPleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Doğrulama başarısız oldu, lütfen tekrar deneyin",
    ),
    "verificationId": MessageLookupByLibrary.simpleMessage("Doğrulama kimliği"),
    "verify": MessageLookupByLibrary.simpleMessage("Doğrula"),
    "verifyEmail": MessageLookupByLibrary.simpleMessage(
      "E-posta adresini doğrulayın",
    ),
    "verifyEmailID": m111,
    "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Doğrula"),
    "verifyPasskey": MessageLookupByLibrary.simpleMessage(
      "Şifrenizi doğrulayın",
    ),
    "verifyPassword": MessageLookupByLibrary.simpleMessage(
      "Şifrenizi doğrulayın",
    ),
    "verifying": MessageLookupByLibrary.simpleMessage("Doğrulanıyor..."),
    "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Kurtarma kodu doğrulanıyor...",
    ),
    "videoInfo": MessageLookupByLibrary.simpleMessage("Video Bilgileri"),
    "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
    "videoStreaming": MessageLookupByLibrary.simpleMessage(
      "Akışlandırılabilir videolar",
    ),
    "videos": MessageLookupByLibrary.simpleMessage("Videolar"),
    "viewActiveSessions": MessageLookupByLibrary.simpleMessage(
      "Aktif oturumları görüntüle",
    ),
    "viewAddOnButton": MessageLookupByLibrary.simpleMessage(
      "Eklentileri görüntüle",
    ),
    "viewAll": MessageLookupByLibrary.simpleMessage("Tümünü görüntüle"),
    "viewAllExifData": MessageLookupByLibrary.simpleMessage(
      "Tüm EXIF verilerini görüntüle",
    ),
    "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Büyük dosyalar"),
    "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
      "En fazla depolama alanı kullanan dosyaları görüntüleyin.",
    ),
    "viewLogs": MessageLookupByLibrary.simpleMessage("Kayıtları görüntüle"),
    "viewPersonToUnlink": m112,
    "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Kurtarma anahtarını görüntüle",
    ),
    "viewer": MessageLookupByLibrary.simpleMessage("Görüntüleyici"),
    "viewersSuccessfullyAdded": m113,
    "visitWebToManage": MessageLookupByLibrary.simpleMessage(
      "Aboneliğinizi yönetmek için lütfen web.ente.io adresini ziyaret edin",
    ),
    "waitingForVerification": MessageLookupByLibrary.simpleMessage(
      "Doğrulama bekleniyor...",
    ),
    "waitingForWifi": MessageLookupByLibrary.simpleMessage(
      "WiFi bekleniyor...",
    ),
    "warning": MessageLookupByLibrary.simpleMessage("Uyarı"),
    "weAreOpenSource": MessageLookupByLibrary.simpleMessage(
      "Biz açık kaynağız!",
    ),
    "weDontSupportEditingPhotosAndAlbumsThatYouDont":
        MessageLookupByLibrary.simpleMessage(
          "Henüz sahibi olmadığınız fotoğraf ve albümlerin düzenlenmesini desteklemiyoruz",
        ),
    "weHaveSendEmailTo": m114,
    "weakStrength": MessageLookupByLibrary.simpleMessage("Zayıf"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("Tekrardan hoşgeldin!"),
    "whatsNew": MessageLookupByLibrary.simpleMessage("Yenilikler"),
    "whyAddTrustContact": MessageLookupByLibrary.simpleMessage("."),
    "widgets": MessageLookupByLibrary.simpleMessage("Widget\'lar"),
    "wishThemAHappyBirthday": m115,
    "yearShort": MessageLookupByLibrary.simpleMessage("yıl"),
    "yearly": MessageLookupByLibrary.simpleMessage("Yıllık"),
    "yearsAgo": m116,
    "yes": MessageLookupByLibrary.simpleMessage("Evet"),
    "yesCancel": MessageLookupByLibrary.simpleMessage("Evet, iptal et"),
    "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
      "Evet, görüntüleyici olarak dönüştür",
    ),
    "yesDelete": MessageLookupByLibrary.simpleMessage("Evet, sil"),
    "yesDiscardChanges": MessageLookupByLibrary.simpleMessage(
      "Evet, değişiklikleri sil",
    ),
    "yesIgnore": MessageLookupByLibrary.simpleMessage("Evet, görmezden gel"),
    "yesLogout": MessageLookupByLibrary.simpleMessage("Evet, oturumu kapat"),
    "yesRemove": MessageLookupByLibrary.simpleMessage("Evet, sil"),
    "yesRenew": MessageLookupByLibrary.simpleMessage("Evet, yenile"),
    "yesResetPerson": MessageLookupByLibrary.simpleMessage(
      "Evet, kişiyi sıfırla",
    ),
    "you": MessageLookupByLibrary.simpleMessage("Sen"),
    "youAndThem": m117,
    "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
      "Aile planı kullanıyorsunuz!",
    ),
    "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
      "En son sürüme sahipsiniz",
    ),
    "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
      "* Alanınızı en fazla ikiye katlayabilirsiniz",
    ),
    "youCanManageYourLinksInTheShareTab": MessageLookupByLibrary.simpleMessage(
      "Bağlantılarınızı paylaşım sekmesinden yönetebilirsiniz.",
    ),
    "youCanTrySearchingForADifferentQuery":
        MessageLookupByLibrary.simpleMessage(
          "Farklı bir sorgu aramayı deneyebilirsiniz.",
        ),
    "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
      "Bu plana geçemezsiniz",
    ),
    "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
      "Kendinizle paylaşamazsınız",
    ),
    "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
      "Arşivlenmiş öğeniz yok.",
    ),
    "youHaveSuccessfullyFreedUp": m118,
    "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
      "Hesabınız silindi",
    ),
    "yourMap": MessageLookupByLibrary.simpleMessage("Haritalarınız"),
    "yourPlanWasSuccessfullyDowngraded": MessageLookupByLibrary.simpleMessage(
      "Planınız başarıyla düşürüldü",
    ),
    "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
      "Planınız başarıyla yükseltildi",
    ),
    "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
      "Satın alım başarılı",
    ),
    "yourStorageDetailsCouldNotBeFetched": MessageLookupByLibrary.simpleMessage(
      "Depolama bilgisi alınamadı",
    ),
    "yourSubscriptionHasExpired": MessageLookupByLibrary.simpleMessage(
      "Aboneliğinizin süresi doldu",
    ),
    "yourSubscriptionWasUpdatedSuccessfully":
        MessageLookupByLibrary.simpleMessage(
          "Aboneliğiniz başarıyla güncellendi",
        ),
    "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
      "Doğrulama kodunuzun süresi doldu",
    ),
    "youveNoDuplicateFilesThatCanBeCleared":
        MessageLookupByLibrary.simpleMessage(
          "Temizlenebilecek yinelenen dosyalarınız yok",
        ),
    "youveNoFilesInThisAlbumThatCanBeDeleted":
        MessageLookupByLibrary.simpleMessage(
          "Her şey zaten temiz, silinecek dosya kalmadı",
        ),
    "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
      "Fotoğrafları görmek için uzaklaştırın",
    ),
  };
}
