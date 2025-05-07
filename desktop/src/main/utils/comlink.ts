import type { Endpoint } from "comlink";
import type { MessagePortMain } from "electron";

/**
 * An adaptation of the `nodeEndpoint` function from comlink suitable for use in
 * TypeScript with an Electron utility process.
 *
 * This is an adaption of the following function from comlink:
 * https://github.com/GoogleChromeLabs/comlink/blob/main/src/node-adapter.ts
 *
 * It has been modified (somewhat hackily) to be useful with an Electron
 * MessagePortMain instead of a Node.js worker_thread. Only things that we
 * currently need have been made to work as you can see by the abundant type
 * casts. Caveat emptor.
 */
export const messagePortMainEndpoint = (mp: MessagePortMain): Endpoint => {
    type NL = EventListenerOrEventListenerObject;
    type EL = (data: Electron.MessageEvent) => void;
    const listeners = new WeakMap<NL, EL>();
    return {
        postMessage: (message, transfer) => {
            mp.postMessage(message, (transfer ?? []) as MessagePortMain[]);
        },
        addEventListener: (_, eh) => {
            const l: EL = (data) =>
                "handleEvent" in eh
                    ? eh.handleEvent({ data } as MessageEvent)
                    : eh(data as unknown as MessageEvent);
            mp.on("message", (data) => {
                l(data);
            });
            listeners.set(eh, l);
        },
        removeEventListener: (_, eh) => {
            const l = listeners.get(eh);
            if (!l) return;
            mp.off("message", l);
            listeners.delete(eh);
        },
        start: mp.start.bind(mp),
    };
};
