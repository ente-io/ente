import * as Sentry from '@sentry/nextjs';
import { getSentryTunnelURL } from '@ente/shared/network/api';
import { getSentryUserID } from '@ente/shared/sentry/utils';
import { runningInBrowser } from '@ente/shared/platform';
import { getHasOptedOutOfCrashReports } from '@ente/shared/storage/localStorage/helpers';
import { getIsSentryEnabled } from '@ente/shared/sentry/utils';
import {
    getAppEnv,
    getSentryDSN,
    getSentryRelease,
} from '@ente/shared/apps/env';

export const setupSentry = async (DEFAULT_SENTRY_DSN: string) => {
    const HAS_OPTED_OUT_OF_CRASH_REPORTING =
        runningInBrowser() && getHasOptedOutOfCrashReports();

    if (!HAS_OPTED_OUT_OF_CRASH_REPORTING) {
        const SENTRY_DSN = getSentryDSN() ?? DEFAULT_SENTRY_DSN;
        const APP_ENV = getAppEnv();
        const IS_ENABLED = getIsSentryEnabled();
        const SENTRY_RELEASE = getSentryRelease();

        Sentry.init({
            dsn: SENTRY_DSN,
            enabled: IS_ENABLED,
            environment: APP_ENV,
            release: SENTRY_RELEASE,
            attachStacktrace: true,
            autoSessionTracking: false,
            tunnel: getSentryTunnelURL(),
            beforeSend(event) {
                event.request = event.request || {};
                const currentURL = new URL(document.location.href);
                currentURL.hash = '';
                event.request.url = currentURL.href;
                return event;
            },
            integrations: function (i) {
                return i.filter(function (i) {
                    return i.name !== 'Breadcrumbs';
                });
            },
            // ...
            // Note: if you want to override the automatic release value, do not set a
            // `release` value here - use the environment variable `SENTRY_RELEASE`, so
            // that it will also get attached to your source maps
        });

        Sentry.setUser({ id: await getSentryUserID() });
    }
};
