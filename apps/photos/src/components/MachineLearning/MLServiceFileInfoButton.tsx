import React, { useState } from 'react';
import { Button, Spinner } from 'react-bootstrap';
import { EnteFile } from 'types/file';
import { getToken, getUserID } from '@ente/shared/storage/localStorage/helpers';
import mlService from '../../services/machineLearning/machineLearningService';

function MLServiceFileInfoButton({
    file,
    updateMLDataIndex,
    setUpdateMLDataIndex,
}: {
    file: EnteFile;
    updateMLDataIndex: number;
    setUpdateMLDataIndex: (num: number) => void;
}) {
    const [mlServiceRunning, setMlServiceRunning] = useState(false);

    const runMLService = async () => {
        setMlServiceRunning(true);
        const token = getToken();
        const userID = getUserID();

        // index 4 is for timeout of 240 seconds
        await mlService.syncLocalFile(token, userID, file as EnteFile, null, 4);

        setUpdateMLDataIndex(updateMLDataIndex + 1);
        setMlServiceRunning(false);
    };

    return (
        <div
            style={{
                marginTop: '18px',
            }}>
            <Button
                onClick={runMLService}
                disabled={mlServiceRunning}
                variant={mlServiceRunning ? 'secondary' : 'primary'}>
                {!mlServiceRunning ? (
                    'Run ML Service'
                ) : (
                    <>
                        ML Service Running{' '}
                        <Spinner
                            animation="border"
                            size="sm"
                            style={{
                                marginLeft: '5px',
                            }}
                        />
                    </>
                )}
            </Button>
        </div>
    );
}

export default MLServiceFileInfoButton;
