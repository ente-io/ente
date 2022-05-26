import React from 'react';
import FileList from 'components/FileList';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { InProgressItemContainer } from './styledComponents';
import { FileProgresses } from '.';
import {
    SectionInfo,
    UploadProgressSection,
    UploadProgressSectionContent,
    UploadProgressSectionTitle,
} from './section';

export interface InProgressProps {
    filenames: Map<number, string>;
    sectionTitle: string;
    fileProgressStatuses: FileProgresses[];
    sectionInfo?: any;
}
export const InProgressSection = (props: InProgressProps) => {
    const fileList = props.fileProgressStatuses ?? [];

    return (
        <UploadProgressSection defaultExpanded>
            <UploadProgressSectionTitle expandIcon={<ExpandMoreIcon />}>
                {props.sectionTitle}
            </UploadProgressSectionTitle>
            <UploadProgressSectionContent>
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
            </UploadProgressSectionContent>
        </UploadProgressSection>
    );
};
