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

  static String m9(count) =>
      "${Intl.plural(count, zero: 'Ortak çalışan ekle', one: 'Ortak çalışan ekle', other: 'Ortak çalışan ekle')}";

  static String m10(count) =>
      "${Intl.plural(count, one: 'Öğeyi taşı', other: 'Öğeleri taşı')}";

  static String m11(storageAmount, endDate) =>
      "${storageAmount} eklentiniz ${endDate} tarihine kadar geçerlidir";

  static String m12(count) =>
      "${Intl.plural(count, zero: 'Görüntüleyen ekle', one: 'Görüntüleyen ekle', other: 'Görüntüleyen ekle')}";

  static String m13(emailOrName) => "${emailOrName} tarafından eklendi";

  static String m14(albumName) => "${albumName} albümüne başarıyla eklendi";

  static String m15(count) =>
      "${Intl.plural(count, zero: 'Katılımcı Yok', one: '1 Katılımcı', other: '${count} Katılımcı')}";

  static String m16(versionValue) => "Sürüm: ${versionValue}";

  static String m18(paymentProvider) =>
      "Lütfen önce mevcut aboneliğinizi ${paymentProvider} adresinden iptal edin";

  static String m3(user) =>
      "${user}, bu albüme daha fazla fotoğraf ekleyemeyecek.\n\nAncak, kendi eklediği mevcut fotoğrafları kaldırmaya devam edebilecektir";

  static String m19(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Şu ana kadar aileniz ${storageAmountInGb} GB aldı',
            'false': 'Şu ana kadar ${storageAmountInGb} GB aldınız',
            'other': 'Şu ana kadar ${storageAmountInGb} GB aldınız!',
          })}";

  static String m20(albumName) =>
      "${albumName} için ortak çalışma bağlantısı oluşturuldu";

  static String m23(familyAdminEmail) =>
      "Aboneliğinizi yönetmek için lütfen <green>${familyAdminEmail}</green> ile iletişime geçin";

  static String m24(provider) =>
      "Lütfen ${provider} aboneliğinizi yönetmek için support@ente.io adresinden bizimle iletişime geçin.";

  static String m25(endpoint) => "${endpoint}\'e bağlanıldı";

  static String m26(count) =>
      "${Intl.plural(count, one: 'Delete ${count} item', other: 'Delete ${count} items')}";

  static String m27(currentlyDeleting, totalCount) =>
      "Siliniyor ${currentlyDeleting} / ${totalCount}";

  static String m28(albumName) =>
      "Bu, \"${albumName}\"e erişim için olan genel bağlantıyı kaldıracaktır.";

  static String m29(supportEmail) =>
      "Lütfen kayıtlı e-posta adresinizden ${supportEmail} adresine bir e-posta gönderin";

  static String m30(count, storageSaved) =>
      "You have cleaned up ${Intl.plural(count, one: '${count} duplicate file', other: '${count} duplicate files')}, saving (${storageSaved}!)";

  static String m31(count, formattedSize) =>
      "${count} dosyalar, ${formattedSize} her biri";

  static String m32(newEmail) => "E-posta ${newEmail} olarak değiştirildi";

  static String m33(email) =>
      "${email}, Ente hesabı bulunmamaktadır.\n\nOnlarla fotoğraf paylaşımı için bir davet gönder.";

  static String m35(count, formattedNumber) =>
      "Bu cihazdaki ${Intl.plural(count, one: '1 file', other: '${formattedNumber} dosya')} güvenli bir şekilde yedeklendi";

  static String m36(count, formattedNumber) =>
      "Bu albümdeki ${Intl.plural(count, one: '1 file', other: '${formattedNumber} dosya')} güvenli bir şekilde yedeklendi";

  static String m4(storageAmountInGB) =>
      "Birisinin davet kodunuzu uygulayıp ücretli hesap açtığı her seferede ${storageAmountInGB} GB";

  static String m37(endDate) => "Ücretsiz deneme ${endDate} sona erir";

  static String m39(sizeInMBorGB) => "${sizeInMBorGB} yer açın";

  static String m40(count, formattedSize) =>
      "${Intl.plural(count, one: 'Yer açmak için cihazdan silinebilir ${formattedSize}', other: 'Yer açmak için cihazdan silinebilir ${formattedSize}')}";

  static String m41(currentlyProcessing, totalCount) =>
      "Siliniyor ${currentlyProcessing} / ${totalCount}";

  static String m42(count) =>
      "${Intl.plural(count, one: '${count} öğe', other: '${count} öğeler')}";

  static String m44(expiryTime) =>
      "Bu bağlantı ${expiryTime} dan sonra geçersiz olacaktır";

  static String m5(count, formattedCount) =>
      "${Intl.plural(count, zero: 'anı yok', one: '${formattedCount} anı', other: '${formattedCount} anılar')}";

  static String m45(count) =>
      "${Intl.plural(count, one: 'Öğeyi taşı', other: 'Öğeleri taşı')}";

  static String m46(albumName) => "${albumName} adlı albüme başarıyla taşındı";

  static String m0(passwordStrengthValue) =>
      "Şifrenin güçlülük seviyesi: ${passwordStrengthValue}";

  static String m50(providerName) =>
      "Sizden ücret alındıysa lütfen ${providerName} destek ekibiyle görüşün";

  static String m53(toEmail) => "Lütfen bize ${toEmail} adresinden ulaşın";

  static String m54(toEmail) =>
      "Lütfen günlükleri şu adrese gönderin\n${toEmail}";

  static String m56(storeName) => "Bizi ${storeName} üzerinden değerlendirin";

  static String m60(storageInGB) => "3. Hepimiz ${storageInGB} GB* bedava alın";

  static String m61(userEmail) =>
      "${userEmail} bu paylaşılan albümden kaldırılacaktır\n\nOnlar tarafından eklenen tüm fotoğraflar da albümden kaldırılacaktır";

  static String m62(endDate) => "Abonelik ${endDate} tarihinde yenilenir";

  static String m63(count) =>
      "${Intl.plural(count, one: '${count} yıl önce', other: '${count} yıl önce')}";

  static String m6(count) => "${count} seçildi";

  static String m65(count, yourCount) =>
      "Seçilenler: ${count} (${yourCount} sizin seçiminiz)";

  static String m66(verificationID) =>
      "İşte ente.io için doğrulama kimliğim: ${verificationID}.";

  static String m7(verificationID) =>
      "Merhaba, bu ente.io doğrulama kimliğinizin doğruluğunu onaylayabilir misiniz: ${verificationID}";

  static String m68(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Belirli kişilerle paylaş', one: '1 kişiyle paylaşıldı', other: '${numberOfPeople} kişiyle paylaşıldı')}";

  static String m69(emailIDs) => "${emailIDs} ile paylaşıldı";

  static String m70(fileType) => "Bu ${fileType}, cihazınızdan silinecek.";

  static String m1(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m73(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} / ${totalAmount} ${totalStorageUnit} kullanıldı";

  static String m75(endDate) =>
      "Aboneliğiniz ${endDate} tarihinde iptal edilecektir";

  static String m76(completed, total) => "${completed}/${total} anı korundu";

  static String m8(storageAmountInGB) =>
      "Aynı zamanda ${storageAmountInGB} GB alıyorlar";

  static String m78(email) => "Bu, ${email}\'in Doğrulama Kimliği";

  static String m84(endDate) => "${endDate} tarihine kadar geçerli";

  static String m85(email) => "${email} doğrula";

  static String m2(email) =>
      "E-postayı <green>${email}</green> adresine gönderdik";

  static String m87(count) =>
      "${Intl.plural(count, one: '${count} yıl önce', other: '${count} yıl önce')}";

  static String m88(storageSaved) =>
      "Başarılı bir şekilde ${storageSaved} alanını boşalttınız!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("Hakkında"),
        "account": MessageLookupByLibrary.simpleMessage("Hesap"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Tekrar hoş geldiniz!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Şifremi kaybedersem, verilerim <underline>uçtan uca şifrelendiği</underline> için verilerimi kaybedebileceğimi farkındayım."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktif oturumlar"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Yeni e-posta ekle"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Düzenleyici ekle"),
        "addCollaborators": m9,
        "addFromDevice": MessageLookupByLibrary.simpleMessage("Cihazdan ekle"),
        "addItem": m10,
        "addLocation": MessageLookupByLibrary.simpleMessage("Konum Ekle"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Ekle"),
        "addMore": MessageLookupByLibrary.simpleMessage("Daha fazla ekle"),
        "addNew": MessageLookupByLibrary.simpleMessage("Yeni ekle"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Eklentilerin ayrıntıları"),
        "addOnValidTill": m11,
        "addOns": MessageLookupByLibrary.simpleMessage("Eklentiler"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Fotoğraf ekle"),
        "addSelected": MessageLookupByLibrary.simpleMessage("Seçileni ekle"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Albüme ekle"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Gizli albüme ekle"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Görüntüleyici ekle"),
        "addViewers": m12,
        "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
            "Fotoğraflarınızı şimdi ekleyin"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Eklendi"),
        "addedBy": m13,
        "addedSuccessfullyTo": m14,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Favorilere ekleniyor..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Gelişmiş"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Gelişmiş"),
        "after1Day": MessageLookupByLibrary.simpleMessage("1 gün sonra"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("1 saat sonra"),
        "after1Month": MessageLookupByLibrary.simpleMessage("1 ay sonra"),
        "after1Week": MessageLookupByLibrary.simpleMessage("1 hafta sonra"),
        "after1Year": MessageLookupByLibrary.simpleMessage("1 yıl sonra"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Sahip"),
        "albumParticipantsCount": m15,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Albüm Başlığı"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Albüm güncellendi"),
        "albums": MessageLookupByLibrary.simpleMessage("Albümler"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Tamamen temizle"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("Tüm anılar saklandı"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Bağlantıya sahip olan kişilere, paylaşılan albüme fotoğraf eklemelerine izin ver."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Fotoğraf eklemeye izin ver"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("İndirmeye izin ver"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Kullanıcıların fotoğraf eklemesine izin ver"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Kimliği doğrula"),
        "androidBiometricNotRecognized":
            MessageLookupByLibrary.simpleMessage("Tanınmadı. Tekrar deneyin."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Biyometrik gerekli"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Başarılı"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("İptal et"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Cihaz kimlik bilgileri gerekli"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Cihaz kimlik bilgileri gerekmekte"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Biyometrik kimlik doğrulama cihazınızda ayarlanmamış. Biyometrik kimlik doğrulama eklemek için \'Ayarlar > Güvenlik\' bölümüne gidin."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Masaüstü"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Kimlik doğrulaması gerekli"),
        "appVersion": m16,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple kimliği"),
        "apply": MessageLookupByLibrary.simpleMessage("Uygula"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Kodu girin"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("PlayStore aboneliği"),
        "archive": MessageLookupByLibrary.simpleMessage("Arşiv"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Albümü arşivle"),
        "archiving": MessageLookupByLibrary.simpleMessage("Arşivleniyor..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Aile planından ayrılmak istediğinize emin misiniz?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "İptal etmek istediğinize emin misiniz?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Planı değistirmek istediğinize emin misiniz?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Çıkmak istediğinden emin misin?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Çıkış yapmak istediğinize emin misiniz?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Yenilemek istediğinize emin misiniz?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Aboneliğiniz iptal edilmiştir. Bunun sebebini paylaşmak ister misiniz?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Hesabınızı neden silmek istiyorsunuz?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Sevdiklerinizden paylaşmalarını isteyin"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("serpinti sığınağında"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "E-posta doğrulamasını değiştirmek için lütfen kimlik doğrulaması yapın"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Kilit ekranı ayarını değiştirmek için lütfen kimliğinizi doğrulayın"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "E-postanızı değiştirmek için lütfen kimlik doğrulaması yapın"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Şifrenizi değiştirmek için lütfen kimlik doğrulaması yapın"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "İki faktörlü kimlik doğrulamayı yapılandırmak için lütfen kimlik doğrulaması yapın"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Hesap silme işlemini başlatmak için lütfen kimlik doğrulaması yapın"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Aktif oturumlarınızı görüntülemek için lütfen kimliğinizi doğrulayın"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Gizli dosyalarınızı görüntülemek için kimlik doğrulama yapınız"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Kodlarınızı görmek için lütfen kimlik doğrulaması yapın"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Kurtarma anahtarınızı görmek için lütfen kimliğinizi doğrulayın"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Kimlik doğrulanıyor..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Kimlik doğrulama başarısız oldu, lütfen tekrar deneyin"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("Kimlik doğrulama başarılı!"),
        "available": MessageLookupByLibrary.simpleMessage("Mevcut"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Yedeklenmiş klasörler"),
        "backup": MessageLookupByLibrary.simpleMessage("Yedekle"),
        "backupFailed":
            MessageLookupByLibrary.simpleMessage("Yedekleme başarısız oldu"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("Mobil veri ile yedekle"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Yedekleme seçenekleri"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Videolari yedekle"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Muhteşem Cuma kampanyası"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData":
            MessageLookupByLibrary.simpleMessage("Ön belleğe alınan veri"),
        "calculating": MessageLookupByLibrary.simpleMessage("Hesaplanıyor..."),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Başkalarına ait albümlere yüklenemez"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Yalnızca size ait dosyalar için bağlantı oluşturabilir"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Yalnızca size ait dosyaları kaldırabilir"),
        "cancel": MessageLookupByLibrary.simpleMessage("İptal Et"),
        "cancelOtherSubscription": m18,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Abonelik iptali"),
        "cannotAddMorePhotosAfterBecomingViewer": m3,
        "cannotDeleteSharedFiles":
            MessageLookupByLibrary.simpleMessage("Dosyalar silinemiyor"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Eşleştirmek istediğiniz cihazda cast.ente.io adresini ziyaret edin.\n\nAlbümü TV\'nizde oynatmak için aşağıdaki kodu girin."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Merkez noktası"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("E-posta adresini değiştir"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Seçilen öğelerin konumu değiştirilsin mi?"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Sifrenizi değiştirin"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Parolanızı değiştirin"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("İzinleri değiştir?"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Güncellemeleri kontol et"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Lütfen doğrulama işlemini tamamlamak için gelen kutunuzu (ve spam klasörünüzü) kontrol edin"),
        "checking": MessageLookupByLibrary.simpleMessage("Kontrol ediliyor..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Bedava alan talep edin"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Arttır!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Alındı"),
        "claimedStorageSoFar": m19,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Temiz Genel"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Diğer albümlerde bulunan Kategorilenmemiş tüm dosyaları kaldırın"),
        "clearCaches":
            MessageLookupByLibrary.simpleMessage("Önbellekleri temizle"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Açık Dizin"),
        "click": MessageLookupByLibrary.simpleMessage("• Tıklamak"),
        "clickOnTheOverflowMenu":
            MessageLookupByLibrary.simpleMessage("• Taşma menüsüne tıklayın"),
        "close": MessageLookupByLibrary.simpleMessage("Kapat"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
            "Yakalama zamanına göre kulüp"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Dosya adına göre kulüp"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Kod kabul edildi"),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Kodunuz panoya kopyalandı"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Sizin kullandığınız kod"),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Organizasyon bağlantısı"),
        "collaborativeLinkCreatedFor": m20,
        "collaborator": MessageLookupByLibrary.simpleMessage("Düzenleyici"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Düzenleyiciler, paylaşılan albüme fotoğraf ve videolar ekleyebilir."),
        "collageLayout": MessageLookupByLibrary.simpleMessage("Düzen"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
            "Kolajınız galeriye kaydedildi"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
            "Etkinlik fotoğraflarını topla"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Fotoğrafları topla"),
        "color": MessageLookupByLibrary.simpleMessage("Renk"),
        "confirm": MessageLookupByLibrary.simpleMessage("Onayla"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "İki adımlı kimlik doğrulamasını devre dışı bırakmak istediğinize emin misiniz?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Hesap silme işlemini onayla"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Evet, bu hesabı ve verilerini tüm uygulamalardan kalıcı olarak silmek istiyorum."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Şifrenizi onaylayın"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Plan değişikliğini onaylayın"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Kurtarma anahtarını doğrula"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Kurtarma anahtarını doğrulayın"),
        "contactFamilyAdmin": m23,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Destek ile iletişim"),
        "contactToManageSubscription": m24,
        "contacts": MessageLookupByLibrary.simpleMessage("Kişiler"),
        "contents": MessageLookupByLibrary.simpleMessage("İçerikler"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Devam edin"),
        "continueOnFreeTrial":
            MessageLookupByLibrary.simpleMessage("Ücretsiz denemeye devam et"),
        "convertToAlbum": MessageLookupByLibrary.simpleMessage("Albüme taşı"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("E-posta adresini kopyala"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Linki kopyala"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Bu kodu kopyalayın ve kimlik doğrulama uygulamanıza yapıştırın"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Verilerinizi yedekleyemedik.\nDaha sonra tekrar deneyeceğiz."),
        "couldNotFreeUpSpace":
            MessageLookupByLibrary.simpleMessage("Yer boşaltılamadı"),
        "couldNotUpdateSubscription":
            MessageLookupByLibrary.simpleMessage("Abonelikler kaydedilemedi"),
        "count": MessageLookupByLibrary.simpleMessage("Miktar"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Çökme raporlaması"),
        "create": MessageLookupByLibrary.simpleMessage("Oluştur"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Hesap oluşturun"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Fotoğrafları seçmek için uzun basın ve + düğmesine tıklayarak bir albüm oluşturun"),
        "createCollage": MessageLookupByLibrary.simpleMessage("Kolaj oluştur"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Yeni bir hesap oluşturun"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Albüm oluştur veya seç"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Herkese açık link oluştur"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Bağlantı oluşturuluyor..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("Kritik güncelleme mevcut"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Güncel kullanımınız "),
        "custom": MessageLookupByLibrary.simpleMessage("Kişisel"),
        "customEndpoint": m25,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Karanlık"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Bugün"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Dün"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("Şifre çözülüyor..."),
        "decryptingVideo": MessageLookupByLibrary.simpleMessage(
            "Videonun şifresi çözülüyor..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Dosyaları Tekilleştirme"),
        "delete": MessageLookupByLibrary.simpleMessage("Sil"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Hesabı sil"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Aramızdan ayrıldığınız için üzgünüz. Lütfen kendimizi geliştirmemize yardımcı olun. Neden ayrıldığınızı Açıklar mısınız."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Hesabımı kalıcı olarak sil"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Albümü sil"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Ayrıca bu albümde bulunan fotoğrafları (ve videoları) parçası oldukları <bold>tüm</bold> diğer albümlerden silebilir miyim?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Bu, tüm boş albümleri silecektir. Bu, albüm listenizdeki dağınıklığı azaltmak istediğinizde kullanışlıdır."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Hepsini Sil"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Lütfen kayıtlı e-posta adresinizden <warning>account-deletion@ente.io</warning>\'a e-posta gönderiniz."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Boş albümleri sil"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Boş albümleri sileyim mi?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Her ikisinden de sil"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Cihazınızdan silin"),
        "deleteItemCount": m26,
        "deleteLocation": MessageLookupByLibrary.simpleMessage("Konumu sil"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Fotoğrafları sil"),
        "deleteProgress": m27,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "İhtiyacım olan önemli bir özellik eksik"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Uygulama veya bir özellik olması gerektiğini düşündüğüm gibi çalışmıyor"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Daha çok sevdiğim başka bir hizmet buldum"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Nedenim listede yok"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "İsteğiniz 72 saat içinde gerçekleştirilecek."),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Paylaşılan albüm silinsin mi?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Albüm herkes için silinecek\n\nBu albümdeki başkalarına ait paylaşılan fotoğraflara erişiminizi kaybedeceksiniz"),
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Tüm seçimi kaldır"),
        "designedToOutlive": MessageLookupByLibrary.simpleMessage(
            "Hayatta kalmak için tasarlandı"),
        "details": MessageLookupByLibrary.simpleMessage("Ayrıntılar"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Geliştirici ayarları"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Geliştirici ayarlarını değiştirmek istediğinizden emin misiniz?"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Kodu girin"),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Cihaz bulunamadı"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Biliyor musun?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Otomatik kilidi devre dışı bırak"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Görüntüleyiciler, hala harici araçlar kullanarak ekran görüntüsü alabilir veya fotoğraflarınızın bir kopyasını kaydedebilir. Lütfen bunu göz önünde bulundurunuz"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Lütfen dikkate alın"),
        "disableLinkMessage": m28,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "İki Aşamalı Doğrulamayı Devre Dışı Bırak"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "İki aşamalı doğrulamayı devre dışı bırak..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Reddet"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Çıkış yapma"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Sonra yap"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Yaptığınız düzenlemeleri silmek istiyor musunuz?"),
        "done": MessageLookupByLibrary.simpleMessage("Bitti"),
        "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "Depolama alanınızı ikiye katlayın"),
        "download": MessageLookupByLibrary.simpleMessage("İndir"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("İndirme başarısız"),
        "downloading": MessageLookupByLibrary.simpleMessage("İndiriliyor..."),
        "dropSupportEmail": m29,
        "duplicateFileCountWithStorageSaved": m30,
        "duplicateItemsGroup": m31,
        "edit": MessageLookupByLibrary.simpleMessage("Düzenle"),
        "editLocation": MessageLookupByLibrary.simpleMessage("Konumu düzenle"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Konumu düzenle"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Düzenleme kaydedildi"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Konumda yapılan düzenlemeler yalnızca Ente\'de görülecektir"),
        "eligible": MessageLookupByLibrary.simpleMessage("uygun"),
        "email": MessageLookupByLibrary.simpleMessage("E-Posta"),
        "emailChangedTo": m32,
        "emailNoEnteAccount": m33,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("E-posta doğrulama"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "Günlüklerinizi e-postayla gönderin"),
        "empty": MessageLookupByLibrary.simpleMessage("Boşalt"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Çöp kutusu boşaltılsın mı?"),
        "enableMaps":
            MessageLookupByLibrary.simpleMessage("Haritaları Etkinleştir"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Bu, fotoğraflarınızı bir dünya haritasında gösterecektir.\n\nBu harita Open Street Map tarafından barındırılmaktadır ve fotoğraflarınızın tam konumları hiçbir zaman paylaşılmaz.\n\nBu özelliği istediğiniz zaman Ayarlar\'dan devre dışı bırakabilirsiniz."),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Yedekleme şifreleniyor..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Şifreleme"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Sifreleme anahtarı"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Fatura başarıyla güncellendi"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Varsayılan olarak uçtan uca şifrelenmiş"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente fotoğrafları saklamak için <i>iznine ihtiyaç duyuyor</i>"),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Aileniz de planınıza eklenebilir."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Bir albüm adı girin"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Kodu giriniz"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Arkadaşınız tarafından sağlanan kodu girerek hem sizin hem de arkadaşınızın ücretsiz depolamayı talep etmek için girin"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("E-postanızı giriniz"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Dosya adını girin"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Verilerinizi şifrelemek için kullanabileceğimiz yeni bir şifre girin"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Şifrenizi girin"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Verilerinizi şifrelemek için kullanabileceğimiz bir şifre girin"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Davet kodunuzu girin"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Doğrulama uygulamasındaki 6 basamaklı kodu giriniz"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Lütfen geçerli bir E-posta adresi girin."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("E-posta adresinizi girin"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Lütfen şifrenizi giriniz"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Kurtarma kodunuzu girin"),
        "error": MessageLookupByLibrary.simpleMessage("Hata"),
        "everywhere": MessageLookupByLibrary.simpleMessage("her yerde"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Mevcut kullanıcı"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Bu bağlantının süresi dolmuştur. Lütfen yeni bir süre belirleyin veya bağlantı süresini devre dışı bırakın."),
        "exportLogs":
            MessageLookupByLibrary.simpleMessage("Günlüğü dışa aktar"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Veriyi dışarı aktar"),
        "faces": MessageLookupByLibrary.simpleMessage("Yüzler"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Uygulanırken hata oluştu"),
        "failedToCancel": MessageLookupByLibrary.simpleMessage(
            "İptal edilirken sorun oluştu"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Video indirilemedi"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Düzenleme için orijinal getirilemedi"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Davet ayrıntıları çekilemedi. Iütfen daha sonra deneyin."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Albüm yüklenirken hata oluştu"),
        "failedToRenew": MessageLookupByLibrary.simpleMessage(
            "Abonelik yenilenirken hata oluştu"),
        "failedToVerifyPaymentStatus":
            MessageLookupByLibrary.simpleMessage("Ödeme durumu doğrulanamadı"),
        "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("Aile"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Aile Planı"),
        "faq": MessageLookupByLibrary.simpleMessage("Sıkça sorulan sorular"),
        "faqs": MessageLookupByLibrary.simpleMessage("Sık sorulanlar"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favori"),
        "feedback": MessageLookupByLibrary.simpleMessage("Geri Bildirim"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Dosya galeriye kaydedilemedi"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Bir açıklama ekle..."),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Video galeriye kaydedildi"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Dosya türü"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Dosya türleri ve adları"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Dosyalar silinmiş"),
        "flip": MessageLookupByLibrary.simpleMessage("Çevir"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("anıların için"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Şifremi unuttum"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Alınan bedava alan"),
        "freeStorageOnReferralSuccess": m4,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Kullanılabilir bedava alan"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Ücretsiz deneme"),
        "freeTrialValidTill": m37,
        "freeUpAmount": m39,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Cihaz alanını boşaltın"),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Boş alan"),
        "freeUpSpaceSaving": m40,
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Galeride 1000\'e kadar anı gösterilir"),
        "general": MessageLookupByLibrary.simpleMessage("Genel"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Şifreleme anahtarı oluşturuluyor..."),
        "genericProgress": m41,
        "goToSettings": MessageLookupByLibrary.simpleMessage("Ayarlara git"),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("Google play kimliği"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Lütfen Ayarlar uygulamasında tüm fotoğraflara erişime izin verin"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("İzinleri değiştir"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
            "Yakındaki fotoğrafları gruplandır"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Biz uygulama kurulumlarını takip etmiyoruz. Bizi nereden duyduğunuzdan bahsetmeniz bize çok yardımcı olacak!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Ente\'yi nereden duydunuz? (opsiyonel)"),
        "help": MessageLookupByLibrary.simpleMessage("Yardım"),
        "hidden": MessageLookupByLibrary.simpleMessage("Gizle"),
        "hide": MessageLookupByLibrary.simpleMessage("Gizle"),
        "hiding": MessageLookupByLibrary.simpleMessage("Gizleniyor..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("OSM Fransa\'da ağırlandı"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Nasıl çalışır"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Lütfen onlardan ayarlar ekranında e-posta adresine uzun süre basmalarını ve her iki cihazdaki kimliklerin eşleştiğini doğrulamalarını isteyin."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Cihazınızda biyometrik kimlik doğrulama ayarlanmamış. Lütfen telefonunuzda Touch ID veya Face ID\'yi etkinleştirin."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "Biyometrik kimlik doğrulama devre dışı. Etkinleştirmek için lütfen ekranınızı kilitleyin ve kilidini açın."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("Tamam"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Yoksay"),
        "importing":
            MessageLookupByLibrary.simpleMessage("İçeri aktarılıyor...."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("Yanlış kod"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Yanlış şifre"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Yanlış kurtarma kodu"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Girdiğiniz kurtarma kod yanlış"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Yanlış kurtarma kodu"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Yeni öğeleri indeksle"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Güvenilir olmayan cihaz"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Manuel kurulum"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Geçersiz e-posta adresi"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Geçersiz uç nokta"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Üzgünüz, girdiğiniz uç nokta geçersiz. Lütfen geçerli bir uç nokta girin ve tekrar deneyin."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Gecersiz anahtar"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Girdiğiniz kurtarma anahtarı geçerli değil. Lütfen anahtarın 24 kelime içerdiğinden ve her bir kelimenin doğru şekilde yazıldığından emin olun.\n\nEğer eski bir kurtarma kodu girdiyseniz, o zaman kodun 64 karakter uzunluğunda olduğunu kontrol edin."),
        "invite": MessageLookupByLibrary.simpleMessage("Davet et"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Arkadaşlarını davet et"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Bir şeyler ters gitmiş gibi görünüyor. Lütfen bir süre sonra tekrar deneyin. Hata devam ederse, lütfen destek ekibimizle iletişime geçin."),
        "itemCount": m42,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Öğeler, kalıcı olarak silinmeden önce kalan gün sayısını gösterir"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Seçilen öğeler bu albümden kaldırılacak"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("Discord\'a Katıl"),
        "keepPhotos":
            MessageLookupByLibrary.simpleMessage("Fotoğrafları sakla"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Lütfen bu bilgilerle bize yardımcı olun"),
        "language": MessageLookupByLibrary.simpleMessage("Dil"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("En son güncellenen"),
        "leave": MessageLookupByLibrary.simpleMessage("Çıkış yap"),
        "leaveAlbum":
            MessageLookupByLibrary.simpleMessage("Albümü yeniden adlandır"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Aile planından ayrıl"),
        "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Paylaşılan albüm silinsin mi?"),
        "light": MessageLookupByLibrary.simpleMessage("Aydınlık"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Aydınlık"),
        "linkCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Link panoya kopyalandı"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Cihaz limiti"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Geçerli"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Süresi dolmuş"),
        "linkExpiresOn": m44,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Linkin geçerliliği"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Bağlantının süresi dolmuş"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Asla"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("Canlı Fotoğraf"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Aboneliğinizi ailenizle paylaşabilirsiniz"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Şu ana kadar 30 milyondan fazla anıyı koruduk"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Verilerinizin 3 kopyasını saklıyoruz, biri yer altı serpinti sığınağında"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Tüm uygulamalarımız açık kaynaktır"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Kaynak kodumuz ve şifrelememiz harici olarak denetlenmiştir"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Albümlerinizin bağlantılarını sevdiklerinizle paylaşabilirsiniz"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Mobil uygulamalarımız, tıkladığınız yeni fotoğrafları şifrelemek ve yedeklemek için arka planda çalışır"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io\'nun mükemmel bir yükleyicisi var"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Verilerinizi güvenli bir şekilde şifrelemek için Xchacha20Poly1305 kullanıyoruz"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("EXIF verileri yükleniyor..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Galeri yükleniyor..."),
        "loadingMessage": MessageLookupByLibrary.simpleMessage(
            "Fotoğraflarınız yükleniyor..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Modeller indiriliyor..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Yerel galeri"),
        "location": MessageLookupByLibrary.simpleMessage("Konum"),
        "locationName": MessageLookupByLibrary.simpleMessage("Konum Adı"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Bir fotoğrafın belli bir yarıçapında çekilen fotoğrafları gruplandırın"),
        "locations": MessageLookupByLibrary.simpleMessage("Konum"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Kilit"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Kilit ekranı"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Giriş yap"),
        "loggingOut":
            MessageLookupByLibrary.simpleMessage("Çıkış yapılıyor..."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "\"Giriş yap\" düğmesine tıklayarak, <u-terms>Hizmet Şartları</u-terms>\'nı ve <u-policy>Gizlilik Politikası</u-policy>\'nı kabul ediyorum"),
        "logout": MessageLookupByLibrary.simpleMessage("Çıkış yap"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Bu, sorununuzu gidermemize yardımcı olmak için günlükleri gönderecektir. Belirli dosyalarla ilgili sorunların izlenmesine yardımcı olmak için dosya adlarının ekleneceğini lütfen unutmayın."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Uçtan uca şifrelemeyi doğrulamak için bir e-postaya uzun basın."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Tam ekranda görüntülemek için bir öğeye uzun basın"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Cihazı kayıp mı ettiniz?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Makine öğrenimi"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Sihirli arama"),
        "manage": MessageLookupByLibrary.simpleMessage("Yönet"),
        "manageFamily": MessageLookupByLibrary.simpleMessage("Aileyi yönet"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Linki yönet"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Yönet"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Abonelikleri yönet"),
        "map": MessageLookupByLibrary.simpleMessage("Harita"),
        "maps": MessageLookupByLibrary.simpleMessage("Haritalar"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m5,
        "merchandise": MessageLookupByLibrary.simpleMessage("Ürünler"),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobil, Web, Masaüstü"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Ilımlı"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Sorgunuzu değiştirin veya aramayı deneyin"),
        "moments": MessageLookupByLibrary.simpleMessage("Anlar"),
        "monthly": MessageLookupByLibrary.simpleMessage("Aylık"),
        "moveItem": m45,
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Albüme taşı"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Gizli albüme ekle"),
        "movedSuccessfullyTo": m46,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Cöp kutusuna taşı"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Dosyalar albüme taşınıyor..."),
        "name": MessageLookupByLibrary.simpleMessage("İsim"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Ente\'ye bağlanılamıyor. Lütfen bir süre sonra tekrar deneyin. Hata devam ederse lütfen desteğe başvurun."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Ente\'ye bağlanılamıyor. Lütfen ağ ayarlarınızı kontrol edin ve hata devam ederse destek ekibiyle iletişime geçin."),
        "never": MessageLookupByLibrary.simpleMessage("Asla"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Yeni albüm"),
        "newest": MessageLookupByLibrary.simpleMessage("En yeni"),
        "no": MessageLookupByLibrary.simpleMessage("Hayır"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Henüz paylaştığınız albüm yok"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Yok"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Bu cihazda silinebilecek hiçbir dosyanız yok"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("Yinelenenleri kaldır"),
        "noExifData": MessageLookupByLibrary.simpleMessage("EXIF verisi yok"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Gizli fotoğraf veya video yok"),
        "noImagesWithLocation":
            MessageLookupByLibrary.simpleMessage("Konum içeren resim yok"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("İnternet bağlantısı yok"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Şu anda hiçbir fotoğraf yedeklenmiyor"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("Burada fotoğraf bulunamadı"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Kurtarma kodunuz yok mu?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Uçtan uca şifreleme protokolümüzün doğası gereği, verileriniz şifreniz veya kurtarma anahtarınız olmadan çözülemez"),
        "noResults": MessageLookupByLibrary.simpleMessage("Sonuç bulunamadı"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Hiçbir sonuç bulunamadı"),
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Henüz sizinle paylaşılan bir şey yok"),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
            "Burada görülecek bir şey yok! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Bildirimler"),
        "ok": MessageLookupByLibrary.simpleMessage("Tamam"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Bu cihaz"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "<branding>ente</branding> üzerinde"),
        "oops": MessageLookupByLibrary.simpleMessage("Hay aksi"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Hata! Düzenlemeler kaydedilemedi"),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
            "Hoop, Birşeyler yanlış gitti"),
        "openSettings": MessageLookupByLibrary.simpleMessage("Ayarları Açın"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Öğeyi açın"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
            "© OpenStreetMap katkıda bululanlar"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "İsteğe bağlı, istediğiniz kadar kısa..."),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Veya mevcut birini seçiniz"),
        "pair": MessageLookupByLibrary.simpleMessage("Eşleştir"),
        "passkey": MessageLookupByLibrary.simpleMessage("Parola Anahtarı"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Geçiş anahtarı doğrulaması"),
        "password": MessageLookupByLibrary.simpleMessage("Şifre"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Şifreniz başarılı bir şekilde değiştirildi"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Sifre kilidi"),
        "passwordStrength": m0,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Şifrelerinizi saklamıyoruz, bu yüzden unutursanız, <underline>verilerinizi deşifre edemeyiz</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Ödeme detayları"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Ödeme başarısız oldu"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Maalesef ödemeniz başarısız oldu. Lütfen destekle iletişime geçin, size yardımcı olacağız!"),
        "paymentFailedTalkToProvider": m50,
        "pendingItems": MessageLookupByLibrary.simpleMessage("Bekleyen Öğeler"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Senkronizasyon bekleniyor"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("Kodunuzu kullananlar"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Çöp kutusundaki tüm öğeler kalıcı olarak silinecek\n\nBu işlem geri alınamaz"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Kalıcı olarak sil"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Cihazdan kalıcı olarak silinsin mi?"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Fotoğraf Açıklaması"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Fotoğraf ızgara boyutu"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("fotoğraf"),
        "photos": MessageLookupByLibrary.simpleMessage("Fotoğraflar"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Eklediğiniz fotoğraflar albümden kaldırılacak"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Merkez noktasını seçin"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Albümü sabitle"),
        "playOnTv": MessageLookupByLibrary.simpleMessage("Albümü TV\'de oynat"),
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("PlayStore aboneliği"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Lütfen internet bağlantınızı kontrol edin ve yeniden deneyin."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Lütfen support@ente.io ile iletişime geçin; size yardımcı olmaktan memnuniyet duyarız!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Bu hata devam ederse lütfen desteğe başvurun"),
        "pleaseEmailUsAt": m53,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Lütfen izin ver"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Lütfen tekrar giriş yapın"),
        "pleaseSendTheLogsTo": m54,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Lütfen tekrar deneyiniz"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Lütfen girdiğiniz kodu doğrulayın"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Lütfen bekleyiniz..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Lütfen bekleyin, albüm siliniyor"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Tekrar denemeden önce lütfen bir süre bekleyin"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Günlük hazırlanıyor..."),
        "preserveMore":
            MessageLookupByLibrary.simpleMessage("Daha fazlasını koruyun"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Videoları yönetmek için basılı tutun"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Videoyu oynatmak için resmi basılı tutun"),
        "privacy": MessageLookupByLibrary.simpleMessage("Gizlilik"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Mahremiyet Politikası"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Özel yedeklemeler"),
        "privateSharing": MessageLookupByLibrary.simpleMessage("Özel paylaşım"),
        "publicLinkCreated": MessageLookupByLibrary.simpleMessage(
            "Herkese açık link oluşturuldu"),
        "publicLinkEnabled": MessageLookupByLibrary.simpleMessage(
            "Herkese açık bağlantı aktive edildi"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Hızlı Erişim"),
        "radius": MessageLookupByLibrary.simpleMessage("Yarıçap"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Bileti artır"),
        "rateTheApp":
            MessageLookupByLibrary.simpleMessage("Uygulamaya puan verin"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Bizi değerlendirin"),
        "rateUsOnStore": m56,
        "recover": MessageLookupByLibrary.simpleMessage("Kurtarma"),
        "recoverAccount": MessageLookupByLibrary.simpleMessage("Hesabı kurtar"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Kurtar"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Kurtarma anahtarı"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Kurtarma anahtarınız panoya kopyalandı"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Şifrenizi unutursanız, verilerinizi kurtarmanın tek yolu bu anahtar olacaktır."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Bu anahtarı saklamıyoruz, lütfen bu 24 kelime anahtarı güvenli bir yerde saklayın."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Harika! Kurtarma anahtarınız geçerlidir. Doğrulama için teşekkür ederim.\n\nLütfen kurtarma anahtarınızı güvenli bir şekilde yedeklediğinizden emin olun."),
        "recoveryKeyVerified":
            MessageLookupByLibrary.simpleMessage("Kurtarma kodu doğrulandı"),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Kurtarma başarılı!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Cihazınız, şifrenizi doğrulamak için yeterli güce sahip değil, ancak tüm cihazlarda çalışacak şekilde yeniden oluşturabiliriz.\n\nLütfen kurtarma anahtarınızı kullanarak giriş yapın ve şifrenizi yeniden oluşturun (istediğiniz takdirde aynı şifreyi tekrar kullanabilirsiniz)."),
        "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
            "Sifrenizi tekrardan oluşturun"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Arkadaşlarınıza önerin ve planınızı 2 katına çıkarın"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Bu kodu arkadaşlarınıza verin"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Ücretli bir plan için kaydolsunlar"),
        "referralStep3": m60,
        "referrals": MessageLookupByLibrary.simpleMessage("Referanslar"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Davetler şu anda durmuş durumda"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Ayrıca boşalan alanı talep etmek için \"Ayarlar\" -> \"Depolama\" bölümünden \"Son Silinenler \"i boşaltın"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Ayrıca boşalan alana sahip olmak için \"Çöp Kutunuzu\" boşaltın"),
        "remoteImages":
            MessageLookupByLibrary.simpleMessage("Uzaktan Görüntüler"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Uzak Küçük Resim"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Uzak videolar"),
        "remove": MessageLookupByLibrary.simpleMessage("Kaldır"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Yinelenenleri kaldır"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Albümden çıkar"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Albümden çıkarılsın mı?"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Linki kaldır"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Katılımcıyı kaldır"),
        "removeParticipantBody": m61,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Herkese açık link oluştur"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Kaldırdığınız öğelerden bazıları başkaları tarafından eklenmiştir ve bunlara erişiminizi kaybedeceksiniz"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Kaldır?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Favorilerimden kaldır..."),
        "rename": MessageLookupByLibrary.simpleMessage("Yeniden adlandır"),
        "renameAlbum":
            MessageLookupByLibrary.simpleMessage("Albümü yeniden adlandır"),
        "renameFile":
            MessageLookupByLibrary.simpleMessage("Dosyayı yeniden adlandır"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Abonelik yenileme"),
        "renewsOn": m62,
        "reportABug": MessageLookupByLibrary.simpleMessage("Hatayı bildir"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Hata bildir"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("E-postayı yeniden gönder"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Yok sayılan dosyaları sıfırla"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Parolanızı sıfırlayın"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Varsayılana sıfırla"),
        "restore": MessageLookupByLibrary.simpleMessage("Yenile"),
        "restoreToAlbum": MessageLookupByLibrary.simpleMessage("Albümü yenile"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Dosyalar geri yükleniyor..."),
        "retry": MessageLookupByLibrary.simpleMessage("Tekrar dene"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Lütfen kopya olduğunu düşündüğünüz öğeleri inceleyin ve silin."),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Sola döndür"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Sağa döndür"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Güvenle saklanır"),
        "save": MessageLookupByLibrary.simpleMessage("Kaydet"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Kolajı kaydet"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Kopyasını kaydet"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Anahtarı kaydet"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Henüz yapmadıysanız kurtarma anahtarınızı kaydetmeyi unutmayın"),
        "saving": MessageLookupByLibrary.simpleMessage("Kaydediliyor..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Kodu tarayın"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kimlik doğrulama uygulamanız ile kodu tarayın"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Albümler"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Albüm adı"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Albüm adları (ör. \"Kamera\")\n• Dosya türleri (ör. \"Videolar\", \".gif\")\n• Yıllar ve aylar (ör. \"2022\", \"Ocak\")\n• Tatiller (ör. \"Noel\")\n• Fotoğraf açıklamaları (ör. \"#eğlence\")"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Fotoğraf bilgilerini burada hızlı bir şekilde bulmak için \"#trip\" gibi açıklamalar ekleyin"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Tarihe, aya veya yıla göre arama yapın"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Dosya türleri ve adları"),
        "searchHint1":
            MessageLookupByLibrary.simpleMessage("Hızlı, cihaz üzerinde arama"),
        "searchHint2": MessageLookupByLibrary.simpleMessage(
            "Fotoğraf tarihleri, açıklamalar"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Albümler, dosya adları ve türleri"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Konum"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Çok yakında: Yüzler ve sihirli arama ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Bir fotoğrafın belli bir yarıçapında çekilen fotoğrafları gruplandırın"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "İnsanları davet ettiğinizde onların paylaştığı tüm fotoğrafları burada göreceksiniz"),
        "searchResultCount": m63,
        "security": MessageLookupByLibrary.simpleMessage("Güvenlik"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Bir konum seçin"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Önce yeni yer seçin"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Albüm seçin"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Hepsini seç"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Yedekleme için klasörleri seçin"),
        "selectItemsToAdd":
            MessageLookupByLibrary.simpleMessage("Eklenecek eşyaları seçin"),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("Dil Seçin"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Daha Fazla Fotoğraf Seç"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Ayrılma nedeninizi seçin"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Planınızı seçin"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Seçilen klasörler şifrelenecek ve yedeklenecektir"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Seçilen öğeler tüm albümlerden silinecek ve çöp kutusuna taşınacak."),
        "selectedPhotos": m6,
        "selectedPhotosWithYours": m65,
        "send": MessageLookupByLibrary.simpleMessage("Gönder"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("E-posta gönder"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Davet kodu gönder"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Link gönder"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Sunucu uç noktası"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Oturum süresi doldu"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Şifre ayarla"),
        "setAs": MessageLookupByLibrary.simpleMessage("Şu şekilde ayarla"),
        "setCover": MessageLookupByLibrary.simpleMessage("Kapak Belirle"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Ayarla"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Parola ayarlayın"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Yarıçapı ayarla"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Ayarlama işlemi başarılı"),
        "share": MessageLookupByLibrary.simpleMessage("Paylaş"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Linki paylaş"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Bir albüm açın ve paylaşmak için sağ üstteki paylaş düğmesine dokunun."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Şimdi bir albüm paylaşın"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Linki paylaş"),
        "shareMyVerificationID": m66,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Yalnızca istediğiniz kişilerle paylaşın"),
        "shareTextConfirmOthersVerificationID": m7,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Ente kullanıcısı olmayanlar için paylaş"),
        "shareWithPeopleSectionTitle": m68,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("İlk albümünüzü paylaşın"),
        "sharedByMe":
            MessageLookupByLibrary.simpleMessage("Benim paylaştıklarım"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Paylaştıklarınız"),
        "sharedPhotoNotifications": MessageLookupByLibrary.simpleMessage(
            "Paylaşılan fotoğrafları ekle"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Birisi sizin de parçası olduğunuz paylaşılan bir albüme fotoğraf eklediğinde bildirim alın"),
        "sharedWith": m69,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Benimle paylaşılan"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Sizinle paylaşıldı"),
        "sharing": MessageLookupByLibrary.simpleMessage("Paylaşılıyor..."),
        "showMemories": MessageLookupByLibrary.simpleMessage("Anıları göster"),
        "signOutFromOtherDevices":
            MessageLookupByLibrary.simpleMessage("Diğer cihazlardan çıkış yap"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Eğer başka birisinin parolanızı bildiğini düşünüyorsanız, diğer tüm cihazları hesabınızdan çıkışa zorlayabilirsiniz."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Diğer cihazlardan çıkış yap"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "<u-terms>Hizmet Şartları</u-terms>\'nı ve <u-policy>Gizlilik Politikası</u-policy>\'nı kabul ediyorum"),
        "singleFileDeleteFromDevice": m70,
        "singleFileDeleteHighlight":
            MessageLookupByLibrary.simpleMessage("Tüm albümlerden silinecek."),
        "skip": MessageLookupByLibrary.simpleMessage("Geç"),
        "social": MessageLookupByLibrary.simpleMessage("Sosyal Medya"),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Silmeye çalıştığınız dosyalardan bazıları yalnızca cihazınızda mevcuttur ve silindiği takdirde kurtarılamaz"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Size albümleri paylaşan biri, kendi cihazında aynı kimliği görmelidir."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Bazı şeyler yanlış gitti"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Bir şeyler ters gitti, lütfen tekrar deneyin"),
        "sorry": MessageLookupByLibrary.simpleMessage("Üzgünüz"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Üzgünüm, favorilere ekleyemedim!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Üzgünüm, favorilere ekleyemedim!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Üzgünüz, girdiğiniz kod yanlış"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Üzgünüm, bu cihazda güvenli anahtarlarını oluşturamadık.\n\nLütfen başka bir cihazdan giriş yapmayı deneyiniz."),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sırala"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Yeniden eskiye"),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage("Önce en eski"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Başarılı"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Yedeklemeyi başlat"),
        "status": MessageLookupByLibrary.simpleMessage("Durum"),
        "storage": MessageLookupByLibrary.simpleMessage("Depolama"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Aile"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Sen"),
        "storageInGB": m1,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Depolama sınırı aşıldı"),
        "storageUsageInfo": m73,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Güçlü"),
        "subWillBeCancelledOn": m75,
        "subscribe": MessageLookupByLibrary.simpleMessage("Abone ol"),
        "subscription": MessageLookupByLibrary.simpleMessage("Abonelik"),
        "success": MessageLookupByLibrary.simpleMessage("Başarılı"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Başarıyla arşivlendi"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Başarıyla saklandı"),
        "successfullyUnarchived": MessageLookupByLibrary.simpleMessage(
            "Başarıyla arşivden çıkarıldı"),
        "successfullyUnhid": MessageLookupByLibrary.simpleMessage(
            "Başarıyla arşivden çıkarıldı"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Özellik önerin"),
        "support": MessageLookupByLibrary.simpleMessage("Destek"),
        "syncProgress": m76,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Senkronizasyon durduruldu"),
        "syncing": MessageLookupByLibrary.simpleMessage("Eşitleniyor..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistem"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("kopyalamak için dokunun"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Kodu girmek icin tıklayın"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Bir şeyler ters gitmiş gibi görünüyor. Lütfen bir süre sonra tekrar deneyin. Hata devam ederse, lütfen destek ekibimizle iletişime geçin."),
        "terminate": MessageLookupByLibrary.simpleMessage("Sonlandır"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Oturumu sonlandır?"),
        "terms": MessageLookupByLibrary.simpleMessage("Şartlar"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Şartlar"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Teşekkürler"),
        "thankYouForSubscribing": MessageLookupByLibrary.simpleMessage(
            "Abone olduğunuz için teşekkürler!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "İndirme işlemi tamamlanamadı"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Girdiğiniz kurtarma kodu yanlış"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Bu öğeler cihazınızdan silinecektir."),
        "theyAlsoGetXGb": m8,
        "theyWillBeDeletedFromAllAlbums":
            MessageLookupByLibrary.simpleMessage("Tüm albümlerden silinecek."),
        "thisActionCannotBeUndone":
            MessageLookupByLibrary.simpleMessage("Bu eylem geri alınamaz"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Bu albümde zaten bir ortak çalışma bağlantısı var"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Bu, iki faktörünüzü kaybederseniz hesabınızı kurtarmak için kullanılabilir"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Bu cihaz"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Bu e-posta zaten kullanılıyor"),
        "thisImageHasNoExifData":
            MessageLookupByLibrary.simpleMessage("Bu görselde exif verisi yok"),
        "thisIsPersonVerificationId": m78,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("Doğrulama kimliğiniz"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Bu, sizi aşağıdaki cihazdan çıkış yapacak:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Bu cihazdaki oturumunuz kapatılacak!"),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Bir fotoğrafı veya videoyu gizlemek için"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Şifrenizi sıfılamak için lütfen e-postanızı girin."),
        "todaysLogs":
            MessageLookupByLibrary.simpleMessage("Bugünün günlükleri"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Toplam boyut"),
        "trash": MessageLookupByLibrary.simpleMessage("Cöp kutusu"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Tekrar deneyiniz"),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "Yıllık planlarda 2 ay ücretsiz"),
        "twofactor": MessageLookupByLibrary.simpleMessage("İki faktör"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "İki faktörlü kimlik doğrulama devre dışı"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("İki faktörlü doğrulama"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "İki faktörlü kimlik doğrulama başarıyla sıfırlandı"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Cift faktör ayarı"),
        "unarchive": MessageLookupByLibrary.simpleMessage("Arşivden cıkar"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Arşivden Çıkar"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Arşivden çıkarılıyor..."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Kategorisiz"),
        "unhide": MessageLookupByLibrary.simpleMessage("Gizleme"),
        "unhideToAlbum": MessageLookupByLibrary.simpleMessage("Albümü gizleme"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Gösteriliyor..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Albümdeki dosyalar gösteriliyor"),
        "unlock": MessageLookupByLibrary.simpleMessage("Kilidi aç"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage(
            "Albümün sabitlemesini kaldır"),
        "unselectAll":
            MessageLookupByLibrary.simpleMessage("Tümünün seçimini kaldır"),
        "update": MessageLookupByLibrary.simpleMessage("Güncelle"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Güncelleme mevcut"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Klasör seçimi güncelleniyor..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Yükselt"),
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Dosyalar albüme taşınıyor..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "4 Aralık\'a kadar %50\'ye varan indirim."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Kullanılabilir depolama alanı mevcut planınızla sınırlıdır. Talep edilen fazla depolama alanı, planınızı yükselttiğinizde otomatik olarak kullanılabilir hale gelecektir."),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Kurtarma anahtarını kullan"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Seçilen fotoğrafı kullan"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Kullanılan alan"),
        "validTill": m84,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Doğrulama başarısız oldu, lütfen tekrar deneyin"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Doğrulama kimliği"),
        "verify": MessageLookupByLibrary.simpleMessage("Doğrula"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("E-posta adresini doğrulayın"),
        "verifyEmailID": m85,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Doğrula"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Şifrenizi doğrulayın"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Şifrenizi doğrulayın"),
        "verifying": MessageLookupByLibrary.simpleMessage("Doğrulanıyor..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Kurtarma kodu doğrulanıyor..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "videos": MessageLookupByLibrary.simpleMessage("Videolar"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Aktif oturumları görüntüle"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Eklentileri görüntüle"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Tümünü görüntüle"),
        "viewAllExifData": MessageLookupByLibrary.simpleMessage(
            "Tüm EXIF verilerini görüntüle"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Günlükleri göster"),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Kurtarma anahtarını görüntüle"),
        "viewer": MessageLookupByLibrary.simpleMessage("Görüntüleyici"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Aboneliğinizi yönetmek için lütfen web.ente.io adresini ziyaret edin"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Doğrulama bekleniyor..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("WiFi bekleniyor..."),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Biz açık kaynağız!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Henüz sahibi olmadığınız fotoğraf ve albümlerin düzenlenmesini desteklemiyoruz"),
        "weHaveSendEmailTo": m2,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Zayıf"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Tekrardan hoşgeldin!"),
        "yearly": MessageLookupByLibrary.simpleMessage("Yıllık"),
        "yearsAgo": m87,
        "yes": MessageLookupByLibrary.simpleMessage("Evet"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Evet, iptal et"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Evet, görüntüleyici olarak dönüştür"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Evet, sil"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Evet, değişiklikleri sil"),
        "yesLogout":
            MessageLookupByLibrary.simpleMessage("Evet, oturumu kapat"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Evet, sil"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Evet, yenile"),
        "you": MessageLookupByLibrary.simpleMessage("Sen"),
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("Aile planı kullanıyorsunuz!"),
        "youAreOnTheLatestVersion":
            MessageLookupByLibrary.simpleMessage("En son sürüme sahipsiniz"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Alanınızı en fazla ikiye katlayabilirsiniz"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Bağlantılarınızı paylaşım sekmesinden yönetebilirsiniz."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Farklı bir sorgu aramayı deneyebilirsiniz."),
        "youCannotDowngradeToThisPlan":
            MessageLookupByLibrary.simpleMessage("Bu plana geçemezsiniz"),
        "youCannotShareWithYourself":
            MessageLookupByLibrary.simpleMessage("Kendinizle paylaşamazsınız"),
        "youDontHaveAnyArchivedItems":
            MessageLookupByLibrary.simpleMessage("Arşivlenmiş öğeniz yok."),
        "youHaveSuccessfullyFreedUp": m88,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Hesabınız silindi"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Haritalarınız"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Planınız başarıyla düşürüldü"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Planınız başarılı şekilde yükseltildi"),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("Satın alım başarılı"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage("Depolama bilgisi alınamadı"),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("Aboneliğinizin süresi doldu"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Aboneliğiniz başarıyla güncellendi"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Doğrulama kodunuzun süresi doldu"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Temizlenebilecek yinelenen dosyalarınız yok"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Bu cihazda silinebilecek hiçbir dosyanız yok"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
            "Fotoğrafları görmek için uzaklaştırın")
      };
}
