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

  static String m0(title) => "${title} (Tôi)";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Thêm cộng tác viên', one: 'Thêm cộng tác viên', other: 'Thêm cộng tác viên')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Thêm mục', other: 'Thêm các mục')}";

  static String m3(storageAmount, endDate) =>
      "Gói bổ sung ${storageAmount} áp dụng đến ${endDate}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Thêm người xem', one: 'Thêm người xem', other: 'Thêm người xem')}";

  static String m5(emailOrName) => "Được thêm bởi ${emailOrName}";

  static String m6(albumName) => "Đã thêm thành công vào ${albumName}";

  static String m7(count) =>
      "${Intl.plural(count, one: 'Đã thêm vào 1 album thành công', other: 'Đã thêm vào ${count} album thành công')}";

  static String m8(name) => "Ngưỡng mộ ${name}";

  static String m9(count) =>
      "${Intl.plural(count, zero: 'Không có người tham gia', one: '1 người tham gia', other: '${count} Người tham gia')}";

  static String m10(versionValue) => "Phiên bản: ${versionValue}";

  static String m11(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} trống";

  static String m12(name) => "Ngắm cảnh với ${name}";

  static String m13(paymentProvider) =>
      "Vui lòng hủy gói hiện tại của bạn từ ${paymentProvider} trước";

  static String m14(user) =>
      "${user} sẽ không thể thêm ảnh vào album này\n\nHọ vẫn có thể xóa ảnh đã thêm bởi họ";

  static String m15(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {'true': 'Gia đình bạn đã nhận thêm ${storageAmountInGb} GB tính đến hiện tại', 'false': 'Bạn đã nhận thêm ${storageAmountInGb} GB tính đến hiện tại', 'other': 'Bạn đã nhận thêm ${storageAmountInGb} GB tính đến hiện tại!'})}";

  static String m16(albumName) =>
      "Liên kết cộng tác đã được tạo cho ${albumName}";

  static String m17(count) =>
      "${Intl.plural(count, zero: 'Chưa có cộng tác viên', one: 'Đã thêm 1 cộng tác viên', other: 'Đã thêm ${count} cộng tác viên')}";

  static String m18(email, numOfDays) =>
      "Bạn sắp thêm ${email} làm liên hệ tin cậy. Họ sẽ có thể khôi phục tài khoản của bạn nếu bạn không hoạt động trong ${numOfDays} ngày.";

  static String m19(familyAdminEmail) =>
      "Vui lòng liên hệ <green>${familyAdminEmail}</green> để quản lý gói của bạn";

  static String m20(provider) =>
      "Vui lòng liên hệ với chúng tôi qua support@ente.io để quản lý gói ${provider} của bạn.";

  static String m21(endpoint) => "Đã kết nối với ${endpoint}";

  static String m22(count) =>
      "${Intl.plural(count, one: 'Xóa ${count} mục', other: 'Xóa ${count} mục')}";

  static String m23(count) =>
      "Xóa luôn ảnh (và video) trong ${count} album này <bold>khỏi toàn bộ album khác</bold> cũng đang chứa chúng?";

  static String m24(currentlyDeleting, totalCount) =>
      "Đang xóa ${currentlyDeleting} / ${totalCount}";

  static String m25(albumName) =>
      "Xóa liên kết công khai dùng để truy cập \"${albumName}\".";

  static String m26(supportEmail) =>
      "Vui lòng gửi email đến ${supportEmail} từ địa chỉ email đã đăng ký của bạn";

  static String m27(count, storageSaved) =>
      "Bạn đã dọn dẹp ${Intl.plural(count, other: '${count} tệp bị trùng lặp')}, lấy lại (${storageSaved}!)";

  static String m28(count, formattedSize) =>
      "${count} tệp, ${formattedSize} mỗi tệp";

  static String m29(name) => "Email này đã được liên kết với ${name} trước.";

  static String m30(newEmail) => "Email đã được đổi thành ${newEmail}";

  static String m31(email) => "${email} chưa có tài khoản Ente.";

  static String m32(email) =>
      "${email} không có tài khoản Ente.\n\nGửi họ một lời mời để chia sẻ ảnh.";

  static String m33(name) => "Yêu mến ${name}";

  static String m34(text) => "Tìm thấy ảnh bổ sung cho ${text}";

  static String m35(name) => "Tiệc tùng với ${name}";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, other: '${formattedNumber} tệp')} trên thiết bị đã được sao lưu an toàn";

  static String m37(count, formattedNumber) =>
      "${Intl.plural(count, other: '${formattedNumber} tệp')} trong album đã được sao lưu an toàn";

  static String m38(storageAmountInGB) =>
      "${storageAmountInGB} GB mỗi khi ai đó đăng ký gói trả phí và áp dụng mã của bạn";

  static String m39(endDate) => "Dùng thử miễn phí áp dụng đến ${endDate}";

  static String m40(count) =>
      "Bạn vẫn có thể truy cập ${Intl.plural(count, one: 'chúng', other: 'chúng')} trên Ente, miễn là gói của bạn còn hiệu lực";

  static String m41(sizeInMBorGB) => "Giải phóng ${sizeInMBorGB}";

  static String m42(count, formattedSize) =>
      "${Intl.plural(count, one: 'Xóa chúng khỏi thiết bị để giải phóng ${formattedSize}', other: 'Xóa chúng khỏi thiết bị để giải phóng ${formattedSize}')}";

  static String m43(currentlyProcessing, totalCount) =>
      "Đang xử lý ${currentlyProcessing} / ${totalCount}";

  static String m44(name) => "Leo núi với ${name}";

  static String m45(count) => "${Intl.plural(count, other: '${count} mục')}";

  static String m46(name) => "Lần cuối với ${name}";

  static String m47(email) =>
      "${email} đã mời bạn trở thành một liên hệ tin cậy";

  static String m48(expiryTime) => "Liên kết sẽ hết hạn vào ${expiryTime}";

  static String m49(email) => "Liên kết người với ${email}";

  static String m50(personName, email) =>
      "Việc này sẽ liên kết ${personName} với ${email}";

  static String m51(count, formattedCount) =>
      "${Intl.plural(count, zero: 'chưa có kỷ niệm', other: '${formattedCount} kỷ niệm')}";

  static String m52(count) =>
      "${Intl.plural(count, one: 'Di chuyển mục', other: 'Di chuyển các mục')}";

  static String m53(albumName) => "Đã di chuyển thành công đến ${albumName}";

  static String m54(personName) => "Không có gợi ý cho ${personName}";

  static String m55(name) => "Không phải ${name}?";

  static String m56(familyAdminEmail) =>
      "Vui lòng liên hệ ${familyAdminEmail} để thay đổi mã của bạn.";

  static String m57(name) => "Quẩy với ${name}";

  static String m58(passwordStrengthValue) =>
      "Độ mạnh mật khẩu: ${passwordStrengthValue}";

  static String m59(providerName) =>
      "Vui lòng trao đổi với bộ phận hỗ trợ ${providerName} nếu bạn đã bị tính phí";

  static String m60(name, age) => "${name} đã ${age} tuổi!";

  static String m61(name, age) => "${name} sắp ${age} tuổi";

  static String m62(count) =>
      "${Intl.plural(count, zero: 'Chưa có ảnh', one: '1 ảnh', other: '${count} ảnh')}";

  static String m63(count) =>
      "${Intl.plural(count, zero: 'Chưa có ảnh', one: '1 ảnh', other: '${count} ảnh')}";

  static String m64(endDate) =>
      "Dùng thử miễn phí áp dụng đến ${endDate}.\nBạn có thể chọn gói trả phí sau đó.";

  static String m65(toEmail) =>
      "Vui lòng gửi email cho chúng tôi tại ${toEmail}";

  static String m66(toEmail) => "Vui lòng gửi nhật ký đến \n${toEmail}";

  static String m67(name) => "Làm dáng với ${name}";

  static String m68(folderName) => "Đang xử lý ${folderName}...";

  static String m69(storeName) => "Đánh giá chúng tôi trên ${storeName}";

  static String m70(name) => "Đã chỉ định lại bạn thành ${name}";

  static String m71(days, email) =>
      "Bạn có thể truy cập tài khoản sau ${days} ngày. Một thông báo sẽ được gửi đến ${email}.";

  static String m72(email) =>
      "Bạn có thể khôi phục tài khoản của ${email} bằng cách đặt lại mật khẩu mới.";

  static String m73(email) =>
      "${email} đang cố gắng khôi phục tài khoản của bạn.";

  static String m74(storageInGB) =>
      "3. Cả hai nhận thêm ${storageInGB} GB* miễn phí";

  static String m75(userEmail) =>
      "${userEmail} sẽ bị xóa khỏi album chia sẻ này\n\nBất kỳ ảnh nào được thêm bởi họ cũng sẽ bị xóa khỏi album";

  static String m76(endDate) => "Gia hạn gói vào ${endDate}";

  static String m77(name) => "Đi bộ với ${name}";

  static String m78(count) =>
      "${Intl.plural(count, other: '${count} kết quả đã tìm thấy')}";

  static String m79(snapshotLength, searchLength) =>
      "Độ dài các phần không khớp: ${snapshotLength} != ${searchLength}";

  static String m80(count) => "${count} đã chọn";

  static String m81(count) => "${count} đã chọn";

  static String m82(count, yourCount) =>
      "${count} đã chọn (${yourCount} là của bạn)";

  static String m83(name) => "Selfie với ${name}";

  static String m84(verificationID) =>
      "Đây là ID xác minh của tôi: ${verificationID} cho ente.io.";

  static String m85(verificationID) =>
      "Chào, bạn có thể xác nhận rằng đây là ID xác minh ente.io của bạn: ${verificationID}";

  static String m86(referralCode, referralStorageInGB) =>
      "Mã giới thiệu Ente: ${referralCode} \n\nÁp dụng nó trong Cài đặt → Chung → Giới thiệu để nhận thêm ${referralStorageInGB} GB miễn phí sau khi bạn đăng ký gói trả phí\n\nhttps://ente.io";

  static String m87(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Chia sẻ với những người cụ thể', one: 'Chia sẻ với 1 người', other: 'Chia sẻ với ${numberOfPeople} người')}";

  static String m88(emailIDs) => "Chia sẻ với ${emailIDs}";

  static String m89(fileType) =>
      "Tệp ${fileType} này sẽ bị xóa khỏi thiết bị của bạn.";

  static String m90(fileType) =>
      "Tệp ${fileType} này có trong cả Ente và thiết bị của bạn.";

  static String m91(fileType) => "Tệp ${fileType} này sẽ bị xóa khỏi Ente.";

  static String m92(name) => "Chơi thể thao với ${name}";

  static String m93(name) => "Tập trung vào ${name}";

  static String m94(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m95(
    usedAmount,
    usedStorageUnit,
    totalAmount,
    totalStorageUnit,
  ) =>
      "${usedAmount} ${usedStorageUnit} / ${totalAmount} ${totalStorageUnit} đã dùng";

  static String m96(id) =>
      "ID ${id} của bạn đã được liên kết với một tài khoản Ente khác.\nNếu bạn muốn sử dụng ID ${id} này với tài khoản này, vui lòng liên hệ bộ phận hỗ trợ của chúng tôi.";

  static String m97(endDate) => "Gói của bạn sẽ bị hủy vào ${endDate}";

  static String m98(completed, total) =>
      "${completed}/${total} kỷ niệm đã được lưu giữ";

  static String m99(ignoreReason) =>
      "Nhấn để tải lên, tải lên hiện tại bị bỏ qua do ${ignoreReason}";

  static String m100(storageAmountInGB) =>
      "Họ cũng nhận được ${storageAmountInGB} GB";

  static String m101(email) => "Đây là ID xác minh của ${email}";

  static String m102(count) =>
      "${Intl.plural(count, one: 'Tuần này, ${count} năm trước', other: 'Tuần này, ${count} năm trước')}";

  static String m103(dateFormat) => "${dateFormat} qua các năm";

  static String m104(count) =>
      "${Intl.plural(count, zero: 'Sắp xóa', one: '1 ngày', other: '${count} ngày')}";

  static String m105(year) => "Phượt năm ${year}";

  static String m106(location) => "Phượt ở ${location}";

  static String m107(email) =>
      "Bạn đã được mời làm người thừa kế của ${email}.";

  static String m108(galleryType) =>
      "Loại thư viện ${galleryType} không được hỗ trợ đổi tên";

  static String m109(ignoreReason) => "Tải lên bị bỏ qua do ${ignoreReason}";

  static String m110(count) => "Đang lưu giữ ${count} kỷ niệm...";

  static String m111(endDate) => "Áp dụng đến ${endDate}";

  static String m112(email) => "Xác minh ${email}";

  static String m113(name) => "Xem ${name} để hủy liên kết";

  static String m114(count) =>
      "${Intl.plural(count, zero: 'Chưa thêm người xem', one: 'Đã thêm 1 người xem', other: 'Đã thêm ${count} người xem')}";

  static String m115(email) =>
      "Chúng tôi đã gửi một email đến <green>${email}</green>";

  static String m116(name) => "Chúc ${name} sinh nhật vui vẻ! 🎉";

  static String m117(count) =>
      "${Intl.plural(count, other: '${count} năm trước')}";

  static String m118(name) => "Bạn và ${name}";

  static String m119(storageSaved) =>
      "Bạn đã giải phóng thành công ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
      "Ente có phiên bản mới.",
    ),
    "about": MessageLookupByLibrary.simpleMessage("Giới thiệu"),
    "acceptTrustInvite": MessageLookupByLibrary.simpleMessage(
      "Chấp nhận lời mời",
    ),
    "account": MessageLookupByLibrary.simpleMessage("Tài khoản"),
    "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
      "Tài khoản đã được cấu hình.",
    ),
    "accountOwnerPersonAppbarTitle": m0,
    "accountWelcomeBack": MessageLookupByLibrary.simpleMessage(
      "Chào mừng bạn trở lại!",
    ),
    "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
      "Tôi hiểu rằng nếu mất mật khẩu, dữ liệu của tôi sẽ mất vì nó được <underline>mã hóa đầu cuối</underline>.",
    ),
    "actionNotSupportedOnFavouritesAlbum": MessageLookupByLibrary.simpleMessage(
      "Hành động không áp dụng trong album Đã thích",
    ),
    "activeSessions": MessageLookupByLibrary.simpleMessage("Phiên hoạt động"),
    "add": MessageLookupByLibrary.simpleMessage("Thêm"),
    "addAName": MessageLookupByLibrary.simpleMessage("Thêm một tên"),
    "addANewEmail": MessageLookupByLibrary.simpleMessage("Thêm một email mới"),
    "addAlbumWidgetPrompt": MessageLookupByLibrary.simpleMessage(
      "Thêm tiện ích album vào màn hình chính và quay lại đây để tùy chỉnh.",
    ),
    "addCollaborator": MessageLookupByLibrary.simpleMessage(
      "Thêm cộng tác viên",
    ),
    "addCollaborators": m1,
    "addFiles": MessageLookupByLibrary.simpleMessage("Thêm tệp"),
    "addFromDevice": MessageLookupByLibrary.simpleMessage("Thêm từ thiết bị"),
    "addItem": m2,
    "addLocation": MessageLookupByLibrary.simpleMessage("Thêm vị trí"),
    "addLocationButton": MessageLookupByLibrary.simpleMessage("Thêm"),
    "addMemoriesWidgetPrompt": MessageLookupByLibrary.simpleMessage(
      "Thêm tiện ích kỷ niệm vào màn hình chính và quay lại đây để tùy chỉnh.",
    ),
    "addMore": MessageLookupByLibrary.simpleMessage("Thêm nhiều hơn"),
    "addName": MessageLookupByLibrary.simpleMessage("Thêm tên"),
    "addNameOrMerge": MessageLookupByLibrary.simpleMessage(
      "Thêm tên hoặc hợp nhất",
    ),
    "addNew": MessageLookupByLibrary.simpleMessage("Thêm mới"),
    "addNewPerson": MessageLookupByLibrary.simpleMessage("Thêm người mới"),
    "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
      "Chi tiết về tiện ích mở rộng",
    ),
    "addOnValidTill": m3,
    "addOns": MessageLookupByLibrary.simpleMessage("Tiện ích mở rộng"),
    "addParticipants": MessageLookupByLibrary.simpleMessage(
      "Thêm người tham gia",
    ),
    "addPeopleWidgetPrompt": MessageLookupByLibrary.simpleMessage(
      "Thêm tiện ích người vào màn hình chính và quay lại đây để tùy chỉnh.",
    ),
    "addPhotos": MessageLookupByLibrary.simpleMessage("Thêm ảnh"),
    "addSelected": MessageLookupByLibrary.simpleMessage("Thêm mục đã chọn"),
    "addSomePhotosDesc1": MessageLookupByLibrary.simpleMessage(
      "Thêm vài ảnh hoặc chọn ",
    ),
    "addSomePhotosDesc2": MessageLookupByLibrary.simpleMessage(
      "những khuôn mặt giống nhau",
    ),
    "addSomePhotosDesc3": MessageLookupByLibrary.simpleMessage(
      "\nđể bắt đầu với",
    ),
    "addToAlbum": MessageLookupByLibrary.simpleMessage("Thêm vào album"),
    "addToEnte": MessageLookupByLibrary.simpleMessage("Thêm vào Ente"),
    "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
      "Thêm vào album ẩn",
    ),
    "addTrustedContact": MessageLookupByLibrary.simpleMessage(
      "Thêm liên hệ tin cậy",
    ),
    "addViewer": MessageLookupByLibrary.simpleMessage("Thêm người xem"),
    "addViewers": m4,
    "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
      "Thêm ảnh của bạn ngay bây giờ",
    ),
    "addedAs": MessageLookupByLibrary.simpleMessage("Đã thêm như"),
    "addedBy": m5,
    "addedSuccessfullyTo": m6,
    "addedToAlbums": m7,
    "addingPhotos": MessageLookupByLibrary.simpleMessage("Đang thêm ảnh"),
    "addingToFavorites": MessageLookupByLibrary.simpleMessage(
      "Đang thêm vào mục yêu thích...",
    ),
    "adjust": MessageLookupByLibrary.simpleMessage("Điều chỉnh"),
    "admiringThem": m8,
    "advanced": MessageLookupByLibrary.simpleMessage("Nâng cao"),
    "advancedSettings": MessageLookupByLibrary.simpleMessage("Nâng cao"),
    "after1Day": MessageLookupByLibrary.simpleMessage("Sau 1 ngày"),
    "after1Hour": MessageLookupByLibrary.simpleMessage("Sau 1 giờ"),
    "after1Month": MessageLookupByLibrary.simpleMessage("Sau 1 tháng"),
    "after1Week": MessageLookupByLibrary.simpleMessage("Sau 1 tuần"),
    "after1Year": MessageLookupByLibrary.simpleMessage("Sau 1 năm"),
    "albumOwner": MessageLookupByLibrary.simpleMessage("Chủ sở hữu"),
    "albumParticipantsCount": m9,
    "albumTitle": MessageLookupByLibrary.simpleMessage("Tiêu đề album"),
    "albumUpdated": MessageLookupByLibrary.simpleMessage(
      "Album đã được cập nhật",
    ),
    "albums": MessageLookupByLibrary.simpleMessage("Album"),
    "albumsWidgetDesc": MessageLookupByLibrary.simpleMessage(
      "Chọn những album bạn muốn thấy trên màn hình chính của mình.",
    ),
    "align": MessageLookupByLibrary.simpleMessage("Căn chỉnh"),
    "allClear": MessageLookupByLibrary.simpleMessage("✨ Tất cả đã xong"),
    "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
      "Tất cả kỷ niệm đã được lưu giữ",
    ),
    "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
      "Tất cả nhóm của người này sẽ được đặt lại, và bạn sẽ mất tất cả các gợi ý đã được tạo ra cho người này",
    ),
    "allUnnamedGroupsWillBeMergedIntoTheSelectedPerson":
        MessageLookupByLibrary.simpleMessage(
          "Tất cả nhóm không có tên sẽ được hợp nhất vào người đã chọn. Điều này vẫn có thể được hoàn tác từ tổng quan lịch sử đề xuất của người đó.",
        ),
    "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
      "Đây là ảnh đầu tiên trong nhóm. Các ảnh được chọn khác sẽ tự động thay đổi dựa theo ngày mới này",
    ),
    "allow": MessageLookupByLibrary.simpleMessage("Cho phép"),
    "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
      "Cho phép người có liên kết thêm ảnh vào album chia sẻ.",
    ),
    "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
      "Cho phép thêm ảnh",
    ),
    "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
      "Cho phép ứng dụng mở liên kết album chia sẻ",
    ),
    "allowDownloads": MessageLookupByLibrary.simpleMessage(
      "Cho phép tải xuống",
    ),
    "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
      "Cho phép mọi người thêm ảnh",
    ),
    "allowPermBody": MessageLookupByLibrary.simpleMessage(
      "Vui lòng cho phép truy cập vào ảnh của bạn từ Cài đặt để Ente có thể hiển thị và sao lưu thư viện của bạn.",
    ),
    "allowPermTitle": MessageLookupByLibrary.simpleMessage(
      "Cho phép truy cập ảnh",
    ),
    "analysis": MessageLookupByLibrary.simpleMessage("Phân tích"),
    "androidBiometricHint": MessageLookupByLibrary.simpleMessage(
      "Xác minh danh tính",
    ),
    "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
      "Không nhận diện được. Thử lại.",
    ),
    "androidBiometricRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "Yêu cầu sinh trắc học",
    ),
    "androidBiometricSuccess": MessageLookupByLibrary.simpleMessage(
      "Thành công",
    ),
    "androidCancelButton": MessageLookupByLibrary.simpleMessage("Hủy"),
    "androidDeviceCredentialsRequiredTitle":
        MessageLookupByLibrary.simpleMessage(
          "Yêu cầu thông tin xác thực thiết bị",
        ),
    "androidDeviceCredentialsSetupDescription":
        MessageLookupByLibrary.simpleMessage(
          "Yêu cầu thông tin xác thực thiết bị",
        ),
    "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Xác thực sinh trắc học chưa được thiết lập trên thiết bị của bạn. Đi đến \'Cài đặt > Bảo mật\' để thêm xác thực sinh trắc học.",
    ),
    "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
      "Android, iOS, Web, Desktop",
    ),
    "androidSignInTitle": MessageLookupByLibrary.simpleMessage(
      "Yêu cầu xác thực",
    ),
    "appIcon": MessageLookupByLibrary.simpleMessage("Biểu tượng ứng dụng"),
    "appLock": MessageLookupByLibrary.simpleMessage("Khóa ứng dụng"),
    "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
      "Chọn giữa màn hình khóa mặc định của thiết bị và màn hình khóa tùy chỉnh với PIN hoặc mật khẩu.",
    ),
    "appVersion": m10,
    "appleId": MessageLookupByLibrary.simpleMessage("ID Apple"),
    "apply": MessageLookupByLibrary.simpleMessage("Áp dụng"),
    "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Áp dụng mã"),
    "appstoreSubscription": MessageLookupByLibrary.simpleMessage(
      "Gói AppStore",
    ),
    "archive": MessageLookupByLibrary.simpleMessage("Lưu trữ"),
    "archiveAlbum": MessageLookupByLibrary.simpleMessage("Lưu trữ album"),
    "archiving": MessageLookupByLibrary.simpleMessage("Đang lưu trữ..."),
    "areThey": MessageLookupByLibrary.simpleMessage("Họ có phải là "),
    "areYouSureRemoveThisFaceFromPerson": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn xóa khuôn mặt này khỏi người này không?",
    ),
    "areYouSureThatYouWantToLeaveTheFamily":
        MessageLookupByLibrary.simpleMessage(
          "Bạn có chắc muốn rời khỏi gói gia đình không?",
        ),
    "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn hủy không?",
    ),
    "areYouSureYouWantToChangeYourPlan": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn thay đổi gói của mình không?",
    ),
    "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn thoát không?",
    ),
    "areYouSureYouWantToIgnoreThesePersons":
        MessageLookupByLibrary.simpleMessage(
          "Bạn có chắc muốn bỏ qua những người này?",
        ),
    "areYouSureYouWantToIgnoreThisPerson": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn bỏ qua người này?",
    ),
    "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn đăng xuất không?",
    ),
    "areYouSureYouWantToMergeThem": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn hợp nhất họ?",
    ),
    "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn gia hạn không?",
    ),
    "areYouSureYouWantToResetThisPerson": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn đặt lại người này không?",
    ),
    "askCancelReason": MessageLookupByLibrary.simpleMessage(
      "Gói của bạn đã bị hủy. Bạn có muốn chia sẻ lý do không?",
    ),
    "askDeleteReason": MessageLookupByLibrary.simpleMessage(
      "Lý do chính bạn xóa tài khoản là gì?",
    ),
    "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
      "Hãy gợi ý những người thân yêu của bạn chia sẻ",
    ),
    "atAFalloutShelter": MessageLookupByLibrary.simpleMessage(
      "ở hầm trú ẩn hạt nhân",
    ),
    "authToChangeEmailVerificationSetting":
        MessageLookupByLibrary.simpleMessage(
          "Vui lòng xác thực để đổi cài đặt xác minh email",
        ),
    "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác thực để thay đổi cài đặt khóa màn hình",
    ),
    "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác thực để đổi email",
    ),
    "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác thực để đổi mật khẩu",
    ),
    "authToConfigureTwofactorAuthentication":
        MessageLookupByLibrary.simpleMessage(
          "Vui lòng xác thực để cấu hình xác thực 2 bước",
        ),
    "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác thực để bắt đầu xóa tài khoản",
    ),
    "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác thực để quản lý các liên hệ tin cậy",
    ),
    "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác thực để xem khóa truy cập",
    ),
    "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác thực để xem các tệp đã xóa",
    ),
    "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác thực để xem các phiên hoạt động",
    ),
    "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác thực để xem các tệp ẩn",
    ),
    "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác thực để xem kỷ niệm",
    ),
    "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác thực để xem mã khôi phục",
    ),
    "authenticating": MessageLookupByLibrary.simpleMessage("Đang xác thực..."),
    "authenticationFailedPleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Xác thực không thành công, vui lòng thử lại",
    ),
    "authenticationSuccessful": MessageLookupByLibrary.simpleMessage(
      "Xác thực thành công!",
    ),
    "autoAddPeople": MessageLookupByLibrary.simpleMessage("Tự động thêm người"),
    "autoAddToAlbum": MessageLookupByLibrary.simpleMessage(
      "Tự động thêm vào album",
    ),
    "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
      "Bạn sẽ thấy các thiết bị phát khả dụng ở đây.",
    ),
    "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
      "Hãy chắc rằng quyền Mạng cục bộ đã được bật cho ứng dụng Ente Photos, trong Cài đặt.",
    ),
    "autoLock": MessageLookupByLibrary.simpleMessage("Khóa tự động"),
    "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
      "Sau thời gian này, ứng dụng sẽ khóa sau khi được chạy ở chế độ nền",
    ),
    "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
      "Do sự cố kỹ thuật, bạn đã bị đăng xuất. Chúng tôi xin lỗi vì sự bất tiện.",
    ),
    "autoPair": MessageLookupByLibrary.simpleMessage("Kết nối tự động"),
    "autoPairDesc": MessageLookupByLibrary.simpleMessage(
      "Kết nối tự động chỉ hoạt động với các thiết bị hỗ trợ Chromecast.",
    ),
    "automaticallyAnalyzeAndSplitGrouping": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi sẽ tự động phân tích nhóm để xác định xem có nhiều người góp mặt hay không và tách họ ra lần nữa. Việc này có thể mất vài giây.",
    ),
    "available": MessageLookupByLibrary.simpleMessage("Có sẵn"),
    "availableStorageSpace": m11,
    "backedUpFolders": MessageLookupByLibrary.simpleMessage(
      "Thư mục đã sao lưu",
    ),
    "background": MessageLookupByLibrary.simpleMessage("Nền"),
    "backgroundWithThem": m12,
    "backup": MessageLookupByLibrary.simpleMessage("Sao lưu"),
    "backupFailed": MessageLookupByLibrary.simpleMessage("Sao lưu thất bại"),
    "backupFile": MessageLookupByLibrary.simpleMessage("Sao lưu tệp"),
    "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
      "Sao lưu với dữ liệu di động",
    ),
    "backupSettings": MessageLookupByLibrary.simpleMessage("Cài đặt sao lưu"),
    "backupStatus": MessageLookupByLibrary.simpleMessage("Trạng thái sao lưu"),
    "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Các mục đã được sao lưu sẽ hiển thị ở đây",
    ),
    "backupVideos": MessageLookupByLibrary.simpleMessage("Sao lưu video"),
    "beach": MessageLookupByLibrary.simpleMessage("Cát và biển"),
    "birthday": MessageLookupByLibrary.simpleMessage("Sinh nhật"),
    "birthdayNotifications": MessageLookupByLibrary.simpleMessage(
      "Thông báo sinh nhật",
    ),
    "birthdays": MessageLookupByLibrary.simpleMessage("Sinh nhật"),
    "blackFridaySale": MessageLookupByLibrary.simpleMessage(
      "Giảm giá Black Friday",
    ),
    "blog": MessageLookupByLibrary.simpleMessage("Blog"),
    "brushColor": MessageLookupByLibrary.simpleMessage("Màu cọ"),
    "cLDesc1": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi phát hành một trình chỉnh sửa ảnh tân tiến, bổ sung thêm cắt ảnh, bộ lọc có sẵn để chỉnh sửa nhanh, các tùy chọn tinh chỉnh bao gồm độ bão hòa, độ tương phản, độ sáng, độ ấm và nhiều hơn nữa. Trình chỉnh sửa mới cũng bao gồm khả năng vẽ lên ảnh và thêm emoji dưới dạng nhãn dán.",
    ),
    "cLDesc2": MessageLookupByLibrary.simpleMessage(
      "Giờ đây, bạn có thể tự động thêm ảnh của những người đã chọn vào bất kỳ album nào. Chỉ cần mở album và chọn \"Tự động thêm người\" trong menu. Nếu sử dụng cùng với album chia sẻ, bạn có thể chia sẻ ảnh mà không cần tốn công.",
    ),
    "cLDesc3": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi bổ sung tính năng phân nhóm thư viện ảnh theo tuần, tháng và năm. Giờ đây, bạn có thể tùy chỉnh thư viện ảnh theo đúng ý muốn với các tùy chọn mới này, cùng với các lưới tùy chỉnh.",
    ),
    "cLDesc4": MessageLookupByLibrary.simpleMessage(
      "Cùng với một loạt cải tiến ngầm nhằm nâng cao trải nghiệm cuộn thư viện, chúng tôi cũng đã thiết kế lại thanh cuộn để hiển thị các điểm đánh dấu, cho phép bạn nhanh chóng nhảy cóc trên dòng thời gian.",
    ),
    "cLTitle1": MessageLookupByLibrary.simpleMessage(
      "Trình chỉnh sửa ảnh nâng cao",
    ),
    "cLTitle2": MessageLookupByLibrary.simpleMessage("Album thông minh"),
    "cLTitle3": MessageLookupByLibrary.simpleMessage("Cải tiến Thư viện ảnh"),
    "cLTitle4": MessageLookupByLibrary.simpleMessage("Cuộn nhanh hơn"),
    "cachedData": MessageLookupByLibrary.simpleMessage(
      "Dữ liệu đã lưu trong bộ nhớ đệm",
    ),
    "calculating": MessageLookupByLibrary.simpleMessage("Đang tính toán..."),
    "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
      "Rất tiếc, album này không thể mở trong ứng dụng.",
    ),
    "canNotOpenTitle": MessageLookupByLibrary.simpleMessage(
      "Không thể mở album này",
    ),
    "canNotUploadToAlbumsOwnedByOthers": MessageLookupByLibrary.simpleMessage(
      "Không thể tải lên album thuộc sở hữu của người khác",
    ),
    "canOnlyCreateLinkForFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
      "Chỉ có thể tạo liên kết cho các tệp thuộc sở hữu của bạn",
    ),
    "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
      "Chỉ có thể xóa các tệp thuộc sở hữu của bạn",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Hủy"),
    "cancelAccountRecovery": MessageLookupByLibrary.simpleMessage(
      "Hủy khôi phục",
    ),
    "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn hủy khôi phục không?",
    ),
    "cancelOtherSubscription": m13,
    "cancelSubscription": MessageLookupByLibrary.simpleMessage("Hủy gói"),
    "cannotAddMorePhotosAfterBecomingViewer": m14,
    "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
      "Không thể xóa các tệp đã chia sẻ",
    ),
    "castAlbum": MessageLookupByLibrary.simpleMessage("Phát album"),
    "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
      "Hãy chắc rằng bạn đang dùng chung mạng với TV.",
    ),
    "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
      "Không thể phát album",
    ),
    "castInstruction": MessageLookupByLibrary.simpleMessage(
      "Truy cập cast.ente.io trên thiết bị bạn muốn kết nối.\n\nNhập mã dưới đây để phát album trên TV của bạn.",
    ),
    "centerPoint": MessageLookupByLibrary.simpleMessage("Tâm điểm"),
    "change": MessageLookupByLibrary.simpleMessage("Thay đổi"),
    "changeEmail": MessageLookupByLibrary.simpleMessage("Đổi email"),
    "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
      "Thay đổi vị trí của các mục đã chọn?",
    ),
    "changePassword": MessageLookupByLibrary.simpleMessage("Đổi mật khẩu"),
    "changePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Thay đổi mật khẩu",
    ),
    "changePermissions": MessageLookupByLibrary.simpleMessage(
      "Thay đổi quyền?",
    ),
    "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
      "Thay đổi mã giới thiệu của bạn",
    ),
    "checkForUpdates": MessageLookupByLibrary.simpleMessage(
      "Kiểm tra cập nhật",
    ),
    "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
      "Vui lòng kiểm tra hộp thư đến (và thư rác) để hoàn tất xác minh",
    ),
    "checkStatus": MessageLookupByLibrary.simpleMessage("Kiểm tra trạng thái"),
    "checking": MessageLookupByLibrary.simpleMessage("Đang kiểm tra..."),
    "checkingModels": MessageLookupByLibrary.simpleMessage(
      "Đang kiểm tra mô hình...",
    ),
    "city": MessageLookupByLibrary.simpleMessage("Trong thành phố"),
    "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
      "Nhận thêm dung lượng",
    ),
    "claimMore": MessageLookupByLibrary.simpleMessage("Nhận thêm!"),
    "claimed": MessageLookupByLibrary.simpleMessage("Đã nhận"),
    "claimedStorageSoFar": m15,
    "cleanUncategorized": MessageLookupByLibrary.simpleMessage(
      "Dọn dẹp chưa phân loại",
    ),
    "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
      "Xóa khỏi mục Chưa phân loại với tất cả tệp đang xuất hiện trong các album khác",
    ),
    "clearCaches": MessageLookupByLibrary.simpleMessage("Xóa bộ nhớ cache"),
    "clearIndexes": MessageLookupByLibrary.simpleMessage("Xóa chỉ mục"),
    "click": MessageLookupByLibrary.simpleMessage("• Nhấn"),
    "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
      "• Nhấn vào menu xổ xuống",
    ),
    "clickToInstallOurBestVersionYet": MessageLookupByLibrary.simpleMessage(
      "Nhấn để cài đặt phiên bản tốt nhất",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Đóng"),
    "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
      "Xếp theo thời gian chụp",
    ),
    "clubByFileName": MessageLookupByLibrary.simpleMessage("Xếp theo tên tệp"),
    "clusteringProgress": MessageLookupByLibrary.simpleMessage(
      "Tiến trình phân cụm",
    ),
    "codeAppliedPageTitle": MessageLookupByLibrary.simpleMessage(
      "Mã đã được áp dụng",
    ),
    "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
      "Rất tiếc, bạn đã đạt hạn mức thay đổi mã.",
    ),
    "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Mã đã được sao chép vào bộ nhớ tạm",
    ),
    "codeUsedByYou": MessageLookupByLibrary.simpleMessage("Mã bạn đã dùng"),
    "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
      "Tạo một liên kết cho phép mọi người thêm và xem ảnh trong album chia sẻ của bạn mà không cần ứng dụng hoặc tài khoản Ente. Phù hợp để thu thập ảnh sự kiện.",
    ),
    "collaborativeLink": MessageLookupByLibrary.simpleMessage(
      "Liên kết cộng tác",
    ),
    "collaborativeLinkCreatedFor": m16,
    "collaborator": MessageLookupByLibrary.simpleMessage("Cộng tác viên"),
    "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
        MessageLookupByLibrary.simpleMessage(
          "Cộng tác viên có thể thêm ảnh và video vào album chia sẻ.",
        ),
    "collaboratorsSuccessfullyAdded": m17,
    "collageLayout": MessageLookupByLibrary.simpleMessage("Bố cục"),
    "collageSaved": MessageLookupByLibrary.simpleMessage(
      "Ảnh ghép đã được lưu vào thư viện",
    ),
    "collect": MessageLookupByLibrary.simpleMessage("Thu thập"),
    "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
      "Thu thập ảnh sự kiện",
    ),
    "collectPhotos": MessageLookupByLibrary.simpleMessage("Thu thập ảnh"),
    "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
      "Tạo một liên kết nơi bạn bè của bạn có thể tải lên ảnh với chất lượng gốc.",
    ),
    "color": MessageLookupByLibrary.simpleMessage("Màu sắc"),
    "configuration": MessageLookupByLibrary.simpleMessage("Cấu hình"),
    "confirm": MessageLookupByLibrary.simpleMessage("Xác nhận"),
    "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn tắt xác thực 2 bước không?",
    ),
    "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
      "Xác nhận xóa tài khoản",
    ),
    "confirmAddingTrustedContact": m18,
    "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
      "Có, tôi muốn xóa vĩnh viễn tài khoản này và tất cả dữ liệu.",
    ),
    "confirmPassword": MessageLookupByLibrary.simpleMessage(
      "Xác nhận mật khẩu",
    ),
    "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
      "Xác nhận thay đổi gói",
    ),
    "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Xác nhận mã khôi phục",
    ),
    "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Xác nhận mã khôi phục của bạn",
    ),
    "connectToDevice": MessageLookupByLibrary.simpleMessage(
      "Kết nối với thiết bị",
    ),
    "contactFamilyAdmin": m19,
    "contactSupport": MessageLookupByLibrary.simpleMessage("Liên hệ hỗ trợ"),
    "contactToManageSubscription": m20,
    "contacts": MessageLookupByLibrary.simpleMessage("Danh bạ"),
    "contents": MessageLookupByLibrary.simpleMessage("Nội dung"),
    "continueLabel": MessageLookupByLibrary.simpleMessage("Tiếp tục"),
    "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
      "Tiếp tục dùng thử miễn phí",
    ),
    "convertToAlbum": MessageLookupByLibrary.simpleMessage(
      "Chuyển đổi thành album",
    ),
    "copyEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Sao chép địa chỉ email",
    ),
    "copyLink": MessageLookupByLibrary.simpleMessage("Sao chép liên kết"),
    "copypasteThisCodentoYourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Chép & dán mã này\nvào ứng dụng xác thực của bạn",
        ),
    "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi không thể sao lưu dữ liệu của bạn.\nChúng tôi sẽ thử lại sau.",
    ),
    "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
      "Không thể giải phóng dung lượng",
    ),
    "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
      "Không thể cập nhật gói",
    ),
    "count": MessageLookupByLibrary.simpleMessage("Số lượng"),
    "crashReporting": MessageLookupByLibrary.simpleMessage("Báo cáo sự cố"),
    "create": MessageLookupByLibrary.simpleMessage("Tạo"),
    "createAccount": MessageLookupByLibrary.simpleMessage("Tạo tài khoản"),
    "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
      "Nhấn giữ để chọn ảnh và nhấn + để tạo album",
    ),
    "createCollaborativeLink": MessageLookupByLibrary.simpleMessage(
      "Tạo liên kết cộng tác",
    ),
    "createCollage": MessageLookupByLibrary.simpleMessage("Tạo ảnh ghép"),
    "createNewAccount": MessageLookupByLibrary.simpleMessage(
      "Tạo tài khoản mới",
    ),
    "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage(
      "Tạo hoặc chọn album",
    ),
    "createPublicLink": MessageLookupByLibrary.simpleMessage(
      "Tạo liên kết công khai",
    ),
    "creatingLink": MessageLookupByLibrary.simpleMessage(
      "Đang tạo liên kết...",
    ),
    "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Cập nhật quan trọng có sẵn",
    ),
    "crop": MessageLookupByLibrary.simpleMessage("Cắt xén"),
    "curatedMemories": MessageLookupByLibrary.simpleMessage("Kỷ niệm đáng nhớ"),
    "currentUsageIs": MessageLookupByLibrary.simpleMessage(
      "Dung lượng hiện tại ",
    ),
    "currentlyRunning": MessageLookupByLibrary.simpleMessage("đang chạy"),
    "custom": MessageLookupByLibrary.simpleMessage("Tùy chỉnh"),
    "customEndpoint": m21,
    "darkTheme": MessageLookupByLibrary.simpleMessage("Tối"),
    "day": MessageLookupByLibrary.simpleMessage("Ngày"),
    "dayToday": MessageLookupByLibrary.simpleMessage("Hôm nay"),
    "dayYesterday": MessageLookupByLibrary.simpleMessage("Hôm qua"),
    "declineTrustInvite": MessageLookupByLibrary.simpleMessage(
      "Từ chối lời mời",
    ),
    "decrypting": MessageLookupByLibrary.simpleMessage("Đang giải mã..."),
    "decryptingVideo": MessageLookupByLibrary.simpleMessage(
      "Đang giải mã video...",
    ),
    "deduplicateFiles": MessageLookupByLibrary.simpleMessage("Xóa trùng lặp"),
    "delete": MessageLookupByLibrary.simpleMessage("Xóa"),
    "deleteAccount": MessageLookupByLibrary.simpleMessage("Xóa tài khoản"),
    "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi rất tiếc khi thấy bạn rời đi. Vui lòng chia sẻ phản hồi của bạn để giúp chúng tôi cải thiện.",
    ),
    "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
      "Xóa tài khoản vĩnh viễn",
    ),
    "deleteAlbum": MessageLookupByLibrary.simpleMessage("Xóa album"),
    "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
      "Xóa luôn ảnh (và video) trong album này <bold>khỏi toàn bộ album khác</bold> cũng đang chứa chúng?",
    ),
    "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
      "Tất cả album trống sẽ bị xóa. Sẽ hữu ích khi bạn muốn giảm bớt sự lộn xộn trong danh sách album của mình.",
    ),
    "deleteAll": MessageLookupByLibrary.simpleMessage("Xóa tất cả"),
    "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
      "Tài khoản này được liên kết với các ứng dụng Ente khác, nếu bạn có dùng. Dữ liệu bạn đã tải lên, trên tất cả ứng dụng Ente, sẽ được lên lịch để xóa, và tài khoản của bạn sẽ bị xóa vĩnh viễn.",
    ),
    "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
      "Vui lòng gửi email đến <warning>account-deletion@ente.io</warning> từ địa chỉ email đã đăng ký của bạn.",
    ),
    "deleteEmptyAlbums": MessageLookupByLibrary.simpleMessage(
      "Xóa album trống",
    ),
    "deleteEmptyAlbumsWithQuestionMark": MessageLookupByLibrary.simpleMessage(
      "Xóa album trống?",
    ),
    "deleteFromBoth": MessageLookupByLibrary.simpleMessage("Xóa khỏi cả hai"),
    "deleteFromDevice": MessageLookupByLibrary.simpleMessage(
      "Xóa khỏi thiết bị",
    ),
    "deleteFromEnte": MessageLookupByLibrary.simpleMessage("Xóa khỏi Ente"),
    "deleteItemCount": m22,
    "deleteLocation": MessageLookupByLibrary.simpleMessage("Xóa vị trí"),
    "deleteMultipleAlbumDialog": m23,
    "deletePhotos": MessageLookupByLibrary.simpleMessage("Xóa ảnh"),
    "deleteProgress": m24,
    "deleteReason1": MessageLookupByLibrary.simpleMessage(
      "Nó thiếu một tính năng quan trọng mà tôi cần",
    ),
    "deleteReason2": MessageLookupByLibrary.simpleMessage(
      "Ứng dụng hoặc một tính năng không hoạt động như tôi muốn",
    ),
    "deleteReason3": MessageLookupByLibrary.simpleMessage(
      "Tôi tìm thấy một dịch vụ khác mà tôi thích hơn",
    ),
    "deleteReason4": MessageLookupByLibrary.simpleMessage(
      "Lý do không có trong danh sách",
    ),
    "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
      "Yêu cầu của bạn sẽ được xử lý trong vòng 72 giờ.",
    ),
    "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
      "Xóa album chia sẻ?",
    ),
    "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
      "Album sẽ bị xóa với tất cả mọi người\n\nBạn sẽ mất quyền truy cập vào các ảnh chia sẻ trong album này mà thuộc sở hữu của người khác",
    ),
    "deselectAll": MessageLookupByLibrary.simpleMessage("Bỏ chọn tất cả"),
    "designedToOutlive": MessageLookupByLibrary.simpleMessage(
      "Được thiết kế để trường tồn",
    ),
    "details": MessageLookupByLibrary.simpleMessage("Chi tiết"),
    "developerSettings": MessageLookupByLibrary.simpleMessage(
      "Cài đặt Nhà phát triển",
    ),
    "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn thay đổi cài đặt Nhà phát triển không?",
    ),
    "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Nhập mã"),
    "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
      "Các tệp được thêm vào album thiết bị này sẽ tự động được tải lên Ente.",
    ),
    "deviceLock": MessageLookupByLibrary.simpleMessage("Khóa thiết bị"),
    "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
      "Vô hiệu hóa khóa màn hình thiết bị khi Ente đang ở chế độ nền và có một bản sao lưu đang diễn ra. Điều này thường không cần thiết, nhưng có thể giúp tải lên các tệp lớn và tệp nhập của các thư viện lớn xong nhanh hơn.",
    ),
    "deviceNotFound": MessageLookupByLibrary.simpleMessage(
      "Không tìm thấy thiết bị",
    ),
    "didYouKnow": MessageLookupByLibrary.simpleMessage("Bạn có biết?"),
    "different": MessageLookupByLibrary.simpleMessage("Khác"),
    "disableAutoLock": MessageLookupByLibrary.simpleMessage(
      "Vô hiệu hóa khóa tự động",
    ),
    "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
      "Người xem vẫn có thể chụp màn hình hoặc sao chép ảnh của bạn bằng các công cụ bên ngoài",
    ),
    "disableDownloadWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Xin lưu ý",
    ),
    "disableLinkMessage": m25,
    "disableTwofactor": MessageLookupByLibrary.simpleMessage(
      "Tắt xác thực 2 bước",
    ),
    "disablingTwofactorAuthentication": MessageLookupByLibrary.simpleMessage(
      "Đang vô hiệu hóa xác thực 2 bước...",
    ),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "discover": MessageLookupByLibrary.simpleMessage("Khám phá"),
    "discover_babies": MessageLookupByLibrary.simpleMessage("Em bé"),
    "discover_celebrations": MessageLookupByLibrary.simpleMessage("Lễ kỷ niệm"),
    "discover_food": MessageLookupByLibrary.simpleMessage("Thức ăn"),
    "discover_greenery": MessageLookupByLibrary.simpleMessage("Cây cối"),
    "discover_hills": MessageLookupByLibrary.simpleMessage("Đồi"),
    "discover_identity": MessageLookupByLibrary.simpleMessage("Nhận dạng"),
    "discover_memes": MessageLookupByLibrary.simpleMessage("Meme"),
    "discover_notes": MessageLookupByLibrary.simpleMessage("Ghi chú"),
    "discover_pets": MessageLookupByLibrary.simpleMessage("Thú cưng"),
    "discover_receipts": MessageLookupByLibrary.simpleMessage("Biên lai"),
    "discover_screenshots": MessageLookupByLibrary.simpleMessage(
      "Ảnh chụp màn hình",
    ),
    "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfie"),
    "discover_sunset": MessageLookupByLibrary.simpleMessage("Hoàng hôn"),
    "discover_visiting_cards": MessageLookupByLibrary.simpleMessage(
      "Danh thiếp",
    ),
    "discover_wallpapers": MessageLookupByLibrary.simpleMessage("Hình nền"),
    "dismiss": MessageLookupByLibrary.simpleMessage("Bỏ qua"),
    "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
    "doNotSignOut": MessageLookupByLibrary.simpleMessage("Không đăng xuất"),
    "doThisLater": MessageLookupByLibrary.simpleMessage("Để sau"),
    "doYouWantToDiscardTheEditsYouHaveMade":
        MessageLookupByLibrary.simpleMessage(
          "Bạn có muốn bỏ qua các chỉnh sửa đã thực hiện không?",
        ),
    "doesGroupContainMultiplePeople": MessageLookupByLibrary.simpleMessage(
      "Nhóm này có chứa nhiều người?",
    ),
    "done": MessageLookupByLibrary.simpleMessage("Xong"),
    "dontSave": MessageLookupByLibrary.simpleMessage("Không lưu"),
    "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
      "Nhân đôi dung lượng",
    ),
    "download": MessageLookupByLibrary.simpleMessage("Tải xuống"),
    "downloadFailed": MessageLookupByLibrary.simpleMessage(
      "Tải xuống thất bại",
    ),
    "downloading": MessageLookupByLibrary.simpleMessage("Đang tải xuống..."),
    "draw": MessageLookupByLibrary.simpleMessage("Vẽ"),
    "dropSupportEmail": m26,
    "duplicateFileCountWithStorageSaved": m27,
    "duplicateItemsGroup": m28,
    "edit": MessageLookupByLibrary.simpleMessage("Chỉnh sửa"),
    "editAutoAddPeople": MessageLookupByLibrary.simpleMessage(
      "Sửa tự động thêm người",
    ),
    "editEmailAlreadyLinked": m29,
    "editLocation": MessageLookupByLibrary.simpleMessage("Chỉnh sửa vị trí"),
    "editLocationTagTitle": MessageLookupByLibrary.simpleMessage(
      "Chỉnh sửa vị trí",
    ),
    "editPerson": MessageLookupByLibrary.simpleMessage("Chỉnh sửa người"),
    "editTime": MessageLookupByLibrary.simpleMessage("Chỉnh sửa thời gian"),
    "editsSaved": MessageLookupByLibrary.simpleMessage("Chỉnh sửa đã được lưu"),
    "editsToLocationWillOnlyBeSeenWithinEnte":
        MessageLookupByLibrary.simpleMessage(
          "Các chỉnh sửa vị trí sẽ chỉ thấy được trong Ente",
        ),
    "eligible": MessageLookupByLibrary.simpleMessage("đủ điều kiện"),
    "email": MessageLookupByLibrary.simpleMessage("Email"),
    "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
      "Email đã được đăng ký.",
    ),
    "emailChangedTo": m30,
    "emailDoesNotHaveEnteAccount": m31,
    "emailNoEnteAccount": m32,
    "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
      "Email chưa được đăng ký.",
    ),
    "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
      "Xác minh email",
    ),
    "emailYourLogs": MessageLookupByLibrary.simpleMessage(
      "Gửi nhật ký qua email",
    ),
    "embracingThem": m33,
    "emergencyContacts": MessageLookupByLibrary.simpleMessage(
      "Liên hệ khẩn cấp",
    ),
    "empty": MessageLookupByLibrary.simpleMessage("Xóa sạch"),
    "emptyTrash": MessageLookupByLibrary.simpleMessage("Xóa sạch thùng rác?"),
    "enable": MessageLookupByLibrary.simpleMessage("Bật"),
    "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
      "Ente hỗ trợ học máy trên-thiết-bị nhằm nhận diện khuôn mặt, tìm kiếm vi diệu và các tính năng tìm kiếm nâng cao khác",
    ),
    "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
      "Bật học máy để tìm kiếm vi diệu và nhận diện khuôn mặt",
    ),
    "enableMaps": MessageLookupByLibrary.simpleMessage("Kích hoạt Bản đồ"),
    "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
      "Ảnh của bạn sẽ hiển thị trên bản đồ thế giới.\n\nBản đồ được lưu trữ bởi OpenStreetMap và vị trí chính xác ảnh của bạn không bao giờ được chia sẻ.\n\nBạn có thể tắt tính năng này bất cứ lúc nào từ Cài đặt.",
    ),
    "enabled": MessageLookupByLibrary.simpleMessage("Bật"),
    "encryptingBackup": MessageLookupByLibrary.simpleMessage(
      "Đang mã hóa sao lưu...",
    ),
    "encryption": MessageLookupByLibrary.simpleMessage("Mã hóa"),
    "encryptionKeys": MessageLookupByLibrary.simpleMessage("Khóa mã hóa"),
    "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
      "Điểm cuối đã được cập nhật thành công",
    ),
    "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
      "Mã hóa đầu cuối theo mặc định",
    ),
    "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
        MessageLookupByLibrary.simpleMessage(
          "Ente chỉ có thể mã hóa và lưu giữ tệp nếu bạn cấp quyền truy cập chúng",
        ),
    "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
      "Ente <i>cần quyền để</i> lưu giữ ảnh của bạn",
    ),
    "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
      "Ente lưu giữ kỷ niệm của bạn, vì vậy chúng luôn có sẵn, ngay cả khi bạn mất thiết bị.",
    ),
    "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
      "Bạn có thể thêm gia đình vào gói của mình.",
    ),
    "enterAlbumName": MessageLookupByLibrary.simpleMessage("Nhập tên album"),
    "enterCode": MessageLookupByLibrary.simpleMessage("Nhập mã"),
    "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
      "Nhập mã do bạn bè cung cấp để nhận thêm dung lượng miễn phí cho cả hai",
    ),
    "enterDateOfBirth": MessageLookupByLibrary.simpleMessage(
      "Sinh nhật (tùy chọn)",
    ),
    "enterEmail": MessageLookupByLibrary.simpleMessage("Nhập email"),
    "enterFileName": MessageLookupByLibrary.simpleMessage("Nhập tên tệp"),
    "enterName": MessageLookupByLibrary.simpleMessage("Nhập tên"),
    "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập một mật khẩu mới để mã hóa dữ liệu của bạn",
    ),
    "enterPassword": MessageLookupByLibrary.simpleMessage("Nhập mật khẩu"),
    "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập một mật khẩu dùng để mã hóa dữ liệu của bạn",
    ),
    "enterPersonName": MessageLookupByLibrary.simpleMessage("Nhập tên người"),
    "enterPin": MessageLookupByLibrary.simpleMessage("Nhập PIN"),
    "enterReferralCode": MessageLookupByLibrary.simpleMessage(
      "Nhập mã giới thiệu",
    ),
    "enterThe6digitCodeFromnyourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Nhập mã 6 chữ số từ\nứng dụng xác thực của bạn",
        ),
    "enterValidEmail": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập một địa chỉ email hợp lệ.",
    ),
    "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Nhập địa chỉ email của bạn",
    ),
    "enterYourNewEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Nhập địa chỉ email mới của bạn",
    ),
    "enterYourPassword": MessageLookupByLibrary.simpleMessage(
      "Nhập mật khẩu của bạn",
    ),
    "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Nhập mã khôi phục của bạn",
    ),
    "error": MessageLookupByLibrary.simpleMessage("Lỗi"),
    "everywhere": MessageLookupByLibrary.simpleMessage("mọi nơi"),
    "exif": MessageLookupByLibrary.simpleMessage("Exif"),
    "existingUser": MessageLookupByLibrary.simpleMessage("Người dùng hiện tại"),
    "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
      "Liên kết này đã hết hạn. Vui lòng chọn thời gian hết hạn mới hoặc tắt tính năng hết hạn liên kết.",
    ),
    "exportLogs": MessageLookupByLibrary.simpleMessage("Xuất nhật ký"),
    "exportYourData": MessageLookupByLibrary.simpleMessage(
      "Xuất dữ liệu của bạn",
    ),
    "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
      "Tìm thấy ảnh bổ sung",
    ),
    "extraPhotosFoundFor": m34,
    "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
      "Khuôn mặt chưa được phân cụm, vui lòng quay lại sau",
    ),
    "faceRecognition": MessageLookupByLibrary.simpleMessage(
      "Nhận diện khuôn mặt",
    ),
    "faceThumbnailGenerationFailed": MessageLookupByLibrary.simpleMessage(
      "Không thể tạo ảnh thu nhỏ khuôn mặt",
    ),
    "faces": MessageLookupByLibrary.simpleMessage("Khuôn mặt"),
    "failed": MessageLookupByLibrary.simpleMessage("Không thành công"),
    "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
      "Không thể áp dụng mã",
    ),
    "failedToCancel": MessageLookupByLibrary.simpleMessage(
      "Hủy không thành công",
    ),
    "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
      "Không thể tải video",
    ),
    "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
      "Không thể lấy phiên hoạt động",
    ),
    "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
      "Không thể lấy bản gốc để chỉnh sửa",
    ),
    "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
      "Không thể lấy thông tin giới thiệu. Vui lòng thử lại sau.",
    ),
    "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
      "Không thể tải album",
    ),
    "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
      "Không thể phát video",
    ),
    "failedToRefreshStripeSubscription": MessageLookupByLibrary.simpleMessage(
      "Không thể làm mới gói",
    ),
    "failedToRenew": MessageLookupByLibrary.simpleMessage(
      "Gia hạn không thành công",
    ),
    "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
      "Không thể xác minh trạng thái thanh toán",
    ),
    "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
      "Thêm 5 thành viên gia đình vào gói hiện tại của bạn mà không phải trả thêm phí.\n\nMỗi thành viên có không gian riêng tư của mình và không thể xem tệp của nhau trừ khi được chia sẻ.\n\nGói gia đình có sẵn cho người dùng Ente gói trả phí.\n\nĐăng ký ngay để bắt đầu!",
    ),
    "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("Gia đình"),
    "familyPlans": MessageLookupByLibrary.simpleMessage("Gói gia đình"),
    "faq": MessageLookupByLibrary.simpleMessage("Câu hỏi thường gặp"),
    "faqs": MessageLookupByLibrary.simpleMessage("Câu hỏi thường gặp"),
    "favorite": MessageLookupByLibrary.simpleMessage("Thích"),
    "feastingWithThem": m35,
    "feedback": MessageLookupByLibrary.simpleMessage("Phản hồi"),
    "file": MessageLookupByLibrary.simpleMessage("Tệp"),
    "fileAnalysisFailed": MessageLookupByLibrary.simpleMessage(
      "Không thể xác định tệp",
    ),
    "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
      "Không thể lưu tệp vào thư viện",
    ),
    "fileInfoAddDescHint": MessageLookupByLibrary.simpleMessage(
      "Thêm mô tả...",
    ),
    "fileNotUploadedYet": MessageLookupByLibrary.simpleMessage(
      "Tệp chưa được tải lên",
    ),
    "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Tệp đã được lưu vào thư viện",
    ),
    "fileTypes": MessageLookupByLibrary.simpleMessage("Loại tệp"),
    "fileTypesAndNames": MessageLookupByLibrary.simpleMessage(
      "Loại tệp và tên",
    ),
    "filesBackedUpFromDevice": m36,
    "filesBackedUpInAlbum": m37,
    "filesDeleted": MessageLookupByLibrary.simpleMessage("Tệp đã bị xóa"),
    "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Các tệp đã được lưu vào thư viện",
    ),
    "filter": MessageLookupByLibrary.simpleMessage("Bộ lọc"),
    "findPeopleByName": MessageLookupByLibrary.simpleMessage(
      "Tìm nhanh người theo tên",
    ),
    "findThemQuickly": MessageLookupByLibrary.simpleMessage(
      "Tìm họ nhanh chóng",
    ),
    "flip": MessageLookupByLibrary.simpleMessage("Lật"),
    "font": MessageLookupByLibrary.simpleMessage("Phông chữ"),
    "food": MessageLookupByLibrary.simpleMessage("Ăn chơi"),
    "forYourMemories": MessageLookupByLibrary.simpleMessage(
      "cho những kỷ niệm của bạn",
    ),
    "forgotPassword": MessageLookupByLibrary.simpleMessage("Quên mật khẩu"),
    "foundFaces": MessageLookupByLibrary.simpleMessage("Đã tìm thấy khuôn mặt"),
    "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
      "Dung lượng miễn phí đã nhận",
    ),
    "freeStorageOnReferralSuccess": m38,
    "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
      "Dung lượng miễn phí có thể dùng",
    ),
    "freeTrial": MessageLookupByLibrary.simpleMessage("Dùng thử miễn phí"),
    "freeTrialValidTill": m39,
    "freeUpAccessPostDelete": m40,
    "freeUpAmount": m41,
    "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
      "Giải phóng dung lượng thiết bị",
    ),
    "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
      "Tiết kiệm dung lượng thiết bị của bạn bằng cách xóa các tệp đã được sao lưu.",
    ),
    "freeUpSpace": MessageLookupByLibrary.simpleMessage(
      "Giải phóng dung lượng",
    ),
    "freeUpSpaceSaving": m42,
    "gallery": MessageLookupByLibrary.simpleMessage("Thư viện"),
    "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
      "Mỗi thư viện chứa tối đa 1000 ảnh và video",
    ),
    "general": MessageLookupByLibrary.simpleMessage("Chung"),
    "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
      "Đang mã hóa...",
    ),
    "genericProgress": m43,
    "gettingReady": MessageLookupByLibrary.simpleMessage("Chuẩn bị sẵn sàng"),
    "goToSettings": MessageLookupByLibrary.simpleMessage("Đi đến cài đặt"),
    "googlePlayId": MessageLookupByLibrary.simpleMessage("ID Google Play"),
    "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
      "Vui lòng cho phép truy cập vào tất cả ảnh trong ứng dụng Cài đặt",
    ),
    "grantPermission": MessageLookupByLibrary.simpleMessage("Cấp quyền"),
    "greenery": MessageLookupByLibrary.simpleMessage("Cây cối"),
    "groupBy": MessageLookupByLibrary.simpleMessage("Phân nhóm theo"),
    "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
      "Nhóm ảnh gần nhau",
    ),
    "guestView": MessageLookupByLibrary.simpleMessage("Chế độ khách"),
    "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
      "Để bật chế độ khách, vui lòng thiết lập mã khóa thiết bị hoặc khóa màn hình trong cài đặt hệ thống của bạn.",
    ),
    "happyBirthday": MessageLookupByLibrary.simpleMessage(
      "Chúc mừng sinh nhật! 🥳",
    ),
    "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi không theo dõi cài đặt ứng dụng, nên nếu bạn bật mí bạn tìm thấy chúng tôi từ đâu sẽ rất hữu ích!",
    ),
    "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
      "Bạn biết Ente từ đâu? (tùy chọn)",
    ),
    "help": MessageLookupByLibrary.simpleMessage("Trợ giúp"),
    "hidden": MessageLookupByLibrary.simpleMessage("Ẩn"),
    "hide": MessageLookupByLibrary.simpleMessage("Ẩn"),
    "hideContent": MessageLookupByLibrary.simpleMessage("Ẩn nội dung"),
    "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
      "Ẩn nội dung ứng dụng trong trình chuyển đổi ứng dụng và vô hiệu hóa chụp màn hình",
    ),
    "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
      "Ẩn nội dung ứng dụng trong trình chuyển đổi ứng dụng",
    ),
    "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
      "Ẩn các mục được chia sẻ khỏi thư viện chính",
    ),
    "hiding": MessageLookupByLibrary.simpleMessage("Đang ẩn..."),
    "hikingWithThem": m44,
    "hostedAtOsmFrance": MessageLookupByLibrary.simpleMessage(
      "Được lưu trữ tại OSM Pháp",
    ),
    "howItWorks": MessageLookupByLibrary.simpleMessage("Cách thức hoạt động"),
    "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
      "Hãy chỉ họ nhấn giữ địa chỉ email của họ trên màn hình cài đặt, và xác minh rằng ID trên cả hai thiết bị khớp nhau.",
    ),
    "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Xác thực sinh trắc học chưa được thiết lập trên thiết bị của bạn. Vui lòng kích hoạt Touch ID hoặc Face ID.",
    ),
    "iOSLockOut": MessageLookupByLibrary.simpleMessage(
      "Xác thực sinh trắc học đã bị vô hiệu hóa. Vui lòng khóa và mở khóa màn hình của bạn để kích hoạt lại.",
    ),
    "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
    "ignore": MessageLookupByLibrary.simpleMessage("Bỏ qua"),
    "ignorePerson": MessageLookupByLibrary.simpleMessage("Bỏ qua người"),
    "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Bỏ qua"),
    "ignored": MessageLookupByLibrary.simpleMessage("bỏ qua"),
    "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
      "Một số tệp trong album này bị bỏ qua khi tải lên vì chúng đã bị xóa trước đó từ Ente.",
    ),
    "imageNotAnalyzed": MessageLookupByLibrary.simpleMessage(
      "Hình ảnh chưa được phân tích",
    ),
    "immediately": MessageLookupByLibrary.simpleMessage("Lập tức"),
    "importing": MessageLookupByLibrary.simpleMessage("Đang nhập...."),
    "incorrectCode": MessageLookupByLibrary.simpleMessage("Mã không chính xác"),
    "incorrectPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Mật khẩu không đúng",
    ),
    "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Mã khôi phục không chính xác",
    ),
    "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
      "Mã khôi phục bạn nhập không chính xác",
    ),
    "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
      "Mã khôi phục không chính xác",
    ),
    "indexedItems": MessageLookupByLibrary.simpleMessage(
      "Các mục đã lập chỉ mục",
    ),
    "indexingPausedStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Lập chỉ mục bị tạm dừng. Nó sẽ tự động tiếp tục khi thiết bị đã sẵn sàng. Thiết bị được coi là sẵn sàng khi mức pin, tình trạng pin và trạng thái nhiệt độ nằm trong phạm vi tốt.",
    ),
    "ineligible": MessageLookupByLibrary.simpleMessage("Không đủ điều kiện"),
    "info": MessageLookupByLibrary.simpleMessage("Thông tin"),
    "insecureDevice": MessageLookupByLibrary.simpleMessage(
      "Thiết bị không an toàn",
    ),
    "installManually": MessageLookupByLibrary.simpleMessage("Cài đặt thủ công"),
    "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Địa chỉ email không hợp lệ",
    ),
    "invalidEndpoint": MessageLookupByLibrary.simpleMessage(
      "Điểm cuối không hợp lệ",
    ),
    "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
      "Xin lỗi, điểm cuối bạn nhập không hợp lệ. Vui lòng nhập một điểm cuối hợp lệ và thử lại.",
    ),
    "invalidKey": MessageLookupByLibrary.simpleMessage("Mã không hợp lệ"),
    "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Mã khôi phục không hợp lệ. Vui lòng đảm bảo nó chứa 24 từ, và đúng chính tả từng từ.\n\nNếu bạn nhập loại mã khôi phục cũ, hãy đảm bảo nó dài 64 ký tự, và kiểm tra từng ký tự.",
    ),
    "invite": MessageLookupByLibrary.simpleMessage("Mời"),
    "inviteToEnte": MessageLookupByLibrary.simpleMessage("Mời sử dụng Ente"),
    "inviteYourFriends": MessageLookupByLibrary.simpleMessage(
      "Mời bạn bè của bạn",
    ),
    "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
      "Mời bạn bè dùng Ente",
    ),
    "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
        MessageLookupByLibrary.simpleMessage(
          "Có vẻ đã xảy ra sự cố. Vui lòng thử lại sau ít phút. Nếu lỗi vẫn tiếp diễn, hãy liên hệ với đội ngũ hỗ trợ của chúng tôi.",
        ),
    "itemCount": m45,
    "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
        MessageLookupByLibrary.simpleMessage(
          "Trên các mục là số ngày còn lại trước khi xóa vĩnh viễn",
        ),
    "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
      "Các mục đã chọn sẽ bị xóa khỏi album này",
    ),
    "join": MessageLookupByLibrary.simpleMessage("Tham gia"),
    "joinAlbum": MessageLookupByLibrary.simpleMessage("Tham gia album"),
    "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
      "Tham gia một album sẽ khiến email của bạn hiển thị với những người tham gia khác.",
    ),
    "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
      "để xem và thêm ảnh của bạn",
    ),
    "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
      "để thêm vào album được chia sẻ",
    ),
    "joinDiscord": MessageLookupByLibrary.simpleMessage("Tham gia Discord"),
    "keepPhotos": MessageLookupByLibrary.simpleMessage("Giữ ảnh"),
    "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
    "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
      "Mong bạn giúp chúng tôi thông tin này",
    ),
    "language": MessageLookupByLibrary.simpleMessage("Ngôn ngữ"),
    "lastTimeWithThem": m46,
    "lastUpdated": MessageLookupByLibrary.simpleMessage("Mới cập nhật"),
    "lastWeek": MessageLookupByLibrary.simpleMessage("Tuần trước"),
    "lastYearsTrip": MessageLookupByLibrary.simpleMessage("Phượt năm ngoái"),
    "layout": MessageLookupByLibrary.simpleMessage("Bố cục"),
    "leave": MessageLookupByLibrary.simpleMessage("Rời"),
    "leaveAlbum": MessageLookupByLibrary.simpleMessage("Rời khỏi album"),
    "leaveFamily": MessageLookupByLibrary.simpleMessage("Rời khỏi gia đình"),
    "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
      "Rời album được chia sẻ?",
    ),
    "left": MessageLookupByLibrary.simpleMessage("Trái"),
    "legacy": MessageLookupByLibrary.simpleMessage("Thừa kế"),
    "legacyAccounts": MessageLookupByLibrary.simpleMessage("Tài khoản thừa kế"),
    "legacyInvite": m47,
    "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
      "Thừa kế cho phép các liên hệ tin cậy truy cập tài khoản của bạn khi bạn qua đời.",
    ),
    "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
      "Các liên hệ tin cậy có thể khởi động quá trình khôi phục tài khoản, và nếu không bị chặn trong vòng 30 ngày, có thể đặt lại mật khẩu và truy cập tài khoản của bạn.",
    ),
    "light": MessageLookupByLibrary.simpleMessage("Độ sáng"),
    "lightTheme": MessageLookupByLibrary.simpleMessage("Sáng"),
    "link": MessageLookupByLibrary.simpleMessage("Liên kết"),
    "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Liên kết đã được sao chép vào bộ nhớ tạm",
    ),
    "linkDeviceLimit": MessageLookupByLibrary.simpleMessage(
      "Giới hạn thiết bị",
    ),
    "linkEmail": MessageLookupByLibrary.simpleMessage("Liên kết email"),
    "linkEmailToContactBannerCaption": MessageLookupByLibrary.simpleMessage(
      "để chia sẻ nhanh hơn",
    ),
    "linkEnabled": MessageLookupByLibrary.simpleMessage("Đã bật"),
    "linkExpired": MessageLookupByLibrary.simpleMessage("Hết hạn"),
    "linkExpiresOn": m48,
    "linkExpiry": MessageLookupByLibrary.simpleMessage("Hết hạn liên kết"),
    "linkHasExpired": MessageLookupByLibrary.simpleMessage(
      "Liên kết đã hết hạn",
    ),
    "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Không bao giờ"),
    "linkPerson": MessageLookupByLibrary.simpleMessage("Liên kết người"),
    "linkPersonCaption": MessageLookupByLibrary.simpleMessage(
      "để trải nghiệm chia sẻ tốt hơn",
    ),
    "linkPersonToEmail": m49,
    "linkPersonToEmailConfirmation": m50,
    "livePhotos": MessageLookupByLibrary.simpleMessage("Ảnh động"),
    "loadMessage1": MessageLookupByLibrary.simpleMessage(
      "Bạn có thể chia sẻ gói của mình với gia đình",
    ),
    "loadMessage2": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi đã lưu giữ hơn 200 triệu kỷ niệm cho đến hiện tại",
    ),
    "loadMessage3": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi giữ 3 bản sao dữ liệu của bạn, một cái lưu ở hầm trú ẩn hạt nhân",
    ),
    "loadMessage4": MessageLookupByLibrary.simpleMessage(
      "Tất cả các ứng dụng của chúng tôi đều là mã nguồn mở",
    ),
    "loadMessage5": MessageLookupByLibrary.simpleMessage(
      "Mã nguồn và mã hóa của chúng tôi đã được kiểm nghiệm ngoại bộ",
    ),
    "loadMessage6": MessageLookupByLibrary.simpleMessage(
      "Bạn có thể chia sẻ liên kết đến album của mình với những người thân yêu",
    ),
    "loadMessage7": MessageLookupByLibrary.simpleMessage(
      "Các ứng dụng di động của chúng tôi chạy ngầm để mã hóa và sao lưu bất kỳ ảnh nào bạn mới chụp",
    ),
    "loadMessage8": MessageLookupByLibrary.simpleMessage(
      "web.ente.io có một trình tải lên mượt mà",
    ),
    "loadMessage9": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi sử dụng Xchacha20Poly1305 để mã hóa dữ liệu của bạn",
    ),
    "loadingExifData": MessageLookupByLibrary.simpleMessage(
      "Đang lấy thông số Exif...",
    ),
    "loadingGallery": MessageLookupByLibrary.simpleMessage(
      "Đang tải thư viện...",
    ),
    "loadingMessage": MessageLookupByLibrary.simpleMessage(
      "Đang tải ảnh của bạn...",
    ),
    "loadingModel": MessageLookupByLibrary.simpleMessage("Đang tải mô hình..."),
    "loadingYourPhotos": MessageLookupByLibrary.simpleMessage(
      "Đang tải ảnh của bạn...",
    ),
    "localGallery": MessageLookupByLibrary.simpleMessage("Thư viện cục bộ"),
    "localIndexing": MessageLookupByLibrary.simpleMessage("Chỉ mục cục bộ"),
    "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
      "Có vẻ như có điều gì đó không ổn vì đồng bộ ảnh cục bộ đang tốn nhiều thời gian hơn mong đợi. Vui lòng liên hệ đội ngũ hỗ trợ của chúng tôi",
    ),
    "location": MessageLookupByLibrary.simpleMessage("Vị trí"),
    "locationName": MessageLookupByLibrary.simpleMessage("Tên vị trí"),
    "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
      "Thẻ vị trí sẽ giúp xếp nhóm tất cả ảnh được chụp gần kề nhau",
    ),
    "locations": MessageLookupByLibrary.simpleMessage("Vị trí"),
    "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Khóa"),
    "lockscreen": MessageLookupByLibrary.simpleMessage("Khóa màn hình"),
    "logInLabel": MessageLookupByLibrary.simpleMessage("Đăng nhập"),
    "loggingOut": MessageLookupByLibrary.simpleMessage("Đang đăng xuất..."),
    "loginSessionExpired": MessageLookupByLibrary.simpleMessage(
      "Phiên đăng nhập đã hết hạn",
    ),
    "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
      "Phiên đăng nhập của bạn đã hết hạn. Vui lòng đăng nhập lại.",
    ),
    "loginTerms": MessageLookupByLibrary.simpleMessage(
      "Nhấn vào đăng nhập, tôi đồng ý với <u-terms>điều khoản</u-terms> và <u-policy>chính sách bảo mật</u-policy>",
    ),
    "loginWithTOTP": MessageLookupByLibrary.simpleMessage(
      "Đăng nhập bằng TOTP",
    ),
    "logout": MessageLookupByLibrary.simpleMessage("Đăng xuất"),
    "logsDialogBody": MessageLookupByLibrary.simpleMessage(
      "Gửi file nhật ký để chúng tôi có thể phân tích lỗi mà bạn gặp. Lưu ý rằng, trong nhật ký lỗi sẽ bao gồm tên các tệp để giúp theo dõi vấn đề với từng tệp cụ thể.",
    ),
    "longPressAnEmailToVerifyEndToEndEncryption":
        MessageLookupByLibrary.simpleMessage(
          "Nhấn giữ một email để xác minh mã hóa đầu cuối.",
        ),
    "longpressOnAnItemToViewInFullscreen": MessageLookupByLibrary.simpleMessage(
      "Nhấn giữ một mục để xem toàn màn hình",
    ),
    "lookBackOnYourMemories": MessageLookupByLibrary.simpleMessage(
      "Xem lại kỷ niệm của bạn 🌄",
    ),
    "loopVideoOff": MessageLookupByLibrary.simpleMessage(
      "Dừng phát video lặp lại",
    ),
    "loopVideoOn": MessageLookupByLibrary.simpleMessage("Phát video lặp lại"),
    "lostDevice": MessageLookupByLibrary.simpleMessage("Mất thiết bị?"),
    "machineLearning": MessageLookupByLibrary.simpleMessage("Học máy"),
    "magicSearch": MessageLookupByLibrary.simpleMessage("Tìm kiếm vi diệu"),
    "magicSearchHint": MessageLookupByLibrary.simpleMessage(
      "Tìm kiếm vi diệu cho phép tìm ảnh theo nội dung của chúng, ví dụ: \'xe hơi\', \'xe hơi đỏ\', \'Ferrari\'",
    ),
    "manage": MessageLookupByLibrary.simpleMessage("Quản lý"),
    "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
      "Quản lý bộ nhớ đệm của thiết bị",
    ),
    "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
      "Xem và xóa bộ nhớ đệm trên thiết bị.",
    ),
    "manageFamily": MessageLookupByLibrary.simpleMessage("Quản lý gia đình"),
    "manageLink": MessageLookupByLibrary.simpleMessage("Quản lý liên kết"),
    "manageParticipants": MessageLookupByLibrary.simpleMessage("Quản lý"),
    "manageSubscription": MessageLookupByLibrary.simpleMessage("Quản lý gói"),
    "manualPairDesc": MessageLookupByLibrary.simpleMessage(
      "Kết nối bằng PIN hoạt động với bất kỳ màn hình nào bạn muốn.",
    ),
    "map": MessageLookupByLibrary.simpleMessage("Bản đồ"),
    "maps": MessageLookupByLibrary.simpleMessage("Bản đồ"),
    "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
    "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
    "me": MessageLookupByLibrary.simpleMessage("Tôi"),
    "memories": MessageLookupByLibrary.simpleMessage("Kỷ niệm"),
    "memoriesWidgetDesc": MessageLookupByLibrary.simpleMessage(
      "Chọn những loại kỷ niệm bạn muốn thấy trên màn hình chính của mình.",
    ),
    "memoryCount": m51,
    "merchandise": MessageLookupByLibrary.simpleMessage("Vật phẩm"),
    "merge": MessageLookupByLibrary.simpleMessage("Hợp nhất"),
    "mergeWithExisting": MessageLookupByLibrary.simpleMessage(
      "Hợp nhất với người đã có",
    ),
    "mergedPhotos": MessageLookupByLibrary.simpleMessage("Hợp nhất ảnh"),
    "mixedGrouping": MessageLookupByLibrary.simpleMessage("Nhóm hỗn hợp?"),
    "mlConsent": MessageLookupByLibrary.simpleMessage("Bật học máy"),
    "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
      "Tôi hiểu và muốn bật học máy",
    ),
    "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
      "Nếu bạn bật học máy, Ente sẽ trích xuất thông tin như hình dạng khuôn mặt từ các tệp, gồm cả những tệp mà bạn được chia sẻ.\n\nViệc này sẽ diễn ra trên thiết bị của bạn, với mọi thông tin sinh trắc học tạo ra đều được mã hóa đầu cuối.",
    ),
    "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhấn vào đây để biết thêm chi tiết về tính năng này trong chính sách quyền riêng tư của chúng tôi",
    ),
    "mlConsentTitle": MessageLookupByLibrary.simpleMessage("Bật học máy?"),
    "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
      "Lưu ý rằng việc học máy sẽ khiến tốn băng thông và pin nhiều hơn cho đến khi tất cả mục được lập chỉ mục. Hãy sử dụng ứng dụng máy tính để lập chỉ mục nhanh hơn. Mọi kết quả sẽ được tự động đồng bộ.",
    ),
    "mobileWebDesktop": MessageLookupByLibrary.simpleMessage(
      "Di động, Web, Desktop",
    ),
    "moderateStrength": MessageLookupByLibrary.simpleMessage("Trung bình"),
    "modifyYourQueryOrTrySearchingFor": MessageLookupByLibrary.simpleMessage(
      "Chỉnh sửa truy vấn của bạn, hoặc thử tìm",
    ),
    "moments": MessageLookupByLibrary.simpleMessage("Khoảnh khắc"),
    "month": MessageLookupByLibrary.simpleMessage("tháng"),
    "monthly": MessageLookupByLibrary.simpleMessage("Theo tháng"),
    "moon": MessageLookupByLibrary.simpleMessage("Ánh trăng"),
    "moreDetails": MessageLookupByLibrary.simpleMessage("Thông tin thêm"),
    "mostRecent": MessageLookupByLibrary.simpleMessage("Mới nhất"),
    "mostRelevant": MessageLookupByLibrary.simpleMessage("Liên quan nhất"),
    "mountains": MessageLookupByLibrary.simpleMessage("Đồi núi"),
    "moveItem": m52,
    "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
      "Di chuyển ảnh đã chọn đến một ngày",
    ),
    "moveToAlbum": MessageLookupByLibrary.simpleMessage("Chuyển đến album"),
    "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
      "Di chuyển đến album ẩn",
    ),
    "movedSuccessfullyTo": m53,
    "movedToTrash": MessageLookupByLibrary.simpleMessage(
      "Đã cho vào thùng rác",
    ),
    "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
      "Đang di chuyển tệp vào album...",
    ),
    "name": MessageLookupByLibrary.simpleMessage("Tên"),
    "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Đặt tên cho album"),
    "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
      "Không thể kết nối với Ente, vui lòng thử lại sau ít phút. Nếu lỗi vẫn tiếp diễn, hãy liên hệ với bộ phận hỗ trợ.",
    ),
    "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
      "Không thể kết nối với Ente, vui lòng kiểm tra cài đặt mạng của bạn và liên hệ với bộ phận hỗ trợ nếu lỗi vẫn tiếp diễn.",
    ),
    "never": MessageLookupByLibrary.simpleMessage("Không bao giờ"),
    "newAlbum": MessageLookupByLibrary.simpleMessage("Album mới"),
    "newLocation": MessageLookupByLibrary.simpleMessage("Vị trí mới"),
    "newPerson": MessageLookupByLibrary.simpleMessage("Người mới"),
    "newPhotosEmoji": MessageLookupByLibrary.simpleMessage(" mới 📸"),
    "newRange": MessageLookupByLibrary.simpleMessage("Phạm vi mới"),
    "newToEnte": MessageLookupByLibrary.simpleMessage("Mới dùng Ente"),
    "newest": MessageLookupByLibrary.simpleMessage("Mới nhất"),
    "next": MessageLookupByLibrary.simpleMessage("Tiếp theo"),
    "no": MessageLookupByLibrary.simpleMessage("Không"),
    "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
      "Bạn chưa chia sẻ album nào",
    ),
    "noDeviceFound": MessageLookupByLibrary.simpleMessage(
      "Không tìm thấy thiết bị",
    ),
    "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Không có"),
    "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
      "Bạn không có tệp nào có thể xóa trên thiết bị này",
    ),
    "noDuplicates": MessageLookupByLibrary.simpleMessage(
      "✨ Không có trùng lặp",
    ),
    "noEnteAccountExclamation": MessageLookupByLibrary.simpleMessage(
      "Chưa có tài khoản Ente!",
    ),
    "noExifData": MessageLookupByLibrary.simpleMessage("Không có Exif"),
    "noFacesFound": MessageLookupByLibrary.simpleMessage(
      "Không tìm thấy khuôn mặt",
    ),
    "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
      "Không có ảnh hoặc video ẩn",
    ),
    "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
      "Không có ảnh với vị trí",
    ),
    "noInternetConnection": MessageLookupByLibrary.simpleMessage(
      "Không có kết nối internet",
    ),
    "noPhotosAreBeingBackedUpRightNow": MessageLookupByLibrary.simpleMessage(
      "Hiện tại không có ảnh nào đang được sao lưu",
    ),
    "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage(
      "Không tìm thấy ảnh ở đây",
    ),
    "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
      "Không có liên kết nhanh nào được chọn",
    ),
    "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Không có mã khôi phục?",
    ),
    "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
      "Do tính chất của giao thức mã hóa đầu cuối, không thể giải mã dữ liệu của bạn mà không có mật khẩu hoặc mã khôi phục",
    ),
    "noResults": MessageLookupByLibrary.simpleMessage("Không có kết quả"),
    "noResultsFound": MessageLookupByLibrary.simpleMessage(
      "Không tìm thấy kết quả",
    ),
    "noSuggestionsForPerson": m54,
    "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
      "Không tìm thấy khóa hệ thống",
    ),
    "notPersonLabel": m55,
    "notThisPerson": MessageLookupByLibrary.simpleMessage(
      "Không phải người này?",
    ),
    "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
      "Bạn chưa được chia sẻ gì",
    ),
    "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
      "Ở đây không có gì để xem! 👀",
    ),
    "notifications": MessageLookupByLibrary.simpleMessage("Thông báo"),
    "ok": MessageLookupByLibrary.simpleMessage("Được"),
    "onDevice": MessageLookupByLibrary.simpleMessage("Trên thiết bị"),
    "onEnte": MessageLookupByLibrary.simpleMessage(
      "Trên <branding>ente</branding>",
    ),
    "onTheRoad": MessageLookupByLibrary.simpleMessage("Trên đường"),
    "onThisDay": MessageLookupByLibrary.simpleMessage("Vào ngày này"),
    "onThisDayMemories": MessageLookupByLibrary.simpleMessage(
      "Kỷ niệm hôm nay",
    ),
    "onThisDayNotificationExplanation": MessageLookupByLibrary.simpleMessage(
      "Nhắc về những kỷ niệm ngày này trong những năm trước.",
    ),
    "onlyFamilyAdminCanChangeCode": m56,
    "onlyThem": MessageLookupByLibrary.simpleMessage("Chỉ họ"),
    "oops": MessageLookupByLibrary.simpleMessage("Ốii!"),
    "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
      "Ốii!, không thể lưu chỉnh sửa",
    ),
    "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
      "Ốii!, có gì đó không ổn",
    ),
    "openAlbumInBrowser": MessageLookupByLibrary.simpleMessage(
      "Mở album trong trình duyệt",
    ),
    "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
      "Vui lòng sử dụng ứng dụng web để thêm ảnh vào album này",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Mở tệp"),
    "openSettings": MessageLookupByLibrary.simpleMessage("Mở Cài đặt"),
    "openTheItem": MessageLookupByLibrary.simpleMessage("• Mở mục"),
    "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
      "Người đóng góp OpenStreetMap",
    ),
    "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
      "Tùy chọn, ngắn dài tùy ý...",
    ),
    "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
      "Hoặc hợp nhất với hiện có",
    ),
    "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
      "Hoặc chọn một cái có sẵn",
    ),
    "orPickFromYourContacts": MessageLookupByLibrary.simpleMessage(
      "hoặc chọn từ danh bạ",
    ),
    "otherDetectedFaces": MessageLookupByLibrary.simpleMessage(
      "Những khuôn mặt khác được phát hiện",
    ),
    "pair": MessageLookupByLibrary.simpleMessage("Kết nối"),
    "pairWithPin": MessageLookupByLibrary.simpleMessage("Kết nối bằng PIN"),
    "pairingComplete": MessageLookupByLibrary.simpleMessage("Kết nối hoàn tất"),
    "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
    "partyWithThem": m57,
    "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
      "Xác minh vẫn đang chờ",
    ),
    "passkey": MessageLookupByLibrary.simpleMessage("Khóa truy cập"),
    "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
      "Xác minh khóa truy cập",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Mật khẩu"),
    "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Đã thay đổi mật khẩu thành công",
    ),
    "passwordLock": MessageLookupByLibrary.simpleMessage("Khóa bằng mật khẩu"),
    "passwordStrength": m58,
    "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
      "Độ mạnh của mật khẩu được tính toán dựa trên độ dài của mật khẩu, các ký tự đã sử dụng và liệu mật khẩu có xuất hiện trong 10.000 mật khẩu được sử dụng nhiều nhất hay không",
    ),
    "passwordWarning": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi không lưu trữ mật khẩu này, nên nếu bạn quên, <underline>chúng tôi không thể giải mã dữ liệu của bạn</underline>",
    ),
    "pastYearsMemories": MessageLookupByLibrary.simpleMessage(
      "Kỷ niệm năm ngoái",
    ),
    "paymentDetails": MessageLookupByLibrary.simpleMessage(
      "Chi tiết thanh toán",
    ),
    "paymentFailed": MessageLookupByLibrary.simpleMessage(
      "Thanh toán thất bại",
    ),
    "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
      "Rất tiếc, bạn đã thanh toán không thành công. Vui lòng liên hệ hỗ trợ và chúng tôi sẽ giúp bạn!",
    ),
    "paymentFailedTalkToProvider": m59,
    "pendingItems": MessageLookupByLibrary.simpleMessage("Các mục đang chờ"),
    "pendingSync": MessageLookupByLibrary.simpleMessage("Đồng bộ hóa đang chờ"),
    "people": MessageLookupByLibrary.simpleMessage("Người"),
    "peopleAutoAddDesc": MessageLookupByLibrary.simpleMessage(
      "Chọn những người bạn muốn tự động thêm vào album",
    ),
    "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
      "Người dùng mã của bạn",
    ),
    "peopleWidgetDesc": MessageLookupByLibrary.simpleMessage(
      "Chọn những người bạn muốn thấy trên màn hình chính của mình.",
    ),
    "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
      "Tất cả các mục trong thùng rác sẽ bị xóa vĩnh viễn\n\nKhông thể hoàn tác thao tác này",
    ),
    "permanentlyDelete": MessageLookupByLibrary.simpleMessage("Xóa vĩnh viễn"),
    "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
      "Xóa vĩnh viễn khỏi thiết bị?",
    ),
    "personIsAge": m60,
    "personName": MessageLookupByLibrary.simpleMessage("Tên người"),
    "personTurningAge": m61,
    "pets": MessageLookupByLibrary.simpleMessage("Thú cưng"),
    "photoDescriptions": MessageLookupByLibrary.simpleMessage("Mô tả ảnh"),
    "photoGridSize": MessageLookupByLibrary.simpleMessage(
      "Kích thước lưới ảnh",
    ),
    "photoSmallCase": MessageLookupByLibrary.simpleMessage("ảnh"),
    "photocountPhotos": m62,
    "photos": MessageLookupByLibrary.simpleMessage("Ảnh"),
    "photosAddedByYouWillBeRemovedFromTheAlbum":
        MessageLookupByLibrary.simpleMessage(
          "Ảnh bạn đã thêm sẽ bị xóa khỏi album",
        ),
    "photosCount": m63,
    "photosKeepRelativeTimeDifference": MessageLookupByLibrary.simpleMessage(
      "Ảnh giữ nguyên chênh lệch thời gian tương đối",
    ),
    "pickCenterPoint": MessageLookupByLibrary.simpleMessage("Chọn tâm điểm"),
    "pinAlbum": MessageLookupByLibrary.simpleMessage("Ghim album"),
    "pinLock": MessageLookupByLibrary.simpleMessage("Khóa PIN"),
    "playOnTv": MessageLookupByLibrary.simpleMessage("Phát album trên TV"),
    "playOriginal": MessageLookupByLibrary.simpleMessage("Phát tệp gốc"),
    "playStoreFreeTrialValidTill": m64,
    "playStream": MessageLookupByLibrary.simpleMessage("Phát trực tiếp"),
    "playstoreSubscription": MessageLookupByLibrary.simpleMessage(
      "Gói PlayStore",
    ),
    "pleaseCheckYourInternetConnectionAndTryAgain":
        MessageLookupByLibrary.simpleMessage(
          "Vui lòng kiểm tra kết nối internet của bạn và thử lại.",
        ),
    "pleaseContactSupportAndWeWillBeHappyToHelp":
        MessageLookupByLibrary.simpleMessage(
          "Vui lòng liên hệ support@ente.io và chúng tôi rất sẵn sàng giúp đỡ!",
        ),
    "pleaseContactSupportIfTheProblemPersists":
        MessageLookupByLibrary.simpleMessage(
          "Vui lòng liên hệ bộ phận hỗ trợ nếu vấn đề vẫn tiếp diễn",
        ),
    "pleaseEmailUsAt": m65,
    "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
      "Vui lòng cấp quyền",
    ),
    "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
      "Vui lòng đăng nhập lại",
    ),
    "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
      "Vui lòng chọn liên kết nhanh để xóa",
    ),
    "pleaseSendTheLogsTo": m66,
    "pleaseTryAgain": MessageLookupByLibrary.simpleMessage("Vui lòng thử lại"),
    "pleaseVerifyTheCodeYouHaveEntered": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xác minh mã bạn đã nhập",
    ),
    "pleaseWait": MessageLookupByLibrary.simpleMessage("Vui lòng chờ..."),
    "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
      "Vui lòng chờ, đang xóa album",
    ),
    "pleaseWaitForSometimeBeforeRetrying": MessageLookupByLibrary.simpleMessage(
      "Vui lòng chờ một chút trước khi thử lại",
    ),
    "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
      "Vui lòng chờ, có thể mất một lúc.",
    ),
    "posingWithThem": m67,
    "preparingLogs": MessageLookupByLibrary.simpleMessage(
      "Đang ghi nhật ký...",
    ),
    "preserveMore": MessageLookupByLibrary.simpleMessage("Lưu giữ nhiều hơn"),
    "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
      "Nhấn giữ để phát video",
    ),
    "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
      "Nhấn giữ ảnh để phát video",
    ),
    "previous": MessageLookupByLibrary.simpleMessage("Trước"),
    "privacy": MessageLookupByLibrary.simpleMessage("Bảo mật"),
    "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
      "Chính sách bảo mật",
    ),
    "privateBackups": MessageLookupByLibrary.simpleMessage("Sao lưu riêng tư"),
    "privateSharing": MessageLookupByLibrary.simpleMessage("Chia sẻ riêng tư"),
    "proceed": MessageLookupByLibrary.simpleMessage("Tiếp tục"),
    "processed": MessageLookupByLibrary.simpleMessage("Đã xử lý"),
    "processing": MessageLookupByLibrary.simpleMessage("Đang xử lý"),
    "processingImport": m68,
    "processingVideos": MessageLookupByLibrary.simpleMessage(
      "Đang xử lý video",
    ),
    "publicLinkCreated": MessageLookupByLibrary.simpleMessage(
      "Liên kết công khai đã được tạo",
    ),
    "publicLinkEnabled": MessageLookupByLibrary.simpleMessage(
      "Liên kết công khai đã được bật",
    ),
    "questionmark": MessageLookupByLibrary.simpleMessage("?"),
    "queued": MessageLookupByLibrary.simpleMessage("Đang chờ"),
    "quickLinks": MessageLookupByLibrary.simpleMessage("Liên kết nhanh"),
    "radius": MessageLookupByLibrary.simpleMessage("Bán kính"),
    "raiseTicket": MessageLookupByLibrary.simpleMessage("Yêu cầu hỗ trợ"),
    "rateTheApp": MessageLookupByLibrary.simpleMessage("Đánh giá ứng dụng"),
    "rateUs": MessageLookupByLibrary.simpleMessage("Đánh giá chúng tôi"),
    "rateUsOnStore": m69,
    "reassignMe": MessageLookupByLibrary.simpleMessage("Chỉ định lại \"Tôi\""),
    "reassignedToName": m70,
    "reassigningLoading": MessageLookupByLibrary.simpleMessage(
      "Đang chỉ định lại...",
    ),
    "receiveRemindersOnBirthdays": MessageLookupByLibrary.simpleMessage(
      "Nhắc khi đến sinh nhật của ai đó. Nhấn vào thông báo sẽ đưa bạn đến ảnh của người sinh nhật.",
    ),
    "recover": MessageLookupByLibrary.simpleMessage("Khôi phục"),
    "recoverAccount": MessageLookupByLibrary.simpleMessage(
      "Khôi phục tài khoản",
    ),
    "recoverButton": MessageLookupByLibrary.simpleMessage("Khôi phục"),
    "recoveryAccount": MessageLookupByLibrary.simpleMessage(
      "Khôi phục tài khoản",
    ),
    "recoveryInitiated": MessageLookupByLibrary.simpleMessage(
      "Quá trình khôi phục đã được khởi động",
    ),
    "recoveryInitiatedDesc": m71,
    "recoveryKey": MessageLookupByLibrary.simpleMessage("Mã khôi phục"),
    "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Đã sao chép mã khôi phục vào bộ nhớ tạm",
    ),
    "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
      "Nếu bạn quên mật khẩu, cách duy nhất để khôi phục dữ liệu của bạn là dùng mã này.",
    ),
    "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi không lưu trữ mã này, nên hãy lưu nó ở nơi an toàn.",
    ),
    "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
      "Tuyệt! Mã khôi phục của bạn hợp lệ. Cảm ơn đã xác minh.\n\nNhớ lưu giữ mã khôi phục của bạn ở nơi an toàn.",
    ),
    "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
      "Mã khôi phục đã được xác minh",
    ),
    "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
      "Mã khôi phục là cách duy nhất để khôi phục ảnh của bạn nếu bạn quên mật khẩu. Bạn có thể xem mã khôi phục của mình trong Cài đặt > Tài khoản.\n\nVui lòng nhập mã khôi phục của bạn ở đây để xác minh rằng bạn đã lưu nó đúng cách.",
    ),
    "recoveryReady": m72,
    "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
      "Khôi phục thành công!",
    ),
    "recoveryWarning": MessageLookupByLibrary.simpleMessage(
      "Một liên hệ tin cậy đang cố gắng truy cập tài khoản của bạn",
    ),
    "recoveryWarningBody": m73,
    "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
      "Thiết bị hiện tại không đủ mạnh để xác minh mật khẩu của bạn, nhưng chúng tôi có thể tạo lại để nó hoạt động với tất cả thiết bị.\n\nVui lòng đăng nhập bằng mã khôi phục và tạo lại mật khẩu (bạn có thể dùng lại mật khẩu cũ nếu muốn).",
    ),
    "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Tạo lại mật khẩu",
    ),
    "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
    "redo": MessageLookupByLibrary.simpleMessage("Làm lại"),
    "reenterPassword": MessageLookupByLibrary.simpleMessage(
      "Nhập lại mật khẩu",
    ),
    "reenterPin": MessageLookupByLibrary.simpleMessage("Nhập lại PIN"),
    "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
      "Giới thiệu bạn bè để được ×2 dung lượng gói của bạn",
    ),
    "referralStep1": MessageLookupByLibrary.simpleMessage(
      "1. Đưa mã này cho bạn bè của bạn",
    ),
    "referralStep2": MessageLookupByLibrary.simpleMessage(
      "2. Họ đăng ký gói trả phí",
    ),
    "referralStep3": m74,
    "referrals": MessageLookupByLibrary.simpleMessage("Giới thiệu"),
    "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
      "Giới thiệu hiện đang tạm dừng",
    ),
    "rejectRecovery": MessageLookupByLibrary.simpleMessage("Từ chối khôi phục"),
    "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
      "Hãy xóa luôn \"Đã xóa gần đây\" từ \"Cài đặt\" -> \"Lưu trữ\" để lấy lại dung lượng đã giải phóng",
    ),
    "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
      "Hãy xóa luôn \"Thùng rác\" của bạn để lấy lại dung lượng đã giải phóng",
    ),
    "remoteImages": MessageLookupByLibrary.simpleMessage("Ảnh bên ngoài"),
    "remoteThumbnails": MessageLookupByLibrary.simpleMessage(
      "Ảnh thu nhỏ bên ngoài",
    ),
    "remoteVideos": MessageLookupByLibrary.simpleMessage("Video bên ngoài"),
    "remove": MessageLookupByLibrary.simpleMessage("Xóa"),
    "removeDuplicates": MessageLookupByLibrary.simpleMessage("Xóa trùng lặp"),
    "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
      "Xem và xóa các tệp bị trùng lặp.",
    ),
    "removeFromAlbum": MessageLookupByLibrary.simpleMessage("Xóa khỏi album"),
    "removeFromAlbumTitle": MessageLookupByLibrary.simpleMessage(
      "Xóa khỏi album?",
    ),
    "removeFromFavorite": MessageLookupByLibrary.simpleMessage(
      "Xóa khỏi mục đã thích",
    ),
    "removeInvite": MessageLookupByLibrary.simpleMessage("Gỡ bỏ lời mời"),
    "removeLink": MessageLookupByLibrary.simpleMessage("Xóa liên kết"),
    "removeParticipant": MessageLookupByLibrary.simpleMessage(
      "Xóa người tham gia",
    ),
    "removeParticipantBody": m75,
    "removePersonLabel": MessageLookupByLibrary.simpleMessage("Xóa nhãn người"),
    "removePublicLink": MessageLookupByLibrary.simpleMessage(
      "Xóa liên kết công khai",
    ),
    "removePublicLinks": MessageLookupByLibrary.simpleMessage(
      "Xóa liên kết công khai",
    ),
    "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
      "Vài mục mà bạn đang xóa được thêm bởi người khác, và bạn sẽ mất quyền truy cập vào chúng",
    ),
    "removeWithQuestionMark": MessageLookupByLibrary.simpleMessage("Xóa?"),
    "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
      "Gỡ bỏ bạn khỏi liên hệ tin cậy",
    ),
    "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
      "Đang xóa khỏi mục yêu thích...",
    ),
    "rename": MessageLookupByLibrary.simpleMessage("Đổi tên"),
    "renameAlbum": MessageLookupByLibrary.simpleMessage("Đổi tên album"),
    "renameFile": MessageLookupByLibrary.simpleMessage("Đổi tên tệp"),
    "renewSubscription": MessageLookupByLibrary.simpleMessage("Gia hạn gói"),
    "renewsOn": m76,
    "reportABug": MessageLookupByLibrary.simpleMessage("Báo lỗi"),
    "reportBug": MessageLookupByLibrary.simpleMessage("Báo lỗi"),
    "resendEmail": MessageLookupByLibrary.simpleMessage("Gửi lại email"),
    "reset": MessageLookupByLibrary.simpleMessage("Đặt lại"),
    "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
      "Đặt lại các tệp bị bỏ qua",
    ),
    "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Đặt lại mật khẩu",
    ),
    "resetPerson": MessageLookupByLibrary.simpleMessage("Xóa"),
    "resetToDefault": MessageLookupByLibrary.simpleMessage("Đặt lại mặc định"),
    "restore": MessageLookupByLibrary.simpleMessage("Khôi phục"),
    "restoreToAlbum": MessageLookupByLibrary.simpleMessage(
      "Khôi phục vào album",
    ),
    "restoringFiles": MessageLookupByLibrary.simpleMessage(
      "Đang khôi phục tệp...",
    ),
    "resumableUploads": MessageLookupByLibrary.simpleMessage(
      "Cho phép tải lên tiếp tục",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Thử lại"),
    "review": MessageLookupByLibrary.simpleMessage("Xem lại"),
    "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
      "Vui lòng xem qua và xóa các mục mà bạn tin là trùng lặp.",
    ),
    "reviewSuggestions": MessageLookupByLibrary.simpleMessage("Xem gợi ý"),
    "right": MessageLookupByLibrary.simpleMessage("Phải"),
    "roadtripWithThem": m77,
    "rotate": MessageLookupByLibrary.simpleMessage("Xoay"),
    "rotateLeft": MessageLookupByLibrary.simpleMessage("Xoay trái"),
    "rotateRight": MessageLookupByLibrary.simpleMessage("Xoay phải"),
    "safelyStored": MessageLookupByLibrary.simpleMessage("Lưu trữ an toàn"),
    "same": MessageLookupByLibrary.simpleMessage("Chính xác"),
    "sameperson": MessageLookupByLibrary.simpleMessage("Cùng một người?"),
    "save": MessageLookupByLibrary.simpleMessage("Lưu"),
    "saveAsAnotherPerson": MessageLookupByLibrary.simpleMessage(
      "Lưu như một người khác",
    ),
    "saveChangesBeforeLeavingQuestion": MessageLookupByLibrary.simpleMessage(
      "Lưu thay đổi trước khi rời?",
    ),
    "saveCollage": MessageLookupByLibrary.simpleMessage("Lưu ảnh ghép"),
    "saveCopy": MessageLookupByLibrary.simpleMessage("Lưu bản sao"),
    "saveKey": MessageLookupByLibrary.simpleMessage("Lưu mã"),
    "savePerson": MessageLookupByLibrary.simpleMessage("Lưu người"),
    "saveYourRecoveryKeyIfYouHaventAlready":
        MessageLookupByLibrary.simpleMessage(
          "Lưu mã khôi phục của bạn nếu bạn chưa làm",
        ),
    "saving": MessageLookupByLibrary.simpleMessage("Đang lưu..."),
    "savingEdits": MessageLookupByLibrary.simpleMessage(
      "Đang lưu chỉnh sửa...",
    ),
    "scanCode": MessageLookupByLibrary.simpleMessage("Quét mã"),
    "scanThisBarcodeWithnyourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Quét mã vạch này bằng\nứng dụng xác thực của bạn",
        ),
    "search": MessageLookupByLibrary.simpleMessage("Tìm kiếm"),
    "searchAlbumsEmptySection": MessageLookupByLibrary.simpleMessage("Album"),
    "searchByAlbumNameHint": MessageLookupByLibrary.simpleMessage("Tên album"),
    "searchByExamples": MessageLookupByLibrary.simpleMessage(
      "• Tên album (vd: \"Camera\")\n• Loại tệp (vd: \"Video\", \".gif\")\n• Năm và tháng (vd: \"2022\", \"Tháng Một\")\n• Ngày lễ (vd: \"Giáng Sinh\")\n• Mô tả ảnh (vd: “#vui”)",
    ),
    "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
      "Thêm mô tả như \"#phượt\" trong thông tin ảnh để tìm nhanh thấy chúng ở đây",
    ),
    "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
      "Tìm kiếm theo ngày, tháng hoặc năm",
    ),
    "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
      "Ảnh sẽ được hiển thị ở đây sau khi xử lý và đồng bộ hoàn tất",
    ),
    "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
      "Người sẽ được hiển thị ở đây khi quá trình xử lý hoàn tất",
    ),
    "searchFileTypesAndNamesEmptySection": MessageLookupByLibrary.simpleMessage(
      "Loại tệp và tên",
    ),
    "searchHint1": MessageLookupByLibrary.simpleMessage(
      "Tìm kiếm nhanh, trên thiết bị",
    ),
    "searchHint2": MessageLookupByLibrary.simpleMessage("Ngày chụp, mô tả ảnh"),
    "searchHint3": MessageLookupByLibrary.simpleMessage(
      "Album, tên tệp và loại",
    ),
    "searchHint4": MessageLookupByLibrary.simpleMessage("Vị trí"),
    "searchHint5": MessageLookupByLibrary.simpleMessage(
      "Sắp ra mắt: Nhận diện khuôn mặt & tìm kiếm vi diệu ✨",
    ),
    "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
      "Xếp nhóm những ảnh được chụp gần kề nhau",
    ),
    "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
      "Mời mọi người, và bạn sẽ thấy tất cả ảnh mà họ chia sẻ ở đây",
    ),
    "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
      "Người sẽ được hiển thị ở đây sau khi hoàn tất xử lý và đồng bộ",
    ),
    "searchResultCount": m78,
    "searchSectionsLengthMismatch": m79,
    "security": MessageLookupByLibrary.simpleMessage("Bảo mật"),
    "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
      "Xem liên kết album công khai trong ứng dụng",
    ),
    "selectALocation": MessageLookupByLibrary.simpleMessage("Chọn một vị trí"),
    "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
      "Chọn một vị trí trước",
    ),
    "selectAlbum": MessageLookupByLibrary.simpleMessage("Chọn album"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Chọn tất cả"),
    "selectAllShort": MessageLookupByLibrary.simpleMessage("Tất cả"),
    "selectCoverPhoto": MessageLookupByLibrary.simpleMessage("Chọn ảnh bìa"),
    "selectDate": MessageLookupByLibrary.simpleMessage("Chọn ngày"),
    "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
      "Chọn thư mục để sao lưu",
    ),
    "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
      "Chọn mục để thêm",
    ),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Chọn ngôn ngữ"),
    "selectMailApp": MessageLookupByLibrary.simpleMessage(
      "Chọn ứng dụng email",
    ),
    "selectMorePhotos": MessageLookupByLibrary.simpleMessage("Chọn thêm ảnh"),
    "selectOneDateAndTime": MessageLookupByLibrary.simpleMessage(
      "Chọn một ngày và giờ",
    ),
    "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
      "Chọn một ngày và giờ cho tất cả",
    ),
    "selectPersonToLink": MessageLookupByLibrary.simpleMessage(
      "Chọn người để liên kết",
    ),
    "selectReason": MessageLookupByLibrary.simpleMessage("Chọn lý do"),
    "selectStartOfRange": MessageLookupByLibrary.simpleMessage(
      "Chọn phạm vi bắt đầu",
    ),
    "selectTime": MessageLookupByLibrary.simpleMessage("Chọn thời gian"),
    "selectYourFace": MessageLookupByLibrary.simpleMessage(
      "Chọn khuôn mặt bạn",
    ),
    "selectYourPlan": MessageLookupByLibrary.simpleMessage("Chọn gói của bạn"),
    "selectedAlbums": m80,
    "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
      "Các tệp đã chọn không có trên Ente",
    ),
    "selectedFoldersWillBeEncryptedAndBackedUp":
        MessageLookupByLibrary.simpleMessage(
          "Các thư mục đã chọn sẽ được mã hóa và sao lưu",
        ),
    "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
        MessageLookupByLibrary.simpleMessage(
          "Các tệp đã chọn sẽ bị xóa khỏi tất cả album và cho vào thùng rác.",
        ),
    "selectedItemsWillBeRemovedFromThisPerson":
        MessageLookupByLibrary.simpleMessage(
          "Các mục đã chọn sẽ bị xóa khỏi người này, nhưng không bị xóa khỏi thư viện của bạn.",
        ),
    "selectedPhotos": m81,
    "selectedPhotosWithYours": m82,
    "selfiesWithThem": m83,
    "send": MessageLookupByLibrary.simpleMessage("Gửi"),
    "sendEmail": MessageLookupByLibrary.simpleMessage("Gửi email"),
    "sendInvite": MessageLookupByLibrary.simpleMessage("Gửi lời mời"),
    "sendLink": MessageLookupByLibrary.simpleMessage("Gửi liên kết"),
    "serverEndpoint": MessageLookupByLibrary.simpleMessage("Điểm cuối máy chủ"),
    "sessionExpired": MessageLookupByLibrary.simpleMessage("Phiên đã hết hạn"),
    "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
      "Mã phiên không khớp",
    ),
    "setAPassword": MessageLookupByLibrary.simpleMessage("Đặt mật khẩu"),
    "setAs": MessageLookupByLibrary.simpleMessage("Đặt làm"),
    "setCover": MessageLookupByLibrary.simpleMessage("Đặt ảnh bìa"),
    "setLabel": MessageLookupByLibrary.simpleMessage("Đặt"),
    "setNewPassword": MessageLookupByLibrary.simpleMessage("Đặt mật khẩu mới"),
    "setNewPin": MessageLookupByLibrary.simpleMessage("Đặt PIN mới"),
    "setPasswordTitle": MessageLookupByLibrary.simpleMessage("Đặt mật khẩu"),
    "setRadius": MessageLookupByLibrary.simpleMessage("Đặt bán kính"),
    "setupComplete": MessageLookupByLibrary.simpleMessage("Cài đặt hoàn tất"),
    "share": MessageLookupByLibrary.simpleMessage("Chia sẻ"),
    "shareALink": MessageLookupByLibrary.simpleMessage("Chia sẻ một liên kết"),
    "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
      "Mở album và nhấn nút chia sẻ ở góc trên bên phải để chia sẻ.",
    ),
    "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage(
      "Chia sẻ ngay một album",
    ),
    "shareLink": MessageLookupByLibrary.simpleMessage("Chia sẻ liên kết"),
    "shareMyVerificationID": m84,
    "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
      "Chỉ chia sẻ với những người bạn muốn",
    ),
    "shareTextConfirmOthersVerificationID": m85,
    "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
      "Tải Ente để chúng ta có thể dễ dàng chia sẻ ảnh và video chất lượng gốc\n\nhttps://ente.io",
    ),
    "shareTextReferralCode": m86,
    "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
      "Chia sẻ với người không dùng Ente",
    ),
    "shareWithPeopleSectionTitle": m87,
    "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
      "Chia sẻ album đầu tiên của bạn",
    ),
    "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
      "Tạo album chia sẻ và cộng tác với người dùng Ente khác, bao gồm người dùng gói miễn phí.",
    ),
    "sharedByMe": MessageLookupByLibrary.simpleMessage("Chia sẻ bởi tôi"),
    "sharedByYou": MessageLookupByLibrary.simpleMessage("Được chia sẻ bởi bạn"),
    "sharedPhotoNotifications": MessageLookupByLibrary.simpleMessage(
      "Ảnh chia sẻ mới",
    ),
    "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
      "Nhận thông báo khi ai đó thêm ảnh vào album chia sẻ mà bạn tham gia.",
    ),
    "sharedWith": m88,
    "sharedWithMe": MessageLookupByLibrary.simpleMessage("Chia sẻ với tôi"),
    "sharedWithYou": MessageLookupByLibrary.simpleMessage(
      "Được chia sẻ với bạn",
    ),
    "sharing": MessageLookupByLibrary.simpleMessage("Đang chia sẻ..."),
    "shiftDatesAndTime": MessageLookupByLibrary.simpleMessage(
      "Di chuyển ngày và giờ",
    ),
    "shouldRemoveFilesSmartAlbumsDesc": MessageLookupByLibrary.simpleMessage(
      "Bạn có muốn xóa các tệp liên quan đến người đã được chọn trước đó trong album thông minh không?",
    ),
    "showLessFaces": MessageLookupByLibrary.simpleMessage(
      "Hiện ít khuôn mặt hơn",
    ),
    "showMemories": MessageLookupByLibrary.simpleMessage("Xem lại kỷ niệm"),
    "showMoreFaces": MessageLookupByLibrary.simpleMessage(
      "Hiện nhiều khuôn mặt hơn",
    ),
    "showPerson": MessageLookupByLibrary.simpleMessage("Hiện người"),
    "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
      "Đăng xuất khỏi các thiết bị khác",
    ),
    "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
      "Nếu bạn nghĩ rằng ai đó biết mật khẩu của bạn, hãy ép tài khoản của bạn đăng xuất khỏi tất cả thiết bị khác đang sử dụng.",
    ),
    "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
      "Đăng xuất khỏi các thiết bị khác",
    ),
    "signUpTerms": MessageLookupByLibrary.simpleMessage(
      "Tôi đồng ý với <u-terms>điều khoản</u-terms> và <u-policy>chính sách bảo mật</u-policy>",
    ),
    "singleFileDeleteFromDevice": m89,
    "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
      "Nó sẽ bị xóa khỏi tất cả album.",
    ),
    "singleFileInBothLocalAndRemote": m90,
    "singleFileInRemoteOnly": m91,
    "skip": MessageLookupByLibrary.simpleMessage("Bỏ qua"),
    "smartMemories": MessageLookupByLibrary.simpleMessage("Gợi nhớ kỷ niệm"),
    "social": MessageLookupByLibrary.simpleMessage("Mạng xã hội"),
    "someItemsAreInBothEnteAndYourDevice": MessageLookupByLibrary.simpleMessage(
      "Một số mục có trên cả Ente và thiết bị của bạn.",
    ),
    "someOfTheFilesYouAreTryingToDeleteAre": MessageLookupByLibrary.simpleMessage(
      "Một số tệp bạn đang cố gắng xóa chỉ có trên thiết bị của bạn và không thể khôi phục nếu bị xóa",
    ),
    "someoneSharingAlbumsWithYouShouldSeeTheSameId":
        MessageLookupByLibrary.simpleMessage(
          "Ai đó chia sẻ album với bạn nên thấy cùng một ID trên thiết bị của họ.",
        ),
    "somethingWentWrong": MessageLookupByLibrary.simpleMessage(
      "Có gì đó không ổn",
    ),
    "somethingWentWrongPleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Có gì đó không ổn, vui lòng thử lại",
    ),
    "sorry": MessageLookupByLibrary.simpleMessage("Xin lỗi"),
    "sorryBackupFailedDesc": MessageLookupByLibrary.simpleMessage(
      "Rất tiếc, không thể sao lưu tệp vào lúc này, chúng tôi sẽ thử lại sau.",
    ),
    "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
      "Xin lỗi, không thể thêm vào mục yêu thích!",
    ),
    "sorryCouldNotRemoveFromFavorites": MessageLookupByLibrary.simpleMessage(
      "Xin lỗi, không thể xóa khỏi mục yêu thích!",
    ),
    "sorryTheCodeYouveEnteredIsIncorrect": MessageLookupByLibrary.simpleMessage(
      "Rất tiếc, mã bạn nhập không chính xác",
    ),
    "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
        MessageLookupByLibrary.simpleMessage(
          "Rất tiếc, chúng tôi không thể tạo khóa an toàn trên thiết bị này.\n\nVui lòng đăng ký từ một thiết bị khác.",
        ),
    "sorryWeHadToPauseYourBackups": MessageLookupByLibrary.simpleMessage(
      "Rất tiếc, chúng tôi phải dừng sao lưu cho bạn",
    ),
    "sort": MessageLookupByLibrary.simpleMessage("Sắp xếp"),
    "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sắp xếp theo"),
    "sortNewestFirst": MessageLookupByLibrary.simpleMessage("Mới nhất trước"),
    "sortOldestFirst": MessageLookupByLibrary.simpleMessage("Cũ nhất trước"),
    "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Thành công"),
    "sportsWithThem": m92,
    "spotlightOnThem": m93,
    "spotlightOnYourself": MessageLookupByLibrary.simpleMessage(
      "Tập trung vào bản thân bạn",
    ),
    "startAccountRecoveryTitle": MessageLookupByLibrary.simpleMessage(
      "Bắt đầu khôi phục",
    ),
    "startBackup": MessageLookupByLibrary.simpleMessage("Bắt đầu sao lưu"),
    "status": MessageLookupByLibrary.simpleMessage("Trạng thái"),
    "sticker": MessageLookupByLibrary.simpleMessage("Sticker"),
    "stopCastingBody": MessageLookupByLibrary.simpleMessage(
      "Bạn có muốn dừng phát không?",
    ),
    "stopCastingTitle": MessageLookupByLibrary.simpleMessage("Dừng phát"),
    "storage": MessageLookupByLibrary.simpleMessage("Dung lượng"),
    "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Gia đình"),
    "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Bạn"),
    "storageInGB": m94,
    "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
      "Đã vượt hạn mức lưu trữ",
    ),
    "storageUsageInfo": m95,
    "streamDetails": MessageLookupByLibrary.simpleMessage("Chi tiết phát"),
    "strongStrength": MessageLookupByLibrary.simpleMessage("Mạnh"),
    "subAlreadyLinkedErrMessage": m96,
    "subWillBeCancelledOn": m97,
    "subscribe": MessageLookupByLibrary.simpleMessage("Đăng ký gói"),
    "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
      "Bạn phải dùng gói trả phí mới có thể chia sẻ.",
    ),
    "subscription": MessageLookupByLibrary.simpleMessage("Gói đăng ký"),
    "success": MessageLookupByLibrary.simpleMessage("Thành công"),
    "successfullyArchived": MessageLookupByLibrary.simpleMessage(
      "Lưu trữ thành công",
    ),
    "successfullyHid": MessageLookupByLibrary.simpleMessage("Đã ẩn thành công"),
    "successfullyUnarchived": MessageLookupByLibrary.simpleMessage(
      "Bỏ lưu trữ thành công",
    ),
    "successfullyUnhid": MessageLookupByLibrary.simpleMessage(
      "Đã hiện thành công",
    ),
    "suggestFeatures": MessageLookupByLibrary.simpleMessage(
      "Đề xuất tính năng",
    ),
    "sunrise": MessageLookupByLibrary.simpleMessage("Đường chân trời"),
    "support": MessageLookupByLibrary.simpleMessage("Hỗ trợ"),
    "syncProgress": m98,
    "syncStopped": MessageLookupByLibrary.simpleMessage("Đồng bộ hóa đã dừng"),
    "syncing": MessageLookupByLibrary.simpleMessage("Đang đồng bộ..."),
    "systemTheme": MessageLookupByLibrary.simpleMessage("Giống hệ thống"),
    "tapToCopy": MessageLookupByLibrary.simpleMessage("nhấn để sao chép"),
    "tapToEnterCode": MessageLookupByLibrary.simpleMessage("Nhấn để nhập mã"),
    "tapToUnlock": MessageLookupByLibrary.simpleMessage("Nhấn để mở khóa"),
    "tapToUpload": MessageLookupByLibrary.simpleMessage("Nhấn để tải lên"),
    "tapToUploadIsIgnoredDue": m99,
    "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
      "Có vẻ đã xảy ra sự cố. Vui lòng thử lại sau ít phút. Nếu lỗi vẫn tiếp diễn, hãy liên hệ với đội ngũ hỗ trợ của chúng tôi.",
    ),
    "terminate": MessageLookupByLibrary.simpleMessage("Kết thúc"),
    "terminateSession": MessageLookupByLibrary.simpleMessage(
      "Kết thúc phiên? ",
    ),
    "terms": MessageLookupByLibrary.simpleMessage("Điều khoản"),
    "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Điều khoản"),
    "thankYou": MessageLookupByLibrary.simpleMessage("Cảm ơn bạn"),
    "thankYouForSubscribing": MessageLookupByLibrary.simpleMessage(
      "Cảm ơn bạn đã đăng ký gói!",
    ),
    "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
      "Không thể hoàn tất tải xuống",
    ),
    "theLinkYouAreTryingToAccessHasExpired":
        MessageLookupByLibrary.simpleMessage(
          "Liên kết mà bạn truy cập đã hết hạn.",
        ),
    "thePersonGroupsWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
      "Nhóm người sẽ không được hiển thị trong phần người nữa. Ảnh sẽ vẫn được giữ nguyên.",
    ),
    "thePersonWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
      "Người sẽ không được hiển thị trong phần người nữa. Ảnh sẽ vẫn được giữ nguyên.",
    ),
    "theRecoveryKeyYouEnteredIsIncorrect": MessageLookupByLibrary.simpleMessage(
      "Mã khôi phục bạn nhập không chính xác",
    ),
    "theme": MessageLookupByLibrary.simpleMessage("Chủ đề"),
    "theseItemsWillBeDeletedFromYourDevice":
        MessageLookupByLibrary.simpleMessage(
          "Các mục này sẽ bị xóa khỏi thiết bị của bạn.",
        ),
    "theyAlsoGetXGb": m100,
    "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
      "Nó sẽ bị xóa khỏi tất cả album.",
    ),
    "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
      "Không thể hoàn tác thao tác này",
    ),
    "thisAlbumAlreadyHDACollaborativeLink":
        MessageLookupByLibrary.simpleMessage(
          "Album này đã có một liên kết cộng tác",
        ),
    "thisCanBeUsedToRecoverYourAccountIfYou": MessageLookupByLibrary.simpleMessage(
      "Chúng có thể giúp khôi phục tài khoản của bạn nếu bạn mất xác thực 2 bước",
    ),
    "thisDevice": MessageLookupByLibrary.simpleMessage("Thiết bị này"),
    "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
      "Email này đã được sử dụng",
    ),
    "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
      "Ảnh này không có thông số Exif",
    ),
    "thisIsMeExclamation": MessageLookupByLibrary.simpleMessage("Đây là tôi!"),
    "thisIsPersonVerificationId": m101,
    "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
      "Đây là ID xác minh của bạn",
    ),
    "thisMonth": MessageLookupByLibrary.simpleMessage("Tháng này"),
    "thisWeek": MessageLookupByLibrary.simpleMessage("Tuần này"),
    "thisWeekThroughTheYears": MessageLookupByLibrary.simpleMessage(
      "Tuần này qua các năm",
    ),
    "thisWeekXYearsAgo": m102,
    "thisWillLogYouOutOfTheFollowingDevice":
        MessageLookupByLibrary.simpleMessage(
          "Bạn cũng sẽ đăng xuất khỏi những thiết bị sau:",
        ),
    "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
      "Bạn sẽ đăng xuất khỏi thiết bị này!",
    ),
    "thisWillMakeTheDateAndTimeOfAllSelected": MessageLookupByLibrary.simpleMessage(
      "Thao tác này sẽ làm cho ngày và giờ của tất cả ảnh được chọn đều giống nhau.",
    ),
    "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
        MessageLookupByLibrary.simpleMessage(
          "Liên kết công khai của tất cả các liên kết nhanh đã chọn sẽ bị xóa.",
        ),
    "thisYear": MessageLookupByLibrary.simpleMessage("Năm nay"),
    "throughTheYears": m103,
    "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
        MessageLookupByLibrary.simpleMessage(
          "Để bật khóa ứng dụng, vui lòng thiết lập mã khóa thiết bị hoặc khóa màn hình trong cài đặt hệ thống của bạn.",
        ),
    "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
      "Để ẩn một ảnh hoặc video",
    ),
    "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
      "Để đặt lại mật khẩu, vui lòng xác minh email của bạn trước.",
    ),
    "todaysLogs": MessageLookupByLibrary.simpleMessage("Nhật ký hôm nay"),
    "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
      "Thử sai nhiều lần",
    ),
    "total": MessageLookupByLibrary.simpleMessage("tổng"),
    "totalSize": MessageLookupByLibrary.simpleMessage("Tổng dung lượng"),
    "trash": MessageLookupByLibrary.simpleMessage("Thùng rác"),
    "trashDaysLeft": m104,
    "trim": MessageLookupByLibrary.simpleMessage("Cắt"),
    "tripInYear": m105,
    "tripToLocation": m106,
    "trustedContacts": MessageLookupByLibrary.simpleMessage("Liên hệ tin cậy"),
    "trustedInviteBody": m107,
    "tryAgain": MessageLookupByLibrary.simpleMessage("Thử lại"),
    "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
      "Bật sao lưu để tự động tải lên các tệp được thêm vào thư mục thiết bị này lên Ente.",
    ),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
      "Nhận 2 tháng miễn phí với các gói theo năm",
    ),
    "twofactor": MessageLookupByLibrary.simpleMessage("Xác thực 2 bước"),
    "twofactorAuthenticationHasBeenDisabled":
        MessageLookupByLibrary.simpleMessage(
          "Xác thực 2 bước đã bị vô hiệu hóa",
        ),
    "twofactorAuthenticationPageTitle": MessageLookupByLibrary.simpleMessage(
      "Xác thực 2 bước",
    ),
    "twofactorAuthenticationSuccessfullyReset":
        MessageLookupByLibrary.simpleMessage(
          "Xác thực 2 bước đã được đặt lại thành công",
        ),
    "twofactorSetup": MessageLookupByLibrary.simpleMessage(
      "Cài đặt xác minh 2 bước",
    ),
    "typeOfGallerGallerytypeIsNotSupportedForRename": m108,
    "unarchive": MessageLookupByLibrary.simpleMessage("Bỏ lưu trữ"),
    "unarchiveAlbum": MessageLookupByLibrary.simpleMessage("Bỏ lưu trữ album"),
    "unarchiving": MessageLookupByLibrary.simpleMessage("Đang bỏ lưu trữ..."),
    "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
      "Rất tiếc, mã này không khả dụng.",
    ),
    "uncategorized": MessageLookupByLibrary.simpleMessage("Chưa phân loại"),
    "undo": MessageLookupByLibrary.simpleMessage("Hoàn tác"),
    "unhide": MessageLookupByLibrary.simpleMessage("Hiện lại"),
    "unhideToAlbum": MessageLookupByLibrary.simpleMessage(
      "Hiện lại trong album",
    ),
    "unhiding": MessageLookupByLibrary.simpleMessage("Đang hiện..."),
    "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
      "Đang hiện lại tệp trong album",
    ),
    "unlock": MessageLookupByLibrary.simpleMessage("Mở khóa"),
    "unpinAlbum": MessageLookupByLibrary.simpleMessage("Bỏ ghim album"),
    "unselectAll": MessageLookupByLibrary.simpleMessage("Bỏ chọn tất cả"),
    "update": MessageLookupByLibrary.simpleMessage("Cập nhật"),
    "updateAvailable": MessageLookupByLibrary.simpleMessage("Cập nhật có sẵn"),
    "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
      "Đang cập nhật lựa chọn thư mục...",
    ),
    "upgrade": MessageLookupByLibrary.simpleMessage("Nâng cấp"),
    "uploadIsIgnoredDueToIgnorereason": m109,
    "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
      "Đang tải tệp lên album...",
    ),
    "uploadingMultipleMemories": m110,
    "uploadingSingleMemory": MessageLookupByLibrary.simpleMessage(
      "Đang lưu giữ 1 kỷ niệm...",
    ),
    "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
      "Giảm tới 50%, đến ngày 4 Tháng 12.",
    ),
    "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
      "Dung lượng có thể dùng bị giới hạn bởi gói hiện tại của bạn. Dung lượng nhận thêm vượt hạn mức sẽ tự động có thể dùng khi bạn nâng cấp gói.",
    ),
    "useAsCover": MessageLookupByLibrary.simpleMessage("Đặt làm ảnh bìa"),
    "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
      "Phát video gặp vấn đề? Nhấn giữ tại đây để thử một trình phát khác.",
    ),
    "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
      "Dùng liên kết công khai cho những người không dùng Ente",
    ),
    "useRecoveryKey": MessageLookupByLibrary.simpleMessage("Dùng mã khôi phục"),
    "useSelectedPhoto": MessageLookupByLibrary.simpleMessage(
      "Sử dụng ảnh đã chọn",
    ),
    "usedSpace": MessageLookupByLibrary.simpleMessage("Dung lượng đã dùng"),
    "validTill": m111,
    "verificationFailedPleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Xác minh không thành công, vui lòng thử lại",
    ),
    "verificationId": MessageLookupByLibrary.simpleMessage("ID xác minh"),
    "verify": MessageLookupByLibrary.simpleMessage("Xác minh"),
    "verifyEmail": MessageLookupByLibrary.simpleMessage("Xác minh email"),
    "verifyEmailID": m112,
    "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Xác minh"),
    "verifyPasskey": MessageLookupByLibrary.simpleMessage(
      "Xác minh khóa truy cập",
    ),
    "verifyPassword": MessageLookupByLibrary.simpleMessage("Xác minh mật khẩu"),
    "verifying": MessageLookupByLibrary.simpleMessage("Đang xác minh..."),
    "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Đang xác minh mã khôi phục...",
    ),
    "videoInfo": MessageLookupByLibrary.simpleMessage("Thông tin video"),
    "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
    "videoStreaming": MessageLookupByLibrary.simpleMessage(
      "Phát trực tuyến video",
    ),
    "videos": MessageLookupByLibrary.simpleMessage("Video"),
    "viewActiveSessions": MessageLookupByLibrary.simpleMessage(
      "Xem phiên hoạt động",
    ),
    "viewAddOnButton": MessageLookupByLibrary.simpleMessage(
      "Xem tiện ích mở rộng",
    ),
    "viewAll": MessageLookupByLibrary.simpleMessage("Xem tất cả"),
    "viewAllExifData": MessageLookupByLibrary.simpleMessage(
      "Xem thông số Exif",
    ),
    "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Tệp lớn"),
    "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
      "Xem các tệp đang chiếm nhiều dung lượng nhất.",
    ),
    "viewLogs": MessageLookupByLibrary.simpleMessage("Xem nhật ký"),
    "viewPersonToUnlink": m113,
    "viewRecoveryKey": MessageLookupByLibrary.simpleMessage("Xem mã khôi phục"),
    "viewer": MessageLookupByLibrary.simpleMessage("Người xem"),
    "viewersSuccessfullyAdded": m114,
    "visitWebToManage": MessageLookupByLibrary.simpleMessage(
      "Vui lòng truy cập web.ente.io để quản lý gói đăng ký",
    ),
    "waitingForVerification": MessageLookupByLibrary.simpleMessage(
      "Đang chờ xác minh...",
    ),
    "waitingForWifi": MessageLookupByLibrary.simpleMessage("Đang chờ WiFi..."),
    "warning": MessageLookupByLibrary.simpleMessage("Cảnh báo"),
    "weAreOpenSource": MessageLookupByLibrary.simpleMessage(
      "Chúng tôi là mã nguồn mở!",
    ),
    "weDontSupportEditingPhotosAndAlbumsThatYouDont":
        MessageLookupByLibrary.simpleMessage(
          "Chúng tôi chưa hỗ trợ chỉnh sửa ảnh và album không phải bạn sở hữu",
        ),
    "weHaveSendEmailTo": m115,
    "weakStrength": MessageLookupByLibrary.simpleMessage("Yếu"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("Chào mừng trở lại!"),
    "whatsNew": MessageLookupByLibrary.simpleMessage("Có gì mới"),
    "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
      "Liên hệ tin cậy có thể giúp khôi phục dữ liệu của bạn.",
    ),
    "widgets": MessageLookupByLibrary.simpleMessage("Tiện ích"),
    "wishThemAHappyBirthday": m116,
    "yearShort": MessageLookupByLibrary.simpleMessage("năm"),
    "yearly": MessageLookupByLibrary.simpleMessage("Theo năm"),
    "yearsAgo": m117,
    "yes": MessageLookupByLibrary.simpleMessage("Có"),
    "yesCancel": MessageLookupByLibrary.simpleMessage("Có, hủy"),
    "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
      "Có, chuyển thành người xem",
    ),
    "yesDelete": MessageLookupByLibrary.simpleMessage("Có, xóa"),
    "yesDiscardChanges": MessageLookupByLibrary.simpleMessage(
      "Có, bỏ qua thay đổi",
    ),
    "yesIgnore": MessageLookupByLibrary.simpleMessage("Có, bỏ qua"),
    "yesLogout": MessageLookupByLibrary.simpleMessage("Có, đăng xuất"),
    "yesRemove": MessageLookupByLibrary.simpleMessage("Có, xóa"),
    "yesRenew": MessageLookupByLibrary.simpleMessage("Có, Gia hạn"),
    "yesResetPerson": MessageLookupByLibrary.simpleMessage("Có, đặt lại người"),
    "you": MessageLookupByLibrary.simpleMessage("Bạn"),
    "youAndThem": m118,
    "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
      "Bạn đang dùng gói gia đình!",
    ),
    "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
      "Bạn đang sử dụng phiên bản mới nhất",
    ),
    "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
      "* Bạn có thể tối đa ×2 dung lượng của mình",
    ),
    "youCanManageYourLinksInTheShareTab": MessageLookupByLibrary.simpleMessage(
      "Bạn có thể quản lý các liên kết của mình trong tab chia sẻ.",
    ),
    "youCanTrySearchingForADifferentQuery":
        MessageLookupByLibrary.simpleMessage(
          "Bạn có thể thử tìm kiếm một truy vấn khác.",
        ),
    "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
      "Bạn không thể đổi xuống gói này",
    ),
    "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
      "Bạn không thể chia sẻ với chính mình",
    ),
    "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
      "Bạn không có mục nào đã lưu trữ.",
    ),
    "youHaveSuccessfullyFreedUp": m119,
    "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
      "Tài khoản của bạn đã bị xóa",
    ),
    "yourMap": MessageLookupByLibrary.simpleMessage("Bản đồ của bạn"),
    "yourPlanWasSuccessfullyDowngraded": MessageLookupByLibrary.simpleMessage(
      "Gói của bạn đã được hạ cấp thành công",
    ),
    "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
      "Gói của bạn đã được nâng cấp thành công",
    ),
    "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
      "Bạn đã giao dịch thành công",
    ),
    "yourStorageDetailsCouldNotBeFetched": MessageLookupByLibrary.simpleMessage(
      "Không thể lấy chi tiết dung lượng của bạn",
    ),
    "yourSubscriptionHasExpired": MessageLookupByLibrary.simpleMessage(
      "Gói của bạn đã hết hạn",
    ),
    "yourSubscriptionWasUpdatedSuccessfully":
        MessageLookupByLibrary.simpleMessage(
          "Gói của bạn đã được cập nhật thành công",
        ),
    "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
      "Mã xác minh của bạn đã hết hạn",
    ),
    "youveNoDuplicateFilesThatCanBeCleared":
        MessageLookupByLibrary.simpleMessage(
          "Bạn không có tệp nào bị trùng để xóa",
        ),
    "youveNoFilesInThisAlbumThatCanBeDeleted":
        MessageLookupByLibrary.simpleMessage(
          "Bạn không có tệp nào có thể xóa trong album này",
        ),
    "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
      "Phóng to để xem ảnh",
    ),
  };
}
