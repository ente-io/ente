# CHANGELOG

## 0.7.0

- Fix

  - Fix momory leaked for android.

- Support android v2 plugin.

**Breaking Change**:

- Replace `List<int>` to `Uint8List`.

## 0.6.8

Update `Validate` code.

## 0.6.7

Use the async GCD in iOS.

## 0.6.6

[#116](https://github.com/OpenFlutter/flutter_image_compress/pull/116), [#124](https://github.com/OpenFlutter/flutter_image_compress/pull/124)

## 0.6.5+1

Fix:

- Web format error
- Import header error for iOS.

## 0.6.5

New feature

- Support webp on iOS.

## 0.6.4

New feature:

- Add Params inSampleSize for methods.
- Heif and webp Partially supported.

## 0.6.3

Fix:

- Android: When the register of the calling plugin is not in the main process or there is no Activity.

## 0.6.2

Optimization:

- Reduce the speed required for ios to add dependencies by copying the `SYPictureMetadata` source code into the project.

## 0.6.1

Fix:

- autoCorrectionAngle switches image width and height.

New feature:

- Keep exif (no have orientation), use `keepExif`

## 0.6.0

**BREAKING CHANGE** :

- remove method `getImageInfo`.

For the time being, the follow-dev branch is no longer used, but only the master branch is needed to unify the pub version number.

New Feature:

- It is now supported to set the compression target to png format.

## 0.5.2

Fix:

- [#49](https://github.com/OpenFlutter/flutter_image_compress/issues/49): A problem of reading Exif information.

## 0.5.1

Change `reportError` with flutter stable version.

**Breaking Change:**
The autoCorrectionAngle parameter causes a number of situations to behave differently than `0.4.0`. See readme for details.

## 0.5.0

(don't use)

**Breaking Change:**
Because `FlutterError.reportError` method's param `context` type changed.
So this library will add the constraints of flutter SDK so that users before 1.5.9 will not use version 0.5.0 incorrectly.

## 0.4.0

Some code has been added to ensure that parameters that do not pass in native do not trigger crash.

## 0.3.1

Fix:

- Android close file output stream.

## 0.3.0

Fix:

- optimize compress scale.

## 0.2.4

Updated Kotlin version

**Breaking change**. Migrate from the deprecated original Android Support
Library to AndroidX. This shouldn't result in any functional changes, but it
requires any Android apps using this plugin to [also
migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
using the original support library.

## 0.2.3

change iOS return type

## 0.2.2

add some dart doc

## 0.2.1

update readme

## 0.2.0

The version number is updated so that people who can use the higher version of gradle can use it. see pr #8

if android run error, you must update your kotlin'version to 1.2.71+

## 0.1.4

add optional params rotate

fix bug

update example

## 0.1.3

fix the ios `flutter.h` bug

## 0.1.1

update readme

## 0.1.0

first version
