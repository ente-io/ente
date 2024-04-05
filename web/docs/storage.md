# Storage

## Local Storage

Data in the local storage is persisted even after the user closes the tab (or
the browser itself). This is in contrast with session storage, where the data is
cleared when the browser tab is closed.

The data in local storage is tied to the Document's origin (scheme + host).

## Session Storage

## Indexed DB

We use the LocalForage library for storing things in Indexed DB. This library
falls back to localStorage in case Indexed DB storage is not available.
