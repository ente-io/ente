import { EnteFile } from "@/new/photos/types/file";
import CopyButton from "@ente/shared/components/CodeBlock/CopyButton";
import { FlexWrapper } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { formatDate, formatTime } from "@ente/shared/time/format";
import BackupOutlined from "@mui/icons-material/BackupOutlined";
import CameraOutlined from "@mui/icons-material/CameraOutlined";
import FolderOutlined from "@mui/icons-material/FolderOutlined";
import LocationOnOutlined from "@mui/icons-material/LocationOnOutlined";
import TextSnippetOutlined from "@mui/icons-material/TextSnippetOutlined";
import { Box, DialogProps, Link, Stack, styled } from "@mui/material";
import { Chip } from "components/Chip";
import { EnteDrawer } from "components/EnteDrawer";
import Titlebar from "components/Titlebar";
import { UnidentifiedFaces } from "components/ml/PeopleList";
import LinkButton from "components/pages/gallery/LinkButton";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import { useContext, useEffect, useMemo, useState } from "react";
import { getEXIFLocation } from "services/exif";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";
import {
    getMapDisableConfirmationDialog,
    getMapEnableConfirmationDialog,
} from "utils/ui";
import { ExifData } from "./ExifData";
import InfoItem from "./InfoItem";
import MapBox from "./MapBox";
import { RenderCaption } from "./RenderCaption";
import { RenderCreationTime } from "./RenderCreationTime";
import { RenderFileName } from "./RenderFileName";

export const FileInfoSidebar = styled((props: DialogProps) => (
    <EnteDrawer {...props} anchor="right" />
))({
    zIndex: 1501,
    "& .MuiPaper-root": {
        padding: 8,
    },
});

interface Iprops {
    shouldDisableEdits?: boolean;
    showInfo: boolean;
    handleCloseInfo: () => void;
    file: EnteFile;
    exif: any;
    scheduleUpdate: () => void;
    refreshPhotoswipe: () => void;
    fileToCollectionsMap?: Map<number, number[]>;
    collectionNameMap?: Map<number, string>;
    showCollectionChips: boolean;
    closePhotoViewer: () => void;
}

function BasicDeviceCamera({
    parsedExifData,
}: {
    parsedExifData: Record<string, any>;
}) {
    return (
        <FlexWrapper gap={1}>
            <Box>{parsedExifData["fNumber"]}</Box>
            <Box>{parsedExifData["exposureTime"]}</Box>
            <Box>{parsedExifData["ISO"]}</Box>
        </FlexWrapper>
    );
}

function getOpenStreetMapLink(location: {
    latitude: number;
    longitude: number;
}) {
    return `https://www.openstreetmap.org/?mlat=${location.latitude}&mlon=${location.longitude}#map=15/${location.latitude}/${location.longitude}`;
}

