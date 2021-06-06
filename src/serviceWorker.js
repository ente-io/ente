import { precacheAndRoute } from 'workbox-precaching';
import { registerRoute, setDefaultHandler } from 'workbox-routing';
import { NetworkOnly } from 'workbox-strategies';
import { pageCache, offlineFallback } from 'workbox-recipes';

pageCache();

precacheAndRoute(self.__WB_MANIFEST);

registerRoute('/share-target', async ({ event }) => {
    event.waitUntil(async function() {
        const data = await event.request.formData();
        const client = await self.clients.get(event.resultingClientId || event.clientId);
        const files = data.getAll('files');
        setTimeout(() => {
            client.postMessage({ files, action: 'upload-files' });
        }, 1000);
        console.log(client);
    }());
    return Response.redirect('./');
}, 'POST');

// Use a stale-while-revalidate strategy for all other requests.
setDefaultHandler(new NetworkOnly());

offlineFallback();
