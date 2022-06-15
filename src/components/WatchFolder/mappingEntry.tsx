import {
    DialogBoxButton,
    DialogBoxHeading,
    DialogBoxText,
    HorizontalFlex,
    MappingEntryFolder,
    MappingEntryTitle,
    VerticalFlex,
} from './styledComponents';
import React, { useEffect, useState } from 'react';
import { CircularProgress, IconButton, Menu, MenuItem } from '@mui/material';
import watchService from 'services/watchFolderService';
import { SpaceBetweenFlex } from 'components/Container';
import { WatchMapping } from 'types/watchFolder';
import { AppContext } from 'pages/_app';
import FolderOpenIcon from '@mui/icons-material/FolderOpen';
import MoreHorizIcon from '@mui/icons-material/MoreHoriz';
import DoNotDisturbOutlinedIcon from '@mui/icons-material/DoNotDisturbOutlined';
import DialogBox from '../DialogBox';
import constants from 'utils/strings/constants';

export function MappingEntry({
    mapping,
    handleRemoveMapping,
}: {
    mapping: WatchMapping;
    handleRemoveMapping: (mapping: WatchMapping) => void;
}) {
    const appContext = React.useContext(AppContext);

    useEffect(() => {
        console.log(appContext.watchServiceIsRunning);
    }, [appContext.watchServiceIsRunning]);

    const [anchorEl, setAnchorEl] = useState(null);
    const [dialogBoxOpen, setDialogBoxOpen] = useState(false);
    const open = Boolean(anchorEl);
    const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
        setAnchorEl(event.currentTarget);
    };
    const handleClose = () => {
        setAnchorEl(null);
    };

    return (
        <>
            <SpaceBetweenFlex>
                <HorizontalFlex>
                    <FolderOpenIcon />
                    <VerticalFlex>
                        <MappingEntryTitle>
                            {mapping.collectionName}
                            {appContext.watchServiceIsRunning &&
                                watchService.currentEvent?.collectionName ===
                                    mapping.collectionName && (
                                    <CircularProgress
                                        size={12}
                                        sx={{
                                            marginLeft: '6px',
                                        }}
                                    />
                                )}
                        </MappingEntryTitle>
                        <MappingEntryFolder
                            sx={{
                                color: (theme) => theme.palette.grey[500],
                            }}>
                            {mapping.folderPath}
                        </MappingEntryFolder>
                    </VerticalFlex>
                </HorizontalFlex>
                <IconButton onClick={handleClick}>
                    <MoreHorizIcon />
                </IconButton>
            </SpaceBetweenFlex>
            <Menu
                id="basic-menu"
                anchorEl={anchorEl}
                open={open}
                onClose={handleClose}
                MenuListProps={{
                    'aria-labelledby': 'basic-button',
                }}
                anchorOrigin={{
                    vertical: 'bottom',
                    horizontal: 'left',
                }}
                transformOrigin={{
                    vertical: 'center',
                    horizontal: 'center',
                }}>
                <MenuItem
                    onClick={() => setDialogBoxOpen(true)}
                    sx={{
                        fontWeight: 600,
                        color: (theme) => theme.palette.danger.main,
                    }}>
                    <span
                        style={{
                            marginRight: '6px',
                        }}>
                        <DoNotDisturbOutlinedIcon />
                    </span>{' '}
                    {constants.STOP_WATCHING}
                </MenuItem>
            </Menu>
            <DialogBox
                size="xs"
                PaperProps={{
                    style: {
                        width: '350px',
                    },
                }}
                open={dialogBoxOpen}
                onClose={() => setDialogBoxOpen(false)}
                attributes={{}}>
                <DialogBoxHeading>
                    {constants.STOP_WATCHING_FOLDER}
                </DialogBoxHeading>
                <DialogBoxText>
                    {constants.STOP_WATCHING_DIALOG_MESSAGE}
                </DialogBoxText>
                <HorizontalFlex>
                    <DialogBoxButton onClick={() => setDialogBoxOpen(false)}>
                        {constants.CANCEL}
                    </DialogBoxButton>
                    <DialogBoxButton
                        color="danger"
                        onClick={() => handleRemoveMapping(mapping)}>
                        {constants.YES_STOP}
                    </DialogBoxButton>
                </HorizontalFlex>
            </DialogBox>
        </>
    );
}
