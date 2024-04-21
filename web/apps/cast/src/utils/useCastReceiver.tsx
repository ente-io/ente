declare const cast: any;

import { useEffect, useState } from "react";

type Receiver = {
    cast: typeof cast;
};

const load = (() => {
    let promise: Promise<Receiver> | null = null;

    return () => {
        if (promise === null) {
            promise = new Promise((resolve) => {
                const script = document.createElement("script");
                script.src =
                    "https://www.gstatic.com/cast/sdk/libs/caf_receiver/v3/cast_receiver_framework.js";

                script.addEventListener("load", () => {
                    resolve({
                        cast,
                    });
                });

                document.body.appendChild(script);
                const debugScript = document.createElement("script");
                debugScript.src =
                    "https://www.gstatic.com/cast/sdk/libs/devtools/debug_layer/caf_receiver_logger.js";
                debugScript.addEventListener("load", () => {
                    console.log("debug script loaded");
                });
                document.body.appendChild(debugScript);
            });
        }
        return promise;
    };
})();

export const useCastReceiver = () => {
    const [receiver, setReceiver] = useState<Receiver | null>({
        cast: null,
    });

    useEffect(() => {
        load().then((receiver) => {
            setReceiver(receiver);
        });
    });

    return receiver;
};
