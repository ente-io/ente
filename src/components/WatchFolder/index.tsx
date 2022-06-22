import { MappingList } from './mappingList';
import { NoMappingsContent } from './noMappingsContent';
import React, { useContext, useEffect, useState } from 'react';
import { Button, DialogActions, DialogContent } from '@mui/material';
import watchFolderService from 'services/watchFolder/watchFolderService';
import { WatchMapping } from 'types/watchFolder';
import { AppContext } from 'pages/_app';
import constants from 'utils/strings/constants';
import DialogBoxBase from 'components/DialogBox/base';
import DialogTitleWithCloseButton from 'components/DialogBox/titleWithCloseButton';

interface Iprops {
    open: boolean;
    onClose: () => void;
}

export default function WatchFolder({ open, onClose }: Iprops) {
    const [mappings, setMappings] = useState<WatchMapping[]>([]);
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
                await handleAddWatchMapping(path);
            }
        }
    };

    const handleAddFolderClick = async () => {
        await handleFolderSelection();
    };

    const handleFolderSelection = async () => {
        const folderPath = await watchFolderService.selectFolder();
        await handleAddWatchMapping(folderPath);
    };

    const handleAddWatchMapping = async (inputFolderPath: string) => {
        if (inputFolderPath?.length > 0) {
            await watchFolderService.addWatchMapping(
                inputFolderPath.substring(inputFolderPath.lastIndexOf('/') + 1),
                inputFolderPath,
                true
            );
            setMappings(watchFolderService.getWatchMappings());
        }
    };

    const handleRemoveWatchMapping = async (mapping: WatchMapping) => {
        await watchFolderService.removeWatchMapping(mapping.folderPath);
        setMappings(watchFolderService.getWatchMappings());
    };

    return (
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
    );
}
