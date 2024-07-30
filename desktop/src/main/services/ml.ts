/**
 * @file ML related functionality. This code runs in the main process.
 */

import { MessageChannelMain, type BrowserWindow } from "electron";
import { utilityProcess } from "electron/main";
import path from "node:path";

/**
 * Create a new ML worker process.
 *
 * [Note: ML IPC]
 *
 * The primary reason for doing ML tasks in the Node.js layer is so that we can
 * use the binary ONNX runtime, which is 10-20x faster than the WASM one that
 * can be used directly on the web layer.
 *
 * For this to work, the main and renderer process need to communicate with each
 * other. Further, in the web layer the ML indexing runs in a web worker (so as
 * to not get in the way of the main thread). So the communication has 2 hops:
 *
 *     Node.js main <-> Renderer main <-> Renderer web worker
 *
 * This naive way works, but has a problem. The Node.js main process is in the
 * code path for delivering user events to the renderer process. The ML tasks we
 * do take in the order of 100-300 ms (possibly more) for each individual
 * inference. Thus, the Node.js main process is busy for those 100-300 ms, and
 * does not forward events to the renderer, causing the UI to jitter.
 *
 * The solution for this is to spawn an Electron UtilityProcess, which we can
 * think of a regular Node.js child process.  This frees up the Node.js main
 * process, and would remove the jitter.
 * https://www.electronjs.org/docs/latest/tutorial/process-model
 *
 * It would seem that this introduces another hop in our IPC
 *
 *     Node.js utility process <-> Node.js main <-> ...
 *
 * but here we can use the special bit about Electron utility processes that
 * separates them from regular Node.js child processes: their support for
 * message ports. https://www.electronjs.org/docs/latest/tutorial/message-ports
 *
 * As a brief summary, a MessagePort is a web feature that allows two contexts
 * to communicate. A pair of message ports is called a message channel. The cool
 * thing about these is that we can pass these ports themselves over IPC.
 *
 * > One caveat here is that the message ports can only be passed using the
 * > `postMessage` APIs, not the usual send/invoke APIs.
 *
 * So we
 *
 * 1.  In the utility process create a message channel.
 * 2.  Spawn a utility process, and send one port of the pair to it.
 * 3.  Send the other port of the pair to the renderer.
 *
 * The renderer will forward that port to the web worker that is coordinating
 * the ML indexing on the web layer. Thereafter, the utility process and web
 * worker can directly talk to each other!
 *
 *     Node.js utility process <-> Renderer web worker
 *
 */
export const createMLWorker = (window: BrowserWindow) => {
    const { port1, port2 } = new MessageChannelMain();

    const child = utilityProcess.fork(path.join(__dirname, "ml-util-test.js"));
    child.postMessage(undefined, [port1]);

    window.webContents.postMessage("createMLWorker/port", undefined, [port2]);
};
