import React, { useEffect, useState } from 'react';
import { Button, Modal } from 'react-bootstrap';
import watchService, { WatchMapping } from 'services/watchService';
import { MdDelete } from 'react-icons/md';
import { HiArrowNarrowRight } from 'react-icons/hi';

function WatchModal({ watchModalView, setWatchModalView }) {
    const [mappings, setMappings] = useState<WatchMapping[]>([]);
    const [shouldUpdateMappings, setShouldUpdateMappings] = useState(true);
    const [inputFolderPath, setInputFolderPath] = useState('');
    const [inputCollectionName, setInputCollectionName] = useState('');

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

    const handleCollectionNameChange = (
        e: React.ChangeEvent<HTMLInputElement>
    ) => {
        setInputCollectionName(e.target.value);
    };

    const handleAddWatchMapping = () => {
        if (inputFolderPath.length > 0 && inputCollectionName.length > 0) {
            watchService.addWatchMapping(inputCollectionName, inputFolderPath);
            setInputCollectionName('');
            setInputFolderPath('');
            setShouldUpdateMappings(true);
        }
    };

    const handleRemoveWatchMapping = (mapping: WatchMapping) => {
        watchService.removeWatchMapping(mapping.collectionName);
        setShouldUpdateMappings(true);
    };

    return (
        <Modal
            size="lg"
            aria-labelledby="contained-modal-title-vcenter"
            centered
            show={watchModalView}
            onHide={() => setWatchModalView(false)}>
            <Modal.Header closeButton>
                <Modal.Title>Watch Folders</Modal.Title>
            </Modal.Header>
            <Modal.Body>
                <div
                    style={{
                        display: 'flex',
                        flexDirection: 'column',
                    }}>
                    <input
                        type="text"
                        placeholder="Collection Name"
                        value={inputCollectionName}
                        onChange={handleCollectionNameChange}
                        style={{
                            width: '50%',
                        }}
                    />
                    <div
                        style={{
                            display: 'flex',
                        }}>
                        <Button
                            variant="primary"
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
                            variant="success"
                            onClick={handleAddWatchMapping}>
                            Add mapping
                        </Button>
                    </div>
                </div>
                <div
                    style={{
                        borderTop: '1px solid #e6e6e6',
                        paddingTop: '8px',
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
                                <HiArrowNarrowRight
                                    size={24}
                                    style={{
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
            </Modal.Body>
        </Modal>
    );
}

export default WatchModal;
