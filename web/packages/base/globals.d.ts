interface ErrorConstructor {
    /**
     * V8 stack trace hook available in Chromium-derived browsers and Electron.
     */
    captureStackTrace?(targetObject: object, constructorOpt?: unknown): void;
}

/**
 * Build-time `process.env.*` replacements available to our browser bundles.
 */
declare const process: {
    readonly env: {
        readonly NODE_ENV: "development" | "production" | "test";
        readonly NEXT_PUBLIC_ENTE_ENDPOINT?: string;
        readonly NEXT_PUBLIC_ENTE_TRACE?: string;
        readonly appName: string;
        readonly desktopAppVersion?: string;
        readonly gitSHA?: string;
        readonly isDesktop: "" | "1";
    };
};
