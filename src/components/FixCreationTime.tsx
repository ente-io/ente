import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import React, { useEffect, useState } from 'react';
import { ProgressBar, Button } from 'react-bootstrap';
import { ComfySpan } from './ExportInProgress';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import {
    getFilesPendingCreationTimeUpdate,
    updateCreationTimeWithExif,
} from 'services/updateCreationTimeWithExif';

interface Props {
    isOpen: boolean;
    show: () => void;
    hide: () => void;
}
export enum FIX_STATE {
    NOT_STARTED,
    FIX_LATER,
    NOOP,
    RUNNING,
    COMPLETED,
    COMPLETED_WITH_ERRORS,
}
function Message(props: { fixState: FIX_STATE }) {
    let message = null;
    switch (props.fixState) {
        case FIX_STATE.NOT_STARTED:
        case FIX_STATE.FIX_LATER:
            message = constants.UPDATE_CREATION_TIME_NOT_STARTED();
            break;
        case FIX_STATE.COMPLETED:
            message = constants.UPDATE_CREATION_TIME_COMPLETED();
            break;
        case FIX_STATE.NOOP:
            message = constants.UPDATE_CREATION_TIME_NOOP();
            break;
        case FIX_STATE.COMPLETED_WITH_ERRORS:
            message = constants.UPDATE_CREATION_TIME_COMPLETED_WITH_ERROR();
            break;
    }
    return message ? (
        <div style={{ marginBottom: '30px' }}>{message}</div>
    ) : (
        <></>
    );
}
export default function FixCreationTime(props: Props) {
    const [fixState, setFixState] = useState(FIX_STATE.NOT_STARTED);
    const [progressTracker, setProgressTracker] = useState({
        current: 0,
        total: 0,
    });

    const updateFixState = (fixState: FIX_STATE) => {
        setFixState(fixState);
        setData(LS_KEYS.CREATION_TIME_FIX_STATE, { state: fixState });
    };

    const init = () => {
        let fixState = getData(LS_KEYS.CREATION_TIME_FIX_STATE)?.state;
        if (!fixState || fixState === FIX_STATE.RUNNING) {
            fixState = FIX_STATE.NOT_STARTED;
            updateFixState(fixState);
        }
        if (fixState === FIX_STATE.COMPLETED) {
            fixState = FIX_STATE.NOOP;
            updateFixState(fixState);
        }
        setFixState(fixState);
        return fixState;
    };

    useEffect(() => {
        init();
    }, []);

    const main = async () => {
        const filesToBeUpdated = await getFilesPendingCreationTimeUpdate();
        if (fixState === FIX_STATE.NOT_STARTED && filesToBeUpdated.length > 0) {
            props.show();
        }
        if (
            (fixState === FIX_STATE.COMPLETED || fixState === FIX_STATE.NOOP) &&
            filesToBeUpdated.length > 0
        ) {
            updateFixState(FIX_STATE.NOT_STARTED);
        }
        if (filesToBeUpdated.length === 0 && fixState !== FIX_STATE.NOOP) {
            updateFixState(FIX_STATE.NOOP);
        }
    };

    useEffect(() => {
        if (props.isOpen && fixState !== FIX_STATE.RUNNING) {
            main();
        }
    }, [props.isOpen]);

    const startFix = async () => {
        updateFixState(FIX_STATE.RUNNING);
        const filesToBeUpdated = await getFilesPendingCreationTimeUpdate();
        const completedWithoutError = await updateCreationTimeWithExif(
            filesToBeUpdated,
            setProgressTracker
        );
        if (!completedWithoutError) {
            updateFixState(FIX_STATE.COMPLETED);
        } else {
            updateFixState(FIX_STATE.COMPLETED_WITH_ERRORS);
        }
    };

    return (
        <MessageDialog
            show={props.isOpen}
            onHide={props.hide}
            attributes={{
                title: constants.FIX_CREATION_TIME,
                staticBackdrop: true,
            }}>
            <div
                style={{
                    marginBottom: '20px',
                    padding: '0 5%',
                    display: 'flex',
                    alignItems: 'center',
                    flexDirection: 'column',
                }}>
                <Message fixState={fixState} />

                {fixState === FIX_STATE.RUNNING && (
                    <>
                        <div style={{ marginBottom: '10px' }}>
                            <ComfySpan>
                                {' '}
                                {progressTracker.current} /{' '}
                                {progressTracker.total}{' '}
                            </ComfySpan>{' '}
                            <span style={{ marginLeft: '10px' }}>
                                {' '}
                                {constants.CREATION_TIME_UPDATED}
                            </span>
                        </div>
                        <div
                            style={{
                                width: '100%',
                                marginTop: '10px',
                                marginBottom: '20px',
                            }}>
                            <ProgressBar
                                now={Math.round(
                                    (progressTracker.current * 100) /
                                        progressTracker.total
                                )}
                                animated={true}
                                variant="upload-progress-bar"
                            />
                        </div>
                    </>
                )}
                <div
                    style={{
                        width: '100%',
                        display: 'flex',
                        justifyContent: 'space-around',
                    }}>
                    {fixState === FIX_STATE.NOT_STARTED ||
                    fixState === FIX_STATE.FIX_LATER ? (
                        <Button
                            block
                            variant={'outline-secondary'}
                            onClick={() => {
                                updateFixState(FIX_STATE.FIX_LATER);
                                props.hide();
                            }}>
                            {constants.FIX_CREATION_TIME_LATER}
                        </Button>
                    ) : (
                        <Button
                            block
                            variant={'outline-secondary'}
                            onClick={props.hide}>
                            {constants.CLOSE}
                        </Button>
                    )}
                    {(fixState === FIX_STATE.NOT_STARTED ||
                        fixState === FIX_STATE.FIX_LATER ||
                        fixState === FIX_STATE.COMPLETED_WITH_ERRORS) && (
                        <>
                            <div style={{ width: '30px' }} />

                            <Button
                                block
                                variant={'outline-success'}
                                onClick={() => startFix()}>
                                {constants.FIX_CREATION_TIME}
                            </Button>
                        </>
                    )}
                </div>
            </div>
        </MessageDialog>
    );
}
