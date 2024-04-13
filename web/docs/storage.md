# Storage

## Local Storage

Data in the local storage is persisted even after the user closes the tab (or
the browser itself). This is in contrast with session storage, where the data is
cleared when the browser tab is closed.

The data in local storage is tied to the Document's origin (scheme + host).

Some things that get stored here are:

-   Details about the logged in user, in particular their user id and a auth
    token we can use to make API calls on their behalf.

-   Various user preferences

## Session Storage

Data tied to the browser tab's lifetime.

We store the user's encryption key here.

## Indexed DB

We use the LocalForage library for storing things in Indexed DB. This library
falls back to localStorage in case Indexed DB storage is not available.

Indexed DB allows for larger sizes than local/session storage, and is generally
meant for larger, tabular data.

## OPFS

OPFS is used for caching entire files when we're running under Electron (the Web
Cache API is used in the browser).

As it name suggests, it is an entire filesystem, private for us ("origin"). In
is not undbounded though, and the storage is not guaranteed to be persistent (at
least with the APIs we use), hence the cache designation.
