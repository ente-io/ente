import React, { useEffect, useState } from 'react';
import { Button, Dialog, IconButton } from '@mui/material';
import watchService, { WatchMapping } from 'services/watchService';
import { MdDelete } from 'react-icons/md';
import ArrowForwardIcon from '@mui/icons-material/ArrowForward';
import Close from '@mui/icons-material/Close';
import { SpaceBetweenFlex } from 'components/Container';

function WatchModal({ watchModalView, setWatchModalView }) {
    const [mappings, setMappings] = useState<WatchMapping[]>([]);
    const [shouldUpdateMappings, setShouldUpdateMappings] = useState(true);
    const [inputFolderPath, setInputFolderPath] = useState('');

    useEffect(() => {
        if (shouldUpdateMappings) {
            setMappings(watchService.getWatchMappings());
            setShouldUpdateMappings(false);
        }
    }, [shouldUpdateMappings]);

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
            setShouldUpdateMappings(true);
        }
    };

    const handleRemoveWatchMapping = async (mapping: WatchMapping) => {
        await watchService.removeWatchMapping(mapping.collectionName);
        setShouldUpdateMappings(true);
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
                <div
                    style={{
                        borderTop: '1px solid #e6e6e6',
                        paddingTop: '12px',
                        marginTop: '20px',
                        marginBottom: '8px',
                        fontSize: '28px',
                        fontWeight: 'bold',
                    }}>
                    Current Watch Mappings
                </div>
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
