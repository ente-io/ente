import * as Comlink from 'comlink';
import { runningInBrowser } from 'utils/common/utilFunctions';

const CryptoWorker: any =
    runningInBrowser() &&
    Comlink.wrap(new Worker('worker/crypto.worker.js', { type: 'module' }));

export default CryptoWorker;
