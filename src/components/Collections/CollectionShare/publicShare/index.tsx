import React, { useEffect, useState } from 'react';
import { PublicURL } from 'types/collection';
import { appendCollectionKeyToShareURL } from 'utils/collection';
import PublicShareControl from './control';
import PublicShareLink from './link';
import PublicShareManage from './manage';

export default function PublicShare({ collection }) {
    const [sharableLinkError, setSharableLinkError] = useState(null);
    const [publicShareUrl, setPublicShareUrl] = useState<string>(null);
    const [publicShareProp, setPublicShareProp] = useState<PublicURL>(null);

    useEffect(() => {
        const main = async () => {
            if (collection?.publicURLs?.[0]?.url) {
                const t = await appendCollectionKeyToShareURL(
                    collection?.publicURLs?.[0]?.url,
                    collection.key
                );
                setPublicShareUrl(t);
                setPublicShareProp(collection?.publicURLs?.[0] as PublicURL);
            } else {
                setPublicShareUrl(null);
                setPublicShareProp(null);
            }
        };
        main();
    }, [collection]);

    return (
        <>
            <PublicShareControl
                setPublicShareUrl={setPublicShareUrl}
                collection={collection}
                publicShareUrl={publicShareUrl}
                sharableLinkError={sharableLinkError}
                setSharableLinkError={setSharableLinkError}
            />
            {publicShareUrl && (
                <>
                    <PublicShareLink publicShareUrl={publicShareUrl} />
                    <PublicShareManage
                        publicShareProp={publicShareProp}
                        collection={collection}
                        setPublicShareProp={setPublicShareProp}
                        setSharableLinkError={setSharableLinkError}
                    />
                </>
            )}
        </>
    );
}
