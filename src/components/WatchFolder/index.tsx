import { MappingList } from './mappingList';
import { NoMappingsContent } from './noMappingsContent';
import React, { useContext, useEffect, useState } from 'react';
import { Button, DialogActions, DialogContent } from '@mui/material';
import watchFolderService from 'services/watchFolder/watchFolderService';
import { WatchMapping } from 'types/watchFolder';
import { AppContext } from 'pages/_app';
import constants from 'utils/strings/constants';
import DialogBoxBase from 'components/DialogBox/base';
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
    const [choicModalOpen, setChoiceModalOpen] = useState(false);
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
            <DialogBoxBase maxWidth="xs" open={open} onClose={onClose}>
                <DialogTitleWithCloseButton onClose={onClose}>
                    {constants.WATCHED_FOLDERS}
                </DialogTitleWithCloseButton>
                <DialogContent>
                    {mappings.length === 0 ? (
                        <NoMappingsContent />
                    ) : (
                        <MappingList
                            mappings={mappings}
                            handleRemoveWatchMapping={handleRemoveWatchMapping}
                        />
                    )}
                </DialogContent>

                <DialogActions>
                    <Button
                        sx={{ mt: 2 }}
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
                </DialogActions>
            </DialogBoxBase>
            <UploadStrategyChoiceModal
                open={choicModalOpen}
                onClose={closeChoiceModal}
                uploadToSingleCollection={uploadToSingleCollection}
                uploadToMultipleCollection={uploadToMultipleCollection}
            />
        </>
    );
}
