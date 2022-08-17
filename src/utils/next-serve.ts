import { webFrame } from 'electron';

// Patch the global WebSocket constructor to use the correct DevServer url
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
