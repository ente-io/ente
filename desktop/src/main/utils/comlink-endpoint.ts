import type { Endpoint } from "comlink";
import type { MessagePortMain } from "electron";

/**
 * An adaptation of the `nodeEndpoint` function from comlink suitable for use in
 * TypeScript with an Electron utility process.
 *
 * This is an adaption of the 
 *
 * Comlink provides a `nodeEndpoint` [function][1] to allow a Node worker_thread
 * to be treated as an {@link Endpoint} and be used with comlink.
 *
 * The first issue we run into when using it is that this the function is not
 * exported as part of the normal comlink.d.ts. Accessing it via this
 * [workaround][2] doesn't work for us either since we cannot currently change
 * our package type to "module".
 *
 * We could skirt around that by doing
 *
 *     const nodeEndpoint = require("comlink/dist/umd/node-adapter");
 *
 * and silencing tsc and eslint. However, we then run into a different issue:
 * the comlink implementation of the adapter adds an extra layer of nesting.
 * This line:
 *
 *       eh({ data } as MessageEvent);
 *
 * Should be
 *
 *       eh(data)
 *
 * I don't currently know if it is because of an impedance mismatch between
 * Node's worker_threads and Electron's UtilityProcesses, or if it is something
 * else that I'm doing wrong somewhere else causing this to happen.
 *
 * To solve both these issues, we create this variant. This also removes the
 * need for us to type cast when passing MessagePortMain.
 *
 * References:
 * 1. https://github.com/GoogleChromeLabs/comlink/blob/main/src/node-adapter.ts
 * 2. https://github.com/GoogleChromeLabs/comlink/pull/542
 * 3. https://github.com/GoogleChromeLabs/comlink/issues/129
 */
export const messagePortMainEndpoint = (mp: MessagePortMain): Endpoint => {
    const listeners = new WeakMap();
    return {
        postMessage: mp.postMessage.bind(mp),
        addEventListener: (_, eh) => {
            const l = (data: Electron.MessageEvent) =>
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
