import React from 'react';
import FileList from 'components/FileList';
import { Typography } from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { SectionInfo, ResultItemContainer } from './styledComponents';
import { FileUploadResults } from 'constants/upload';
import {
    UploadProgressSection,
    UploadProgressSectionContent,
    UploadProgressSectionTitle,
} from './section';

export interface ResultSectionProps {
    filenames: Map<number, string>;
    fileUploadResultMap: Map<FileUploadResults, number[]>;
    fileUploadResult: FileUploadResults;
    sectionTitle: any;
    sectionInfo?: any;
}
export const ResultSection = (props: ResultSectionProps) => {
    const fileList = props.fileUploadResultMap?.get(props.fileUploadResult);
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
                            {props.filenames.get(fileID)}
                        </ResultItemContainer>
                    ))}
                />
            </UploadProgressSectionContent>
        </UploadProgressSection>
    );
};
