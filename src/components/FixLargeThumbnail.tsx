/* eslint-disable @typescript-eslint/no-unused-vars */
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import React, { useContext, useState } from 'react';
import { ProgressBar, Button } from 'react-bootstrap';
import { ComfySpan } from './ExportInProgress';
import { regenerateThumbnail } from 'services/migrate';
import { GalleryContext } from 'pages/gallery';
import { RequestCanceller } from 'services/upload/queueProcessor';
import { getLocalFiles } from 'services/fileService';

interface Props {
    show: boolean;
    hide: () => void;
}

export default function FixLargeThumbnails(props: Props) {
    const galleryContext = useContext(GalleryContext);
    const [inprogress, SetInProgress] = useState(true);
    const [updateCanceler, setUpdateCanceler] = useState<RequestCanceller>({
        exec: () => null,
    });
    const [progressTracker, setProgressTracker] = useState();
    const cancelFix = () => {
        updateCanceler.exec();
        SetInProgress(false);
    };
    const startFix = async () => {
        SetInProgress(true);
        const localFiles = await getLocalFiles();
        regenerateThumbnail(localFiles);
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
                    marginBottom: '30px',
                    padding: '0 5%',
                    display: 'flex',
                    alignItems: 'center',
                    flexDirection: 'column',
                }}>
                {inprogress ? (
                    <>
                        <div style={{ marginBottom: '10px' }}>
                            <ComfySpan>
                                {' '}
                                {0} / {10}{' '}
                            </ComfySpan>{' '}
                            <span style={{ marginLeft: '10px' }}>
                                {' '}
                                files exported
                            </span>
                        </div>
                        <div style={{ width: '100%', marginBottom: '30px' }}>
                            <ProgressBar
                                now={Math.round((1 * 100) / 10)}
                                animated={true}
                                variant="upload-progress-bar"
                            />
                        </div>
                    </>
                ) : (
                    <div style={{ marginBottom: '10px' }}>
                        Your some files have of the thumbnails have been updated
                        of large size do you want to update them with low res
                        version to save space
                    </div>
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
                    {inprogress ? (
                        <Button
                            block
                            variant={'outline-danger'}
                            onClick={cancelFix}>
                            {constants.CANCEL}
                        </Button>
                    ) : (
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
