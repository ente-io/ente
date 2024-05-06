/// <reference types="chromecast-caf-receiver" />

export type Cast = typeof cast;

let _cast: Cast | undefined;
let _loader: Promise<Cast> | undefined;

/**
 * Load the Chromecast Web Receiver SDK and return a reference to the `cast`
 * global object that the SDK attaches to the window.
 *
 * Calling this function multiple times is fine, once the Chromecast SDK is
 * loaded it'll thereafter return the reference to the same object always.
 *
 * https://developers.google.com/cast/docs/web_receiver/basic
 */
export const castReceiverLoadingIfNeeded = async (): Promise<Cast> => {
    if (_cast) return _cast;
    if (_loader) return await _loader;

    _loader = new Promise((resolve) => {
        const script = document.createElement("script");
        script.src =
            "https://www.gstatic.com/cast/sdk/libs/caf_receiver/v3/cast_receiver_framework.js";

        script.addEventListener("load", () => resolve(cast));
        document.body.appendChild(script);
    });
    const c = await _loader;
    _cast = c;
    return c;
};
