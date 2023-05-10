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
import { t } from 'i18next';

import { UPLOAD_STAGES } from 'constants/upload';

export const InProgressSection = () => {
    const { inProgressUploads, hasLivePhotos, uploadFileNames, uploadStage } =
        useContext(UploadProgressContext);
    const fileList = inProgressUploads ?? [];

    return (
        <UploadProgressSection>
            <UploadProgressSectionTitle expandIcon={<ExpandMoreIcon />}>
                {uploadStage === UPLOAD_STAGES.EXTRACTING_METADATA
                    ? t('INPROGRESS_METADATA_EXTRACTION')
                    : t('INPROGRESS_UPLOADS')}
            </UploadProgressSectionTitle>
            <UploadProgressSectionContent>
                {hasLivePhotos && (
                    <SectionInfo>{t('LIVE_PHOTOS_DETECTED')}</SectionInfo>
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
