import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import Spinner from 'react-bootstrap/Spinner';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { collection, fetchCollections, file, getFile, getFiles, getPreview } from 'services/fileService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import PreviewCard from './components/PreviewCard';
import { getActualKey } from 'utils/common/key';
import styled from 'styled-components';
import { PhotoSwipe } from 'react-photoswipe';
import { Options } from 'photoswipe';
import AutoSizer from 'react-virtualized-auto-sizer';
import { FixedSizeList as List } from 'react-window';
import Collections from './components/Collections';
import SadFace from 'components/SadFace';

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

const DeadCenter = styled.div`
    flex: 1;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    text-align: center;
    flex-direction: column;
`;

const ListContainer = styled.div`
    display: flex;

    @media (min-width: 1000px) {
        width: 1000px;
    }

    @media (min-width: 450px) and (max-width: 1000px) {
        max-width: 600px;
    }

    @media (max-width: 450px) {
        width: 100%;
    }
`;

const PAGE_SIZE = 12;
const COLUMNS = 3;

export default function Gallery() {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [collections, setCollections] = useState<collection[]>([])
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
            const collections = await fetchCollections(token, encryptionKey);
            const resp = await getFiles("0", token, "100", encryptionKey, collections);
            setLoading(false);
            setCollections(collections);
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

    const getThumbnail = (file: file[], index: number) => {
        return (<PreviewCard
            key={`tile-${file[index].id}`}
            data={file[index]}
            updateUrl={updateUrl(file[index].dataIndex)}
            onClick={onThumbnailClick(index)}
        />);
    }

    const getSlideData = async (instance: any, index: number, item: file) => {
        const token = getData(LS_KEYS.USER).token;
        if (!item.msrc) {
            const url = await getPreview(token, item);
            updateUrl(item.dataIndex)(url);
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
        if ((!item.src || item.src === item.msrc) && !fetching[item.dataIndex]) {
            fetching[item.dataIndex] = true;
            const url = await getFile(token, item);
            updateSrcUrl(item.dataIndex, url);
            if (item.metadata.fileType === 1) {
                item.html = `
                    <video width="320" height="240" controls>
                        <source src="${url}" />
                        Your browser does not support the video tag.
                    </video>
                `;
                delete item.src;
                item.w = window.innerWidth;
            } else {
                item.src = url;
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

    const selectCollection = (id?: string) => {
        const href = `/gallery?collection=${id || ''}`;
        router.push(href, undefined, { shallow: true });
    }

    const idSet = new Set();
    const filteredData = data.map((item, index) => ({
        ...item,
        dataIndex: index,
    })).filter(item => {
        if (!idSet.has(item.id)) {
            if (!router.query.collection || router.query.collection === item.collectionID.toString()) {
                idSet.add(item.id);
                return true;
            }
            return false;
        }
        return false;
    });

    return (<>
        <Collections
            collections={collections}
            selected={router.query.collection?.toString()}
            selectCollection={selectCollection}
        />
        {
            filteredData.length
                ? <Container>
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
                                    itemCount={Math.ceil(filteredData.length / columns)}
                                >
                                    {({ index, style }) => {
                                        const arr = [];
                                        for (let i = 0; i < columns; i++) {
                                            arr.push(index * columns + i);
                                        }
                                        return (<ListItem style={style}>
                                            <ListContainer>
                                                {arr.map(i => filteredData[i] && getThumbnail(filteredData, i))}
                                            </ListContainer>
                                        </ListItem>);
                                    }}
                                </List>
                            )
                        }}
                    </AutoSizer>
                    <PhotoSwipe
                        isOpen={open}
                        items={filteredData}
                        options={options}
                        onClose={handleClose}
                        gettingData={getSlideData}
                    />
                </Container>
                : <DeadCenter>
                    <SadFace height={100} width={100} />
                    <div>No content found!</div>
                </DeadCenter>
        }
    </>);
}
