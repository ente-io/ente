import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import ItemList from "components/ItemList";
import { t } from "i18next";
import { useContext } from "react";
import UploadProgressContext from "./context";
import {
    SectionInfo,
    UploadProgressSection,
    UploadProgressSectionContent,
    UploadProgressSectionTitle,
} from "./section";
import { InProgressItemContainer } from "./styledComponents";

import { CaptionedText } from "components/CaptionedText";

export const InProgressSection = () => {
    const { inProgressUploads, hasLivePhotos, uploadFileNames, uploadPhase } =
        useContext(UploadProgressContext);
    const fileList = inProgressUploads ?? [];

    const renderListItem = ({ localFileID, progress }) => {
        return (
            <InProgressItemContainer key={localFileID}>
                <span>{uploadFileNames.get(localFileID)}</span>
                {uploadPhase == "uploading" && (
                    <>
                        {" "}
                        <span className="separator">{`-`}</span>
                        <span>{`${progress}%`}</span>
                    </>
                )}
            </InProgressItemContainer>
        );
    };

    const getItemTitle = ({ localFileID, progress }) => {
        return `${uploadFileNames.get(localFileID)} - ${progress}%`;
    };

    const generateItemKey = ({ localFileID, progress }) => {
        return `${localFileID}-${progress}`;
    };

    return (
        <UploadProgressSection>
            <UploadProgressSectionTitle expandIcon={<ExpandMoreIcon />}>
                <CaptionedText
                    mainText={
                        uploadPhase == "extractingMetadata"
                            ? t("INPROGRESS_METADATA_EXTRACTION")
                            : t("INPROGRESS_UPLOADS")
                    }
                    subText={String(inProgressUploads?.length ?? 0)}
                />
            </UploadProgressSectionTitle>
            <UploadProgressSectionContent>
                {hasLivePhotos && (
                    <SectionInfo>{t("LIVE_PHOTOS_DETECTED")}</SectionInfo>
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
