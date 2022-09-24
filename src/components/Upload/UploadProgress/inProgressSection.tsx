import React, { useContext } from 'react';
import FileList from 'components/FileList';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { InProgressItemContainer } from './styledComponents';
import {
    SectionInfo,
    UploadProgressSection,
    UploadProgressSectionContent,
    UploadProgressSectionTitle,
} from './section';
import UploadProgressContext from 'contexts/uploadProgress';
import constants from 'utils/strings/constants';
import { UPLOAD_STAGES } from 'constants/upload';

export const InProgressSection = () => {
    const { inProgressUploads, hasLivePhotos, uploadFileNames, uploadStage } =
        useContext(UploadProgressContext);
    const fileList = inProgressUploads ?? [];

    return (
        <UploadProgressSection
            defaultExpanded={uploadStage === UPLOAD_STAGES.UPLOADING}>
            <UploadProgressSectionTitle expandIcon={<ExpandMoreIcon />}>
                {constants.INPROGRESS_UPLOADS}
            </UploadProgressSectionTitle>
            <UploadProgressSectionContent>
                {hasLivePhotos && (
                    <SectionInfo>{constants.LIVE_PHOTOS_DETECTED}</SectionInfo>
                )}
                <FileList
                    fileList={fileList.map(({ localFileID, progress }) => (
                        <InProgressItemContainer key={localFileID}>
                            <span>{uploadFileNames.get(localFileID)}</span>
                            {uploadStage === UPLOAD_STAGES.UPLOADING && (
                                <>
                                    {' '}
                                    <span className="separator">{`-`}</span>
                                    <span>{`${progress}%`}</span>
                                </>
                            )}
                        </InProgressItemContainer>
                    ))}
                />
            </UploadProgressSectionContent>
        </UploadProgressSection>
    );
};
