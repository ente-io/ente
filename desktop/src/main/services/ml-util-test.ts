/**
 * [Note: Using Electron APIs in UtilityProcess]
 *
 * Only a small subset of the Electron APIs are available to a UtilityProcess.
 * As of writing (Jul 2024, Electron 30), only the following are available:
 * - net
 * - systemPreferences
 *
 * In particular, `app` is not available.
 *
 * We structure our code so that it doesn't need anything apart from `net`.
 */

// import log from "../log";
import { ensure, wait } from "../utils/common";

const log = {
    info: (...ms: unknown[]) => console.log(...ms),
    debug: (fn: () => unknown) => console.log(fn()),
};

log.debug(() => "Started ML worker process");

process.parentPort.once("message", (e) => {
    const port = ensure(e.ports[0]);
    port.on("message", (event) => {
        void handleMessage(event.data).then((response) => {
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
const handleMessage = async (m: unknown) => {
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
