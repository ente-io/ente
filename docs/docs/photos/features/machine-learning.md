---
title: Machine learning
description:
    Ente supports on-device machine learning for face and natural language
    search
---

# Machine learning

Ente supports on-device machine learning. This allows you to use the latest
advances in AI in a privacy preserving manner.

- You can search for your photos by the **Faces** of the people in them. Ente
  will show you all the faces in a photo, and will also try to group similar
  faces together to create clusters of people so that you can give them names,
  and quickly find all photos with a given person in them.

- You can search for your photos by typing natural language descriptions of
  them. For example, you can search for "night", "by the seaside", or "the red
  motorcycle next to a fountain". Within the app, this ability is referred to as
  **Magic search**.

You can enable face recognition and magic search in the app's preferences on
either the mobile app or the desktop app.

On mobile, this is available under `General > Advanced > Machine learning`.

On desktop, this is available under `Preferences > Machine learning`.

---

The app needs to download your original photos to index them. This is faster
over WiFi. Indexing is also faster on your computer as compared to your mobile
device.

> [!TIP]
>
> If you have a large library on Ente, we recommend enabling this feature on the
> desktop app first, because it can index your existing photos faster. Once your
> existing photos have been indexed, then you can use either. The mobile app is
> fast enough to index new photos as they are being backed up.
>
> Also, it is beneficial to enable machine learning before importing your
> photos, as this allows the Ente app to index your files as they are getting
> uploaded instead of needing to download them again.

The indexes are synced across all your devices automatically using the same
end-to-end encrypted security that we use for syncing your photos.

---

#### Local indexing on mobile

In general the machine learning is optimized to work well on most mobile device.
However, devices with low RAM (4-6GB) and large photo libraries might struggle
to complete the indexing without affecting performance of the app. In such case,
you might want to disable local indexing and let the desktop run it instead.

You can disable local indexing from the settings, under
`General > Advanced > Machine learning > Configuration`. This way, you can
continue to use the ML features without your phone performance taking any hit.

---

For more information on how to use Machine Learning for face recognition please
check out [the FAQ](../faq/face-recognition).
