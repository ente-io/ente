// See [Note: Using Electron APIs in UtilityProcess] about what we can and
// cannot import.

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
    /**
     * Unlike the real {@link log.error}, this accepts only the first string
     * argument, not the second optional error one.
     */
    errorString: (s: string) => mainProcess("log.errorString", s),
    info: (...ms: unknown[]) => mainProcess("log.info", ms),
    /**
     * Unlike the real {@link log.debug}, this is (a) eagerly evaluated, and (b)
     * accepts only strings.
     */
    debugString: (s: string) => mainProcess("log.debugString", s),
};

/**
 * Send a message to the main process using a barebones protocol.
 */
const mainProcess = (method: string, param: unknown) =>
    process.parentPort.postMessage({ method, p: param });

log.debugString(
    `Started ML worker process with args ${process.argv.join(" ")}`,
);

process.parentPort.once("message", (e) => {
    parseInitData(e.data);

    const port = ensure(e.ports[0]);
    port.on("message", (request) => {
        void handleMessageFromRenderer(request.data).then((response) =>
            port.postMessage(response),
        );
    });
    port.start();
});

/**
 * We cannot access Electron's {@link app} object within a utility process, so
 * we pass the value of `app.getPath("userData")` during initialization, and it
 * can be subsequently retrieved from here.
 */
let _userDataPath: string | undefined;

/** Equivalent to app.getPath("userData") */
const userDataPath = () => ensure(_userDataPath);

const parseInitData = (data: unknown) => {
    if (
        data &&
        typeof data == "object" &&
        "userDataPateh" in data &&
        "userDataPath" in data &&
        typeof data.userDataPath == "string"
    ) {
        _userDataPath = data.userDataPath;
    } else {
        log.errorString("Unparseable initialization data");
    }
};

/**
 * Our hand-rolled RPC handler and router - the Node.js utility process end.
 *
 * Sibling of the electronMLWorker function (in `ml/worker.ts`) in the web code.
 *
 * [Note: Node.js ML worker RPC protocol]
 *
 * -   Each RPC call (i.e. request message) has a "method" (string), "id"
 *     (number) and "p" (arbitrary param).
 *
 * -   Each RPC result (i.e. response message) has an "id" (number) that is the
 *     same as the "id" for the request which it corresponds to.
 *
 * -   If the RPC call was a success, then the response messege will have an
 *     "result" (arbitrary result) property. Otherwise it will have a "error"
 *     (string) property describing what went wrong.
 */
const handleMessageFromRenderer = async (m: unknown) => {
    if (m && typeof m == "object" && "method" in m && "id" in m && "p" in m) {
        const id = m.id;
        const p = m.p;
        try {
            switch (m.method) {
                case "foo":
                    if (p && typeof p == "string")
                        return { id, result: await foo(p) };
                    break;
            }
        } catch (e) {
            return { id, error: e instanceof Error ? e.message : String(e) };
        }
        return { id, error: "Unknown message" };
    }

    // We don't even have an "id", so at least log it lest the renderer also
    // ignore the "id"-less response.
    log.info("Ignoring unknown message", m);
    return { error: "Unknown message" };
};

const foo = async (a: string) => {
    log.info("got message foo with argument", a, userDataPath());
    await wait(0);
    return a.length;
};
