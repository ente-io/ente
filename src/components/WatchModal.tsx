/* eslint-disable */
import React, { useEffect, useState } from 'react';
import {
    Button,
    CircularProgress,
    Dialog,
    Icon,
    IconButton,
} from '@mui/material';
import watchService from 'services/watchService';
import { MdDelete } from 'react-icons/md';
import ArrowForwardIcon from '@mui/icons-material/ArrowForward';
import Close from '@mui/icons-material/Close';
import { CenteredFlex, SpaceBetweenFlex } from 'components/Container';
import { WatchMapping } from 'types/watch';
import { AppContext } from 'pages/_app';
import CheckIcon from '@mui/icons-material/Check';
import FolderIcon from '@mui/icons-material/Folder';
import { default as MuiStyled } from '@mui/styled-engine';
import { Box } from '@mui/system';

const ModalHeading = MuiStyled('h3')({
    fontSize: '28px',
    marginBottom: '24px',
    fontWeight: 'bold',
});

const FullWidthButton = MuiStyled(Button)({
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

const VerticallyCentered = MuiStyled(Box)({
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
});

const NoFoldersTitleText = MuiStyled('h4')({
    fontSize: '24px',
    marginBottom: '16px',
    fontWeight: 'bold',
});

const BottomMarginSpacer = MuiStyled(Box)({
    marginBottom: '10px',
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
    const [inputFolderPath, setInputFolderPath] = useState('');
    const appContext = React.useContext(AppContext);

    useEffect(() => {
        setMappings(watchService.getWatchMappings());
    }, []);

    const handleFolderSelection = async () => {
        const folderPath = await watchService.selectFolder();
        setInputFolderPath(folderPath);
    };

    const handleAddWatchMapping = async () => {
        if (inputFolderPath.length > 0) {
            await watchService.addWatchMapping(
                inputFolderPath.substring(inputFolderPath.lastIndexOf('/') + 1),
                inputFolderPath
            );
            setInputFolderPath('');
            setMappings(watchService.getWatchMappings());
        }
    };

    const handleRemoveWatchMapping = async (mapping: WatchMapping) => {
        await watchService.removeWatchMapping(mapping.collectionName);
        setMappings(watchService.getWatchMappings());
    };

    const handleSyncProgressClick = () => {
        if (watchService.isUploadRunning()) {
            watchService.showProgressView();
        }
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
                        <ModalHeading>Watched folders</ModalHeading>
                        <IconButton
                            onClick={handleClose}
                            sx={{
                                marginBottom: 'auto',
                            }}>
                            <Close />
                        </IconButton>
                    </SpaceBetweenFlex>

                    {mappings.length === 0 ? (
                        <VerticallyCentered
                            sx={{
                                height: '100%',
                            }}>
                            <NoFoldersTitleText>
                                No folders added yet!
                            </NoFoldersTitleText>
                            The folders you add here will monitored to
                            automatically
                            <BottomMarginSpacer />
                            <span>
                                <CheckmarkIcon /> Upload new files to ente
                            </span>
                            <span>
                                <CheckmarkIcon /> Remove deleted files from ente
                            </span>
                        </VerticallyCentered>
                    ) : null}

                    <CenteredFlex>
                        <FullWidthButton color="accent">
                            +
                            <span
                                style={{
                                    marginLeft: '8px',
                                }}></span>
                            Add folder
                        </FullWidthButton>
                    </CenteredFlex>
                </FixedHeightContainer>
            </PaddedContainer>
        </Dialog>
    );
}

export default WatchModal;
