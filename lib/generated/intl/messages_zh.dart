// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
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
  String get localeName => 'zh';

  static String m1(user) => "${user} 将无法添加更多照片到此相册\n\n他们仍然能够删除他们添加的现有照片";

  static String m14(passwordStrengthValue) => "密码强度： ${passwordStrengthValue}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack": MessageLookupByLibrary.simpleMessage("欢迎回来！"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "我明白，如果我丢失密码，我可能会丢失我的数据，因为我的数据是 <underline>端到端加密的</underline>。"),
        "activeSessions": MessageLookupByLibrary.simpleMessage("已登录的设备"),
        "addedAs": MessageLookupByLibrary.simpleMessage("已添加为"),
        "allowAddPhotosDescription":
            MessageLookupByLibrary.simpleMessage("允许具有链接的人也将照片添加到共享相册。"),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage("允许添加照片"),
        "allowDownloads": MessageLookupByLibrary.simpleMessage("允许下载"),
        "askDeleteReason":
            MessageLookupByLibrary.simpleMessage("您删除账户的主要原因是什么？"),
        "cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "cannotAddMorePhotosAfterBecomingViewer": m1,
        "changeEmail": MessageLookupByLibrary.simpleMessage("修改邮箱"),
        "changePasswordTitle": MessageLookupByLibrary.simpleMessage("修改密码"),
        "changePermissions": MessageLookupByLibrary.simpleMessage("要修改权限吗？"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "请检查您的收件箱 (或者是在您的“垃圾邮件”列表内) 以完成验证"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("确认删除账户"),
        "confirmDeletePrompt":
            MessageLookupByLibrary.simpleMessage("是的，我想永久删除此账户及其相关数据."),
        "confirmPassword": MessageLookupByLibrary.simpleMessage("请确认密码"),
        "contactSupport": MessageLookupByLibrary.simpleMessage("联系支持"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("继续"),
        "createAccount": MessageLookupByLibrary.simpleMessage("创建账户"),
        "createNewAccount": MessageLookupByLibrary.simpleMessage("创建新账号"),
        "decrypting": MessageLookupByLibrary.simpleMessage("解密中..."),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("删除账户"),
        "deleteAccountFeedbackPrompt":
            MessageLookupByLibrary.simpleMessage("我们很抱歉看到您离开。请分享您的反馈以帮助我们改进。"),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("永久删除账户"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "您将要永久删除您的账户及其所有数据。\n此操作是不可逆的。"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "请从您注册的电子邮件地址发送电子邮件到 <warning>account-delettion@ente.io</warning>。"),
        "deleteReason1": MessageLookupByLibrary.simpleMessage("找不到我想要的功能"),
        "deleteReason2":
            MessageLookupByLibrary.simpleMessage("应用或某个功能不会有 \n行为。我认为它应该有的"),
        "deleteReason3":
            MessageLookupByLibrary.simpleMessage("我找到了另一个我喜欢更好的服务"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage("我的原因未被列出"),
        "deleteRequestSLAText":
            MessageLookupByLibrary.simpleMessage("您的请求将在 72 小时内处理。"),
        "disableDownloadWarningBody":
            MessageLookupByLibrary.simpleMessage("查看者仍然可以使用外部工具截图或保存您的照片副本"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("请注意"),
        "email": MessageLookupByLibrary.simpleMessage("电子邮件地址"),
        "encryption": MessageLookupByLibrary.simpleMessage("加密"),
        "encryptionKeys": MessageLookupByLibrary.simpleMessage("加密密钥"),
        "enterNewPasswordToEncrypt":
            MessageLookupByLibrary.simpleMessage("输入我们可以用来加密您的数据的新密码"),
        "enterPasswordToEncrypt":
            MessageLookupByLibrary.simpleMessage("输入我们可以用来加密您的数据的密码"),
        "enterValidEmail":
            MessageLookupByLibrary.simpleMessage("请输入一个有效的电子邮件地址。"),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("请输入您的电子邮件地址"),
        "enterYourPassword": MessageLookupByLibrary.simpleMessage("输入您的密码"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("输入您的恢复密钥"),
        "expiredLinkInfo":
            MessageLookupByLibrary.simpleMessage("此链接已过期。请选择新的过期时间或禁用链接过期。"),
        "feedback": MessageLookupByLibrary.simpleMessage("反馈"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage("忘记密码"),
        "generatingEncryptionKeys":
            MessageLookupByLibrary.simpleMessage("正在生成加密密钥..."),
        "howItWorks": MessageLookupByLibrary.simpleMessage("工作原理"),
        "incorrectPasswordTitle": MessageLookupByLibrary.simpleMessage("密码错误"),
        "incorrectRecoveryKeyBody":
            MessageLookupByLibrary.simpleMessage("您输入的恢复密钥不正确"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("不正确的恢复密钥"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage("设备不安全"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("无效的电子邮件地址"),
        "kindlyHelpUsWithThisInformation":
            MessageLookupByLibrary.simpleMessage("请帮助我们了解这个信息"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("设备限制"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("已启用"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("已过期"),
        "linkExpiry": MessageLookupByLibrary.simpleMessage("链接过期"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("永不"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("登录"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "点击登录后，我同意 <u-terms>服务条款</u-terms> 和 <u-policy>隐私政策</u-policy>"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("中等"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage("没有恢复密钥吗？"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "由于我们端到端加密协议的性质，如果没有您的密码或恢复密钥，您的数据将无法解密"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "oops": MessageLookupByLibrary.simpleMessage("哎呀"),
        "password": MessageLookupByLibrary.simpleMessage("密码"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("密码修改成功"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("密码锁"),
        "passwordStrength": m14,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "我们不储存这个密码，所以如果忘记， <underline>我们不能解密您的数据</underline>"),
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage("请重试"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("请稍候..."),
        "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage("隐私政策"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("恢复"),
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage("恢复成功!"),
        "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage("重新创建密码"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("重新发送电子邮件"),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage("重置密码"),
        "selectReason": MessageLookupByLibrary.simpleMessage("选择原因"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("发送电子邮件"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("设置密码"),
        "setPasswordTitle": MessageLookupByLibrary.simpleMessage("设置密码"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "我同意 <u-terms>服务条款</u-terms> 和 <u-policy>隐私政策</u-policy>"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("出了点问题，请重试"),
        "sorry": MessageLookupByLibrary.simpleMessage("抱歉"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "抱歉，我们无法在此设备上生成安全密钥。\n\n请使用其他设备注册。"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("强"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage("点击以输入代码"),
        "terminate": MessageLookupByLibrary.simpleMessage("终止"),
        "terminateSession": MessageLookupByLibrary.simpleMessage("是否终止会话？"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("使用条款"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("此设备"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage("这将使您在以下设备中退出登录："),
        "thisWillLogYouOutOfThisDevice":
            MessageLookupByLibrary.simpleMessage("这将使您在此设备上退出登录！"),
        "verify": MessageLookupByLibrary.simpleMessage("验证"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("验证电子邮件"),
        "weakStrength": MessageLookupByLibrary.simpleMessage("弱"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("欢迎回来！"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage("是的，转换为查看者"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("您的账户已删除")
      };
}
