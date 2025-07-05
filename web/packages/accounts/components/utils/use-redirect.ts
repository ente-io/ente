import { haveMasterKeyInSession } from "ente-base/session";
import { useRouter } from "next/router";
import { useEffect } from "react";
import { stashRedirect } from "../../services/redirect";

/**
 * Redirect to the appropriate credential step (password reverify, or a full
 * login) and then back to the current page if the user's master key is not
 * present in the session storage.
 *
 * @param currentPageSlug The slug for the current page where this hook is being
 * used. If a redirect happens, then this slug will be stashed and used to
 * redirect back here after the credentials have been obtained.
 */
export const useRedirectIfNeedsCredentials = (currentPageSlug: string) => {
    const router = useRouter();

    useEffect(() => {
        if (!haveMasterKeyInSession()) {
            stashRedirect(currentPageSlug);
            void router.push("/");
        }
    }, [router]);
};
