import constants from 'utils/strings/constants';
import MessageDialog from '../MessageDialog';
import React, { useContext, useEffect, useState } from 'react';
import { updateCreationTimeWithExif } from 'services/updateCreationTimeWithExif';
import { GalleryContext } from 'pages/gallery';
import { File } from 'services/fileService';
import { FixCreationTimeRunning } from './running';
import { FixCreationTimeOptions } from './options';
import { FixCreationTimeFooter } from './footer';
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

export enum FIX_OPTIONS {
    DATE_TIME_ORIGINAL,
    DATE_TIME_DIGITIZED,
    CUSTOM_TIME,
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

    const startFix = async (option: FIX_OPTIONS, customTime: Date) => {
        setFixState(FIX_STATE.RUNNING);
        const completedWithoutError = await updateCreationTimeWithExif(
            props.attributes.files,
            option,
            customTime,
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
                title:
                    fixState === FIX_STATE.RUNNING
                        ? constants.FIX_CREATION_TIME_IN_PROGRESS
                        : constants.FIX_CREATION_TIME,
                staticBackdrop: true,
                nonClosable: true,
            }}>
            <div
                style={{
                    marginBottom: '10px',
                    padding: '0 5%',
                    display: 'flex',
                    flexDirection: 'column',
                }}>
                <Message fixState={fixState} />

                {fixState === FIX_STATE.RUNNING && (
                    <FixCreationTimeRunning progressTracker={progressTracker} />
                )}
                {(fixState === FIX_STATE.NOT_STARTED ||
                    fixState === FIX_STATE.COMPLETED_WITH_ERRORS) && (
                    <div style={{ marginTop: '10px' }}>
                        <FixCreationTimeOptions handleSubmit={startFix} />
                    </div>
                )}
                <FixCreationTimeFooter
                    fixState={fixState}
                    startFix={startFix}
                    hide={props.hide}
                />
            </div>
        </MessageDialog>
    );
}
