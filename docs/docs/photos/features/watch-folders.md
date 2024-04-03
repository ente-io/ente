---
title: Watch folder
description:
    Automatic syncing of selected folders using the Ente Photos desktop app
---

# Watch folders

The Ente desktop app allows you to "watch" a folder on your computer for any
changes, creating a one-way background sync from folders on your computer to
Ente albums. This is intended to automate your photo management and backup.

By using the "Watch folders" option in the sidebar, you can tell the desktop app
which are the folders that you want to watch for changes. The app will then
automatically upload new files added to these folders to the corresponding ente
album (it will also upload them initially). And if a file is deleted locally,
then the corresponding Ente file will also be automatically moved to
uncategorized.

Paired with the option to run Ente automatically when your computer starts, this
allows you to automate backups to ente's cloud.

### Steps

1. Press the **Watch folders** button in the sidebar. This will open up a dialog
   where you can add and remove watched folders.

2. To start watching a folder, press the **Add folder** button and select the
   folder on your laptop that you want to watch for any changes. You can also
   drag and drop the folder here.

3. If the folder has nesting, you will see two options - **A single album** and
   **Separate albums**.

    - **Single album** will create a new Ente album with the same name as the
      folder's name, and will then sync all the changes in the folder (and any
      nested folders) to this single album.

    - **Separate albums** will create separate albums for each nested folder of
      the selected folder, and will then sync the changes in each nested folder
      separately.

    - For example, suppose you have a folder name `Photos` on your computer, and
      inside that folder you have two nested folders named `New Year` and
      `Summer`. In the single album mode, the app will create an Ente album
      named "Photos" and put all the files from both `New Year` and `Summer`
      there. In the separate album mode, the app will create two Ente albums,
      "New Year" and "Summer", each only containing the respective files.

    - In separate album mode, only nested folders that have at least one file
      will result in the creation of a new album – empty folders (or folders
      that only contain other folders) will be ignored.

4. After choosing any of the above options, the folder will be initially synced
   to ente's cloud and monitored for any changes. You can now close the dialog
   and the sync will continue in background.

5. When the app is syncing in the background it'll show a small progress status
   in the bottom right. You can expand it to see more details if needed.

6. You can stop watching any folder by clicking on the three dots next to the
   watch folder entry, and then selecting **Stop watching**.

> Note: In case you start a new upload while an existing sync is in progress,
> the sync will be paused then and resumed when your upload is done.

Some more details about the feature are in our
[blog post](http://ente.io/blog/watch-folders) announcing it.
