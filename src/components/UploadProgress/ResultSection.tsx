import React from 'react';
import FileList from 'components/FileList';
import {
    Accordion,
    AccordionDetails,
    AccordionSummary,
    Typography,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { SectionInfo, ResultItemContainer } from './styledComponents';
import { FileUploadResults } from 'constants/upload';

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
        <Accordion>
            <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Typography> {props.sectionTitle}</Typography>
            </AccordionSummary>
            <AccordionDetails>
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
            </AccordionDetails>
        </Accordion>
    );
};
