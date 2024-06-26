import { EnteFile } from "@/new/photos/types/file";
import { nameAndExtension } from "@/next/file";
import log from "@/next/log";
import { ensure } from "@/utils/ensure";
import {
    CenteredFlex,
    HorizontalFlex,
} from "@ente/shared/components/Container";
import EnteButton from "@ente/shared/components/EnteButton";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import { downloadUsingAnchor } from "@ente/shared/utils";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import CloseIcon from "@mui/icons-material/Close";
import CloudUploadIcon from "@mui/icons-material/CloudUpload";
import CropIcon from "@mui/icons-material/Crop";
import CropOriginalIcon from "@mui/icons-material/CropOriginal";
import DownloadIcon from "@mui/icons-material/Download";
import MenuIcon from "@mui/icons-material/Menu";
import {
    Backdrop,
    Box,
    CircularProgress,
    IconButton,
    Tab,
    Tabs,
    Typography,
} from "@mui/material";
import { EnteDrawer } from "components/EnteDrawer";
import MenuItemDivider from "components/Menu/MenuItemDivider";
import { MenuItemGroup } from "components/Menu/MenuItemGroup";
import MenuSectionTitle from "components/Menu/MenuSectionTitle";
import { CORNER_THRESHOLD, FILTER_DEFAULT_VALUES } from "constants/photoEditor";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import type { Dispatch, MutableRefObject, SetStateAction } from "react";
import { createContext, useContext, useEffect, useRef, useState } from "react";
import { getLocalCollections } from "services/collectionService";
import downloadManager from "services/download";
import uploadManager from "services/upload/uploadManager";
import { getEditorCloseConfirmationMessage } from "utils/ui";
import ColoursMenu from "./ColoursMenu";
import CropMenu, { cropRegionOfCanvas, getCropRegionArgs } from "./CropMenu";
import FreehandCropRegion from "./FreehandCropRegion";
import TransformMenu from "./TransformMenu";

interface IProps {
    file: EnteFile;
    show: boolean;
    onClose: () => void;
    closePhotoViewer: () => void;
}

export const ImageEditorOverlayContext = createContext(
    {} as {
        canvasRef: MutableRefObject<HTMLCanvasElement>;
        originalSizeCanvasRef: MutableRefObject<HTMLCanvasElement>;
        setTransformationPerformed: Dispatch<SetStateAction<boolean>>;
        setCanvasLoading: Dispatch<SetStateAction<boolean>>;
        canvasLoading: boolean;
        setCurrentTab: Dispatch<SetStateAction<OperationTab>>;
    },
);

type OperationTab = "crop" | "transform" | "colours";

export interface CropBoxProps {
    x: number;
    y: number;
    width: number;
    height: number;
}

