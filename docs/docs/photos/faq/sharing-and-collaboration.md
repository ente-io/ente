---
title: Sharing and Collaboration FAQ
description: Frequently asked questions about sharing photos and collaborating in Ente Photos
---

# Sharing and Collaboration

## Understanding Sharing Methods

### What are the different ways to share in Ente? {#sharing-methods}

Ente offers three main ways to share photos, each designed for different use cases:

**1. Shared albums (with Ente users)**

Share directly with specific people who have Ente accounts:

- Invite by email address
- Recipients need an Ente account
- Choose Viewer or Collaborator permissions
- Each photo's storage counts towards whoever uploaded it
- Perfect for ongoing collaboration with family and friends

Learn more: [Collaboration guide](/photos/features/sharing-and-collaboration/collaboration)

**2. Public links (for anyone)**

Share via links that anyone can access without an account:

- **Regular public links**: View-only access to an album
- **Quick links**: Select photos → create link (Ente creates hidden album automatically)
- **Collect links**: Enable "Allow adding photos" so anyone can contribute
- Password protection, expiry, and device limits available
- Custom domains supported

Learn more: [Public links guide](/photos/features/sharing-and-collaboration/public-links)

**3. Collaborative albums (Ente users working together)**

Multiple Ente users can add photos to the same album:

- All collaborators can contribute photos
- Each person's uploads count towards their own storage
- Owner controls permissions and membership
- Currently full support on mobile, view-only on web/desktop

Learn more: [Collaboration guide](/photos/features/sharing-and-collaboration/collaboration)

For a complete overview, see [Sharing documentation](/photos/features/sharing-and-collaboration/share).

### What's the difference between public links and quick links? {#link-types}

Quick links ARE public links - just with a different creation method:

**Public links:**

- Create from an existing album
- Share the entire album via link

**Quick links:**

- Select specific photos anywhere in Ente
- Ente creates a hidden album automatically
- Share via link (works exactly like a public link)
- Can convert to regular album later

Both support the same features: password protection, expiry, device limits, collect mode, and custom domains.

Learn more: [Public links guide](/photos/features/sharing-and-collaboration/public-links)

### Can I use my own domain for public links? {#custom-domains}

Yes! Ente's custom domains feature lets you serve your public album links using your own personalized domain instead of `albums.ente.io`.

For example, instead of:

```
https://albums.ente.io/?t=...
```

You can use:

```
https://pics.example.org/?t=...
```

**Requirements:**

- Active Ente subscription (required for public sharing)
- Your own domain or subdomain
- Ability to add a CNAME DNS record

**Setup:**

1. Link your domain in `Settings > Preferences > Custom domains` (currently web only)
2. Add a CNAME DNS record pointing your domain to `my.ente.io`
3. Wait for DNS changes to propagate (usually a few minutes)

Once configured, Ente automatically uses your custom domain when creating new public links. Ente still hosts and serves your albums - only the URL changes.

Learn more in the [Custom domains guide](/photos/features/sharing-and-collaboration/custom-domains/).

### Do Trip albums work with custom domains? {#trip-custom-domains}

Trip albums (albums with the Trip layout feature) are not currently supported on custom domains. When someone tries to access a Trip album through your custom domain, they will be automatically redirected to the default `albums.ente.io` domain.

Regular albums continue to work perfectly on your custom domain - only the Trip layout feature has this limitation.

Learn more in the [Custom domains guide](/photos/features/sharing-and-collaboration/custom-domains/).

### How can my partner and I automatically share all photos we take with each other? {#auto-share-partners}

You can do this by adding your partner as a viewer or collaborator to your camera folder, and asking them to do the same for you. On Android this is the **Camera** folder, and on iOS this is **Recents** (or equivalent).

Any new photos backed up to these folders will automatically be shared and synced to the other person's device. This results in two separate albums — one for your photos and one for your partner's — where both of you can view and add photos.

### Does Ente have a shared library feature where all photos are shared with another account (similar to Google Photos Partner Sharing/iCloud Shared Photo Library)? {#shared-library}

