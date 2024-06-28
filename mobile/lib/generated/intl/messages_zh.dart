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

  static String m0(count) =>
      "${Intl.plural(count, zero: '添加协作者', one: '添加协作者', other: '添加协作者')}";

  static String m2(count) =>
      "${Intl.plural(count, one: '添加一个项目', other: '添加一些项目')}";

  static String m3(storageAmount, endDate) =>
      "您的 ${storageAmount} 插件有效期至 ${endDate}";

  static String m1(count) =>
      "${Intl.plural(count, zero: '添加查看者', one: '添加查看者', other: '添加查看者')}";

  static String m4(emailOrName) => "由 ${emailOrName} 添加";

  static String m5(albumName) => "成功添加到  ${albumName}";

  static String m6(count) =>
      "${Intl.plural(count, zero: '无参与者', one: '1个参与者', other: '${count} 个参与者')}";

  static String m7(versionValue) => "版本: ${versionValue}";

  static String m8(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} 空闲";

  static String m9(paymentProvider) => "请先取消您现有的订阅 ${paymentProvider}";

  static String m10(user) => "${user} 将无法添加更多照片到此相册\n\n他们仍然能够删除他们添加的现有照片";

  static String m11(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': '到目前为止，您的家庭已经领取了 ${storageAmountInGb} GB',
            'false': '到目前为止，您已经领取了 ${storageAmountInGb} GB',
            'other': '到目前为止，您已经领取了${storageAmountInGb} GB',
          })}";

  static String m12(albumName) => "为 ${albumName} 创建了协作链接";

  static String m13(familyAdminEmail) =>
      "请联系 <green>${familyAdminEmail}</green> 来管理您的订阅";

  static String m14(provider) =>
      "请通过support@ente.io 用英语联系我们来管理您的 ${provider} 订阅。";

  static String m15(endpoint) => "已连接至 ${endpoint}";

  static String m16(count) =>
      "${Intl.plural(count, one: '删除 ${count} 个项目', other: '删除 ${count} 个项目')}";

  static String m17(currentlyDeleting, totalCount) =>
      "正在删除 ${currentlyDeleting} /共 ${totalCount}";

  static String m18(albumName) => "这将删除用于访问\"${albumName}\"的公开链接。";

  static String m19(supportEmail) => "请从您注册的邮箱发送一封邮件到 ${supportEmail}";

  static String m20(count, storageSaved) =>
      "您已经清理了 ${Intl.plural(count, other: '${count} 个重复文件')}, 释放了 (${storageSaved}!)";

  static String m21(count, formattedSize) =>
      "${count} 个文件，每个文件 ${formattedSize}";

  static String m22(newEmail) => "电子邮件已更改为 ${newEmail}";

  static String m23(email) => "${email} 没有 Ente 帐户。\n\n向他们发出共享照片的邀请。";

  static String m24(count, formattedNumber) =>
      "此设备上的 ${Intl.plural(count, one: '1 个文件', other: '${formattedNumber} 个文件')} 已安全备份";

  static String m25(count, formattedNumber) =>
      "此相册中的 ${Intl.plural(count, one: '1 个文件', other: '${formattedNumber} 个文件')} 已安全备份";

  static String m26(storageAmountInGB) =>
      "每当有人使用您的代码注册付费计划时您将获得${storageAmountInGB} GB";

  static String m27(endDate) => "免费试用有效期至 ${endDate}";

  static String m28(count) =>
      "只要您有有效的订阅，您仍然可以在 Ente 上访问 ${Intl.plural(count, one: '它', other: '它们')}";

  static String m29(sizeInMBorGB) => "释放 ${sizeInMBorGB}";

  static String m30(count, formattedSize) =>
      "${Intl.plural(count, one: '它可以从设备中删除以释放 ${formattedSize}', other: '它们可以从设备中删除以释放 ${formattedSize}')}";

  static String m31(currentlyProcessing, totalCount) =>
      "正在处理 ${currentlyProcessing} / ${totalCount}";

  static String m32(count) =>
      "${Intl.plural(count, one: '${count} 个项目', other: '${count} 个项目')}";

  static String m33(expiryTime) => "链接将在 ${expiryTime} 过期";

  static String m34(count, formattedCount) =>
      "${Intl.plural(count, zero: '没有回忆', one: '${formattedCount} 个回忆', other: '${formattedCount} 个回忆')}";

  static String m35(count) =>
      "${Intl.plural(count, one: '移动一个项目', other: '移动一些项目')}";

  static String m36(albumName) => "成功移动到 ${albumName}";

  static String m37(passwordStrengthValue) => "密码强度： ${passwordStrengthValue}";

  static String m38(providerName) => "如果您被收取费用，请用英语与 ${providerName} 的客服聊天";

  static String m39(endDate) => "免费试用有效期至 ${endDate}。\n在此之后您可以选择付费计划。";

  static String m40(toEmail) => "请给我们发送电子邮件至 ${toEmail}";

  static String m41(toEmail) => "请将日志发送至 \n${toEmail}";

  static String m42(storeName) => "在 ${storeName} 上给我们评分";

  static String m43(storageInGB) => "3. 你和朋友都将免费获得 ${storageInGB} GB*";

  static String m44(userEmail) =>
      "${userEmail} 将从这个共享相册中删除\n\nTA们添加的任何照片也将从相册中删除";

  static String m45(endDate) => "在 ${endDate} 前续费";

  static String m46(count) =>
      "${Intl.plural(count, other: '已找到 ${count} 个结果')}";

  static String m47(count) => "已选择 ${count} 个";

  static String m48(count, yourCount) => "选择了 ${count} 个 (您的 ${yourCount} 个)";

  static String m49(verificationID) => "这是我的ente.io 的验证 ID： ${verificationID}。";

  static String m50(verificationID) =>
      "嘿，你能确认这是你的 ente.io 验证 ID吗：${verificationID}";

  static String m51(referralCode, referralStorageInGB) =>
      "Ente 推荐代码：${referralCode}\n\n在 \"设置\"→\"通用\"→\"推荐 \"中应用它，即可在注册付费计划后免费获得 ${referralStorageInGB} GB 存储空间\n\nhttps://ente.io";

  static String m52(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: '与特定人员共享', one: '与 1 人共享', other: '与 ${numberOfPeople} 人共享')}";

  static String m53(emailIDs) => "与 ${emailIDs} 共享";

  static String m54(fileType) => "此 ${fileType} 将从您的设备中删除。";

  static String m55(fileType) => "${fileType} 已同时存在于 Ente 和您的设备中。";

  static String m56(fileType) => "${fileType} 将从 Ente 中删除。";

  static String m57(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m58(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "已使用 ${usedAmount} ${usedStorageUnit} / ${totalAmount} ${totalStorageUnit}";

  static String m59(id) =>
      "您的 ${id} 已链接到另一个 Ente 账户。\n如果您想在此账户中使用您的 ${id} ，请联系我们的支持人员";

  static String m60(endDate) => "您的订阅将于 ${endDate} 取消";

  static String m61(completed, total) => "已保存的回忆 ${completed}/共 ${total}";

  static String m62(storageAmountInGB) => "他们也会获得 ${storageAmountInGB} GB";

  static String m63(email) => "这是 ${email} 的验证ID";

  static String m64(count) =>
      "${Intl.plural(count, zero: '', one: '1天', other: '${count} 天')}";

  static String m65(endDate) => "有效期至 ${endDate}";

  static String m66(email) => "验证 ${email}";

  static String m67(email) => "我们已经发送邮件到 <green>${email}</green>";

  static String m68(count) =>
      "${Intl.plural(count, one: '${count} 年前', other: '${count} 年前')}";

  static String m69(storageSaved) => "您已成功释放了 ${storageSaved}！";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable":
            MessageLookupByLibrary.simpleMessage("有新版本的 Ente 可供使用。"),
        "about": MessageLookupByLibrary.simpleMessage("关于"),
        "account": MessageLookupByLibrary.simpleMessage("账户"),
        "accountWelcomeBack": MessageLookupByLibrary.simpleMessage("欢迎回来！"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "我明白，如果我丢失密码，我可能会丢失我的数据，因为我的数据是 <underline>端到端加密的</underline>。"),
        "activeSessions": MessageLookupByLibrary.simpleMessage("已登录的设备"),
        "addAName": MessageLookupByLibrary.simpleMessage("添加一个名称"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage("添加新的电子邮件"),
        "addCollaborator": MessageLookupByLibrary.simpleMessage("添加协作者"),
        "addCollaborators": m0,
        "addFromDevice": MessageLookupByLibrary.simpleMessage("从设备添加"),
        "addItem": m2,
        "addLocation": MessageLookupByLibrary.simpleMessage("添加地点"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("添加"),
        "addMore": MessageLookupByLibrary.simpleMessage("添加更多"),
        "addNew": MessageLookupByLibrary.simpleMessage("新建"),
        "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage("附加组件详情"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("附加组件"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("添加照片"),
        "addSelected": MessageLookupByLibrary.simpleMessage("添加所选项"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("添加到相册"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("添加到 Ente"),
        "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage("添加到隐藏相册"),
        "addViewer": MessageLookupByLibrary.simpleMessage("添加查看者"),
        "addViewers": m1,
        "addYourPhotosNow": MessageLookupByLibrary.simpleMessage("立即添加您的照片"),
        "addedAs": MessageLookupByLibrary.simpleMessage("已添加为"),
        "addedBy": m4,
        "addedSuccessfullyTo": m5,
        "addingToFavorites": MessageLookupByLibrary.simpleMessage("正在添加到收藏..."),
        "advanced": MessageLookupByLibrary.simpleMessage("高级设置"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("高级设置"),
        "after1Day": MessageLookupByLibrary.simpleMessage("1天后"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("1小时后"),
        "after1Month": MessageLookupByLibrary.simpleMessage("1个月后"),
        "after1Week": MessageLookupByLibrary.simpleMessage("1 周后"),
        "after1Year": MessageLookupByLibrary.simpleMessage("1 年后"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("所有者"),
        "albumParticipantsCount": m6,
        "albumTitle": MessageLookupByLibrary.simpleMessage("相册标题"),
        "albumUpdated": MessageLookupByLibrary.simpleMessage("相册已更新"),
        "albums": MessageLookupByLibrary.simpleMessage("相册"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ 全部清除"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("所有回忆都已保存"),
        "allowAddPhotosDescription":
            MessageLookupByLibrary.simpleMessage("允许具有链接的人也将照片添加到共享相册。"),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage("允许添加照片"),
        "allowDownloads": MessageLookupByLibrary.simpleMessage("允许下载"),
        "allowPeopleToAddPhotos":
            MessageLookupByLibrary.simpleMessage("允许人们添加照片"),
        "androidBiometricHint": MessageLookupByLibrary.simpleMessage("验证身份"),
        "androidBiometricNotRecognized":
            MessageLookupByLibrary.simpleMessage("无法识别。请重试。"),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("需要生物识别认证"),
        "androidBiometricSuccess": MessageLookupByLibrary.simpleMessage("成功"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("取消"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage("需要设备凭据"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage("需要设备凭据"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "您未在该设备上设置生物识别身份验证。前往“设置>安全”添加生物识别身份验证。"),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("安卓, iOS, 网页端, 桌面端"),
        "androidSignInTitle": MessageLookupByLibrary.simpleMessage("需要身份验证"),
        "appVersion": m7,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("应用"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("应用代码"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("AppStore 订阅"),
        "archive": MessageLookupByLibrary.simpleMessage("存档"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("存档相册"),
        "archiving": MessageLookupByLibrary.simpleMessage("正在归档中..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage("您确定要离开家庭计划吗？"),
        "areYouSureYouWantToCancel":
            MessageLookupByLibrary.simpleMessage("您确定要取消吗？"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage("您确定要更改您的计划吗？"),
        "areYouSureYouWantToExit":
            MessageLookupByLibrary.simpleMessage("您确定要退出吗？"),
        "areYouSureYouWantToLogout":
            MessageLookupByLibrary.simpleMessage("您确定要退出登录吗？"),
        "areYouSureYouWantToRenew":
            MessageLookupByLibrary.simpleMessage("您确定要续费吗？"),
        "askCancelReason":
            MessageLookupByLibrary.simpleMessage("您的订阅已取消。您想分享原因吗？"),
        "askDeleteReason":
            MessageLookupByLibrary.simpleMessage("您删除账户的主要原因是什么？"),
        "askYourLovedOnesToShare":
            MessageLookupByLibrary.simpleMessage("请您的亲人分享"),
        "atAFalloutShelter": MessageLookupByLibrary.simpleMessage("在一个庇护所中"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage("请进行身份验证以更改电子邮件验证"),
        "authToChangeLockscreenSetting":
            MessageLookupByLibrary.simpleMessage("请验证以更改锁屏设置"),
        "authToChangeYourEmail":
            MessageLookupByLibrary.simpleMessage("请验证以更改您的电子邮件"),
        "authToChangeYourPassword":
            MessageLookupByLibrary.simpleMessage("请验证以更改密码"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage("请进行身份验证以配置双重身份认证"),
        "authToInitiateAccountDeletion":
            MessageLookupByLibrary.simpleMessage("请进行身份验证以启动账户删除"),
        "authToViewYourActiveSessions":
            MessageLookupByLibrary.simpleMessage("请验证以查看您的活动会话"),
        "authToViewYourHiddenFiles":
            MessageLookupByLibrary.simpleMessage("请验证以查看您的隐藏文件"),
        "authToViewYourMemories":
            MessageLookupByLibrary.simpleMessage("请验证以查看您的回忆"),
        "authToViewYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("请验证以查看您的恢复密钥"),
        "authenticating": MessageLookupByLibrary.simpleMessage("正在验证..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("身份验证失败，请重试"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("验证成功"),
        "autoCastDialogBody":
            MessageLookupByLibrary.simpleMessage("您将在此处看到可用的 Cast 设备。"),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "请确保已在“设置”中为 Ente Photos 应用打开本地网络权限。"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "由于技术故障，您已退出登录。对于由此造成的不便，我们深表歉意。"),
        "autoPair": MessageLookupByLibrary.simpleMessage("自动配对"),
        "autoPairDesc":
            MessageLookupByLibrary.simpleMessage("自动配对仅适用于支持 Chromecast 的设备。"),
        "available": MessageLookupByLibrary.simpleMessage("可用"),
        "availableStorageSpace": m8,
        "backedUpFolders": MessageLookupByLibrary.simpleMessage("已备份的文件夹"),
        "backup": MessageLookupByLibrary.simpleMessage("备份"),
        "backupFailed": MessageLookupByLibrary.simpleMessage("备份失败"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("通过移动数据备份"),
        "backupSettings": MessageLookupByLibrary.simpleMessage("备份设置"),
        "backupVideos": MessageLookupByLibrary.simpleMessage("备份视频"),
        "blackFridaySale": MessageLookupByLibrary.simpleMessage("黑色星期五特惠"),
        "blog": MessageLookupByLibrary.simpleMessage("博客"),
        "cachedData": MessageLookupByLibrary.simpleMessage("缓存数据"),
        "calculating": MessageLookupByLibrary.simpleMessage("正在计算..."),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage("无法上传到他人拥有的相册中"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage("只能为您拥有的文件创建链接"),
        "canOnlyRemoveFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage("只能删除您拥有的文件"),
        "cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "cancelOtherSubscription": m9,
        "cancelSubscription": MessageLookupByLibrary.simpleMessage("取消订阅"),
        "cannotAddMorePhotosAfterBecomingViewer": m10,
        "cannotDeleteSharedFiles":
            MessageLookupByLibrary.simpleMessage("无法删除共享文件"),
        "castIPMismatchBody":
            MessageLookupByLibrary.simpleMessage("请确保您的设备与电视处于同一网络。"),
        "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage("投放相册失败"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "在您要配对的设备上访问 cast.ente.io。\n输入下面的代码即可在电视上播放相册。"),
        "centerPoint": MessageLookupByLibrary.simpleMessage("中心点"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("修改邮箱"),
        "changeLocationOfSelectedItems":
            MessageLookupByLibrary.simpleMessage("确定要更改所选项目的位置吗？"),
        "changePassword": MessageLookupByLibrary.simpleMessage("修改密码"),
        "changePasswordTitle": MessageLookupByLibrary.simpleMessage("修改密码"),
        "changePermissions": MessageLookupByLibrary.simpleMessage("要修改权限吗？"),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage("检查更新"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "请检查您的收件箱 (或者是在您的“垃圾邮件”列表内) 以完成验证"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("检查状态"),
        "checking": MessageLookupByLibrary.simpleMessage("正在检查..."),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage("领取免费存储"),
        "claimMore": MessageLookupByLibrary.simpleMessage("领取更多！"),
        "claimed": MessageLookupByLibrary.simpleMessage("已领取"),
        "claimedStorageSoFar": m11,
        "cleanUncategorized": MessageLookupByLibrary.simpleMessage("清除未分类的"),
        "cleanUncategorizedDescription":
            MessageLookupByLibrary.simpleMessage("从“未分类”中删除其他相册中存在的所有文件"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("清除缓存"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("清空索引"),
        "click": MessageLookupByLibrary.simpleMessage("• 点击"),
        "clickOnTheOverflowMenu":
            MessageLookupByLibrary.simpleMessage("• 点击溢出菜单"),
        "close": MessageLookupByLibrary.simpleMessage("关闭"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage("按拍摄时间分组"),
        "clubByFileName": MessageLookupByLibrary.simpleMessage("按文件名排序"),
        "clusteringProgress": MessageLookupByLibrary.simpleMessage("聚类进展"),
        "codeAppliedPageTitle": MessageLookupByLibrary.simpleMessage("代码已应用"),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("代码已复制到剪贴板"),
        "codeUsedByYou": MessageLookupByLibrary.simpleMessage("您所使用的代码"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "创建一个链接来让他人无需 Ente 应用程序或账户即可在您的共享相册中添加和查看照片。非常适合收集活动照片。"),
        "collaborativeLink": MessageLookupByLibrary.simpleMessage("协作链接"),
        "collaborativeLinkCreatedFor": m12,
        "collaborator": MessageLookupByLibrary.simpleMessage("协作者"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage("协作者可以将照片和视频添加到共享相册中。"),
        "collageLayout": MessageLookupByLibrary.simpleMessage("布局"),
        "collageSaved": MessageLookupByLibrary.simpleMessage("拼贴已保存到相册"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage("收集活动照片"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("收集照片"),
        "color": MessageLookupByLibrary.simpleMessage("颜色"),
        "confirm": MessageLookupByLibrary.simpleMessage("确认"),
        "confirm2FADisable":
            MessageLookupByLibrary.simpleMessage("您确定要禁用双重认证吗？"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("确认删除账户"),
        "confirmDeletePrompt":
            MessageLookupByLibrary.simpleMessage("是的，我想永久删除此账户及其相关数据."),
        "confirmPassword": MessageLookupByLibrary.simpleMessage("请确认密码"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage("确认更改计划"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage("确认恢复密钥"),
        "confirmYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("确认您的恢复密钥"),
        "connectToDevice": MessageLookupByLibrary.simpleMessage("连接到设备"),
        "contactFamilyAdmin": m13,
        "contactSupport": MessageLookupByLibrary.simpleMessage("联系支持"),
        "contactToManageSubscription": m14,
        "contacts": MessageLookupByLibrary.simpleMessage("联系人"),
        "contents": MessageLookupByLibrary.simpleMessage("内容"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("继续"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage("继续免费试用"),
        "convertToAlbum": MessageLookupByLibrary.simpleMessage("转换为相册"),
        "copyEmailAddress": MessageLookupByLibrary.simpleMessage("复制电子邮件地址"),
        "copyLink": MessageLookupByLibrary.simpleMessage("复制链接"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage("请复制粘贴此代码\n到您的身份验证器应用程序上"),
        "couldNotBackUpTryLater":
            MessageLookupByLibrary.simpleMessage("我们无法备份您的数据。\n我们将稍后再试。"),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage("无法释放空间"),
        "couldNotUpdateSubscription":
            MessageLookupByLibrary.simpleMessage("无法升级订阅"),
        "count": MessageLookupByLibrary.simpleMessage("计数"),
        "crashReporting": MessageLookupByLibrary.simpleMessage("上报崩溃"),
        "create": MessageLookupByLibrary.simpleMessage("创建"),
        "createAccount": MessageLookupByLibrary.simpleMessage("创建账户"),
        "createAlbumActionHint":
            MessageLookupByLibrary.simpleMessage("长按选择照片，然后点击 + 创建相册"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("创建协作链接"),
        "createCollage": MessageLookupByLibrary.simpleMessage("创建拼贴"),
        "createNewAccount": MessageLookupByLibrary.simpleMessage("创建新账号"),
        "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage("创建或选择相册"),
        "createPublicLink": MessageLookupByLibrary.simpleMessage("创建公开链接"),
        "creatingLink": MessageLookupByLibrary.simpleMessage("正在创建链接..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("可用的关键更新"),
        "crop": MessageLookupByLibrary.simpleMessage("裁剪"),
        "currentUsageIs": MessageLookupByLibrary.simpleMessage("当前用量 "),
        "custom": MessageLookupByLibrary.simpleMessage("自定义"),
        "customEndpoint": m15,
        "darkTheme": MessageLookupByLibrary.simpleMessage("深色"),
        "dayToday": MessageLookupByLibrary.simpleMessage("今天"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("昨天"),
        "decrypting": MessageLookupByLibrary.simpleMessage("解密中..."),
        "decryptingVideo": MessageLookupByLibrary.simpleMessage("正在解密视频..."),
        "deduplicateFiles": MessageLookupByLibrary.simpleMessage("文件去重"),
        "delete": MessageLookupByLibrary.simpleMessage("删除"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("删除账户"),
        "deleteAccountFeedbackPrompt":
            MessageLookupByLibrary.simpleMessage("我们很抱歉看到您离开。请分享您的反馈以帮助我们改进。"),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("永久删除账户"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("删除相册"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "也删除此相册中存在的照片(和视频)，从 <bold>他们所加入的所有</bold> 其他相册？"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "这将删除所有空相册。 当您想减少相册列表的混乱时，这很有用。"),
        "deleteAll": MessageLookupByLibrary.simpleMessage("全部删除"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "此账户已链接到其他 Ente 应用程序（如果您使用任何应用程序）。您在所有 Ente 应用程序中上传的数据将被安排删除，并且您的账户将被永久删除。"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "请从您注册的电子邮件地址发送电子邮件到 <warning>account-delettion@ente.io</warning>。"),
        "deleteEmptyAlbums": MessageLookupByLibrary.simpleMessage("删除空相册"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("要删除空相册吗？"),
        "deleteFromBoth": MessageLookupByLibrary.simpleMessage("同时从两者中删除"),
        "deleteFromDevice": MessageLookupByLibrary.simpleMessage("从设备中删除"),
        "deleteFromEnte": MessageLookupByLibrary.simpleMessage("从 Ente 中删除"),
        "deleteItemCount": m16,
        "deleteLocation": MessageLookupByLibrary.simpleMessage("删除位置"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("删除照片"),
        "deleteProgress": m17,
        "deleteReason1": MessageLookupByLibrary.simpleMessage("找不到我想要的功能"),
        "deleteReason2":
            MessageLookupByLibrary.simpleMessage("应用或某个功能没有按我的预期运行"),
        "deleteReason3":
            MessageLookupByLibrary.simpleMessage("我找到了另一个我喜欢更好的服务"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage("我的原因未被列出"),
        "deleteRequestSLAText":
            MessageLookupByLibrary.simpleMessage("您的请求将在 72 小时内处理。"),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage("要删除共享相册吗？"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "将为所有人删除相册\n\n您将无法访问此相册中他人拥有的共享照片"),
        "descriptions": MessageLookupByLibrary.simpleMessage("描述"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("取消全选"),
        "designedToOutlive": MessageLookupByLibrary.simpleMessage("经久耐用"),
        "details": MessageLookupByLibrary.simpleMessage("详情"),
        "developerSettings": MessageLookupByLibrary.simpleMessage("开发者设置"),
        "developerSettingsWarning":
            MessageLookupByLibrary.simpleMessage("您确定要修改开发者设置吗？"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("输入代码"),
        "deviceFilesAutoUploading":
            MessageLookupByLibrary.simpleMessage("添加到此设备相册的文件将自动上传到 Ente。"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "当 Ente 置于前台且正在进行备份时将禁用设备屏幕锁定。这通常是不需要的，但可能有助于更快地完成大型上传和大型库的初始导入。"),
        "deviceNotFound": MessageLookupByLibrary.simpleMessage("未发现设备"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("您知道吗？"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage("禁用自动锁定"),
        "disableDownloadWarningBody":
            MessageLookupByLibrary.simpleMessage("查看者仍然可以使用外部工具截图或保存您的照片副本"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("请注意"),
        "disableLinkMessage": m18,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage("禁用双重认证"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage("正在禁用双重认证..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "dismiss": MessageLookupByLibrary.simpleMessage("忽略"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("公里"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("不要登出"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("稍后再说"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage("您想要放弃您所做的编辑吗？"),
        "done": MessageLookupByLibrary.simpleMessage("已完成"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("将您的存储空间增加一倍"),
        "download": MessageLookupByLibrary.simpleMessage("下载"),
        "downloadFailed": MessageLookupByLibrary.simpleMessage("下載失敗"),
        "downloading": MessageLookupByLibrary.simpleMessage("正在下载..."),
        "dropSupportEmail": m19,
        "duplicateFileCountWithStorageSaved": m20,
        "duplicateItemsGroup": m21,
        "edit": MessageLookupByLibrary.simpleMessage("编辑"),
        "editLocation": MessageLookupByLibrary.simpleMessage("编辑位置"),
        "editLocationTagTitle": MessageLookupByLibrary.simpleMessage("编辑位置"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("已保存编辑"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage("对位置的编辑只能在 Ente 内看到"),
        "eligible": MessageLookupByLibrary.simpleMessage("符合资格"),
        "email": MessageLookupByLibrary.simpleMessage("电子邮件地址"),
        "emailChangedTo": m22,
        "emailNoEnteAccount": m23,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("电子邮件验证"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage("通过电子邮件发送您的日志"),
        "empty": MessageLookupByLibrary.simpleMessage("清空"),
        "emptyTrash": MessageLookupByLibrary.simpleMessage("要清空回收站吗？"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("启用地图"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "这将在世界地图上显示您的照片。\n\n该地图由 Open Street Map 托管，并且您的照片的确切位置永远不会共享。\n\n您可以随时从“设置”中禁用此功能。"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage("正在加密备份..."),
        "encryption": MessageLookupByLibrary.simpleMessage("加密"),
        "encryptionKeys": MessageLookupByLibrary.simpleMessage("加密密钥"),
        "endpointUpdatedMessage":
            MessageLookupByLibrary.simpleMessage("端点更新成功"),
        "endtoendEncryptedByDefault":
            MessageLookupByLibrary.simpleMessage("默认端到端加密"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage("仅当您授予文件访问权限时，Ente 才能加密和保存文件"),
        "entePhotosPerm":
            MessageLookupByLibrary.simpleMessage("Ente <i>需要许可</i>才能保存您的照片"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente 会保留您的回忆，因此即使您丢失了设备，也能随时找到它们。"),
        "enteSubscriptionShareWithFamily":
            MessageLookupByLibrary.simpleMessage("您的家人也可以添加到您的计划中。"),
        "enterAlbumName": MessageLookupByLibrary.simpleMessage("输入相册名称"),
        "enterCode": MessageLookupByLibrary.simpleMessage("输入代码"),
        "enterCodeDescription":
            MessageLookupByLibrary.simpleMessage("输入您的朋友提供的代码来为您申请免费存储"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("输入电子邮件"),
        "enterFileName": MessageLookupByLibrary.simpleMessage("请输入文件名"),
        "enterNewPasswordToEncrypt":
            MessageLookupByLibrary.simpleMessage("输入我们可以用来加密您的数据的新密码"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("输入密码"),
        "enterPasswordToEncrypt":
            MessageLookupByLibrary.simpleMessage("输入我们可以用来加密您的数据的密码"),
        "enterPersonName": MessageLookupByLibrary.simpleMessage("输入人物名称"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage("输入推荐代码"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage("从你的身份验证器应用中\n输入6位数字代码"),
        "enterValidEmail":
            MessageLookupByLibrary.simpleMessage("请输入一个有效的电子邮件地址。"),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("请输入您的电子邮件地址"),
        "enterYourPassword": MessageLookupByLibrary.simpleMessage("输入您的密码"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("输入您的恢复密钥"),
        "error": MessageLookupByLibrary.simpleMessage("错误"),
        "everywhere": MessageLookupByLibrary.simpleMessage("随时随地"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser": MessageLookupByLibrary.simpleMessage("现有用户"),
        "expiredLinkInfo":
            MessageLookupByLibrary.simpleMessage("此链接已过期。请选择新的过期时间或禁用链接有效期。"),
        "exportLogs": MessageLookupByLibrary.simpleMessage("导出日志"),
        "exportYourData": MessageLookupByLibrary.simpleMessage("导出您的数据"),
        "faceRecognition": MessageLookupByLibrary.simpleMessage("人脸识别"),
        "faces": MessageLookupByLibrary.simpleMessage("人脸"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage("无法使用此代码"),
        "failedToCancel": MessageLookupByLibrary.simpleMessage("取消失败"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage("视频下载失败"),
        "failedToFetchOriginalForEdit":
            MessageLookupByLibrary.simpleMessage("无法获取原始编辑"),
        "failedToFetchReferralDetails":
            MessageLookupByLibrary.simpleMessage("无法获取引荐详细信息。 请稍后再试。"),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage("加载相册失败"),
        "failedToRenew": MessageLookupByLibrary.simpleMessage("续费失败"),
        "failedToVerifyPaymentStatus":
            MessageLookupByLibrary.simpleMessage("验证支付状态失败"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "将 5 名家庭成员添加到您现有的计划中，无需支付额外费用。\n\n每个成员都有自己的私人空间，除非共享，否则无法看到彼此的文件。\n\n家庭计划适用于已付费 Ente 订阅的客户。\n\n立即订阅，开始体验！"),
        "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("家庭"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("家庭计划"),
        "faq": MessageLookupByLibrary.simpleMessage("常见问题"),
        "faqs": MessageLookupByLibrary.simpleMessage("常见问题"),
        "favorite": MessageLookupByLibrary.simpleMessage("收藏"),
        "feedback": MessageLookupByLibrary.simpleMessage("反馈"),
        "fileFailedToSaveToGallery":
            MessageLookupByLibrary.simpleMessage("无法将文件保存到相册"),
        "fileInfoAddDescHint": MessageLookupByLibrary.simpleMessage("添加说明..."),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage("文件已保存到相册"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("文件类型"),
        "fileTypesAndNames": MessageLookupByLibrary.simpleMessage("文件类型和名称"),
        "filesBackedUpFromDevice": m24,
        "filesBackedUpInAlbum": m25,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("文件已删除"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("多个文件已保存到相册"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage("按名称快速查找人物"),
        "flip": MessageLookupByLibrary.simpleMessage("上下翻转"),
        "forYourMemories": MessageLookupByLibrary.simpleMessage("为您的回忆"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage("忘记密码"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("已找到的人脸"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage("已领取的免费存储"),
        "freeStorageOnReferralSuccess": m26,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage("可用的免费存储"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("免费试用"),
        "freeTrialValidTill": m27,
        "freeUpAccessPostDelete": m28,
        "freeUpAmount": m29,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage("释放设备空间"),
        "freeUpDeviceSpaceDesc":
            MessageLookupByLibrary.simpleMessage("通过清除已备份的文件来节省设备空间。"),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("释放空间"),
        "freeUpSpaceSaving": m30,
        "galleryMemoryLimitInfo":
            MessageLookupByLibrary.simpleMessage("在图库中显示最多1000个回忆"),
        "general": MessageLookupByLibrary.simpleMessage("通用"),
        "generatingEncryptionKeys":
            MessageLookupByLibrary.simpleMessage("正在生成加密密钥..."),
        "genericProgress": m31,
        "goToSettings": MessageLookupByLibrary.simpleMessage("前往设置"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt":
            MessageLookupByLibrary.simpleMessage("请在手机“设置”中授权软件访问所有照片"),
        "grantPermission": MessageLookupByLibrary.simpleMessage("授予权限"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage("将附近的照片分组"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "我们不跟踪应用程序安装情况。如果您告诉我们您是在哪里找到我们的，将会有所帮助！"),
        "hearUsWhereTitle":
            MessageLookupByLibrary.simpleMessage("您是如何知道Ente的？ （可选的）"),
        "help": MessageLookupByLibrary.simpleMessage("帮助"),
        "hidden": MessageLookupByLibrary.simpleMessage("已隐藏"),
        "hide": MessageLookupByLibrary.simpleMessage("隐藏"),
        "hiding": MessageLookupByLibrary.simpleMessage("正在隐藏..."),
        "hostedAtOsmFrance": MessageLookupByLibrary.simpleMessage("法国 OSM 主办"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("工作原理"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "请让他们在设置屏幕上长按他们的电子邮件地址，并验证两台设备上的 ID 是否匹配。"),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "您未在该设备上设置生物识别身份验证。请在您的手机上启用 Touch ID或Face ID。"),
        "iOSLockOut":
            MessageLookupByLibrary.simpleMessage("生物识别认证已禁用。请锁定并解锁您的屏幕以启用它。"),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("好的"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("忽略"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "此相册中的某些文件在上传时会被忽略，因为它们之前已从 Ente 中删除。"),
        "importing": MessageLookupByLibrary.simpleMessage("正在导入..."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("代码错误"),
        "incorrectPasswordTitle": MessageLookupByLibrary.simpleMessage("密码错误"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("不正确的恢复密钥"),
        "incorrectRecoveryKeyBody":
            MessageLookupByLibrary.simpleMessage("您输入的恢复密钥不正确"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("不正确的恢复密钥"),
        "indexedItems": MessageLookupByLibrary.simpleMessage("已索引项目"),
        "indexingIsPaused":
            MessageLookupByLibrary.simpleMessage("索引已暂停。当设备准备就绪时，它将自动恢复。"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage("设备不安全"),
        "installManually": MessageLookupByLibrary.simpleMessage("手动安装"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("无效的电子邮件地址"),
        "invalidEndpoint": MessageLookupByLibrary.simpleMessage("端点无效"),
        "invalidEndpointMessage":
            MessageLookupByLibrary.simpleMessage("抱歉，您输入的端点无效。请输入有效的端点，然后重试。"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("无效的密钥"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "您输入的恢复密钥无效。请确保它包含24个单词，并检查每个单词的拼写。\n\n如果您输入了旧的恢复码，请确保它长度为64个字符，并检查其中每个字符。"),
        "invite": MessageLookupByLibrary.simpleMessage("邀请"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("邀请到 Ente"),
        "inviteYourFriends": MessageLookupByLibrary.simpleMessage("邀请您的朋友"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("邀请您的朋友加入 Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "看起来出了点问题。 请稍后重试。 如果错误仍然存在，请联系我们的支持团队。"),
        "itemCount": m32,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage("项目显示永久删除前剩余的天数"),
        "itemsWillBeRemovedFromAlbum":
            MessageLookupByLibrary.simpleMessage("所选项目将从此相册中移除"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("加入 Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("保留照片"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("公里"),
        "kindlyHelpUsWithThisInformation":
            MessageLookupByLibrary.simpleMessage("请帮助我们了解这个信息"),
        "language": MessageLookupByLibrary.simpleMessage("语言"),
        "lastUpdated": MessageLookupByLibrary.simpleMessage("最后更新"),
        "leave": MessageLookupByLibrary.simpleMessage("离开"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("离开相册"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("离开家庭计划"),
        "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage("要离开共享相册吗？"),
        "left": MessageLookupByLibrary.simpleMessage("向左"),
        "light": MessageLookupByLibrary.simpleMessage("亮度"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("浅色"),
        "linkCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("链接已复制到剪贴板"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("设备限制"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("已启用"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("已过期"),
        "linkExpiresOn": m33,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("链接过期"),
        "linkHasExpired": MessageLookupByLibrary.simpleMessage("链接已过期"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("永不"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("实况照片"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage("您可以与家庭分享您的订阅"),
        "loadMessage2":
            MessageLookupByLibrary.simpleMessage("到目前为止，我们已经保存了超过3 000万个回忆"),
        "loadMessage3":
            MessageLookupByLibrary.simpleMessage("我们保存你的3个数据副本，其中一个在地下安全屋中"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage("我们所有的应用程序都是开源的"),
        "loadMessage5":
            MessageLookupByLibrary.simpleMessage("我们的源代码和加密技术已经由外部审计"),
        "loadMessage6":
            MessageLookupByLibrary.simpleMessage("您可以与您所爱的人分享您相册的链接"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "我们的移动应用程序在后台运行以加密和备份您点击的任何新照片"),
        "loadMessage8":
            MessageLookupByLibrary.simpleMessage("web.ente.io 有一个巧妙的上传器"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "我们使用 Xchacha20Poly1305 加密技术来安全地加密您的数据"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("正在加载 EXIF 数据..."),
        "loadingGallery": MessageLookupByLibrary.simpleMessage("正在加载图库..."),
        "loadingMessage": MessageLookupByLibrary.simpleMessage("正在加载您的照片..."),
        "loadingModel": MessageLookupByLibrary.simpleMessage("正在下载模型..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("本地相册"),
        "location": MessageLookupByLibrary.simpleMessage("地理位置"),
        "locationName": MessageLookupByLibrary.simpleMessage("地点名称"),
        "locationTagFeatureDescription":
            MessageLookupByLibrary.simpleMessage("位置标签将在照片的某个半径范围内拍摄的所有照片进行分组"),
        "locations": MessageLookupByLibrary.simpleMessage("位置"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("锁定"),
        "lockScreenEnablePreSteps":
            MessageLookupByLibrary.simpleMessage("要启用锁屏，请在系统设置中设置设备密码或屏幕锁定。"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("锁屏"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("登录"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("正在退出登录..."),
        "loginSessionExpired": MessageLookupByLibrary.simpleMessage("会话已过期"),
        "loginSessionExpiredDetails":
            MessageLookupByLibrary.simpleMessage("您的会话已过期。请重新登录。"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "点击登录时，默认我同意 <u-terms>服务条款</u-terms> 和 <u-policy>隐私政策</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("退出登录"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "这将跨日志发送以帮助我们调试您的问题。 请注意，将包含文件名以帮助跟踪特定文件的问题。"),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage("长按电子邮件以验证端到端加密。"),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage("长按一个项目来全屏查看"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("设备丢失？"),
        "machineLearning": MessageLookupByLibrary.simpleMessage("机器学习"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("魔法搜索"),
        "manage": MessageLookupByLibrary.simpleMessage("管理"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage("管理设备存储"),
        "manageFamily": MessageLookupByLibrary.simpleMessage("管理家庭计划"),
        "manageLink": MessageLookupByLibrary.simpleMessage("管理链接"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("管理"),
        "manageSubscription": MessageLookupByLibrary.simpleMessage("管理订阅"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "用 PIN 码配对适用于您希望在其上查看相册的任何屏幕。"),
        "map": MessageLookupByLibrary.simpleMessage("地图"),
        "maps": MessageLookupByLibrary.simpleMessage("地图"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m34,
        "merchandise": MessageLookupByLibrary.simpleMessage("商品"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "请注意，机器学习将使用更高的带宽和更多的电量，直到所有项目都被索引为止。"),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("移动端, 网页端, 桌面端"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("中等"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage("修改您的查询，或尝试搜索"),
        "moments": MessageLookupByLibrary.simpleMessage("瞬间"),
        "monthly": MessageLookupByLibrary.simpleMessage("每月"),
        "moveItem": m35,
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("移动到相册"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage("移至隐藏相册"),
        "movedSuccessfullyTo": m36,
        "movedToTrash": MessageLookupByLibrary.simpleMessage("已移至回收站"),
        "movingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("正在将文件移动到相册..."),
        "name": MessageLookupByLibrary.simpleMessage("名称"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "无法连接到 Ente，请稍后重试。如果错误仍然存在，请联系支持人员。"),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "无法连接到 Ente，请检查您的网络设置，如果错误仍然存在，请联系支持人员。"),
        "never": MessageLookupByLibrary.simpleMessage("永不"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("新建相册"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("初来 Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("最新"),
        "no": MessageLookupByLibrary.simpleMessage("否"),
        "noAlbumsSharedByYouYet":
            MessageLookupByLibrary.simpleMessage("您尚未共享任何相册"),
        "noDeviceFound": MessageLookupByLibrary.simpleMessage("未发现设备"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("无"),
        "noDeviceThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage("您在此设备上没有可被删除的文件"),
        "noDuplicates": MessageLookupByLibrary.simpleMessage("✨ 没有重复内容"),
        "noExifData": MessageLookupByLibrary.simpleMessage("无 EXIF 数据"),
        "noHiddenPhotosOrVideos":
            MessageLookupByLibrary.simpleMessage("没有隐藏的照片或视频"),
        "noImagesWithLocation":
            MessageLookupByLibrary.simpleMessage("没有带有位置的图像"),
        "noInternetConnection": MessageLookupByLibrary.simpleMessage("无互联网连接"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage("目前没有照片正在备份"),
        "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage("这里没有找到照片"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage("没有恢复密钥吗？"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "由于我们端到端加密协议的性质，如果没有您的密码或恢复密钥，您的数据将无法解密"),
        "noResults": MessageLookupByLibrary.simpleMessage("无结果"),
        "noResultsFound": MessageLookupByLibrary.simpleMessage("未找到任何结果"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("尚未与您共享任何内容"),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage("这里空空如也! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("通知"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "onDevice": MessageLookupByLibrary.simpleMessage("在设备上"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "在 <branding>ente</branding> 上"),
        "oops": MessageLookupByLibrary.simpleMessage("哎呀"),
        "oopsCouldNotSaveEdits":
            MessageLookupByLibrary.simpleMessage("糟糕，无法保存编辑"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("哎呀，似乎出了点问题"),
        "openSettings": MessageLookupByLibrary.simpleMessage("打开“设置”"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• 打开该项目"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("OpenStreetMap 贡献者"),
        "optionalAsShortAsYouLike":
            MessageLookupByLibrary.simpleMessage("可选的，按您喜欢的短语..."),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("或者选择一个现有的"),
        "pair": MessageLookupByLibrary.simpleMessage("配对"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("用 PIN 配对"),
        "pairingComplete": MessageLookupByLibrary.simpleMessage("配对完成"),
        "passKeyPendingVerification":
            MessageLookupByLibrary.simpleMessage("仍需进行验证"),
        "passkey": MessageLookupByLibrary.simpleMessage("通行密钥"),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage("通行密钥认证"),
        "password": MessageLookupByLibrary.simpleMessage("密码"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("密码修改成功"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("密码锁"),
        "passwordStrength": m37,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "我们不储存这个密码，所以如果忘记， <underline>我们将无法解密您的数据</underline>"),
        "paymentDetails": MessageLookupByLibrary.simpleMessage("付款明细"),
        "paymentFailed": MessageLookupByLibrary.simpleMessage("支付失败"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "不幸的是，您的付款失败。请联系支持人员，我们将为您提供帮助！"),
        "paymentFailedTalkToProvider": m38,
        "pendingItems": MessageLookupByLibrary.simpleMessage("待处理项目"),
        "pendingSync": MessageLookupByLibrary.simpleMessage("正在等待同步"),
        "people": MessageLookupByLibrary.simpleMessage("人物"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage("使用您的代码的人"),
        "permDeleteWarning":
            MessageLookupByLibrary.simpleMessage("回收站中的所有项目将被永久删除\n\n此操作无法撤消"),
        "permanentlyDelete": MessageLookupByLibrary.simpleMessage("永久删除"),
        "permanentlyDeleteFromDevice":
            MessageLookupByLibrary.simpleMessage("要从设备中永久删除吗？"),
        "photoDescriptions": MessageLookupByLibrary.simpleMessage("照片说明"),
        "photoGridSize": MessageLookupByLibrary.simpleMessage("照片网格大小"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("照片"),
        "photos": MessageLookupByLibrary.simpleMessage("照片"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage("您添加的照片将从相册中移除"),
        "pickCenterPoint": MessageLookupByLibrary.simpleMessage("选择中心点"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("置顶相册"),
        "playOnTv": MessageLookupByLibrary.simpleMessage("在电视上播放相册"),
        "playStoreFreeTrialValidTill": m39,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("PlayStore 订阅"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage("请检查您的互联网连接，然后重试。"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "请用英语联系 support@ente.io ，我们将乐意提供帮助！"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage("如果问题仍然存在，请联系支持"),
        "pleaseEmailUsAt": m40,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage("请授予权限"),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage("请重新登录"),
        "pleaseSendTheLogsTo": m41,
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage("请重试"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage("请验证您输入的代码"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("请稍候..."),
        "pleaseWaitDeletingAlbum":
            MessageLookupByLibrary.simpleMessage("请稍候，正在删除相册"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage("请稍等片刻后再重试"),
        "preparingLogs": MessageLookupByLibrary.simpleMessage("正在准备日志..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("保留更多"),
        "pressAndHoldToPlayVideo":
            MessageLookupByLibrary.simpleMessage("按住以播放视频"),
        "pressAndHoldToPlayVideoDetailed":
            MessageLookupByLibrary.simpleMessage("长按图像以播放视频"),
        "privacy": MessageLookupByLibrary.simpleMessage("隐私"),
        "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage("隐私政策"),
        "privateBackups": MessageLookupByLibrary.simpleMessage("私人备份"),
        "privateSharing": MessageLookupByLibrary.simpleMessage("私人分享"),
        "publicLinkCreated": MessageLookupByLibrary.simpleMessage("公共链接已创建"),
        "publicLinkEnabled": MessageLookupByLibrary.simpleMessage("公开链接已启用"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("快速链接"),
        "radius": MessageLookupByLibrary.simpleMessage("半径"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("提升工单"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("为此应用评分"),
        "rateUs": MessageLookupByLibrary.simpleMessage("给我们评分"),
        "rateUsOnStore": m42,
        "recover": MessageLookupByLibrary.simpleMessage("恢复"),
        "recoverAccount": MessageLookupByLibrary.simpleMessage("恢复账户"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("恢复"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage("恢复密钥"),
        "recoveryKeyCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("恢复密钥已复制到剪贴板"),
        "recoveryKeyOnForgotPassword":
            MessageLookupByLibrary.simpleMessage("如果您忘记了密码，恢复数据的唯一方法就是使用此密钥。"),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "我们不会存储此密钥，请将此24个单词密钥保存在一个安全的地方。"),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "太棒了！ 您的恢复密钥是有效的。 感谢您的验证。\n\n请记住要安全备份您的恢复密钥。"),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage("恢复密钥已验证"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "如果您忘记了您的密码，您的恢复密钥是恢复您的照片的唯一途径。 您可以在“设置 > 账户”中找到您的恢复密钥。\n\n请在此输入您的恢复密钥以确认您已经正确地保存了它。"),
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage("恢复成功!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "当前设备的功能不足以验证您的密码，但我们可以以适用于所有设备的方式重新生成。\n\n请使用您的恢复密钥登录并重新生成您的密码（如果您希望，可以再次使用相同的密码）。"),
        "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage("重新创建密码"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referFriendsAnd2xYourPlan":
            MessageLookupByLibrary.simpleMessage("把我们推荐给你的朋友然后获得延长一倍的订阅计划"),
        "referralStep1": MessageLookupByLibrary.simpleMessage("1. 将此代码提供给您的朋友"),
        "referralStep2": MessageLookupByLibrary.simpleMessage("2. 他们注册一个付费计划"),
        "referralStep3": m43,
        "referrals": MessageLookupByLibrary.simpleMessage("推荐"),
        "referralsAreCurrentlyPaused":
            MessageLookupByLibrary.simpleMessage("推荐已暂停"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "同时从“设置”->“存储”中清空“最近删除”以领取释放的空间"),
        "remindToEmptyEnteTrash":
            MessageLookupByLibrary.simpleMessage("同时清空您的“回收站”以领取释放的空间"),
        "remoteImages": MessageLookupByLibrary.simpleMessage("云端图像"),
        "remoteThumbnails": MessageLookupByLibrary.simpleMessage("云端缩略图"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("云端视频"),
        "remove": MessageLookupByLibrary.simpleMessage("移除"),
        "removeDuplicates": MessageLookupByLibrary.simpleMessage("移除重复内容"),
        "removeDuplicatesDesc":
            MessageLookupByLibrary.simpleMessage("检查并删除完全重复的文件。"),
        "removeFromAlbum": MessageLookupByLibrary.simpleMessage("从相册中移除"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("要从相册中移除吗？"),
        "removeFromFavorite": MessageLookupByLibrary.simpleMessage("从收藏中移除"),
        "removeLink": MessageLookupByLibrary.simpleMessage("移除链接"),
        "removeParticipant": MessageLookupByLibrary.simpleMessage("移除参与者"),
        "removeParticipantBody": m44,
        "removePersonLabel": MessageLookupByLibrary.simpleMessage("移除人物标签"),
        "removePublicLink": MessageLookupByLibrary.simpleMessage("删除公开链接"),
        "removeShareItemsWarning":
            MessageLookupByLibrary.simpleMessage("您要删除的某些项目是由其他人添加的，您将无法访问它们"),
        "removeWithQuestionMark": MessageLookupByLibrary.simpleMessage("要移除吗?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("正在从收藏中删除..."),
        "rename": MessageLookupByLibrary.simpleMessage("重命名"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("重命名相册"),
        "renameFile": MessageLookupByLibrary.simpleMessage("重命名文件"),
        "renewSubscription": MessageLookupByLibrary.simpleMessage("续费订阅"),
        "renewsOn": m45,
        "reportABug": MessageLookupByLibrary.simpleMessage("报告错误"),
        "reportBug": MessageLookupByLibrary.simpleMessage("报告错误"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("重新发送电子邮件"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage("重置忽略的文件"),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage("重置密码"),
        "resetToDefault": MessageLookupByLibrary.simpleMessage("重置为默认设置"),
        "restore": MessageLookupByLibrary.simpleMessage("恢复"),
        "restoreToAlbum": MessageLookupByLibrary.simpleMessage("恢复到相册"),
        "restoringFiles": MessageLookupByLibrary.simpleMessage("正在恢复文件..."),
        "retry": MessageLookupByLibrary.simpleMessage("重试"),
        "reviewDeduplicateItems":
            MessageLookupByLibrary.simpleMessage("请检查并删除您认为重复的项目。"),
        "reviewSuggestions": MessageLookupByLibrary.simpleMessage("查看建议"),
        "right": MessageLookupByLibrary.simpleMessage("向右"),
        "rotate": MessageLookupByLibrary.simpleMessage("旋转"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("向左旋转"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("向右旋转"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("安全存储"),
        "save": MessageLookupByLibrary.simpleMessage("保存"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("保存拼贴"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("保存副本"),
        "saveKey": MessageLookupByLibrary.simpleMessage("保存密钥"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage("若您尚未保存，请妥善保存此恢复密钥"),
        "saving": MessageLookupByLibrary.simpleMessage("正在保存..."),
        "savingEdits": MessageLookupByLibrary.simpleMessage("正在保存编辑内容..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("扫描二维码/条码"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage("用您的身份验证器应用\n扫描此条码"),
        "search": MessageLookupByLibrary.simpleMessage("搜索"),
        "searchAlbumsEmptySection": MessageLookupByLibrary.simpleMessage("相册"),
        "searchByAlbumNameHint": MessageLookupByLibrary.simpleMessage("相册名称"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• 相册名称（例如“相机”）\n• 文件类型（例如“视频”、“.gif”）\n• 年份和月份（例如“2022”、“一月”）\n• 假期（例如“圣诞节”）\n• 照片说明（例如“#和女儿独居，好开心啊”）"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "在照片信息中添加“#旅游”等描述，以便在此处快速找到它们"),
        "searchDatesEmptySection":
            MessageLookupByLibrary.simpleMessage("按日期搜索，月份或年份"),
        "searchFaceEmptySection":
            MessageLookupByLibrary.simpleMessage("待索引完成后，人物将显示在此处"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("文件类型和名称"),
        "searchHint1": MessageLookupByLibrary.simpleMessage("在设备上快速搜索"),
        "searchHint2": MessageLookupByLibrary.simpleMessage("照片日期、描述"),
        "searchHint3": MessageLookupByLibrary.simpleMessage("相册、文件名和类型"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("位置"),
        "searchHint5": MessageLookupByLibrary.simpleMessage("即将到来：面部和魔法搜索✨"),
        "searchLocationEmptySection":
            MessageLookupByLibrary.simpleMessage("在照片的一定半径内拍摄的几组照片"),
        "searchPeopleEmptySection":
            MessageLookupByLibrary.simpleMessage("邀请他人，您将在此看到他们分享的所有照片"),
        "searchResultCount": m46,
        "security": MessageLookupByLibrary.simpleMessage("安全"),
        "selectALocation": MessageLookupByLibrary.simpleMessage("选择一个位置"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("首先选择一个位置"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("选择相册"),
        "selectAll": MessageLookupByLibrary.simpleMessage("全选"),
        "selectFoldersForBackup":
            MessageLookupByLibrary.simpleMessage("选择要备份的文件夹"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage("选择要添加的项目"),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("选择语言"),
        "selectMorePhotos": MessageLookupByLibrary.simpleMessage("选择更多照片"),
        "selectReason": MessageLookupByLibrary.simpleMessage("选择原因"),
        "selectYourPlan": MessageLookupByLibrary.simpleMessage("选择您的计划"),
        "selectedFilesAreNotOnEnte":
            MessageLookupByLibrary.simpleMessage("所选文件不在 Ente 上"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage("所选文件夹将被加密并备份"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage("所选项目将从所有相册中删除并移动到回收站。"),
        "selectedPhotos": m47,
        "selectedPhotosWithYours": m48,
        "send": MessageLookupByLibrary.simpleMessage("发送"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("发送电子邮件"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("发送邀请"),
        "sendLink": MessageLookupByLibrary.simpleMessage("发送链接"),
        "serverEndpoint": MessageLookupByLibrary.simpleMessage("服务器端点"),
        "sessionExpired": MessageLookupByLibrary.simpleMessage("会话已过期"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("设置密码"),
        "setAs": MessageLookupByLibrary.simpleMessage("设置为"),
        "setCover": MessageLookupByLibrary.simpleMessage("设置封面"),
        "setLabel": MessageLookupByLibrary.simpleMessage("设置"),
        "setPasswordTitle": MessageLookupByLibrary.simpleMessage("设置密码"),
        "setRadius": MessageLookupByLibrary.simpleMessage("设定半径"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("设置完成"),
        "share": MessageLookupByLibrary.simpleMessage("分享"),
        "shareALink": MessageLookupByLibrary.simpleMessage("分享链接"),
        "shareAlbumHint":
            MessageLookupByLibrary.simpleMessage("打开相册并点击右上角的分享按钮进行分享"),
        "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage("立即分享相册"),
        "shareLink": MessageLookupByLibrary.simpleMessage("分享链接"),
        "shareMyVerificationID": m49,
        "shareOnlyWithThePeopleYouWant":
            MessageLookupByLibrary.simpleMessage("仅与您想要的人分享"),
        "shareTextConfirmOthersVerificationID": m50,
        "shareTextRecommendUsingEnte":
            MessageLookupByLibrary.simpleMessage("下载 Ente，让我们轻松共享高质量的原始照片和视频"),
        "shareTextReferralCode": m51,
        "shareWithNonenteUsers":
            MessageLookupByLibrary.simpleMessage("与非 Ente 用户共享"),
        "shareWithPeopleSectionTitle": m52,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("分享您的第一个相册"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "与其他 Ente 用户（包括免费计划用户）创建共享和协作相册。"),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("由我共享的"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("您共享的"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("新共享的照片"),
        "sharedPhotoNotificationsExplanation":
            MessageLookupByLibrary.simpleMessage("当有人将照片添加到您所属的共享相册时收到通知"),
        "sharedWith": m53,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("与我共享"),
        "sharedWithYou": MessageLookupByLibrary.simpleMessage("已与您共享"),
        "sharing": MessageLookupByLibrary.simpleMessage("正在分享..."),
        "showMemories": MessageLookupByLibrary.simpleMessage("显示回忆"),
        "signOutFromOtherDevices":
            MessageLookupByLibrary.simpleMessage("从其他设备退出登录"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "如果你认为有人可能知道你的密码，你可以强制所有使用你账户的其他设备退出登录。"),
        "signOutOtherDevices": MessageLookupByLibrary.simpleMessage("登出其他设备"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "我同意 <u-terms>服务条款</u-terms> 和 <u-policy>隐私政策</u-policy>"),
        "singleFileDeleteFromDevice": m54,
        "singleFileDeleteHighlight":
            MessageLookupByLibrary.simpleMessage("它将从所有相册中删除。"),
        "singleFileInBothLocalAndRemote": m55,
        "singleFileInRemoteOnly": m56,
        "skip": MessageLookupByLibrary.simpleMessage("跳过"),
        "social": MessageLookupByLibrary.simpleMessage("社交"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage("有些项目同时存在于 Ente 和您的设备中。"),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage("您要删除的部分文件仅在您的设备上可用，且删除后无法恢复"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage("与您共享相册的人应该会在他们的设备上看到相同的 ID。"),
        "somethingWentWrong": MessageLookupByLibrary.simpleMessage("出了些问题"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("出了点问题，请重试"),
        "sorry": MessageLookupByLibrary.simpleMessage("抱歉"),
        "sorryCouldNotAddToFavorites":
            MessageLookupByLibrary.simpleMessage("抱歉，无法添加到收藏！"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage("抱歉，无法从收藏中移除！"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage("抱歉，您输入的代码不正确"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "抱歉，我们无法在此设备上生成安全密钥。\n\n请使用其他设备注册。"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("排序方式"),
        "sortNewestFirst": MessageLookupByLibrary.simpleMessage("最新在前"),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage("最旧在前"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ 成功"),
        "startBackup": MessageLookupByLibrary.simpleMessage("开始备份"),
        "status": MessageLookupByLibrary.simpleMessage("状态"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage("您想停止投放吗？"),
        "stopCastingTitle": MessageLookupByLibrary.simpleMessage("停止投放"),
        "storage": MessageLookupByLibrary.simpleMessage("存储空间"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("家庭"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("您"),
        "storageInGB": m57,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage("已超出存储限制"),
        "storageUsageInfo": m58,
        "strongStrength": MessageLookupByLibrary.simpleMessage("强"),
        "subAlreadyLinkedErrMessage": m59,
        "subWillBeCancelledOn": m60,
        "subscribe": MessageLookupByLibrary.simpleMessage("订阅"),
        "subscribeToEnableSharing":
            MessageLookupByLibrary.simpleMessage("您的订阅似乎已过期。请订阅以启用分享。"),
        "subscription": MessageLookupByLibrary.simpleMessage("订阅"),
        "success": MessageLookupByLibrary.simpleMessage("成功"),
        "successfullyArchived": MessageLookupByLibrary.simpleMessage("归档成功"),
        "successfullyHid": MessageLookupByLibrary.simpleMessage("已成功隐藏"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("取消归档成功"),
        "successfullyUnhid": MessageLookupByLibrary.simpleMessage("已成功取消隐藏"),
        "suggestFeatures": MessageLookupByLibrary.simpleMessage("建议新功能"),
        "support": MessageLookupByLibrary.simpleMessage("支持"),
        "syncProgress": m61,
        "syncStopped": MessageLookupByLibrary.simpleMessage("同步已停止"),
        "syncing": MessageLookupByLibrary.simpleMessage("正在同步···"),
        "systemTheme": MessageLookupByLibrary.simpleMessage("适应系统"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("点击以复制"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage("点击以输入代码"),
        "tempErrorContactSupportIfPersists":
            MessageLookupByLibrary.simpleMessage(
                "看起来出了点问题。 请稍后重试。 如果错误仍然存在，请联系我们的支持团队。"),
        "terminate": MessageLookupByLibrary.simpleMessage("终止"),
        "terminateSession": MessageLookupByLibrary.simpleMessage("是否终止会话？"),
        "terms": MessageLookupByLibrary.simpleMessage("使用条款"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("使用条款"),
        "thankYou": MessageLookupByLibrary.simpleMessage("非常感谢您"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("感谢您的订阅！"),
        "theDownloadCouldNotBeCompleted":
            MessageLookupByLibrary.simpleMessage("未能完成下载"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage("您输入的恢复密钥不正确"),
        "theme": MessageLookupByLibrary.simpleMessage("主题"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage("这些项目将从您的设备中删除。"),
        "theyAlsoGetXGb": m62,
        "theyWillBeDeletedFromAllAlbums":
            MessageLookupByLibrary.simpleMessage("他们将从所有相册中删除。"),
        "thisActionCannotBeUndone":
            MessageLookupByLibrary.simpleMessage("此操作无法撤销"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage("此相册已经有一个协作链接"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage("如果您丢失了双重认证方式，这可以用来恢复您的账户"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("此设备"),
        "thisEmailIsAlreadyInUse":
            MessageLookupByLibrary.simpleMessage("这个邮箱地址已经被使用"),
        "thisImageHasNoExifData":
            MessageLookupByLibrary.simpleMessage("此图像没有Exif 数据"),
        "thisIsPersonVerificationId": m63,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("这是您的验证 ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage("这将使您在以下设备中退出登录："),
        "thisWillLogYouOutOfThisDevice":
            MessageLookupByLibrary.simpleMessage("这将使您在此设备上退出登录！"),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage("隐藏照片或视频"),
        "toResetVerifyEmail":
            MessageLookupByLibrary.simpleMessage("要重置您的密码，请先验证您的电子邮件。"),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("当天日志"),
        "total": MessageLookupByLibrary.simpleMessage("总计"),
        "totalSize": MessageLookupByLibrary.simpleMessage("总大小"),
        "trash": MessageLookupByLibrary.simpleMessage("回收站"),
        "trashDaysLeft": m64,
        "trim": MessageLookupByLibrary.simpleMessage("修剪"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("请再试一次"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "打开备份可自动上传添加到此设备文件夹的文件至 Ente。"),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans":
            MessageLookupByLibrary.simpleMessage("在年度计划上免费获得 2 个月"),
        "twofactor": MessageLookupByLibrary.simpleMessage("双重认证"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage("双重认证已被禁用"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("双重认证"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage("成功重置双重认证"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage("双重认证设置"),
        "unarchive": MessageLookupByLibrary.simpleMessage("取消存档"),
        "unarchiveAlbum": MessageLookupByLibrary.simpleMessage("取消存档相册"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("正在取消归档..."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("未分类的"),
        "unhide": MessageLookupByLibrary.simpleMessage("取消隐藏"),
        "unhideToAlbum": MessageLookupByLibrary.simpleMessage("取消隐藏到相册"),
        "unhiding": MessageLookupByLibrary.simpleMessage("正在取消隐藏..."),
        "unhidingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("正在取消隐藏文件到相册"),
        "unlock": MessageLookupByLibrary.simpleMessage("解锁"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("取消置顶相册"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("取消全部选择"),
        "update": MessageLookupByLibrary.simpleMessage("更新"),
        "updateAvailable": MessageLookupByLibrary.simpleMessage("有可用的更新"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("正在更新文件夹选择..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("升级"),
        "uploadingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("正在将文件上传到相册..."),
        "upto50OffUntil4thDec":
            MessageLookupByLibrary.simpleMessage("最高五折优惠，直至12月4日。"),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "可用存储空间受您当前计划的限制。 当您升级您的计划时，超出要求的存储空间将自动变为可用。"),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage("对不在 Ente 上的人使用公开链接"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage("使用恢复密钥"),
        "useSelectedPhoto": MessageLookupByLibrary.simpleMessage("使用所选照片"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("已用空间"),
        "validTill": m65,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("验证失败，请重试"),
        "verificationId": MessageLookupByLibrary.simpleMessage("验证 ID"),
        "verify": MessageLookupByLibrary.simpleMessage("验证"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("验证电子邮件"),
        "verifyEmailID": m66,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("验证"),
        "verifyPasskey": MessageLookupByLibrary.simpleMessage("验证通行密钥"),
        "verifyPassword": MessageLookupByLibrary.simpleMessage("验证密码"),
        "verifying": MessageLookupByLibrary.simpleMessage("正在验证..."),
        "verifyingRecoveryKey":
            MessageLookupByLibrary.simpleMessage("正在验证恢复密钥..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("视频"),
        "videos": MessageLookupByLibrary.simpleMessage("视频"),
        "viewActiveSessions": MessageLookupByLibrary.simpleMessage("查看活动会话"),
        "viewAddOnButton": MessageLookupByLibrary.simpleMessage("查看附加组件"),
        "viewAll": MessageLookupByLibrary.simpleMessage("查看全部"),
        "viewAllExifData": MessageLookupByLibrary.simpleMessage("查看所有 EXIF 数据"),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("大文件"),
        "viewLargeFilesDesc":
            MessageLookupByLibrary.simpleMessage("查看占用存储空间最多的文件"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("查看日志"),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage("查看恢复密钥"),
        "viewer": MessageLookupByLibrary.simpleMessage("查看者"),
        "visitWebToManage":
            MessageLookupByLibrary.simpleMessage("请访问 web.ente.io 来管理您的订阅"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("等待验证..."),
        "waitingForWifi": MessageLookupByLibrary.simpleMessage("正在等待 WiFi..."),
        "weAreOpenSource": MessageLookupByLibrary.simpleMessage("我们是开源的 ！"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage("我们不支持编辑您尚未拥有的照片和相册"),
        "weHaveSendEmailTo": m67,
        "weakStrength": MessageLookupByLibrary.simpleMessage("弱"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("欢迎回来！"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("更新日志"),
        "yearly": MessageLookupByLibrary.simpleMessage("每年"),
        "yearsAgo": m68,
        "yes": MessageLookupByLibrary.simpleMessage("是"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("是的，取消"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage("是的，转换为查看者"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("是的, 删除"),
        "yesDiscardChanges": MessageLookupByLibrary.simpleMessage("是的，放弃更改"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("是的，退出登陆"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("是，移除"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("是的，续费"),
        "you": MessageLookupByLibrary.simpleMessage("您"),
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("你在一个家庭计划中！"),
        "youAreOnTheLatestVersion":
            MessageLookupByLibrary.simpleMessage("当前为最新版本"),
        "youCanAtMaxDoubleYourStorage":
            MessageLookupByLibrary.simpleMessage("* 您最多可以将您的存储空间增加一倍"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage("您可以在分享选项卡中管理您的链接。"),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage("您可以尝试搜索不同的查询。"),
        "youCannotDowngradeToThisPlan":
            MessageLookupByLibrary.simpleMessage("您不能降级到此计划"),
        "youCannotShareWithYourself":
            MessageLookupByLibrary.simpleMessage("莫开玩笑，您不能与自己分享"),
        "youDontHaveAnyArchivedItems":
            MessageLookupByLibrary.simpleMessage("您没有任何存档的项目。"),
        "youHaveSuccessfullyFreedUp": m69,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("您的账户已删除"),
        "yourMap": MessageLookupByLibrary.simpleMessage("您的地图"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage("您的计划已成功降级"),
        "yourPlanWasSuccessfullyUpgraded":
            MessageLookupByLibrary.simpleMessage("您的计划已成功升级"),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("您购买成功！"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage("无法获取您的存储详情"),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("您的订阅已过期"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage("您的订阅已成功更新"),
        "yourVerificationCodeHasExpired":
            MessageLookupByLibrary.simpleMessage("您的验证码已过期"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage("您没有可以被清除的重复文件"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage("您在此相册中没有可以删除的文件"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage("缩小以查看照片")
      };
}