const ImageEditorOverlay = (props: IProps) => {
    const appContext = useContext(AppContext);

    const canvasRef = useRef<HTMLCanvasElement | null>(null);
    const originalSizeCanvasRef = useRef<HTMLCanvasElement | null>(null);
    const parentRef = useRef<HTMLDivElement | null>(null);

    const [fileURL, setFileURL] = useState<string>("");
    // The MIME type of the original file that we are editing.
    //
    // It _should_ generally be present, but it is not guaranteed to be.
    const [mimeType, setMIMEType] = useState<string | undefined>();

    const [currentRotationAngle, setCurrentRotationAngle] = useState(0);

    const [currentTab, setCurrentTab] = useState<OperationTab>("transform");

    const [brightness, setBrightness] = useState(
        FILTER_DEFAULT_VALUES.brightness,
    );
    const [contrast, setContrast] = useState(FILTER_DEFAULT_VALUES.contrast);
    const [blur, setBlur] = useState(FILTER_DEFAULT_VALUES.blur);
    const [saturation, setSaturation] = useState(
        FILTER_DEFAULT_VALUES.saturation,
    );
    const [invert, setInvert] = useState(FILTER_DEFAULT_VALUES.invert);

    const [transformationPerformed, setTransformationPerformed] =
        useState(false);
    const [coloursAdjusted, setColoursAdjusted] = useState(false);

    const [canvasLoading, setCanvasLoading] = useState(false);

    const [showControlsDrawer, setShowControlsDrawer] = useState(true);

    const [previewCanvasScale, setPreviewCanvasScale] = useState(0);

    const [cropBox, setCropBox] = useState<CropBoxProps>({
        x: 0,
        y: 0,
        width: 100,
        height: 100,
    });

    const [startX, setStartX] = useState(0);
    const [startY, setStartY] = useState(0);

    const [beforeGrowthHeight, setBeforeGrowthHeight] = useState(0);
    const [beforeGrowthWidth, setBeforeGrowthWidth] = useState(0);

    const [isDragging, setIsDragging] = useState(false);
    const [isGrowing, setIsGrowing] = useState(false);

    const cropBoxRef = useRef<HTMLDivElement>(null);

    const getCanvasBoundsOffsets = () => {
        const canvasBounds = {
            height: canvasRef.current.height,
            width: canvasRef.current.width,
        };
        const parentBounds = parentRef.current.getBoundingClientRect();

        // calculate the offset created by centering the canvas in its parent
        const offsetX = (parentBounds.width - canvasBounds.width) / 2;
        const offsetY = (parentBounds.height - canvasBounds.height) / 2;

        return {
            offsetY,
            offsetX,
            canvasBounds,
            parentBounds,
        };
    };

    const handleDragStart = (e) => {
        if (currentTab !== "crop") return;

        const rect = cropBoxRef.current.getBoundingClientRect();
        const offsetX = e.pageX - rect.left - rect.width / 2;
        const offsetY = e.pageY - rect.top - rect.height / 2;

        // check if the cursor is near the corners of the box
        const isNearLeftOrRightEdge =
            e.pageX < rect.left + CORNER_THRESHOLD ||
            e.pageX > rect.right - CORNER_THRESHOLD;
        const isNearTopOrBottomEdge =
            e.pageY < rect.top + CORNER_THRESHOLD ||
            e.pageY > rect.bottom - CORNER_THRESHOLD;

        if (isNearLeftOrRightEdge && isNearTopOrBottomEdge) {
            // cursor is near a corner, do not initiate dragging
            setIsGrowing(true);
            setStartX(e.pageX);
            setStartY(e.pageY);
            setBeforeGrowthWidth(cropBox.width);
            setBeforeGrowthHeight(cropBox.height);
            return;
        }

        setIsDragging(true);
        setStartX(e.pageX - offsetX);
        setStartY(e.pageY - offsetY);
    };

    const handleDrag = (e) => {
        if (!isDragging && !isGrowing) return;

        // d- variables are the delta change between start and now
        const dx = e.pageX - startX;
        const dy = e.pageY - startY;

        const { offsetX, offsetY, canvasBounds } = getCanvasBoundsOffsets();

        if (isGrowing) {
            setCropBox((prev) => {
                const newWidth = Math.min(
                    beforeGrowthWidth + dx,
                    canvasBounds.width - prev.x + offsetX,
                );
                const newHeight = Math.min(
                    beforeGrowthHeight + dy,
                    canvasBounds.height - prev.y + offsetY,
                );

                return {
                    ...prev,
                    width: newWidth,
                    height: newHeight,
                };
            });
        } else {
            setCropBox((prev) => {
                let newX = prev.x + dx;
                let newY = prev.y + dy;

                // constrain the new position to the canvas boundaries, accounting for the offset
                newX = Math.max(
                    offsetX,
                    Math.min(newX, offsetX + canvasBounds.width - prev.width),
                );
                newY = Math.max(
                    offsetY,
                    Math.min(newY, offsetY + canvasBounds.height - prev.height),
                );

                return {
                    ...prev,
                    x: newX,
                    y: newY,
                };
            });
            setStartX(e.pageX);
            setStartY(e.pageY);
        }
    };

    const handleDragEnd = () => {
        setStartX(0);
        setStartY(0);

        setIsGrowing(false);
        setIsDragging(false);
    };

    const resetCropBox = () => {
        setCropBox((prev) => {
            const { offsetX, offsetY, canvasBounds } = getCanvasBoundsOffsets();

            return {
                ...prev,
                x: offsetX,
                y: offsetY,
                height: canvasBounds.height,
                width: canvasBounds.width,
            };
        });
    };

    useEffect(() => {
        if (!canvasRef.current) {
            return;
        }
        try {
            applyFilters([canvasRef.current, originalSizeCanvasRef.current]);
            setColoursAdjusted(
                brightness !== FILTER_DEFAULT_VALUES.brightness ||
                    contrast !== FILTER_DEFAULT_VALUES.contrast ||
                    blur !== FILTER_DEFAULT_VALUES.blur ||
                    saturation !== FILTER_DEFAULT_VALUES.saturation ||
                    invert !== FILTER_DEFAULT_VALUES.invert,
            );
        } catch (e) {
            log.error("Error applying filters", e);
        }
    }, [brightness, contrast, blur, saturation, invert, canvasRef, fileURL]);

    useEffect(() => {
        if (currentTab !== "crop") return;
        resetCropBox();
        setShowControlsDrawer(false);
    }, [currentTab]);

    const applyFilters = async (canvases: HTMLCanvasElement[]) => {
        try {
            for (const canvas of canvases) {
                const blurSizeRatio =
                    Math.min(canvas.width, canvas.height) /
                    Math.min(canvasRef.current.width, canvasRef.current.height);
                const blurRadius = blurSizeRatio * blur;
                const filterString = `brightness(${brightness}%) contrast(${contrast}%) blur(${blurRadius}px) saturate(${saturation}%) invert(${
                    invert ? 1 : 0
                })`;
                const context = canvas.getContext("2d");
                context.imageSmoothingEnabled = false;

                context.filter = filterString;

                const image = new Image();
                image.src = fileURL;

                await new Promise((resolve, reject) => {
                    image.onload = () => {
                        try {
                            context.clearRect(
                                0,
                                0,
                                canvas.width,
                                canvas.height,
                            );
                            context.save();
                            context.drawImage(
                                image,
                                0,
                                0,
                                canvas.width,
                                canvas.height,
                            );
                            context.restore();
                            resolve(true);
                        } catch (e) {
                            reject(e);
                        }
                    };
                });
            }
        } catch (e) {
            log.error("Error applying filters", e);
            throw e;
        }
    };

    useEffect(() => {
        if (currentRotationAngle >= 360 || currentRotationAngle <= -360) {
            // set back to 0
            setCurrentRotationAngle(0);
        }
    }, [currentRotationAngle]);

    const resetFilters = () => {
        setBrightness(100);
        setContrast(100);
        setBlur(0);
        setSaturation(100);
        setInvert(false);
    };

    const loadCanvas = async () => {
        try {
            if (
                !canvasRef.current ||
                !parentRef.current ||
                !originalSizeCanvasRef.current
            ) {
                return;
            }

            setCanvasLoading(true);

            resetFilters();
            setCurrentRotationAngle(0);

            const img = new Image();
            const ctx = canvasRef.current.getContext("2d");
            ctx.imageSmoothingEnabled = false;
            if (!fileURL) {
                const srcURLs = await downloadManager.getFileForPreview(
                    props.file,
                );
                img.src = srcURLs.url as string;
                setFileURL(srcURLs.url as string);
                // We're casting the srcURLs.url to string above, i.e. this code
                // is not meant to run for the live photos scenario. For images,
                // we usually will have the mime type.
                setMIMEType(srcURLs.mimeType);
            } else {
                img.src = fileURL;
            }

            await new Promise((resolve, reject) => {
                img.onload = () => {
                    try {
                        const scale = Math.min(
                            parentRef.current.clientWidth / img.width,
                            parentRef.current.clientHeight / img.height,
                        );
                        setPreviewCanvasScale(scale);

                        const width = img.width * scale;
                        const height = img.height * scale;
                        canvasRef.current.width = width;
                        canvasRef.current.height = height;

                        ctx?.drawImage(img, 0, 0, width, height);

                        originalSizeCanvasRef.current.width = img.width;
                        originalSizeCanvasRef.current.height = img.height;

                        const oSCtx =
                            originalSizeCanvasRef.current.getContext("2d");

                        oSCtx?.drawImage(img, 0, 0, img.width, img.height);

                        setTransformationPerformed(false);
                        setColoursAdjusted(false);

                        setCanvasLoading(false);

                        resetCropBox();
                        setStartX(0);
                        setStartY(0);
                        setIsDragging(false);
                        setIsGrowing(false);

                        resolve(true);
                    } catch (e) {
                        reject(e);
                    }
                };
                img.onerror = (e) => {
                    reject(e);
                };
            });
        } catch (e) {
            log.error("Error loading canvas", e);
        }
    };

    useEffect(() => {
        if (!props.show || !props.file) return;
        loadCanvas();
    }, [props.show, props.file]);

    const handleClose = () => {
        setFileURL(null);
        props.onClose();
    };

    const handleCloseWithConfirmation = () => {
        if (transformationPerformed || coloursAdjusted) {
            appContext.setDialogBoxAttributesV2(
                getEditorCloseConfirmationMessage(handleClose),
            );
        } else {
            handleClose();
        }
    };

    if (!props.show) {
        return <></>;
    }

    const getEditedFile = async () => {
        const originalSizeCanvas = ensure(originalSizeCanvasRef.current);
        const originalFileName = props.file.metadata.title;
        return canvasToFile(originalSizeCanvas, originalFileName, mimeType);
    };

    const downloadEditedPhoto = async () => {
        if (!canvasRef.current) return;

        const f = await getEditedFile();
        // Revokes the URL after downloading.
        downloadUsingAnchor(URL.createObjectURL(f), f.name);
    };

    const saveCopyToEnte = async () => {
        if (!canvasRef.current) return;
        try {
            const collections = await getLocalCollections();

            const collection = collections.find(
                (c) => c.id === props.file.collectionID,
            );

            const editedFile = await getEditedFile();
            const file = {
                uploadItem: editedFile,
                localID: 1,
                collectionID: props.file.collectionID,
            };

            uploadManager.prepareForNewUpload();
            uploadManager.showUploadProgressDialog();
            uploadManager.uploadItems([file], [collection]);
            setFileURL(null);
            props.onClose();
            props.closePhotoViewer();
        } catch (e) {
            log.error("Error saving copy to ente", e);
        }
    };
    return (
        <>
            <Backdrop
                sx={{
                    background: "#000",
                    zIndex: 1600,
                    width: "100%",
                }}
                open
            >
                <Box padding="1rem" width="100%" height="100%">
                    <HorizontalFlex
                        justifyContent={"space-between"}
                        alignItems={"center"}
                    >
                        <Typography variant="h2" fontWeight="bold">
                            {t("PHOTO_EDITOR")}
                        </Typography>
                        <IconButton
                            onClick={() => {
                                setShowControlsDrawer(true);
                            }}
                        >
                            <MenuIcon />
                        </IconButton>
                    </HorizontalFlex>
                    <Box
                        width="100%"
                        height="100%"
                        overflow="hidden"
                        boxSizing={"border-box"}
                        display="flex"
                        alignItems="center"
                        justifyContent="center"
                        position="relative"
                        onMouseUp={handleDragEnd}
                        onMouseMove={isDragging ? handleDrag : null}
                        onMouseDown={handleDragStart}
                    >
                        <Box
                            style={{
                                position: "relative",
                                width: "100%",
                                height: "100%",
                            }}
                        >
                            <Box
                                height="90%"
                                width="100%"
                                ref={parentRef}
                                display="flex"
                                alignItems="center"
                                justifyContent="center"
                                position="relative"
                            >
                                {(fileURL === null || canvasLoading) && (
                                    <CircularProgress />
                                )}

                                <canvas
                                    ref={canvasRef}
                                    style={{
                                        objectFit: "contain",
                                        display:
                                            fileURL === null || canvasLoading
                                                ? "none"
                                                : "block",
                                        position: "absolute",
                                    }}
                                />
                                <canvas
                                    ref={originalSizeCanvasRef}
                                    style={{
                                        display: "none",
                                    }}
                                />

                                {currentTab === "crop" && (
                                    <FreehandCropRegion
                                        cropBox={cropBox}
                                        ref={cropBoxRef}
                                        setIsDragging={setIsDragging}
                                    />
                                )}
                            </Box>
                            {currentTab === "crop" && (
                                <CenteredFlex marginTop="1rem">
                                    <EnteButton
                                        color="accent"
                                        startIcon={<CropIcon />}
                                        onClick={() => {
                                            if (
                                                !cropBoxRef.current ||
                                                !canvasRef.current
                                            )
                                                return;

                                            const { x1, x2, y1, y2 } =
                                                getCropRegionArgs(
                                                    cropBoxRef.current,
                                                    canvasRef.current,
                                                );
                                            setCanvasLoading(true);
                                            setTransformationPerformed(true);
                                            cropRegionOfCanvas(
                                                canvasRef.current,
                                                x1,
                                                y1,
                                                x2,
                                                y2,
                                            );
                                            cropRegionOfCanvas(
                                                originalSizeCanvasRef.current,
                                                x1 / previewCanvasScale,
                                                y1 / previewCanvasScale,
                                                x2 / previewCanvasScale,
                                                y2 / previewCanvasScale,
                                            );
                                            resetCropBox();
                                            setCanvasLoading(false);

                                            setCurrentTab("transform");
                                        }}
                                    >
                                        {t("APPLY_CROP")}
                                    </EnteButton>
                                </CenteredFlex>
                            )}
                        </Box>
                    </Box>
                </Box>
                <EnteDrawer
                    variant="persistent"
                    anchor="right"
                    open={showControlsDrawer}
                    onClose={handleCloseWithConfirmation}
                >
                    <HorizontalFlex justifyContent={"space-between"}>
                        <IconButton
                            onClick={() => {
                                setShowControlsDrawer(false);
                            }}
                        >
                            <ChevronRightIcon />
                        </IconButton>
                        <IconButton onClick={handleCloseWithConfirmation}>
                            <CloseIcon />
                        </IconButton>
                    </HorizontalFlex>
                    <HorizontalFlex gap="0.5rem" marginBottom="1rem">
                        <Tabs
                            value={currentTab}
                            onChange={(_, value) => {
                                setCurrentTab(value);
                            }}
                        >
                            <Tab label={t("editor.crop")} value="crop" />
                            <Tab label={t("TRANSFORM")} value="transform" />
                            <Tab
                                label={t("COLORS")}
                                value="colours"
                                disabled={transformationPerformed}
                            />
                        </Tabs>
                    </HorizontalFlex>
                    <MenuSectionTitle title={t("RESET")} />
                    <MenuItemGroup
                        style={{
                            marginBottom: "0.5rem",
                        }}
                    >
                        <EnteMenuItem
                            disabled={canvasLoading}
                            startIcon={<CropOriginalIcon />}
                            onClick={() => {
                                loadCanvas();
                            }}
                            label={t("RESTORE_ORIGINAL")}
                        />
                    </MenuItemGroup>
                    <ImageEditorOverlayContext.Provider
                        value={{
                            originalSizeCanvasRef,
                            canvasRef,
                            setCanvasLoading,
                            canvasLoading,
                            setTransformationPerformed,
                            setCurrentTab,
                        }}
                    >
                        {currentTab === "crop" && (
                            <CropMenu
                                previewScale={previewCanvasScale}
                                cropBoxProps={cropBox}
                                cropBoxRef={cropBoxRef}
                                resetCropBox={resetCropBox}
                            />
                        )}
                        {currentTab === "transform" && <TransformMenu />}
                    </ImageEditorOverlayContext.Provider>
                    {currentTab === "colours" && (
                        <ColoursMenu
                            brightness={brightness}
                            contrast={contrast}
                            saturation={saturation}
                            blur={blur}
                            invert={invert}
                            setBrightness={setBrightness}
                            setContrast={setContrast}
                            setSaturation={setSaturation}
                            setBlur={setBlur}
                            setInvert={setInvert}
                        />
                    )}
                    <MenuSectionTitle title={t("EXPORT")} />
                    <MenuItemGroup>
                        <EnteMenuItem
                            startIcon={<DownloadIcon />}
                            onClick={downloadEditedPhoto}
                            label={t("DOWNLOAD_EDITED")}
                            disabled={
                                !transformationPerformed && !coloursAdjusted
                            }
                        />
                        <MenuItemDivider />
                        <EnteMenuItem
                            startIcon={<CloudUploadIcon />}
                            onClick={saveCopyToEnte}
                            label={t("SAVE_A_COPY_TO_ENTE")}
                            disabled={
                                !transformationPerformed && !coloursAdjusted
                            }
                        />
                    </MenuItemGroup>
                    {!transformationPerformed && !coloursAdjusted && (
                        <MenuSectionTitle
                            title={t("PHOTO_EDIT_REQUIRED_TO_SAVE")}
                        />
                    )}
                </EnteDrawer>
            </Backdrop>
        </>
    );
};

