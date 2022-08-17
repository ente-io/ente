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
                setChoiceModalOpen(true);
            }
        }
    };

    const handleAddFolderClick = async () => {
        await handleFolderSelection();
    };

    const handleFolderSelection = async () => {
        const folderPath = await watchFolderService.selectFolder();
        if (folderPath?.length > 0) {
            setInputFolderPath(folderPath);
            setChoiceModalOpen(true);
        }
    };

    const handleAddWatchMapping = async (uploadStrategy: UPLOAD_STRATEGY) => {
        await watchFolderService.addWatchMapping(
            inputFolderPath.substring(inputFolderPath.lastIndexOf('/') + 1),
            inputFolderPath,
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
        setChoiceModalOpen(false);
        handleAddWatchMapping(UPLOAD_STRATEGY.SINGLE_COLLECTION);
    };

    const uploadToMultipleCollection = () => {
        setChoiceModalOpen(false);
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
                            +
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
