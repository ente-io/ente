import React, { useEffect, useState } from 'react';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import { FileList } from 'components/pages/gallery/UploadProgress';
import LinkButton from './pages/gallery/LinkButton';

export default function FailedUploads() {
    const [listView, setListView] = useState(false);
    const [failedFiles, setFailedFiles] = useState([]);

    const hideList = () => setListView(false);
    const showList = () => setListView(true);
    useEffect(() => {
        const failedFiles = getData(LS_KEYS.FAILED_UPLOADS)?.files ?? [];
        setFailedFiles(failedFiles);
    }, [listView]);

    return (
        failedFiles.length > 0 && (
            <>
                <LinkButton style={{ marginTop: '30px' }} onClick={showList}>
                    {constants.FAILED_UPLOADS}
                </LinkButton>
                <MessageDialog
                    show={listView}
                    onHide={hideList}
                    attributes={{
                        title: constants.FAILED_UPLOADS,
                        staticBackdrop: true,
                        close: { text: constants.CLOSE },
                    }}>
                    <FileList>
                        {failedFiles.map((file) => (
                            <li key={file}> {file}</li>
                        ))}
                    </FileList>
                </MessageDialog>
            </>
        )
    );
}
