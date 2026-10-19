import type { RemotePullOpts } from "@/components/gallery";
import { isMuseumHTTPError } from "ente-base/http";
import log from "ente-base/log";
import {
    CollectionSubType,
    type Collection,
    type PublicURL,
} from "ente-media/collection";
import {
    deleteCollection,
    deleteShareURL,
    updateCollectionLayout,
    updatePublicURL,
    type UpdatePublicURLAttributes,
} from "ente-new/photos/services/collection";
import { t } from "i18next";
import { useEffect, useRef, useState } from "react";

interface PublicLinkManagementProps {
    collection: Collection;
    setPublicURL: (url: PublicURL | undefined) => void;
    setBlockingLoad?: (value: boolean) => void;
    onRemotePull: (opts?: RemotePullOpts) => Promise<void>;
    onRemove: (isQuickLink: boolean) => void;
    onLinkRemoved?: (collectionID: number) => void;
}

/** One mutation at a time, scoped to the mounted collection's settings. */
export const usePublicLinkManagement = ({
    collection,
    setPublicURL,
    setBlockingLoad,
    onRemotePull,
    onRemove,
    onLinkRemoved,
}: PublicLinkManagementProps) => {
    const [isSaving, setIsSaving] = useState(false);
    const [errorMessage, setErrorMessage] = useState("");
    const inFlight = useRef(false);
    const mounted = useRef(true);
    useEffect(() => {
        mounted.current = true;
        return () => {
            mounted.current = false;
        };
    }, []);

    const isMounted = () => mounted.current;

    const mutate = async (operation: () => Promise<void>) => {
        if (inFlight.current || !mounted.current) return false;
        inFlight.current = true;
        setIsSaving(true);
        setErrorMessage("");
        setBlockingLoad?.(true);
        try {
            await operation();
            // A failed refresh must not turn a successful mutation into a failure.
            void onRemotePull({ silent: true }).catch((e: unknown) =>
                log.error("Could not refresh public link settings", e),
            );
            return true;
        } catch (e) {
            log.error("Could not change public link settings", e);
            const restricted = await isMuseumHTTPError(
                e,
                403,
                "LINK_EDIT_NOT_ALLOWED",
            );
            if (isMounted()) {
                setErrorMessage(
                    t(
                        restricted
                            ? "link_edit_disabled_for_free_accounts"
                            : "generic_error",
                    ),
                );
            }
            return false;
        } finally {
            inFlight.current = false;
            if (isMounted()) setIsSaving(false);
            setBlockingLoad?.(false);
        }
    };

    const onUpdate = (updates: UpdatePublicURLAttributes) =>
        mutate(async () => {
            const result = await updatePublicURL(collection.id, updates);
            if (isMounted()) setPublicURL(result);
        });

    const onUpdateLayout = (layout: string) =>
        mutate(async () => {
            await updateCollectionLayout(collection, layout);
        });

    const onRemoveLink = () =>
        mutate(async () => {
            const isQuickLink =
                collection.magicMetadata?.data.subType ===
                    CollectionSubType.quicklink &&
                collection.sharees.length === 0;
            if (isQuickLink) {
                await deleteCollection(collection.id, { keepFiles: true });
            } else {
                await deleteShareURL(collection.id);
            }
            onLinkRemoved?.(collection.id);
            if (isMounted()) {
                setPublicURL(undefined);
                onRemove(isQuickLink);
            }
        });

    return { isSaving, errorMessage, onUpdate, onUpdateLayout, onRemoveLink };
};
