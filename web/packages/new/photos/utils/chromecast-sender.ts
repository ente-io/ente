/// <reference types="chromecast-caf-sender" />

export type Cast = typeof cast;

/**
 * Load the Chromecast script, resolving with the global `cast` object.
 */
export const loadCast = (() => {
    let promise: Promise<Cast> | undefined;

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
