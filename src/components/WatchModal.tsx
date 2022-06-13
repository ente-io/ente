import React, { useContext, useEffect, useState } from 'react';
import {
    Button,
    CircularProgress,
    Dialog,
    Icon,
    IconButton,
    Menu,
    MenuItem,
} from '@mui/material';
import watchService from 'services/watchService';
import Close from '@mui/icons-material/Close';
import { CenteredFlex, SpaceBetweenFlex } from 'components/Container';
import { WatchMapping } from 'types/watch';
import { AppContext } from 'pages/_app';
import CheckIcon from '@mui/icons-material/Check';
import FolderOpenIcon from '@mui/icons-material/FolderOpen';
import MoreHorizIcon from '@mui/icons-material/MoreHoriz';
import DoNotDisturbOutlinedIcon from '@mui/icons-material/DoNotDisturbOutlined';
import { default as MuiStyled } from '@mui/styled-engine';
import { Box } from '@mui/system';
import DialogBox from './DialogBox';
import { GalleryContext } from 'pages/gallery';
import constants from 'utils/strings/constants';

const ModalHeading = MuiStyled('h3')({
    fontSize: '28px',
    marginBottom: '24px',
    fontWeight: 600,
});

const FullWidthButtonWithTopMargin = MuiStyled(Button)({
    marginTop: '16px',
    width: '100%',
    borderRadius: '4px',
});

const PaddedContainer = MuiStyled(Box)({
    padding: '24px',
});

const FixedHeightContainer = MuiStyled(Box)({
    height: '450px',
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'space-between',
});

const FullHeightVerticallyCentered = MuiStyled(Box)({
    display: 'flex',
    flexDirection: 'column',
    height: '100%',
    overflowY: 'auto',
    margin: 0,
    padding: 0,
    listStyle: 'none',
    '&::-webkit-scrollbar': {
        width: '6px',
    },
    '&::-webkit-scrollbar-thumb': {
        backgroundColor: 'slategrey',
    },
});

const NoFoldersTitleText = MuiStyled('h4')({
    fontSize: '24px',
    marginBottom: '16px',
    fontWeight: 600,
});

const BottomMarginSpacer = MuiStyled(Box)({
    marginBottom: '10px',
});

const HorizontalFlex = MuiStyled(Box)({
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between',
});

const VerticalFlex = MuiStyled(Box)({
    display: 'flex',
    flexDirection: 'column',
});

const MappingEntryTitle = MuiStyled(Box)({
    fontSize: '16px',
    fontWeight: 500,
    marginLeft: '12px',
    marginRight: '6px',
});

const MappingEntryFolder = MuiStyled(Box)({
    fontSize: '14px',
    fontWeight: 500,
    marginTop: '2px',
    marginLeft: '12px',
    marginRight: '6px',
    marginBottom: '6px',
    lineHeight: '18px',
});

const DialogBoxHeading = MuiStyled('h4')({
    fontSize: '24px',
    marginBottom: '16px',
    fontWeight: 600,
});

const DialogBoxText = MuiStyled('p')({
    fontWeight: 500,
});

const DialogBoxButton = MuiStyled(Button)({
    width: '140px',
});

function CheckmarkIcon() {
    return (
        <Icon
            sx={{
                marginLeft: '4px',
                marginRight: '4px',
                color: (theme) => theme.palette.grey.A200,
            }}>
            <CheckIcon />
        </Icon>
    );
}

