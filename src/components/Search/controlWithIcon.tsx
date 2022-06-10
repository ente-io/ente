import React from 'react';
import FolderIcon from '@mui/icons-material/Folder';
import CalendarIcon from '@mui/icons-material/CalendarMonth';
import ImageIcon from '@mui/icons-material/Image';
import LocationIcon from '@mui/icons-material/LocationOn';
import VideoFileIcon from '@mui/icons-material/VideoFile';
import { components } from 'react-select';
import { SearchOption, SuggestionType } from 'types/search';
import SearchIcon from '@mui/icons-material/Search';
import { SelectComponents } from 'react-select/src/components';

const { Control } = components;

const getIconByType = (type: SuggestionType) => {
    switch (type) {
        case SuggestionType.DATE:
            return <CalendarIcon />;
        case SuggestionType.LOCATION:
            return <LocationIcon />;
        case SuggestionType.COLLECTION:
            return <FolderIcon />;
        case SuggestionType.IMAGE:
            return <ImageIcon />;
        case SuggestionType.VIDEO:
            return <VideoFileIcon />;
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
