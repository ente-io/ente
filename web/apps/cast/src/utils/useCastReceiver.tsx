/// <reference types="chromecast-caf-receiver" />
import { useEffect, useState } from "react";

/**
 * Load the Chromecast Web Receiver SDK and return a reference to the `cast`
 * global object that the SDK attaches to the window.
 *
 * https://developers.google.com/cast/docs/web_receiver/basic
 */
export const useCastReceiver = () => {
    const [receiver, setReceiver] = useState<typeof cast | undefined>();

    useEffect(() => {
        const script = document.createElement("script");
        script.src =
            "https://www.gstatic.com/cast/sdk/libs/caf_receiver/v3/cast_receiver_framework.js";

        script.addEventListener("load", () => setReceiver(cast));
        document.body.appendChild(script);
    }, []);

    return receiver;
};
