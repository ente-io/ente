import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import Spinner from 'react-bootstrap/Spinner';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { file, getFile, getFiles, getPreview } from 'services/fileService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import PreviewCard from './components/PreviewCard';
import { getActualKey } from 'utils/common/key';
import styled from 'styled-components';
import { PhotoSwipe } from 'react-photoswipe';
import { Options } from 'photoswipe';
import AutoSizer from 'react-virtualized-auto-sizer';
import { FixedSizeList as List } from 'react-window';

const Container = styled.div`
    display: block;
    flex: 1;
    width: 100%;
    flex-wrap: wrap;
    margin: 0 auto;

    .pswp-thumbnail {
        display: inline-block;
        cursor: pointer;
    }
`;

const ListItem = styled.div`
   display: flex;
   justify-content: center;
`;

const PAGE_SIZE = 12;
const COLUMNS = 3;

export default function Gallery() {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [data, setData] = useState<file[]>();
    const [open, setOpen] = useState(false);
    const [options, setOptions] = useState<Options>({
        history: false,
        maxSpreadZoom: 5,
    });
    const fetching: { [k: number]: boolean }  = {};

    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        const token = getData(LS_KEYS.USER).token;
        if (!key) {
            router.push("/");
        }
        const main = async () => {
            setLoading(true);
            const encryptionKey = await getActualKey();
            const resp = await getFiles("0", token, "100", encryptionKey);
            setLoading(false);
            setData(resp.map(item => ({
                ...item,
                w: window.innerWidth,
                h: window.innerHeight,
            })));
        };
        main();
    }, []);

    if (!data || loading) {
        return <div className="text-center">
            <Spinner animation="border" variant="primary" />
        </div>
    }

    const updateUrl = (index: number) => (url: string) => {
        data[index] = {
            ...data[index],
            msrc: url,
            w: window.innerWidth,
            h: window.innerHeight,
        }
        if (data[index].metadata.fileType === 1 && !data[index].html) {
            data[index].html = `
                <div class="video-loading">
                    <img src="${url}" />
                    <div class="spinner-border text-light" role="status">
                        <span class="sr-only">Loading...</span>
                    </div>
                </div>
            `;
            delete data[index].src;
        }
        if (data[index].metadata.fileType === 0 && !data[index].src) {
            data[index].src = url;
        }
        setData(data);
    }

    const updateSrcUrl = (index: number, url: string) => {
        data[index] = {
            ...data[index],
            src: url,
            w: window.innerWidth,
            h: window.innerHeight,
        }
        if (data[index].metadata.fileType === 1) {
            data[index].html = `
                <video controls>
                    <source src="${url}" />
                    Your browser does not support the video tag.
                </video>
            `;
            delete data[index].src;
        }
        setData(data);
    }

    const handleClose = () => {
        setOpen(false);
    }

    const onThumbnailClick = (index: number) => () => {
        setOptions({
            ...options,
            index,
        });
        setOpen(true);
    }

    const getThumbnail = (data: file[], index: number) => (
        <PreviewCard
            key={`tile-${index}`}
            data={data[index]}
            updateUrl={updateUrl(index)}
            onClick={onThumbnailClick(index)}
        />
    )

    const getSlideData = async (instance: any, index: number, item: file) => {
        const token = getData(LS_KEYS.USER).token;
        if (!item.msrc) {
            const url = await getPreview(token, item);
            updateUrl(index)(url);
            item.msrc = url;
            if (!item.src) {
                item.src = url;
            }
            item.w = window.innerWidth;
            item.h = window.innerHeight;
            try {
                instance.invalidateCurrItems();
                instance.updateSize(true);
            } catch (e) {
                // ignore
            }
        }
        if ((!item.src || item.src === item.msrc) && !fetching[index]) {
            fetching[index] = true;
            const url = await getFile(token, item);
            updateSrcUrl(index, url);
            if (item.metadata.fileType === 1) {
                item.html = `
                    <video width="320" height="240" controls>
                        <source src="${url}" />
                        Your browser does not support the video tag.
                    </video>
                `;
                delete item.src;
                item.w = window.innerWidth;
            }
            item.h = window.innerHeight;
            try {
                instance.invalidateCurrItems();
                instance.updateSize(true);
            } catch (e) {
                // ignore
            }
        }
    }

    return (<Container>
        <AutoSizer>
            {({ height, width }) => {
                let columns;
                if (width >= 1000) {
                    columns = 5;
                } else if (width < 1000 && width >= 450) {
                    columns = 3;
                } else if (width < 450 && width >= 300) {
                    columns = 2;
                } else {
                    columns = 1;
                }
                return (
                    <List
                        itemSize={200}
                        height={height}
                        width={width}
                        itemCount={data.length / columns}
                        
                    >
                        {({ index, style }) => {
                            const arr = [];
                            for (let i = 0; i < columns; i++) {
                                arr.push(index * columns + i);
                            }
                            return (<ListItem style={style}>
                                {arr.map(i => getThumbnail(data, i))}
                            </ListItem>);
                        }}
                    </List>
                )
            }}
        </AutoSizer>
        <PhotoSwipe
            isOpen={open}
            items={data}
            options={options}
            onClose={handleClose}
            gettingData={getSlideData}
        />
    </Container>);
}
