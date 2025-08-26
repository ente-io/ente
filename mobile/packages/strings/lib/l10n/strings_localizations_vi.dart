// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class StringsLocalizationsVi extends StringsLocalizations {
  StringsLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Không thể kết nối đến Ente, vui lòng kiểm tra lại kết nối mạng. Nếu vẫn còn lỗi, xin vui lòng liên hệ hỗ trợ.';

  @override
  String get networkConnectionRefusedErr =>
      'Không thể kết nối đến Ente, vui lòng thử lại sau. Nếu vẫn còn lỗi, xin vui lòng liên hệ hỗ trợ.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Có vẻ như đã xảy ra sự cố. Vui lòng thử lại sau một thời gian. Nếu lỗi vẫn tiếp diễn, vui lòng liên hệ với nhóm hỗ trợ của chúng tôi.';

  @override
  String get error => 'Lỗi';

  @override
  String get ok => 'Đồng ý';

  @override
  String get faq => 'Câu hỏi thường gặp';

  @override
  String get contactSupport => 'Liên hệ hỗ trợ';

  @override
  String get emailYourLogs => 'Gửi email nhật ký của bạn';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Vui lòng gửi nhật ký đến \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Sao chép địa chỉ email';

  @override
  String get exportLogs => 'Xuất nhật ký';

  @override
  String get cancel => 'Hủy';

  @override
  String pleaseEmailUsAt(String toEmail) {
    return 'Email us at $toEmail';
  }

  @override
  String get emailAddressCopied => 'Email address copied';

  @override
  String get supportEmailSubject => '[Support]';

  @override
  String get clientDebugInfoLabel =>
      'Following information can help us in debugging if you are facing any issue';

  @override
  String get registeredEmailLabel => 'Registered email:';

  @override
  String get clientLabel => 'Client:';

  @override
  String get versionLabel => 'Version :';

  @override
  String get notAvailable => 'N/A';

  @override
  String get reportABug => 'Báo cáo lỗi';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Đã kết nối đến';
  }

  @override
  String get save => 'Lưu';

  @override
  String get send => 'Gửi';

  @override
  String get saveOrSendDescription =>
      'Bạn có muốn lưu vào bộ nhớ (Mặc định lưu vào thư mục Tải về) hoặc chuyển qua ứng dụng khác?';

  @override
  String get saveOnlyDescription =>
      'Bạn có muốn lưu vào bộ nhớ không (Mặc định lưu vào thư mục Tải về)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'Thư điện tử';

  @override
  String get verify => 'Xác minh';

  @override
  String get invalidEmailTitle => 'Địa chỉ email không hợp lệ';

  @override
  String get invalidEmailMessage =>
      'Xin vui lòng nhập một địa chỉ email hợp lệ.';

  @override
  String get pleaseWait => 'Vui lòng chờ...';

  @override
  String get verifyPassword => 'Xác nhận mật khẩu';

  @override
  String get incorrectPasswordTitle => 'Mật khẩu không đúng';

  @override
  String get pleaseTryAgain => 'Vui lòng thử lại';

  @override
  String get enterPassword => 'Nhập mật khẩu';

  @override
  String get enterYourPasswordHint => 'Nhập mật khẩu của bạn';

  @override
  String get activeSessions => 'Các phiên làm việc hiện tại';

  @override
  String get oops => 'Rất tiếc';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Phát hiện có lỗi, xin thử lại';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Thao tác này sẽ đăng xuất bạn khỏi thiết bị này!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Thao tác này sẽ đăng xuất bạn khỏi thiết bị sau:';

  @override
  String get terminateSession => 'Kết thúc phiên?';

  @override
  String get terminate => 'Kết thúc';

  @override
  String get thisDevice => 'Thiết bị này';

  @override
  String get createAccount => 'Tạo tài khoản';

  @override
  String get weakStrength => 'Yếu';

  @override
  String get moderateStrength => 'Trung bình';

  @override
  String get strongStrength => 'Mạnh';

  @override
  String get deleteAccount => 'Xoá tài khoản';

  @override
  String get deleteAccountQuery =>
      'Chúng tôi sẽ rất tiếc khi thấy bạn đi. Bạn đang phải đối mặt với một số vấn đề?';

  @override
  String get yesSendFeedbackAction => 'Có, gửi phản hồi';

  @override
  String get noDeleteAccountAction => 'Không, xóa tài khoản';

  @override
  String get initiateAccountDeleteTitle =>
      'Vui lòng xác thực để bắt đầu xóa tài khoản';

  @override
  String get confirmAccountDeleteTitle => 'Xác nhận xóa tài khoản';

  @override
  String get confirmAccountDeleteMessage =>
      'Tài khoản này được liên kết với các ứng dụng Ente trên các nền tảng khác, nếu bạn có sử dụng.\n\nDữ liệu đã tải lên của bạn, trên mọi nền tảng, sẽ bị lên lịch xóa và tài khoản của bạn sẽ bị xóa vĩnh viễn.';

  @override
  String get delete => 'Xóa';

  @override
  String get createNewAccount => 'Tạo tài khoản mới';

  @override
  String get password => 'Mật khẩu';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Độ mạnh mật khẩu: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle =>
      'Bạn biết đến Ente bằng cách nào? (không bắt buộc)';

  @override
  String get hearUsExplanation =>
      'Chúng tôi không theo dõi lượt cài đặt ứng dụng. Sẽ rất hữu ích nếu bạn cho chúng tôi biết nơi bạn tìm thấy chúng tôi!';

  @override
  String get signUpTerms =>
      'Tôi đồng ý với <u-terms>điều khoản dịch vụ</u-terms> và <u-policy>chính sách quyền riêng tư</u-policy>';

  @override
  String get termsOfServicesTitle => 'Điều khoản';

  @override
  String get privacyPolicyTitle => 'Chính sách bảo mật';

  @override
  String get ackPasswordLostWarning =>
      'Tôi hiểu rằng việc mất mật khẩu có thể đồng nghĩa với việc mất dữ liệu của tôi vì dữ liệu của tôi được <underline>mã hóa hai đầu</underline>.';

  @override
  String get encryption => 'Mã hóa';

  @override
  String get logInLabel => 'Đăng nhập';

  @override
  String get welcomeBack => 'Chào mừng trở lại!';

  @override
  String get loginTerms =>
      'Bằng cách nhấp vào đăng nhập, tôi đồng ý với <u-terms>điều khoản dịch vụ</u-terms> và <u-policy>chính sách quyền riêng tư</u-policy>';

  @override
  String get noInternetConnection => 'Không có kết nối Internet';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Vui lòng kiểm tra kết nối internet của bạn và thử lại.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Mã xác nhận thất bại. Vui lòng thử lại';

  @override
  String get recreatePasswordTitle => 'Tạo lại mật khẩu';

  @override
  String get recreatePasswordBody =>
      'Thiết bị hiện tại không đủ mạnh để xác minh mật khẩu của bạn nhưng chúng tôi có thể tạo lại mật khẩu theo cách hoạt động với tất cả các thiết bị.\n\nVui lòng đăng nhập bằng khóa khôi phục và tạo lại mật khẩu của bạn (bạn có thể sử dụng lại cùng một mật khẩu nếu muốn).';

  @override
  String get useRecoveryKey => 'Dùng khóa khôi phục';

  @override
  String get forgotPassword => 'Quên mật khẩu';

  @override
  String get changeEmail => 'Thay đổi email';

  @override
  String get verifyEmail => 'Xác nhận địa chỉ Email';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Chúng tôi đã gửi thư đến <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Để đặt lại mật khẩu, vui lòng xác minh email của bạn trước.';

  @override
  String get checkInboxAndSpamFolder =>
      'Vui lòng kiểm tra hộp thư đến (và thư rác) của bạn để hoàn tất xác minh';

  @override
  String get tapToEnterCode => 'Chạm để nhập mã';

  @override
  String get sendEmail => 'Gửi email';

  @override
  String get resendEmail => 'Gửi lại email';

  @override
  String get passKeyPendingVerification => 'Đang chờ xác thực';

  @override
  String get loginSessionExpired => 'Phiên làm việc hết hạn';

  @override
  String get loginSessionExpiredDetails =>
      'Phiên làm việc hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get passkeyAuthTitle => 'Xác minh mã khóa';

  @override
  String get waitingForVerification => 'Đang chờ xác thực';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get checkStatus => 'Kiểm tra trạng thái';

  @override
  String get loginWithTOTP => 'Đăng nhập bằng TOTP';

  @override
  String get recoverAccount => 'Khôi phục tài khoản';

  @override
  String get setPasswordTitle => 'Đặt mật khẩu';

  @override
  String get changePasswordTitle => 'Thay đổi mật khẩu';

  @override
  String get resetPasswordTitle => 'Đặt lại mật khẩu';

  @override
  String get encryptionKeys => 'Khóa mã hóa';

  @override
  String get enterPasswordToEncrypt =>
      'Nhập mật khẩu mà chúng tôi có thể sử dụng để mã hóa dữ liệu của bạn';

  @override
  String get enterNewPasswordToEncrypt =>
      'Nhập một mật khẩu mới mà chúng tôi có thể sử dụng để mã hóa dữ liệu của bạn';

  @override
  String get passwordWarning =>
      'Chúng tôi không lưu trữ mật khẩu này, vì vậy nếu bạn quên, <underline>chúng tôi không thể giải mã dữ liệu của bạn</underline>';

  @override
  String get howItWorks => 'Cách thức hoạt động';

  @override
  String get generatingEncryptionKeys => 'Đang tạo khóa mã hóa...';

  @override
  String get passwordChangedSuccessfully => 'Thay đổi mật khẩu thành công';

  @override
  String get signOutFromOtherDevices => 'Đăng xuất khỏi các thiết bị khác';

  @override
  String get signOutOtherBody =>
      'Nếu bạn cho rằng ai đó có thể biết mật khẩu của mình, bạn có thể buộc đăng xuất tất cả các thiết bị khác đang sử dụng tài khoản của mình.';

  @override
  String get signOutOtherDevices => 'Đăng xuất khỏi các thiết bị khác';

  @override
  String get doNotSignOut => 'Không được đăng xuất';

  @override
  String get generatingEncryptionKeysTitle => 'Đang tạo khóa mã hóa...';

  @override
  String get continueLabel => 'Tiếp tục';

  @override
  String get insecureDevice => 'Thiết bị không an toàn';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Rất tiếc, chúng tôi không thể tạo khóa bảo mật trên thiết bị này.\n\nvui lòng đăng ký từ một thiết bị khác.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Đã sao chép khóa khôi phục vào bộ nhớ tạm';

  @override
  String get recoveryKey => 'Khóa khôi phục';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Nếu bạn quên mật khẩu, cách duy nhất bạn có thể khôi phục dữ liệu của mình là sử dụng khóa này.';

  @override
  String get recoveryKeySaveDescription =>
      'Chúng tôi không lưu trữ khóa này, vui lòng lưu khóa 24 từ này ở nơi an toàn.';

  @override
  String get doThisLater => 'Để sau';

  @override
  String get saveKey => 'Lưu khóa';

  @override
  String get recoveryKeySaved => 'Đã lưu khoá dự phòng vào thư mục Tải về!';

  @override
  String get noRecoveryKeyTitle => 'Không có khóa khôi phục?';

  @override
  String get twoFactorAuthTitle => 'Xác thực hai yếu tố';

  @override
  String get enterCodeHint =>
      'Nhập mã gồm 6 chữ số từ ứng dụng xác thực của bạn';

  @override
  String get lostDeviceTitle => 'Mất thiết bị?';

  @override
  String get enterRecoveryKeyHint => 'Nhập khóa khôi phục của bạn';

  @override
  String get recover => 'Khôi phục';

  @override
  String get loggingOut => 'Đang đăng xuất...';

  @override
  String get immediately => 'Tức thì';

  @override
  String get appLock => 'Khóa ứng dụng';

  @override
  String get autoLock => 'Tự động khóa';

  @override
  String get noSystemLockFound => 'Không thấy khoá hệ thống';

  @override
  String get deviceLockEnablePreSteps =>
      'Để bật khoá thiết bị, vui lòng thiết lập mật khẩu thiết bị hoặc khóa màn hình trong cài đặt hệ thống của bạn.';

  @override
  String get appLockDescription =>
      'Chọn giữa màn hình khoá mặc định của thiết bị và màn hình khoá tự chọn dùng mã PIN hoặc mật khẩu.';

  @override
  String get deviceLock => 'Khóa thiết bị';

  @override
  String get pinLock => 'Mã PIN';

  @override
  String get autoLockFeatureDescription =>
      'Thời gian ứng dụng tự khoá sau khi ở trạng thái nền';

  @override
  String get hideContent => 'Ẩn nội dung';

  @override
  String get hideContentDescriptionAndroid =>
      'Ẩn nội dung khi chuyển ứng dụng và chặn chụp màn hình';

  @override
  String get hideContentDescriptioniOS => 'Ẩn nội dung khi chuyển ứng dụng';

  @override
  String get tooManyIncorrectAttempts => 'Quá nhiều lần thử không chính xác';

  @override
  String get tapToUnlock => 'Nhấn để mở khóa';

  @override
  String get areYouSureYouWantToLogout => 'Bạn có chắc chắn muốn đăng xuất?';

  @override
  String get yesLogout => 'Có, đăng xuất';

  @override
  String get authToViewSecrets => 'Vui lòng xác thực để xem bí mật của bạn';

  @override
  String get next => 'Tiếp theo';

  @override
  String get setNewPassword => 'Đặt lại mật khẩu';

  @override
  String get enterPin => 'Nhập mã PIN';

  @override
  String get setNewPin => 'Đổi mã PIN';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get reEnterPassword => 'Nhập lại mật khẩu';

  @override
  String get reEnterPin => 'Nhập lại mã PIN';

  @override
  String get androidBiometricHint => 'Xác định danh tính';

  @override
  String get androidBiometricNotRecognized =>
      'Không nhận dạng được. Vui lòng thử lại.';

  @override
  String get androidBiometricSuccess => 'Thành công';

  @override
  String get androidCancelButton => 'Hủy bỏ';

  @override
  String get androidSignInTitle => 'Yêu cầu xác thực';

  @override
  String get androidBiometricRequiredTitle => 'Yêu cầu sinh trắc học';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Yêu cầu thông tin xác thực thiết bị';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Yêu cầu thông tin xác thực thiết bị';

  @override
  String get goToSettings => 'Chuyển đến cài đặt';

  @override
  String get androidGoToSettingsDescription =>
      'Xác thực sinh trắc học chưa được thiết lập trên thiết bị của bạn. Đi tới \'Cài đặt > Bảo mật\' để thêm xác thực sinh trắc học.';

  @override
  String get iOSLockOut =>
      'Xác thực sinh trắc học bị vô hiệu hóa. Vui lòng khóa và mở khóa màn hình của bạn để kích hoạt nó.';

  @override
  String get iOSOkButton => 'Đồng ý';

  @override
  String get emailAlreadyRegistered => 'Email đã được đăng kí.';

  @override
  String get emailNotRegistered => 'Email chưa được đăng kí.';

  @override
  String get thisEmailIsAlreadyInUse => 'Email này đã được sử dụng';

  @override
  String emailChangedTo(String newEmail) {
    return 'Thay đổi email thành $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Xác thực lỗi, vui lòng thử lại';

  @override
  String get authenticationSuccessful => 'Xác thực thành công!';

  @override
  String get sessionExpired => 'Phiên làm việc đã hết hạn';

  @override
  String get incorrectRecoveryKey => 'Khóa khôi phục không chính xác';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Khóa khôi phục bạn đã nhập không chính xác';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Xác thực hai bước được khôi phục thành công';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired => 'Mã xác minh của bạn đã hết hạn';

  @override
  String get incorrectCode => 'Mã không chính xác';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Xin lỗi, mã bạn đã nhập không chính xác';

  @override
  String get developerSettings => 'Cài đặt cho nhà phát triển';

  @override
  String get serverEndpoint => 'Điểm cuối máy chủ';

  @override
  String get invalidEndpoint => 'Điểm cuối không hợp lệ';

  @override
  String get invalidEndpointMessage =>
      'Xin lỗi, điểm cuối bạn nhập không hợp lệ. Vui lòng nhập một điểm cuối hợp lệ và thử lại.';

  @override
  String get endpointUpdatedMessage => 'Cập nhật điểm cuối thành công';
}
