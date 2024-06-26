import { FILE_TYPE } from "@/media/file-type";
import { EnteFile } from "@/new/photos/types/file";
import { nameAndExtension } from "@/next/file";
import log from "@/next/log";
import { FlexWrapper } from "@ente/shared/components/Container";
import PhotoOutlined from "@mui/icons-material/PhotoOutlined";
import VideocamOutlined from "@mui/icons-material/VideocamOutlined";
import Box from "@mui/material/Box";
import { useEffect, useState } from "react";
import { changeFileName, updateExistingFilePubMetadata } from "utils/file";
import { formattedByteSize } from "utils/units";
import { FileNameEditDialog } from "./FileNameEditDialog";
import InfoItem from "./InfoItem";

const getFileTitle = (filename, extension) => {
    if (extension) {
        return filename + "." + extension;
    } else {
        return filename;
    }
};

const getCaption = (file: EnteFile, parsedExifData) => {
    const megaPixels = parsedExifData?.["megaPixels"];
    const resolution = parsedExifData?.["resolution"];
    const fileSize = file.info?.fileSize;

    const captionParts = [];
    if (megaPixels) {
        captionParts.push(megaPixels);
    }
    if (resolution) {
        captionParts.push(resolution);
    }
    if (fileSize) {
        captionParts.push(formattedByteSize(fileSize));
    }
    return (
        <FlexWrapper gap={1}>
            {captionParts.map((caption) => (
                <Box key={caption}> {caption}</Box>
            ))}
        </FlexWrapper>
    );
};

export function RenderFileName({
    parsedExifData,
    shouldDisableEdits,
    file,
    scheduleUpdate,
}: {
    parsedExifData: Record<string, any>;
    shouldDisableEdits: boolean;
    file: EnteFile;
    scheduleUpdate: () => void;
}) {
    const [isInEditMode, setIsInEditMode] = useState(false);
    const openEditMode = () => setIsInEditMode(true);
    const closeEditMode = () => setIsInEditMode(false);
    const [filename, setFilename] = useState<string>();
    const [extension, setExtension] = useState<string>();

    useEffect(() => {
        const [filename, extension] = nameAndExtension(file.metadata.title);
        setFilename(filename);
        setExtension(extension);
    }, [file]);

    const saveEdits = async (newFilename: string) => {
        try {
            if (file) {
                if (filename === newFilename) {
                    closeEditMode();
                    return;
                }
                setFilename(newFilename);
                const newTitle = getFileTitle(newFilename, extension);
                const updatedFile = await changeFileName(file, newTitle);
                updateExistingFilePubMetadata(file, updatedFile);
                scheduleUpdate();
            }
        } catch (e) {
            log.error("failed to update file name", e);
            throw e;
        }
    };

    return (
        <>
            <InfoItem
                icon={
                    file.metadata.fileType === FILE_TYPE.VIDEO ? (
                        <VideocamOutlined />
                    ) : (
                        <PhotoOutlined />
                    )
                }
                title={getFileTitle(filename, extension)}
                caption={getCaption(file, parsedExifData)}
                openEditor={openEditMode}
                hideEditOption={shouldDisableEdits || isInEditMode}
            />
            <FileNameEditDialog
                isInEditMode={isInEditMode}
                closeEditMode={closeEditMode}
                filename={filename}
                extension={extension}
                saveEdits={saveEdits}
            />
        </>
    );
}
