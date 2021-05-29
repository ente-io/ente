import {precacheAndRoute} from 'workbox-precaching';
import {setDefaultHandler} from 'workbox-routing';
import {NetworkOnly} from 'workbox-strategies';
import {pageCache, offlineFallback} from 'workbox-recipes';

pageCache();

precacheAndRoute(self.__WB_MANIFEST);

// Use a stale-while-revalidate strategy for all other requests.
setDefaultHandler(new NetworkOnly());

offlineFallback();
