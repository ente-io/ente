import {
    Backdrop,
    Box,
    CircularProgress,
    IconButton,
    Tab,
    Tabs,
    Typography,
} from '@mui/material';
import {
    useEffect,
    useRef,
    useState,
    createContext,
    Dispatch,
    SetStateAction,
    MutableRefObject,
    useContext,
} from 'react';

import { EnteFile } from 'types/file';
import downloadManager from 'services/download';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import CropOriginalIcon from '@mui/icons-material/CropOriginal';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import DownloadIcon from '@mui/icons-material/Download';
import mime from 'mime-types';
import CloseIcon from '@mui/icons-material/Close';
import { HorizontalFlex } from '@ente/shared/components/Container';
import TransformMenu from './TransformMenu';
import ColoursMenu from './ColoursMenu';
import { FileWithCollection } from 'types/upload';
import uploadManager from 'services/upload/uploadManager';
import { getLocalCollections } from 'services/collectionService';
import CloudUploadIcon from '@mui/icons-material/CloudUpload';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import { t } from 'i18next';
import { EnteDrawer } from 'components/EnteDrawer';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import MenuIcon from '@mui/icons-material/Menu';
import { AppContext } from 'pages/_app';
import { getEditorCloseConfirmationMessage } from 'utils/ui';
import { logError } from '@ente/shared/sentry';
import { getFileType } from 'services/typeDetectionService';
import { downloadUsingAnchor } from '@ente/shared/utils';

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
    }
);

const filterDefaultValues = {
    brightness: 100,
    contrast: 100,
    blur: 0,
    saturation: 100,
    invert: false,
};

const getEditedFileName = (fileName: string) => {
    const fileNameParts = fileName.split('.');
    const extension = fileNameParts.pop();
    const editedFileName = `${fileNameParts.join('.')}-edited.${extension}`;
    return editedFileName;
};