export default ImageEditorOverlay;

/**
 * Create a new {@link File} with the contents of the given canvas.
 *
 * @param canvas A {@link HTMLCanvasElement} whose contents we want to download
 * as a file.
 *
 * @param originalFileName The name of the original file which was used to seed
 * the canvas. This will be used as a base name for the generated file (with an
 * "-edited" suffix).
 *
 * @param originalMIMEType The MIME type of the original file which was used to
 * seed the canvas. When possible, we try to download a file in the same format,
 * but this is not guaranteed and depends on browser support. If the original
 * MIME type can not be preserved, a PNG file will be downloaded.
 */
const canvasToFile = async (
    canvas: HTMLCanvasElement,
    originalFileName: string,
    originalMIMEType?: string,
): Promise<File> => {
    const image = new Image();
    image.src = canvas.toDataURL();

    // Browsers are required to support "image/png". They may also support
    // "image/jpeg" and "image/webp". Potentially they may even support more
    // formats, but to keep this scoped we limit to these three.
    let [mimeType, extension] = ["image/png", "png"];
    switch (originalMIMEType) {
        case "image/jpeg":
            mimeType = originalMIMEType;
            extension = "jpeg";
            break;
        case "image/webp":
            mimeType = originalMIMEType;
            extension = "webp";
            break;
        default:
            break;
    }

    const blob = ensure(
        await new Promise<Blob>((resolve) => canvas.toBlob(resolve, mimeType)),
    );

    const [originalName] = nameAndExtension(originalFileName);
    const fileName = `${originalName}-edited.${extension}`;

    log.debug(() => ({ a: "canvas => file", blob, type: blob.type, mimeType }));

    return new File([blob], fileName);
};
