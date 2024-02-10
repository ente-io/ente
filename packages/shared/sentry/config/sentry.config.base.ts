import * as Sentry from '@sentry/nextjs';
import { getSentryUserID } from '@ente/shared/sentry/utils';
import { runningInBrowser } from '@ente/shared/platform';
import { getHasOptedOutOfCrashReports } from '@ente/shared/storage/localStorage/helpers';

export const setupSentry = async (dsn: string) => {
    const optedOut = runningInBrowser() && getHasOptedOutOfCrashReports();
    if (optedOut) return;

    Sentry.init({
        dsn,
        environment: process.env.NODE_ENV,
        attachStacktrace: true,
        autoSessionTracking: false,
        tunnel: 'https://sentry-reporter.ente.io',
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
    });

    Sentry.setUser({ id: await getSentryUserID() });
};