const ImageEditorOverlay = (props: IProps) => {
    const appContext = useContext(AppContext);

    const canvasRef = useRef<HTMLCanvasElement | null>(null);
    const originalSizeCanvasRef = useRef<HTMLCanvasElement | null>(null);
    const parentRef = useRef<HTMLDivElement | null>(null);

    const [fileURL, setFileURL] = useState<string>('');

    const [currentRotationAngle, setCurrentRotationAngle] = useState(0);

    const [currentTab, setCurrentTab] = useState<'transform' | 'colours'>(
        'transform'
    );

    const [brightness, setBrightness] = useState(
        filterDefaultValues.brightness
    );
    const [contrast, setContrast] = useState(filterDefaultValues.contrast);
    const [blur, setBlur] = useState(filterDefaultValues.blur);
    const [saturation, setSaturation] = useState(
        filterDefaultValues.saturation
    );
    const [invert, setInvert] = useState(filterDefaultValues.invert);

    const [transformationPerformed, setTransformationPerformed] =
        useState(false);
    const [coloursAdjusted, setColoursAdjusted] = useState(false);

    const [canvasLoading, setCanvasLoading] = useState(false);

    const [showControlsDrawer, setShowControlsDrawer] = useState(true);

    useEffect(() => {
        if (!canvasRef.current) {
            return;
        }
        try {
            applyFilters([canvasRef.current, originalSizeCanvasRef.current]);
            setColoursAdjusted(
                brightness !== filterDefaultValues.brightness ||
                    contrast !== filterDefaultValues.contrast ||
                    blur !== filterDefaultValues.blur ||
                    saturation !== filterDefaultValues.saturation ||
                    invert !== filterDefaultValues.invert
            );
        } catch (e) {
            logError(e, 'Error applying filters');
        }
    }, [brightness, contrast, blur, saturation, invert, canvasRef, fileURL]);

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
                const context = canvas.getContext('2d');
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
                                canvas.height
                            );
                            context.save();
                            context.drawImage(
                                image,
                                0,
                                0,
                                canvas.width,
                                canvas.height
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
            logError(e, 'Error applying filters');
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
            const ctx = canvasRef.current.getContext('2d');
            ctx.imageSmoothingEnabled = false;
            if (!fileURL) {
                const { converted } = await downloadManager.getFileForPreview(
                    props.file
                );
                img.src = converted[0];
                setFileURL(converted[0]);
            } else {
                img.src = fileURL;
            }

            await new Promise((resolve, reject) => {
                img.onload = () => {
                    try {
                        const scale = Math.min(
                            parentRef.current.clientWidth / img.width,
                            parentRef.current.clientHeight / img.height
                        );

                        const width = img.width * scale;
                        const height = img.height * scale;
                        canvasRef.current.width = width;
                        canvasRef.current.height = height;

                        ctx?.drawImage(img, 0, 0, width, height);

                        originalSizeCanvasRef.current.width = img.width;
                        originalSizeCanvasRef.current.height = img.height;

                        const oSCtx =
                            originalSizeCanvasRef.current.getContext('2d');

                        oSCtx?.drawImage(img, 0, 0, img.width, img.height);

                        setTransformationPerformed(false);
                        setColoursAdjusted(false);

                        setCanvasLoading(false);
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
            logError(e, 'Error loading canvas');
        }
    };

    useEffect(() => {
        if (!props.show || !props.file) return;
        loadCanvas();
    }, [props.show, props.file]);

    const exportCanvasToBlob = (): Promise<Blob> => {
        try {
            const canvas = originalSizeCanvasRef.current;
            if (!canvas) return;

            const mimeType = mime.lookup(props.file.metadata.title);

            const image = new Image();
            image.src = canvas.toDataURL();

            const context = canvas.getContext('2d');
            if (!context) return;
            return new Promise((resolve) => {
                canvas.toBlob(resolve, mimeType);
            });
        } catch (e) {
            logError(e, 'Error exporting canvas to blob');
            throw e;
        }
    };

    const getEditedFile = async () => {
        const blob = await exportCanvasToBlob();
        if (!blob) {
            throw Error('no blob');
        }
        const editedFileName = getEditedFileName(props.file.metadata.title);
        const editedFile = new File([blob], editedFileName);
        return editedFile;
    };

    const handleClose = () => {
        setFileURL(null);
        props.onClose();
    };

    const handleCloseWithConfirmation = () => {
        if (transformationPerformed || coloursAdjusted) {
            appContext.setDialogBoxAttributesV2(
                getEditorCloseConfirmationMessage(handleClose)
            );
        } else {
            handleClose();
        }
    };

    if (!props.show) {
        return <></>;
    }

    const downloadEditedPhoto = async () => {
        try {
            if (!canvasRef.current) return;

            const editedFile = await getEditedFile();
            const fileType = await getFileType(editedFile);
            const tempImgURL = URL.createObjectURL(
                new Blob([editedFile], { type: fileType.mimeType })
            );
            downloadUsingAnchor(tempImgURL, editedFile.name);
        } catch (e) {
            logError(e, 'Error downloading edited photo');
        }
    };

    const saveCopyToEnte = async () => {
        try {
            if (!canvasRef.current) return;

            const collections = await getLocalCollections();

            const collection = collections.find(
                (c) => c.id === props.file.collectionID
            );

            const editedFile = await getEditedFile();
            const file: FileWithCollection = {
                file: editedFile,
                collectionID: props.file.collectionID,
                localID: 1,
            };

            uploadManager.prepareForNewUpload();
            uploadManager.showUploadProgressDialog();
            uploadManager.queueFilesForUpload([file], [collection]);
            setFileURL(null);
            props.onClose();
            props.closePhotoViewer();
        } catch (e) {
            logError(e, 'Error saving copy to ente');
        }
    };
    return (
        <>
            <Backdrop
                sx={{
                    background: '#000',
                    zIndex: 1600,
                    width: '100%',
                }}
                open>
                <Box padding="1rem" width="100%" height="100%">
                    <HorizontalFlex
                        justifyContent={'space-between'}
                        alignItems={'center'}>
                        <Typography variant="h2" fontWeight="bold">
                            {t('PHOTO_EDITOR')}
                        </Typography>
                        <IconButton
                            onClick={() => {
                                setShowControlsDrawer(true);
                            }}>
                            <MenuIcon />
                        </IconButton>
                    </HorizontalFlex>
                    <Box
                        width="100%"
                        height="100%"
                        overflow="hidden"
                        boxSizing={'border-box'}
                        display="flex"
                        alignItems="center"
                        justifyContent="center">
                        <Box
                            height="90%"
                            width="100%"
                            ref={parentRef}
                            display="flex"
                            alignItems="center"
                            justifyContent="center">
                            {(fileURL === null || canvasLoading) && (
                                <CircularProgress />
                            )}

                            <canvas
                                ref={canvasRef}
                                style={{
                                    objectFit: 'contain',
                                    display:
                                        fileURL === null || canvasLoading
                                            ? 'none'
                                            : 'block',
                                    position: 'absolute',
                                }}
                            />
                            <canvas
                                ref={originalSizeCanvasRef}
                                style={{
                                    display: 'none',
                                }}
                            />
                        </Box>
                    </Box>
                </Box>
                <EnteDrawer
                    variant="persistent"
                    anchor="right"
                    open={showControlsDrawer}
                    onClose={handleCloseWithConfirmation}>
                    <HorizontalFlex justifyContent={'space-between'}>
                        <IconButton
                            onClick={() => {
                                setShowControlsDrawer(false);
                            }}>
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
                            }}>
                            <Tab label={t('TRANSFORM')} value="transform" />
                            <Tab
                                label={t('COLORS')}
                                value="colours"
                                disabled={transformationPerformed}
                            />
                        </Tabs>
                    </HorizontalFlex>
                    <MenuSectionTitle title={t('RESET')} />
                    <MenuItemGroup
                        style={{
                            marginBottom: '0.5rem',
                        }}>
                        <EnteMenuItem
                            disabled={canvasLoading}
                            startIcon={<CropOriginalIcon />}
                            onClick={() => {
                                loadCanvas();
                            }}
                            label={t('RESTORE_ORIGINAL')}
                        />
                    </MenuItemGroup>
                    {currentTab === 'transform' && (
                        <ImageEditorOverlayContext.Provider
                            value={{
                                originalSizeCanvasRef,
                                canvasRef,
                                setCanvasLoading,
                                canvasLoading,
                                setTransformationPerformed,
                            }}>
                            <TransformMenu />
                        </ImageEditorOverlayContext.Provider>
                    )}
                    {currentTab === 'colours' && (
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
                    <MenuSectionTitle title={t('EXPORT')} />
                    <MenuItemGroup>
                        <EnteMenuItem
                            startIcon={<DownloadIcon />}
                            onClick={downloadEditedPhoto}
                            label={t('DOWNLOAD_EDITED')}
                        />
                        <MenuItemDivider />
                        <EnteMenuItem
                            startIcon={<CloudUploadIcon />}
                            onClick={saveCopyToEnte}
                            label={t('SAVE_A_COPY_TO_ENTE')}
                        />
                    </MenuItemGroup>
                </EnteDrawer>
            </Backdrop>
        </>
    );
};

export default ImageEditorOverlay;
