import { useContext } from 'react';
import ItemList from 'components/ItemList';
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
import { CaptionedText } from 'components/CaptionedText';

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

    const renderListItem = (fileID) => {
        return (
            <ResultItemContainer key={fileID}>
                {uploadFileNames.get(fileID)}
            </ResultItemContainer>
        );
    };

    const getItemTitle = (fileID) => {
        return uploadFileNames.get(fileID);
    };

    const generateItemKey = (fileID) => {
        return fileID;
    };

    return (
        <UploadProgressSection>
            <UploadProgressSectionTitle expandIcon={<ExpandMoreIcon />}>
                <CaptionedText
                    mainText={props.sectionTitle}
                    subText={String(fileList?.length ?? 0)}
                />
            </UploadProgressSectionTitle>
            <UploadProgressSectionContent>
                {props.sectionInfo && (
                    <SectionInfo>{props.sectionInfo}</SectionInfo>
                )}
                <ItemList
                    items={fileList}
                    generateItemKey={generateItemKey}
                    getItemTitle={getItemTitle}
                    renderListItem={renderListItem}
                    maxHeight={160}
                    itemSize={35}
                />
            </UploadProgressSectionContent>
        </UploadProgressSection>
    );
};
