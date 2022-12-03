import { webFrame } from 'electron';

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

export function isPlatform(platform: 'mac' | 'windows' | 'linux') {
    if (process.platform === 'darwin') {
        return platform === 'mac';
    } else if (process.platform === 'win32') {
        return platform === 'windows';
    } else if (process.platform === 'linux') {
        return platform === 'linux';
    } else {
        return false;
    }
}
