---
title: Machine learning
description:
    Ente supports on-device machine learning for face and natural language
    search
---

# Machine learning

> [!NOTE]
>
> This document describes a beta feature that will be present in an upcoming
> release.

Ente supports on-device machine learning. This allows you to use the latest
advances in AI in a privacy preserving manner.

-   You can search for your photos by the **faces** of the people in them. Ente
    will show you all the faces in a photo, and will also try to group similar
    faces together to create clusters of people so that you can give them names,
    and quickly find all photos with a given person in them.

-   You can search for your photos by typing natural language descriptions of
    them. For example, you can search for "night", "by the seaside", or "the red
    motorcycle next to a fountain". Within the app, this ability is sometimes
    referred to as **magic search**.

-   We will build on this foundation to add more forms of advanced search.

You can enable face and magic search in the app's preferences on either the
mobile app or the desktop app.

If you have a big library, we recommend enabling this on the desktop app first,
because it can index your existing photos faster (The app needs to download your
originals to index them which can happen faster over WiFi, and indexing is also
faster on your computer as compared to your mobile device).

Once your existing photos have been indexed, then you can use either. The mobile
app is fast enough to easily and seamlessly index the new photos that you take.

> [!TIP]
>
> Even for the initial indexing, you don't necessarily need the desktop app, it
> just will be a bit faster.

The indexes are synced across all your devices automatically using the same
end-to-end encypted security that we use for syncing your photos.

Note that the desktop app does not currently support viewing and modifying the
automatically generated face groupings, that is only supported by the mobile
app.
