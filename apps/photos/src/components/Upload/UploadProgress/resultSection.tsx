import React, { useContext } from 'react';
import FileList from 'components/FileList';
import { Typography } from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { ResultItemContainer } from './styledComponents';
import { UPLOAD_RESULT } from 'constants/upload';
import {
    SectionInfo,
    UploadProgressSection,
    UploadProgressSectionContent,
    UploadProgressSectionTitle,
} from './section';
import UploadProgressContext from 'contexts/uploadProgress';

export interface ResultSectionProps {
    uploadResult: UPLOAD_RESULT;
    sectionTitle: any;
    sectionInfo?: any;
}
export const ResultSection = (props: ResultSectionProps) => {
    const { finishedUploads, uploadFileNames } = useContext(
        UploadProgressContext
    );
    const fileList = finishedUploads.get(props.uploadResult);

    if (!fileList?.length) {
        return <></>;
    }
    return (
        <UploadProgressSection>
            <UploadProgressSectionTitle expandIcon={<ExpandMoreIcon />}>
                <Typography> {props.sectionTitle}</Typography>
            </UploadProgressSectionTitle>
            <UploadProgressSectionContent>
                {props.sectionInfo && (
                    <SectionInfo>{props.sectionInfo}</SectionInfo>
                )}
                <FileList
                    fileList={fileList.map((fileID) => (
                        <ResultItemContainer key={fileID}>
                            {uploadFileNames.get(fileID)}
                        </ResultItemContainer>
                    ))}
                />
            </UploadProgressSectionContent>
        </UploadProgressSection>
    );
};
