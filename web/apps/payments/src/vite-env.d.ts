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
    /**
     * Override the publishable Stripe key to use when the user's account
     * country is "US".
     *
     * This is useful when testing.
     */
    readonly VITE_STRIPE_US_PUBLISHABLE_KEY: string | undefined;
    /**
     * Override the publishable Stripe key to use when the user's account
     * country is "IN".
     *
     * This is useful when testing.
     */
    readonly VITE_STRIPE_IN_PUBLISHABLE_KEY: string | undefined;
}

interface ImportMeta {
    env: ImportMetaEnv;
}
