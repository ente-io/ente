// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a vi locale. All the
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
  String get localeName => 'vi';

  static String m3(storageAmount, endDate) =>
      "Gói bổ sung ${storageAmount} của bạn có hiệu lực đến ${endDate}";

  static String m5(emailOrName) => "Được thêm bởi ${emailOrName}";

  static String m6(albumName) => "Đã thêm thành công vào ${albumName}";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Không có người tham gia', one: '1 người tham gia', other: '${count} Người tham gia')}";

  static String m9(versionValue) => "Phiên bản: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} còn trống";

  static String m12(paymentProvider) =>
      "Vui lòng hủy đăng ký hiện tại của bạn từ ${paymentProvider} trước";

  static String m13(user) =>
      "${user} sẽ không thể thêm ảnh mới vào album này\n\nHọ vẫn có thể xóa các ảnh đã thêm trước đó";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Gia đình bạn đã yêu cầu ${storageAmountInGb} GB cho đến nay',
            'false': 'Bạn đã yêu cầu ${storageAmountInGb} GB cho đến nay',
            'other': 'Bạn đã yêu cầu ${storageAmountInGb} GB cho đến nay!',
          })}";

  static String m15(albumName) =>
      "Liên kết hợp tác đã được tạo cho ${albumName}";

  static String m16(count) =>
      "${Intl.plural(count, zero: 'Đã thêm 0 cộng tác viên', one: 'Đã thêm 1 cộng tác viên', other: 'Đã thêm ${count} cộng tác viên')}";

  static String m17(email, numOfDays) =>
      "Bạn sắp thêm ${email} làm liên hệ tin cậy. Họ sẽ có thể khôi phục tài khoản của bạn nếu bạn không hoạt động trong ${numOfDays} ngày.";

  static String m18(familyAdminEmail) =>
      "Vui lòng liên hệ với <green>${familyAdminEmail}</green> để quản lý đăng ký của bạn";

  static String m19(provider) =>
      "Vui lòng liên hệ với chúng tôi tại support@ente.io để quản lý đăng ký ${provider} của bạn.";

  static String m20(endpoint) => "Đã kết nối với ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Xóa ${count} mục', other: 'Xóa ${count} mục')}";

  static String m23(currentlyDeleting, totalCount) =>
      "Đang xóa ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "Điều này sẽ xóa liên kết công khai để truy cập \"${albumName}\".";

  static String m25(supportEmail) =>
      "Vui lòng gửi email đến ${supportEmail} từ địa chỉ email đã đăng ký của bạn";

  static String m26(count, storageSaved) =>
      "Bạn đã dọn dẹp ${Intl.plural(count, other: '${count} tệp trùng lặp')}, tiết kiệm (${storageSaved}!)";

  static String m27(count, formattedSize) =>
      "${count} tệp, ${formattedSize} mỗi tệp";

  static String m29(newEmail) => "Email đã được thay đổi thành ${newEmail}";

  static String m31(email) =>
      "${email} không có tài khoản Ente.\n\nGửi cho họ một lời mời để chia sẻ ảnh.";

  static String m33(text) => "Extra photos found for ${text}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 tệp', other: '${formattedNumber} tệp')} trên thiết bị này đã được sao lưu an toàn";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 tệp', other: '${formattedNumber} tệp')} trong album này đã được sao lưu an toàn";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB mỗi khi ai đó đăng ký gói trả phí và áp dụng mã của bạn";

  static String m38(endDate) => "Dùng thử miễn phí có hiệu lực đến ${endDate}";

  static String m40(sizeInMBorGB) => "Giải phóng ${sizeInMBorGB}";

  static String m41(count, formattedSize) =>
      "${Intl.plural(count, one: 'Nó có thể được xóa khỏi thiết bị để giải phóng ${formattedSize}', other: 'Chúng có thể được xóa khỏi thiết bị để giải phóng ${formattedSize}')}";

  static String m42(currentlyProcessing, totalCount) =>
      "Đang xử lý ${currentlyProcessing} / ${totalCount}";

  static String m44(count) => "${Intl.plural(count, other: '${count} mục')}";

  static String m46(email) =>
      "${email} đã mời bạn trở thành một liên hệ tin cậy";

  static String m47(expiryTime) => "Liên kết sẽ hết hạn vào ${expiryTime}";

  static String m52(albumName) => "Đã di chuyển thành công đến ${albumName}";

  static String m53(personName) => "Không có gợi ý cho ${personName}";

  static String m54(name) => "Không phải ${name}?";

  static String m55(familyAdminEmail) =>
      "Vui lòng liên hệ ${familyAdminEmail} để thay đổi mã của bạn.";

  static String m57(passwordStrengthValue) =>
      "Độ mạnh mật khẩu: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Vui lòng nói chuyện với bộ phận hỗ trợ ${providerName} nếu bạn đã bị tính phí";

  static String m63(endDate) =>
      "Dùng thử miễn phí có hiệu lực đến ${endDate}.\nBạn có thể chọn gói trả phí sau đó.";

  static String m64(toEmail) =>
      "Vui lòng gửi email cho chúng tôi tại ${toEmail}";

  static String m65(toEmail) => "Vui lòng gửi nhật ký đến \n${toEmail}";

  static String m67(folderName) => "Đang xử lý ${folderName}...";

  static String m68(storeName) => "Đánh giá chúng tôi trên ${storeName}";

  static String m70(days, email) =>
      "Bạn có thể truy cập tài khoản sau ${days} ngày. Một thông báo sẽ được gửi đến ${email}.";

  static String m71(email) =>
      "Bạn có thể khôi phục tài khoản của ${email} bằng cách đặt lại mật khẩu mới.";

  static String m72(email) =>
      "${email} đang cố gắng khôi phục tài khoản của bạn.";

  static String m73(storageInGB) =>
      "3. Cả hai bạn đều nhận ${storageInGB} GB* miễn phí";

  static String m74(userEmail) =>
      "${userEmail} sẽ bị xóa khỏi album chia sẻ này\n\nBất kỳ ảnh nào được thêm bởi họ cũng sẽ bị xóa khỏi album";

  static String m75(endDate) => "Đăng ký sẽ được gia hạn vào ${endDate}";

  static String m77(count) =>
      "${Intl.plural(count, other: '${count} kết quả được tìm thấy')}";

  static String m78(snapshotLength, searchLength) =>
      "Độ dài các phần không khớp: ${snapshotLength} != ${searchLength}";

  static String m80(count) => "${count} đã chọn";

  static String m81(count, yourCount) =>
      "${count} đã chọn (${yourCount} của bạn)";

  static String m83(verificationID) =>
      "Đây là ID xác minh của tôi: ${verificationID} cho ente.io.";

  static String m84(verificationID) =>
      "Chào, bạn có thể xác nhận rằng đây là ID xác minh ente.io của bạn: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Mã giới thiệu Ente: ${referralCode} \n\nÁp dụng nó trong Cài đặt → Chung → Giới thiệu để nhận ${referralStorageInGB} GB miễn phí sau khi bạn đăng ký gói trả phí\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Chia sẻ với những người cụ thể', one: 'Chia sẻ với 1 người', other: 'Chia sẻ với ${numberOfPeople} người')}";

  static String m87(emailIDs) => "Chia sẻ với ${emailIDs}";

  static String m88(fileType) =>
      "Tệp ${fileType} này sẽ bị xóa khỏi thiết bị của bạn.";

  static String m89(fileType) =>
      "Tệp ${fileType} này có trong cả Ente và thiết bị của bạn.";

  static String m90(fileType) => "Tệp ${fileType} này sẽ bị xóa khỏi Ente.";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m94(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} trong tổng số ${totalAmount} ${totalStorageUnit} đã sử dụng";

  static String m95(id) =>
      "ID ${id} của bạn đã được liên kết với một tài khoản Ente khác.\nNếu bạn muốn sử dụng ID ${id} này với tài khoản này, vui lòng liên hệ với bộ phận hỗ trợ của chúng tôi.";

  static String m96(endDate) => "Đăng ký của bạn sẽ bị hủy vào ${endDate}";

  static String m97(completed, total) =>
      "${completed}/${total} kỷ niệm đã được lưu giữ";

  static String m98(ignoreReason) =>
      "Nhấn để tải lên, tải lên hiện tại bị bỏ qua do ${ignoreReason}";

  static String m99(storageAmountInGB) =>
      "Họ cũng nhận được ${storageAmountInGB} GB";

  static String m100(email) => "Đây là ID xác minh của ${email}";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Soon', one: '1 day', other: '${count} days')}";

  static String m106(email) =>
      "Bạn đã được mời làm người liên hệ thừa kế bởi ${email}.";

  static String m107(galleryType) =>
      "Loại thư viện ${galleryType} không được hỗ trợ để đổi tên";

  static String m108(ignoreReason) => "Tải lên bị bỏ qua do ${ignoreReason}";

  static String m109(count) => "Đang lưu giữ ${count} kỷ niệm...";

  static String m110(endDate) => "Có hiệu lực đến ${endDate}";

  static String m111(email) => "Xác minh ${email}";

  static String m114(email) =>
      "Chúng tôi đã gửi một email đến <green>${email}</green>";

  static String m115(name) => "Wish \$${name} a happy birthday! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, other: '${count} năm trước')}";

  static String m118(storageSaved) =>
      "Bạn đã giải phóng thành công ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable":
            MessageLookupByLibrary.simpleMessage("Có phiên bản mới của Ente."),
        "about": MessageLookupByLibrary.simpleMessage("Giới thiệu"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Chấp nhận lời mời"),
        "account": MessageLookupByLibrary.simpleMessage("Tài khoản"),
        "accountIsAlreadyConfigured":
            MessageLookupByLibrary.simpleMessage("Tài khoản đã được cấu hình."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Chào mừng bạn trở lại!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Tôi hiểu rằng nếu tôi mất mật khẩu, tôi có thể mất dữ liệu của mình vì dữ liệu của tôi được <underline>mã hóa đầu cuối</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Phiên hoạt động"),
        "add": MessageLookupByLibrary.simpleMessage("Thêm"),
        "addAName": MessageLookupByLibrary.simpleMessage("Thêm một tên"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Thêm một email mới"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Thêm cộng tác viên"),
        "addFiles": MessageLookupByLibrary.simpleMessage("Thêm tệp"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Thêm từ thiết bị"),
        "addLocation": MessageLookupByLibrary.simpleMessage("Thêm vị trí"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Thêm"),
        "addMore": MessageLookupByLibrary.simpleMessage("Thêm nữa"),
        "addName": MessageLookupByLibrary.simpleMessage("Thêm tên"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Thêm tên hoặc hợp nhất"),
        "addNew": MessageLookupByLibrary.simpleMessage("Thêm mới"),
        "addNewPerson": MessageLookupByLibrary.simpleMessage("Thêm người mới"),
        "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
            "Chi tiết về tiện ích mở rộng"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Tiện ích mở rộng"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Thêm ảnh"),
        "addSelected": MessageLookupByLibrary.simpleMessage("Thêm đã chọn"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Thêm vào album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Thêm vào Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Thêm vào album ẩn"),
        "addTrustedContact":
            MessageLookupByLibrary.simpleMessage("Thêm liên hệ tin cậy"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Thêm người xem"),
        "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
            "Thêm ảnh của bạn ngay bây giờ"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Đã thêm như"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
            "Đang thêm vào mục yêu thích..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Nâng cao"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Nâng cao"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Sau 1 ngày"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Sau 1 giờ"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Sau 1 tháng"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Sau 1 tuần"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Sau 1 năm"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Chủ sở hữu"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Tiêu đề album"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album đã được cập nhật"),
        "albums": MessageLookupByLibrary.simpleMessage("Album"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Tất cả đã rõ"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
            "Tất cả kỷ niệm đã được lưu giữ"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Tất cả các nhóm cho người này sẽ được đặt lại, và bạn sẽ mất tất cả các gợi ý đã được đưa ra cho người này"),
        "allow": MessageLookupByLibrary.simpleMessage("Cho phép"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Cho phép người có liên kết cũng thêm ảnh vào album chia sẻ."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Cho phép thêm ảnh"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "Cho phép ứng dụng mở liên kết album chia sẻ"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Cho phép tải xuống"),
        "allowPeopleToAddPhotos":
            MessageLookupByLibrary.simpleMessage("Cho phép mọi người thêm ảnh"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Vui lòng cho phép truy cập vào ảnh của bạn từ Cài đặt để Ente có thể hiển thị và sao lưu thư viện của bạn."),
        "allowPermTitle":
            MessageLookupByLibrary.simpleMessage("Cho phép truy cập ảnh"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Xác minh danh tính"),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
            "Không nhận diện được. Thử lại."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Yêu cầu sinh trắc học"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Thành công"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Hủy"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Yêu cầu thông tin xác thực thiết bị"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Yêu cầu thông tin xác thực thiết bị"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Xác thực sinh trắc học chưa được thiết lập trên thiết bị của bạn. Đi đến \'Cài đặt > Bảo mật\' để thêm xác thực sinh trắc học."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Desktop"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Yêu cầu xác thực"),
        "appLock": MessageLookupByLibrary.simpleMessage("Khóa ứng dụng"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Chọn giữa màn hình khóa mặc định của thiết bị và màn hình khóa tùy chỉnh với PIN hoặc mật khẩu."),
        "appVersion": m9,
        "appleId": MessageLookupByLibrary.simpleMessage("ID Apple"),
        "apply": MessageLookupByLibrary.simpleMessage("Áp dụng"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Áp dụng mã"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Đăng ký AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("Lưu trữ"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Lưu trữ album"),
        "archiving": MessageLookupByLibrary.simpleMessage("Đang lưu trữ..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Bạn có chắc chắn muốn rời khỏi kế hoạch gia đình không?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Bạn có chắc chắn muốn hủy không?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Bạn có chắc chắn muốn thay đổi gói của mình không?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Bạn có chắc chắn muốn thoát không?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Bạn có chắc chắn muốn đăng xuất không?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Bạn có chắc chắn muốn gia hạn không?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Bạn có chắc chắn muốn đặt lại người này không?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Đăng ký của bạn đã bị hủy. Bạn có muốn chia sẻ lý do không?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Lý do chính bạn xóa tài khoản là gì?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Hãy yêu cầu những người thân yêu của bạn chia sẻ"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("tại một nơi trú ẩn"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Vui lòng xác thực để thay đổi cài đặt xác minh email"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xác thực để thay đổi cài đặt màn hình khóa"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xác thực để thay đổi email của bạn"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xác thực để thay đổi mật khẩu của bạn"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Vui lòng xác thực để cấu hình xác thực hai yếu tố"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xác thực để bắt đầu xóa tài khoản"),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xác thực để quản lý các liên hệ tin cậy của bạn"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xác thực để xem khóa truy cập của bạn"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xác thực để xem các tệp đã xóa của bạn"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xác thực để xem các phiên hoạt động của bạn"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xác thực để xem các tệp ẩn của bạn"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xác thực để xem kỷ niệm của bạn"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xác thực để xem khóa khôi phục của bạn"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Đang xác thực..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Xác thực không thành công, vui lòng thử lại"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("Xác thực thành công!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Bạn sẽ thấy các thiết bị Cast có sẵn ở đây."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Hãy chắc chắn rằng quyền Mạng cục bộ đã được bật cho ứng dụng Ente Photos, trong Cài đặt."),
        "autoLock": MessageLookupByLibrary.simpleMessage("Khóa tự động"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Thời gian sau đó ứng dụng sẽ khóa khi được đưa vào nền"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Do sự cố kỹ thuật, bạn đã bị đăng xuất. Chúng tôi xin lỗi vì sự bất tiện."),
        "autoPair": MessageLookupByLibrary.simpleMessage("Ghép nối tự động"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Ghép nối tự động chỉ hoạt động với các thiết bị hỗ trợ Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Có sẵn"),
        "availableStorageSpace": m10,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Thư mục đã sao lưu"),
        "backup": MessageLookupByLibrary.simpleMessage("Sao lưu"),
        "backupFailed":
            MessageLookupByLibrary.simpleMessage("Sao lưu thất bại"),
        "backupFile": MessageLookupByLibrary.simpleMessage("Tệp sao lưu"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("Sao lưu qua dữ liệu di động"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Cài đặt sao lưu"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("Trạng thái sao lưu"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Các mục đã được sao lưu sẽ hiển thị ở đây"),
        "backupVideos": MessageLookupByLibrary.simpleMessage("Sao lưu video"),
        "birthday": MessageLookupByLibrary.simpleMessage("Sinh nhật"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Giảm giá Black Friday"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Dữ liệu đã lưu"),
        "calculating":
            MessageLookupByLibrary.simpleMessage("Đang tính toán..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Xin lỗi, album này không thể mở trong ứng dụng."),
        "canNotOpenTitle":
            MessageLookupByLibrary.simpleMessage("Không thể mở album này"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Không thể tải lên album thuộc sở hữu của người khác"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Chỉ có thể tạo liên kết cho các tệp thuộc sở hữu của bạn"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Chỉ có thể xóa các tệp thuộc sở hữu của bạn"),
        "cancel": MessageLookupByLibrary.simpleMessage("Hủy"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Hủy khôi phục"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "Bạn có chắc chắn muốn hủy khôi phục không?"),
        "cancelOtherSubscription": m12,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Hủy đăng ký"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Không thể xóa các tệp đã chia sẻ"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Phát album"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Vui lòng đảm bảo bạn đang ở trên cùng một mạng với TV."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("Không thể phát album"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Truy cập cast.ente.io trên thiết bị bạn muốn ghép nối.\n\nNhập mã dưới đây để phát album trên TV của bạn."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Điểm trung tâm"),
        "change": MessageLookupByLibrary.simpleMessage("Thay đổi"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Thay đổi email"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Thay đổi vị trí của các mục đã chọn?"),
        "changePassword": MessageLookupByLibrary.simpleMessage("Đổi mật khẩu"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Thay đổi mật khẩu"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Thay đổi quyền?"),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
            "Thay đổi mã giới thiệu của bạn"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Kiểm tra cập nhật"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Vui lòng kiểm tra hộp thư đến (và thư rác) để hoàn tất xác minh"),
        "checkStatus":
            MessageLookupByLibrary.simpleMessage("Kiểm tra trạng thái"),
        "checking": MessageLookupByLibrary.simpleMessage("Đang kiểm tra..."),
        "checkingModels": MessageLookupByLibrary.simpleMessage(
            "Đang kiểm tra các mô hình..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Yêu cầu lưu trữ miễn phí"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Yêu cầu thêm!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Đã yêu cầu"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Dọn dẹp chưa phân loại"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Xóa tất cả các tệp từ chưa phân loại có mặt trong các album khác"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Xóa bộ nhớ cache"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Xóa chỉ mục"),
        "click": MessageLookupByLibrary.simpleMessage("• Nhấn"),
        "clickOnTheOverflowMenu":
            MessageLookupByLibrary.simpleMessage("• Nhấn vào menu thả xuống"),
        "close": MessageLookupByLibrary.simpleMessage("Đóng"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Nhóm theo thời gian chụp"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Nhóm theo tên tệp"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Tiến trình phân cụm"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Mã đã được áp dụng"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Xin lỗi, bạn đã đạt giới hạn thay đổi mã."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Mã đã được sao chép vào clipboard"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Mã được sử dụng bởi bạn"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Tạo một liên kết để cho phép mọi người thêm và xem ảnh trong album chia sẻ của bạn mà không cần ứng dụng hoặc tài khoản Ente. Tuyệt vời để thu thập ảnh sự kiện."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Liên kết hợp tác"),
        "collaborativeLinkCreatedFor": m15,
        "collaborator": MessageLookupByLibrary.simpleMessage("Cộng tác viên"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Cộng tác viên có thể thêm ảnh và video vào album chia sẻ."),
        "collaboratorsSuccessfullyAdded": m16,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Bố cục"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
            "Ảnh ghép đã được lưu vào thư viện"),
        "collect": MessageLookupByLibrary.simpleMessage("Thu thập"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Thu thập ảnh sự kiện"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Thu thập ảnh"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Tạo một liên kết nơi bạn bè của bạn có thể tải lên ảnh với chất lượng gốc."),
        "color": MessageLookupByLibrary.simpleMessage("Màu sắc"),
        "configuration": MessageLookupByLibrary.simpleMessage("Cấu hình"),
        "confirm": MessageLookupByLibrary.simpleMessage("Xác nhận"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Bạn có chắc chắn muốn vô hiệu hóa xác thực hai yếu tố không?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Xác nhận xóa tài khoản"),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Có, tôi muốn xóa vĩnh viễn tài khoản này và dữ liệu của nó trên tất cả các ứng dụng."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Xác nhận mật khẩu"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("Xác nhận thay đổi gói"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Xác nhận khóa khôi phục"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Xác nhận khóa khôi phục của bạn"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Kết nối với thiết bị"),
        "contactFamilyAdmin": m18,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Liên hệ hỗ trợ"),
        "contactToManageSubscription": m19,
        "contacts": MessageLookupByLibrary.simpleMessage("Danh bạ"),
        "contents": MessageLookupByLibrary.simpleMessage("Nội dung"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Tiếp tục"),
        "continueOnFreeTrial":
            MessageLookupByLibrary.simpleMessage("Tiếp tục dùng thử miễn phí"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Chuyển đổi thành album"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Sao chép địa chỉ email"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Sao chép liên kết"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Sao chép-dán mã này\ntới ứng dụng xác thực của bạn"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Chúng tôi không thể sao lưu dữ liệu của bạn.\nChúng tôi sẽ thử lại sau."),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
            "Không thể giải phóng không gian"),
        "couldNotUpdateSubscription":
            MessageLookupByLibrary.simpleMessage("Không thể cập nhật đăng ký"),
        "count": MessageLookupByLibrary.simpleMessage("Số lượng"),
        "crashReporting": MessageLookupByLibrary.simpleMessage("Báo cáo sự cố"),
        "create": MessageLookupByLibrary.simpleMessage("Tạo"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Tạo tài khoản"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Nhấn giữ để chọn ảnh và nhấp + để tạo album"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Tạo liên kết cộng tác"),
        "createCollage": MessageLookupByLibrary.simpleMessage("Tạo ảnh ghép"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Tạo tài khoản mới"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Tạo hoặc chọn album"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Tạo liên kết công khai"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Đang tạo liên kết..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("Cập nhật quan trọng có sẵn"),
        "crop": MessageLookupByLibrary.simpleMessage("Cắt xén"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Sử dụng hiện tại là "),
        "currentlyRunning": MessageLookupByLibrary.simpleMessage("đang chạy"),
        "custom": MessageLookupByLibrary.simpleMessage("Tùy chỉnh"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Tối"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Hôm nay"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Hôm qua"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Từ chối lời mời"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Đang giải mã..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Đang giải mã video..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Xóa trùng lặp tệp"),
        "delete": MessageLookupByLibrary.simpleMessage("Xóa"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Xóa tài khoản"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Chúng tôi rất tiếc khi thấy bạn rời đi. Vui lòng chia sẻ phản hồi của bạn để giúp chúng tôi cải thiện."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Xóa tài khoản vĩnh viễn"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Xóa album"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Cũng xóa các ảnh (và video) có trong album này từ <bold>tất cả</bold> các album khác mà chúng là một phần của?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Điều này sẽ xóa tất cả album trống. Điều này hữu ích khi bạn muốn giảm bớt sự lộn xộn trong danh sách album của mình."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Xóa tất cả"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Tài khoản này được liên kết với các ứng dụng Ente khác, nếu bạn sử dụng bất kỳ. Dữ liệu bạn đã tải lên, trên tất cả các ứng dụng Ente, sẽ được lên lịch để xóa, và tài khoản của bạn sẽ bị xóa vĩnh viễn."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Vui lòng gửi email đến <warning>account-deletion@ente.io</warning> từ địa chỉ email đã đăng ký của bạn."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Xóa album trống"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Xóa album trống?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Xóa khỏi cả hai"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Xóa khỏi thiết bị"),
        "deleteFromEnte": MessageLookupByLibrary.simpleMessage("Xóa khỏi Ente"),
        "deleteItemCount": m21,
        "deleteLocation": MessageLookupByLibrary.simpleMessage("Xóa vị trí"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Xóa ảnh"),
        "deleteProgress": m23,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Nó thiếu một tính năng quan trọng mà tôi cần"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Ứng dụng hoặc một tính năng nhất định không hoạt động như tôi nghĩ"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Tôi đã tìm thấy một dịch vụ khác mà tôi thích hơn"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
            "Lý do của tôi không có trong danh sách"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Yêu cầu của bạn sẽ được xử lý trong vòng 72 giờ."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Xóa album chia sẻ?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Album sẽ bị xóa cho tất cả mọi người\n\nBạn sẽ mất quyền truy cập vào các ảnh chia sẻ trong album này mà thuộc sở hữu của người khác"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Bỏ chọn tất cả"),
        "designedToOutlive": MessageLookupByLibrary.simpleMessage(
            "Được thiết kế để tồn tại lâu hơn"),
        "details": MessageLookupByLibrary.simpleMessage("Chi tiết"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Cài đặt Nhà phát triển"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Bạn có chắc chắn muốn thay đổi cài đặt Nhà phát triển không?"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Nhập mã"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Các tệp được thêm vào album thiết bị này sẽ tự động được tải lên Ente."),
        "deviceLock": MessageLookupByLibrary.simpleMessage("Khóa thiết bị"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Vô hiệu hóa khóa màn hình thiết bị khi Ente đang ở chế độ nền và có một bản sao lưu đang diễn ra. Điều này thường không cần thiết, nhưng có thể giúp các tải lên lớn và nhập khẩu ban đầu của các thư viện lớn hoàn thành nhanh hơn."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Không tìm thấy thiết bị"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Bạn có biết?"),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("Vô hiệu hóa khóa tự động"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Người xem vẫn có thể chụp màn hình hoặc lưu bản sao ảnh của bạn bằng các công cụ bên ngoài"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Xin lưu ý"),
        "disableLinkMessage": m24,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Vô hiệu hóa xác thực hai yếu tố"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Đang vô hiệu hóa xác thực hai yếu tố..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Khám phá"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Trẻ em"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Lễ kỷ niệm"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Thức ăn"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Cây cối"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Đồi"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Danh tính"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Hình ảnh chế"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Ghi chú"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Thú cưng"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Biên lai"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Ảnh chụp màn hình"),
        "discover_selfies":
            MessageLookupByLibrary.simpleMessage("Ảnh tự sướng"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Hoàng hôn"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Thẻ thăm"),
        "discover_wallpapers": MessageLookupByLibrary.simpleMessage("Hình nền"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Bỏ qua"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Không đăng xuất"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Làm điều này sau"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Bạn có muốn bỏ qua các chỉnh sửa bạn đã thực hiện không?"),
        "done": MessageLookupByLibrary.simpleMessage("Xong"),
        "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "Gấp đôi dung lượng lưu trữ của bạn"),
        "download": MessageLookupByLibrary.simpleMessage("Tải xuống"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Tải xuống thất bại"),
        "downloading":
            MessageLookupByLibrary.simpleMessage("Đang tải xuống..."),
        "dropSupportEmail": m25,
        "duplicateFileCountWithStorageSaved": m26,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Chỉnh sửa"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Chỉnh sửa vị trí"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Chỉnh sửa vị trí"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Chỉnh sửa người"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Chỉnh sửa đã được lưu"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Các chỉnh sửa cho vị trí sẽ chỉ được thấy trong Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("đủ điều kiện"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "emailAlreadyRegistered":
            MessageLookupByLibrary.simpleMessage("Email đã được đăng kí."),
        "emailChangedTo": m29,
        "emailNoEnteAccount": m31,
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("Email chưa được đăng kí."),
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("Xác minh email"),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("Gửi nhật ký qua email"),
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Liên hệ khẩn cấp"),
        "empty": MessageLookupByLibrary.simpleMessage("Rỗng"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Làm rỗng thùng rác?"),
        "enable": MessageLookupByLibrary.simpleMessage("Bật"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente hỗ trợ học máy trên thiết bị cho nhận diện khuôn mặt, tìm kiếm ma thuật và các tính năng tìm kiếm nâng cao khác"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Bật học máy cho tìm kiếm ma thuật và nhận diện khuôn mặt"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Kích hoạt Bản đồ"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Điều này sẽ hiển thị ảnh của bạn trên bản đồ thế giới.\n\nBản đồ này được lưu trữ bởi Open Street Map, và vị trí chính xác của ảnh của bạn sẽ không bao giờ được chia sẻ.\n\nBạn có thể vô hiệu hóa tính năng này bất cứ lúc nào từ Cài đặt."),
        "enabled": MessageLookupByLibrary.simpleMessage("Đã bật"),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Đang mã hóa sao lưu..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Mã hóa"),
        "encryptionKeys": MessageLookupByLibrary.simpleMessage("Khóa mã hóa"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Điểm cuối đã được cập nhật thành công"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Mã hóa đầu cuối theo mặc định"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente có thể mã hóa và lưu giữ tệp chỉ nếu bạn cấp quyền truy cập cho chúng"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>cần quyền để</i> lưu giữ ảnh của bạn"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente lưu giữ kỷ niệm của bạn, vì vậy chúng luôn có sẵn cho bạn, ngay cả khi bạn mất thiết bị."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Gia đình bạn cũng có thể được thêm vào gói của bạn."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Nhập tên album"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Nhập mã"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Nhập mã do bạn bè cung cấp để nhận lưu trữ miễn phí cho cả hai bạn"),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Sinh nhật (tùy chọn)"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Nhập email"),
        "enterFileName": MessageLookupByLibrary.simpleMessage("Nhập tên tệp"),
        "enterName": MessageLookupByLibrary.simpleMessage("Nhập tên"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Nhập mật khẩu mới mà chúng tôi có thể sử dụng để mã hóa dữ liệu của bạn"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Nhập mật khẩu"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Nhập mật khẩu mà chúng tôi có thể sử dụng để mã hóa dữ liệu của bạn"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Nhập tên người"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Nhập PIN"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Nhập mã giới thiệu"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Nhập mã 6 chữ số từ\ntới ứng dụng xác thực của bạn"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Vui lòng nhập một địa chỉ email hợp lệ."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Nhập địa chỉ email của bạn"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Nhập mật khẩu của bạn"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Nhập khóa khôi phục của bạn"),
        "error": MessageLookupByLibrary.simpleMessage("Lỗi"),
        "everywhere": MessageLookupByLibrary.simpleMessage("mọi nơi"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Người dùng hiện tại"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Liên kết này đã hết hạn. Vui lòng chọn thời gian hết hạn mới hoặc tắt tính năng hết hạn liên kết."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Xuất nhật ký"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Xuất dữ liệu của bạn"),
        "extraPhotosFound":
            MessageLookupByLibrary.simpleMessage("Tìm thấy ảnh bổ sung"),
        "extraPhotosFoundFor": m33,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Khuôn mặt chưa được phân cụm, vui lòng quay lại sau"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Nhận diện khuôn mặt"),
        "faces": MessageLookupByLibrary.simpleMessage("Khuôn mặt"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Không thể áp dụng mã"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Hủy không thành công"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Không thể tải video"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Không thể lấy phiên hoạt động"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Không thể lấy bản gốc để chỉnh sửa"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Không thể lấy thông tin giới thiệu. Vui lòng thử lại sau."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Không thể tải album"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Không thể phát video"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage("Không thể làm mới đăng ký"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Gia hạn không thành công"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Không thể xác minh trạng thái thanh toán"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Thêm 5 thành viên gia đình vào gói hiện tại của bạn mà không phải trả thêm phí.\n\nMỗi thành viên có không gian riêng tư của mình và không thể xem tệp của nhau trừ khi được chia sẻ.\n\nGói gia đình có sẵn cho khách hàng có đăng ký Ente trả phí.\n\nĐăng ký ngay để bắt đầu!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Gia đình"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Gói gia đình"),
        "faq": MessageLookupByLibrary.simpleMessage("Câu hỏi thường gặp"),
        "faqs": MessageLookupByLibrary.simpleMessage("Câu hỏi thường gặp"),
        "favorite": MessageLookupByLibrary.simpleMessage("Yêu thích"),
        "feedback": MessageLookupByLibrary.simpleMessage("Phản hồi"),
        "file": MessageLookupByLibrary.simpleMessage("Tệp"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Không thể lưu tệp vào thư viện"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Thêm mô tả..."),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("Tệp chưa được tải lên"),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Tệp đã được lưu vào thư viện"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Loại tệp"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Loại tệp và tên"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("Tệp đã bị xóa"),
        "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Các tệp đã được lưu vào thư viện"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Tìm người nhanh chóng theo tên"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("Tìm họ nhanh chóng"),
        "flip": MessageLookupByLibrary.simpleMessage("Lật"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("cho những kỷ niệm của bạn"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage("Quên mật khẩu"),
        "foundFaces":
            MessageLookupByLibrary.simpleMessage("Đã tìm thấy khuôn mặt"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Lưu trữ miễn phí đã yêu cầu"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Lưu trữ miễn phí có thể sử dụng"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Dùng thử miễn phí"),
        "freeTrialValidTill": m38,
        "freeUpAmount": m40,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Giải phóng không gian thiết bị"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Tiết kiệm không gian trên thiết bị của bạn bằng cách xóa các tệp đã được sao lưu."),
        "freeUpSpace":
            MessageLookupByLibrary.simpleMessage("Giải phóng không gian"),
        "freeUpSpaceSaving": m41,
        "gallery": MessageLookupByLibrary.simpleMessage("Thư viện"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Tối đa 1000 kỷ niệm được hiển thị trong thư viện"),
        "general": MessageLookupByLibrary.simpleMessage("Chung"),
        "generatingEncryptionKeys":
            MessageLookupByLibrary.simpleMessage("Đang tạo khóa mã hóa..."),
        "genericProgress": m42,
        "goToSettings": MessageLookupByLibrary.simpleMessage("Đi đến cài đặt"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("ID Google Play"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Vui lòng cho phép truy cập vào tất cả ảnh trong ứng dụng Cài đặt"),
        "grantPermission": MessageLookupByLibrary.simpleMessage("Cấp quyền"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("Nhóm ảnh gần đó"),
        "guestView": MessageLookupByLibrary.simpleMessage("Chế độ khách"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Để bật chế độ khách, vui lòng thiết lập mã khóa thiết bị hoặc khóa màn hình trong cài đặt hệ thống của bạn."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Chúng tôi không theo dõi cài đặt ứng dụng. Sẽ rất hữu ích nếu bạn cho chúng tôi biết bạn đã tìm thấy chúng ở đâu!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Bạn đã nghe về Ente từ đâu? (tùy chọn)"),
        "help": MessageLookupByLibrary.simpleMessage("Trợ giúp"),
        "hidden": MessageLookupByLibrary.simpleMessage("Ẩn"),
        "hide": MessageLookupByLibrary.simpleMessage("Ẩn"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Ẩn nội dung"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Ẩn nội dung ứng dụng trong trình chuyển đổi ứng dụng và vô hiệu hóa chụp màn hình"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Ẩn nội dung ứng dụng trong trình chuyển đổi ứng dụng"),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "Ẩn các mục được chia sẻ khỏi thư viện chính"),
        "hiding": MessageLookupByLibrary.simpleMessage("Đang ẩn..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Được lưu trữ tại OSM Pháp"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Cách hoạt động"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Vui lòng yêu cầu họ nhấn giữ địa chỉ email của họ trên màn hình cài đặt, và xác minh rằng các ID trên cả hai thiết bị khớp nhau."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Xác thực sinh trắc học chưa được thiết lập trên thiết bị của bạn. Vui lòng kích hoạt Touch ID hoặc Face ID trên điện thoại của bạn."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "Xác thực sinh trắc học đã bị vô hiệu hóa. Vui lòng khóa và mở khóa màn hình của bạn để kích hoạt lại."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Bỏ qua"),
        "ignored": MessageLookupByLibrary.simpleMessage("bỏ qua"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Một số tệp trong album này bị bỏ qua khi tải lên vì chúng đã bị xóa trước đó từ Ente."),
        "imageNotAnalyzed": MessageLookupByLibrary.simpleMessage(
            "Hình ảnh chưa được phân tích"),
        "immediately": MessageLookupByLibrary.simpleMessage("Ngay lập tức"),
        "importing": MessageLookupByLibrary.simpleMessage("Đang nhập...."),
        "incorrectCode":
            MessageLookupByLibrary.simpleMessage("Mã không chính xác"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Mật khẩu không chính xác"),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Khóa khôi phục không chính xác"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Khóa khôi phục bạn nhập không chính xác"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Khóa khôi phục không chính xác"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Các mục đã lập chỉ mục"),
        "info": MessageLookupByLibrary.simpleMessage("Thông tin"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Thiết bị không an toàn"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Cài đặt thủ công"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Địa chỉ email không hợp lệ"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Điểm cuối không hợp lệ"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Xin lỗi, điểm cuối bạn nhập không hợp lệ. Vui lòng nhập một điểm cuối hợp lệ và thử lại."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Khóa không hợp lệ"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Khóa khôi phục bạn nhập không hợp lệ. Vui lòng đảm bảo nó chứa 24 từ, và kiểm tra chính tả của từng từ.\n\nNếu bạn đã nhập mã khôi phục cũ, hãy đảm bảo nó dài 64 ký tự, và kiểm tra từng ký tự."),
        "invite": MessageLookupByLibrary.simpleMessage("Mời"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Mời đến Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Mời bạn bè của bạn"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Mời bạn bè của bạn đến Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Có vẻ như đã xảy ra sự cố. Vui lòng thử lại sau một thời gian. Nếu lỗi vẫn tiếp diễn, vui lòng liên hệ với đội ngũ hỗ trợ của chúng tôi."),
        "itemCount": m44,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Các mục cho biết số ngày còn lại trước khi xóa vĩnh viễn"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Các mục đã chọn sẽ bị xóa khỏi album này"),
        "join": MessageLookupByLibrary.simpleMessage("Tham gia"),
        "joinAlbum": MessageLookupByLibrary.simpleMessage("Tham gia album"),
        "joinAlbumSubtext":
            MessageLookupByLibrary.simpleMessage("để xem và thêm ảnh của bạn"),
        "joinAlbumSubtextViewer":
            MessageLookupByLibrary.simpleMessage("thêm vào album được chia sẻ"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("Tham gia Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Giữ ảnh"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Vui lòng giúp chúng tôi với thông tin này"),
        "language": MessageLookupByLibrary.simpleMessage("Ngôn ngữ"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Cập nhật lần cuối"),
        "leave": MessageLookupByLibrary.simpleMessage("Rời"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Rời khỏi album"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Rời khỏi gia đình"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Rời khỏi album chia sẻ?"),
        "left": MessageLookupByLibrary.simpleMessage("Trái"),
        "legacy": MessageLookupByLibrary.simpleMessage("Thừa kế"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Tài khoản thừa kế"),
        "legacyInvite": m46,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "Thừa kế cho phép các liên hệ tin cậy truy cập tài khoản của bạn khi bạn không hoạt động."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Các liên hệ tin cậy có thể khởi động quá trình khôi phục tài khoản, và nếu không bị chặn trong vòng 30 ngày, có thể đặt lại mật khẩu và truy cập tài khoản của bạn."),
        "light": MessageLookupByLibrary.simpleMessage("Ánh sáng"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Sáng"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Liên kết đã được sao chép vào clipboard"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Giới hạn thiết bị"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Đã bật"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Hết hạn"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Hết hạn liên kết"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Liên kết đã hết hạn"),
        "linkNeverExpires":
            MessageLookupByLibrary.simpleMessage("Không bao giờ"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("Ảnh trực tiếp"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Bạn có thể chia sẻ đăng ký của mình với gia đình"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Chúng tôi giữ 3 bản sao dữ liệu của bạn, một trong nơi trú ẩn dưới lòng đất"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Tất cả các ứng dụng của chúng tôi đều là mã nguồn mở"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Mã nguồn và mật mã của chúng tôi đã được kiểm toán bên ngoài"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Bạn có thể chia sẻ liên kết đến album của mình với những người thân yêu"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Các ứng dụng di động của chúng tôi chạy ngầm để mã hóa và sao lưu bất kỳ ảnh mới nào bạn chụp"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io có một trình tải lên mượt mà"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Chúng tôi sử dụng Xchacha20Poly1305 để mã hóa dữ liệu của bạn một cách an toàn"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Đang tải dữ liệu EXIF..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Đang tải thư viện..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Đang tải ảnh của bạn..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Đang tải mô hình..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Đang tải ảnh của bạn..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Thư viện cục bộ"),
        "localIndexing": MessageLookupByLibrary.simpleMessage("Chỉ mục cục bộ"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Có vẻ như có điều gì đó không ổn vì đồng bộ hóa ảnh cục bộ đang mất nhiều thời gian hơn mong đợi. Vui lòng liên hệ với đội ngũ hỗ trợ của chúng tôi"),
        "location": MessageLookupByLibrary.simpleMessage("Vị trí"),
        "locationName": MessageLookupByLibrary.simpleMessage("Tên vị trí"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Một thẻ vị trí nhóm tất cả các ảnh được chụp trong một bán kính nào đó của một bức ảnh"),
        "locations": MessageLookupByLibrary.simpleMessage("Vị trí"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Khóa"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Màn hình khóa"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Đăng nhập"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Đang đăng xuất..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Phiên đăng nhập đã hết hạn"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Phiên đăng nhập của bạn đã hết hạn. Vui lòng đăng nhập lại."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Bằng cách nhấp vào đăng nhập, tôi đồng ý với <u-terms>các điều khoản dịch vụ</u-terms> và <u-policy>chính sách bảo mật</u-policy>"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("Login with TOTP"),
        "logout": MessageLookupByLibrary.simpleMessage("Đăng xuất"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Điều này sẽ gửi nhật ký để giúp chúng tôi gỡ lỗi vấn đề của bạn. Vui lòng lưu ý rằng tên tệp sẽ được bao gồm để giúp theo dõi các vấn đề với các tệp cụ thể."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Nhấn giữ một email để xác minh mã hóa đầu cuối."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Nhấn và giữ vào một mục để xem toàn màn hình"),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("Dừng phát video lặp lại"),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("Phát video lặp lại"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Mất thiết bị?"),
        "machineLearning": MessageLookupByLibrary.simpleMessage("Học máy"),
        "magicSearch":
            MessageLookupByLibrary.simpleMessage("Tìm kiếm ma thuật"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "Tìm kiếm ma thuật cho phép tìm kiếm ảnh theo nội dung của chúng, ví dụ: \'hoa\', \'xe hơi đỏ\', \'tài liệu nhận dạng\'"),
        "manage": MessageLookupByLibrary.simpleMessage("Quản lý"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Quản lý bộ nhớ đệm của thiết bị"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Review and clear local cache storage."),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Quản lý gia đình"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Quản lý liên kết"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Quản lý"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Quản lý đăng ký"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Ghép nối với PIN hoạt động với bất kỳ màn hình nào bạn muốn xem album của mình."),
        "map": MessageLookupByLibrary.simpleMessage("Map"),
        "maps": MessageLookupByLibrary.simpleMessage("Bản đồ"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "merchandise": MessageLookupByLibrary.simpleMessage("Merchandise"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Hợp nhất với người đã có"),
        "mergedPhotos": MessageLookupByLibrary.simpleMessage("Hợp nhất ảnh"),
        "mlConsent": MessageLookupByLibrary.simpleMessage("Kích hoạt học máy"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Tôi hiểu và muốn kích hoạt học máy"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Nếu bạn kích hoạt học máy, Ente sẽ trích xuất thông tin như hình dạng khuôn mặt từ các tệp, bao gồm cả những tệp được chia sẻ với bạn.\n\nĐiều này sẽ xảy ra trên thiết bị của bạn, và bất kỳ thông tin sinh trắc học nào được tạo ra sẽ được mã hóa đầu cuối."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Vui lòng nhấp vào đây để biết thêm chi tiết về tính năng này trong chính sách quyền riêng tư của chúng tôi"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("Kích hoạt học máy?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Xin lưu ý rằng việc học máy sẽ dẫn đến việc sử dụng băng thông và pin cao hơn cho đến khi tất cả các mục được lập chỉ mục. Hãy xem xét việc sử dụng ứng dụng máy tính để bàn để lập chỉ mục nhanh hơn, tất cả kết quả sẽ được đồng bộ hóa tự động."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Di động, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Vừa phải"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Chỉnh sửa truy vấn của bạn, hoặc thử tìm kiếm cho"),
        "moments": MessageLookupByLibrary.simpleMessage("Khoảnh khắc"),
        "month": MessageLookupByLibrary.simpleMessage("tháng"),
        "monthly": MessageLookupByLibrary.simpleMessage("Hàng tháng"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Thêm chi tiết"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Mới nhất"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Liên quan nhất"),
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Chuyển đến album"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Di chuyển đến album ẩn"),
        "movedSuccessfullyTo": m52,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Đã chuyển vào thùng rác"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Đang di chuyển tệp vào album..."),
        "name": MessageLookupByLibrary.simpleMessage("Tên"),
        "nameTheAlbum":
            MessageLookupByLibrary.simpleMessage("Đặt tên cho album"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Không thể kết nối với Ente, vui lòng thử lại sau một thời gian. Nếu lỗi vẫn tiếp diễn, vui lòng liên hệ với bộ phận hỗ trợ."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Không thể kết nối với Ente, vui lòng kiểm tra cài đặt mạng của bạn và liên hệ với bộ phận hỗ trợ nếu lỗi vẫn tiếp diễn."),
        "never": MessageLookupByLibrary.simpleMessage("Không bao giờ"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Album mới"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Vị trí mới"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Người mới"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Mới đến Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Mới nhất"),
        "next": MessageLookupByLibrary.simpleMessage("Tiếp theo"),
        "no": MessageLookupByLibrary.simpleMessage("Không"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Chưa có album nào được chia sẻ bởi bạn"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Không tìm thấy thiết bị"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Không có"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Bạn không có tệp nào trên thiết bị này có thể bị xóa"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Không có trùng lặp"),
        "noExifData":
            MessageLookupByLibrary.simpleMessage("Không có dữ liệu EXIF"),
        "noFacesFound":
            MessageLookupByLibrary.simpleMessage("Không tìm thấy khuôn mặt"),
        "noHiddenPhotosOrVideos":
            MessageLookupByLibrary.simpleMessage("Không có ảnh hoặc video ẩn"),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
            "Không có hình ảnh với vị trí"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Không có kết nối internet"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Hiện tại không có ảnh nào đang được sao lưu"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("Không tìm thấy ảnh ở đây"),
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
            "Không có liên kết nhanh nào được chọn"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Không có khóa khôi phục?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Do tính chất của giao thức mã hóa đầu cuối của chúng tôi, dữ liệu của bạn không thể được giải mã mà không có mật khẩu hoặc khóa khôi phục của bạn"),
        "noResults": MessageLookupByLibrary.simpleMessage("Không có kết quả"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Không tìm thấy kết quả"),
        "noSuggestionsForPerson": m53,
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
            "Không tìm thấy khóa hệ thống"),
        "notPersonLabel": m54,
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Chưa có gì được chia sẻ với bạn"),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
            "Không có gì để xem ở đây! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Thông báo"),
        "ok": MessageLookupByLibrary.simpleMessage("Được"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Trên thiết bị"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Trên <branding>ente</branding>"),
        "onlyFamilyAdminCanChangeCode": m55,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Chỉ họ"),
        "oops": MessageLookupByLibrary.simpleMessage("Ôi"),
        "oopsCouldNotSaveEdits":
            MessageLookupByLibrary.simpleMessage("Ôi, không thể lưu chỉnh sửa"),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
            "Ôi, có điều gì đó không đúng"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("Mở album trong trình duyệt"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Vui lòng sử dụng ứng dụng web để thêm ảnh vào album này"),
        "openFile": MessageLookupByLibrary.simpleMessage("Mở tệp"),
        "openSettings": MessageLookupByLibrary.simpleMessage("Mở Cài đặt"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Mở mục"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("Nhà đóng góp OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Tùy chọn, ngắn như bạn muốn..."),
        "orMergeWithExistingPerson":
            MessageLookupByLibrary.simpleMessage("Hoặc hợp nhất với hiện có"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Hoặc chọn một cái có sẵn"),
        "pair": MessageLookupByLibrary.simpleMessage("Ghép nối"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("Ghép nối với PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Ghép nối hoàn tất"),
        "panorama": MessageLookupByLibrary.simpleMessage("Toàn cảnh"),
        "passKeyPendingVerification":
            MessageLookupByLibrary.simpleMessage("Xác minh vẫn đang chờ"),
        "passkey": MessageLookupByLibrary.simpleMessage("Mã khóa"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Xác minh mã khóa"),
        "password": MessageLookupByLibrary.simpleMessage("Mật khẩu"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Đã thay đổi mật khẩu thành công"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Khóa bằng mật khẩu"),
        "passwordStrength": m57,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "Độ mạnh của mật khẩu được tính toán dựa trên độ dài của mật khẩu, các ký tự đã sử dụng và liệu mật khẩu có xuất hiện trong 10.000 mật khẩu được sử dụng nhiều nhất hay không"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Chúng tôi không lưu trữ mật khẩu này, vì vậy nếu bạn quên, <underline>chúng tôi không thể giải mã dữ liệu của bạn</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Chi tiết thanh toán"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Thanh toán thất bại"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Rất tiếc, thanh toán của bạn đã thất bại. Vui lòng liên hệ với bộ phận hỗ trợ và chúng tôi sẽ giúp bạn!"),
        "paymentFailedTalkToProvider": m58,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Các mục đang chờ"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Đồng bộ hóa đang chờ"),
        "people": MessageLookupByLibrary.simpleMessage("Người"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("Người dùng mã của bạn"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Tất cả các mục trong thùng rác sẽ bị xóa vĩnh viễn\n\nHành động này không thể hoàn tác"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Xóa vĩnh viễn"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Xóa vĩnh viễn khỏi thiết bị?"),
        "personName": MessageLookupByLibrary.simpleMessage("Tên người"),
        "photoDescriptions": MessageLookupByLibrary.simpleMessage("Mô tả ảnh"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Kích thước lưới ảnh"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("ảnh"),
        "photos": MessageLookupByLibrary.simpleMessage("Ảnh"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Ảnh bạn đã thêm sẽ bị xóa khỏi album"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Chọn điểm trung tâm"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Ghim album"),
        "pinLock": MessageLookupByLibrary.simpleMessage("Khóa PIN"),
        "playOnTv": MessageLookupByLibrary.simpleMessage("Phát album trên TV"),
        "playStoreFreeTrialValidTill": m63,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Đăng ký PlayStore"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Vui lòng kiểm tra kết nối internet của bạn và thử lại."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Vui lòng liên hệ với support@ente.io và chúng tôi sẽ rất vui lòng giúp đỡ!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Vui lòng liên hệ với bộ phận hỗ trợ nếu vấn đề vẫn tiếp diễn"),
        "pleaseEmailUsAt": m64,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Vui lòng cấp quyền"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Vui lòng đăng nhập lại"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Vui lòng chọn liên kết nhanh để xóa"),
        "pleaseSendTheLogsTo": m65,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Vui lòng thử lại"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Vui lòng xác minh mã bạn đã nhập"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Vui lòng chờ..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Vui lòng chờ, đang xóa album"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Vui lòng chờ một thời gian trước khi thử lại"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Đang chuẩn bị nhật ký..."),
        "preserveMore":
            MessageLookupByLibrary.simpleMessage("Lưu giữ nhiều hơn"),
        "pressAndHoldToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Nhấn và giữ để phát video"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Nhấn và giữ vào hình ảnh để phát video"),
        "privacy": MessageLookupByLibrary.simpleMessage("Quyền riêng tư"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Chính sách bảo mật"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Sao lưu riêng tư"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Chia sẻ riêng tư"),
        "proceed": MessageLookupByLibrary.simpleMessage("Tiếp tục"),
        "processed": MessageLookupByLibrary.simpleMessage("Đã xử lý"),
        "processingImport": m67,
        "publicLinkCreated": MessageLookupByLibrary.simpleMessage(
            "Liên kết công khai đã được tạo"),
        "publicLinkEnabled": MessageLookupByLibrary.simpleMessage(
            "Liên kết công khai đã được kích hoạt"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Liên kết nhanh"),
        "radius": MessageLookupByLibrary.simpleMessage("Bán kính"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Tạo vé"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Đánh giá ứng dụng"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Đánh giá chúng tôi"),
        "rateUsOnStore": m68,
        "recover": MessageLookupByLibrary.simpleMessage("Khôi phục"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Khôi phục tài khoản"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Khôi phục"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Khôi phục tài khoản"),
        "recoveryInitiated": MessageLookupByLibrary.simpleMessage(
            "Quá trình khôi phục đã được khởi động"),
        "recoveryInitiatedDesc": m70,
        "recoveryKey": MessageLookupByLibrary.simpleMessage("Khóa khôi phục"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Khóa khôi phục đã được sao chép vào clipboard"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Nếu bạn quên mật khẩu, cách duy nhất để khôi phục dữ liệu của bạn là với khóa này."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Chúng tôi không lưu trữ khóa này, vui lòng lưu khóa 24 từ này ở một nơi an toàn."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Tuyệt vời! Khóa khôi phục của bạn hợp lệ. Cảm ơn bạn đã xác minh.\n\nVui lòng nhớ giữ khóa khôi phục của bạn được sao lưu an toàn."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Khóa khôi phục đã được xác minh"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Khóa khôi phục của bạn là cách duy nhất để khôi phục ảnh của bạn nếu bạn quên mật khẩu. Bạn có thể tìm thấy khóa khôi phục của mình trong Cài đặt > Tài khoản.\n\nVui lòng nhập khóa khôi phục của bạn ở đây để xác minh rằng bạn đã lưu nó đúng cách."),
        "recoveryReady": m71,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Khôi phục thành công!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "Một liên hệ tin cậy đang cố gắng truy cập tài khoản của bạn"),
        "recoveryWarningBody": m72,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Thiết bị hiện tại không đủ mạnh để xác minh mật khẩu của bạn, nhưng chúng tôi có thể tạo lại theo cách hoạt động với tất cả các thiết bị.\n\nVui lòng đăng nhập bằng khóa khôi phục của bạn và tạo lại mật khẩu (bạn có thể sử dụng lại mật khẩu cũ nếu muốn)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Tạo lại mật khẩu"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Nhập lại mật khẩu"),
        "reenterPin": MessageLookupByLibrary.simpleMessage("Nhập lại PIN"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Giới thiệu bạn bè và gấp đôi gói của bạn"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Đưa mã này cho bạn bè của bạn"),
        "referralStep2":
            MessageLookupByLibrary.simpleMessage("2. Họ đăng ký gói trả phí"),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("Giới thiệu"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Giới thiệu hiện đang tạm dừng"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Từ chối khôi phục"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Cũng hãy xóa \"Đã xóa gần đây\" từ \"Cài đặt\" -> \"Lưu trữ\" để chiếm không gian đã giải phóng"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Cũng hãy xóa \"Thùng rác\" của bạn để chiếm không gian đã giải phóng"),
        "remoteImages": MessageLookupByLibrary.simpleMessage("Hình ảnh từ xa"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Hình thu nhỏ từ xa"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Video từ xa"),
        "remove": MessageLookupByLibrary.simpleMessage("Xóa"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Xóa trùng lặp"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Xem xét và xóa các tệp là bản sao chính xác."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Xóa khỏi album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Xóa khỏi album?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Xóa khỏi yêu thích"),
        "removeInvite": MessageLookupByLibrary.simpleMessage("Gỡ bỏ lời mời"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Xóa liên kết"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Xóa người tham gia"),
        "removeParticipantBody": m74,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Xóa nhãn người"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Xóa liên kết công khai"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Xóa liên kết công khai"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Một số mục bạn đang xóa đã được thêm bởi người khác, và bạn sẽ mất quyền truy cập vào chúng"),
        "removeWithQuestionMark": MessageLookupByLibrary.simpleMessage("Xóa?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Gỡ bỏ bạn khỏi liên hệ tin cậy"),
        "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
            "Đang xóa khỏi mục yêu thích..."),
        "rename": MessageLookupByLibrary.simpleMessage("Đổi tên"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Đổi tên album"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Đổi tên tệp"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Gia hạn đăng ký"),
        "renewsOn": m75,
        "reportABug": MessageLookupByLibrary.simpleMessage("Báo cáo lỗi"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Báo cáo lỗi"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Gửi lại email"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("Đặt lại các tệp bị bỏ qua"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Đặt lại mật khẩu"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Đặt lại người"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Đặt lại về mặc định"),
        "restore": MessageLookupByLibrary.simpleMessage("Khôi phục"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Khôi phục vào album"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Đang khôi phục tệp..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("Tải lên có thể tiếp tục"),
        "retry": MessageLookupByLibrary.simpleMessage("Thử lại"),
        "review": MessageLookupByLibrary.simpleMessage("Xem lại"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Vui lòng xem xét và xóa các mục mà bạn cho là trùng lặp."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Xem xét gợi ý"),
        "right": MessageLookupByLibrary.simpleMessage("Phải"),
        "rotate": MessageLookupByLibrary.simpleMessage("Xoay"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Xoay trái"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Xoay phải"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("Lưu trữ an toàn"),
        "save": MessageLookupByLibrary.simpleMessage("Lưu"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Lưu ảnh ghép"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Lưu bản sao"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Lưu khóa"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Lưu người"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Lưu khóa khôi phục của bạn nếu bạn chưa làm"),
        "saving": MessageLookupByLibrary.simpleMessage("Đang lưu..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Đang lưu chỉnh sửa..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Quét mã"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Quét mã vạch này bằng\ntới ứng dụng xác thực của bạn"),
        "search": MessageLookupByLibrary.simpleMessage("Tìm kiếm"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Album"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Tên album"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Tên album (ví dụ: \"Camera\")\n• Loại tệp (ví dụ: \"Video\", \".gif\")\n• Năm và tháng (ví dụ: \"2022\", \"Tháng Một\")\n• Ngày lễ (ví dụ: \"Giáng Sinh\")\n• Mô tả ảnh (ví dụ: “#vui”)"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Thêm mô tả như \"#chuyến đi\" trong thông tin ảnh để nhanh chóng tìm thấy chúng ở đây"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Tìm kiếm theo ngày, tháng hoặc năm"),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "Hình ảnh sẽ được hiển thị ở đây sau khi hoàn tất xử lý và đồng bộ"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Người sẽ được hiển thị ở đây khi việc lập chỉ mục hoàn tất"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Loại tệp và tên"),
        "searchHint1": MessageLookupByLibrary.simpleMessage(
            "Tìm kiếm nhanh, trên thiết bị"),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("Ngày tháng, mô tả ảnh"),
        "searchHint3":
            MessageLookupByLibrary.simpleMessage("Album, tên tệp và loại"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Vị trí"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Sắp có: Nhận diện khuôn mặt & tìm kiếm ma thuật ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Nhóm ảnh được chụp trong một bán kính nào đó của một bức ảnh"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Mời mọi người, và bạn sẽ thấy tất cả ảnh được chia sẻ bởi họ ở đây"),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "Người sẽ được hiển thị ở đây sau khi hoàn tất xử lý và đồng bộ"),
        "searchResultCount": m77,
        "searchSectionsLengthMismatch": m78,
        "security": MessageLookupByLibrary.simpleMessage("Bảo mật"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "Xem liên kết album công khai trong ứng dụng"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Chọn một vị trí"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Chọn một vị trí trước"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Chọn album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Chọn tất cả"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Tất cả"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Chọn ảnh bìa"),
        "selectFoldersForBackup":
            MessageLookupByLibrary.simpleMessage("Chọn thư mục để sao lưu"),
        "selectItemsToAdd":
            MessageLookupByLibrary.simpleMessage("Chọn mục để thêm"),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("Chọn ngôn ngữ"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Chọn ứng dụng email"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Chọn thêm ảnh"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Chọn lý do"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Chọn gói của bạn"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Các tệp đã chọn không có trên Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Các thư mục đã chọn sẽ được mã hóa và sao lưu"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Các mục đã chọn sẽ bị xóa khỏi tất cả các album và chuyển vào thùng rác."),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "send": MessageLookupByLibrary.simpleMessage("Gửi"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Gửi email"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Gửi lời mời"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Gửi liên kết"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Điểm cuối máy chủ"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Phiên đã hết hạn"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Mã phiên không khớp"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Đặt mật khẩu"),
        "setAs": MessageLookupByLibrary.simpleMessage("Đặt làm"),
        "setCover": MessageLookupByLibrary.simpleMessage("Đặt ảnh bìa"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Đặt"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Đặt mật khẩu mới"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("Đặt PIN mới"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Đặt mật khẩu"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Đặt bán kính"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Cài đặt hoàn tất"),
        "share": MessageLookupByLibrary.simpleMessage("Chia sẻ"),
        "shareALink":
            MessageLookupByLibrary.simpleMessage("Chia sẻ một liên kết"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Mở album và nhấn nút chia sẻ ở góc trên bên phải để chia sẻ."),
        "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage(
            "Chia sẻ một album ngay bây giờ"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Chia sẻ liên kết"),
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Chia sẻ chỉ với những người bạn muốn"),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Tải Ente để chúng ta có thể dễ dàng chia sẻ ảnh và video chất lượng gốc\n\nhttps://ente.io"),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Chia sẻ với người dùng không phải Ente"),
        "shareWithPeopleSectionTitle": m86,
        "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
            "Chia sẻ album đầu tiên của bạn"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Tạo album chia sẻ và hợp tác với các người dùng Ente khác, bao gồm cả người dùng trên các gói miễn phí."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Chia sẻ bởi tôi"),
        "sharedByYou":
            MessageLookupByLibrary.simpleMessage("Được chia sẻ bởi bạn"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Ảnh chia sẻ mới"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Nhận thông báo khi ai đó thêm ảnh vào album chia sẻ mà bạn tham gia"),
        "sharedWith": m87,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("Chia sẻ với tôi"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Được chia sẻ với bạn"),
        "sharing": MessageLookupByLibrary.simpleMessage("Chia sẻ..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Hiển thị kỷ niệm"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Hiện người"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Đăng xuất từ các thiết bị khác"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Nếu bạn nghĩ rằng ai đó có thể biết mật khẩu của bạn, bạn có thể buộc tất cả các thiết bị khác đang sử dụng tài khoản của bạn đăng xuất."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Đăng xuất các thiết bị khác"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Tôi đồng ý với <u-terms>các điều khoản dịch vụ</u-terms> và <u-policy>chính sách bảo mật</u-policy>"),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Nó sẽ bị xóa khỏi tất cả các album."),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("Bỏ qua"),
        "social": MessageLookupByLibrary.simpleMessage("Xã hội"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Một số mục có trên cả Ente và thiết bị của bạn."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Một số tệp bạn đang cố gắng xóa chỉ có trên thiết bị của bạn và không thể khôi phục nếu bị xóa"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Ai đó chia sẻ album với bạn nên thấy cùng một ID trên thiết bị của họ."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Có điều gì đó không đúng"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Có gì đó không ổn, vui lòng thử lại"),
        "sorry": MessageLookupByLibrary.simpleMessage("Xin lỗi"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Xin lỗi, không thể thêm vào mục yêu thích!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Xin lỗi, không thể xóa khỏi mục yêu thích!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Xin lỗi, mã bạn đã nhập không chính xác"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Xin lỗi, chúng tôi không thể tạo khóa an toàn trên thiết bị này.\n\nVui lòng đăng ký từ một thiết bị khác."),
        "sort": MessageLookupByLibrary.simpleMessage("Sắp xếp"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sắp xếp theo"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Mới nhất trước"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Cũ nhất trước"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Thành công"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Bắt đầu khôi phục"),
        "startBackup": MessageLookupByLibrary.simpleMessage("Bắt đầu sao lưu"),
        "status": MessageLookupByLibrary.simpleMessage("Trạng thái"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Bạn có muốn dừng phát không?"),
        "stopCastingTitle": MessageLookupByLibrary.simpleMessage("Dừng phát"),
        "storage": MessageLookupByLibrary.simpleMessage("Lưu trữ"),
        "storageBreakupFamily":
            MessageLookupByLibrary.simpleMessage("Gia đình"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Bạn"),
        "storageInGB": m93,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Vượt quá giới hạn lưu trữ"),
        "storageUsageInfo": m94,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Mạnh"),
        "subAlreadyLinkedErrMessage": m95,
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("Đăng ký"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Bạn cần một đăng ký trả phí hoạt động để kích hoạt chia sẻ."),
        "subscription": MessageLookupByLibrary.simpleMessage("Đăng ký"),
        "success": MessageLookupByLibrary.simpleMessage("Thành công"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Lưu trữ thành công"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Đã ẩn thành công"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Khôi phục thành công"),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("Đã hiện thành công"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Gợi ý tính năng"),
        "support": MessageLookupByLibrary.simpleMessage("Hỗ trợ"),
        "syncProgress": m97,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Đồng bộ hóa đã dừng"),
        "syncing": MessageLookupByLibrary.simpleMessage("Đang đồng bộ hóa..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Hệ thống"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("chạm để sao chép"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Chạm để nhập mã"),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage("Nhấn để mở khóa"),
        "tapToUpload": MessageLookupByLibrary.simpleMessage("Nhấn để tải lên"),
        "tapToUploadIsIgnoredDue": m98,
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Có vẻ như đã xảy ra sự cố. Vui lòng thử lại sau một thời gian. Nếu lỗi vẫn tiếp diễn, vui lòng liên hệ với đội ngũ hỗ trợ."),
        "terminate": MessageLookupByLibrary.simpleMessage("Kết thúc"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Kết thúc phiên? "),
        "terms": MessageLookupByLibrary.simpleMessage("Điều khoản"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Điều khoản"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Cảm ơn bạn"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("Cảm ơn bạn đã đăng ký!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Tải xuống không thể hoàn tất"),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "Liên kết bạn đang cố gắng truy cập đã hết hạn."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Khóa khôi phục bạn đã nhập không chính xác"),
        "theme": MessageLookupByLibrary.simpleMessage("Chủ đề"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Các mục này sẽ bị xóa khỏi thiết bị của bạn."),
        "theyAlsoGetXGb": m99,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Chúng sẽ bị xóa khỏi tất cả các album."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Hành động này không thể hoàn tác"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Album này đã có một liên kết hợp tác"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Điều này có thể được sử dụng để khôi phục tài khoản của bạn nếu bạn mất yếu tố thứ hai"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Thiết bị này"),
        "thisEmailIsAlreadyInUse":
            MessageLookupByLibrary.simpleMessage("Email này đã được sử dụng"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Hình ảnh này không có dữ liệu exif"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("Đây là ID xác minh của bạn"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Điều này sẽ đăng xuất bạn khỏi thiết bị sau:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Điều này sẽ đăng xuất bạn khỏi thiết bị này!"),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Điều này sẽ xóa liên kết công khai của tất cả các liên kết nhanh đã chọn."),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Để bật khóa ứng dụng, vui lòng thiết lập mã khóa thiết bị hoặc khóa màn hình trong cài đặt hệ thống của bạn."),
        "toHideAPhotoOrVideo":
            MessageLookupByLibrary.simpleMessage("Để ẩn một ảnh hoặc video"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Để đặt lại mật khẩu của bạn, vui lòng xác minh email của bạn trước."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Nhật ký hôm nay"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
            "Quá nhiều lần thử không chính xác"),
        "total": MessageLookupByLibrary.simpleMessage("tổng"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Tổng kích thước"),
        "trash": MessageLookupByLibrary.simpleMessage("Thùng rác"),
        "trashDaysLeft": m103,
        "trim": MessageLookupByLibrary.simpleMessage("Cắt"),
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Liên hệ tin cậy"),
        "trustedInviteBody": m106,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Thử lại"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Bật sao lưu để tự động tải lên các tệp được thêm vào thư mục thiết bị này lên Ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 tháng miễn phí cho các gói hàng năm"),
        "twofactor":
            MessageLookupByLibrary.simpleMessage("Xác thực hai yếu tố"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "Xác thực hai yếu tố đã bị vô hiệu hóa"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Xác thực hai yếu tố"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Xác thực hai yếu tố đã được đặt lại thành công"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Cài đặt hai yếu tố"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
        "unarchive": MessageLookupByLibrary.simpleMessage("Khôi phục"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Khôi phục album"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Đang khôi phục..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Xin lỗi, mã này không khả dụng."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Chưa phân loại"),
        "unhide": MessageLookupByLibrary.simpleMessage("Hiện lại"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Hiện lại vào album"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Đang hiện..."),
        "unhidingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Đang hiện lại tệp vào album"),
        "unlock": MessageLookupByLibrary.simpleMessage("Mở khóa"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Bỏ ghim album"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Bỏ chọn tất cả"),
        "update": MessageLookupByLibrary.simpleMessage("Cập nhật"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Cập nhật có sẵn"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Đang cập nhật lựa chọn thư mục..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Nâng cấp"),
        "uploadIsIgnoredDueToIgnorereason": m108,
        "uploadingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Đang tải tệp lên album..."),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Đang lưu giữ 1 kỷ niệm..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Giảm tới 50%, đến ngày 4 tháng 12."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Lưu trữ có thể sử dụng bị giới hạn bởi gói hiện tại của bạn. Lưu trữ đã yêu cầu vượt quá sẽ tự động trở thành có thể sử dụng khi bạn nâng cấp gói của mình."),
        "useAsCover": MessageLookupByLibrary.simpleMessage("Sử dụng làm bìa"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "Phát video gặp vấn đề? Ấn giữ tại đây để thử một trình phát khác."),
        "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Sử dụng liên kết công khai cho những người không có trên Ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Sử dụng khóa khôi phục"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Sử dụng ảnh đã chọn"),
        "usedSpace":
            MessageLookupByLibrary.simpleMessage("Không gian đã sử dụng"),
        "validTill": m110,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Xác minh không thành công, vui lòng thử lại"),
        "verificationId": MessageLookupByLibrary.simpleMessage("ID xác minh"),
        "verify": MessageLookupByLibrary.simpleMessage("Xác minh"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Xác minh email"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Xác minh"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Xác minh mã khóa"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Xác minh mật khẩu"),
        "verifying": MessageLookupByLibrary.simpleMessage("Đang xác minh..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Đang xác minh khóa khôi phục..."),
        "videoInfo": MessageLookupByLibrary.simpleMessage("Thông tin video"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "videos": MessageLookupByLibrary.simpleMessage("Video"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Xem phiên hoạt động"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Xem tiện ích mở rộng"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Xem tất cả"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Xem tất cả dữ liệu EXIF"),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Tệp lớn"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Xem các tệp đang tiêu tốn nhiều dung lượng lưu trữ nhất."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Xem nhật ký"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Xem khóa khôi phục"),
        "viewer": MessageLookupByLibrary.simpleMessage("Người xem"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Vui lòng truy cập web.ente.io để quản lý đăng ký của bạn"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Đang chờ xác minh..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Đang chờ WiFi..."),
        "warning": MessageLookupByLibrary.simpleMessage("Cảnh báo"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Chúng tôi là mã nguồn mở!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Chúng tôi không hỗ trợ chỉnh sửa ảnh và album mà bạn chưa sở hữu"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Yếu"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Chào mừng trở lại!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Có gì mới"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Liên hệ tin cậy có thể giúp khôi phục dữ liệu của bạn."),
        "wishThemAHappyBirthday": m115,
        "yearShort": MessageLookupByLibrary.simpleMessage("năm"),
        "yearly": MessageLookupByLibrary.simpleMessage("Hàng năm"),
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("Có"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Có, hủy"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Có, chuyển thành người xem"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Có, xóa"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Có, bỏ qua thay đổi"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Có, đăng xuất"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Có, xóa"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Có, Gia hạn"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Có, đặt lại người"),
        "you": MessageLookupByLibrary.simpleMessage("Bạn"),
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
            "Bạn đang ở trên một kế hoạch gia đình!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Bạn đang sử dụng phiên bản mới nhất"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Bạn có thể tối đa gấp đôi lưu trữ của mình"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Bạn có thể quản lý các liên kết của mình trong tab chia sẻ."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Bạn có thể thử tìm kiếm một truy vấn khác."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Bạn không thể hạ cấp xuống gói này"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Bạn không thể chia sẻ với chính mình"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Bạn không có mục nào đã lưu trữ."),
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Tài khoản của bạn đã bị xóa"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Bản đồ của bạn"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Kế hoạch của bạn đã được hạ cấp thành công"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Kế hoạch của bạn đã được nâng cấp thành công"),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
            "Mua hàng của bạn đã thành công"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Chi tiết lưu trữ của bạn không thể được lấy"),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("Đăng ký của bạn đã hết hạn"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Đăng ký của bạn đã được cập nhật thành công"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Mã xác minh của bạn đã hết hạn"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Bạn không có tệp nào trong album này có thể bị xóa"),
        "zoomOutToSeePhotos":
            MessageLookupByLibrary.simpleMessage("Phóng to để xem ảnh")
      };
}
