import React from 'react';
import CollectionIcon from 'components/icons/CollectionIcon';
import DateIcon from 'components/icons/DateIcon';
import ImageIcon from 'components/icons/ImageIcon';
import LocationIcon from 'components/icons/LocationIcon';
import VideoIcon from 'components/icons/VideoIcon';
import { components } from 'react-select';
import { SuggestionType } from 'types/search';
import SearchIcon from '@mui/icons-material/Search';

const { Option, Control } = components;

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

export const OptionWithIcon = (props) => (
    <Option {...props}>
        <LabelWithIcon type={props.data.type} label={props.data.label} />
    </Option>
);
export const ControlWithIcon = (props) => (
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

const LabelWithIcon = (props: { type: SuggestionType; label: string }) => (
    <div style={{ display: 'flex', alignItems: 'center' }}>
        <span style={{ paddingRight: '10px', paddingBottom: '4px' }}>
            {getIconByType(props.type)}
        </span>
        <span>{props.label}</span>
    </div>
);
