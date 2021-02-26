import * as Comlink from 'comlink';

const CryptoWorker: any =
    typeof window !== 'undefined' &&
    Comlink.wrap(new Worker('worker/crypto.worker.js', { type: 'module' }));

export default CryptoWorker;
