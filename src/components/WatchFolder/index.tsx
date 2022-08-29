import { MappingList } from './mappingList';
import React, { useContext, useEffect, useState } from 'react';
import { Button, Dialog, DialogContent, Stack } from '@mui/material';
import watchFolderService from 'services/watchFolder/watchFolderService';
import { WatchMapping } from 'types/watchFolder';
import { AppContext } from 'pages/_app';
import constants from 'utils/strings/constants';
import DialogTitleWithCloseButton from 'components/DialogBox/TitleWithCloseButton';
import UploadStrategyChoiceModal from 'components/Upload/UploadStrategyChoiceModal';
import { UPLOAD_STRATEGY } from 'constants/upload';
import { analyseUploadFiles } from 'utils/upload/fs';
import electronFSService from 'services/electron/fs';
import { UPLOAD_TYPE } from 'types/upload';

interface Iprops {
    open: boolean;
    onClose: () => void;
}

export default function WatchFolder({ open, onClose }: Iprops) {
    const [mappings, setMappings] = useState<WatchMapping[]>([]);
    const [inputFolderPath, setInputFolderPath] = useState('');
    const [choiceModalOpen, setChoiceModalOpen] = useState(false);
    const appContext = useContext(AppContext);

    useEffect(() => {
        setMappings(watchFolderService.getWatchMappings());
    }, []);

    useEffect(() => {
        if (
            appContext.watchFolderFiles &&
            appContext.watchFolderFiles.length > 0
        ) {
            handleFolderDrop(appContext.watchFolderFiles);
        }
    }, [appContext.watchFolderFiles]);

    const handleFolderDrop = async (folders: FileList) => {
        for (let i = 0; i < folders.length; i++) {
            const folder: any = folders[i];
            const path = (folder.path as string).replace(/\\/g, '/');
            if (await watchFolderService.isFolder(path)) {
                setInputFolderPath(path);
                const files = await electronFSService.getDirFiles(path);
                const analysisResult = analyseUploadFiles(
                    files,
                    UPLOAD_TYPE.FOLDERS
                );
                if (analysisResult.multipleFolders) {
                    setChoiceModalOpen(true);
                } else {
                    handleAddWatchMapping(
                        UPLOAD_STRATEGY.SINGLE_COLLECTION,
                        path
                    );
                }
            }
        }
    };

    const handleAddFolderClick = async () => {
        await handleFolderSelection();
    };

    const handleFolderSelection = async () => {
        const folderPath = await watchFolderService.selectFolder();
        if (folderPath) {
            setInputFolderPath(folderPath);
            const files = await electronFSService.getDirFiles(folderPath);
            const analysisResult = analyseUploadFiles(
                files,
                UPLOAD_TYPE.FOLDERS
            );
            if (analysisResult.multipleFolders) {
                setChoiceModalOpen(true);
            } else {
                handleAddWatchMapping(
                    UPLOAD_STRATEGY.SINGLE_COLLECTION,
                    folderPath
                );
            }
        }
    };

    const handleAddWatchMapping = async (
        uploadStrategy: UPLOAD_STRATEGY,
        folderPath?: string
    ) => {
        folderPath = folderPath || inputFolderPath;
        await watchFolderService.addWatchMapping(
            folderPath.substring(folderPath.lastIndexOf('/') + 1),
            folderPath,
            uploadStrategy
        );
        setInputFolderPath('');
        setMappings(watchFolderService.getWatchMappings());
    };

    const handleRemoveWatchMapping = async (mapping: WatchMapping) => {
        await watchFolderService.removeWatchMapping(mapping.folderPath);
        setMappings(watchFolderService.getWatchMappings());
    };

    const closeChoiceModal = () => setChoiceModalOpen(false);

    const uploadToSingleCollection = () => {
        closeChoiceModal();
        handleAddWatchMapping(UPLOAD_STRATEGY.SINGLE_COLLECTION);
    };

    const uploadToMultipleCollection = () => {
        closeChoiceModal();
        handleAddWatchMapping(UPLOAD_STRATEGY.COLLECTION_PER_FOLDER);
    };

    return (
        <>
            <Dialog
                maxWidth="xs"
                open={open}
                onClose={onClose}
                PaperProps={{ sx: { height: '450px' } }}>
                <DialogTitleWithCloseButton
                    onClose={onClose}
                    sx={{ '&&&': { padding: '32px 16px 16px 24px' } }}>
                    {constants.WATCHED_FOLDERS}
                </DialogTitleWithCloseButton>
                <DialogContent sx={{ flex: 1 }}>
                    <Stack spacing={1} p={1.5} height={'100%'}>
                        <MappingList
                            mappings={mappings}
                            handleRemoveWatchMapping={handleRemoveWatchMapping}
                        />
                        <Button
                            fullWidth
                            color="accent"
                            onClick={handleAddFolderClick}>
                            <span>+</span>
                            <span
                                style={{
                                    marginLeft: '8px',
                                }}></span>
                            {constants.ADD_FOLDER}
                        </Button>
                    </Stack>
                </DialogContent>
            </Dialog>
            <UploadStrategyChoiceModal
                open={choiceModalOpen}
                onClose={closeChoiceModal}
                uploadToSingleCollection={uploadToSingleCollection}
                uploadToMultipleCollection={uploadToMultipleCollection}
            />
        </>
    );
}
