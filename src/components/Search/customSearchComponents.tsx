import React from 'react';
import CollectionIcon from 'components/icons/CollectionIcon';
import DateIcon from 'components/icons/DateIcon';
import ImageIcon from 'components/icons/ImageIcon';
import LocationIcon from 'components/icons/LocationIcon';
import VideoIcon from 'components/icons/VideoIcon';
import { components } from 'react-select';
import { SuggestionType } from 'types/search';
import SearchIcon from '@mui/icons-material/Search';
import { Box, Divider, Stack, Typography } from '@mui/material';
import { FreeFlowText, SpaceBetweenFlex } from 'components/Container';
import { PreviewResultImages } from './styledComponents';

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
    <>
        <Box className="main" px={2} py={1}>
            <Typography
                css={`
                    font-size: 12px;
                    line-height: 16px;
                `}
                mb={1}>
                Location
            </Typography>
            <SpaceBetweenFlex>
                <Box mr={1}>
                    <FreeFlowText>
                        <Typography>{props.label}</Typography>
                    </FreeFlowText>
                    <Typography color="text.secondary"> 22 Photos</Typography>
                </Box>

                <Stack direction={'row'} spacing={1}>
                    <PreviewResultImages src="https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500" />
                    <PreviewResultImages src="https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500" />
                    <PreviewResultImages src="https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500" />
                </Stack>
            </SpaceBetweenFlex>
        </Box>
        <Divider sx={{ mx: 2, my: 1 }} />
    </>
);
