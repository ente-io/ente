import { useEffect, useState } from "react";
import { Collection, PublicURL } from "types/collection";
import { appendCollectionKeyToShareURL } from "utils/collection";
import EnablePublicShareOptions from "./EnablePublicShareOptions";
import CopyLinkModal from "./copyLinkModal";
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
    const [copyLinkModalView, setCopyLinkModalView] = useState(false);

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
        handleCancel();
    };
    const handleCancel = () => {
        setCopyLinkModalView(false);
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
                    setCopyLinkModalView={setCopyLinkModalView}
                />
            )}
            <CopyLinkModal
                open={copyLinkModalView}
                onClose={handleCancel}
                handleCancel={handleCancel}
                copyToClipboardHelper={copyToClipboardHelper}
            />
        </>
    );
}
