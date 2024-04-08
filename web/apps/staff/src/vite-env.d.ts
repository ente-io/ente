/* Type shims provided by vite, e.g. for asset imports
   https://vitejs.dev/guide/features.html#client-types */

/// <reference types="vite/client" />

/** Types for the vite injected environment variables */
interface ImportMetaEnv {
    /**
     * Override the origin (scheme://host:port) of Ente's API to connect to.
     *
     * This is useful when testing or connecting to alternative installations.
     */
    readonly VITE_ENTE_ENDPOINT: string | undefined;
}

interface ImportMeta {
    env: ImportMetaEnv;
}
