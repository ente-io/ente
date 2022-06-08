import React, { useEffect, useState } from 'react';
import { Button, CircularProgress, Dialog, IconButton } from '@mui/material';
import watchService from 'services/watchService';
import { MdDelete } from 'react-icons/md';
import ArrowForwardIcon from '@mui/icons-material/ArrowForward';
import Close from '@mui/icons-material/Close';
import { SpaceBetweenFlex } from 'components/Container';
import { WatchMapping } from 'types/watch';
import { AppContext } from 'pages/_app';

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
        <Dialog maxWidth="xl" open={watchModalView} onClose={handleClose}>
            <div
                style={{
                    width: '600px',
                    padding: '20px',
                    paddingBottom: '28px',
                }}>
                <SpaceBetweenFlex>
                    <div
                        style={{
                            marginTop: '20px',
                            marginBottom: '20px',
                            fontSize: '32px',
                            fontWeight: 'bold',
                        }}>
                        Watch Folders
                    </div>
                    <IconButton onClick={handleClose}>
                        <Close />
                    </IconButton>
                </SpaceBetweenFlex>
                <div
                    style={{
                        display: 'flex',
                        flexDirection: 'column',
                    }}>
                    <div
                        style={{
                            display: 'flex',
                        }}>
                        <Button
                            variant="outlined"
                            style={{
                                marginRight: '12px',
                                marginTop: '8px',
                            }}
                            onClick={handleFolderSelection}>
                            Select Folder
                        </Button>
                        <div
                            style={{
                                marginTop: 'auto',
                                marginBottom: 'auto',
                            }}>
                            {inputFolderPath}
                        </div>
                    </div>
                    <div
                        style={{
                            marginTop: '8px',
                        }}>
                        <Button
                            variant="contained"
                            color="success"
                            onClick={handleAddWatchMapping}>
                            Add mapping
                        </Button>
                    </div>
                </div>
                <SpaceBetweenFlex
                    sx={{
                        marginTop: '20px',
                        borderTop: '1px solid #e6e6e6',
                        paddingTop: '12px',
                    }}>
                    <div
                        style={{
                            marginBottom: '8px',
                            fontSize: '28px',
                            fontWeight: 'bold',
                        }}>
                        Current Watch Mappings
                    </div>
                    {appContext.watchServiceIsRunning && (
                        <IconButton onClick={handleSyncProgressClick}>
                            <CircularProgress size={24} />
                        </IconButton>
                    )}
                </SpaceBetweenFlex>
                <div
                    style={{
                        marginTop: '12px',
                    }}>
                    {mappings.map((mapping) => (
                        <div
                            key={mapping.collectionName}
                            style={{
                                display: 'flex',
                                width: '100%',
                                marginTop: '4px',
                                marginBottom: '4px',
                            }}>
                            <div>
                                <span
                                    style={{
                                        fontWeight: 'bold',
                                        fontSize: '18px',
                                        color: 'green',
                                    }}>
                                    {mapping.folderPath}{' '}
                                </span>
                                <ArrowForwardIcon
                                    sx={{
                                        marginLeft: '12px',
                                        marginRight: '16px',
                                    }}
                                />
                                <span
                                    style={{
                                        fontWeight: 'bold',
                                        fontSize: '20px',
                                    }}>
                                    {mapping.collectionName}
                                </span>
                            </div>
                            <div
                                style={{
                                    marginLeft: 'auto',
                                }}>
                                <MdDelete
                                    size={24}
                                    style={{
                                        color: 'red',
                                        cursor: 'pointer',
                                        marginRight: '6px',
                                    }}
                                    onClick={() =>
                                        handleRemoveWatchMapping(mapping)
                                    }
                                />
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </Dialog>
    );
}

export default WatchModal;
