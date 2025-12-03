---
title: Search and Discovery FAQ
description: Frequently asked questions about finding photos using map, face recognition, and search in Ente Photos
---

# Search and Discovery

## Map View

### Why doesn't the map show all my photos? {#missing-photos}

Photos appear on the map only if they have GPS location data embedded in their metadata. Photos may not appear on the map if:

- They were taken without location services enabled
- Location data was stripped during export/transfer
- They were screenshots or downloaded images (which typically don't have location data)
- They were taken on devices with GPS disabled

You can manually add location data to photos that don't have it. See [Metadata and Editing FAQ](/photos/faq/metadata-and-editing#add-location).

### Is my location data sent to Ente servers? {#privacy}

No. Your location data is end-to-end encrypted, just like your photos. When you view photos on the map, the map view uses the encrypted location coordinates stored with your photos.

Ente's servers cannot see:

- Where your photos were taken
- Your location tags
- Map view usage

All location-based searches happen locally on your device. Learn more in our [Security and Privacy FAQ](/photos/faq/security-and-privacy).

### Can I view all albums on the map at once? {#all-albums}

Yes! By default, the map view shows photos from all your albums. You can also:

- View a specific album on the map by opening that album and selecting "Map" from the menu
- Filter the map view by date range
- Zoom in to see photos from specific locations

### How do I access the map view? {#access-map}

**On mobile:**

1. Tap the search icon at the bottom right
2. Tap the globe icon (Your map) in the location section
3. Explore your photos on the map

**From an album:**

- Open any album
- Tap the three dots menu
- Select "Map"
- View only that album's photos on the map

Learn more in the [Map and location guide](/photos/features/search-and-discovery/map-and-location).

## Location Tags

### How are location tags different from map view? {#location-tags-vs-map}

**Map view** shows photos based on GPS coordinates embedded in the photo's metadata. It displays all photos that have location data.

**Location tags** are custom labels you create to organize photos by location. You can:

- Create tags like "Home", "Office", "Paris Trip"
- Define a center point and radius
- Search for photos within that area
- Tag photos that don't have GPS data

Location tags are useful for:

- Organizing photos from places you visit frequently
- Finding photos from a general area (not just exact GPS points)
- Tagging photos that don't have GPS coordinates

Learn more about [Map and location](/photos/features/search-and-discovery/map-and-location).

### How do I create location tags? {#create-location-tags}

**From a photo:**

1. Open a photo
2. Click Info (i)
3. Select "Add Location"
4. Enter the location name and define a radius

**From the search tab:**

1. Open the search tab
2. Click "Add new" in the location tags section
3. Select a photo as the center point
4. Enter the location name and define a radius

The app will automatically cluster photos falling within that radius under your specified location tag.

### Are my location tags encrypted? {#location-tags-encryption}

Yes! Location tags are stored end-to-end encrypted, just like your photos. When you create a location tag, all the location data (coordinates, radius, and tag name) is encrypted on your device before being synced.

Ente's servers cannot see your location tags or where your photos were taken.

## Machine Learning and Face Recognition

### Why doesn't search work for me? {#search-not-working}

If you're searching for objects (like "food", "car", "dog") or trying to find faces but nothing appears, you likely need to enable **Machine Learning (ML)**.

⚠️ **Machine Learning is OFF by default** and must be manually enabled.

**What ML enables:**

- Face recognition and grouping
- Magic search (search by objects, scenes, colors)
- Advanced photo indexing

**Where to enable ML:**

**On mobile:**

Open `Settings > General > Advanced > Machine learning` and toggle ON face recognition and magic search.

**On desktop:**

Open `Settings > Preferences > Machine learning` and toggle ON face recognition and magic search.

**Important limitations:**

- ❌ ML does NOT work on web.ente.io (web browser)
- ✅ ML only works on desktop and mobile apps
- Initial indexing can take time depending on library size

### How do I enable face recognition? {#enable-face-recognition}

Face recognition requires enabling **Machine Learning** first:

**On mobile:**

Open `Settings > General > Advanced > Machine learning`, enable "Face recognition", and wait for indexing to complete.

**On desktop:**

Open `Settings > Preferences > Machine learning`, enable "Face recognition", and monitor indexing progress in the app.

**After enabling:**

- The app downloads and indexes your photos locally
- Progress is shown as a percentage (e.g., "Indexing... 45%")
- Faster on WiFi and desktop computers
- Once complete, faces are grouped automatically

**Troubleshooting:**

- If stuck at 100% but faces don't appear, try disabling and re-enabling ML
- Make sure you're using the desktop or mobile app, NOT web.ente.io
- Check that indexing has actually completed (not just showing 100%)

Learn more in the [Machine learning guide](/photos/features/search-and-discovery/machine-learning).

### Can I search my library by text that appears inside images? {#search-text-in-images}

Only partially. Ente does not maintain a full OCR index of your photos, so search cannot guarantee matches for arbitrary words. Text-related hits today come from metadata or from magic search (CLIP embeddings); magic search can surface photos with very apparent text, but doesn't offer a dedicated OCR search.

### Can I merge or de-merge persons recognized by the app? {#merge-persons}

Yes! The general mechanism for doing this is to assign the same name to both persons.

**On mobile:**

First, make sure one of the two person groupings is assigned a name through the `Add a name` banner. Then for the second grouping, use the same banner but now instead of typing the name again, tap on the already given name that should now be listed.

De-merging a certain grouping can be done by going to the person, pressing `Review suggestions` and then the top right `History icon`. Now press on the `minus icon` beside the group you want to de-merge.

**On desktop:**

Similarly, on desktop you can use the "Add a name" button to merge people by selecting an existing person, and use the "Review suggestions" sheet to de-merge previously merged persons (click the top right history icon on the suggestion sheet to see the previous merges, and if necessary, undo them).

### How can I remove an incorrectly grouped face from a person? {#remove-incorrect-face}

On our mobile app, open up the person from the People section, click on the three dots to open up overflow menu, and click on Edit. Now you will be presented with the list of all photos that were merged to create this person.

You can click on the merged photos and select the photos you think are incorrectly grouped (by long-pressing on them) and select "Remove" from the action bar that pops up to remove any incorrect faces.

### How do I change the cover for a recognized person? {#change-person-cover}

**On mobile:**

Inside the person group, long-press the image you want to use as cover. Then press `Use as cover`.

**On desktop:**

Desktop currently does not support picking a cover. It will default to the most recent image.

### Can I tell the app to ignore certain recognized person? {#ignore-person}

Yes! You can tell the app not to show certain persons.

**On mobile:**

First, make sure the person is not named. If you already gave a name, then first press `Remove person label` in the top right menu. Now inside the unnamed grouping, press `Ignore person` from the top right menu. Long press on the unnamed grouping will also show the option to ignore person.

To undo this action, go to a **photo containing the person**. Open the **file info** section of the photo and press on the **face thumbnail of the ignored person**. This will take you to the grouping of this person. Here you can press `Show person` to undo ignoring the person.

**On desktop:**

Similarly, on desktop, you use the "Ignore" option from the top right menu to ignore a particular face group (If you already give them a name, "Reset person" first). And to undo this action, open that person (via the file info of a photo containing that person), and select "Show person".

### How well does the app handle photos of babies? {#baby-photos}

The face recognition model we use (or any face recognition model for that matter) is known to struggle with pictures of babies and toddlers. While we can't prevent all cases where this goes wrong, we've added a option to help you correct the model in such cases.

If you find a mixed grouping of several different babies, you can use the `mixed grouping` option in the top right menu of said grouping. Activating this option will make the model re-evaluate the grouping with stricter settings, hopefully separating the different babies in different new groupings.

Please note this functionality is currently only available on mobile.

### Does face recognition work offline? {#ml-offline}

Yes! Once your photos have been indexed, face recognition and magic search work completely offline. The initial indexing requires downloading your photos (which happens faster over WiFi), but after that all searches happen locally on your device. The indexes are synced across your devices using end-to-end encryption.

### Is my face data used to train AI models? {#face-data-training}

No. All machine learning (face recognition and magic search) happens entirely on your device. Your photos are downloaded to your device, indexed locally, and the indexes are encrypted before being synced across your devices.

Ente's servers never receive:

- Your unencrypted photos
- Face recognition data
- Search indexes
- Any information about what's in your photos

Your photos and ML data are never used to train any AI models, neither by Ente nor by any third parties.

Learn more in our [Security and Privacy FAQ](/photos/faq/security-and-privacy#ml-privacy).

### Why is face recognition faster on desktop? {#face-recognition-speed}

Desktop computers typically have:

- More powerful processors
- More RAM
- Faster network connections over Ethernet/WiFi

This makes the initial indexing process significantly faster. We recommend enabling machine learning on desktop first if you have a large library. Once indexed, the data syncs to your mobile devices, and they can then quickly index new photos.

### Can I name the recognized persons? {#name-persons}

Yes! Once the app has grouped faces:

1. Open the People section
2. Tap on a person cluster
3. Tap "Add name" or the edit icon
4. Enter the person's name

You can then search for photos by person name.

## Magic Search

### What is magic search? {#what-is-magic-search}

Magic search lets you find photos using natural language descriptions. You can search for things like:

- "night"
- "by the seaside"
- "the red motorcycle next to a fountain"
- "sunset"
- "birthday cake"

The app uses on-device AI to understand the content of your photos and match your search queries.

### How do I enable magic search? {#enable-magic-search}

Magic search is enabled when you enable machine learning:

**On mobile:**

- `Settings > General > Advanced > Machine learning`

**On desktop:**

- `Settings > Preferences > Machine learning`

After enabling, the app will index your photos locally. Once indexing is complete, you can use magic search.

### Does magic search require internet? {#magic-search-offline}

No! Magic search works completely offline after the initial indexing. All processing happens on your device.

However, the initial indexing requires downloading your photos, which is faster over WiFi.

### Can I search for photos using the descriptions I've added? {#search-descriptions}

Yes! Descriptions (captions) you add to photos are searchable, making it easier to find specific photos later.

**To add a description:**

1. Open the photo
2. Tap the info button (i)
3. Enter your description
4. Save

You can then search for words in those descriptions to find the photos.

Learn more in [Metadata and Editing FAQ](/photos/faq/metadata-and-editing#descriptions).

## General Search

### How do I search my photos? {#how-to-search}

Ente supports multiple search types:

**Date search**: Search by date, month, or year
**Location search**: Find photos taken in specific locations (if they have GPS data)
**Magic search**: Natural language descriptions of photo content
**Face search**: Find photos of specific people
**Description search**: Search descriptions/captions you've added
**File name search**: Search by original file name

Simply type in the search bar and Ente will show matching results across all these categories.

### Can I save my searches? {#save-searches}

Currently, you cannot save searches. However, you can:

- Create albums for specific types of photos
- Use location tags to organize by place
- Name persons in face recognition for quick access

### Does search include archived or hidden photos? {#search-archived-hidden}

**Archived photos**: Yes, archived photos appear in search results. Archiving only removes photos from your timeline.

**Hidden photos**: No, hidden photos do not appear in search results. They're completely removed from all views except the special "Hidden" section.

Learn more in [Albums and Organization FAQ](/photos/faq/albums-and-organization#hide-vs-archive).

### Indexing stuck at 100% but faces don't appear {#indexing-stuck-no-faces}

If indexing shows 100% but you don't see faces:

1. Make sure you're using the mobile or desktop app (not web.ente.io)
2. Try disabling and re-enabling machine learning
3. Check that indexing has truly completed (not just displaying 100%)
4. Restart the app

### Faces not being grouped correctly {#faces-not-grouped-correctly}

If face grouping quality is poor:

- For baby photos, use the **mixed grouping** feature (mobile only)
- Manually merge persons that should be together
- Remove incorrect faces from groupings
- Face recognition works better with clear, front-facing photos

Learn more about [handling baby photos](/photos/faq/search-and-discovery#babies).

### Can't modify face groupings on desktop {#cant-modify-faces-desktop}

This is a current limitation. To edit face groupings (remove incorrect faces, change covers), use the mobile app. Desktop can view and name persons but cannot modify the groupings.

### Performance issues during indexing {#ml-performance-issues}

If indexing is slow or affecting performance:

- **Mobile**: Consider disabling local indexing and using desktop instead
- **Desktop**: Indexing is CPU intensive but temporary
- Enable on desktop first for large libraries

Learn more in [Machine learning configuration](/photos/features/search-and-discovery/machine-learning#local-indexing-configuration).

### Magic search not finding relevant photos {#magic-search-not-finding}

If search results aren't what you expect:

- Try different phrasing or synonyms
- Be more specific with your query
- Check that indexing has completed
- Try combining multiple descriptive terms

### Machine learning features not working {#ml-features-not-working}

If face recognition or magic search isn't available:

- Ensure you're using mobile or desktop app (not web.ente.io)
- Check that machine learning is enabled in ML settings
- Verify indexing has completed
- Restart the app

Note: Machine learning features only work on mobile and desktop apps, not on web.ente.io.
