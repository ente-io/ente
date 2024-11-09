import { useModalVisibility } from "@/base/components/utils/modal";
import type { Collection, PublicURL } from "@/media/collection";
import { PublicLinkCreated } from "@/new/photos/components/share/PublicLinkCreated";
import { useEffect, useState } from "react";
import { appendCollectionKeyToShareURL } from "utils/collection";
import EnablePublicShareOptions from "./EnablePublicShareOptions";
import ManagePublicShare from "./managePublicShare";

export default function PublicShare({
    collection,
    onRootClose,
}: {
    collection: Collection;
    onRootClose: () => void;
}) {
    const [publicShareUrl, setPublicShareUrl] = useState<string>(null);
    const [publicShareProp, setPublicShareProp] = useState<PublicURL>(null);
    const {
        show: showPublicLinkCreated,
        props: publicLinkCreatedVisibilityProps,
    } = useModalVisibility();

    useEffect(() => {
        if (collection.publicURLs?.length) {
            setPublicShareProp(collection.publicURLs[0]);
        }
    }, [collection]);

    useEffect(() => {
        if (publicShareProp) {
            const url = appendCollectionKeyToShareURL(
                publicShareProp.url,
                collection.key,
            );
            setPublicShareUrl(url);
        } else {
            setPublicShareUrl(null);
        }
    }, [publicShareProp]);

    const copyToClipboardHelper = () => {
        navigator.clipboard.writeText(publicShareUrl);
    };

    return (
        <>
            {publicShareProp ? (
                <ManagePublicShare
                    publicShareProp={publicShareProp}
                    setPublicShareProp={setPublicShareProp}
                    collection={collection}
                    publicShareUrl={publicShareUrl}
                    onRootClose={onRootClose}
                    copyToClipboardHelper={copyToClipboardHelper}
                />
            ) : (
                <EnablePublicShareOptions
                    setPublicShareProp={setPublicShareProp}
                    collection={collection}
                    onLinkCreated={showPublicLinkCreated}
                />
            )}
            <PublicLinkCreated
                {...publicLinkCreatedVisibilityProps}
                onCopyLink={copyToClipboardHelper}
            />
        </>
    );
}
