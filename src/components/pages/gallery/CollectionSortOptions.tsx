import TickIcon from 'components/icons/TickIcon';
import React from 'react';
import { ListGroup, Popover } from 'react-bootstrap';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import { MenuItem, MenuLink } from './CollectionOptions';
import { COLLECTION_SORT_BY } from './CollectionSort';

interface Props {
    setCollectionSortBy: (sortBy: COLLECTION_SORT_BY) => void;
}

const TickWrapper = styled.span`
    color: #aaa;
    margin-left: 5px;
`;
const CollectionSortOptions = (props: Props) => {
    return (
        <Popover id="collection-sort-options" style={{ borderRadius: '10px' }}>
            <Popover.Content style={{ padding: 0, border: 'none' }}>
                <ListGroup style={{ borderRadius: '8px' }}>
                    <MenuItem>
                        <TickWrapper>
                            <TickIcon />
                        </TickWrapper>
                        <MenuLink
                            onClick={() =>
                                props.setCollectionSortBy(
                                    COLLECTION_SORT_BY.CREATION_TIME
                                )
                            }>
                            {constants.SORT_BY_CREATION_TIME}
                        </MenuLink>
                    </MenuItem>
                    <MenuItem>
                        <MenuLink
                            onClick={() =>
                                props.setCollectionSortBy(
                                    COLLECTION_SORT_BY.MODIFICATION_TIME
                                )
                            }>
                            {constants.SORT_BY_MODIFICATION_TIME}
                        </MenuLink>
                    </MenuItem>
                    <MenuItem>
                        <MenuLink
                            onClick={() =>
                                props.setCollectionSortBy(
                                    COLLECTION_SORT_BY.NAME
                                )
                            }>
                            {constants.SORT_BY_COLLECTION_NAME}
                        </MenuLink>
                    </MenuItem>
                </ListGroup>
            </Popover.Content>
        </Popover>
    );
};

export default CollectionSortOptions;
