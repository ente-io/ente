// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja locale. All the
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
  String get localeName => 'ja';

  static String m0(title) => "${title} (私)";

  static String m3(storageAmount, endDate) =>
      "あなたの ${storageAmount} アドオンは ${endDate} まで有効です";

  static String m5(emailOrName) => "${emailOrName} が追加";

  static String m6(albumName) => "${albumName} に追加しました";

  static String m7(name) => "${name}に注目！";

  static String m8(count) =>
      "${Intl.plural(count, zero: '参加者なし', one: '1 参加者', other: '${count} 参加者')}";

  static String m9(versionValue) => "バージョン: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} 無料";

  static String m11(name) => "${name}と見た美しい景色！";

  static String m12(paymentProvider) =>
      "まず${paymentProvider} から既存のサブスクリプションをキャンセルしてください";

  static String m13(user) =>
      "${user} は写真をアルバムに追加できなくなります\n\n※${user} が追加した写真は今後も${user} が削除できます";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': '家族は ${storageAmountInGb} GB 受け取っています',
            'false': 'あなたは ${storageAmountInGb} GB 受け取っています',
            'other': 'あなたは ${storageAmountInGb} GB受け取っています',
          })}";

  static String m15(albumName) => "${albumName} のコラボレーションリンクを生成しました";

  static String m16(count) =>
      "${Intl.plural(count, zero: '${count}人のコラボレーターを追加', one: '${count}人のコラボレーターを追加', other: '${count}人のコラボレーターを追加')}";

  static String m17(email, numOfDays) =>
      "${email} を信頼する連絡先として追加しようとしています。 ${numOfDays} 日間あなたの利用がなくなった場合、アカウントを復旧することができるようになります。";

  static String m18(familyAdminEmail) =>
      "サブスクリプションを管理するには、 <green>${familyAdminEmail}</green> に連絡してください";

  static String m19(provider) =>
      "${provider} サブスクリプションを管理するには、support@ente.io までご連絡ください。";

  static String m20(endpoint) => "${endpoint} に接続しました";

  static String m21(count) =>
      "${Intl.plural(count, one: '${count} 個の項目を削除', other: '${count} 個の項目を削除')}";

  static String m23(currentlyDeleting, totalCount) =>
      "${currentlyDeleting} / ${totalCount} を削除中";

  static String m24(albumName) => "\"${albumName}\" にアクセスするための公開リンクが削除されます。";

  static String m25(supportEmail) =>
      "あなたの登録したメールアドレスから${supportEmail} にメールを送ってください";

  static String m26(count, storageSaved) =>
      "お掃除しました ${Intl.plural(count, other: '${count} 個の重複ファイル')}, (${storageSaved}が開放されます！)";

  static String m27(count, formattedSize) =>
      "${count} 個のファイル、それぞれ${formattedSize}";

  static String m29(newEmail) => "メールアドレスが ${newEmail} に変更されました";

  static String m30(email) => "${email} は Ente アカウントを持っていません。";

  static String m31(email) =>
      "${email} はEnteアカウントを持っていません。\n\n写真を共有するために「招待」を送信してください。";

  static String m32(name) => "${name}抱きしめて！";

  static String m33(text) => "${text} の写真が見つかりました";

  static String m34(name) => "${name}とご飯！";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, other: '${formattedNumber} 個のファイル')} が安全にバックアップされました";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, other: '${formattedNumber} ファイル')} が安全にバックアップされました";

  static String m37(storageAmountInGB) =>
      "誰かが有料プランにサインアップしてコードを適用する度に ${storageAmountInGB} GB";

  static String m38(endDate) => "無料トライアルは${endDate} までです";

  static String m40(sizeInMBorGB) => "${sizeInMBorGB} を解放する";

  static String m42(currentlyProcessing, totalCount) =>
      "${currentlyProcessing} / ${totalCount} を処理中";

  static String m43(name) => "${name}とハイキング！";

  static String m44(count) => "${Intl.plural(count, other: '${count}個のアイテム')}";

  static String m45(name) => "前回の${name}との時間";

  static String m46(email) => "${email} があなたを信頼する連絡先として招待しました";

  static String m47(expiryTime) => "リンクは ${expiryTime} に期限切れになります";

  static String m48(email) => "この人物を ${email}に紐づけ";

  static String m49(personName, email) => "${personName} を ${email} に紐づけします";

  static String m52(albumName) => "${albumName} に移動しました";

  static String m53(personName) => "${personName} の候補はありません";

  static String m54(name) => "${name} ではありませんか？";

  static String m55(familyAdminEmail) =>
      "コードを変更するには、 ${familyAdminEmail} までご連絡ください。";

  static String m56(name) => "${name}とパーティー！";

  static String m57(passwordStrengthValue) =>
      "パスワードの長さ: ${passwordStrengthValue}";

  static String m58(providerName) => "請求された場合は、 ${providerName} のサポートに連絡してください";

  static String m59(name, age) => "${name}が${age}才！";

  static String m60(name, age) => "${name}が${age}才になった！";

  static String m61(count) =>
      "${Intl.plural(count, zero: '0枚の写真', one: '1枚の写真', other: '${count} 枚の写真')}";

  static String m63(endDate) =>
      "${endDate} まで無料トライアルが有効です。\nその後、有料プランを選択することができます。";

  static String m64(toEmail) => "${toEmail} にメールでご連絡ください";

  static String m65(toEmail) => "ログを以下のアドレスに送信してください \n${toEmail}";

  static String m66(name) => "${name}と一緒にポーズ！";

  static String m67(folderName) => "${folderName} を処理中...";

  static String m68(storeName) => "${storeName} で評価";

  static String m69(name) => "あなたを ${name} に紐づけました";

  static String m70(days, email) =>
      "${days} 日後にアカウントにアクセスできます。通知は ${email}に送信されます。";

  static String m71(email) => "${email}のアカウントを復元できるようになりました。新しいパスワードを設定してください。";

  static String m72(email) => "${email} はあなたのアカウントを復元しようとしています。";

  static String m73(storageInGB) => "3. お二人とも ${storageInGB} GB*を無料で手に入ります。";

  static String m74(userEmail) =>
      "${userEmail} はこの共有アルバムから退出します\n\n${userEmail} が追加した写真もアルバムから削除されます";

  static String m75(endDate) => "サブスクリプションは ${endDate} に更新します";

  static String m76(name) => "${name}と車で旅行！";

  static String m77(count) => "${Intl.plural(count, other: '${count} 個の結果')}";

  static String m78(snapshotLength, searchLength) =>
      "セクションの長さの不一致: ${snapshotLength} != ${searchLength}";

  static String m80(count) => "${count} 個を選択";

  static String m81(count, yourCount) => "${count} 個選択中（${yourCount} あなた）";

  static String m82(name) => "${name}とセルフィー！";

  static String m83(verificationID) => "私の確認ID: ente.ioの ${verificationID}";

  static String m84(verificationID) =>
      "これがあなたのente.io確認用IDであることを確認できますか？ ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "リフェラルコード: ${referralCode}\n\n設定→一般→リフェラルで使うことで${referralStorageInGB}が無料になります(あなたが有料プランに加入したあと)。\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: '誰かと共有しましょう', one: '1人と共有されています', other: '${numberOfPeople} 人と共有されています')}";

  static String m87(emailIDs) => "${emailIDs} と共有中";

  static String m88(fileType) => "${fileType} はEnteから削除されます。";

  static String m89(fileType) => "この ${fileType} はEnteとお使いのデバイスの両方にあります。";

  static String m90(fileType) => "${fileType} はEnteから削除されます。";

  static String m91(name) => "${name}とスポーツ！";

  static String m92(name) => "${name}にスポットライト！";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m94(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} / ${totalAmount} ${totalStorageUnit} 使用";

  static String m95(id) =>
      "あなたの ${id} はすでに別のEnteアカウントにリンクされています。\nこのアカウントであなたの ${id} を使用したい場合は、サポートにお問い合わせください。";

  static String m96(endDate) => "サブスクリプションは ${endDate} でキャンセルされます";

  static String m97(completed, total) => "${completed}/${total} のメモリが保存されました";

  static String m98(ignoreReason) =>
      "アップロードするにはタップしてください。 以下の理由のためアップロードは現在無視されています: ${ignoreReason}";

  static String m99(storageAmountInGB) => "紹介者も ${storageAmountInGB} GB を得ます";

  static String m100(email) => "これは ${email} の確認用ID";

  static String m101(count) =>
      "${Intl.plural(count, one: '${count} 1年前の今週', other: '${count}年前の今週')}";

  static String m102(dateFormat) => "${dateFormat} から年";

  static String m103(count) =>
      "${Intl.plural(count, zero: '', one: '1日', other: '${count} 日')}";

  static String m104(year) => "${year}年の旅行";

  static String m105(location) => "${location}への旅行";

  static String m106(email) => "あなたは ${email}から信頼する連絡先になってもらうよう、お願いされています。";

  static String m107(galleryType) =>
      "このギャラリーのタイプ ${galleryType} は名前の変更には対応していません";

  static String m108(ignoreReason) => "以下の理由によりアップロードは無視されます: ${ignoreReason}";

  static String m109(count) => "${count} メモリを保存しています...";

  static String m110(endDate) => "${endDate} まで";

  static String m111(email) => "${email} を確認";

  static String m114(email) => "<green>${email}</green>にメールを送りました";

  static String m115(name) => "Wish \$${name} a happy birthday! 🎉";

  static String m116(count) => "${Intl.plural(count, other: '${count} 年前')}";

  static String m117(name) => "あなたと${name}";

  static String m118(storageSaved) => "${storageSaved} を解放しました";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable":
            MessageLookupByLibrary.simpleMessage("Enteの新しいバージョンが利用可能です。"),
        "about": MessageLookupByLibrary.simpleMessage("このアプリについて"),
        "acceptTrustInvite": MessageLookupByLibrary.simpleMessage("招待を受け入れる"),
        "account": MessageLookupByLibrary.simpleMessage("アカウント"),
        "accountIsAlreadyConfigured":
            MessageLookupByLibrary.simpleMessage("アカウントが既に設定されています"),
        "accountOwnerPersonAppbarTitle": m0,
        "accountWelcomeBack": MessageLookupByLibrary.simpleMessage("おかえりなさい！"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "もしパスワードを忘れたら、自身のデータを失うことを理解しました"),
        "activeSessions": MessageLookupByLibrary.simpleMessage("アクティブなセッション"),
        "add": MessageLookupByLibrary.simpleMessage("追加"),
        "addAName": MessageLookupByLibrary.simpleMessage("名前を追加"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage("新しいEメールアドレスを追加"),
        "addCollaborator": MessageLookupByLibrary.simpleMessage("コラボレーターを追加"),
        "addFiles": MessageLookupByLibrary.simpleMessage("ファイルを追加"),
        "addFromDevice": MessageLookupByLibrary.simpleMessage("デバイスから追加"),
        "addLocation": MessageLookupByLibrary.simpleMessage("位置情報を追加"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("追加"),
        "addMore": MessageLookupByLibrary.simpleMessage("さらに追加"),
        "addName": MessageLookupByLibrary.simpleMessage("名前を追加"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("名前をつける、あるいは既存の人物にまとめる"),
        "addNew": MessageLookupByLibrary.simpleMessage("新規追加"),
        "addNewPerson": MessageLookupByLibrary.simpleMessage("新しい人物を追加"),
        "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage("アドオンの詳細"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("アドオン"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("写真を追加"),
        "addSelected": MessageLookupByLibrary.simpleMessage("選んだものをアルバムに追加"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("アルバムに追加"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Enteに追加"),
        "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage("非表示アルバムに追加"),
        "addTrustedContact": MessageLookupByLibrary.simpleMessage("信頼する連絡先を追加"),
        "addViewer": MessageLookupByLibrary.simpleMessage("ビューアーを追加"),
        "addYourPhotosNow": MessageLookupByLibrary.simpleMessage("写真を今すぐ追加する"),
        "addedAs": MessageLookupByLibrary.simpleMessage("追加:"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("お気に入りに追加しています..."),
        "admiringThem": m7,
        "advanced": MessageLookupByLibrary.simpleMessage("詳細"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("高度な設定"),
        "after1Day": MessageLookupByLibrary.simpleMessage("1日後"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("1時間後"),
        "after1Month": MessageLookupByLibrary.simpleMessage("1ヶ月後"),
        "after1Week": MessageLookupByLibrary.simpleMessage("1週間後"),
        "after1Year": MessageLookupByLibrary.simpleMessage("1年後"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("所有者"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("アルバムタイトル"),
        "albumUpdated": MessageLookupByLibrary.simpleMessage("アルバムが更新されました"),
        "albums": MessageLookupByLibrary.simpleMessage("アルバム"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ オールクリア"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("すべての思い出が保存されました"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "この人のグループ化がリセットされ、この人かもしれない写真への提案もなくなります"),
        "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
            "これはグループ内の最初のものです。他の選択した写真は、この新しい日付に基づいて自動的にシフトされます"),
        "allow": MessageLookupByLibrary.simpleMessage("許可"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "リンクを持つ人が共有アルバムに写真を追加できるようにします。"),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage("写真の追加を許可"),
        "allowAppToOpenSharedAlbumLinks":
            MessageLookupByLibrary.simpleMessage("共有アルバムリンクを開くことをアプリに許可する"),
        "allowDownloads": MessageLookupByLibrary.simpleMessage("ダウンロードを許可"),
        "allowPeopleToAddPhotos":
            MessageLookupByLibrary.simpleMessage("写真の追加をメンバーに許可する"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Enteがライブラリを表示およびバックアップできるように、端末の設定から写真へのアクセスを許可してください。"),
        "allowPermTitle": MessageLookupByLibrary.simpleMessage("写真へのアクセスを許可"),
        "androidBiometricHint": MessageLookupByLibrary.simpleMessage("本人確認を行う"),
        "androidBiometricNotRecognized":
            MessageLookupByLibrary.simpleMessage("認識できません。再試行してください。"),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("生体認証が必要です"),
        "androidBiometricSuccess": MessageLookupByLibrary.simpleMessage("成功"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("キャンセル"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage("デバイスの認証情報が必要です"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage("デバイスの認証情報が必要です"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "生体認証がデバイスで設定されていません。生体認証を追加するには、\"設定 > セキュリティ\"を開いてください。"),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android、iOS、Web、Desktop"),
        "androidSignInTitle": MessageLookupByLibrary.simpleMessage("認証が必要です"),
        "appIcon": MessageLookupByLibrary.simpleMessage("アプリアイコン"),
        "appLock": MessageLookupByLibrary.simpleMessage("アプリのロック"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "デバイスのデフォルトのロック画面と、カスタムロック画面のどちらを利用しますか？"),
        "appVersion": m9,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("適用"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("コードを適用"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("AppStore サブスクリプション"),
        "archive": MessageLookupByLibrary.simpleMessage("アーカイブ"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("アルバムをアーカイブ"),
        "archiving": MessageLookupByLibrary.simpleMessage("アーカイブ中です"),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage("本当にファミリープランを退会しますか？"),
        "areYouSureYouWantToCancel":
            MessageLookupByLibrary.simpleMessage("キャンセルしてもよろしいですか？"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage("プランを変更して良いですか？"),
        "areYouSureYouWantToExit":
            MessageLookupByLibrary.simpleMessage("本当に中止してよろしいですか？"),
        "areYouSureYouWantToLogout":
            MessageLookupByLibrary.simpleMessage("本当にログアウトしてよろしいですか？"),
        "areYouSureYouWantToRenew":
            MessageLookupByLibrary.simpleMessage("更新してもよろしいですか？"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage("この人を忘れてもよろしいですね？"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "サブスクリプションはキャンセルされました。理由を教えていただけますか？"),
        "askDeleteReason":
            MessageLookupByLibrary.simpleMessage("アカウントを削除する理由を教えて下さい"),
        "askYourLovedOnesToShare":
            MessageLookupByLibrary.simpleMessage("あなたの愛する人にシェアしてもらうように頼んでください"),
        "atAFalloutShelter": MessageLookupByLibrary.simpleMessage("核シェルターで"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage("メール確認を変更するには認証してください"),
        "authToChangeLockscreenSetting":
            MessageLookupByLibrary.simpleMessage("画面のロックの設定を変更するためには認証が必要です"),
        "authToChangeYourEmail":
            MessageLookupByLibrary.simpleMessage("メールアドレスを変更するには認証してください"),
        "authToChangeYourPassword":
            MessageLookupByLibrary.simpleMessage("メールアドレスを変更するには認証してください"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage("2段階認証を設定するには認証してください"),
        "authToInitiateAccountDeletion":
            MessageLookupByLibrary.simpleMessage("アカウントの削除をするためには認証が必要です"),
        "authToManageLegacy":
            MessageLookupByLibrary.simpleMessage("信頼する連絡先を管理するために認証してください"),
        "authToViewPasskey":
            MessageLookupByLibrary.simpleMessage("パスキーを表示するには認証してください"),
        "authToViewTrashedFiles":
            MessageLookupByLibrary.simpleMessage("削除したファイルを閲覧するには認証が必要です"),
        "authToViewYourActiveSessions":
            MessageLookupByLibrary.simpleMessage("アクティブなセッションを表示するためには認証が必要です"),
        "authToViewYourHiddenFiles":
            MessageLookupByLibrary.simpleMessage("隠しファイルを表示するには認証してください"),
        "authToViewYourMemories":
            MessageLookupByLibrary.simpleMessage("思い出を閲覧するためには認証が必要です"),
        "authToViewYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("リカバリーキーを表示するためには認証が必要です"),
        "authenticating": MessageLookupByLibrary.simpleMessage("認証中..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("認証が間違っています。もう一度お試しください"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("認証に成功しました！"),
        "autoCastDialogBody":
            MessageLookupByLibrary.simpleMessage("利用可能なキャストデバイスが表示されます。"),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "ローカルネットワークへのアクセス許可がEnte Photosアプリに与えられているか確認してください"),
        "autoLock": MessageLookupByLibrary.simpleMessage("自動ロック"),
        "autoLockFeatureDescription":
            MessageLookupByLibrary.simpleMessage("アプリがバックグラウンドでロックするまでの時間"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "技術的な不具合により、ログアウトしました。ご不便をおかけして申し訳ございません。"),
        "autoPair": MessageLookupByLibrary.simpleMessage("オートペアリング"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "自動ペアリングは Chromecast に対応しているデバイスでのみ動作します。"),
        "available": MessageLookupByLibrary.simpleMessage("ご利用可能"),
        "availableStorageSpace": m10,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("バックアップされたフォルダ"),
        "backgroundWithThem": m11,
        "backup": MessageLookupByLibrary.simpleMessage("バックアップ"),
        "backupFailed": MessageLookupByLibrary.simpleMessage("バックアップ失敗"),
        "backupFile": MessageLookupByLibrary.simpleMessage("バックアップファイル"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("モバイルデータを使ってバックアップ"),
        "backupSettings": MessageLookupByLibrary.simpleMessage("バックアップ設定"),
        "backupStatus": MessageLookupByLibrary.simpleMessage("バックアップの状態"),
        "backupStatusDescription":
            MessageLookupByLibrary.simpleMessage("バックアップされたアイテムがここに表示されます"),
        "backupVideos": MessageLookupByLibrary.simpleMessage("動画をバックアップ"),
        "beach": MessageLookupByLibrary.simpleMessage("砂浜と海"),
        "birthday": MessageLookupByLibrary.simpleMessage("誕生日"),
        "blackFridaySale": MessageLookupByLibrary.simpleMessage("ブラックフライデーセール"),
        "blog": MessageLookupByLibrary.simpleMessage("ブログ"),
        "cLDesc1": MessageLookupByLibrary.simpleMessage(
            "動画ストリーミングベータ版と再開可能なアップロード・ダウンロードの作業により、ファイルアップロード制限を10GBに増加しました。これはデスクトップとモバイルアプリの両方で利用可能です。"),
        "cLDesc2": MessageLookupByLibrary.simpleMessage(
            "バックグラウンドアップロードがAndroidデバイスに加えてiOSでもサポートされるようになりました。最新の写真や動画をバックアップするためにアプリを開く必要がありません。"),
        "cLDesc3": MessageLookupByLibrary.simpleMessage(
            "自動再生、次のメモリーへのスワイプなど、メモリー体験に大幅な改善を加えました。"),
        "cLDesc4": MessageLookupByLibrary.simpleMessage(
            "多くの内部改善とともに、検出されたすべての顔を確認し、類似した顔にフィードバックを提供し、1枚の写真から顔を追加/削除することがはるかに簡単になりました。"),
        "cLDesc5": MessageLookupByLibrary.simpleMessage(
            "Enteに保存したすべての誕生日について、その人のベスト写真のコレクションとともに、オプトアウト通知を受け取るようになります。"),
        "cLDesc6": MessageLookupByLibrary.simpleMessage(
            "アプリを閉じる前にアップロード/ダウンロードの完了を待つ必要がなくなりました。すべてのアップロードとダウンロードは途中で一時停止し、中断したところから再開できるようになりました。"),
        "cLTitle1": MessageLookupByLibrary.simpleMessage("大きな動画ファイルのアップロード"),
        "cLTitle2": MessageLookupByLibrary.simpleMessage("バックグラウンドアップロード"),
        "cLTitle3": MessageLookupByLibrary.simpleMessage("メモリーの自動再生"),
        "cLTitle4": MessageLookupByLibrary.simpleMessage("顔認識の改善"),
        "cLTitle5": MessageLookupByLibrary.simpleMessage("誕生日通知"),
        "cLTitle6": MessageLookupByLibrary.simpleMessage("再開可能なアップロードとダウンロード"),
        "cachedData": MessageLookupByLibrary.simpleMessage("キャッシュデータ"),
        "calculating": MessageLookupByLibrary.simpleMessage("計算中..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "申し訳ありません。このアルバムをアプリで開くことができませんでした。"),
        "canNotOpenTitle": MessageLookupByLibrary.simpleMessage("このアルバムは開けません"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage("他の人が作ったアルバムにはアップロードできません"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage("あなたが所有するファイルのみリンクを作成できます"),
        "canOnlyRemoveFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage("あなたが所有しているファイルのみを削除できます"),
        "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("リカバリをキャンセル"),
        "cancelAccountRecoveryBody":
            MessageLookupByLibrary.simpleMessage("リカバリをキャンセルしてもよろしいですか？"),
        "cancelOtherSubscription": m12,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("サブスクリプションをキャンセル"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles":
            MessageLookupByLibrary.simpleMessage("共有ファイルは削除できません"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("アルバムをキャスト"),
        "castIPMismatchBody":
            MessageLookupByLibrary.simpleMessage("TVと同じネットワーク上にいることを確認してください。"),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("アルバムのキャストに失敗しました"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "ペアリングしたいデバイスでcast.ente.ioにアクセスしてください。\n\nテレビでアルバムを再生するには以下のコードを入力してください。"),
        "centerPoint": MessageLookupByLibrary.simpleMessage("中心点"),
        "change": MessageLookupByLibrary.simpleMessage("変更"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Eメールを変更"),
        "changeLocationOfSelectedItems":
            MessageLookupByLibrary.simpleMessage("選択したアイテムの位置を変更しますか？"),
        "changePassword": MessageLookupByLibrary.simpleMessage("パスワードを変更"),
        "changePasswordTitle": MessageLookupByLibrary.simpleMessage("パスワードを変更"),
        "changePermissions": MessageLookupByLibrary.simpleMessage("権限を変更する"),
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("自分自身の紹介コードを変更する"),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage("アップデートを確認"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "メールボックスを確認してEメールの所有を証明してください(見つからない場合は、スパムの中も確認してください)"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("ステータスの確認"),
        "checking": MessageLookupByLibrary.simpleMessage("確認中…"),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("モデルを確認しています..."),
        "city": MessageLookupByLibrary.simpleMessage("市街"),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("無料のストレージを受け取る"),
        "claimMore": MessageLookupByLibrary.simpleMessage("もっと！"),
        "claimed": MessageLookupByLibrary.simpleMessage("受け取り済"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("未分類のクリーンアップ"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "他のアルバムに存在する「未分類」からすべてのファイルを削除"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("キャッシュをクリア"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("行った処理をクリアする"),
        "click": MessageLookupByLibrary.simpleMessage("• クリック"),
        "clickOnTheOverflowMenu":
            MessageLookupByLibrary.simpleMessage("• 三点ドットをクリックしてください"),
        "close": MessageLookupByLibrary.simpleMessage("閉じる"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage("時間ごとにまとめる"),
        "clubByFileName": MessageLookupByLibrary.simpleMessage("ファイル名ごとにまとめる"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("クラスタリングの進行状況"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("コードが適用されました。"),
        "codeChangeLimitReached":
            MessageLookupByLibrary.simpleMessage("コード変更の回数上限に達しました。"),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("コードがクリップボードにコピーされました"),
        "codeUsedByYou": MessageLookupByLibrary.simpleMessage("あなたが使用したコード"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Enteアプリやアカウントを持っていない人にも、共有アルバムに写真を追加したり表示したりできるリンクを作成します。"),
        "collaborativeLink": MessageLookupByLibrary.simpleMessage("共同作業リンク"),
        "collaborativeLinkCreatedFor": m15,
        "collaborator": MessageLookupByLibrary.simpleMessage("コラボレーター"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "コラボレーターは共有アルバムに写真やビデオを追加できます。"),
        "collaboratorsSuccessfullyAdded": m16,
        "collageLayout": MessageLookupByLibrary.simpleMessage("レイアウト"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("コラージュをギャラリーに保存しました"),
        "collect": MessageLookupByLibrary.simpleMessage("集める"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("イベントの写真を集めよう"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("写真を集めよう"),
        "collectPhotosDescription":
            MessageLookupByLibrary.simpleMessage("友達が写真をアップロードできるリンクを作成できます"),
        "color": MessageLookupByLibrary.simpleMessage("色"),
        "configuration": MessageLookupByLibrary.simpleMessage("設定"),
        "confirm": MessageLookupByLibrary.simpleMessage("確認"),
        "confirm2FADisable":
            MessageLookupByLibrary.simpleMessage("2 要素認証を無効にしてよろしいですか。"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("アカウント削除の確認"),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt":
            MessageLookupByLibrary.simpleMessage("はい、アカウントとすべてのアプリのデータを削除します"),
        "confirmPassword": MessageLookupByLibrary.simpleMessage("パスワードを確認"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage("プランの変更を確認"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("リカバリーキーを確認"),
        "confirmYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("リカバリーキーを確認"),
        "connectToDevice": MessageLookupByLibrary.simpleMessage("デバイスに接続"),
        "contactFamilyAdmin": m18,
        "contactSupport": MessageLookupByLibrary.simpleMessage("お問い合わせ"),
        "contactToManageSubscription": m19,
        "contacts": MessageLookupByLibrary.simpleMessage("連絡先"),
        "contents": MessageLookupByLibrary.simpleMessage("内容"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("つづける"),
        "continueOnFreeTrial":
            MessageLookupByLibrary.simpleMessage("無料トライアルで続ける"),
        "convertToAlbum": MessageLookupByLibrary.simpleMessage("アルバムに変換"),
        "copyEmailAddress": MessageLookupByLibrary.simpleMessage("メールアドレスをコピー"),
        "copyLink": MessageLookupByLibrary.simpleMessage("リンクをコピー"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage("認証アプリにこのコードをコピペしてください"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "データをバックアップできませんでした。\n後で再試行します。"),
        "couldNotFreeUpSpace":
            MessageLookupByLibrary.simpleMessage("スペースを解放できませんでした"),
        "couldNotUpdateSubscription":
            MessageLookupByLibrary.simpleMessage("サブスクリプションを更新できませんでした"),
        "count": MessageLookupByLibrary.simpleMessage("カウント"),
        "crashReporting": MessageLookupByLibrary.simpleMessage("クラッシュを報告"),
        "create": MessageLookupByLibrary.simpleMessage("作成"),
        "createAccount": MessageLookupByLibrary.simpleMessage("アカウント作成"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "長押しで写真を選択し、+をクリックしてアルバムを作成します"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("共同作業用リンクを作成"),
        "createCollage": MessageLookupByLibrary.simpleMessage("コラージュを作る"),
        "createNewAccount": MessageLookupByLibrary.simpleMessage("新規アカウントを作成"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("アルバムを作成または選択"),
        "createPublicLink": MessageLookupByLibrary.simpleMessage("公開リンクを作成"),
        "creatingLink": MessageLookupByLibrary.simpleMessage("リンクを作成中..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("重要なアップデートがあります"),
        "crop": MessageLookupByLibrary.simpleMessage("クロップ"),
        "currentUsageIs": MessageLookupByLibrary.simpleMessage("現在の使用状況 "),
        "currentlyRunning": MessageLookupByLibrary.simpleMessage("現在実行中"),
        "custom": MessageLookupByLibrary.simpleMessage("カスタム"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("ダーク"),
        "dayToday": MessageLookupByLibrary.simpleMessage("今日"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("昨日"),
        "declineTrustInvite": MessageLookupByLibrary.simpleMessage("招待を拒否する"),
        "decrypting": MessageLookupByLibrary.simpleMessage("復号しています"),
        "decryptingVideo": MessageLookupByLibrary.simpleMessage("ビデオの復号化中..."),
        "deduplicateFiles": MessageLookupByLibrary.simpleMessage("重複ファイル"),
        "delete": MessageLookupByLibrary.simpleMessage("削除"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("アカウントを削除"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "今までご利用ありがとうございました。改善点があれば、フィードバックをお寄せください"),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("アカウントの削除"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("アルバムの削除"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "このアルバムに含まれている写真 (およびビデオ) を <bold>すべて</bold> 他のアルバムからも削除しますか?"),
        "deleteAlbumsDialogBody":
            MessageLookupByLibrary.simpleMessage("空のアルバムはすべて削除されます。"),
        "deleteAll": MessageLookupByLibrary.simpleMessage("全て削除"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "このアカウントは他のEnteアプリも使用している場合はそれらにも紐づけされています。\nすべてのEnteアプリでアップロードされたデータは削除され、アカウントは完全に削除されます。"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "<warning>account-deletion@ente.io</warning>にあなたの登録したメールアドレスからメールを送信してください"),
        "deleteEmptyAlbums": MessageLookupByLibrary.simpleMessage("空のアルバムを削除"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("空のアルバムを削除しますか？"),
        "deleteFromBoth": MessageLookupByLibrary.simpleMessage("両方から削除"),
        "deleteFromDevice": MessageLookupByLibrary.simpleMessage("デバイスから削除"),
        "deleteFromEnte": MessageLookupByLibrary.simpleMessage("Enteから削除"),
        "deleteItemCount": m21,
        "deleteLocation": MessageLookupByLibrary.simpleMessage("位置情報を削除"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("写真を削除"),
        "deleteProgress": m23,
        "deleteReason1": MessageLookupByLibrary.simpleMessage("いちばん必要な機能がない"),
        "deleteReason2":
            MessageLookupByLibrary.simpleMessage("アプリや特定の機能が想定通りに動かない"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage("より良いサービスを見つけた"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage("該当する理由がない"),
        "deleteRequestSLAText":
            MessageLookupByLibrary.simpleMessage("リクエストは72時間以内に処理されます"),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("共有アルバムを削除しますか？"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "このアルバムは他の人からも削除されます\n\n他の人が共有してくれた写真も、あなたからは見れなくなります"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("選択解除"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("生き延びるためのデザイン"),
        "details": MessageLookupByLibrary.simpleMessage("詳細"),
        "developerSettings": MessageLookupByLibrary.simpleMessage("開発者向け設定"),
        "developerSettingsWarning":
            MessageLookupByLibrary.simpleMessage("開発者向け設定を変更してもよろしいですか？"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("コードを入力する"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "このデバイス上アルバムに追加されたファイルは自動的にEnteにアップロードされます。"),
        "deviceLock": MessageLookupByLibrary.simpleMessage("デバイスロック"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "進行中のバックアップがある場合、デバイスがスリープしないようにします。\n\n※容量の大きいアップロードがある際にご活用ください。"),
        "deviceNotFound": MessageLookupByLibrary.simpleMessage("デバイスが見つかりません"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("ご存知ですか?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage("自動ロックを無効にする"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "ビューアーはスクリーンショットを撮ったり、外部ツールを使用して写真のコピーを保存したりすることができます"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("ご注意ください"),
        "disableLinkMessage": m24,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage("2段階認証を無効にする"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage("2要素認証を無効にしています..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("新たな発見"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("赤ちゃん"),
        "discover_celebrations": MessageLookupByLibrary.simpleMessage("お祝い"),
        "discover_food": MessageLookupByLibrary.simpleMessage("食べ物"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("自然"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("丘"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("身分証"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("ミーム"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("メモ"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("ペット"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("レシート"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("スクリーンショット"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("セルフィー"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("夕焼け"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("訪問カード"),
        "discover_wallpapers": MessageLookupByLibrary.simpleMessage("壁紙"),
        "dismiss": MessageLookupByLibrary.simpleMessage("閉じる"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("サインアウトしない"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("あとで行う"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage("編集を破棄しますか？"),
        "done": MessageLookupByLibrary.simpleMessage("完了"),
        "dontSave": MessageLookupByLibrary.simpleMessage("保存しない"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("ストレージを倍にしよう"),
        "download": MessageLookupByLibrary.simpleMessage("ダウンロード"),
        "downloadFailed": MessageLookupByLibrary.simpleMessage("ダウンロード失敗"),
        "downloading": MessageLookupByLibrary.simpleMessage("ダウンロード中…"),
        "dropSupportEmail": m25,
        "duplicateFileCountWithStorageSaved": m26,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("編集"),
        "editLocation": MessageLookupByLibrary.simpleMessage("位置情報を編集"),
        "editLocationTagTitle": MessageLookupByLibrary.simpleMessage("位置情報を編集"),
        "editPerson": MessageLookupByLibrary.simpleMessage("人物を編集"),
        "editTime": MessageLookupByLibrary.simpleMessage("時刻を編集"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("編集が保存されました"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage("位置情報の編集はEnteでのみ表示されます"),
        "eligible": MessageLookupByLibrary.simpleMessage("対象となる"),
        "email": MessageLookupByLibrary.simpleMessage("Eメール"),
        "emailAlreadyRegistered":
            MessageLookupByLibrary.simpleMessage("このメールアドレスはすでに登録されています。"),
        "emailChangedTo": m29,
        "emailDoesNotHaveEnteAccount": m30,
        "emailNoEnteAccount": m31,
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("このメールアドレスはまだ登録されていません。"),
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("メール確認"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage("ログをメールで送信"),
        "embracingThem": m32,
        "emergencyContacts": MessageLookupByLibrary.simpleMessage("緊急連絡先"),
        "empty": MessageLookupByLibrary.simpleMessage("空"),
        "emptyTrash": MessageLookupByLibrary.simpleMessage("ゴミ箱を空にしますか？"),
        "enable": MessageLookupByLibrary.simpleMessage("有効化"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Enteは顔認識、マジック検索、その他の高度な検索機能のため、あなたのデバイス上で機械学習をしています"),
        "enableMachineLearningBanner":
            MessageLookupByLibrary.simpleMessage("マジック検索と顔認識のため、機械学習を有効にする"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("マップを有効にする"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "世界地図上にあなたの写真を表示します。\n\n地図はOpenStreetMapを利用しており、あなたの写真の位置情報が外部に共有されることはありません。\n\nこの機能は設定から無効にすることができます"),
        "enabled": MessageLookupByLibrary.simpleMessage("有効"),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("バックアップを暗号化中..."),
        "encryption": MessageLookupByLibrary.simpleMessage("暗号化"),
        "encryptionKeys": MessageLookupByLibrary.simpleMessage("暗号化の鍵"),
        "endpointUpdatedMessage":
            MessageLookupByLibrary.simpleMessage("エンドポイントの更新に成功しました"),
        "endtoendEncryptedByDefault":
            MessageLookupByLibrary.simpleMessage("デフォルトで端末間で暗号化されています"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "大切に保管します、Enteにファイルへのアクセスを許可してください"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "写真を大切にバックアップするために<i>許可が必要</i>です"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Enteはあなたの思い出を保存します。デバイスを紛失しても、オンラインでアクセス可能です"),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "あなたの家族もあなたの有料プランに参加することができます。"),
        "enterAlbumName": MessageLookupByLibrary.simpleMessage("アルバム名を入力"),
        "enterCode": MessageLookupByLibrary.simpleMessage("コードを入力"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "もらったコードを入力して、無料のストレージを入手してください"),
        "enterDateOfBirth": MessageLookupByLibrary.simpleMessage("誕生日（任意）"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Eメールアドレスを入力してください"),
        "enterFileName": MessageLookupByLibrary.simpleMessage("ファイル名を入力してください"),
        "enterName": MessageLookupByLibrary.simpleMessage("名前を入力"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "あなたのデータを暗号化するための新しいパスワードを入力してください"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("パスワードを入力"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "あなたのデータを暗号化するためのパスワードを入力してください"),
        "enterPersonName": MessageLookupByLibrary.simpleMessage("人名を入力してください"),
        "enterPin": MessageLookupByLibrary.simpleMessage("PINを入力してください"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("紹介コードを入力してください"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "認証アプリに表示された 6 桁のコードを入力してください"),
        "enterValidEmail":
            MessageLookupByLibrary.simpleMessage("有効なEメールアドレスを入力してください"),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Eメールアドレスを入力"),
        "enterYourPassword": MessageLookupByLibrary.simpleMessage("パスワードを入力"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("リカバリーキーを入力してください"),
        "error": MessageLookupByLibrary.simpleMessage("エラー"),
        "everywhere": MessageLookupByLibrary.simpleMessage("どこでも"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser": MessageLookupByLibrary.simpleMessage("既存のユーザー"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "このリンクは期限切れです。新たな期限を設定するか、期限設定そのものを無くすか、選択してください"),
        "exportLogs": MessageLookupByLibrary.simpleMessage("ログのエクスポート"),
        "exportYourData": MessageLookupByLibrary.simpleMessage("データをエクスポート"),
        "extraPhotosFound":
            MessageLookupByLibrary.simpleMessage("追加の写真が見つかりました"),
        "extraPhotosFoundFor": m33,
        "faceNotClusteredYet":
            MessageLookupByLibrary.simpleMessage("顔がまだ集まっていません。後で戻ってきてください"),
        "faceRecognition": MessageLookupByLibrary.simpleMessage("顔認識"),
        "faces": MessageLookupByLibrary.simpleMessage("顔"),
        "failed": MessageLookupByLibrary.simpleMessage("失敗"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("コードを適用できませんでした"),
        "failedToCancel": MessageLookupByLibrary.simpleMessage("キャンセルに失敗しました"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("ビデオをダウンロードできませんでした"),
        "failedToFetchActiveSessions":
            MessageLookupByLibrary.simpleMessage("アクティブなセッションの取得に失敗しました"),
        "failedToFetchOriginalForEdit":
            MessageLookupByLibrary.simpleMessage("編集前の状態の取得に失敗しました"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "紹介の詳細を取得できません。後でもう一度お試しください。"),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("アルバムの読み込みに失敗しました"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("動画の再生に失敗しました"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage("サブスクリプションの更新に失敗しました"),
        "failedToRenew": MessageLookupByLibrary.simpleMessage("更新に失敗しました"),
        "failedToVerifyPaymentStatus":
            MessageLookupByLibrary.simpleMessage("支払ステータスの確認に失敗しました"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "5人までの家族をファミリープランに追加しましょう(追加料金無し)\n\n一人ひとりがプライベートなストレージを持ち、共有されない限りお互いに見ることはありません。\n\nファミリープランはEnteサブスクリプションに登録した人が利用できます。\n\nさっそく登録しましょう！"),
        "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("ファミリー"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("ファミリープラン"),
        "faq": MessageLookupByLibrary.simpleMessage("よくある質問"),
        "faqs": MessageLookupByLibrary.simpleMessage("よくある質問"),
        "favorite": MessageLookupByLibrary.simpleMessage("お気に入り"),
        "feastingWithThem": m34,
        "feedback": MessageLookupByLibrary.simpleMessage("フィードバック"),
        "file": MessageLookupByLibrary.simpleMessage("ファイル"),
        "fileFailedToSaveToGallery":
            MessageLookupByLibrary.simpleMessage("ギャラリーへの保存に失敗しました"),
        "fileInfoAddDescHint": MessageLookupByLibrary.simpleMessage("説明を追加..."),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("ファイルがまだアップロードされていません"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("ファイルをギャラリーに保存しました"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("ファイルの種類"),
        "fileTypesAndNames": MessageLookupByLibrary.simpleMessage("ファイルの種類と名前"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("削除されたファイル"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("写真をダウンロードしました"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage("名前で人を探す"),
        "findThemQuickly": MessageLookupByLibrary.simpleMessage("すばやく見つける"),
        "flip": MessageLookupByLibrary.simpleMessage("反転"),
        "food": MessageLookupByLibrary.simpleMessage("料理を楽しむ"),
        "forYourMemories": MessageLookupByLibrary.simpleMessage("思い出の為に"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage("パスワードを忘れた"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("見つかった顔"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage("空き容量を受け取る"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("無料のストレージが利用可能です"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("無料トライアル"),
        "freeTrialValidTill": m38,
        "freeUpAmount": m40,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("デバイスの空き領域を解放する"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "すでにバックアップされているファイルを消去して、デバイスの容量を空けます。"),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("スペースを解放する"),
        "gallery": MessageLookupByLibrary.simpleMessage("ギャラリー"),
        "galleryMemoryLimitInfo":
            MessageLookupByLibrary.simpleMessage("ギャラリーに表示されるメモリは最大1000個までです"),
        "general": MessageLookupByLibrary.simpleMessage("設定"),
        "generatingEncryptionKeys":
            MessageLookupByLibrary.simpleMessage("暗号化鍵を生成しています"),
        "genericProgress": m42,
        "goToSettings": MessageLookupByLibrary.simpleMessage("設定に移動"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "設定アプリで、すべての写真へのアクセスを許可してください"),
        "grantPermission": MessageLookupByLibrary.simpleMessage("許可する"),
        "greenery": MessageLookupByLibrary.simpleMessage("緑の生活"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("近くの写真をグループ化"),
        "guestView": MessageLookupByLibrary.simpleMessage("ゲストビュー"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "アプリのロックを有効にするには、システム設定でデバイスのパスコードまたは画面ロックを設定してください。"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "私たちはアプリのインストールを追跡していませんが、もしよければ、Enteをお知りになった場所を教えてください！"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Ente についてどのようにお聞きになりましたか？（任意）"),
        "help": MessageLookupByLibrary.simpleMessage("ヘルプ"),
        "hidden": MessageLookupByLibrary.simpleMessage("非表示"),
        "hide": MessageLookupByLibrary.simpleMessage("非表示"),
        "hideContent": MessageLookupByLibrary.simpleMessage("内容を非表示"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "アプリ画面を非表示にし、スクリーンショットを無効にします"),
        "hideContentDescriptionIos":
            MessageLookupByLibrary.simpleMessage("アプリ切り替え時に、アプリの画面を非表示にします"),
        "hideSharedItemsFromHomeGallery":
            MessageLookupByLibrary.simpleMessage("ホームギャラリーから共有された写真等を非表示"),
        "hiding": MessageLookupByLibrary.simpleMessage("非表示にしています"),
        "hikingWithThem": m43,
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("OSM Franceでホスト"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("仕組みを知る"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "設定画面でメールアドレスを長押しし、両デバイスのIDが一致していることを確認してください。"),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "生体認証がデバイスで設定されていません。Touch ID もしくは Face ID を有効にしてください。"),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "生体認証が無効化されています。画面をロック・ロック解除して生体認証を有効化してください。"),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("無視する"),
        "ignored": MessageLookupByLibrary.simpleMessage("無視された"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "このアルバムの一部のファイルは、以前にEnteから削除されたため、あえてアップロード時に無視されます"),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("画像が分析されていません"),
        "immediately": MessageLookupByLibrary.simpleMessage("すぐに"),
        "importing": MessageLookupByLibrary.simpleMessage("インポート中..."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("誤ったコード"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("パスワードが間違っています"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("リカバリーキーが正しくありません"),
        "incorrectRecoveryKeyBody":
            MessageLookupByLibrary.simpleMessage("リカバリーキーが間違っています"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("リカバリーキーの誤り"),
        "indexedItems": MessageLookupByLibrary.simpleMessage("処理済みの項目"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "インデックス作成は一時停止されています。デバイスの準備ができたら自動的に再開します。"),
        "ineligible": MessageLookupByLibrary.simpleMessage("対象外"),
        "info": MessageLookupByLibrary.simpleMessage("情報"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage("安全でないデバイス"),
        "installManually": MessageLookupByLibrary.simpleMessage("手動でインストール"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("無効なEメールアドレス"),
        "invalidEndpoint": MessageLookupByLibrary.simpleMessage("無効なエンドポイントです"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "入力されたエンドポイントは無効です。有効なエンドポイントを入力して再試行してください。"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("無効なキー"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "入力されたリカバリーキーが無効です。24 単語が含まれていることを確認し、それぞれのスペルを確認してください。\n\n古い形式のリカバリーコードを入力した場合は、64 文字であることを確認して、それぞれを確認してください。"),
        "invite": MessageLookupByLibrary.simpleMessage("招待"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Enteに招待する"),
        "inviteYourFriends": MessageLookupByLibrary.simpleMessage("友達を招待"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("友達をEnteに招待する"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "問題が発生したようです。しばらくしてから再試行してください。エラーが解決しない場合は、サポートチームにお問い合わせください。"),
        "itemCount": m44,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage("完全に削除されるまでの日数が項目に表示されます"),
        "itemsWillBeRemovedFromAlbum":
            MessageLookupByLibrary.simpleMessage("選択したアイテムはこのアルバムから削除されます"),
        "join": MessageLookupByLibrary.simpleMessage("参加する"),
        "joinAlbum": MessageLookupByLibrary.simpleMessage("アルバムに参加"),
        "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
            "アルバムに参加すると、参加者にメールアドレスが公開されます。"),
        "joinAlbumSubtext":
            MessageLookupByLibrary.simpleMessage("写真を表示したり、追加したりするために"),
        "joinAlbumSubtextViewer":
            MessageLookupByLibrary.simpleMessage("これを共有アルバムに追加するために"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("Discordに参加"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("写真を残す"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation":
            MessageLookupByLibrary.simpleMessage("よければ、情報をお寄せください"),
        "language": MessageLookupByLibrary.simpleMessage("言語"),
        "lastTimeWithThem": m45,
        "lastUpdated": MessageLookupByLibrary.simpleMessage("更新された順"),
        "lastYearsTrip": MessageLookupByLibrary.simpleMessage("昨年の旅行"),
        "leave": MessageLookupByLibrary.simpleMessage("離脱"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("アルバムを抜ける"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("ファミリープランから退会"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("共有アルバムを抜けてよいですか？"),
        "left": MessageLookupByLibrary.simpleMessage("左"),
        "legacy": MessageLookupByLibrary.simpleMessage("レガシー"),
        "legacyAccounts": MessageLookupByLibrary.simpleMessage("レガシーアカウント"),
        "legacyInvite": m46,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "レガシーでは、信頼できる連絡先が不在時(あなたが亡くなった時など)にアカウントにアクセスできます。"),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "信頼できる連絡先はアカウントの回復を開始することができます。30日以内にあなたが拒否しない場合は、その信頼する人がパスワードをリセットしてあなたのアカウントにアクセスできるようになります。"),
        "light": MessageLookupByLibrary.simpleMessage("ライト"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("ライト"),
        "link": MessageLookupByLibrary.simpleMessage("リンク"),
        "linkCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("リンクをクリップボードにコピーしました"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("デバイスの制限"),
        "linkEmail": MessageLookupByLibrary.simpleMessage("メールアドレスをリンクする"),
        "linkEmailToContactBannerCaption":
            MessageLookupByLibrary.simpleMessage("共有を高速化するために"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("有効"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("期限切れ"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("リンクの期限切れ"),
        "linkHasExpired": MessageLookupByLibrary.simpleMessage("リンクは期限切れです"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("なし"),
        "linkPerson": MessageLookupByLibrary.simpleMessage("人を紐づけ"),
        "linkPersonCaption":
            MessageLookupByLibrary.simpleMessage("良い経験を分かち合うために"),
        "linkPersonToEmail": m48,
        "linkPersonToEmailConfirmation": m49,
        "livePhotos": MessageLookupByLibrary.simpleMessage("ライブフォト"),
        "loadMessage1":
            MessageLookupByLibrary.simpleMessage("サブスクリプションを家族と共有できます"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "私たちはあなたのデータのコピーを3つ保管しています。1つは地下のシェルターにあります。"),
        "loadMessage4":
            MessageLookupByLibrary.simpleMessage("すべてのアプリはオープンソースです"),
        "loadMessage5":
            MessageLookupByLibrary.simpleMessage("当社のソースコードと暗号方式は外部から監査されています"),
        "loadMessage6":
            MessageLookupByLibrary.simpleMessage("アルバムへのリンクを共有できます"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "当社のモバイルアプリはバックグラウンドで実行され、新しい写真を暗号化してバックアップします"),
        "loadMessage8":
            MessageLookupByLibrary.simpleMessage("web.ente.ioにはアップローダーがあります"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Xchacha20Poly1305を使用してデータを安全に暗号化します。"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("EXIF データを読み込み中..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("ギャラリーを読み込み中..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("あなたの写真を読み込み中..."),
        "loadingModel": MessageLookupByLibrary.simpleMessage("モデルをダウンロード中"),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("写真を読み込んでいます..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("デバイス上のギャラリー"),
        "localIndexing": MessageLookupByLibrary.simpleMessage("このデバイス上での実行"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "ローカルの写真の同期には予想以上の時間がかかっています。問題が発生したようです。サポートチームまでご連絡ください。"),
        "location": MessageLookupByLibrary.simpleMessage("場所"),
        "locationName": MessageLookupByLibrary.simpleMessage("場所名"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "位置タグは、写真の半径内で撮影されたすべての写真をグループ化します"),
        "locations": MessageLookupByLibrary.simpleMessage("場所"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("ロック"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("画面のロック"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("ログイン"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("ログアウト中..."),
        "loginSessionExpired": MessageLookupByLibrary.simpleMessage("セッション切れ"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "セッションの有効期限が切れました。再度ログインしてください。"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "「ログイン」をクリックすることで、<u-terms>利用規約</u-terms>と<u-policy>プライバシーポリシー</u-policy>に同意します"),
        "loginWithTOTP": MessageLookupByLibrary.simpleMessage("TOTPでログイン"),
        "logout": MessageLookupByLibrary.simpleMessage("ログアウト"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "これにより、問題のデバッグに役立つログが送信されます。 特定のファイルの問題を追跡するために、ファイル名が含まれることに注意してください。"),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "表示されているEメールアドレスを長押しして、暗号化を確認します。"),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage("アイテムを長押しして全画面表示する"),
        "loopVideoOff": MessageLookupByLibrary.simpleMessage("ビデオのループをオフ"),
        "loopVideoOn": MessageLookupByLibrary.simpleMessage("ビデオのループをオン"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("デバイスを紛失しましたか？"),
        "machineLearning": MessageLookupByLibrary.simpleMessage("機械学習"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("マジックサーチ"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "マジック検索では、「花」、「赤い車」、「本人確認書類」などの写真に写っているもので検索できます。"),
        "manage": MessageLookupByLibrary.simpleMessage("管理"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("端末のキャッシュを管理"),
        "manageDeviceStorageDesc":
            MessageLookupByLibrary.simpleMessage("端末上のキャッシュを確認・削除"),
        "manageFamily": MessageLookupByLibrary.simpleMessage("ファミリーの管理"),
        "manageLink": MessageLookupByLibrary.simpleMessage("リンクを管理"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("管理"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("サブスクリプションの管理"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "PINを使ってペアリングすると、どんなスクリーンで動作します。"),
        "map": MessageLookupByLibrary.simpleMessage("地図"),
        "maps": MessageLookupByLibrary.simpleMessage("地図"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "me": MessageLookupByLibrary.simpleMessage("自分"),
        "merchandise": MessageLookupByLibrary.simpleMessage("グッズ"),
        "mergeWithExisting": MessageLookupByLibrary.simpleMessage("既存の人物とまとめる"),
        "mergedPhotos": MessageLookupByLibrary.simpleMessage("統合された写真"),
        "mlConsent": MessageLookupByLibrary.simpleMessage("機械学習を有効にする"),
        "mlConsentConfirmation":
            MessageLookupByLibrary.simpleMessage("機械学習を可能にしたい"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "機械学習を有効にすると、Enteは顔などの情報をファイルから抽出します。\n\nこれはお使いのデバイスで行われ、生成された生体情報は暗号化されます。"),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "この機能の詳細については、こちらをクリックしてください。"),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage("機械学習を有効にしますか？"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "すべての項目が処理されるまで、機械学習は帯域幅とバッテリー使用量が高くなりますのでご注意ください。 処理を高速で終わらせたい場合はデスクトップアプリを使用するのがおすすめです。結果は自動的に同期されます。"),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("モバイル、Web、デスクトップ"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("普通のパスワード"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage("クエリを変更するか、以下のように検索してみてください"),
        "moments": MessageLookupByLibrary.simpleMessage("日々の瞬間"),
        "month": MessageLookupByLibrary.simpleMessage("月"),
        "monthly": MessageLookupByLibrary.simpleMessage("月額"),
        "moon": MessageLookupByLibrary.simpleMessage("月明かりの中"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("さらに詳細を表示"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("新しい順"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("関連度順"),
        "mountains": MessageLookupByLibrary.simpleMessage("丘を超えて"),
        "moveSelectedPhotosToOneDate":
            MessageLookupByLibrary.simpleMessage("選択した写真を1つの日付に移動"),
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("アルバムに移動"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage("隠しアルバムに移動"),
        "movedSuccessfullyTo": m52,
        "movedToTrash": MessageLookupByLibrary.simpleMessage("ごみ箱へ移動"),
        "movingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("アルバムにファイルを移動中"),
        "name": MessageLookupByLibrary.simpleMessage("名前順"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("アルバムに名前を付けよう"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Enteに接続できませんでした。しばらくしてから再試行してください。エラーが解決しない場合は、サポートにお問い合わせください。"),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Enteに接続できませんでした。ネットワーク設定を確認し、エラーが解決しない場合はサポートにお問い合わせください。"),
        "never": MessageLookupByLibrary.simpleMessage("なし"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("新しいアルバム"),
        "newLocation": MessageLookupByLibrary.simpleMessage("新しいロケーション"),
        "newPerson": MessageLookupByLibrary.simpleMessage("新しい人物"),
        "newRange": MessageLookupByLibrary.simpleMessage("範囲を追加"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Enteを初めて使用する"),
        "newest": MessageLookupByLibrary.simpleMessage("新しい順"),
        "next": MessageLookupByLibrary.simpleMessage("次へ"),
        "no": MessageLookupByLibrary.simpleMessage("いいえ"),
        "noAlbumsSharedByYouYet":
            MessageLookupByLibrary.simpleMessage("あなたが共有したアルバムはまだありません"),
        "noDeviceFound": MessageLookupByLibrary.simpleMessage("デバイスが見つかりません"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("なし"),
        "noDeviceThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage("削除できるファイルがありません"),
        "noDuplicates": MessageLookupByLibrary.simpleMessage("✨ 重複なし"),
        "noEnteAccountExclamation":
            MessageLookupByLibrary.simpleMessage("アカウントがありません！"),
        "noExifData": MessageLookupByLibrary.simpleMessage("EXIFデータはありません"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage("顔が見つかりません"),
        "noHiddenPhotosOrVideos":
            MessageLookupByLibrary.simpleMessage("非表示の写真やビデオはありません"),
        "noImagesWithLocation":
            MessageLookupByLibrary.simpleMessage("位置情報のある画像がありません"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("インターネット接続なし"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage("現在バックアップされている写真はありません"),
        "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage("写真が見つかりません"),
        "noQuickLinksSelected":
            MessageLookupByLibrary.simpleMessage("クイックリンクが選択されていません"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage("リカバリーキーがないですか？"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "あなたのデータはエンドツーエンド暗号化されており、パスワードかリカバリーキーがない場合、データを復号することはできません"),
        "noResults": MessageLookupByLibrary.simpleMessage("該当なし"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("一致する結果が見つかりませんでした"),
        "noSuggestionsForPerson": m53,
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("システムロックが見つかりませんでした"),
        "notPersonLabel": m54,
        "notThisPerson": MessageLookupByLibrary.simpleMessage("この人ではありませんか？"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("あなたに共有されたものはありません"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("ここに表示されるものはありません！ 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("通知"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "onDevice": MessageLookupByLibrary.simpleMessage("デバイス上"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "<branding>Ente</branding>が保管"),
        "onTheRoad": MessageLookupByLibrary.simpleMessage("再び道で"),
        "onlyFamilyAdminCanChangeCode": m55,
        "onlyThem": MessageLookupByLibrary.simpleMessage("この人のみ"),
        "oops": MessageLookupByLibrary.simpleMessage("Oops"),
        "oopsCouldNotSaveEdits":
            MessageLookupByLibrary.simpleMessage("編集を保存できませんでした"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("問題が発生しました"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("ブラウザでアルバムを開く"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "このアルバムに写真を追加するには、Webアプリを使用してください"),
        "openFile": MessageLookupByLibrary.simpleMessage("ファイルを開く"),
        "openSettings": MessageLookupByLibrary.simpleMessage("設定を開く"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• アイテムを開く"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("OpenStreetMap のコントリビューター"),
        "optionalAsShortAsYouLike":
            MessageLookupByLibrary.simpleMessage("省略可能、好きなだけお書きください..."),
        "orMergeWithExistingPerson":
            MessageLookupByLibrary.simpleMessage("既存のものと統合する"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("または既存のものを選択"),
        "orPickFromYourContacts":
            MessageLookupByLibrary.simpleMessage("または連絡先から選択"),
        "pair": MessageLookupByLibrary.simpleMessage("ペアリング"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("PINを使ってペアリングする"),
        "pairingComplete": MessageLookupByLibrary.simpleMessage("ペアリング完了"),
        "panorama": MessageLookupByLibrary.simpleMessage("パノラマ"),
        "partyWithThem": m56,
        "passKeyPendingVerification":
            MessageLookupByLibrary.simpleMessage("検証はまだ保留中です"),
        "passkey": MessageLookupByLibrary.simpleMessage("パスキー"),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage("パスキーの検証"),
        "password": MessageLookupByLibrary.simpleMessage("パスワード"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("パスワードの変更に成功しました"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("パスワード保護"),
        "passwordStrength": m57,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "パスワードの長さ、使用される文字の種類を考慮してパスワードの強度は計算されます。"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "このパスワードを忘れると、<underline>あなたのデータを復号することは私達にもできません</underline>"),
        "paymentDetails": MessageLookupByLibrary.simpleMessage("お支払い情報"),
        "paymentFailed": MessageLookupByLibrary.simpleMessage("支払いに失敗しました"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "残念ながらお支払いに失敗しました。サポートにお問い合わせください。お手伝いします！"),
        "paymentFailedTalkToProvider": m58,
        "pendingItems": MessageLookupByLibrary.simpleMessage("処理待ちの項目"),
        "pendingSync": MessageLookupByLibrary.simpleMessage("同期を保留中"),
        "people": MessageLookupByLibrary.simpleMessage("人物"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("あなたのコードを使っている人"),
        "permDeleteWarning":
            MessageLookupByLibrary.simpleMessage("ゴミ箱を空にしました\n\nこの操作はもとに戻せません"),
        "permanentlyDelete": MessageLookupByLibrary.simpleMessage("完全に削除"),
        "permanentlyDeleteFromDevice":
            MessageLookupByLibrary.simpleMessage("デバイスから完全に削除しますか？"),
        "personIsAge": m59,
        "personName": MessageLookupByLibrary.simpleMessage("人名名"),
        "personTurningAge": m60,
        "pets": MessageLookupByLibrary.simpleMessage("毛むくじゃらな仲間たち"),
        "photoDescriptions": MessageLookupByLibrary.simpleMessage("写真の説明"),
        "photoGridSize": MessageLookupByLibrary.simpleMessage("写真のグリッドサイズ"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("写真"),
        "photocountPhotos": m61,
        "photos": MessageLookupByLibrary.simpleMessage("写真"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage("あなたの追加した写真はこのアルバムから削除されます"),
        "photosKeepRelativeTimeDifference":
            MessageLookupByLibrary.simpleMessage("写真はお互いの相対的な時間差を維持します"),
        "pickCenterPoint": MessageLookupByLibrary.simpleMessage("中心点を選択"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("アルバムをピンする"),
        "pinLock": MessageLookupByLibrary.simpleMessage("PINロック"),
        "playOnTv": MessageLookupByLibrary.simpleMessage("TVでアルバムを再生"),
        "playOriginal": MessageLookupByLibrary.simpleMessage("元動画を再生"),
        "playStoreFreeTrialValidTill": m63,
        "playStream": MessageLookupByLibrary.simpleMessage("再生"),
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("PlayStoreサブスクリプション"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage("インターネット接続を確認して、再試行してください。"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Support@ente.ioにお問い合わせください、お手伝いいたします。"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage("問題が解決しない場合はサポートにお問い合わせください"),
        "pleaseEmailUsAt": m64,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("権限を付与してください"),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage("もう一度試してください"),
        "pleaseSelectQuickLinksToRemove":
            MessageLookupByLibrary.simpleMessage("削除するクイックリンクを選択してください"),
        "pleaseSendTheLogsTo": m65,
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage("もう一度試してください"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage("入力したコードを確認してください"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("お待ち下さい"),
        "pleaseWaitDeletingAlbum":
            MessageLookupByLibrary.simpleMessage("お待ちください、アルバムを削除しています"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage("再試行する前にしばらくお待ちください"),
        "pleaseWaitThisWillTakeAWhile":
            MessageLookupByLibrary.simpleMessage("しばらくお待ちください。時間がかかります。"),
        "posingWithThem": m66,
        "preparingLogs": MessageLookupByLibrary.simpleMessage("ログを準備中..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("もっと保存する"),
        "pressAndHoldToPlayVideo":
            MessageLookupByLibrary.simpleMessage("長押しで動画を再生"),
        "pressAndHoldToPlayVideoDetailed":
            MessageLookupByLibrary.simpleMessage("画像の長押しで動画を再生"),
        "previous": MessageLookupByLibrary.simpleMessage("前"),
        "privacy": MessageLookupByLibrary.simpleMessage("プライバシー"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("プライバシーポリシー"),
        "privateBackups": MessageLookupByLibrary.simpleMessage("プライベートバックアップ"),
        "privateSharing": MessageLookupByLibrary.simpleMessage("プライベート共有"),
        "proceed": MessageLookupByLibrary.simpleMessage("続行"),
        "processed": MessageLookupByLibrary.simpleMessage("処理完了"),
        "processing": MessageLookupByLibrary.simpleMessage("処理中"),
        "processingImport": m67,
        "processingVideos": MessageLookupByLibrary.simpleMessage("動画を処理中"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("公開リンクが作成されました"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("公開リンクを有効にしました"),
        "queued": MessageLookupByLibrary.simpleMessage("処理待ち"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("クイックリンク"),
        "radius": MessageLookupByLibrary.simpleMessage("半径"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("サポートを受ける"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("アプリを評価"),
        "rateUs": MessageLookupByLibrary.simpleMessage("評価して下さい"),
        "rateUsOnStore": m68,
        "reassignMe": MessageLookupByLibrary.simpleMessage("\"自分\" を再割り当て"),
        "reassignedToName": m69,
        "reassigningLoading": MessageLookupByLibrary.simpleMessage("再割り当て中..."),
        "recover": MessageLookupByLibrary.simpleMessage("復元"),
        "recoverAccount": MessageLookupByLibrary.simpleMessage("アカウントを復元"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("復元"),
        "recoveryAccount": MessageLookupByLibrary.simpleMessage("アカウントを復元"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("リカバリが開始されました"),
        "recoveryInitiatedDesc": m70,
        "recoveryKey": MessageLookupByLibrary.simpleMessage("リカバリーキー"),
        "recoveryKeyCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("リカバリーキーはクリップボードにコピーされました"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "パスワードを忘れてしまったら、このリカバリーキーがあなたのデータを復元する唯一の方法です。"),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "リカバリーキーは私達も保管しません。この24個の単語を安全な場所に保管してください。"),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "リカバリーキーは有効です。ご確認いただきありがとうございます。\n\nリカバリーキーは今後も安全にバックアップしておいてください。"),
        "recoveryKeyVerified":
            MessageLookupByLibrary.simpleMessage("リカバリキーが確認されました"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "パスワードを忘れた場合、リカバリーキーは写真を復元するための唯一の方法になります。なお、設定 > アカウント でリカバリーキーを確認することができます。\n \n\nここにリカバリーキーを入力して、正しく保存できていることを確認してください。"),
        "recoveryReady": m71,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("復元に成功しました！"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "信頼する連絡先の持ち主があなたのアカウントにアクセスしようとしています"),
        "recoveryWarningBody": m72,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "このデバイスではパスワードを確認する能力が足りません。\n\n恐れ入りますが、リカバリーキーを入力してパスワードを再生成する必要があります。"),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("パスワードを再生成"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("パスワードを再入力してください"),
        "reenterPin": MessageLookupByLibrary.simpleMessage("PINを再入力してください"),
        "referFriendsAnd2xYourPlan":
            MessageLookupByLibrary.simpleMessage("友達に紹介して2倍"),
        "referralStep1":
            MessageLookupByLibrary.simpleMessage("1. このコードを友達に贈りましょう"),
        "referralStep2": MessageLookupByLibrary.simpleMessage("2. 友達が有料プランに登録"),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("リフェラル"),
        "referralsAreCurrentlyPaused":
            MessageLookupByLibrary.simpleMessage("リフェラルは現在一時停止しています"),
        "rejectRecovery": MessageLookupByLibrary.simpleMessage("リカバリを拒否する"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "また、空き領域を取得するには、「設定」→「ストレージ」から「最近削除した項目」を空にします"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "「ゴミ箱」も空にするとアカウントのストレージが解放されます"),
        "remoteImages": MessageLookupByLibrary.simpleMessage("デバイス上にない画像"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("リモートのサムネイル画像"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("デバイス上にない動画"),
        "remove": MessageLookupByLibrary.simpleMessage("削除"),
        "removeDuplicates": MessageLookupByLibrary.simpleMessage("重複した項目を削除"),
        "removeDuplicatesDesc":
            MessageLookupByLibrary.simpleMessage("完全に重複しているファイルを確認し、削除します。"),
        "removeFromAlbum": MessageLookupByLibrary.simpleMessage("アルバムから削除"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("アルバムから削除しますか？"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("お気に入りリストから外す"),
        "removeInvite": MessageLookupByLibrary.simpleMessage("招待を削除"),
        "removeLink": MessageLookupByLibrary.simpleMessage("リンクを削除"),
        "removeParticipant": MessageLookupByLibrary.simpleMessage("参加者を削除"),
        "removeParticipantBody": m74,
        "removePersonLabel": MessageLookupByLibrary.simpleMessage("人名を削除"),
        "removePublicLink": MessageLookupByLibrary.simpleMessage("公開リンクを削除"),
        "removePublicLinks": MessageLookupByLibrary.simpleMessage("公開リンクを削除"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "削除したアイテムのいくつかは他の人によって追加されました。あなたはそれらへのアクセスを失います"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("削除しますか?"),
        "removeYourselfAsTrustedContact":
            MessageLookupByLibrary.simpleMessage("あなた自身を信頼できる連絡先から削除"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("お気に入りから削除しています..."),
        "rename": MessageLookupByLibrary.simpleMessage("名前変更"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("アルバムの名前変更"),
        "renameFile": MessageLookupByLibrary.simpleMessage("ファイル名を変更"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("サブスクリプションの更新"),
        "renewsOn": m75,
        "reportABug": MessageLookupByLibrary.simpleMessage("バグを報告"),
        "reportBug": MessageLookupByLibrary.simpleMessage("バグを報告"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("メールを再送信"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("アップロード時に無視されるファイルをリセット"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("パスワードをリセット"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("削除"),
        "resetToDefault": MessageLookupByLibrary.simpleMessage("初期設定にリセット"),
        "restore": MessageLookupByLibrary.simpleMessage("復元"),
        "restoreToAlbum": MessageLookupByLibrary.simpleMessage("アルバムに戻す"),
        "restoringFiles": MessageLookupByLibrary.simpleMessage("ファイルを復元中..."),
        "resumableUploads": MessageLookupByLibrary.simpleMessage("再開可能なアップロード"),
        "retry": MessageLookupByLibrary.simpleMessage("リトライ"),
        "review": MessageLookupByLibrary.simpleMessage("確認"),
        "reviewDeduplicateItems":
            MessageLookupByLibrary.simpleMessage("重複だと思うファイルを確認して削除してください"),
        "reviewSuggestions": MessageLookupByLibrary.simpleMessage("提案を確認"),
        "right": MessageLookupByLibrary.simpleMessage("右"),
        "roadtripWithThem": m76,
        "rotate": MessageLookupByLibrary.simpleMessage("回転"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("左に回転"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("右に回転"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("保管されています"),
        "save": MessageLookupByLibrary.simpleMessage("保存"),
        "saveChangesBeforeLeavingQuestion":
            MessageLookupByLibrary.simpleMessage("その前に変更を保存しますか？"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("コラージュを保存"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("コピーを保存"),
        "saveKey": MessageLookupByLibrary.simpleMessage("キーを保存"),
        "savePerson": MessageLookupByLibrary.simpleMessage("人物を保存"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage("リカバリーキーを保存してください"),
        "saving": MessageLookupByLibrary.simpleMessage("保存中…"),
        "savingEdits": MessageLookupByLibrary.simpleMessage("編集を保存中..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("コードをスキャン"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage("認証アプリでQRコードをスキャンして下さい。"),
        "search": MessageLookupByLibrary.simpleMessage("検索"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("アルバム"),
        "searchByAlbumNameHint": MessageLookupByLibrary.simpleMessage("アルバム名"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• アルバム名 (e.g. \"Camera\")\n• ファイルの種類 (e.g. \"Videos\", \".gif\")\n• 年月日 (e.g. \"2022\", \"January\")\n• ホリデー (e.g. \"Christmas\")\n• 写真の説明文 (e.g. “#fun”)"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "写真情報に \"#trip\" のように説明を追加すれば、ここで簡単に見つけることができます"),
        "searchDatesEmptySection":
            MessageLookupByLibrary.simpleMessage("日付、月または年で検索"),
        "searchDiscoverEmptySection":
            MessageLookupByLibrary.simpleMessage("処理と同期が完了すると、画像がここに表示されます"),
        "searchFaceEmptySection":
            MessageLookupByLibrary.simpleMessage("学習が完了すると、ここに人が表示されます"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("ファイルの種類と名前"),
        "searchHint1": MessageLookupByLibrary.simpleMessage("デバイス上で高速検索"),
        "searchHint2": MessageLookupByLibrary.simpleMessage("写真の日付、説明"),
        "searchHint3": MessageLookupByLibrary.simpleMessage("アルバム、ファイル名、種類"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("場所"),
        "searchHint5":
            MessageLookupByLibrary.simpleMessage("近日公開: フェイスとマジック検索 ✨"),
        "searchLocationEmptySection":
            MessageLookupByLibrary.simpleMessage("当時の直近で撮影された写真をグループ化"),
        "searchPeopleEmptySection":
            MessageLookupByLibrary.simpleMessage("友達を招待すると、共有される写真はここから閲覧できます"),
        "searchPersonsEmptySection":
            MessageLookupByLibrary.simpleMessage("処理と同期が完了すると、ここに人々が表示されます"),
        "searchResultCount": m77,
        "searchSectionsLengthMismatch": m78,
        "security": MessageLookupByLibrary.simpleMessage("セキュリティ"),
        "seePublicAlbumLinksInApp":
            MessageLookupByLibrary.simpleMessage("アプリ内で公開アルバムのリンクを見る"),
        "selectALocation": MessageLookupByLibrary.simpleMessage("場所を選択"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("先に場所を選択してください"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("アルバムを選択"),
        "selectAll": MessageLookupByLibrary.simpleMessage("全て選択"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("すべて"),
        "selectCoverPhoto": MessageLookupByLibrary.simpleMessage("カバー写真を選択"),
        "selectDate": MessageLookupByLibrary.simpleMessage("日付を選択する"),
        "selectFoldersForBackup":
            MessageLookupByLibrary.simpleMessage("バックアップするフォルダを選択"),
        "selectItemsToAdd":
            MessageLookupByLibrary.simpleMessage("追加するアイテムを選んでください"),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("言語を選ぶ"),
        "selectMailApp": MessageLookupByLibrary.simpleMessage("メールアプリを選択"),
        "selectMorePhotos": MessageLookupByLibrary.simpleMessage("さらに写真を選択"),
        "selectOneDateAndTime":
            MessageLookupByLibrary.simpleMessage("日付と時刻を1つ選択してください"),
        "selectOneDateAndTimeForAll":
            MessageLookupByLibrary.simpleMessage("すべてに対して日付と時刻を1つ選択してください"),
        "selectPersonToLink": MessageLookupByLibrary.simpleMessage("リンクする人を選択"),
        "selectReason": MessageLookupByLibrary.simpleMessage(""),
        "selectStartOfRange":
            MessageLookupByLibrary.simpleMessage("範囲の開始位置を選択"),
        "selectTime": MessageLookupByLibrary.simpleMessage("時刻を選択"),
        "selectYourFace": MessageLookupByLibrary.simpleMessage("あなたの顔を選択"),
        "selectYourPlan": MessageLookupByLibrary.simpleMessage("プランを選びましょう"),
        "selectedFilesAreNotOnEnte":
            MessageLookupByLibrary.simpleMessage("選択したファイルはEnte上にありません"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage("選ばれたフォルダは暗号化されバックアップされます"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "選択したアイテムはすべてのアルバムから削除され、ゴミ箱に移動されます。"),
        "selectedItemsWillBeRemovedFromThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "選択したアイテムはこの人としての登録が解除されますが、ライブラリからは削除されません。"),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "selfiesWithThem": m82,
        "send": MessageLookupByLibrary.simpleMessage("送信"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("メールを送信する"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("招待を送る"),
        "sendLink": MessageLookupByLibrary.simpleMessage("リンクを送信"),
        "serverEndpoint": MessageLookupByLibrary.simpleMessage("サーバーエンドポイント"),
        "sessionExpired": MessageLookupByLibrary.simpleMessage("セッション切れ"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("セッションIDが一致しません"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("パスワードを設定"),
        "setAs": MessageLookupByLibrary.simpleMessage("設定："),
        "setCover": MessageLookupByLibrary.simpleMessage("カバー画像をセット"),
        "setLabel": MessageLookupByLibrary.simpleMessage("セット"),
        "setNewPassword": MessageLookupByLibrary.simpleMessage("新しいパスワードを設定"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("新しいPINを設定"),
        "setPasswordTitle": MessageLookupByLibrary.simpleMessage("パスワードを決定"),
        "setRadius": MessageLookupByLibrary.simpleMessage("半径の設定"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("セットアップ完了"),
        "share": MessageLookupByLibrary.simpleMessage("共有"),
        "shareALink": MessageLookupByLibrary.simpleMessage("リンクをシェアする"),
        "shareAlbumHint":
            MessageLookupByLibrary.simpleMessage("アルバムを開いて右上のシェアボタンをタップ"),
        "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage("アルバムを共有"),
        "shareLink": MessageLookupByLibrary.simpleMessage("リンクの共有"),
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant":
            MessageLookupByLibrary.simpleMessage("選んだ人と共有します"),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Enteをダウンロードして、写真や動画の共有を簡単に！\n\nhttps://ente.io"),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers":
            MessageLookupByLibrary.simpleMessage("Enteを使っていない人に共有"),
        "shareWithPeopleSectionTitle": m86,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("アルバムの共有をしてみましょう"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "無料プランのユーザーを含む、他のEnteユーザーと共有および共同アルバムを作成します。"),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("あなたが共有しました"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("あなたが共有しました"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("新しい共有写真"),
        "sharedPhotoNotificationsExplanation":
            MessageLookupByLibrary.simpleMessage("誰かが写真を共有アルバムに追加した時に通知を受け取る"),
        "sharedWith": m87,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("あなたと共有されたアルバム"),
        "sharedWithYou": MessageLookupByLibrary.simpleMessage("あなたと共有されています"),
        "sharing": MessageLookupByLibrary.simpleMessage("共有中..."),
        "shiftDatesAndTime": MessageLookupByLibrary.simpleMessage("日付と時間のシフト"),
        "showMemories": MessageLookupByLibrary.simpleMessage("思い出を表示"),
        "showPerson": MessageLookupByLibrary.simpleMessage("人物を表示"),
        "signOutFromOtherDevices":
            MessageLookupByLibrary.simpleMessage("他のデバイスからサインアウトする"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "他の誰かがあなたのパスワードを知っている可能性があると判断した場合は、あなたのアカウントを使用している他のすべてのデバイスから強制的にサインアウトできます。"),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("他のデバイスからサインアウトする"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "<u-terms>利用規約</u-terms>と<u-policy>プライバシーポリシー</u-policy>に同意します"),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight":
            MessageLookupByLibrary.simpleMessage("全てのアルバムから削除されます。"),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("スキップ"),
        "social": MessageLookupByLibrary.simpleMessage("SNS"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "いくつかの項目は、Enteとお使いのデバイス上の両方にあります。"),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "削除しようとしているファイルのいくつかは、お使いのデバイス上にのみあり、削除した場合は復元できません"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "アルバムを共有している人はデバイス上で同じIDを見るはずです。"),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("エラーが発生しました"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("問題が起きてしまいました、もう一度試してください"),
        "sorry": MessageLookupByLibrary.simpleMessage("すみません"),
        "sorryCouldNotAddToFavorites":
            MessageLookupByLibrary.simpleMessage("お気に入りに追加できませんでした。"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage("お気に入りから削除できませんでした"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage("入力されたコードは正しくありません"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "このデバイスでは安全な鍵を生成することができませんでした。\n\n他のデバイスからサインアップを試みてください。"),
        "sort": MessageLookupByLibrary.simpleMessage("並び替え"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("並び替え"),
        "sortNewestFirst": MessageLookupByLibrary.simpleMessage("新しい順"),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage("古い順"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("成功✨"),
        "sportsWithThem": m91,
        "spotlightOnThem": m92,
        "spotlightOnYourself":
            MessageLookupByLibrary.simpleMessage("あなた自身にスポットライト！"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("リカバリを開始"),
        "startBackup": MessageLookupByLibrary.simpleMessage("バックアップを開始"),
        "status": MessageLookupByLibrary.simpleMessage("ステータス"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage("キャストを停止しますか？"),
        "stopCastingTitle": MessageLookupByLibrary.simpleMessage("キャストを停止"),
        "storage": MessageLookupByLibrary.simpleMessage("ストレージ"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("ファミリー"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("あなた"),
        "storageInGB": m93,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("ストレージの上限を超えました"),
        "storageUsageInfo": m94,
        "streamDetails": MessageLookupByLibrary.simpleMessage("動画の詳細"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("強いパスワード"),
        "subAlreadyLinkedErrMessage": m95,
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("サブスクライブ"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "共有を有効にするには、有料サブスクリプションが必要です。"),
        "subscription": MessageLookupByLibrary.simpleMessage("サブスクリプション"),
        "success": MessageLookupByLibrary.simpleMessage("成功"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("アーカイブしました"),
        "successfullyHid": MessageLookupByLibrary.simpleMessage("非表示にしました"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("アーカイブを解除しました"),
        "successfullyUnhid": MessageLookupByLibrary.simpleMessage("非表示を解除しました"),
        "suggestFeatures": MessageLookupByLibrary.simpleMessage("機能を提案"),
        "sunrise": MessageLookupByLibrary.simpleMessage("水平線"),
        "support": MessageLookupByLibrary.simpleMessage("サポート"),
        "syncProgress": m97,
        "syncStopped": MessageLookupByLibrary.simpleMessage("同期が停止しました"),
        "syncing": MessageLookupByLibrary.simpleMessage("同期中..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("システム"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("タップしてコピー"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage("タップしてコードを入力"),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage("タップして解除"),
        "tapToUpload": MessageLookupByLibrary.simpleMessage("タップしてアップロード"),
        "tapToUploadIsIgnoredDue": m98,
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "問題が発生したようです。しばらくしてから再試行してください。エラーが解決しない場合は、サポートチームにお問い合わせください。"),
        "terminate": MessageLookupByLibrary.simpleMessage("終了させる"),
        "terminateSession": MessageLookupByLibrary.simpleMessage("セッションを終了"),
        "terms": MessageLookupByLibrary.simpleMessage("規約"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("規約"),
        "thankYou": MessageLookupByLibrary.simpleMessage("ありがとうございます"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("ありがとうございます！"),
        "theDownloadCouldNotBeCompleted":
            MessageLookupByLibrary.simpleMessage("ダウンロードを完了できませんでした"),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage("アクセスしようとしているリンクの期限が切れています。"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage("入力したリカバリーキーが間違っています"),
        "theme": MessageLookupByLibrary.simpleMessage("テーマ"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage("これらの項目はデバイスから削除されます。"),
        "theyAlsoGetXGb": m99,
        "theyWillBeDeletedFromAllAlbums":
            MessageLookupByLibrary.simpleMessage("全てのアルバムから削除されます。"),
        "thisActionCannotBeUndone":
            MessageLookupByLibrary.simpleMessage("この操作は元に戻せません"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "このアルバムはすでにコラボレーションリンクが生成されています"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "2段階認証を失った場合、アカウントを回復するために使用できます。"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("このデバイス"),
        "thisEmailIsAlreadyInUse":
            MessageLookupByLibrary.simpleMessage("このメールアドレスはすでに使用されています。"),
        "thisImageHasNoExifData":
            MessageLookupByLibrary.simpleMessage("この画像にEXIFデータはありません"),
        "thisIsMeExclamation": MessageLookupByLibrary.simpleMessage("これは私です"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("これはあなたの認証IDです"),
        "thisWeekThroughTheYears":
            MessageLookupByLibrary.simpleMessage("毎年のこの週"),
        "thisWeekXYearsAgo": m101,
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage("以下のデバイスからログアウトします:"),
        "thisWillLogYouOutOfThisDevice":
            MessageLookupByLibrary.simpleMessage("ログアウトします"),
        "thisWillMakeTheDateAndTimeOfAllSelected":
            MessageLookupByLibrary.simpleMessage("選択したすべての写真の日付と時刻が同じになります。"),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "選択したすべてのクイックリンクの公開リンクを削除します。"),
        "throughTheYears": m102,
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "アプリのロックを有効にするには、システム設定でデバイスのパスコードまたは画面ロックを設定してください。"),
        "toHideAPhotoOrVideo":
            MessageLookupByLibrary.simpleMessage("写真や動画を非表示にする"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "パスワードのリセットをするには、まずEメールを確認してください"),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("今日のログ"),
        "tooManyIncorrectAttempts":
            MessageLookupByLibrary.simpleMessage("間違った回数が多すぎます"),
        "total": MessageLookupByLibrary.simpleMessage("合計"),
        "totalSize": MessageLookupByLibrary.simpleMessage("合計サイズ"),
        "trash": MessageLookupByLibrary.simpleMessage("ゴミ箱"),
        "trashDaysLeft": m103,
        "trim": MessageLookupByLibrary.simpleMessage("トリミング"),
        "tripInYear": m104,
        "tripToLocation": m105,
        "trustedContacts": MessageLookupByLibrary.simpleMessage("信頼する連絡先"),
        "trustedInviteBody": m106,
        "tryAgain": MessageLookupByLibrary.simpleMessage("もう一度試してください"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "バックアップをオンにすると、このデバイスフォルダに追加されたファイルは自動的にEnteにアップロードされます。"),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans":
            MessageLookupByLibrary.simpleMessage("年次プランでは2ヶ月無料"),
        "twofactor": MessageLookupByLibrary.simpleMessage("二段階認証"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage("二段階認証が無効になりました。"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("2段階認証"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage("2段階認証をリセットしました"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage("2段階認証のセットアップ"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
        "unarchive": MessageLookupByLibrary.simpleMessage("アーカイブ解除"),
        "unarchiveAlbum": MessageLookupByLibrary.simpleMessage("アルバムのアーカイブ解除"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("アーカイブを解除中..."),
        "unavailableReferralCode":
            MessageLookupByLibrary.simpleMessage("このコードは利用できません"),
        "uncategorized": MessageLookupByLibrary.simpleMessage("カテゴリなし"),
        "unhide": MessageLookupByLibrary.simpleMessage("再表示"),
        "unhideToAlbum": MessageLookupByLibrary.simpleMessage("アルバムを再表示する"),
        "unhiding": MessageLookupByLibrary.simpleMessage("非表示を解除しています"),
        "unhidingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("アルバムにファイルを表示しない"),
        "unlock": MessageLookupByLibrary.simpleMessage("ロック解除"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("アルバムのピン留めを解除"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("すべての選択を解除"),
        "update": MessageLookupByLibrary.simpleMessage("アップデート"),
        "updateAvailable": MessageLookupByLibrary.simpleMessage("アップデートがあります"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("フォルダの選択を更新しています..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("アップグレード"),
        "uploadIsIgnoredDueToIgnorereason": m108,
        "uploadingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("アルバムにファイルをアップロード中"),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("1メモリを保存しています..."),
        "upto50OffUntil4thDec":
            MessageLookupByLibrary.simpleMessage("12月4日まで、最大50%オフ。"),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "使用可能なストレージは現在のプランによって制限されています。プランをアップグレードすると、あなたが手に入れたストレージが自動的に使用可能になります。"),
        "useAsCover": MessageLookupByLibrary.simpleMessage("カバー写真として使用"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "この動画の再生に問題がありますか？別のプレイヤーを試すには、ここを長押ししてください。"),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "公開リンクを使用する(Enteを利用しない人と共有できます)"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage("リカバリーキーを使用"),
        "useSelectedPhoto": MessageLookupByLibrary.simpleMessage("選択した写真を使用"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("使用済み領域"),
        "validTill": m110,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("確認に失敗しました、再試行してください"),
        "verificationId": MessageLookupByLibrary.simpleMessage("確認用ID"),
        "verify": MessageLookupByLibrary.simpleMessage("確認"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Eメールの確認"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("確認"),
        "verifyPasskey": MessageLookupByLibrary.simpleMessage("パスキーを確認"),
        "verifyPassword": MessageLookupByLibrary.simpleMessage("パスワードの確認"),
        "verifying": MessageLookupByLibrary.simpleMessage("確認中..."),
        "verifyingRecoveryKey":
            MessageLookupByLibrary.simpleMessage("リカバリキーを確認中..."),
        "videoInfo": MessageLookupByLibrary.simpleMessage("ビデオ情報"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("ビデオ"),
        "videos": MessageLookupByLibrary.simpleMessage("ビデオ"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("アクティブなセッションを表示"),
        "viewAddOnButton": MessageLookupByLibrary.simpleMessage("アドオンを表示"),
        "viewAll": MessageLookupByLibrary.simpleMessage("すべて表示"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("全ての EXIF データを表示"),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("大きなファイル"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "最も多くのストレージを消費しているファイルを表示します。"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("ログを表示"),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage("リカバリキーを表示"),
        "viewer": MessageLookupByLibrary.simpleMessage("ビューアー"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "サブスクリプションを管理するにはweb.ente.ioをご覧ください"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("確認を待っています..."),
        "waitingForWifi": MessageLookupByLibrary.simpleMessage("WiFi を待っています"),
        "warning": MessageLookupByLibrary.simpleMessage("警告"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("私たちはオープンソースです！"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "あなたが所有していない写真やアルバムの編集はサポートされていません"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("弱いパスワード"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("おかえりなさい！"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("最新情報"),
        "whyAddTrustContact":
            MessageLookupByLibrary.simpleMessage("信頼する連絡先は、データの復旧が必要な際に役立ちます。"),
        "wishThemAHappyBirthday": m115,
        "yearShort": MessageLookupByLibrary.simpleMessage("年"),
        "yearly": MessageLookupByLibrary.simpleMessage("年額"),
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("はい"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("ビューアーに変換する"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("はい、削除"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("はい、変更を破棄します。"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("はい、ログアウトします"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("削除"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("はい、更新する"),
        "yesResetPerson": MessageLookupByLibrary.simpleMessage("リセット"),
        "you": MessageLookupByLibrary.simpleMessage("あなた"),
        "youAndThem": m117,
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("ファミリープランに入会しています！"),
        "youAreOnTheLatestVersion":
            MessageLookupByLibrary.simpleMessage("あなたは最新バージョンを使用しています"),
        "youCanAtMaxDoubleYourStorage":
            MessageLookupByLibrary.simpleMessage("* 最大2倍のストレージまで"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage("作ったリンクは共有タブで管理できます"),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage("別の単語を検索してみてください。"),
        "youCannotDowngradeToThisPlan":
            MessageLookupByLibrary.simpleMessage("このプランにダウングレードはできません"),
        "youCannotShareWithYourself":
            MessageLookupByLibrary.simpleMessage("自分自身と共有することはできません"),
        "youDontHaveAnyArchivedItems":
            MessageLookupByLibrary.simpleMessage("アーカイブした項目はありません"),
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("アカウントは削除されました"),
        "yourMap": MessageLookupByLibrary.simpleMessage("あなたの地図"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage("プランはダウングレードされました"),
        "yourPlanWasSuccessfullyUpgraded":
            MessageLookupByLibrary.simpleMessage("プランはアップグレードされました"),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("決済に成功しました"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage("ストレージの詳細を取得できませんでした"),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("サブスクリプションの有効期限が終了しました"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage("サブスクリプションが更新されました"),
        "yourVerificationCodeHasExpired":
            MessageLookupByLibrary.simpleMessage("確認用コードが失効しました"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage("削除できる同一ファイルはありません"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage("このアルバムには消すファイルがありません"),
        "zoomOutToSeePhotos":
            MessageLookupByLibrary.simpleMessage("ズームアウトして写真を表示")
      };
}
