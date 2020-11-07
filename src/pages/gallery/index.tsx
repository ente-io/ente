import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import Spinner from 'react-bootstrap/Spinner';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { file, getFiles } from 'services/fileService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import PreviewCard from './components/PreviewCard';
import { getActualKey } from 'utils/common/key';
import styled from 'styled-components';
import { PhotoSwipeGallery } from 'react-photoswipe';
import InfiniteLoader from 'react-window-infinite-loader';
import { FixedSizeGrid as Grid } from 'react-window';

const Container = styled.div`
    max-width: 1000px;
    display: flex;
    flex-wrap: wrap;
    margin: 0 auto;

    .pswp-thumbnail {
        display: inline-block;
        cursor: pointer;
    }
`;

const PAGE_SIZE = 12;
const COLUMNS = 3;

export default function Gallery() {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [data, setData] = useState<file[]>();
    const [total, setTotal] = useState(1);

    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        const token = getData(LS_KEYS.USER).token;
        if (!key) {
            router.push("/");
        }
        const main = async () => {
            setLoading(true);
            const encryptionKey = await getActualKey();
            const resp = await getFiles("0", token, "24", encryptionKey);
            setLoading(false);
            setData(resp);
        };
        main();
    }, []);

    if (!data || loading) {
        return <div className="text-center">
            <Spinner animation="border" variant="primary" />;
        </div>
    }

    const getThumbnail = (item) => (
        <PreviewCard data={item} />
    )

    return (<Container>
        <PhotoSwipeGallery
            items={data.map(item => ({
                ...item,
                src: '/image.svg',
                w: window.innerWidth,
                h: window.innerHeight,
            }))}
            thumbnailContent={getThumbnail}
        />
    </Container>);
}
