import React, { useState } from "react"
import CollectionSelector from "./CollectionSelector"
import UploadProgress from "./UploadProgress"

export default function Upload({ uploadModalView, closeUploadModal, collectionLatestFile, setData }) {
    const [progressView, setProgressView] = useState(false);
    return (<>
        <CollectionSelector
            uploadModalView={uploadModalView}
            closeUploadModal={closeUploadModal}
            collectionLatestFile={collectionLatestFile}
            showProgress={() => setProgressView(true)}
            setData={setData}
        />
        <UploadProgress
            show={progressView}
            onHide={() => setProgressView(false)}
        />
    </>
    )
}