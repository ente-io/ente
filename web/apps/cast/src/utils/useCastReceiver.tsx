/// <reference types="chromecast-caf-receiver" />
import { useEffect, useState } from "react";

type Receiver = {
    cast: typeof cast;
};

export const useCastReceiver = () => {
    const [receiver, setReceiver] = useState<Receiver | null>({
        cast: null,
    });

    useEffect(() => {
        const script = document.createElement("script");
        script.src =
            "https://www.gstatic.com/cast/sdk/libs/caf_receiver/v3/cast_receiver_framework.js";

        script.addEventListener("load", () => {
            setReceiver({
                cast,
            });
        });
        document.body.appendChild(script);
    }, []);

    return receiver;
};
