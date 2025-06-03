---
title: Face recognition
description: Frequently asked questions about Ente's face recognition
---

# Face recognition

## Can I merge or de-merge persons recognized by the app?

Yes! The general mechanism for doing this is to assign the same name to both
persons.

### Mobile

First, make sure one of the two person groupings is assigned a name through the
`Add a name` banner. Then for the second grouping, use the same banner but now
instead of typing the name again, tap on the already given name that should now
be listed.

De-merging a certain grouping can be done by going to the person, pressing
`Review suggestions` and then the top right `History icon`. Now press on the
`minus icon` beside the group you want to de-merge.

### Desktop

Similarly, on desktop you can use the "Add a name" button to merge people by
selecting an existing person, and use the "Review suggestions" sheet to de-merge
previously merged persons (click the top right history icon on the suggestion
sheet to see the previous merges, and if necessary, undo them).

## How can I remove an incorrectly grouped face from a person?

On our mobile app, open up the person from the People section, click on the
three dots to open up overflow menu, and click on Edit. Now you will be
presented with the list of all photos that were merged to create this person.

You can click on the merged photos and select the photos you think are
incorrectly grouped (by long-pressing on them) and select "Remove" from the
action bar that pops up to remove any incorrect faces.

## How do I change the cover for a recognized person?

### Mobile

Inside the person group, long-press the image you want to use as cover. Then
press `Use as cover`.

### Desktop

Desktop currently does not support picking a cover. It will default to the most
recent image.

## Can I tell the app to ignore certain recognized person?

Yes! You can tell the app not to show certain persons.

### Mobile

First, make sure the person is not named. If you already gave a name, then first
press `Remove person label` in the top right menu. Now inside the unnamed
grouping, press `Ignore person` from the top right menu.

To undo this action, go to a **photo containing the person**. Go to the **file
info** section of the photo and press on the **face thumbnail of the ignored
person**. This will take you to the grouping of this person. Here you can press
`Show person` to undo ignoring the person.

### Desktop

Similarly, on desktop, you use the "Ignore" option from the top right menu to
ignore a particular face group (If you already give them a name, "Reset person"
first). And to undo this action, open that person (via the file info of a photo
containing that person), and select "Show person".

## How well does the app handle photos of babies?

The face recognition model we use (or any face recognition model for that
matter) is known to struggle with pictures of babies and toddlers. While we
can't prevent all cases where this goes wrong, we've added a option to help you
correct the model in such cases.

If you find a mixed grouping of several different babies, you can use the
`mixed grouping` option in the top right menu of said grouping. Activating this
option will make the model re-evaluate the grouping with stricter settings,
hopefully separating the different babies in different new groupings.

Please note this functionality is currently only available on mobile.
