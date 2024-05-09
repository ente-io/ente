/// <reference types="chromecast-caf-receiver" />

export type Cast = typeof cast;

/**
 * A holder for the "cast" global object exposed by the Chromecast SDK,
 * alongwith auxiliary state we need around it.
 */
class CastReceiver {
    /**
     * A reference to the `cast` global object that the Chromecast Web Receiver
     * SDK attaches to the window.
     *
     * https://developers.google.com/cast/docs/web_receiver/basic
     */
    cast: Cast | undefined;
    loader: Promise<Cast> | undefined;
}

const castReceiver = new CastReceiver();

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
    if (castReceiver.cast) return castReceiver.cast;
    if (castReceiver.loader) return await castReceiver.loader;

    castReceiver.loader = new Promise((resolve) => {
        const script = document.createElement("script");
        script.src =
            "https://www.gstatic.com/cast/sdk/libs/caf_receiver/v3/cast_receiver_framework.js";

        castReceiver.cast = cast;
        script.addEventListener("load", () => resolve(cast));
        document.body.appendChild(script);
    });

    return await castReceiver.loader;
};
