import * as Sentry from '@sentry/nextjs';
import { getSentryUserID } from '@ente/shared/sentry/utils';
import { runningInBrowser } from '@ente/shared/platform';
import { getHasOptedOutOfCrashReports } from '@ente/shared/storage/localStorage/helpers';

export const initSentry = async (dsn: string) => {
    const optedOut = runningInBrowser() && getHasOptedOutOfCrashReports();
    if (optedOut) return;

    // [Note: Specifying the Sentry release]
    //
    // Sentry supports automatically deducing the release, and if running the
    // `sentry-cli release propose-version` command directly, it can indeed find
    // and use the git SHA as the release, but I've been unable to get that
    // automated detection to work with the Sentry webpack plugin.
    //
    // The other recommended approach, and what we were using earlier, is
    // specify the release param in the `sentryWebpackPluginOptions` (second)
    // argument to `withSentryConfig`. However, we selectively turn off Sentry
    // to disable sourcemap uploads when the auth token is not available, and
    // Sentry's documentation states that
    //
    // > Disable SentryWebPackPlugin... Note that [when doing so] you'll also
    // > have to explicitly set a `release` value in your `Sentry.init()`.
    //
    // https://docs.sentry.io/platforms/javascript/guides/nextjs/manual-setup/#disable-sentrywebpackplugin
    //
    // So we just keep things simple and always specify the release here (and
    // only here).
    const release = process.env.GIT_SHA;

    Sentry.init({
        dsn,
        release,
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
