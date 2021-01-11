import React, { useState } from "react"
import CollectionSelector from "./CollectionSelector"
import UploadProgress from "./UploadProgress"

export default function Upload({ uploadModalView, closeUploadModal, collectionLatestFile, setData }) {
    const [progressView, setProgressView] = useState(false);
    const [percentComplete, setPercentComplete] = useState(0);

    const init = () => {
        setProgressView(false);
        setPercentComplete(0);
    }
    return (<>
        <CollectionSelector
            uploadModalView={uploadModalView}
            closeUploadModal={closeUploadModal}
            collectionLatestFile={collectionLatestFile}
            showProgress={() => setProgressView(true)}
            setData={setData}
            setPercentComplete={setPercentComplete}
        />
        <UploadProgress
            now={percentComplete}
            show={progressView}
            onHide={init}
        />
    </>
    )
}