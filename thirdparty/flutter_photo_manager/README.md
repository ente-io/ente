# photo_manager

[![pub package](https://img.shields.io/pub/v/photo_manager.svg)](https://pub.dartlang.org/packages/photo_manager)
[![GitHub](https://img.shields.io/github/license/Caijinglong/flutter_photo_manager.svg)](https://github.com/Caijinglong/flutter_photo_manager)
[![GitHub stars](https://img.shields.io/github/stars/Caijinglong/flutter_photo_manager.svg?style=social&label=Stars)](https://github.com/Caijinglong/flutter_photo_manager)

A flutter api for photo, you can get image/video from ios or android.

一个提供相册 api 的插件, android ios 可用,没有 ui,以便于自定义自己的界面, 你可以通过提供的 api 来制作图片相关的 ui 或插件

## Other projects using this library

If you just need a picture selector, you can choose to use [photo](https://pub.dartlang.org/packages/photo) library , a multi image picker. All UI create by flutter.

| name                 | owner          | description                                                                                                                                       | pub                                                                                                                    | github                                                                                                                                                                  |
| :------------------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| photo                | Caijinglong    | A selector for multiple pictures / videos, The style is like the 6.0 version of wechat.                                                           | [![pub package](https://img.shields.io/pub/v/photo.svg)](https://pub.dev/packages/photo)                               | [![star](https://img.shields.io/github/stars/Caijinglong/flutter_photo?style=social)](https://github.com/fluttercandies/flutter_wechat_assets_picker)                   |
| wechat_assets_picker | fluttercandies | An assets picker in WeChat 7.x style, support multi assets picking.                                                                               | [![pub package](https://img.shields.io/pub/v/wechat_assets_picker.svg)](https://pub.dev/packages/wechat_assets_picker) | [![star](https://img.shields.io/github/stars/fluttercandies/flutter_wechat_assets_picker?style=social)](https://github.com/fluttercandies/flutter_wechat_assets_picker) |
| photo_widget         | fluttercandies | Not just selectors, but to provide each widget as a separate component, which is convenient for quickly combining and customizing your own style. | [![pub package](https://img.shields.io/pub/v/photo_widget.svg)](https://pub.dev/packages/photo_widget)                 | [![star](https://img.shields.io/github/stars/fluttercandies/photo_widget?style=social)](https://github.com/fluttercandies/photo_widget)                                 |

## Table of contents

- [photo_manager](#photo_manager)
  - [Other projects using this library](#other-projects-using-this-library)
  - [Table of contents](#table-of-contents)
  - [install](#install)
    - [Add to pubspec](#add-to-pubspec)
    - [import in dart code](#import-in-dart-code)
  - [Usage](#usage)
    - [Configure your flutter project to use the plugin](#configure-your-flutter-project-to-use-the-plugin)
    - [request permission](#request-permission)
      - [About `requestPermissionExtend`](#about-requestpermissionextend)
      - [Limit photos](#limit-photos)
    - [you get all of asset list (gallery)](#you-get-all-of-asset-list-gallery)
      - [FilterOption](#filteroption)
    - [Get asset list from `AssetPathEntity`](#get-asset-list-from-assetpathentity)
      - [paged](#paged)
      - [range](#range)
      - [Old version](#old-version)
    - [AssetEntity](#assetentity)
      - [location info of android Q](#location-info-of-android-q)
      - [Origin description](#origin-description)
      - [Create with id](#create-with-id)
    - [observer](#observer)
    - [Clear file cache](#clear-file-cache)
    - [Experimental](#experimental)
      - [Preload thumb](#preload-thumb)
      - [Delete item](#delete-item)
      - [Insert new item](#insert-new-item)
      - [Copy asset](#copy-asset)
        - [Only for iOS](#only-for-ios)
        - [Only for Android](#only-for-android)
  - [iOS config](#ios-config)
    - [iOS plist config](#ios-plist-config)
    - [enabling localized system albums names](#enabling-localized-system-albums-names)
    - [Cache problem of iOS](#cache-problem-of-ios)
  - [android config](#android-config)
    - [Cache problem of android](#cache-problem-of-android)
    - [about androidX](#about-androidx)
    - [Android Q (android10 , API 29)](#android-q-android10--api-29)
    - [Android R (android 11, API30)](#android-r-android-11-api30)
    - [glide](#glide)
    - [Remove Media Location permission](#remove-media-location-permission)
  - [common issues](#common-issues)
    - [ios build error](#ios-build-error)
  - [Some articles about to use this library](#some-articles-about-to-use-this-library)
  - [Migration Guide](#migration-guide)

## install

### Add to pubspec

the latest version is [![pub package](https://img.shields.io/pub/v/photo_manager.svg)](https://pub.dartlang.org/packages/photo_manager)

```yaml
dependencies:
  photo_manager: $latest_version
```

### import in dart code

```dart
import 'package:photo_manager/photo_manager.dart';
```

## Usage

### Configure your flutter project to use the plugin

Before using the plug-in, there are several points to note.
Please click the link below.

1. [Android](#android-config)
2. [iOS](#ios-config)

### request permission

You must get the user's permission on android/ios.

```dart
var result = await PhotoManager.requestPermissionExtend();
if (result.isAuth) {
    // success
} else {
    // fail
    /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
}
```

#### About `requestPermissionExtend`

In iOS14, Apple inclue "LimitedPhotos Library" to iOS.

We need use the `PhotoManager.requestPermissionExtend()` to request permission.

The method will return `PermissionState`. See it in [document of Apple](https://developer.apple.com/documentation/photokit/phauthorizationstatus?language=objc).

So, because of compatibility, Android also recommends using this method to request permission, use `state.isAuth`, use a to be equivalent to the previous method `requestPermission`.

#### Limit photos

Because apple inclue "LimitedPhotos Library" to iOS.

Let the user select the visible image for app again, we can use `PhotoManager.presentLimited()` to repick again.

The method is only valid when iOS14 and user authorization mode is `PermissionState.limited`, other platform will ignore.

### you get all of asset list (gallery)

```dart
List<AssetPathEntity> list = await PhotoManager.getAssetPathList();
```

| name         | description                        |
| ------------ | ---------------------------------- |
| hasAll       | Is there an album containing "all" |
| type         | image/video/all , default all.     |
| filterOption | See [FilterOption](#FilterOption). |

#### FilterOption

| name               | description                                                                                                                                                                               |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| needTitle          | The title attribute of the picture must be included in android (even if it is false), it is more performance-consuming in iOS, please consider whether you need it. The default is false. |
| sizeConstraint     | Constraints on resource size.                                                                                                                                                             |
| durationConstraint | Constraints of time, pictures will ignore this constraint.                                                                                                                                |
| createDateTimeCond | Create date filter                                                                                                                                                                        |
| updateDateTimeCond | Update date filter                                                                                                                                                                        |
| orders             | The sort option, use `addOrderOption`.                                                                                                                                                    |

Example see [filter_option_page.dart](https://github.com/CaiJingLong/flutter_photo_manager/blob/master/example/lib/page/filter_option_page.dart).

Most classes of FilterOption support `copyWith`.

### Get asset list from `AssetPathEntity`

#### paged

```dart
// page: The page number of the page, starting at 0.
// perPage: The number of pages per page.
final assetList = await path.getAssetListPaged(page, perPage);
```

The old version, it is not recommended for continued use, because there may be performance issues on some phones. Now the internal implementation of this method is also paged, but the paged count is assetCount of AssetPathEntity.

#### range

```dart
final assetList = await path.getAssetListRange(start: 0, end: 88); // use start and end to get asset.
// Example: 0~10 will return 10 assets. Special case: If there are only 5, return 5
```

#### Old version

```dart
AssetPathEntity data = list[0]; // 1st album in the list, typically the "Recent" or "All" album
List<AssetEntity> imageList = await data.assetList;
```

### AssetEntity

```dart
AssetEntity entity = imageList[0];

File file = await entity.file; // image file

Uint8List originBytes = await entity.originBytes; // image/video original file content,

Uint8List thumbBytes = await entity.thumbData; // thumb data ,you can use Image.memory(thumbBytes); size is 64px*64px;

Uint8List thumbDataWithSize = await entity.thumbDataWithSize(width,height); //Just like thumbnails, you can specify your own size. unit is px; format is optional support jpg and png.

AssetType type = entity.type; // the type of asset enum of other,image,video

Duration duration = entity.videoDuration; //if type is not video, then return null.

Size size = entity.size

int width = entity.width;

int height = entity.height;

DateTime createDt = entity.createDateTime;

DateTime modifiedDt = entity.modifiedDateTime;

/// Gps info of asset. If latitude and longitude is 0, it means that no positioning information was obtained.
/// This information is not necessarily available, because the photo source is not necessarily the camera.
/// Even the camera, due to privacy issues, this property must not be available on androidQ and above.
double latitude = entity.latitude;
double longitude = entiry.longitude;

Latlng latlng = await entity.latlngAsync(); // In androidQ or higher, need use the method to get location info.

String mediaUrl = await entity.getMediaUrl(); /// It can be used in some video player plugin to preview, such as [flutter_ijkplayer](https://pub.dev/packages/flutter_ijkplayer)

String title = entity.title; // Since this property is fetched using KVO in iOS, the default is null, please use titleAsync to get it.

String relativePath = entity.relativePath; // It is always null in iOS.
```

About title: if the title is null or empty string, need use the titleAsync to get it. See below for the definition of attributes.

```dart
  /// It is title `MediaStore.MediaColumns.DISPLAY_NAME` in MediaStore on android.
  ///
  /// It is `PHAssetResource.filename` on iOS.
  ///
  /// Nullable in iOS. If you must need it, See [FilterOption.needTitle] or use [titleAsync].
  String title;

  /// It is [title] in Android.
  ///
  /// It is [PHAsset valueForKey:@"filename"] in iOS.
  Future<String> get titleAsync => _plugin.getTitleAsync(this);
```

#### location info of android Q

Because of AndroidQ's privacy policy issues, it is necessary to locate permissions in order to obtain the original image, and to obtain location information by reading the Exif metadata of the data.

#### Origin description

The `originFile` and `originBytes` will return the original content.

Not guaranteed to be available in flutter.  
Because flutter's Image does not support heic.  
The video is also the original format, non-exported format, compatibility does not guarantee usability.

#### Create with id

The id of the Asset corresponds to the id field of the MediaStore on android, and the localIdentity of PHAsset on iOS.

The user can store the id to any place if necessary, and next time use the [`AssetEntity.fromId(id)`](https://github.com/CaiJingLong/flutter_photo_manager/blob/add49c1e4125540a9fc612521a8441398f9d72ad/lib/src/entity.dart#L126-L138) method to create the AssetEntity instace.

```dart
final asset = await AssetEntity.fromId(id);
```

### observer

use `addChangeCallback` to regiser observe.

```dart
PhotoManager.addChangeCallback(changeNotify);
PhotoManager.startChangeNotify();
```

```dart
PhotoManager.removeChangeCallback(changeNotify);
PhotoManager.stopChangeNotify();
```

### Clear file cache

You can use `PhotoManager.clearFileCache()` to clear all of cache.

The cache is generated at runtime when your call some methods.
The following table will tell the user when the cache file will be generated.

| Platform                                   | thumb | file/originFile |
| ------------------------------------------ | ----- | --------------- |
| Android(28 or lower)                       | Yes   | No              |
| Android(29) (requestLegacyExternalStorage) | Yes   | No              |
| Android(29)                                | Yes   | Yes             |
| Android(30)                                | Yes   | No              |
| iOS                                        | No    | Yes             |

### Experimental

**Important**: The functions are not guaranteed to be fully usable, because it involves data modification, some APIs will cause irreversible deletion / movement of the data, so please use test equipment to make sure that there is no problem before using it.

#### Preload thumb

```dart
PhotoCachingManager().requestCacheAssets(
  assets: assets,
  option: thumbOption,
);
```

And, if you want to stop, call `PhotoCachingManager().cancelCacheRequest();`

Usually, when we preview an album, we use thumbnails.
In flutter, because `ListView.builder` and `GridView.builder` rendering that loads, but sometimes we might want to pre-load some pictures in advance to make them display faster.

Now, I try to create a caching image manager (just like [PHCachingImageManager](https://developer.apple.com/documentation/photokit/phcachingimagemanager?language=objc)) to do it. In IOS, I use the system API directly, and Android will use glide and use glide's file cache to complete this step.
This function is completely optional.

#### Delete item

Hint: this will delete the asset from your device. For iOS, it's not just about removing from the album.

```dart
final List<String> result = await PhotoManager.editor.deleteWithIds([entity.id]); // The deleted id will be returned, if it fails, an empty array will be returned.
```

Tip: You need to call the corresponding `PathEntity`'s `refreshPathProperties` method to refresh the latest assetCount.

And [range](#range) way to get the latest data to ensure the accuracy of the current data. Such as [example](https://github.com/CaiJingLong/flutter_photo_manager/blob/0298d19464c05b231e2e97989f068ec3a72b0ab0/example/lib/model/photo_provider.dart#L104-L113).

#### Insert new item

```dart
final AssetEntity imageEntity = await PhotoManager.editor.saveImage(uint8list); // nullable

final AssetEntity imageEntity = await PhotoManager.editor.saveImageWithPath(path); // nullable

File videoFile = File("video path");
final AssetEntity videoEntity = await await PhotoManager.editor.saveVideo(videoFile); // nullable
```

#### Copy asset

Availability:

- iOS: some albums are smart albums, their content is automatically managed by the system and cannot be inserted manually.
- android:
  - Before api 28, the method will copy some column from origin row.
  - In api 29 or higher, There are some restrictions that cannot be guaranteed, See [document of relative_path](https://developer.android.com/reference/android/provider/MediaStore.MediaColumns#RELATIVE_PATH).

##### Only for iOS

Create folder:

```dart
PhotoManager.editor.iOS.createFolder(
  name,
  parent: parent, // It is a folder or Recent album.
);
```

Create album:

```dart
PhotoManager.editor.iOS.createAlbum(
  name,
  parent: parent, // It is a folder or Recent album.
);
```

Remove asset in album, the asset can't be delete in device, just remove of album.

```dart
PhotoManager.editor.iOS.removeInAlbum();  // remove single asset.
PhotoManager.editor.iOS.removeAssetsInAlbum(); // Batch remove asset in album.
```

Delete the path in device. Both folders and albums can be deleted, except for smart albums.

```dart
PhotoManager.editor.iOS.deletePath();
```

##### Only for Android

Move asset to another album

```dart
PhotoManager.editor.android.moveAssetToAnother(entity: assetEntity, target: pathEntity);
```

Remove all non-existing rows. For normal Android users, this problem doesn't happened.  
A row record exists in the Android MediaStore, but the corresponding file has been deleted. This kind of abnormal deletion usually comes from file manager, helper to clear cache or adb.  
This is a very resource-consuming operation. If the first one is not completed, the second one cannot be opened.

```dart
await PhotoManager.editor.android.removeAllNoExistsAsset();
```

## iOS config

### iOS plist config

Because the album is a privacy privilege, you need user permission to access it. You must to modify the `Info.plist` file in Runner project.

like next

```xml
    <key>NSPhotoLibraryUsageDescription</key>
    <string>App need your agree, can visit your album</string>
```

xcode like image
![in xcode](https://raw.githubusercontent.com/CaiJingLong/some_asset/master/flutter_photo2.png)

In ios11+, if you want to save or delete asset, you also need add `NSPhotoLibraryAddUsageDescription` to plist.

### enabling localized system albums names

By default iOS will retrieve system album names only in English whatever the device's language currently set.
To change this you need to open the ios project of your flutter app using xCode

![in xcode](https://raw.githubusercontent.com/CaiJingLong/some_asset/master/iosFlutterProjectEditinginXcode.png)

Select the project "Runner" and in the localizations table, click on the + icon

![in xcode](https://raw.githubusercontent.com/CaiJingLong/some_asset/master/iosFlutterAddLocalization.png)

Select the adequate language(s) you want to retrieve localized strings.
Validate the popup screen without any modification
Close xCode
Rebuild your flutter project
Now, the system albums should be displayed according to the device's language

### Cache problem of iOS

iOS does not directly provide APIs to access the original files of the album. The corresponding object is PHAsset,

So when you want to use file or originFile, a cache file will be generated locally.

So if you are sensitive to space, please delete it after using file(just iOS), and if it is only used for preview, you can consider using thumb or thumbWithSize.

```dart

void useEntity(AssetEntity entity) async {
  File file = null;
  try{
    file = await entity.file;
    doUpload(); // do upload
  }finally{
    if(Platform.isIOS){
      file?.deleteSync();
    }
  }
}
```

## android config

### Cache problem of android

Because androidQ restricts the application’s ability to directly access the resource path, some large image caches will be generated. This is because: When the file/originFile attribute is used, the plugin will save a file in the cache folder and provide it to dart:io use.

Fortunately, in androidP, the path attribute can be used again, but for androidQ, this is not good news, but we can use requestLegacyExternalStorage to avoid using androidQ's api, and I also recommend you to do so. See [Android Q](#android-q-android10--api-29) to add the attribute.

### about androidX

Google recommends completing all support-to-AndroidX migrations in 2019. Documentation is also provided.

This library has been migrated in version 0.2.2, but it brings a problem. Sometimes your upstream library has not been migrated yet. At this time, you need to add an option to deal with this problem.

The complete migration method can be consulted [gitbook](https://caijinglong.gitbooks.io/migrate-flutter-to-androidx/content/).

### Android Q (android10 , API 29)

Now, the android part of the plugin uses api 29 to compile the plugin, so your android sdk environment must contain api 29 (androidQ).

AndroidQ has a new privacy policy, users can't access the original file.

If your compileSdkVersion and targetSdkVersion are both below 28, you can use `PhotoManager.forceOldApi` to force the old api to access the album. If you are not sure about this part, don't call this method. And, I recommand you add `android:requestLegacyExternalStorage="true"` to your `AndroidManifest.xml`, just like next.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="top.kikt.imagescannerexample">

    <application
        android:name="io.flutter.app.FlutterApplication"
        android:label="image_scanner_example"
        android:requestLegacyExternalStorage="true"
        android:icon="@mipmap/ic_launcher">
    </application>
</manifest>

```

### Android R (android 11, API30)

Unlike androidQ, this version of `requestLegacyExternalStorage` is invalid, but I still recommend that you add this attribute to make it easier to use the old API on android29 of android device.

### glide

Android native use glide to create image thumb bytes, version is 4.11.0.

If your other android library use the library, and version is not same, then you need edit your android project's build.gradle.

```gradle
rootProject.allprojects {

    subprojects {
        project.configurations.all {
            resolutionStrategy.eachDependency { details ->
                if (details.requested.group == 'com.github.bumptech.glide'
                        && details.requested.name.contains('glide')) {
                    details.useVersion '4.11.0'
                }
            }
        }
    }
}
```

And, if you want to use ProGuard, you can see the [ProGuard of Glide](https://github.com/bumptech/glide#proguard).

### Remove Media Location permission

Android contains [ACCESS_MEDIA_LOCATION](https://developer.android.com/training/data-storage/shared/media#media-location-permission) permission by default.

This permission is introduced in Android Q. If your app doesn't need this permission, you need to add the following node to the Android manifest in your app.

```xml
<uses-permission
  android:name="android.permission.ACCESS_MEDIA_LOCATION"
  tools:node="remove"
  />
```

See code in the [example](https://github.com/CaiJingLong/flutter_photo_manager/blob/e083c7d5f4eb5f5b355a75357c0a0c3e2d534b2e/example/android/app/src/main/AndroidManifest.xml#L11-L14).

## common issues

### ios build error

if your flutter print like the log. see [stackoverflow](https://stackoverflow.com/questions/27776497/include-of-non-modular-header-inside-framework-module)

```bash
Xcode's output:
↳
    === BUILD TARGET Runner OF PROJECT Runner WITH CONFIGURATION Debug ===
    The use of Swift 3 @objc inference in Swift 4 mode is deprecated. Please address deprecated @objc inference warnings, test your code with “Use of deprecated Swift 3 @objc inference” logging enabled, and then disable inference by changing the "Swift 3 @objc Inference" build setting to "Default" for the "Runner" target.
    === BUILD TARGET Runner OF PROJECT Runner WITH CONFIGURATION Debug ===
    While building module 'photo_manager' imported from /Users/cai/IdeaProjects/flutter/sxw_order/ios/Runner/GeneratedPluginRegistrant.m:9:
    In file included from <module-includes>:1:
    In file included from /Users/cai/IdeaProjects/flutter/sxw_order/build/ios/Debug-iphonesimulator/photo_manager/photo_manager.framework/Headers/photo_manager-umbrella.h:16:
    /Users/cai/IdeaProjects/flutter/sxw_order/build/ios/Debug-iphonesimulator/photo_manager/photo_manager.framework/Headers/MD5Utils.h:5:9: error: include of non-modular header inside framework module 'photo_manager.MD5Utils': '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator11.2.sdk/usr/include/CommonCrypto/CommonDigest.h' [-Werror,-Wnon-modular-include-in-framework-module]
    #import <CommonCrypto/CommonDigest.h>
            ^
    1 error generated.
    /Users/cai/IdeaProjects/flutter/sxw_order/ios/Runner/GeneratedPluginRegistrant.m:9:9: fatal error: could not build module 'photo_manager'
    #import <photo_manager/ImageScannerPlugin.h>
     ~~~~~~~^
    2 errors generated.
```

## Some articles about to use this library

[How To: Create a custom media picker in Flutter to select photos and videos from the gallery](https://medium.com/@mhstoller.it/how-to-create-a-custom-media-picker-in-flutter-to-select-photos-and-videos-from-the-gallery-988eea477643?sk=cb395a7c20f6002f92f83374b3cc3875)

[Flutter 开发日记-如何实现一个照片选择器 plugin](https://juejin.im/post/5df797706fb9a016107974fc)

If you have other articles about this library, you can contact me or open PR here.

## Migration Guide

See [Migration-Guide](./Migration-Guide.md)
