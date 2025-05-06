import type { Electron, UtilityProcessType } from "ente-base/types/ipc";

/**
 * Obtain a port from the Node.js layer that can be used to communicate with the
 * native utility process of type {@link type}.
 */
export const createUtilityProcess = (
    electron: Electron,
    type: UtilityProcessType,
): Promise<MessagePort> => {
    // The main process will do its thing, and send back the port it created to
    // us by sending an message on the "utilityProcessPort/<type>" channel via
    // the postMessage API. This roundabout way is needed because MessagePorts
    // cannot be transferred via the usual send/invoke pattern.

    const portEvent = `utilityProcessPort/${type}`;

    const port = new Promise<MessagePort>((resolve) => {
        const l = ({ source, data, ports }: MessageEvent) => {
            // The source check verifies that the message is coming from our own
            // preload script. The data is the message that was posted.
            if (source == window && data == portEvent) {
                window.removeEventListener("message", l);
                resolve(ports[0]!);
            }
        };
        window.addEventListener("message", l);
    });

    electron.triggerCreateUtilityProcess(type);

    return port;
};
