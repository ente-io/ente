# CHANGELOG

## v1.7.1 (Unreleased)

-   Support for passkeys as a second factor authentication mechanism.
-   Remember the window size across app restarts.
-   Revert changes to the Linux icon.
-   Fix an issue causing deleted items in watched folders to not move to
    uncategorized.
-   Fix duplicate file uploads when initializing a folder watch (sometimes).

## v1.7.0

v1.7 is a major rewrite to improve the security of our app. In particular, the
UI and the native parts of the app now run isolated from each other and
communicate only using a predefined IPC boundary.

Other highlights:

-   View your photos on big screens and Chromecast devices by using the "Play
    album on TV" option in the album menu.
-   Support Brazilian Portuguese, German and Russian.
-   Provide a checkbox to select all photos in a day.
-   Fix a case where the dedup screen would not refresh after removing items.

## v1.6.63

### New

-   Option to select file download location.
-   Add support for searching popular cities
-   Sorted duplicates in desecending order of size
-   Add Counter to upload section
-   Display full name and collection name on hover on dedupe screen photos

### Bug Fixes

-   Fix add to album padding issue
-   Fix double uncategorized album issue
-   Hide Hidden collection files from all section

## v1.6.62

### New

-   Integrated onnx clip runner

### Bug Fixes

-   Fixes login button requiring double click issue
-   Fixes Collection sort state not preserved issue
-   Fixes continuous export causing app crash
-   Improves ML related copies for better distinction from clip
-   Added Better favicon for light mode
-   Fixed face indexing issues
-   Fixed thumbnail load issue

## v1.6.60

### Bug Fixes

-   Fix Thumbnail Orientation issue
-   Fix ML logging issue

## v1.6.59

### New

-   Added arm64 builds for linux

### Bug Fixes

-   Fix Editor file not loading issue
-   Fix ML results missing thumbnail issue

## v1.6.58

### Bug Fixes

-   Fix File load issue

## v1.6.57

### New Features

-   Added encrypted Disk caching for files
-   Added option to customize cache folder location

### Bug Fixes

-   Fixed caching issue,causing multiple download of file during ml sync

## v1.6.55

### Bug Fixes

-   Added manage family portal option if add-on is active
-   Fixed filename date parsing issue
-   Fixed storage limit ui glitch
-   Fixed dedupe page layout issue
-   Fixed ElectronAPI refactoring issue
-   Fixed Search related issues

## v1.6.54

### New Features

-   Added support for HEIC and raw image in photo editor

### Bug Fixes

-   Fixed 16bit HDR HEIC images support
-   Fixed blocked login due safe storage issue
-   Fixed Search related issues
-   Fixed issue of watch folder not cleared on logout
-   other under the hood ui/ux improvements

## v1.6.53

### Bug Fixes

-   Fixed watch folder disabled issue
-   Fixed BF Add on related issues
-   Fixed clip sync issue and added better logging
-   Fixed mov file upload
-   Fixed clip extraction related issue

## v1.6.52

### New Features

-   Added Clip Desktop on windows

### Bug Fixes

-   fixed google json matching issue
-   other under-the-hood changes to improve performance and bug fixes

## v1.6.50

### New Features

-   Added Clip desktop

### Bug Fixes

-   Fixed desktop downloaded file had extra dot in the name
-   Cleanup error messages
-   fix the motion photo clustering issue
-   Add option to disable cf proxy locally
-   other under-the-hood changes to improve UX

## v1.6.49

### Photo Editor

Check out our [blog](https://ente.io/blog/introducing-web-desktop-photo-editor/)
to know about feature and functionalities.

## v1.6.47

### Bug Fixes

-   Fixed misaligned icons in photo-viewer
-   Fixed issue with Motion photo upload
-   Fixed issue with Live-photo upload
-   other minor ux improvement

## v1.6.46

### Bug Fixes

-   Fixes OOM crashes during file upload
    [#1379](https://github.com/ente-io/photos-web/pull/1379)

## v1.6.45

### Bug Fixes

-   Fixed app keeps reloading issue
    [#235](https://github.com/ente-io/photos-desktop/pull/235)
-   Fixed dng and arw preview issue
    [#1378](https://github.com/ente-io/photos-web/pull/1378)
-   Added view crash report option (help menu) for user to share electron crash
    report locally

## v1.6.44

-   Upgraded electron to get latest security patches and other improvements.

## v1.6.43

### Added

-   #### Check for update and changelog option

    Added options to check for update manually and a view changelog via the app
    menubar

-   #### Opt out of crash reporting

    Added option to out of a crash reporting, it can accessed from the settings
    -> preferences -> disable crash reporting

-   #### Type search

    Added new search option to search files based on file type i.e, image,
    video, live-photo.

-   #### Manual Convert Button

    In case the video is not playable, Now there is a convert button which can
    be used to trigger conversion of the video to supported format.

-   #### File Download Progress

    The file loader now also shows the exact percentage download progress,
    instead of just a simple loader.

-   #### Bug fixes & other enhancements

    We have squashed a few pesky bugs that were reported by our community

## v1.6.41

### Added

-   #### Hidden albums

    You can now hide albums, just like individual memories.

-   #### Email verification

    We have now made email verification optional, so you can sign in with just
    your email address and password, without waiting for a verification code.

    You can opt in / out of email verification from Settings > Security.

-   #### Download Album

    You can now chose the download location for downloading albums. Along with
    that we have also added progress bar for album download.

-   #### Bug fixes & other enhancements

    We have squashed a few pesky bugs that were reported by our community

    If you would like to help us improve ente, come join the party @
    ente.io/community!
