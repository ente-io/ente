import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import React, { useEffect, useState } from 'react';
import { ProgressBar, Button } from 'react-bootstrap';
import { ComfySpan } from './ExportInProgress';
import { getLargeThumbnailFiles, replaceThumbnail } from 'services/migrate';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';

export type SetProgressTracker = React.Dispatch<
    React.SetStateAction<{
        current: number;
        total: number;
    }>
>;
interface Props {
    isOpen: boolean;
    show: () => void;
    hide: () => void;
}
export enum FIX_STATE {
    NOT_STARTED,
    RUNNING,
    COMPLETED,
    COMPLETED_WITH_ERRORS,
    COMPLETED_BUT_HAS_MORE,
}
function Message(props: { fixState: FIX_STATE }) {
    let message = null;
    switch (props.fixState) {
        case FIX_STATE.NOT_STARTED:
            message = constants.REPLACE_THUMBNAIL_NOT_STARTED();
            break;
        case FIX_STATE.COMPLETED:
            message = constants.REPLACE_THUMBNAIL_COMPLETED();
            break;
        case FIX_STATE.COMPLETED_WITH_ERRORS:
            message = constants.REPLACE_THUMBNAIL_COMPLETED_WITH_ERROR();
            break;
        case FIX_STATE.COMPLETED_BUT_HAS_MORE:
            message = constants.REPLACE_THUMBNAIL_COMPLETED_BUT_HAS_MORE();
            break;
    }
    return message ? (
        <div style={{ marginBottom: '30px' }}>{message}</div>
    ) : (
        <></>
    );
}
export default function FixLargeThumbnails(props: Props) {
    const [fixState, setFixState] = useState(FIX_STATE.NOT_STARTED);
    const [progressTracker, setProgressTracker] = useState({
        current: 0,
        total: 0,
    });
    const [largeThumbnailFiles, setLargeThumbnailFiles] = useState<number[]>(
        []
    );

    useEffect(() => {
        const main = async () => {
            const largeThumbnailFiles = await getLargeThumbnailFiles();
            if (largeThumbnailFiles?.length > 0) {
                setLargeThumbnailFiles(largeThumbnailFiles);
            }
            let fixState =
                getData(LS_KEYS.THUMBNAIL_FIX_STATE)?.state ??
                FIX_STATE.NOT_STARTED;
            if (
                fixState === FIX_STATE.COMPLETED &&
                largeThumbnailFiles.length > 0
            ) {
                fixState = FIX_STATE.COMPLETED_BUT_HAS_MORE;
            }
            setFixState(fixState);
        };
        if (props.isOpen) {
            main();
        }
    }, [props.isOpen]);
    const startFix = async () => {
        updateFixState(FIX_STATE.RUNNING);
        const completedWithError = await replaceThumbnail(
            setProgressTracker,
            new Set(largeThumbnailFiles)
        );
        updateFixState(
            completedWithError
                ? FIX_STATE.COMPLETED_WITH_ERRORS
                : FIX_STATE.COMPLETED
        );
    };

    const updateFixState = (fixState: FIX_STATE) => {
        setFixState(fixState);
        setData(LS_KEYS.THUMBNAIL_FIX_STATE, { state: fixState });
    };
    return (
        <MessageDialog
            show={props.isOpen}
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
                                {constants.THUMBNAIL_REPLACED}
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
                    <Button
                        block
                        variant={'outline-secondary'}
                        onClick={props.hide}>
                        {constants.CLOSE}
                    </Button>
                    {(fixState === FIX_STATE.NOT_STARTED ||
                        fixState === FIX_STATE.COMPLETED_WITH_ERRORS ||
                        fixState === FIX_STATE.COMPLETED_BUT_HAS_MORE) && (
                        <>
                            <div style={{ width: '30px' }} />

                            <Button
                                block
                                variant={'outline-success'}
                                onClick={startFix}>
                                {constants.FIX}
                            </Button>
                        </>
                    )}
                </div>
            </div>
        </MessageDialog>
    );
}
