import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import React, { useState } from 'react';
import { ProgressBar, Button } from 'react-bootstrap';
import { ComfySpan } from './ExportInProgress';
import { replaceThumbnail } from 'services/migrate';
import { LS_KEYS, setData } from 'utils/storage/localStorage';

export type SetProgressTracker = React.Dispatch<
    React.SetStateAction<{
        current: number;
        total: number;
    }>
>;
interface Props {
    show: boolean;
    hide: () => void;
}
export enum FIX_STATE {
    NOT_STARTED,
    RUNNING,
    COMPLETED,
    RAN_WITH_ERROR,
}
function Message(props: { fixState: FIX_STATE }) {
    let message = <></>;
    switch (props.fixState) {
        case FIX_STATE.NOT_STARTED:
            message = constants.REPLACE_THUMBNAIL_NOT_STARTED();
            break;
        case FIX_STATE.COMPLETED:
            message = constants.REPLACE_THUMBNAIL_COMPLETED();
            break;
        case FIX_STATE.RAN_WITH_ERROR:
            message = constants.REPLACE_THUMBNAIL_RAN_WITH_ERROR();
            break;
    }
    return <div style={{ marginBottom: '30px' }}>{message}</div>;
}
export default function FixLargeThumbnails(props: Props) {
    const [fixState, setFixState] = useState(FIX_STATE.NOT_STARTED);
    const [progressTracker, setProgressTracker] = useState({
        current: 0,
        total: 0,
    });

    const startFix = async () => {
        updateFixState(FIX_STATE.RUNNING);
        const completedWithError = await replaceThumbnail(setProgressTracker);
        updateFixState(
            completedWithError ? FIX_STATE.RAN_WITH_ERROR : FIX_STATE.COMPLETED
        );
    };

    const updateFixState = (fixState: FIX_STATE) => {
        setFixState(fixState);
        setData(LS_KEYS.THUMBNAIL_FIX_STATE, { state: fixState });
    };
    return (
        <MessageDialog
            show={props.show}
            onHide={props.hide}
            attributes={{
                title: constants.FIX_LARGE_THUMBNAILS,
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
                                files exported
                            </span>
                        </div>
                        <div style={{ width: '100%', marginTop: '10px' }}>
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
                    <Button
                        block
                        variant={'outline-secondary'}
                        onClick={props.hide}>
                        {constants.CLOSE}
                    </Button>
                    <div style={{ width: '30px' }} />
                    {(fixState === FIX_STATE.NOT_STARTED ||
                        fixState === FIX_STATE.RAN_WITH_ERROR) && (
                        <Button
                            block
                            variant={'outline-success'}
                            onClick={startFix}>
                            {constants.UPDATE}
                        </Button>
                    )}
                </div>
            </div>
        </MessageDialog>
    );
}
