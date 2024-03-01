import { isDevBuild } from "@/utils/env";
import { runningInBrowser } from "@ente/shared/platform";
import { getSentryUserID } from "@ente/shared/sentry/utils";
import { getHasOptedOutOfCrashReports } from "@ente/shared/storage/localStorage/helpers";
import * as Sentry from "@sentry/nextjs";

export const initSentry = async (dsn: string) => {
    // Don't initialize Sentry for dev builds
    if (isDevBuild) return;

    // Don't initialize Sentry if the user has opted out of crash reporting
    if (optedOut()) return;

    Sentry.init({
        dsn,
        release: process.env.GIT_SHA,
        attachStacktrace: true,
        autoSessionTracking: false,
        tunnel: "https://sentry-reporter.ente.io",
        beforeSend(event) {
            event.request = event.request || {};
            const currentURL = new URL(document.location.href);
            currentURL.hash = "";
            event.request.url = currentURL.href;
            return event;
        },
        integrations: function (i) {
            return i.filter(function (i) {
                return i.name !== "Breadcrumbs";
            });
        },
    });

    Sentry.setUser({ id: await getSentryUserID() });
};

/** Return true if the user has opted out of crash reporting */
const optedOut = () => runningInBrowser() && getHasOptedOutOfCrashReports();
