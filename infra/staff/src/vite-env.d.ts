/* Type shims provided by vite, e.g. for asset imports
   https://vitejs.dev/guide/features.html#client-types */

/// <reference types="vite/client" />

/** Types for the vite injected environment variables */
interface ImportMetaEnv {
    /**
     * Override the origin (scheme://host:port) of Ente's API to connect to.
     *
     * Default is "https://api.ente.io".
     */
    readonly VITE_ENTE_API_ORIGIN: string | undefined;
}

interface ImportMeta {
    env: ImportMetaEnv;
}
