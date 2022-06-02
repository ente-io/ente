import React from 'react';
import CollectionIcon from 'components/icons/CollectionIcon';
import DateIcon from 'components/icons/DateIcon';
import ImageIcon from 'components/icons/ImageIcon';
import LocationIcon from 'components/icons/LocationIcon';
import VideoIcon from 'components/icons/VideoIcon';
import { components } from 'react-select';
import { SearchOption, SuggestionType } from 'types/search';
import SearchIcon from '@mui/icons-material/Search';
import { SelectComponents } from 'react-select/src/components';

const { Control } = components;

const getIconByType = (type: SuggestionType) => {
    switch (type) {
        case SuggestionType.DATE:
            return <DateIcon />;
        case SuggestionType.LOCATION:
            return <LocationIcon />;
        case SuggestionType.COLLECTION:
            return <CollectionIcon />;
        case SuggestionType.IMAGE:
            return <ImageIcon />;
        case SuggestionType.VIDEO:
            return <VideoIcon />;
        default:
            return <SearchIcon />;
    }
};

export const ControlWithIcon: SelectComponents<SearchOption, false>['Control'] =
    (props) => (
        <Control {...props}>
            <span
                className="icon"
                style={{
                    paddingLeft: '10px',
                    paddingBottom: '4px',
                }}>
                {getIconByType(props.getValue()[0]?.type)}
            </span>
            {props.children}
        </Control>
    );
