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

  static String m0(count) =>
      "${Intl.plural(count, zero: 'Ortak çalışan ekle', one: 'Ortak çalışan ekle', other: 'Ortak çalışan ekle')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Öğeyi taşı', other: 'Öğeleri taşı')}";

  static String m3(storageAmount, endDate) =>
      "${storageAmount} eklentiniz ${endDate} tarihine kadar geçerlidir";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Görüntüleyen ekle', one: 'Görüntüleyen ekle', other: 'Görüntüleyen ekle')}";

  static String m4(emailOrName) => "${emailOrName} tarafından eklendi";

  static String m5(albumName) => "${albumName} albümüne başarıyla eklendi";

  static String m6(count) =>
      "${Intl.plural(count, zero: 'Katılımcı Yok', one: '1 Katılımcı', other: '${count} Katılımcı')}";

  static String m7(versionValue) => "Sürüm: ${versionValue}";

  static String m8(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} free";

  static String m9(paymentProvider) =>
      "Lütfen önce mevcut aboneliğinizi ${paymentProvider} adresinden iptal edin";

  static String m10(user) =>
      "${user}, bu albüme daha fazla fotoğraf ekleyemeyecek.\n\nAncak, kendi eklediği mevcut fotoğrafları kaldırmaya devam edebilecektir";

  static String m11(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Şu ana kadar aileniz ${storageAmountInGb} GB aldı',
            'false': 'Şu ana kadar ${storageAmountInGb} GB aldınız',
            'other': 'Şu ana kadar ${storageAmountInGb} GB aldınız!',
          })}";

  static String m12(albumName) =>
      "${albumName} için ortak çalışma bağlantısı oluşturuldu";

  static String m13(familyAdminEmail) =>
      "Aboneliğinizi yönetmek için lütfen <green>${familyAdminEmail}</green> ile iletişime geçin";

  static String m14(provider) =>
      "Lütfen ${provider} aboneliğinizi yönetmek için support@ente.io adresinden bizimle iletişime geçin.";

  static String m15(endpoint) => "${endpoint}\'e bağlanıldı";

  static String m16(count) =>
      "${Intl.plural(count, one: 'Delete ${count} item', other: 'Delete ${count} items')}";

  static String m17(currentlyDeleting, totalCount) =>
      "Siliniyor ${currentlyDeleting} / ${totalCount}";

  static String m18(albumName) =>
      "Bu, \"${albumName}\"e erişim için olan genel bağlantıyı kaldıracaktır.";

  static String m19(supportEmail) =>
      "Lütfen kayıtlı e-posta adresinizden ${supportEmail} adresine bir e-posta gönderin";

  static String m20(count, storageSaved) =>
      "You have cleaned up ${Intl.plural(count, one: '${count} duplicate file', other: '${count} duplicate files')}, saving (${storageSaved}!)";

  static String m21(count, formattedSize) =>
      "${count} dosyalar, ${formattedSize} her biri";

  static String m22(newEmail) => "E-posta ${newEmail} olarak değiştirildi";

  static String m23(email) =>
      "${email} does not have an Ente account.\n\nSend them an invite to share photos.";

  static String m24(count, formattedNumber) =>
      "Bu cihazdaki ${Intl.plural(count, one: '1 file', other: '${formattedNumber} dosya')} güvenli bir şekilde yedeklendi";

  static String m25(count, formattedNumber) =>
      "Bu albümdeki ${Intl.plural(count, one: '1 file', other: '${formattedNumber} dosya')} güvenli bir şekilde yedeklendi";

  static String m26(storageAmountInGB) =>
      "Birisinin davet kodunuzu uygulayıp ücretli hesap açtığı her seferede ${storageAmountInGB} GB";

  static String m27(endDate) => "Ücretsiz deneme ${endDate} sona erir";

  static String m28(count) =>
      "You can still access ${Intl.plural(count, one: 'it', other: 'them')} on Ente as long as you have an active subscription";

  static String m29(sizeInMBorGB) => "${sizeInMBorGB} yer açın";

  static String m30(count, formattedSize) =>
      "${Intl.plural(count, one: 'Yer açmak için cihazdan silinebilir ${formattedSize}', other: 'Yer açmak için cihazdan silinebilir ${formattedSize}')}";

  static String m31(currentlyProcessing, totalCount) =>
      "Siliniyor ${currentlyProcessing} / ${totalCount}";

  static String m32(count) =>
      "${Intl.plural(count, one: '${count} öğe', other: '${count} öğeler')}";

  static String m33(expiryTime) =>
      "Bu bağlantı ${expiryTime} dan sonra geçersiz olacaktır";

  static String m34(count, formattedCount) =>
      "${Intl.plural(count, zero: 'anı yok', one: '${formattedCount} anı', other: '${formattedCount} anılar')}";

  static String m35(count) =>
      "${Intl.plural(count, one: 'Öğeyi taşı', other: 'Öğeleri taşı')}";

  static String m36(albumName) => "${albumName} adlı albüme başarıyla taşındı";

  static String m37(name) => "Not ${name}?";

  static String m39(passwordStrengthValue) =>
      "Şifrenin güçlülük seviyesi: ${passwordStrengthValue}";

  static String m40(providerName) =>
      "Sizden ücret alındıysa lütfen ${providerName} destek ekibiyle görüşün";

  static String m41(endDate) =>
      "Free trial valid till ${endDate}.\nYou can choose a paid plan afterwards.";

  static String m42(toEmail) => "Lütfen bize ${toEmail} adresinden ulaşın";

  static String m43(toEmail) =>
      "Lütfen günlükleri şu adrese gönderin\n${toEmail}";

  static String m44(storeName) => "Bizi ${storeName} üzerinden değerlendirin";

  static String m45(storageInGB) => "3. Hepimiz ${storageInGB} GB* bedava alın";

  static String m46(userEmail) =>
      "${userEmail} bu paylaşılan albümden kaldırılacaktır\n\nOnlar tarafından eklenen tüm fotoğraflar da albümden kaldırılacaktır";

  static String m47(endDate) => "Abonelik ${endDate} tarihinde yenilenir";

  static String m48(count) =>
      "${Intl.plural(count, one: '${count} yıl önce', other: '${count} yıl önce')}";

  static String m49(count) => "${count} seçildi";

  static String m50(count, yourCount) =>
      "Seçilenler: ${count} (${yourCount} sizin seçiminiz)";

  static String m51(verificationID) =>
      "İşte ente.io için doğrulama kimliğim: ${verificationID}.";

  static String m52(verificationID) =>
      "Merhaba, bu ente.io doğrulama kimliğinizin doğruluğunu onaylayabilir misiniz: ${verificationID}";

  static String m53(referralCode, referralStorageInGB) =>
      "Ente referral code: ${referralCode} \n\nApply it in Settings → General → Referrals to get ${referralStorageInGB} GB free after you signup for a paid plan\n\nhttps://ente.io";

  static String m54(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Belirli kişilerle paylaş', one: '1 kişiyle paylaşıldı', other: '${numberOfPeople} kişiyle paylaşıldı')}";

  static String m55(emailIDs) => "${emailIDs} ile paylaşıldı";

  static String m56(fileType) => "Bu ${fileType}, cihazınızdan silinecek.";

  static String m57(fileType) =>
      "This ${fileType} is in both Ente and your device.";

  static String m58(fileType) => "This ${fileType} will be deleted from Ente.";

  static String m59(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m60(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} / ${totalAmount} ${totalStorageUnit} kullanıldı";

  static String m61(id) =>
      "Your ${id} is already linked to another Ente account.\nIf you would like to use your ${id} with this account, please contact our support\'\'";

  static String m62(endDate) =>
      "Aboneliğiniz ${endDate} tarihinde iptal edilecektir";

  static String m63(completed, total) => "${completed}/${total} anı korundu";

  static String m64(storageAmountInGB) =>
      "Aynı zamanda ${storageAmountInGB} GB alıyorlar";

  static String m65(email) => "Bu, ${email}\'in Doğrulama Kimliği";

  static String m66(count) =>
      "${Intl.plural(count, zero: 'gün', one: '1 gün', other: '${count} gün')}";

  static String m67(endDate) => "${endDate} tarihine kadar geçerli";

  static String m68(email) => "${email} doğrula";

  static String m69(email) =>
      "E-postayı <green>${email}</green> adresine gönderdik";

  static String m70(count) =>
      "${Intl.plural(count, one: '${count} yıl önce', other: '${count} yıl önce')}";

  static String m71(storageSaved) =>
      "Başarılı bir şekilde ${storageSaved} alanını boşalttınız!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "A new version of Ente is available."),
        "about": MessageLookupByLibrary.simpleMessage("Hakkında"),
        "account": MessageLookupByLibrary.simpleMessage("Hesap"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Tekrar hoş geldiniz!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Şifremi kaybedersem, verilerim <underline>uçtan uca şifrelendiği</underline> için verilerimi kaybedebileceğimi farkındayım."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktif oturumlar"),
        "addAName": MessageLookupByLibrary.simpleMessage("Add a name"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Yeni e-posta ekle"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Düzenleyici ekle"),
        "addCollaborators": m0,
        "addFromDevice": MessageLookupByLibrary.simpleMessage("Cihazdan ekle"),
        "addItem": m2,
        "addLocation": MessageLookupByLibrary.simpleMessage("Konum Ekle"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Ekle"),
        "addMore": MessageLookupByLibrary.simpleMessage("Daha fazla ekle"),
        "addNew": MessageLookupByLibrary.simpleMessage("Yeni ekle"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Eklentilerin ayrıntıları"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Eklentiler"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Fotoğraf ekle"),
        "addSelected": MessageLookupByLibrary.simpleMessage("Seçileni ekle"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Albüme ekle"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Add to Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Gizli albüme ekle"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Görüntüleyici ekle"),
        "addViewers": m1,
        "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
            "Fotoğraflarınızı şimdi ekleyin"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Eklendi"),
        "addedBy": m4,
        "addedSuccessfullyTo": m5,
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
        "albumParticipantsCount": m6,
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
        "appLock": MessageLookupByLibrary.simpleMessage("App lock"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Choose between your device\'s default lock screen and a custom lock screen with a PIN or password."),
        "appVersion": m7,
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
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to view your passkey"),
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
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "You\'ll see available Cast devices here."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Make sure Local Network permissions are turned on for the Ente Photos app, in Settings."),
        "autoLock": MessageLookupByLibrary.simpleMessage("Auto lock"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Time after which the app locks after being put in the background"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Due to technical glitch, you have been logged out. Our apologies for the inconvenience."),
        "autoPair": MessageLookupByLibrary.simpleMessage("Auto pair"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Auto pair works only with devices that support Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Mevcut"),
        "availableStorageSpace": m8,
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
        "cancelOtherSubscription": m9,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Abonelik iptali"),
        "cannotAddMorePhotosAfterBecomingViewer": m10,
        "cannotDeleteSharedFiles":
            MessageLookupByLibrary.simpleMessage("Dosyalar silinemiyor"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Please make sure you are on the same network as the TV."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("Failed to cast album"),
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
        "checkStatus": MessageLookupByLibrary.simpleMessage("Check status"),
        "checking": MessageLookupByLibrary.simpleMessage("Kontrol ediliyor..."),
        "cl_guest_view_call_to_action": MessageLookupByLibrary.simpleMessage(
            "Fotoğrafları seçin ve \"Misafir Görünümü\"nü deneyin."),
        "cl_guest_view_description": MessageLookupByLibrary.simpleMessage(
            "Telefonunuzu bir arkadaşınıza fotoğraf göstermek için mi veriyorsunuz? Fazla kaydırmasından endişelenmeyin. Misafir görünümü seçtiğiniz fotoğraflarla sınırlı kalır."),
        "cl_guest_view_title":
            MessageLookupByLibrary.simpleMessage("Misafir Görünümü"),
        "cl_panorama_viewer_description": MessageLookupByLibrary.simpleMessage(
            "360 derece görüşe sahip panorama fotoğrafları görüntüleme desteği ekledik. Hareket tabanlı gezinme ile etkileyici bir deneyim sunar!"),
        "cl_panorama_viewer_title":
            MessageLookupByLibrary.simpleMessage("Panorama Görüntüleyici"),
        "cl_video_player_description": MessageLookupByLibrary.simpleMessage(
            "Geliştirilmiş oynatma kontrolleri ve HDR video desteği ile yeni bir video oynatıcı sunuyoruz."),
        "cl_video_player_title":
            MessageLookupByLibrary.simpleMessage("Video Oynatıcı"),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Bedava alan talep edin"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Arttır!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Alındı"),
        "claimedStorageSoFar": m11,
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
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Clustering progress"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Kod kabul edildi"),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Kodunuz panoya kopyalandı"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Sizin kullandığınız kod"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Create a link to allow people to add and view photos in your shared album without needing an Ente app or account. Great for collecting event photos."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Organizasyon bağlantısı"),
        "collaborativeLinkCreatedFor": m12,
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
            "Evet, bu hesabı ve tüm verileri kalıcı olarak silmek istiyorum."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Şifrenizi onaylayın"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Plan değişikliğini onaylayın"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Kurtarma anahtarını doğrula"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Kurtarma anahtarını doğrulayın"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Connect to device"),
        "contactFamilyAdmin": m13,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Destek ile iletişim"),
        "contactToManageSubscription": m14,
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
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Create collaborative link"),
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
        "crop": MessageLookupByLibrary.simpleMessage("Crop"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Güncel kullanımınız "),
        "custom": MessageLookupByLibrary.simpleMessage("Kişisel"),
        "customEndpoint": m15,
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
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "This account is linked to other Ente apps, if you use any. Your uploaded data, across all Ente apps, will be scheduled for deletion, and your account will be permanently deleted."),
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
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Delete from Ente"),
        "deleteItemCount": m16,
        "deleteLocation": MessageLookupByLibrary.simpleMessage("Konumu sil"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Fotoğrafları sil"),
        "deleteProgress": m17,
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
        "descriptions": MessageLookupByLibrary.simpleMessage("Açıklama"),
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
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Files added to this device album will automatically get uploaded to Ente."),
        "deviceLock": MessageLookupByLibrary.simpleMessage("Device lock"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Disable the device screen lock when Ente is in the foreground and there is a backup in progress. This is normally not needed, but may help big uploads and initial imports of large libraries complete faster."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Cihaz bulunamadı"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Biliyor musun?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Otomatik kilidi devre dışı bırak"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Görüntüleyiciler, hala harici araçlar kullanarak ekran görüntüsü alabilir veya fotoğraflarınızın bir kopyasını kaydedebilir. Lütfen bunu göz önünde bulundurunuz"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Lütfen dikkate alın"),
        "disableLinkMessage": m18,
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
        "dropSupportEmail": m19,
        "duplicateFileCountWithStorageSaved": m20,
        "duplicateItemsGroup": m21,
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
        "emailChangedTo": m22,
        "emailNoEnteAccount": m23,
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
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente can encrypt and preserve files only if you grant access to them"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>needs permission to</i> preserve your photos"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente preserves your memories, so they\'re always available to you, even if you lose your device."),
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
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Enter person name"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Enter PIN"),
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
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Face recognition"),
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
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Add 5 family members to your existing plan without paying extra.\n\nEach member gets their own private space, and cannot see each other\'s files unless they\'re shared.\n\nFamily plans are available to customers who have a paid Ente subscription.\n\nSubscribe now to get started!"),
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
        "filesBackedUpFromDevice": m24,
        "filesBackedUpInAlbum": m25,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Dosyalar silinmiş"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Files saved to gallery"),
        "findPeopleByName":
            MessageLookupByLibrary.simpleMessage("Find people quickly by name"),
        "flip": MessageLookupByLibrary.simpleMessage("Çevir"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("anıların için"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Şifremi unuttum"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Found faces"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Alınan bedava alan"),
        "freeStorageOnReferralSuccess": m26,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Kullanılabilir bedava alan"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Ücretsiz deneme"),
        "freeTrialValidTill": m27,
        "freeUpAccessPostDelete": m28,
        "freeUpAmount": m29,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Cihaz alanını boşaltın"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Save space on your device by clearing files that have been already backed up."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Boş alan"),
        "freeUpSpaceSaving": m30,
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Galeride 1000\'e kadar anı gösterilir"),
        "general": MessageLookupByLibrary.simpleMessage("Genel"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Şifreleme anahtarı oluşturuluyor..."),
        "genericProgress": m31,
        "goToSettings": MessageLookupByLibrary.simpleMessage("Ayarlara git"),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("Google play kimliği"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Lütfen Ayarlar uygulamasında tüm fotoğraflara erişime izin verin"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("İzinleri değiştir"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
            "Yakındaki fotoğrafları gruplandır"),
        "guestView": MessageLookupByLibrary.simpleMessage("Guest view"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "To enable guest view, please setup device passcode or screen lock in your system settings."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Biz uygulama kurulumlarını takip etmiyoruz. Bizi nereden duyduğunuzdan bahsetmeniz bize çok yardımcı olacak!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Ente\'yi nereden duydunuz? (opsiyonel)"),
        "help": MessageLookupByLibrary.simpleMessage("Yardım"),
        "hidden": MessageLookupByLibrary.simpleMessage("Gizle"),
        "hide": MessageLookupByLibrary.simpleMessage("Gizle"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Hide content"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Hides app content in the app switcher and disables screenshots"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Hides app content in the app switcher"),
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
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Some files in this album are ignored from upload because they had previously been deleted from Ente."),
        "immediately": MessageLookupByLibrary.simpleMessage("Immediately"),
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
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "Indexing is paused. It will automatically resume when device is ready."),
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
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Invite to Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Arkadaşlarını davet et"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Invite your friends to Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Bir şeyler ters gitmiş gibi görünüyor. Lütfen bir süre sonra tekrar deneyin. Hata devam ederse, lütfen destek ekibimizle iletişime geçin."),
        "itemCount": m32,
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
        "left": MessageLookupByLibrary.simpleMessage("Left"),
        "light": MessageLookupByLibrary.simpleMessage("Aydınlık"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Aydınlık"),
        "linkCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Link panoya kopyalandı"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Cihaz limiti"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Geçerli"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Süresi dolmuş"),
        "linkExpiresOn": m33,
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
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expired"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Your session has expired. Please login again."),
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
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Cihaz depolamasını yönet"),
        "manageFamily": MessageLookupByLibrary.simpleMessage("Aileyi yönet"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Linki yönet"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Yönet"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Abonelikleri yönet"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Pair with PIN works with any screen you wish to view your album on."),
        "map": MessageLookupByLibrary.simpleMessage("Harita"),
        "maps": MessageLookupByLibrary.simpleMessage("Haritalar"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m34,
        "merchandise": MessageLookupByLibrary.simpleMessage("Ürünler"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Please note that machine learning will result in a higher bandwidth and battery usage until all items are indexed."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobil, Web, Masaüstü"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Ilımlı"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Sorgunuzu değiştirin veya aramayı deneyin"),
        "moments": MessageLookupByLibrary.simpleMessage("Anlar"),
        "monthly": MessageLookupByLibrary.simpleMessage("Aylık"),
        "moveItem": m35,
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Albüme taşı"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Gizli albüme ekle"),
        "movedSuccessfullyTo": m36,
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
        "newToEnte": MessageLookupByLibrary.simpleMessage("New to Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("En yeni"),
        "next": MessageLookupByLibrary.simpleMessage("Next"),
        "no": MessageLookupByLibrary.simpleMessage("Hayır"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Henüz paylaştığınız albüm yok"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("No device found"),
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
        "noQuickLinksSelected":
            MessageLookupByLibrary.simpleMessage("No quick links selected"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Kurtarma kodunuz yok mu?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Uçtan uca şifreleme protokolümüzün doğası gereği, verileriniz şifreniz veya kurtarma anahtarınız olmadan çözülemez"),
        "noResults": MessageLookupByLibrary.simpleMessage("Sonuç bulunamadı"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Hiçbir sonuç bulunamadı"),
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("No system lock found"),
        "notPersonLabel": m37,
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
        "pairWithPin": MessageLookupByLibrary.simpleMessage("Pair with PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Pairing complete"),
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "Verification is still pending"),
        "passkey": MessageLookupByLibrary.simpleMessage("Parola Anahtarı"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Geçiş anahtarı doğrulaması"),
        "password": MessageLookupByLibrary.simpleMessage("Şifre"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Şifreniz başarılı bir şekilde değiştirildi"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Sifre kilidi"),
        "passwordStrength": m39,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "Password strength is calculated considering the length of the password, used characters, and whether or not the password appears in the top 10,000 most used passwords"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Şifrelerinizi saklamıyoruz, bu yüzden unutursanız, <underline>verilerinizi deşifre edemeyiz</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Ödeme detayları"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Ödeme başarısız oldu"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Maalesef ödemeniz başarısız oldu. Lütfen destekle iletişime geçin, size yardımcı olacağız!"),
        "paymentFailedTalkToProvider": m40,
        "pendingItems": MessageLookupByLibrary.simpleMessage("Bekleyen Öğeler"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Senkronizasyon bekleniyor"),
        "people": MessageLookupByLibrary.simpleMessage("People"),
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
        "pinLock": MessageLookupByLibrary.simpleMessage("PIN lock"),
        "playOnTv": MessageLookupByLibrary.simpleMessage("Albümü TV\'de oynat"),
        "playStoreFreeTrialValidTill": m41,
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
        "pleaseEmailUsAt": m42,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Lütfen izin ver"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Lütfen tekrar giriş yapın"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Please select quick links to remove"),
        "pleaseSendTheLogsTo": m43,
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
        "rateUsOnStore": m44,
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
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Eğer şifrenizi unutursanız, fotoğraflarınızı kurtarmanın tek yolu kurtarma anahtarınızdır. Kurtarma anahtarınızı Ayarlar > Güvenlik bölümünde bulabilirsiniz.\n\nLütfen kurtarma anahtarınızı buraya girerek doğru bir şekilde kaydettiğinizi doğrulayın."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Kurtarma başarılı!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Cihazınız, şifrenizi doğrulamak için yeterli güce sahip değil, ancak tüm cihazlarda çalışacak şekilde yeniden oluşturabiliriz.\n\nLütfen kurtarma anahtarınızı kullanarak giriş yapın ve şifrenizi yeniden oluşturun (istediğiniz takdirde aynı şifreyi tekrar kullanabilirsiniz)."),
        "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
            "Sifrenizi tekrardan oluşturun"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Re-enter password"),
        "reenterPin": MessageLookupByLibrary.simpleMessage("Re-enter PIN"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Arkadaşlarınıza önerin ve planınızı 2 katına çıkarın"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Bu kodu arkadaşlarınıza verin"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Ücretli bir plan için kaydolsunlar"),
        "referralStep3": m45,
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
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Review and remove files that are exact duplicates."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Albümden çıkar"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Albümden çıkarılsın mı?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Favorilerimden kaldır"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Linki kaldır"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Katılımcıyı kaldır"),
        "removeParticipantBody": m46,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Remove person label"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Herkese açık link oluştur"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Remove public links"),
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
        "renewsOn": m47,
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
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Review suggestions"),
        "right": MessageLookupByLibrary.simpleMessage("Right"),
        "rotate": MessageLookupByLibrary.simpleMessage("Rotate"),
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
        "savingEdits": MessageLookupByLibrary.simpleMessage("Saving edits..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Kodu tarayın"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kimlik doğrulama uygulamanız ile kodu tarayın"),
        "search": MessageLookupByLibrary.simpleMessage("Search"),
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
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "People will be shown here once indexing is done"),
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
        "searchResultCount": m48,
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
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Selected files are not on Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Seçilen klasörler şifrelenecek ve yedeklenecektir"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Seçilen öğeler tüm albümlerden silinecek ve çöp kutusuna taşınacak."),
        "selectedPhotos": m49,
        "selectedPhotosWithYours": m50,
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
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Set new password"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("Set new PIN"),
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
        "shareMyVerificationID": m51,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Yalnızca istediğiniz kişilerle paylaşın"),
        "shareTextConfirmOthersVerificationID": m52,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Download Ente so we can easily share original quality photos and videos\n\nhttps://ente.io"),
        "shareTextReferralCode": m53,
        "shareWithNonenteUsers":
            MessageLookupByLibrary.simpleMessage("Share with non-Ente users"),
        "shareWithPeopleSectionTitle": m54,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("İlk albümünüzü paylaşın"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Create shared and collaborative albums with other Ente users, including users on free plans."),
        "sharedByMe":
            MessageLookupByLibrary.simpleMessage("Benim paylaştıklarım"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Paylaştıklarınız"),
        "sharedPhotoNotifications": MessageLookupByLibrary.simpleMessage(
            "Paylaşılan fotoğrafları ekle"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Birisi sizin de parçası olduğunuz paylaşılan bir albüme fotoğraf eklediğinde bildirim alın"),
        "sharedWith": m55,
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
        "singleFileDeleteFromDevice": m56,
        "singleFileDeleteHighlight":
            MessageLookupByLibrary.simpleMessage("Tüm albümlerden silinecek."),
        "singleFileInBothLocalAndRemote": m57,
        "singleFileInRemoteOnly": m58,
        "skip": MessageLookupByLibrary.simpleMessage("Geç"),
        "social": MessageLookupByLibrary.simpleMessage("Sosyal Medya"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Some items are in both Ente and your device."),
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
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Do you want to stop casting?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Stop casting"),
        "storage": MessageLookupByLibrary.simpleMessage("Depolama"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Aile"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Sen"),
        "storageInGB": m59,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Depolama sınırı aşıldı"),
        "storageUsageInfo": m60,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Güçlü"),
        "subAlreadyLinkedErrMessage": m61,
        "subWillBeCancelledOn": m62,
        "subscribe": MessageLookupByLibrary.simpleMessage("Abone ol"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Aboneliğinizin süresi dolmuş gibi görünüyor. Paylaşımı etkinleştirmek için lütfen abone olun."),
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
        "syncProgress": m63,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Senkronizasyon durduruldu"),
        "syncing": MessageLookupByLibrary.simpleMessage("Eşitleniyor..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistem"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("kopyalamak için dokunun"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Kodu girmek icin tıklayın"),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage("Tap to unlock"),
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
        "theyAlsoGetXGb": m64,
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
        "thisIsPersonVerificationId": m65,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("Doğrulama kimliğiniz"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Bu, sizi aşağıdaki cihazdan çıkış yapacak:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Bu cihazdaki oturumunuz kapatılacak!"),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "This will remove public links of all selected quick links."),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "To enable app lock, please setup device passcode or screen lock in your system settings."),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Bir fotoğrafı veya videoyu gizlemek için"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Şifrenizi sıfılamak için lütfen e-postanızı girin."),
        "todaysLogs":
            MessageLookupByLibrary.simpleMessage("Bugünün günlükleri"),
        "tooManyIncorrectAttempts":
            MessageLookupByLibrary.simpleMessage("Too many incorrect attempts"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Toplam boyut"),
        "trash": MessageLookupByLibrary.simpleMessage("Cöp kutusu"),
        "trashDaysLeft": m66,
        "trim": MessageLookupByLibrary.simpleMessage("Trim"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Tekrar deneyiniz"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Turn on backup to automatically upload files added to this device folder to Ente."),
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
        "useAsCover": MessageLookupByLibrary.simpleMessage("Use as cover"),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Use public links for people not on Ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Kurtarma anahtarını kullan"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Seçilen fotoğrafı kullan"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Kullanılan alan"),
        "validTill": m67,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Doğrulama başarısız oldu, lütfen tekrar deneyin"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Doğrulama kimliği"),
        "verify": MessageLookupByLibrary.simpleMessage("Doğrula"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("E-posta adresini doğrulayın"),
        "verifyEmailID": m68,
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
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Large files"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "View files that are consuming the most amount of storage"),
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
        "weHaveSendEmailTo": m69,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Zayıf"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Tekrardan hoşgeldin!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("What\'s new"),
        "yearly": MessageLookupByLibrary.simpleMessage("Yıllık"),
        "yearsAgo": m70,
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
        "youHaveSuccessfullyFreedUp": m71,
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
