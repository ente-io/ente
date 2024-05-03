/// <reference types="chromecast-caf-receiver" />
import { useEffect, useState } from "react";

type Receiver = {
    cast: typeof cast;
};

/**
 * Load the Chromecast Web Receiver SDK and return a reference to the `cast`
 * global object that the SDK attaches to the window.
 */
export const useCastReceiver = () => {
    const [receiver, setReceiver] = useState<Receiver | undefined>();

    useEffect(() => {
        const script = document.createElement("script");
        script.src =
            "https://www.gstatic.com/cast/sdk/libs/caf_receiver/v3/cast_receiver_framework.js";

        script.addEventListener("load", () => setReceiver({ cast }));
        document.body.appendChild(script);
    }, []);

    return receiver;
};
