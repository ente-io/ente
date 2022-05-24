import React from 'react';
import FileList from 'components/FileList';
import { Accordion, AccordionDetails, AccordionSummary } from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { SectionInfo, InProgressItemContainer } from './styledComponents';
import { FileProgresses } from '.';

export interface InProgressProps {
    filenames: Map<number, string>;
    sectionTitle: string;
    fileProgressStatuses: FileProgresses[];
    sectionInfo?: any;
}
export const InProgressSection = (props: InProgressProps) => {
    const fileList = props.fileProgressStatuses ?? [];

    return (
        <Accordion>
            <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                {props.sectionTitle}
            </AccordionSummary>
            <AccordionDetails>
                {props.sectionInfo && (
                    <SectionInfo>{props.sectionInfo}</SectionInfo>
                )}
                <FileList
                    fileList={fileList.map(({ fileID, progress }) => (
                        <InProgressItemContainer key={fileID}>
                            <span>{props.filenames.get(fileID)}</span>
                            <span className="separator">{`-`}</span>
                            <span>{`${progress}%`}</span>
                        </InProgressItemContainer>
                    ))}
                />
            </AccordionDetails>
        </Accordion>
    );
};
