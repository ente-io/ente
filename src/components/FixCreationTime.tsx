import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import React, { useContext, useEffect, useState } from 'react';
import { ProgressBar, Button } from 'react-bootstrap';
import { ComfySpan } from './ExportInProgress';
import { updateCreationTimeWithExif } from 'services/updateCreationTimeWithExif';
import { GalleryContext } from 'pages/gallery';
import { File } from 'services/fileService';
export interface FixCreationTimeAttributes {
    files: File[];
}

interface Props {
    isOpen: boolean;
    show: () => void;
    hide: () => void;
    attributes: FixCreationTimeAttributes;
}
export enum FIX_STATE {
    NOT_STARTED,
    RUNNING,
    COMPLETED,
    COMPLETED_WITH_ERRORS,
}
function Message(props: { fixState: FIX_STATE }) {
    let message = null;
    switch (props.fixState) {
        case FIX_STATE.NOT_STARTED:
            message = constants.UPDATE_CREATION_TIME_NOT_STARTED();
            break;
        case FIX_STATE.COMPLETED:
            message = constants.UPDATE_CREATION_TIME_COMPLETED();
            break;
        case FIX_STATE.COMPLETED_WITH_ERRORS:
            message = constants.UPDATE_CREATION_TIME_COMPLETED_WITH_ERROR();
            break;
    }
    return message ? <div>{message}</div> : <></>;
}
export default function FixCreationTime(props: Props) {
    const [fixState, setFixState] = useState(FIX_STATE.NOT_STARTED);
    const [progressTracker, setProgressTracker] = useState({
        current: 0,
        total: 0,
    });
    const galleryContext = useContext(GalleryContext);

    useEffect(() => {
        if (
            props.attributes &&
            props.isOpen &&
            fixState !== FIX_STATE.RUNNING
        ) {
            setFixState(FIX_STATE.NOT_STARTED);
        }
    }, [props.isOpen]);

    const startFix = async () => {
        setFixState(FIX_STATE.RUNNING);
        const completedWithoutError = await updateCreationTimeWithExif(
            props.attributes.files,
            setProgressTracker
        );
        if (!completedWithoutError) {
            setFixState(FIX_STATE.COMPLETED);
        } else {
            setFixState(FIX_STATE.COMPLETED_WITH_ERRORS);
        }
        await galleryContext.syncWithRemote();
    };
    if (!props.attributes) {
        return <></>;
    }

    return (
        <MessageDialog
            show={props.isOpen}
            onHide={props.hide}
            attributes={{
                title: constants.FIX_CREATION_TIME,
                staticBackdrop: true,
                nonClosable: true,
            }}>
            <div
                style={{
                    marginBottom: '10px',
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
                {fixState !== FIX_STATE.RUNNING && (
                    <div
                        style={{
                            width: '100%',
                            display: 'flex',
                            marginTop: '30px',
                            justifyContent: 'space-around',
                        }}>
                        {(fixState === FIX_STATE.NOT_STARTED ||
                            fixState === FIX_STATE.COMPLETED_WITH_ERRORS) && (
                            <Button
                                block
                                variant={'outline-secondary'}
                                onClick={() => {
                                    props.hide();
                                }}>
                                {constants.CANCEL}
                            </Button>
                        )}
                        {fixState === FIX_STATE.COMPLETED && (
                            <Button
                                block
                                variant={'outline-secondary'}
                                onClick={props.hide}>
                                {constants.CLOSE}
                            </Button>
                        )}
                        {(fixState === FIX_STATE.NOT_STARTED ||
                            fixState === FIX_STATE.COMPLETED_WITH_ERRORS) && (
                            <>
                                <div style={{ width: '30px' }} />

                                <Button
                                    block
                                    variant={'outline-success'}
                                    onClick={startFix}>
                                    {constants.FIX_CREATION_TIME}
                                </Button>
                            </>
                        )}
                    </div>
                )}
            </div>
        </MessageDialog>
    );
}
