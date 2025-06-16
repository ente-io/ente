---
title: Background sync
description: Ente Photos supports automatic background sync and backup
---

# Background sync

Ente Photos supports seamless background sync so that you don't need to open the
app to backup your photos. It will sync in the background and automatically
backup the albums that you have selected for syncing.

Day to day sync will work automatically. However, there are some platform
specific considerations that apply, more on these below:

### iOS

On iOS, if you have a very large number of photos and videos, then you might
need to keep Ente running in the foreground for the first backup to happen
(since we get only a limited amount of background execution time). To help with
this, under "Settings > Backup" there is an option to disable the automatic
device screen lock. But once your initial backup has completed, subsequent
backups will work fine in the background and don't need disabling the screen
lock.

On iOS, Ente will not backup videos in the background (since videos are usually
much larger and need more time to upload than what we get). However, they will
get backed up the next time the Ente app is opened.

Note that the Ente app will not be able to backup in the background if you force
kill the app.

> If you're curious, the way this works is, our servers "tickle" your device
> every once in a while by sending a silent push notification, which wakes up
> our app and gives it 30 seconds to execute a background sync. However, if you
> have killed the app from recents, iOS will not deliver the push to the app,
> breaking the background sync.

### Android

On some Android versions, newly downloaded apps activate a mode called "Optimize
battery usage" which prevents them from running in the background. So you will
need to disable this "Optimize battery usage" mode in the system settings for
Ente if you wish for Ente to automatically back up your photos in the
background.

On Android versions 15 and later, if an app is in private space and the private
space is locked, Android doesn’t allow the app to run any background processes.
As a result, background sync will not work.

### Desktop

In addition to our mobile apps, the background sync also works on our desktop
app, though the [way that works](watch-folders) is a bit different.

---

## Troubleshooting

- On iOS, make sure that you're not killing the Ente app.
- On Android, make sure that "Optimize battery usage" is not turned on in system
  settings for the Ente app.
