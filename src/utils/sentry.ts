import * as Sentry from "@sentry/electron/dist/main";

const SENTRY_DSN="https://e9268b784d1042a7a116f53c58ad2165@sentry.ente.io/5";


function initSentry():void{
Sentry.init({ dsn: SENTRY_DSN});
}

export default initSentry;
