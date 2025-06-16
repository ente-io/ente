/**
 * @file
 *
 * [Note: Files DB]
 *
 * Prior to us using idb for accessing IndexedDB, we used localForage (another
 * IndexedDB library) for that purpose (See `docs/storage.md` for more context).
 *
 * Our use of localForage was limited to a single IndexedDB table named "files".
 * It stored more than files though - files, collections, trash, and their
 * corresponding sync times.
 *
 * Since we've now switched to IDB as our preferred IndexedDB library, the data
 * stored in this files table could be considered legacy in a sense. But such
 * would be an incorrect characterization - this code has no issues, and it
 * stores core data for us (files and collections are as core as it gets).
 *
 * So this table is not legacy or deprecated, and there is currently no strong
 * reason to migrate this data to another IndexedDB table (it works fine as it
 * is, really). However we do want to avoid adding more items here.
 */
