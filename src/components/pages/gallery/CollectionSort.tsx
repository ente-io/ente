import { IconButton } from 'components/Container';
import SortIcon from 'components/icons/SortIcon';
import React from 'react';
import { OverlayTrigger } from 'react-bootstrap';
import { COLLECTION_SORT_BY } from 'types/collection';
import constants from 'utils/strings/constants';
import CollectionSortOptions from './CollectionSortOptions';
import { IconWithMessage } from './SelectedFileOptions';

interface Props {
    setCollectionSortBy: (sortBy: COLLECTION_SORT_BY) => void;
    activeSortBy: COLLECTION_SORT_BY;
}
export default function CollectionSort(props: Props) {
    const collectionSortOptions = CollectionSortOptions(props);
    return (
        <OverlayTrigger
            rootClose
            trigger="click"
            placement="bottom"
            overlay={collectionSortOptions}>
            <div>
                <IconWithMessage message={constants.SORT}>
                    <IconButton style={{ color: '#fff' }}>
                        <SortIcon />
                    </IconButton>
                </IconWithMessage>
            </div>
        </OverlayTrigger>
    );
}
