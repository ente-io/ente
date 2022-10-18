import { LOG_FILENAME, MAX_LOG_SIZE } from '../config';
import { webFrame } from 'electron';
import log from 'electron-log';

export const fixHotReloadNext12 = () => {
    webFrame.executeJavaScript(`Object.defineProperty(globalThis, 'WebSocket', {
    value: new Proxy(WebSocket, {
      construct: (Target, [url, protocols]) => {
        if (url.endsWith('/_next/webpack-hmr')) {
          // Fix the Next.js hmr client url
          return new Target("ws://localhost:3000/_next/webpack-hmr", protocols)
        } else {
          return new Target(url, protocols)
        }
      }
    })
  });`);
};

export function isPlatformMac() {
    return process.platform === 'darwin';
}

export function isPlatformWindows() {
    return process.platform === 'win32';
}

export function setupLogging() {
    log.transports.file.fileName = LOG_FILENAME;
    log.transports.file.maxSize = MAX_LOG_SIZE;
    log.transports.console.level = false;
}
