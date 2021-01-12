import React, { useState } from "react"
import { UPLOAD_STAGES } from "services/uploadService";
import CollectionSelector from "./CollectionSelector"
import UploadProgress from "./UploadProgress"

export default function Upload({ uploadModalView, closeUploadModal, collectionLatestFile, setData }) {
    const [progressView, setProgressView] = useState(false);
    const [uploadStage, setUploadStage] = useState<UPLOAD_STAGES>(UPLOAD_STAGES.START);
    const [fileCounter, setFileCounter] = useState({ current: 0, total: 0 });
    const [percentComplete, setPercentComplete] = useState(0);
    const init = () => {
        setProgressView(false);
        setUploadStage(UPLOAD_STAGES.START);
        setFileCounter({ current: 0, total: 0 });
        setPercentComplete(0);
    }
    return (<>
        <CollectionSelector
            uploadModalView={uploadModalView}
            closeUploadModal={closeUploadModal}
            collectionLatestFile={collectionLatestFile}
            setProgressView={ setProgressView}
            setData={setData}
            progressBarProps={{ setPercentComplete, setFileCounter, setUploadStage }}
        />
        <UploadProgress
            now={percentComplete}
            fileCounter={fileCounter}
            uploadStage={uploadStage}
            show={progressView}
            onHide={init}
        />
    </>
    )
}