/* eslint-disable @typescript-eslint/no-namespace */
/**
 * The types for the sender are already available as
 * "@types/chromecast-caf-sender", however installing them breaks the types for
 * the cast receiver in apps/cast. Vice-versa, having those types for the
 * receiver ("@types/chromecast-caf-receiver") conflicts with the types that we
 * add for the sender.
 *
 * As a workaround, this file includes the handpicked interface from
 * "@types/chromecast-caf-sender" for only the parts that we use.
 */

declare global {
    interface Window {
        cast: typeof cast;
        __onGCastApiAvailable(available: boolean, reason?: string): void;
    }
}

declare namespace chrome.cast {
    /**
     * @see https://developers.google.com/cast/docs/reference/chrome/chrome.cast#.AutoJoinPolicy
     */
    export enum AutoJoinPolicy {
        ORIGIN_SCOPED = "origin_scoped",
    }
}

/**
 * Cast Application Framework
 * @see https://developers.google.com/cast/docs/reference/chrome/cast.framework
 */
declare namespace cast.framework {
    interface CastOptions {
        autoJoinPolicy: chrome.cast.AutoJoinPolicy;
        receiverApplicationId?: string | undefined;
    }

    class CastContext {
        static getInstance(): CastContext;
        setOptions(options: CastOptions): void;
        requestSession(): Promise<unknown>;
        getCurrentSession(): CastSession | null;
    }

    class CastSession {
        sendMessage(namespace: string, data: unknown): Promise<unknown>;
        addMessageListener(
            namespace: string,
            listener: (namespace: string, message: string) => void,
        ): void;
    }
}

/**
 * Load the Chromecast script, resolving with the global `cast` object.
 */
export const loadCast = (() => {
    let promise: Promise<typeof cast> | undefined;

    return () => {
        if (promise === undefined) {
            promise = new Promise((resolve) => {
                const script = document.createElement("script");
                script.src =
                    "https://www.gstatic.com/cv/js/sender/v1/cast_sender.js?loadCastFramework=1";
                window.__onGCastApiAvailable = (isAvailable) => {
                    if (isAvailable) {
                        cast.framework.CastContext.getInstance().setOptions({
                            receiverApplicationId: "F5BCEC64",
                            autoJoinPolicy:
                                chrome.cast.AutoJoinPolicy.ORIGIN_SCOPED,
                        });

                        resolve(cast);
                    }
                };
                document.body.appendChild(script);
            });
        }
        return promise;
    };
})();
