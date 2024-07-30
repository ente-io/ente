import log from "../log";
import { ensure, wait } from "../utils/common";

log.debug(() => "Started ML worker process");

process.parentPort.once("message", (e) => {
    const port = ensure(e.ports[0]);
    port.on("message", (event) => {
        void handleMessage(event.data).then((response) => {
            if (response) port.postMessage(response);
        });
    });
});

/** Our hand-rolled IPC handler and router */
const handleMessage = async (m: unknown) => {
    if (m && typeof m == "object" && "type" in m) {
        switch (m.type) {
            case "foo":
                if ("a" in m && typeof m.a == "string") return await foo(m.a);
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
