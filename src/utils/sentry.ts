import * as Sentry from "@sentry/electron/dist/main";

const SENTRY_DSN="https://e9268b784d1042a7a116f53c58ad2165@sentry.ente.io/5";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const version =require('../../package.json').version;

function initSentry():void{
Sentry.init({ dsn: SENTRY_DSN,release:version});
}

export default initSentry;
