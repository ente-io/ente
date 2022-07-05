import React, { useEffect, useState } from 'react';
import { Collection, PublicURL } from 'types/collection';
import { appendCollectionKeyToShareURL } from 'utils/collection';
import PublicShareControl from './control';
import PublicShareLink from './link';
import PublicShareManage from './manage';

export default function PublicShare({
    collection,
}: {
    collection: Collection;
}) {
    const [publicShareUrl, setPublicShareUrl] = useState<string>(null);
    const [publicShareProp, setPublicShareProp] = useState<PublicURL>(null);

    useEffect(() => {
        if (collection.publicURLs?.length) {
            setPublicShareProp(collection.publicURLs[0]);
        }
    }, [collection]);

    useEffect(() => {
        if (publicShareProp) {
            const url = appendCollectionKeyToShareURL(
                publicShareProp.url,
                collection.key
            );
            setPublicShareUrl(url);
        } else {
            setPublicShareUrl(null);
        }
    }, [publicShareProp]);

    return (
        <>
            <PublicShareControl
                setPublicShareProp={setPublicShareProp}
                collection={collection}
                publicShareActive={!!publicShareProp}
            />
            {publicShareProp && (
                <>
                    <PublicShareLink publicShareUrl={publicShareUrl} />

                    <PublicShareManage
                        publicShareProp={publicShareProp}
                        collection={collection}
                        setPublicShareProp={setPublicShareProp}
                    />
                </>
            )}
        </>
    );
}
