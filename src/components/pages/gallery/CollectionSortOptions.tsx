import { Value } from 'components/Container';
import TickIcon from 'components/icons/TickIcon';
import React from 'react';
import { ListGroup, Popover, Row } from 'react-bootstrap';
import { COLLECTION_SORT_BY } from 'types/collection';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import { MenuItem, MenuLink } from './CollectionOptions';

interface OptionProps {
    activeSortBy: COLLECTION_SORT_BY;
    setCollectionSortBy: (sortBy: COLLECTION_SORT_BY) => void;
}

const TickWrapper = styled.span`
    color: #aaa;
    margin-left: 5px;
`;

const SortByOptionCreator =
    ({ setCollectionSortBy, activeSortBy }: OptionProps) =>
    (props: { sortBy: COLLECTION_SORT_BY; children: any }) =>
        (
            <MenuItem>
                <Row>
                    <Value width="20px">
                        {activeSortBy === props.sortBy && (
                            <TickWrapper>
                                <TickIcon />
                            </TickWrapper>
                        )}
                    </Value>
                    <Value width="165px">
                        <MenuLink
                            onClick={() => setCollectionSortBy(props.sortBy)}
                            variant={
                                activeSortBy === props.sortBy && 'success'
                            }>
                            {props.children}
                        </MenuLink>
                    </Value>
                </Row>
            </MenuItem>
        );

const CollectionSortOptions = (props: OptionProps) => {
    const SortByOption = SortByOptionCreator(props);

    return (
        <Popover id="collection-sort-options" style={{ borderRadius: '10px' }}>
            <Popover.Content
                style={{ padding: 0, border: 'none', width: '185px' }}>
                <ListGroup style={{ borderRadius: '8px' }}>
                    <SortByOption sortBy={COLLECTION_SORT_BY.LATEST_FILE}>
                        {constants.SORT_BY_LATEST_PHOTO}
                    </SortByOption>
                    <SortByOption sortBy={COLLECTION_SORT_BY.MODIFICATION_TIME}>
                        {constants.SORT_BY_MODIFICATION_TIME}
                    </SortByOption>
                    <SortByOption sortBy={COLLECTION_SORT_BY.NAME}>
                        {constants.SORT_BY_COLLECTION_NAME}
                    </SortByOption>
                </ListGroup>
            </Popover.Content>
        </Popover>
    );
};

export default CollectionSortOptions;
