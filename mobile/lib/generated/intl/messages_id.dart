// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a id locale. All the
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
  String get localeName => 'id';

  static String m9(count) =>
      "${Intl.plural(count, other: 'Tambahkan kolaborator')}";

  static String m10(count) => "${Intl.plural(count, other: 'Tambahkan item')}";

  static String m11(storageAmount, endDate) =>
      "Add-on ${storageAmount} kamu berlaku sampai ${endDate}";

  static String m13(emailOrName) => "Ditambahkan oleh ${emailOrName}";

  static String m14(albumName) => "Berhasil ditambahkan ke ${albumName}";

  static String m15(count) =>
      "${Intl.plural(count, zero: '0 Peserta', one: '1 Peserta', other: '${count} Peserta')}";

  static String m16(versionValue) => "Versi: ${versionValue}";

  static String m17(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} tersedia";

  static String m18(paymentProvider) =>
      "Harap batalkan langganan kamu di ${paymentProvider} terlebih dahulu";

  static String m3(user) =>
      "${user} tidak akan dapat menambahkan foto lagi ke album ini\n\nIa masih dapat menghapus foto yang ditambahkan olehnya sendiri";

  static String m19(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Keluargamu saat ini telah memperoleh ${storageAmountInGb} GB',
            'false': 'Kamu saat ini telah memperoleh ${storageAmountInGb} GB',
            'other': 'Kamu saat ini telah memperoleh ${storageAmountInGb} GB!',
          })}";

  static String m20(albumName) => "Link kolaborasi terbuat untuk ${albumName}";

  static String m23(familyAdminEmail) =>
      "Silakan hubungi <green>${familyAdminEmail}</green> untuk mengatur langgananmu";

  static String m24(provider) =>
      "Silakan hubungi kami di support@ente.io untuk mengatur langganan ${provider} kamu.";

  static String m25(endpoint) => "Terhubung ke ${endpoint}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'Hapus ${count} item', other: 'Hapus ${count} item')}";

  static String m27(currentlyDeleting, totalCount) =>
      "Menghapus ${currentlyDeleting} / ${totalCount}";

  static String m28(albumName) =>
      "Ini akan menghapus link publik yang digunakan untuk mengakses \"${albumName}\".";

  static String m29(supportEmail) =>
      "Silakan kirimkan email ke ${supportEmail} dari alamat email terdaftar kamu";

  static String m30(count, storageSaved) =>
      "Kamu telah menghapus ${Intl.plural(count, other: '${count} file duplikat')} dan membersihkan (${storageSaved}!)";

  static String m32(newEmail) => "Email diubah menjadi ${newEmail}";

  static String m33(email) =>
      "${email} tidak punya akun Ente.\n\nUndang dia untuk berbagi foto.";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, other: '${formattedNumber} file')} di perangkat ini telah berhasil dicadangkan";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, other: '${formattedNumber} file')} dalam album ini telah berhasil dicadangkan";

  static String m4(storageAmountInGB) =>
      "${storageAmountInGB} GB setiap kali orang mendaftar dengan paket berbayar lalu menerapkan kode milikmu";

  static String m37(endDate) => "Percobaan gratis berlaku hingga ${endDate}";

  static String m38(count) =>
      "Kamu masih bisa mengakses ${Intl.plural(count, other: 'filenya')} di Ente selama kamu masih berlangganan";

  static String m39(sizeInMBorGB) => "Bersihkan ${sizeInMBorGB}";

  static String m40(count, formattedSize) =>
      "${Intl.plural(count, other: 'File tersebut bisa dihapus dari perangkat ini untuk membersihkan ${formattedSize}')}";

  static String m41(currentlyProcessing, totalCount) =>
      "Memproses ${currentlyProcessing} / ${totalCount}";

  static String m42(count) => "${Intl.plural(count, other: '${count} item')}";

  static String m44(expiryTime) => "Link akan kedaluwarsa pada ${expiryTime}";

  static String m5(count, formattedCount) =>
      "${Intl.plural(count, zero: 'tiada kenangan', one: '${formattedCount} kenangan', other: '${formattedCount} kenangan')}";

  static String m45(count) => "${Intl.plural(count, other: 'Pindahkan item')}";

  static String m46(albumName) => "Berhasil dipindahkan ke ${albumName}";

  static String m49(familyAdminEmail) =>
      "Harap hubungi ${familyAdminEmail} untuk mengubah kode kamu.";

  static String m0(passwordStrengthValue) =>
      "Keamanan sandi: ${passwordStrengthValue}";

  static String m50(providerName) =>
      "Harap hubungi dukungan ${providerName} jika kamu dikenai biaya";

  static String m52(endDate) =>
      "Percobaan gratis berlaku hingga ${endDate}.\nKamu dapat memilih paket berbayar setelahnya.";

  static String m53(toEmail) => "Silakan kirimi kami email di ${toEmail}";

  static String m54(toEmail) => "Silakan kirim log-nya ke \n${toEmail}";

  static String m56(storeName) => "Beri nilai di ${storeName}";

  static String m60(storageInGB) =>
      "3. Kalian berdua mendapat ${storageInGB} GB* gratis";

  static String m61(userEmail) =>
      "${userEmail} akan dikeluarkan dari album berbagi ini\n\nSemua foto yang ia tambahkan juga akan dihapus dari album ini";

  static String m62(endDate) => "Langganan akan diperpanjang pada ${endDate}";

  static String m63(count) =>
      "${Intl.plural(count, other: '${count} hasil ditemukan')}";

  static String m6(count) => "${count} terpilih";

  static String m65(count, yourCount) =>
      "${count} dipilih (${yourCount} milikmu)";

  static String m66(verificationID) =>
      "Ini ID Verifikasi saya di ente.io: ${verificationID}.";

  static String m7(verificationID) =>
      "Halo, bisakah kamu pastikan bahwa ini adalah ID Verifikasi ente.io milikmu: ${verificationID}";

  static String m67(referralCode, referralStorageInGB) =>
      "Kode rujukan Ente: ${referralCode} \n\nTerapkan pada Pengaturan → Umum → Rujukan untuk mendapatkan ${referralStorageInGB} GB gratis setelah kamu mendaftar paket berbayar\n\nhttps://ente.io";

  static String m68(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Bagikan dengan orang tertentu', one: 'Berbagi dengan 1 orang', other: 'Berbagi dengan ${numberOfPeople} orang')}";

  static String m69(emailIDs) => "Dibagikan dengan ${emailIDs}";

  static String m70(fileType) =>
      "${fileType} ini akan dihapus dari perangkat ini.";

  static String m71(fileType) =>
      "${fileType} ini tersimpan di Ente dan juga di perangkat ini.";

  static String m72(fileType) => "${fileType} ini akan dihapus dari Ente.";

  static String m1(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m73(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} dari ${totalAmount} ${totalStorageUnit} terpakai";

  static String m74(id) =>
      "${id} kamu telah terhubung dengan akun Ente lain.\nJika kamu ingin menggunakan ${id} kamu untuk akun ini, silahkan hubungi tim bantuan kami";

  static String m75(endDate) =>
      "Langganan kamu akan dibatalkan pada ${endDate}";

  static String m8(storageAmountInGB) =>
      "Ia juga mendapat ${storageAmountInGB} GB";

  static String m78(email) => "Ini adalah ID Verifikasi milik ${email}";

  static String m84(endDate) => "Berlaku hingga ${endDate}";

  static String m85(email) => "Verifikasi ${email}";

  static String m2(email) =>
      "Kami telah mengirimkan email ke <green>${email}</green>";

  static String m87(count) =>
      "${Intl.plural(count, other: '${count} tahun lalu')}";

  static String m88(storageSaved) =>
      "Kamu telah berhasil membersihkan ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Versi baru dari Ente telah tersedia."),
        "about": MessageLookupByLibrary.simpleMessage("Tentang"),
        "account": MessageLookupByLibrary.simpleMessage("Akun"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Selamat datang kembali!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Saya mengerti bahwa jika saya lupa sandi saya, data saya bisa hilang karena <underline>dienkripsi dari ujung ke ujung</underline>."),
        "activeSessions": MessageLookupByLibrary.simpleMessage("Sesi aktif"),
        "addAName": MessageLookupByLibrary.simpleMessage("Tambahkan nama"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Tambah email baru"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Tambah kolaborator"),
        "addCollaborators": m9,
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Tambahkan dari perangkat"),
        "addItem": m10,
        "addLocation": MessageLookupByLibrary.simpleMessage("Tambah tempat"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Tambah"),
        "addMore": MessageLookupByLibrary.simpleMessage("Tambah lagi"),
        "addOnValidTill": m11,
        "addPhotos": MessageLookupByLibrary.simpleMessage("Tambah foto"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Tambahkan yang dipilih"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Tambah ke album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Tambah ke Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Tambah ke album tersembunyi"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Tambahkan pemirsa"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Ditambahkan sebagai"),
        "addedBy": m13,
        "addedSuccessfullyTo": m14,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Menambahkan ke favorit..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Lanjutan"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Lanjutan"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Setelah 1 hari"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Setelah 1 jam"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Setelah 1 bulan"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Setelah 1 minggu"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Setelah 1 tahun"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Pemilik"),
        "albumParticipantsCount": m15,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Judul album"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album diperbarui"),
        "albums": MessageLookupByLibrary.simpleMessage("Album"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Sudah bersih"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("Semua kenangan terpelihara"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Izinkan orang yang memiliki link untuk menambahkan foto ke album berbagi ini."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Izinkan menambah foto"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Izinkan pengunduhan"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Izinkan orang lain menambahkan foto"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Verifikasi identitas"),
        "androidBiometricNotRecognized":
            MessageLookupByLibrary.simpleMessage("Tidak dikenal. Coba lagi."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Biometrik diperlukan"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Berhasil"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Batal"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Autentikasi biometrik belum aktif di perangkatmu. Buka \'Setelan > Keamanan\' untuk mengaktifkan autentikasi biometrik."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Desktop"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Autentikasi diperlukan"),
        "appVersion": m16,
        "appleId": MessageLookupByLibrary.simpleMessage("ID Apple"),
        "apply": MessageLookupByLibrary.simpleMessage("Terapkan"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Terapkan kode"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Langganan AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("Arsip"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Arsipkan album"),
        "archiving": MessageLookupByLibrary.simpleMessage("Mengarsipkan..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Apakah kamu yakin ingin meninggalkan paket keluarga ini?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Apakah kamu yakin ingin membatalkan?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Apakah kamu yakin ingin mengubah paket kamu?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Apakah kamu yakin ingin keluar?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Apakah kamu yakin ingin keluar akun?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Apakah kamu yakin ingin memperpanjang?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Langganan kamu telah dibatalkan. Apakah kamu ingin membagikan alasannya?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Apa alasan utama kamu dalam menghapus akun?"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("di tempat pengungsian"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Harap autentikasi untuk mengatur verifikasi email"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Lakukan autentikasi untuk mengubah pengaturan kunci layar"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Harap autentikasi untuk mengubah email kamu"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Harap autentikasi untuk mengubah sandi kamu"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Harap autentikasi untuk mengatur autentikasi dua langkah"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Harap autentikasi untuk mulai penghapusan akun"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Harap autentikasi untuk melihat sesi aktif kamu"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Harap autentikasi untuk melihat file tersembunyi kamu"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Harap autentikasi untuk melihat kenanganmu"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Harap autentikasi untuk melihat kunci pemulihan kamu"),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Autentikasi gagal, silakan coba lagi"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("Autentikasi berhasil!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Perangkat Cast yang tersedia akan ditampilkan di sini."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Pastikan izin Jaringan Lokal untuk app Ente Foto aktif di Pengaturan."),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Akibat kesalahan teknis, kamu telah keluar dari akunmu. Kami mohon maaf atas ketidaknyamanannya."),
        "autoPair": MessageLookupByLibrary.simpleMessage("Taut otomatis"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Taut otomatis hanya tersedia di perangkat yang mendukung Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Tersedia"),
        "availableStorageSpace": m17,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Folder yang dicadangkan"),
        "backup": MessageLookupByLibrary.simpleMessage("Pencadangan"),
        "backupFailed":
            MessageLookupByLibrary.simpleMessage("Pencadangan gagal"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Cadangkan dengan data seluler"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Pengaturan pencadangan"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("Status pencadangan"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Item yang sudah dicadangkan akan terlihat di sini"),
        "backupVideos": MessageLookupByLibrary.simpleMessage("Cadangkan video"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Penawaran Black Friday"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Data cache"),
        "calculating": MessageLookupByLibrary.simpleMessage("Menghitung..."),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Hanya dapat menghapus berkas yang dimiliki oleh mu"),
        "cancel": MessageLookupByLibrary.simpleMessage("Batal"),
        "cancelOtherSubscription": m18,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Batalkan langganan"),
        "cannotAddMorePhotosAfterBecomingViewer": m3,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat menghapus file berbagi"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Harap pastikan kamu berada pada jaringan yang sama dengan TV-nya."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("Gagal mentransmisikan album"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Buka cast.ente.io pada perangkat yang ingin kamu tautkan.\n\nMasukkan kode yang ditampilkan untuk memutar album di TV."),
        "change": MessageLookupByLibrary.simpleMessage("Ubah"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Ubah email"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Ubah lokasi pada item terpilih?"),
        "changePassword": MessageLookupByLibrary.simpleMessage("Ubah sandi"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Ubah sandi"),
        "changePermissions": MessageLookupByLibrary.simpleMessage("Ubah izin?"),
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("Ganti kode rujukan kamu"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Periksa pembaruan"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Silakan periksa kotak masuk (serta kotak spam) untuk menyelesaikan verifikasi"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Periksa status"),
        "checking": MessageLookupByLibrary.simpleMessage("Memeriksa..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Peroleh kuota gratis"),
        "claimMore":
            MessageLookupByLibrary.simpleMessage("Peroleh lebih banyak!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Diperoleh"),
        "claimedStorageSoFar": m19,
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Hapus indeks"),
        "click": MessageLookupByLibrary.simpleMessage("• Click"),
        "close": MessageLookupByLibrary.simpleMessage("Tutup"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Kode diterapkan"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Maaf, kamu telah mencapai batas perubahan kode."),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Kode tersalin ke papan klip"),
        "codeUsedByYou": MessageLookupByLibrary.simpleMessage(
            "Kode yang telah kamu gunakan"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Buat link untuk memungkinkan orang lain menambahkan dan melihat foto yang ada pada album bersama kamu tanpa memerlukan app atau akun Ente. Ideal untuk mengumpulkan foto pada suatu acara."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Link kolaborasi"),
        "collaborativeLinkCreatedFor": m20,
        "collaborator": MessageLookupByLibrary.simpleMessage("Kolaborator"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Kolaborator bisa menambahkan foto dan video ke album bersama ini."),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Kumpulkan foto acara"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Kumpulkan foto"),
        "color": MessageLookupByLibrary.simpleMessage("Warna"),
        "confirm": MessageLookupByLibrary.simpleMessage("Konfirmasi"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Apakah kamu yakin ingin menonaktifkan autentikasi dua langkah?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Konfirmasi Penghapusan Akun"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Ya, saya ingin menghapus akun ini dan seluruh datanya secara permanen di semua aplikasi."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Konfirmasi sandi"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("Konfirmasi perubahan paket"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Konfirmasi kunci pemulihan"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Konfirmasi kunci pemulihan kamu"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Hubungkan ke perangkat"),
        "contactFamilyAdmin": m23,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Hubungi dukungan"),
        "contactToManageSubscription": m24,
        "contacts": MessageLookupByLibrary.simpleMessage("Kontak"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Lanjut"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Lanjut dengan percobaan gratis"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Ubah menjadi album"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Salin alamat email"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Salin link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Salin lalu tempel kode ini\ndi app autentikator kamu"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Kami tidak dapat mencadangkan data kamu.\nKami akan coba lagi nanti."),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat membersihkan ruang"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat memperbarui langganan"),
        "count": MessageLookupByLibrary.simpleMessage("Jumlah"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Pelaporan crash"),
        "create": MessageLookupByLibrary.simpleMessage("Buat"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Buat akun"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Tekan dan tahan foto lalu klik + untuk membuat album baru"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Buat link kolaborasi"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Buat akun baru"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Buat atau pilih album"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Buat link publik"),
        "creatingLink": MessageLookupByLibrary.simpleMessage("Membuat link..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("Pembaruan penting tersedia"),
        "crop": MessageLookupByLibrary.simpleMessage("Potong"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Pemakaian saat ini sebesar "),
        "custom": MessageLookupByLibrary.simpleMessage("Kustom"),
        "customEndpoint": m25,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Gelap"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Hari Ini"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Kemarin"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Mendekripsi..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Mendekripsi video..."),
        "delete": MessageLookupByLibrary.simpleMessage("Hapus"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Hapus akun"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Kami sedih kamu pergi. Silakan bagikan masukanmu agar kami bisa jadi lebih baik."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Hapus Akun Secara Permanen"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Hapus album"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Hapus foto (dan video) yang ada dalam album ini dari <bold>semua</bold> album lain yang juga menampungnya?"),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Hapus Semua"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Silakan kirim email ke <warning>account-deletion@ente.io</warning> dari alamat email kamu yang terdaftar."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Hapus album kosong"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Hapus album yang kosong?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Hapus dari keduanya"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Hapus dari perangkat ini"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Hapus dari Ente"),
        "deleteItemCount": m26,
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Hapus foto"),
        "deleteProgress": m27,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Fitur penting yang saya perlukan tidak ada"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "App ini atau fitur tertentu tidak bekerja sesuai harapan saya"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Saya menemukan layanan lain yang lebih baik"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
            "Alasan saya tidak ada di daftar"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Permintaan kamu akan diproses dalam waktu 72 jam."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Hapus album bersama?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Album ini akan di hapus untuk semua\n\nKamu akan kehilangan akses ke foto yang di bagikan dalam album ini yang di miliki oleh pengguna lain"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Dibuat untuk melestarikan"),
        "details": MessageLookupByLibrary.simpleMessage("Rincian"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Pengaturan pengembang"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Apakah kamu yakin ingin mengubah pengaturan pengembang?"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Masukkan kode"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "File yang ditambahkan ke album perangkat ini akan diunggah ke Ente secara otomatis."),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Nonaktfikan kunci layar perangkat saat Ente berada di latar depan dan ada pencadangan yang sedang berlangsung. Hal ini biasanya tidak diperlukan, namun dapat membantu unggahan dan import awal berkas berkas besar selesai lebih cepat."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Perangkat tidak ditemukan"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Tahukah kamu?"),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("Nonaktifkan kunci otomatis"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Orang yang melihat masih bisa mengambil tangkapan layar atau menyalin foto kamu menggunakan alat eksternal"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Perlu diketahui"),
        "disableLinkMessage": m28,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Nonaktifkan autentikasi dua langkah"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Menonaktifkan autentikasi dua langkah..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Bayi"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Makanan"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Bukit"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identitas"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Meme"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Catatan"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Hewan"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Tangkapan layar"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Swafoto"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Senja"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Gambar latar"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut":
            MessageLookupByLibrary.simpleMessage("Jangan keluarkan akun"),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Lakukan lain kali"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Apakah kamu ingin membuang edit yang telah kamu buat?"),
        "done": MessageLookupByLibrary.simpleMessage("Selesai"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Gandakan kuota kamu"),
        "download": MessageLookupByLibrary.simpleMessage("Unduh"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Gagal mengunduh"),
        "downloading": MessageLookupByLibrary.simpleMessage("Mengunduh..."),
        "dropSupportEmail": m29,
        "duplicateFileCountWithStorageSaved": m30,
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "editLocation": MessageLookupByLibrary.simpleMessage("Edit lokasi"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Edit lokasi"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Perubahan tersimpan"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Perubahan lokasi hanya akan terlihat di Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("memenuhi syarat"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "emailChangedTo": m32,
        "emailNoEnteAccount": m33,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("Verifikasi email"),
        "empty": MessageLookupByLibrary.simpleMessage("Kosongkan"),
        "emptyTrash": MessageLookupByLibrary.simpleMessage("Kosongkan sampah?"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Aktifkan Peta"),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Mengenkripsi cadangan..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Enkripsi"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Kunci enkripsi"),
        "endpointUpdatedMessage":
            MessageLookupByLibrary.simpleMessage("Endpoint berhasil diubah"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Dirancang dengan enkripsi ujung ke ujung"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente hanya dapat mengenkripsi dan menyimpan file jika kamu berikan izin"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>memerlukan izin untuk</i> menyimpan fotomu"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente memelihara kenanganmu, sehingga ia selalu tersedia untukmu, bahkan jika kamu kehilangan perangkatmu."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Anggota keluargamu juga bisa ditambahkan ke paketmu."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Masukkan nama album"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Masukkan kode"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Masukkan kode yang diberikan temanmu untuk memperoleh kuota gratis untuk kalian berdua"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Masukkan email"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Masukkan nama file"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Masukkan sandi baru yang bisa kami gunakan untuk mengenkripsi data kamu"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Masukkan sandi"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Masukkan sandi yang bisa kami gunakan untuk mengenkripsi data kamu"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Masukkan nama orang"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Masukkan kode rujukan"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Masukkan kode 6 angka dari\napp autentikator kamu"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Harap masukkan alamat email yang sah."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Masukkan alamat email kamu"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Masukkan sandi kamu"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Masukkan kunci pemulihan kamu"),
        "error": MessageLookupByLibrary.simpleMessage("Kesalahan"),
        "everywhere": MessageLookupByLibrary.simpleMessage("di mana saja"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser": MessageLookupByLibrary.simpleMessage("Masuk"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Link ini telah kedaluwarsa. Silakan pilih waktu kedaluwarsa baru atau nonaktifkan waktu kedaluwarsa."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Ekspor log"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Ekspor data kamu"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Pengenalan wajah"),
        "faces": MessageLookupByLibrary.simpleMessage("Wajah"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Gagal menerapkan kode"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Gagal membatalkan"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Gagal mengunduh video"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Gagal memuat file asli untuk mengedit"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat mengambil kode rujukan. Harap ulang lagi nanti."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Gagal memuat album"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Gagal memperpanjang"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Gagal memeriksa status pembayaran"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Tambahkan 5 anggota keluarga ke paket kamu tanpa perlu bayar lebih.\n\nSetiap anggota mendapat ruang pribadi mereka sendiri, dan tidak dapat melihat file orang lain kecuali dibagikan.\n\nPaket keluarga tersedia bagi pelanggan yang memiliki langganan berbayar Ente.\n\nLangganan sekarang untuk mulai!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Keluarga"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Paket keluarga"),
        "faq": MessageLookupByLibrary.simpleMessage("Tanya Jawab Umum"),
        "faqs": MessageLookupByLibrary.simpleMessage("Tanya Jawab Umum"),
        "feedback": MessageLookupByLibrary.simpleMessage("Masukan"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Gagal menyimpan file ke galeri"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Tambahkan keterangan..."),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("File tersimpan ke galeri"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Jenis file"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Nama dan jenis file"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("File terhapus"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("File tersimpan ke galeri"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Telusuri orang dengan mudah menggunakan nama"),
        "flip": MessageLookupByLibrary.simpleMessage("Balik"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("untuk kenanganmu"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage("Lupa sandi"),
        "foundFaces":
            MessageLookupByLibrary.simpleMessage("Wajah yang ditemukan"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Kuota gratis diperoleh"),
        "freeStorageOnReferralSuccess": m4,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Kuota gratis yang dapat digunakan"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Percobaan gratis"),
        "freeTrialValidTill": m37,
        "freeUpAccessPostDelete": m38,
        "freeUpAmount": m39,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Bersihkan penyimpanan perangkat"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Hemat ruang penyimpanan di perangkatmu dengan membersihkan file yang sudah tercadangkan."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Bersihkan ruang"),
        "freeUpSpaceSaving": m40,
        "general": MessageLookupByLibrary.simpleMessage("Umum"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Menghasilkan kunci enkripsi..."),
        "genericProgress": m41,
        "goToSettings": MessageLookupByLibrary.simpleMessage("Buka pengaturan"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("ID Google Play"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Harap berikan akses ke semua foto di app Pengaturan"),
        "grantPermission": MessageLookupByLibrary.simpleMessage("Berikan izin"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
            "Kelompokkan foto yang berdekatan"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Dari mana Anda menemukan Ente? (opsional)"),
        "help": MessageLookupByLibrary.simpleMessage("Bantuan"),
        "hidden": MessageLookupByLibrary.simpleMessage("Tersembunyi"),
        "hide": MessageLookupByLibrary.simpleMessage("Sembunyikan"),
        "hiding": MessageLookupByLibrary.simpleMessage("Menyembunyikan..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Dihosting oleh OSM France"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Cara kerjanya"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Silakan minta dia untuk menekan lama alamat email-nya di layar pengaturan, dan pastikan bahwa ID di perangkatnya sama."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Autentikasi biometrik belum aktif di perangkatmu. Silakan aktifkan Touch ID atau Face ID pada ponselmu."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Abaikan"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Sejumlah file di album ini tidak terunggah karena telah dihapus sebelumnya dari Ente."),
        "importing": MessageLookupByLibrary.simpleMessage("Mengimpor...."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("Kode salah"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Sandi salah"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Kunci pemulihan salah"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Kunci pemulihan yang kamu masukkan salah"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Kunci pemulihan salah"),
        "indexedItems": MessageLookupByLibrary.simpleMessage("Item terindeks"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "Proses indeks dijeda, dan akan otomatis dilanjutkan saat perangkat siap."),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Perangkat tidak aman"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Instal secara manual"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Alamat email tidak sah"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Endpoint tidak sah"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Maaf, endpoint yang kamu masukkan tidak sah. Harap masukkan endpoint yang sah dan coba lagi."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Kunci tidak sah"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Kunci pemulihan yang kamu masukkan tidak sah. Pastikan kunci tersebut berisi 24 kata, dan teliti ejaan masing-masing kata.\n\nJika kamu memasukkan kode pemulihan lama, pastikan kode tersebut berisi 64 karakter, dan teliti setiap karakter yang ada."),
        "invite": MessageLookupByLibrary.simpleMessage("Undang"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Undang ke Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Undang teman-temanmu"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Undang temanmu ke Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Sepertinya terjadi kesalahan. Silakan coba lagi setelah beberapa saat. Jika kesalahan terus terjadi, silakan hubungi tim dukungan kami."),
        "itemCount": m42,
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Item yang dipilih akan dihapus dari album ini"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Bergabung ke Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Simpan foto"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Harap bantu kami dengan informasi ini"),
        "language": MessageLookupByLibrary.simpleMessage("Bahasa"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Terakhir diperbarui"),
        "leave": MessageLookupByLibrary.simpleMessage("Tinggalkan"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Tinggalkan album"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Tinggalkan keluarga"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Tinggalkan album bersama?"),
        "left": MessageLookupByLibrary.simpleMessage("Kiri"),
        "light": MessageLookupByLibrary.simpleMessage("Cahaya"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Cerah"),
        "linkCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Link tersalin ke papan klip"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Batas perangkat"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Aktif"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Kedaluwarsa"),
        "linkExpiresOn": m44,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Waktu kedaluwarsa link"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Link telah kedaluwarsa"),
        "linkNeverExpires":
            MessageLookupByLibrary.simpleMessage("Tidak pernah"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Kamu bisa membagikan langgananmu dengan keluarga"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Kami telah memelihara lebih dari 30 juta kenangan saat ini"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Kami menyimpan 3 salinan dari data kamu, salah satunya di tempat pengungsian bawah tanah"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "App seluler kami berjalan di latar belakang untuk mengenkripsi dan mencadangkan foto yang kamu potret"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io menyediakan alat pengunggah yang bagus"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Kami menggunakan Xchacha20Poly1305 untuk mengenkripsi data-mu dengan aman"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Memuat data EXIF..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Memuat galeri..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Memuat fotomu..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Mengunduh model..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galeri lokal"),
        "locationName": MessageLookupByLibrary.simpleMessage("Nama tempat"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Kunci"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Kunci layar"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Masuk akun"),
        "loggingOut":
            MessageLookupByLibrary.simpleMessage("Mengeluarkan akun..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Sesi berakhir"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Sesi kamu telah berakhir. Silakan masuk akun kembali."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Dengan mengklik masuk akun, saya menyetujui <u-terms>ketentuan layanan</u-terms> dan <u-policy>kebijakan privasi</u-policy> Ente"),
        "logout": MessageLookupByLibrary.simpleMessage("Keluar akun"),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Tekan dan tahan email untuk membuktikan enkripsi ujung ke ujung."),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Perangkat hilang?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Pemelajaran mesin"),
        "magicSearch":
            MessageLookupByLibrary.simpleMessage("Penelusuran ajaib"),
        "manage": MessageLookupByLibrary.simpleMessage("Atur"),
        "manageFamily": MessageLookupByLibrary.simpleMessage("Atur Keluarga"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Atur link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Atur"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Atur langganan"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Tautkan dengan PIN berfungsi di layar mana pun yang kamu inginkan."),
        "map": MessageLookupByLibrary.simpleMessage("Peta"),
        "maps": MessageLookupByLibrary.simpleMessage("Peta"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m5,
        "merchandise": MessageLookupByLibrary.simpleMessage("Merchandise"),
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Aktifkan pemelajaran mesin"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Saya memahami, dan bersedia mengaktifkan pemelajaran mesin"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Jika kamu mengaktifkan pemelajaran mesin, Ente akan memproses informasi seperti geometri wajah dari file yang ada, termasuk file yang dibagikan kepadamu.\n\nIni dijalankan pada perangkatmu, dan setiap informasi biometrik yang dibuat akan terenkripsi ujung ke ujung."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Klik di sini untuk detail lebih lanjut tentang fitur ini pada kebijakan privasi kami"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("Aktifkan pemelajaran mesin?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Perlu diperhatikan bahwa pemelajaran mesin dapat meningkatkan penggunaan data dan baterai perangkat hingga seluruh item selesai terindeks. Gunakan aplikasi desktop untuk pengindeksan lebih cepat, seluruh hasil akan tersinkronkan secara otomatis."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Seluler, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Sedang"),
        "moments": MessageLookupByLibrary.simpleMessage("Momen"),
        "monthly": MessageLookupByLibrary.simpleMessage("Bulanan"),
        "moveItem": m45,
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Pindahkan ke album tersembunyi"),
        "movedSuccessfullyTo": m46,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Pindah ke sampah"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Memindahkan file ke album..."),
        "name": MessageLookupByLibrary.simpleMessage("Nama"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat terhubung dengan Ente, silakan coba lagi setelah beberapa saat. Jika masalah berlanjut, harap hubungi dukungan."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat terhubung dengan Ente, harap periksa pengaturan jaringan kamu dan hubungi dukungan jika masalah berlanjut."),
        "never": MessageLookupByLibrary.simpleMessage("Tidak pernah"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Album baru"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Baru di Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Terbaru"),
        "no": MessageLookupByLibrary.simpleMessage("Tidak"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Belum ada album yang kamu bagikan"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Tidak ditemukan perangkat"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Tidak ada"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Tidak ada file yang perlu dihapus dari perangkat ini"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Tak ada file duplikat"),
        "noExifData":
            MessageLookupByLibrary.simpleMessage("Tidak ada data EXIF"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Tidak ada foto atau video tersembunyi"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Tidak ada koneksi internet"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Tidak ada foto yang sedang dicadangkan sekarang"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("Tidak ada foto di sini"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Tidak punya kunci pemulihan?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Karena sifat protokol enkripsi ujung ke ujung kami, data kamu tidak dapat didekripsi tanpa sandi atau kunci pemulihan kamu"),
        "noResults": MessageLookupByLibrary.simpleMessage("Tidak ada hasil"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Tidak ditemukan hasil"),
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Belum ada yang dibagikan denganmu"),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
            "Tidak ada apa-apa di sini! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifikasi"),
        "ok": MessageLookupByLibrary.simpleMessage("Oke"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Di perangkat ini"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Di <branding>ente</branding>"),
        "onlyFamilyAdminCanChangeCode": m49,
        "oops": MessageLookupByLibrary.simpleMessage("Aduh"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Aduh, tidak dapat menyimpan perubahan"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Aduh, terjadi kesalahan"),
        "openSettings": MessageLookupByLibrary.simpleMessage("Buka Pengaturan"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Buka item-nya"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("Kontributor OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Opsional, pendek pun tak apa..."),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Atau pilih yang sudah ada"),
        "pair": MessageLookupByLibrary.simpleMessage("Tautkan"),
        "pairWithPin":
            MessageLookupByLibrary.simpleMessage("Tautkan dengan PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Penautan berhasil"),
        "passkey": MessageLookupByLibrary.simpleMessage("Passkey"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Verifikasi passkey"),
        "password": MessageLookupByLibrary.simpleMessage("Sandi"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Sandi berhasil diubah"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Kunci dengan sandi"),
        "passwordStrength": m0,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Kami tidak menyimpan sandi ini, jadi jika kamu melupakannya, <underline>kami tidak akan bisa mendekripsi data kamu</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Rincian pembayaran"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Pembayaran gagal"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Sayangnya, pembayaranmu gagal. Silakan hubungi tim bantuan agar dapat kami bantu!"),
        "paymentFailedTalkToProvider": m50,
        "pendingItems": MessageLookupByLibrary.simpleMessage("Item menunggu"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Sinkronisasi tertunda"),
        "people": MessageLookupByLibrary.simpleMessage("Orang"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Orang yang telah menggunakan kodemu"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Semua item di sampah akan dihapus secara permanen\n\nTindakan ini tidak dapat dibatalkan"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Hapus secara permanen"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Hapus dari perangkat secara permanen?"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Keterangan foto"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Ukuran kotak foto"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "photos": MessageLookupByLibrary.simpleMessage("Foto"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Foto yang telah kamu tambahkan akan dihapus dari album ini"),
        "playOnTv": MessageLookupByLibrary.simpleMessage("Putar album di TV"),
        "playStoreFreeTrialValidTill": m52,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Langganan PlayStore"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Silakan periksa koneksi internet kamu, lalu coba lagi."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Silakan hubungi support@ente.io dan kami akan dengan senang hati membantu!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Silakan hubungi tim bantuan jika masalah terus terjadi"),
        "pleaseEmailUsAt": m53,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Harap berikan izin"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Silakan masuk akun lagi"),
        "pleaseSendTheLogsTo": m54,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Silakan coba lagi"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Harap periksa kode yang kamu masukkan"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Harap tunggu..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Harap tunggu, sedang menghapus album"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Harap tunggu beberapa saat sebelum mencoba lagi"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Menyiapkan log..."),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Tekan dan tahan untuk memutar video"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Tekan dan tahan gambar untuk memutar video"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privasi"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Kebijakan Privasi"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Cadangan pribadi"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Berbagi secara privat"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Link publik dibuat"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Link publik aktif"),
        "radius": MessageLookupByLibrary.simpleMessage("Radius"),
        "raiseTicket":
            MessageLookupByLibrary.simpleMessage("Buat tiket dukungan"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Nilai app ini"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Beri kami nilai"),
        "rateUsOnStore": m56,
        "recover": MessageLookupByLibrary.simpleMessage("Pulihkan"),
        "recoverAccount": MessageLookupByLibrary.simpleMessage("Pulihkan akun"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Pulihkan"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage("Kunci pemulihan"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Kunci pemulihan tersalin ke papan klip"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Saat kamu lupa sandi, satu-satunya cara untuk memulihkan data kamu adalah dengan kunci ini."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Kami tidak menyimpan kunci ini, jadi harap simpan kunci yang berisi 24 kata ini dengan aman."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Bagus! Kunci pemulihan kamu sah. Terima kasih telah melakukan verifikasi.\n\nHarap simpan selalu kunci pemulihan kamu dengan aman."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Kunci pemulihan terverifikasi"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Kunci pemulihan kamu adalah satu-satunya cara untuk memulihkan foto-foto kamu jika kamu lupa kata sandi. Kamu bisa lihat kunci pemulihan kamu di Pengaturan > Akun.\n\nHarap masukkan kunci pemulihan kamu di sini untuk memastikan bahwa kamu telah menyimpannya dengan baik."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Pemulihan berhasil!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Perangkat ini tidak cukup kuat untuk memverifikasi kata sandi kamu, tetapi kami dapat membuat ulang kata sandi kamu sehingga dapat digunakan di semua perangkat.\n\nSilakan masuk menggunakan kunci pemulihan dan buat ulang kata sandi kamu (kamu dapat menggunakan kata sandi yang sama lagi jika mau)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Buat ulang sandi"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Berikan kode ini ke teman kamu"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Ia perlu daftar ke paket berbayar"),
        "referralStep3": m60,
        "referrals": MessageLookupByLibrary.simpleMessage("Referensi"),
        "referralsAreCurrentlyPaused":
            MessageLookupByLibrary.simpleMessage("Rujukan sedang dijeda"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Kosongkan juga “Baru Dihapus” dari “Pengaturan” -> “Penyimpanan” untuk memperoleh ruang yang baru saja dibersihkan"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Kosongkan juga \"Sampah\" untuk memperoleh ruang yang baru dikosongkan"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Thumbnail jarak jauh"),
        "remove": MessageLookupByLibrary.simpleMessage("Hapus"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Hapus duplikat"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Lihat dan hapus file yang sama persis."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Hapus dari album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Hapus dari album?"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Hapus link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Hapus peserta"),
        "removeParticipantBody": m61,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Hapus label orang"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Hapus link publik"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Beberapa item yang kamu hapus ditambahkan oleh orang lain, dan kamu akan kehilangan akses ke item tersebut"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Hapus?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Menghapus dari favorit..."),
        "rename": MessageLookupByLibrary.simpleMessage("Ubah nama"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Ubah nama album"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Ubah nama file"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Perpanjang langganan"),
        "renewsOn": m62,
        "reportABug": MessageLookupByLibrary.simpleMessage("Laporkan bug"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Laporkan bug"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Kirim ulang email"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Atur ulang sandi"),
        "restore": MessageLookupByLibrary.simpleMessage("Pulihkan"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Memulihkan file..."),
        "retry": MessageLookupByLibrary.simpleMessage("Coba lagi"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Silakan lihat dan hapus item yang merupakan duplikat."),
        "right": MessageLookupByLibrary.simpleMessage("Kanan"),
        "rotate": MessageLookupByLibrary.simpleMessage("Putar"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Putar ke kiri"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Putar ke kanan"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("Tersimpan aman"),
        "save": MessageLookupByLibrary.simpleMessage("Simpan"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Simpan kunci"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Jika belum, simpan kunci pemulihan kamu"),
        "saving": MessageLookupByLibrary.simpleMessage("Menyimpan..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Menyimpan edit..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Pindai kode"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Pindai barcode ini dengan\napp autentikator kamu"),
        "search": MessageLookupByLibrary.simpleMessage("Telusuri"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Album"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Nama album"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Nama album (cth. \"Kamera\")\n• Jenis file (cth. \"Video\", \".gif\")\n• Tahun atau bulan (cth. \"2022\", \"Januari\")\n• Musim liburan (cth. \"Natal\")\n• Keterangan foto (cth. “#seru”)"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Tambah keterangan seperti \"#trip\" pada info foto agar mudah ditemukan di sini"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Telusuri dengan tanggal, bulan, atau tahun"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Orang akan ditampilkan di sini setelah pengindeksan selesai"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Nama dan jenis file"),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("Tanggal, keterangan foto"),
        "searchHint3":
            MessageLookupByLibrary.simpleMessage("Album, nama dan jenis file"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Segera tiba: Penelusuran wajah & ajaib ✨"),
        "searchResultCount": m63,
        "security": MessageLookupByLibrary.simpleMessage("Keamanan"),
        "selectALocation": MessageLookupByLibrary.simpleMessage("Pilih lokasi"),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
            "Pilih lokasi terlebih dahulu"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Pilih album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Pilih semua"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Pilih folder yang perlu dicadangkan"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Pilih item untuk ditambahkan"),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("Pilih Bahasa"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Pilih lebih banyak foto"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Pilih alasan"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Pilih paket kamu"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "File terpilih tidak tersimpan di Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Folder yang terpilih akan dienkripsi dan dicadangkan"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Item terpilih akan dihapus dari semua album dan dipindahkan ke sampah."),
        "selectedPhotos": m6,
        "selectedPhotosWithYours": m65,
        "send": MessageLookupByLibrary.simpleMessage("Kirim"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Kirim email"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Kirim undangan"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Kirim link"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Endpoint server"),
        "sessionExpired": MessageLookupByLibrary.simpleMessage("Sesi berakhir"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Atur sandi"),
        "setAs": MessageLookupByLibrary.simpleMessage("Pasang sebagai"),
        "setCover": MessageLookupByLibrary.simpleMessage("Ubah sampul"),
        "setPasswordTitle": MessageLookupByLibrary.simpleMessage("Atur sandi"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Penyiapan selesai"),
        "share": MessageLookupByLibrary.simpleMessage("Bagikan"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Bagikan link"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Buka album lalu ketuk tombol bagikan di sudut kanan atas untuk berbagi."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Bagikan album sekarang"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Bagikan link"),
        "shareMyVerificationID": m66,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Bagikan hanya dengan orang yang kamu inginkan"),
        "shareTextConfirmOthersVerificationID": m7,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Unduh Ente agar kita bisa berbagi foto dan video kualitas asli dengan mudah\n\nhttps://ente.io"),
        "shareTextReferralCode": m67,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Bagikan ke pengguna non-Ente"),
        "shareWithPeopleSectionTitle": m68,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Bagikan album pertamamu"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Buat album bersama dan kolaborasi dengan pengguna Ente lain, termasuk pengguna paket gratis."),
        "sharedByMe":
            MessageLookupByLibrary.simpleMessage("Dibagikan oleh saya"),
        "sharedByYou":
            MessageLookupByLibrary.simpleMessage("Dibagikan oleh kamu"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Foto terbagi baru"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Terima notifikasi apabila seseorang menambahkan foto ke album bersama yang kamu ikuti"),
        "sharedWith": m69,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Dibagikan dengan saya"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Dibagikan dengan kamu"),
        "sharing": MessageLookupByLibrary.simpleMessage("Membagikan..."),
        "showMemories": MessageLookupByLibrary.simpleMessage("Lihat kenangan"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Keluarkan akun dari perangkat lain"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Jika kamu merasa ada yang mengetahui sandimu, kamu bisa mengeluarkan akunmu secara paksa dari perangkat lain."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Keluar di perangkat lain"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Saya menyetujui <u-terms>ketentuan layanan</u-terms> dan <u-policy>kebijakan privasi</u-policy> Ente"),
        "singleFileDeleteFromDevice": m70,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Ia akan dihapus dari semua album."),
        "singleFileInBothLocalAndRemote": m71,
        "singleFileInRemoteOnly": m72,
        "skip": MessageLookupByLibrary.simpleMessage("Lewati"),
        "social": MessageLookupByLibrary.simpleMessage("Sosial"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Sejumlah item tersimpan di Ente serta di perangkat ini."),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Orang yang membagikan album denganmu bisa melihat ID yang sama di perangkat mereka."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Terjadi kesalahan"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Terjadi kesalahan, silakan coba lagi"),
        "sorry": MessageLookupByLibrary.simpleMessage("Maaf"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Maaf, tidak dapat menambahkan ke favorit!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Maaf, tidak dapat menghapus dari favorit!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Maaf, kode yang kamu masukkan salah"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Maaf, kami tidak dapat menghasilkan kunci yang aman di perangkat ini.\n\nHarap mendaftar dengan perangkat lain."),
        "sortAlbumsBy":
            MessageLookupByLibrary.simpleMessage("Urut berdasarkan"),
        "sortNewestFirst": MessageLookupByLibrary.simpleMessage("Terbaru dulu"),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage("Terlama dulu"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Berhasil"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Mulai pencadangan"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Apakah kamu ingin menghentikan transmisi?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Hentikan transmisi"),
        "storage": MessageLookupByLibrary.simpleMessage("Penyimpanan"),
        "storageBreakupFamily":
            MessageLookupByLibrary.simpleMessage("Keluarga"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Kamu"),
        "storageInGB": m1,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
            "Batas penyimpanan terlampaui"),
        "storageUsageInfo": m73,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Kuat"),
        "subAlreadyLinkedErrMessage": m74,
        "subWillBeCancelledOn": m75,
        "subscribe": MessageLookupByLibrary.simpleMessage("Berlangganan"),
        "subscription": MessageLookupByLibrary.simpleMessage("Langganan"),
        "success": MessageLookupByLibrary.simpleMessage("Berhasil"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Berhasil diarsipkan"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Berhasil disembunyikan"),
        "successfullyUnarchived": MessageLookupByLibrary.simpleMessage(
            "Berhasil dikeluarkan dari arsip"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Sarankan fitur"),
        "support": MessageLookupByLibrary.simpleMessage("Dukungan"),
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Sinkronisasi terhenti"),
        "syncing": MessageLookupByLibrary.simpleMessage("Menyinkronkan..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistem"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("ketuk untuk salin"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Ketuk untuk masukkan kode"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Sepertinya terjadi kesalahan. Silakan coba lagi setelah beberapa saat. Jika kesalahan terus terjadi, silakan hubungi tim dukungan kami."),
        "terminate": MessageLookupByLibrary.simpleMessage("Akhiri"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Akhiri sesi?"),
        "terms": MessageLookupByLibrary.simpleMessage("Ketentuan"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Ketentuan"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Terima kasih"),
        "thankYouForSubscribing": MessageLookupByLibrary.simpleMessage(
            "Terima kasih telah berlangganan!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Unduhan tidak dapat diselesaikan"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Kunci pemulihan yang kamu masukkan salah"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Item ini akan dihapus dari perangkat ini."),
        "theyAlsoGetXGb": m8,
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Tindakan ini tidak dapat dibatalkan"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Link kolaborasi untuk album ini sudah terbuat"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Ini dapat digunakan untuk memulihkan akunmu jika kehilangan metode autentikasi dua langkah kamu"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Perangkat ini"),
        "thisEmailIsAlreadyInUse":
            MessageLookupByLibrary.simpleMessage("Email ini telah digunakan"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Gambar ini tidak memiliki data exif"),
        "thisIsPersonVerificationId": m78,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Ini adalah ID Verifikasi kamu"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Ini akan mengeluarkan akunmu dari perangkat berikut:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Ini akan mengeluarkan akunmu dari perangkat ini!"),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Untuk menyembunyikan foto atau video"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Untuk mengatur ulang sandimu, harap verifikasi email kamu terlebih dahulu."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Log hari ini"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "trash": MessageLookupByLibrary.simpleMessage("Sampah"),
        "trim": MessageLookupByLibrary.simpleMessage("Pangkas"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Coba lagi"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Aktifkan pencadangan untuk mengunggah file yang ditambahkan ke folder ini ke Ente secara otomatis."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 bulan gratis dengan paket tahunan"),
        "twofactor":
            MessageLookupByLibrary.simpleMessage("Autentikasi dua langkah"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "Autentikasi dua langkah telah dinonaktifkan"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Autentikasi dua langkah"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Autentikasi dua langkah berhasil direset"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Penyiapan autentikasi dua langkah"),
        "unarchive":
            MessageLookupByLibrary.simpleMessage("Keluarkan dari arsip"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Keluarkan album dari arsip"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Mengeluarkan dari arsip..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Maaf, kode ini tidak tersedia."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Tak Berkategori"),
        "unlock": MessageLookupByLibrary.simpleMessage("Buka"),
        "unselectAll":
            MessageLookupByLibrary.simpleMessage("Batalkan semua pilihan"),
        "update": MessageLookupByLibrary.simpleMessage("Perbarui"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Pembaruan tersedia"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Memperbaharui pilihan folder..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Tingkatkan"),
        "uploadingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Mengunggah file ke album..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Potongan hingga 50%, sampai 4 Des."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Kuota yang dapat digunakan dibatasi oleh paket kamu saat ini. Kelebihan kuota yang diklaim akan dapat digunakan secara otomatis saat meningkatkan paket kamu."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Bagikan link publik ke orang yang tidak menggunakan Ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Gunakan kunci pemulihan"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Gunakan foto terpilih"),
        "validTill": m84,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verifikasi gagal, silakan coba lagi"),
        "verificationId": MessageLookupByLibrary.simpleMessage("ID Verifikasi"),
        "verify": MessageLookupByLibrary.simpleMessage("Verifikasi"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Verifikasi email"),
        "verifyEmailID": m85,
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Verifikasi passkey"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verifikasi sandi"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Memverifikasi kunci pemulihan..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "videos": MessageLookupByLibrary.simpleMessage("Video"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Lihat sesi aktif"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Lihat semua"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Lihat seluruh data EXIF"),
        "viewLargeFiles":
            MessageLookupByLibrary.simpleMessage("File berukuran besar"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Tampilkan file yang paling besar mengonsumsi ruang penyimpanan."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Lihat log"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Lihat kunci pemulihan"),
        "viewer": MessageLookupByLibrary.simpleMessage("Pemirsa"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Silakan buka web.ente.io untuk mengatur langgananmu"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Menunggu verifikasi..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Menunggu WiFi..."),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Kode sumber kami terbuka!"),
        "weHaveSendEmailTo": m2,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Lemah"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Selamat datang kembali!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Hal yang baru"),
        "yearly": MessageLookupByLibrary.simpleMessage("Tahunan"),
        "yearsAgo": m87,
        "yes": MessageLookupByLibrary.simpleMessage("Ya"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Ya, batalkan"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Ya, ubah ke pemirsa"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Ya, hapus"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Ya, buang perubahan"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Ya, keluar"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Ya, hapus"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Ya, Perpanjang"),
        "you": MessageLookupByLibrary.simpleMessage("Kamu"),
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
            "Kamu menggunakan paket keluarga!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Kamu menggunakan versi terbaru"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Maksimal dua kali lipat dari kuota penyimpananmu"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Kamu bisa atur link yang telah kamu buat di tab berbagi."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Kamu tidak dapat turun ke paket ini"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Kamu tidak bisa berbagi dengan dirimu sendiri"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Kamu tidak memiliki item di arsip."),
        "youHaveSuccessfullyFreedUp": m88,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Akunmu telah dihapus"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Peta kamu"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Paket kamu berhasil di turunkan"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Paket kamu berhasil ditingkatkan"),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("Pembelianmu berhasil"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Rincian penyimpananmu tidak dapat dimuat"),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("Langgananmu telah berakhir"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Langgananmu telah berhasil diperbarui"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Kode verifikasi kamu telah kedaluwarsa"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Kamu tidak memiliki file duplikat yang dapat dihapus"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
            "Perkecil peta untuk melihat foto lainnya")
      };
}
