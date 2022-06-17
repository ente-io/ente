import {
    BottomMarginSpacer,
    FixedHeightContainer,
    FullHeightVerticallyCentered,
    FullWidthButtonWithTopMargin,
    ModalHeading,
    NoFoldersTitleText,
    PaddedContainer,
} from './styledComponents';
import React, { useContext, useEffect, useState } from 'react';
import { Dialog, IconButton } from '@mui/material';
import watchService from 'services/watchFolderService';
import Close from '@mui/icons-material/Close';
import { CenteredFlex, SpaceBetweenFlex } from 'components/Container';
import { WatchMapping } from 'types/watchFolder';
import { AppContext } from 'pages/_app';
import constants from 'utils/strings/constants';
import { CheckmarkIcon } from './checkmarkIcon';
import { MappingEntry } from './mappingEntry';

interface NewType {
    open: boolean;
    onClose: () => void;
}

export default function WatchFolderModal({ open, onClose }: NewType) {
    const [mappings, setMappings] = useState<WatchMapping[]>([]);
    const appContext = useContext(AppContext);

    useEffect(() => {
        setMappings(watchService.getWatchMappings());
    }, []);

    useEffect(() => {
        if (
            appContext.watchModalFiles &&
            appContext.watchModalFiles.length > 0
        ) {
            handleFolderDrop(appContext.watchModalFiles);
        }
    }, [appContext.watchModalFiles]);

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

    return (
        <Dialog maxWidth="xs" fullWidth={true} open={open} onClose={onClose}>
            <PaddedContainer>
                <FixedHeightContainer>
                    <SpaceBetweenFlex>
                        <ModalHeading>{constants.WATCHED_FOLDERS}</ModalHeading>
                        <IconButton
                            onClick={onClose}
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