function WatchModal({
    watchModalView,
    setWatchModalView,
}: {
    watchModalView: boolean;
    setWatchModalView: (watchModalView: boolean) => void;
}) {
    const [mappings, setMappings] = useState<WatchMapping[]>([]);
    const { setDropZoneActive } = useContext(GalleryContext);

    useEffect(() => {
        setMappings(watchService.getWatchMappings());
    }, []);

    useEffect(() => {
        if (watchModalView) {
            setDropZoneActive(false);

            const handleDrag = (e: DragEvent) => {
                e.preventDefault();
                e.stopPropagation();
            };
            const handleDrop = (e: DragEvent) => {
                e.preventDefault();
                e.stopPropagation();

                const files = e.dataTransfer.files;
                if (files.length > 0) {
                    handleFolderDrop(files);
                }
            };
            addEventListener('dragover', handleDrag);
            addEventListener('drop', handleDrop);

            return () => {
                setDropZoneActive(true);
                removeEventListener('dragover', handleDrag);
                removeEventListener('drop', handleDrop);
            };
        }
    }, [watchModalView]);

    const handleFolderDrop = async (folders: FileList) => {
        for (let i = 0; i < folders.length; i++) {
            const folder: any = folders[i];
            const path = (folder.path as string).replace(/\\/g, '/');
            if (await watchService.isFolder(path)) {
                await handleAddWatchMapping(path);
            }
        }
    };

    const handleAddFolderClick = async () => {
        await handleFolderSelection();
    };

    const handleFolderSelection = async () => {
        const folderPath = await watchService.selectFolder();
        await handleAddWatchMapping(folderPath);
    };

    const handleAddWatchMapping = async (inputFolderPath: string) => {
        if (inputFolderPath?.length > 0) {
            await watchService.addWatchMapping(
                inputFolderPath.substring(inputFolderPath.lastIndexOf('/') + 1),
                inputFolderPath
            );
            setMappings(watchService.getWatchMappings());
        }
    };

    const handleRemoveWatchMapping = async (mapping: WatchMapping) => {
        await watchService.removeWatchMapping(mapping.collectionName);
        setMappings(watchService.getWatchMappings());
    };

    const handleClose = () => {
        setWatchModalView(false);
    };

    return (
        <Dialog
            maxWidth="xs"
            fullWidth={true}
            open={watchModalView}
            onClose={handleClose}>
            <PaddedContainer>
                <FixedHeightContainer>
                    <SpaceBetweenFlex>
                        <ModalHeading>{constants.WATCHED_FOLDERS}</ModalHeading>
                        <IconButton
                            onClick={handleClose}
                            sx={{
                                marginBottom: 'auto',
                            }}>
                            <Close />
                        </IconButton>
                    </SpaceBetweenFlex>

                    {mappings.length === 0 ? (
                        <FullHeightVerticallyCentered
                            sx={{
                                justifyContent: 'center',
                            }}>
                            <NoFoldersTitleText>
                                {constants.NO_FOLDERS_ADDED}
                            </NoFoldersTitleText>
                            {constants.FOLDERS_AUTOMATICALLY_MONITORED}
                            <BottomMarginSpacer />
                            <span>
                                <CheckmarkIcon />{' '}
                                {constants.UPLOAD_NEW_FILES_TO_ENTE}
                            </span>
                            <span>
                                <CheckmarkIcon />{' '}
                                {constants.REMOVE_DELETED_FILES_FROM_ENTE}
                            </span>
                        </FullHeightVerticallyCentered>
                    ) : (
                        <FullHeightVerticallyCentered>
                            {mappings.map((mapping: WatchMapping) => {
                                return (
                                    <MappingEntry
                                        key={mapping.collectionName}
                                        mapping={mapping}
                                        handleRemoveMapping={
                                            handleRemoveWatchMapping
                                        }
                                    />
                                );
                            })}
                        </FullHeightVerticallyCentered>
                    )}

                    <CenteredFlex>
                        <FullWidthButtonWithTopMargin
                            color="accent"
                            onClick={handleAddFolderClick}>
                            +
                            <span
                                style={{
                                    marginLeft: '8px',
                                }}></span>
                            {constants.ADD_FOLDER}
                        </FullWidthButtonWithTopMargin>
                    </CenteredFlex>
                </FixedHeightContainer>
            </PaddedContainer>
        </Dialog>
    );
}

function MappingEntry({
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

export default WatchModal;
