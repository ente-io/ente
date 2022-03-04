import React from 'react';
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import { FileList, Section } from 'components/pages/gallery/UploadProgress';

interface Iprops {
    failedFiles: string[];
    lastAttemptedFile: string;
    listView: boolean;
    hideList: () => void;
}

export default function FailedUploads({
    failedFiles,
    lastAttemptedFile,
    listView,
    hideList,
}: Iprops) {
    return (
        <>
            <MessageDialog
                show={listView}
                onHide={hideList}
                attributes={{
                    title: constants.UPLOAD_LOGS,
                    staticBackdrop: true,
                    close: { text: constants.CLOSE },
                }}>
                {failedFiles.length > 0 && (
                    <Section>
                        <p>{constants.FAILED_UPLOADS}</p>
                        <FileList>
                            {failedFiles.map((file) => (
                                <li key={file}> {file}</li>
                            ))}
                        </FileList>
                    </Section>
                )}
                {lastAttemptedFile && (
                    <Section>
                        <p>{constants.LAST_ATTEMPTED_FILE_INFO}</p>
                        <FileList>
                            <li>{lastAttemptedFile}</li>
                        </FileList>
                    </Section>
                )}
            </MessageDialog>
        </>
    );
}
