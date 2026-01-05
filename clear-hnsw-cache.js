// Run this in browser console to clear HNSW cache
async function clearHNSWCache() {
    const { openDB } = await import('idb');
    const db = await openDB('ml', 3);
    await db.clear('hnsw-index-metadata');
    console.log('✓ Cleared HNSW metadata');
    
    // Also clear IDBFS
    const idbfsDB = await openDB('FILE_DATA', 1);
    await idbfsDB.clear('FILE_DATA');
    console.log('✓ Cleared IDBFS');
    
    console.log('Cache cleared! Reload the page to rebuild index from scratch.');
}

clearHNSWCache();
