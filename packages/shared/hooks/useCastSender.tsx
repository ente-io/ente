declare const chrome: any;
declare const cast: any;

declare global {
    interface Window {
        __onGCastApiAvailable: (isAvailable: boolean) => void;
    }
}

import { useEffect, useState } from 'react';

type Sender = {
    chrome: typeof chrome;
    cast: typeof cast;
};

const load = (() => {
    let promise: Promise<Sender> | null = null;

    return () => {
        if (promise === null) {
            promise = new Promise((resolve) => {
                const script = document.createElement('script');
                script.src =
                    'https://www.gstatic.com/cv/js/sender/v1/cast_sender.js?loadCastFramework=1';
                window.__onGCastApiAvailable = (isAvailable) => {
                    if (isAvailable) {
                        resolve({
                            chrome,
                            cast,
                        });
                    }
                };
                document.body.appendChild(script);
            });
        }
        return promise;
    };
})();

export const useCastSender = () => {
    const [sender, setSender] = useState<Sender | { chrome: null; cast: null }>(
        {
            chrome: null,
            cast: null,
        }
    );

    useEffect(() => {
        load().then((sender) => {
            setSender(sender);
        });
    }, []);

    return sender;
};