Ente has shared albums but does not support sharing your entire library in one click. However, you can share all albums by selecting one album, choosing the "all" option on the bottom right, which selects all albums and then you can share in one go with a partner (they can be [viewer or collaborator](/photos/features/sharing-and-collaboration/collaboration#collaborating-with-ente-users)).

[Smart albums](/photos/features/albums-and-organization/auto-add-people#auto-add-people-to-albums-smart-albums) let you auto-add specific people to albums as well.

## Collaboration

### How do I share an album with other Ente users? {#share-with-users}

1. Open the album you want to share
2. Tap/click the Share icon
3. Select "Share with Ente users" or enter email addresses
4. Choose permissions (Viewer or Collaborator)
5. Send the invitation

The recipient will receive a notification and can access the shared album from their Ente app. They must have an Ente account to receive shared albums.

### Who pays for storage in collaborative albums? {#collab-storage}

In collaborative albums (shared with other Ente users):

- Each photo's storage is counted towards **the person who uploaded it**
- Since collaborators usually already have the photo in their account, they effectively don't pay extra
- The album owner does not pay for photos uploaded by collaborators

In collect links (public links with upload enabled):

- All photos added via the link count towards **the album owner's storage**
- The owner has full control to remove photos at any time
- People adding photos via the link don't need Ente accounts and don't pay anything

Learn more: [Collaboration guide](/photos/features/sharing-and-collaboration/collaboration)

### Can collaborators delete photos from shared albums? {#collab-permissions}

Permissions depend on your role:

**Collaborators can:**

- Add photos to the shared album
- Delete photos they uploaded themselves
- View all photos in the album

**Collaborators cannot:**

- Delete photos uploaded by others
- Delete the album itself
- Change album settings or permissions

**Album owner can:**

- Remove any photos from the album
- Only permanently delete photos they own
- Remove or change permissions for collaborators
- Delete the entire album

### What happens when I remove a collaborator from an album? {#remove-collaborator}

When a collaborator is removed from a shared album (or when they leave the album voluntarily):

- Any photos they uploaded to the album will also be removed from that album
- Those photos remain in the collaborator's own account
- Photos uploaded by other collaborators or the owner remain in the album
- The removed collaborator loses access to view the album

### Is collaboration available on all platforms? {#collaboration-platforms}

**Collaborative albums** (sharing with other Ente users):

- Fully supported on mobile apps (iOS and Android)
- View-only mode on web and desktop (we're actively working on adding full support)

**Collaborative links** (collect links):

- Can be created on all platforms (mobile, web, desktop)
- Anyone with the link can add photos via web browser

### Why am I not getting notifications when photos are added to shared albums? {#shared-album-notifications}

**On iOS:**

Notification limitations on iOS are due to Apple's platform restrictions:

⚠️ **Notifications only work when the app is running in the background**, not if you've force-closed it from the app switcher.

**Why this happens:**

- iOS delivers notifications via silent push notifications
- These "wake up" the app to check for new photos
- If you force-kill the app, iOS won't deliver these notifications
- This is an Apple platform limitation, not an Ente bug

**To receive notifications on iOS:**

1. Enable notifications in device `Settings > Ente > Notifications`
2. Enable Background App Refresh in device `Settings > Ente`
3. **Don't force-close the Ente app** from the app switcher
4. The app can run in the background without draining battery

**On Android:**

Notifications work more reliably on Android, but can still be affected by:

- Battery optimization settings restricting the app
- Force-closing the app from recents
- Notification permissions not granted

**To receive notifications on Android:**

1. Open device `Settings > Ente > Notifications` and ensure all notification categories are enabled
2. Disable battery optimization for Ente in system settings
3. Don't force-close the app from recents

**Alternative:**
If you need real-time updates, keep the app open or check the shared album manually by opening it in the app.

- No platform restrictions for link recipients

## Public Links

### How do I create a collect link to gather photos from others? {#create-collect-link}

Collect links let anyone add photos to your album without needing an Ente account - perfect for gathering photos from events, parties, or trips.

**On mobile:**

1. Open the album you want to use for collecting photos
2. Tap the Share icon in the top right corner
3. Select "Collect photos"
4. Tap "Copy link"
5. Share the link with anyone you want to collect photos from

**On web/desktop:**

1. Open the album
2. Click the share album icon
3. Select "Collect photos"
4. Click "Copy link"
5. Share the link via email, messaging, or however you prefer

Anyone with the link can view existing photos and add their own through their web browser. All collected photos count toward your storage quota. Learn more in the [Collaboration guide](/photos/features/sharing-and-collaboration/collaboration).

### Can people without Ente add photos to my album? {#collect-without-account}

Yes! When you create a collect link (public link with "Allow adding photos" enabled), anyone with the link can view and add photos using just their web browser - no Ente account or app installation required.

This is perfect for collecting event photos from a large group of people, like weddings, parties, or trips, where not everyone uses Ente.

To enable this, create a public link and enable the "Allow adding photos" option. Learn more in the [Collaboration guide](/photos/features/sharing-and-collaboration/collaboration).

### Do collected photos count against my storage? {#collect-storage}

Yes, photos added to your album through a collect link count towards your storage quota as the album owner.

When someone adds a photo via a collect link:

- The photo is stored in your account
- You have full control to remove these photos at any time
- The storage counts against your plan's total storage limit

Make sure you have sufficient storage available if you're expecting many people to add photos.

### Can I set limits on public links? {#link-limits}

Yes! Public links (including collect links) support several protective features:

- **Link expiry**: Set the link to automatically expire after a duration you define
- **Device limits**: Limit how many devices can access the link (a "device" is identified by the combination of IP address and browser/app, so the same browser on a different network counts as a separate device)
- **Password protection**: Add an additional password that users must enter to access the link
- **Prevent downloads**: Disable the option to download original photos (though screenshots can't be prevented)

These options help you maintain control over who can access and contribute to your shared albums.

### Can I stop people from adding more photos to a collect link? {#disable-collect-link}

Yes, you have several options:

1. **Remove the link entirely**: Delete the public link from your sharing settings
2. **Set an expiry date**: Configure the link to automatically expire after a certain time
3. **Disable uploads**: Edit the link settings and turn off "Allow adding photos"
4. **Change to view-only**: Convert the collect link to a regular public link (view only)

You can manage these settings by going to your Sharing section and selecting the link you want to modify.

### Can I see who added photos to my collect link? {#collect-link-attribution}

When photos are added via a collect link (by people without Ente accounts), you cannot see specifically who added each photo. The photos will appear in your album without attribution.

In collaborative albums (with other Ente users), you can see who uploaded each photo by viewing the photo's info.

## Public Link Features

### Can I convert a quick link to a regular album? {#quick-link-convert}

Yes! Quick links automatically create a special album behind the scenes. You can convert this to a regular album at any time:

1. Open the Sharing tab in the Ente app
2. Find the quick link under "Quick links" section
3. Select the option to convert it to a regular album

This gives you more control over the album, including the ability to rename it and organize it like any other album.

### How do I create a quick link? {#create-quick-link}

1. Select one or more photos (without creating an album)
2. Tap/click the Share button
3. Select "Create quick link"
4. Copy and share the link

Ente creates a special album behind the scenes with the selected photos. Quick links work like public links and support the same features (password protection, expiry, etc.).

## Managing Shared Content

### Can I add photos from a shared album to my own albums? {#add-shared-photos}

Yes, on Ente's mobile apps, you can add photos from an album that's shared with you into one of your own albums.

**Important**: This creates a copy of the photo that you fully own, and it will count against your storage quota. This is different from just viewing shared photos, which doesn't use your storage.

The reason for creating copies is to avoid complications around ownership - if the original owner deletes the photo from their library, your copy remains safe in your account.

### Why does adding shared photos to my albums count against my storage? {#shared-storage-count}

When you add a shared photo to your own album, Ente creates a hard copy that you fully own. This ensures that:

1. **You maintain control**: The photo remains in your account even if the original owner deletes it
2. **Ownership is clear**: There's no ambiguity about who owns which version of the photo
3. **No dependency**: Your organized albums don't break if someone stops sharing with you

We understand this uses extra storage in some use cases (like family photo sharing). We're exploring reference-based solutions in the future where storage would only count if the original is deleted. See [this discussion](https://github.com/ente-io/ente/discussions/790) for more details.

### Can I remove myself from a shared album? {#leave-shared-album}

Yes, if someone has shared an album with you, you can leave it at any time:

1. Open the shared album
2. Tap/click the three dots menu
3. Select "Leave album"

After leaving, you'll no longer have access to the album. If you were a collaborator and uploaded photos, those photos will be removed from the album but remain in your own account.

### How do I see all my shared albums? {#view-shared-albums}

**On mobile:**

- Open the Albums tab
- Shared albums appear alongside your own albums
- Look for the "Shared by" indicator under the album name

**On web/desktop:**

- Shared albums appear in your album list
- They're marked with a sharing icon

You can also view all sharing activity in the Sharing tab/section.

## Permissions and Access

### Who can create collaborative albums or public links? {#who-can-share}

Album sharing and public links are now available on every plan, including the free tier. Free plan users can create public links with a [device limit](https://ente.io/help/photos/features/sharing-and-collaboration/public-links#device-limits) of 5. This limitation helps safeguard against potential platform abuse.

Free users can:

- Create and receive shared albums
- Share albums directly with other Ente users
- Create public links ([device limit](https://ente.io/help/photos/features/sharing-and-collaboration/public-links#device-limits) of 5)
- View public links shared with them
- Add photos to collect links that allow uploads

Paid users can:

- Create public links with no device limit
- Access all other premium features

### Can I change permissions for collaborators after sharing? {#change-permissions}

Yes, the album owner can change permissions at any time:

1. Open the shared album
2. Open sharing settings
3. Find the collaborator
4. Change their role from Collaborator to Viewer (or vice versa)

Viewers can only view photos, while Collaborators can both view and add photos.

### What happens to shared albums if I cancel my subscription? {#cancel-subscription-impact}

If you're the owner of shared albums and your paid subscription expires:

- Existing shared albums will remain accessible to collaborators
- You won't be able to create new shares
- You won't be able to modify existing share settings

Receiving shared albums works on free accounts, so if someone shares with you, you can still access those albums even without a paid plan.

## Security and Privacy

### Are public links end-to-end encrypted? {#public-link-encryption}

Yes, content shared via public links remains end-to-end encrypted. However, the decryption keys are embedded in the link itself (as a URL fragment that never reaches our servers). This means anyone with the link can decrypt and view the content. For sensitive content, use password protection and link expiration features to add extra security layers.

Learn more about [public link encryption](/photos/faq/security-and-privacy#public-link-encryption) in our Security and Privacy FAQ.

### How does sharing work with encryption? {#sharing-encryption-technical}

The information required to decrypt an album is encrypted with the recipient's public key such that only they can decrypt them.

You can read more about this in our [architecture documentation](https://ente.io/architecture#sharing).

In case of sharable links, the key to decrypt the album is appended by the client as a [fragment to the URL](https://en.wikipedia.org/wiki/URI_fragment), and is never sent to our servers.

### Can Ente see my shared photos? {#ente-see-shared}

No. Ente has no information about:

- Whether you have shared an album
- What photos are in shared albums
- Who you've shared with
- What's in public links

All sharing happens with end-to-end encryption. Only people you share with (or who have the link) can decrypt and view the content.

## Embedding Albums

### How do I embed an album on my website? {#embed-albums}

Ente allows you to embed public albums on your own website or blog using an iframe, similar to how you would embed a YouTube video.

**Easy method:**

Open the album in Ente (web or mobile app), create a public link, open link settings, and tap/click "Copy embed HTML".

**Manual method:**

Create a public link for your album, then add an iframe to your HTML with the URL, replacing `albums.ente.io` with `embed.ente.io`:

```html
<iframe
    src="https://embed.ente.io/?t=...#..."
    width="800"
    height="600"
    frameborder="0"
    allowfullscreen
>
</iframe>
```

For complete details, see the [Embed albums guide](/photos/features/sharing-and-collaboration/embed).

### Do embedded albums work with custom domains? {#embed-custom-domains}

Yes, but you need to use `embed.ente.io` instead of your custom domain in the iframe src.

If you're using the easy method (copy embed HTML button), the app automatically handles this for you - it will use `embed.ente.io` regardless of your custom domain setting.

If you're creating the embed code manually and have a custom domain configured:

- Replace your custom domain with `embed.ente.io` in the iframe src
- For example: `https://embed.ente.io/?t=...` (not `https://pics.example.org/?t=...`)

The embed will still work perfectly - it's just served from the embed subdomain instead of your custom domain.

### Can I embed password-protected albums? {#embed-password}

Yes! Password-protected albums work in embeds. When someone views the embedded album, they'll see a password prompt within the iframe. Once they enter the correct password, they can view the photos.

The embed maintains all the security features of your public link:

- Password protection (if enabled)
- Same end-to-end encryption
- Link expiry (if set)
- Device limits (if set)

### What happens to my embed if I delete the public link? {#embed-deletion}

If you delete the public link, the embed will immediately stop working. The embedded album requires an active public link to function.

If you want to stop people from accessing the embedded album:

1. Delete the public link from the album's sharing settings
2. The embed will show an error or empty state
3. Remove the embed code from your website

If you just want to temporarily disable access, consider using the link's password protection or expiry features instead of deleting it entirely.

### What features are available in embedded albums? {#embed-features}

Embedded albums include:

- Thumbnail grid view
- Full-size image viewer with navigation
- Video playback support
- Fullscreen mode (when `allowfullscreen` attribute is set)
- Password protection (if enabled on the link)
- Automatic updates when you add new photos to the album

You can customize the embed size using iframe width/height attributes, including responsive sizing with percentages.

See the [Embed feature guide](/photos/features/sharing-and-collaboration/embed) for customization examples.
