//
import { ensure, wait } from "../utils/common";

/**
 * We cannot do
 *
 *     import log from "../log";
 *
 * because that requires the Electron APIs that are not available to a utility
 * process (See: [Note: Using Electron APIs in UtilityProcess]). But even if
 * that were to work, logging will still be problematic since we'd try opening
 * the log file from two different Node.js processes (this one, and the main
 * one), and I didn't find any indication in the electron-log repository that
 * the log file's integrity would be maintained in such cases.
 *
 * So instead we create this proxy log object that uses `process.parentPort` to
 * transport the logs over to the main process.
 */
const log = {
    info: (...ms: unknown[]) => mainProcess("log.info", ms),
    debug: (fn: () => unknown) => console.log(fn()),
};

/**
 * Send a message to the main process using a barebones protocol.
 */
const mainProcess = (method: string, params: unknown[]) => {
    process.parentPort.postMessage({ method, params });
};

log.debug(() => "Started ML worker process");

process.parentPort.once("message", (e) => {
    const port = ensure(e.ports[0]);
    port.on("message", (event) => {
        void handleMessageFromRenderer(event.data).then((response) => {
            if (response) port.postMessage(response);
        });
    });
    port.start();
});

/**
 * Our hand-rolled IPC handler and router - the Node.js utility process end.
 *
 * Sibling of the electronMLWorker function (in `ml/worker.ts`) in the web code.
 */
const handleMessageFromRenderer = async (m: unknown) => {
    if (m && typeof m == "object" && "type" in m && "id" in m) {
        const id = m.id;
        switch (m.type) {
            case "foo":
                if ("data" in m && typeof m.data == "string")
                    return { id, data: await foo(m.data) };
                break;
        }
    }

    log.info("Ignoring unexpected message", m);
    return undefined;
};

const foo = async (a: string) => {
    console.log("got message foo with argument", a);
    await wait(0);
    return a.length;
};
