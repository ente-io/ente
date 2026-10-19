import log from "ente-base/log";
import { appendCollectionKeyToShareURL } from "ente-gallery/services/share";
import type { Collection, PublicURL } from "ente-media/collection";
import { useSettingsSnapshot } from "ente-new/photos/components/utils/use-snapshot";
import { useEffect, useState } from "react";

/** Resolve the share URL without displaying another collection's key or domain. */
export const useResolvedPublicLinkURL = (
    collection: Collection,
    publicURL: PublicURL | undefined,
    canManage: boolean,
) => {
    const { customDomain } = useSettingsSnapshot();
    const domain = canManage ? customDomain : undefined;
    const url = publicURL?.url;
    const key = collection.key;
    const [resolved, setResolved] = useState<{
        url: string;
        key: string;
        domain: string | undefined;
        value: string;
    }>();

    useEffect(() => {
        if (!url) return;
        let cancelled = false;
        void appendCollectionKeyToShareURL(url, key)
            .then((value) => {
                if (cancelled) return;
                if (domain) {
                    const customURL = new URL(value);
                    customURL.host = domain;
                    value = customURL.href;
                }
                setResolved({ url, key, domain, value });
            })
            .catch((e: unknown) =>
                log.error("Could not resolve public link", e),
            );
        return () => {
            cancelled = true;
        };
    }, [url, key, domain]);

    return resolved &&
        resolved.url === url &&
        resolved.key === key &&
        resolved.domain === domain
        ? resolved.value
        : undefined;
};