export function FileInfo({
    shouldDisableEdits,
    showInfo,
    handleCloseInfo,
    file,
    exif,
    scheduleUpdate,
    refreshPhotoswipe,
    fileToCollectionsMap,
    collectionNameMap,
    showCollectionChips,
    closePhotoViewer,
}: Iprops) {
    const appContext = useContext(AppContext);
    const galleryContext = useContext(GalleryContext);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext,
    );

    const [parsedExifData, setParsedExifData] = useState<Record<string, any>>();
    const [showExif, setShowExif] = useState(false);

    const openExif = () => setShowExif(true);
    const closeExif = () => setShowExif(false);

    const location = useMemo(() => {
        if (file && file.metadata) {
            if (
                (file.metadata.latitude || file.metadata.latitude === 0) &&
                !(file.metadata.longitude === 0 && file.metadata.latitude === 0)
            ) {
                return {
                    latitude: file.metadata.latitude,
                    longitude: file.metadata.longitude,
                };
            }
        }
        if (exif) {
            const exifLocation = getEXIFLocation(exif);
            if (
                (exifLocation.latitude || exifLocation.latitude === 0) &&
                !(exifLocation.longitude === 0 && exifLocation.latitude === 0)
            ) {
                return exifLocation;
            }
        }
        return null;
    }, [file, exif]);

    useEffect(() => {
        if (!exif) {
            setParsedExifData({});
            return;
        }
        const parsedExifData = {};
        if (exif["fNumber"]) {
            parsedExifData["fNumber"] = `f/${Math.ceil(exif["FNumber"])}`;
        } else if (exif["ApertureValue"] && exif["FocalLength"]) {
            parsedExifData["fNumber"] = `f/${Math.ceil(
                exif["FocalLength"] / exif["ApertureValue"],
            )}`;
        }
        const imageWidth = exif["ImageWidth"] ?? exif["ExifImageWidth"];
        const imageHeight = exif["ImageHeight"] ?? exif["ExifImageHeight"];
        if (imageWidth && imageHeight) {
            parsedExifData["resolution"] = `${imageWidth} x ${imageHeight}`;
            const megaPixels = Math.round((imageWidth * imageHeight) / 1000000);
            if (megaPixels) {
                parsedExifData["megaPixels"] = `${Math.round(
                    (imageWidth * imageHeight) / 1000000,
                )}MP`;
            }
        }
        if (exif["Make"] && exif["Model"]) {
            parsedExifData["takenOnDevice"] =
                `${exif["Make"]} ${exif["Model"]}`;
        }
        if (exif["ExposureTime"]) {
            parsedExifData["exposureTime"] = `1/${
                1 / parseFloat(exif["ExposureTime"])
            }`;
        }
        if (exif["ISO"]) {
            parsedExifData["ISO"] = `ISO${exif["ISO"]}`;
        }
        setParsedExifData(parsedExifData);
    }, [exif]);

    if (!file) {
        return <></>;
    }
    const onCollectionChipClick = (collectionID) => {
        galleryContext.setActiveCollectionID(collectionID);
        galleryContext.setIsInSearchMode(false);
        closePhotoViewer();
    };

    const openEnableMapConfirmationDialog = () =>
        appContext.setDialogBoxAttributesV2(
            getMapEnableConfirmationDialog(() =>
                appContext.updateMapEnabled(true),
            ),
        );

    const openDisableMapConfirmationDialog = () =>
        appContext.setDialogBoxAttributesV2(
            getMapDisableConfirmationDialog(() =>
                appContext.updateMapEnabled(false),
            ),
        );

    return (
        <FileInfoSidebar open={showInfo} onClose={handleCloseInfo}>
            <Titlebar onClose={handleCloseInfo} title={t("INFO")} backIsClose />
            <Stack pt={1} pb={3} spacing={"20px"}>
                <RenderCaption
                    shouldDisableEdits={shouldDisableEdits}
                    file={file}
                    scheduleUpdate={scheduleUpdate}
                    refreshPhotoswipe={refreshPhotoswipe}
                />

                <RenderCreationTime
                    shouldDisableEdits={shouldDisableEdits}
                    file={file}
                    scheduleUpdate={scheduleUpdate}
                />

                <RenderFileName
                    parsedExifData={parsedExifData}
                    shouldDisableEdits={shouldDisableEdits}
                    file={file}
                    scheduleUpdate={scheduleUpdate}
                />
                {parsedExifData && parsedExifData["takenOnDevice"] && (
                    <InfoItem
                        icon={<CameraOutlined />}
                        title={parsedExifData["takenOnDevice"]}
                        caption={
                            <BasicDeviceCamera
                                parsedExifData={parsedExifData}
                            />
                        }
                        hideEditOption
                    />
                )}

                {location && (
                    <>
                        <InfoItem
                            icon={<LocationOnOutlined />}
                            title={t("LOCATION")}
                            caption={
                                !appContext.mapEnabled ||
                                publicCollectionGalleryContext.accessedThroughSharedURL ? (
                                    <Link
                                        href={getOpenStreetMapLink(location)}
                                        target="_blank"
                                        sx={{ fontWeight: "bold" }}
                                    >
                                        {t("SHOW_ON_MAP")}
                                    </Link>
                                ) : (
                                    <LinkButton
                                        onClick={
                                            openDisableMapConfirmationDialog
                                        }
                                        sx={{
                                            textDecoration: "none",
                                            color: "text.muted",
                                            fontWeight: "bold",
                                        }}
                                    >
                                        {t("DISABLE_MAP")}
                                    </LinkButton>
                                )
                            }
                            customEndButton={
                                <CopyButton
                                    code={getOpenStreetMapLink(location)}
                                    color="secondary"
                                    size="medium"
                                />
                            }
                        />
                        {!publicCollectionGalleryContext.accessedThroughSharedURL && (
                            <MapBox
                                location={location}
                                mapEnabled={appContext.mapEnabled}
                                openUpdateMapConfirmationDialog={
                                    openEnableMapConfirmationDialog
                                }
                            />
                        )}
                    </>
                )}
                <InfoItem
                    icon={<TextSnippetOutlined />}
                    title={t("DETAILS")}
                    caption={
                        typeof exif === "undefined" ? (
                            <EnteSpinner size={11.33} />
                        ) : exif !== null ? (
                            <LinkButton
                                onClick={openExif}
                                sx={{
                                    textDecoration: "none",
                                    color: "text.muted",
                                    fontWeight: "bold",
                                }}
                            >
                                {t("VIEW_EXIF")}
                            </LinkButton>
                        ) : (
                            t("NO_EXIF")
                        )
                    }
                    hideEditOption
                />
                <InfoItem
                    icon={<BackupOutlined />}
                    title={formatDate(file.metadata.modificationTime / 1000)}
                    caption={formatTime(file.metadata.modificationTime / 1000)}
                    hideEditOption
                />
                {showCollectionChips && (
                    <InfoItem icon={<FolderOutlined />} hideEditOption>
                        <Box
                            display={"flex"}
                            gap={1}
                            flexWrap="wrap"
                            justifyContent={"flex-start"}
                            alignItems={"flex-start"}
                        >
                            {fileToCollectionsMap
                                ?.get(file.id)
                                ?.filter((collectionID) =>
                                    collectionNameMap.has(collectionID),
                                )
                                ?.map((collectionID) => (
                                    <Chip
                                        key={collectionID}
                                        onClick={() =>
                                            onCollectionChipClick(collectionID)
                                        }
                                    >
                                        {collectionNameMap.get(collectionID)}
                                    </Chip>
                                ))}
                        </Box>
                    </InfoItem>
                )}

                {appContext.mlSearchEnabled && (
                    <>
                        {/* <PhotoPeopleList file={file} /> */}
                        <UnidentifiedFaces file={file} />
                    </>
                )}
            </Stack>
            <ExifData
                exif={exif}
                open={showExif}
                onClose={closeExif}
                onInfoClose={handleCloseInfo}
                filename={file.metadata.title}
            />
        </FileInfoSidebar>
    );
}
