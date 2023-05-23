import React, { useEffect, useRef, useState } from 'react';
import { DialogContent } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import AllCollectionCard from './collectionCard';
import { CollectionSummary } from 'types/collection';
import { FixedSizeList as List, areEqual } from 'react-window';
import memoize from 'memoize-one';
import useWindowSize from 'hooks/useWindowSize';

interface Iprops {
    collectionSummaries: CollectionSummary[];
    onCollectionClick: (id?: number) => void;
}

const createItemData = memoize((items, clickHandler) => ({
    items,
    clickHandler,
}));

const AllCollectionRow = React.memo(
    ({ data, index, style, isScrolling }: any) => {
        const { items, onCollectionClick } = data;
        const item = items[index];
        return (
            <div style={style}>
                <FlexWrapper gap={0.5}>
                    {item.map((item: any) => (
                        <AllCollectionCard
                            isScrolling={isScrolling}
                            onCollectionClick={onCollectionClick}
                            collectionSummary={item}
                            key={item.id}
                        />
                    ))}
                </FlexWrapper>
            </div>
        );
    },
    areEqual
);

export default function AllCollectionContent({
    collectionSummaries,
    onCollectionClick,
}: Iprops) {
    const refreshInProgress = useRef(false);
    const shouldRefresh = useRef(false);

    const [allCollectionListItem, setAllCollectionListItem] = useState([]);

    const windowSize = useWindowSize();

    useEffect(() => {
        if (!windowSize.width || !collectionSummaries) {
            return;
        }
        const main = async () => {
            if (refreshInProgress.current) {
                shouldRefresh.current = true;
                return;
            }
            refreshInProgress.current = true;

            const allCollectionListItem: CollectionSummary[][] = [];
            let index = 0;
            const columns = windowSize.width > 559 ? 3 : 2;
            console.log('windowSize', windowSize);
            while (index < collectionSummaries.length) {
                const collectionSummariesRow: CollectionSummary[] = [];

                for (
                    let i = 0;
                    i < columns && index < collectionSummaries.length;
                    i++
                ) {
                    const collectionSummary = collectionSummaries[index];
                    if (collectionSummary) {
                        collectionSummariesRow.push(collectionSummary);
                        index++;
                    }
                }
                allCollectionListItem.push(collectionSummariesRow);
            }
            setAllCollectionListItem(allCollectionListItem);
            refreshInProgress.current = false;
            if (shouldRefresh.current) {
                shouldRefresh.current = false;
                setTimeout(main, 0);
            }
        };
        main();
    }, [collectionSummaries, windowSize]);

    const itemData = createItemData(allCollectionListItem, onCollectionClick);

    return (
        <DialogContent>
            <List
                height={windowSize.height ?? 0}
                width={'100%'}
                itemCount={allCollectionListItem.length}
                itemSize={154}
                itemData={itemData}>
                {AllCollectionRow}
            </List>
        </DialogContent>
    );
}
