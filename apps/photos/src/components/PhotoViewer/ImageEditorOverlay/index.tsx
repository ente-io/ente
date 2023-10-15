import {
    Backdrop,
    Box,
    CircularProgress,
    IconButton,
    Tab,
    Tabs,
    useTheme,
} from '@mui/material';
import {
    useEffect,
    useRef,
    useState,
    MouseEvent,
    createContext,
    Dispatch,
    SetStateAction,
} from 'react';

import { EnteFile } from 'types/file';
import { getRenderableFileURL } from 'utils/file';
import downloadManager from 'services/downloadManager';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import CropOriginalIcon from '@mui/icons-material/CropOriginal';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import DownloadIcon from '@mui/icons-material/Download';
import mime from 'mime-types';
import CloseIcon from '@mui/icons-material/Close';
import { HorizontalFlex } from 'components/Container';
import TransformMenu from './TransformMenu';
import ColoursMenu from './ColoursMenu';
interface IProps {
    file: EnteFile;
    show: boolean;
    onClose: () => void;
}

export const ImageEditorOverlayContext = createContext(
    {} as {
        cropLoading: boolean;
        setCropLoading: Dispatch<SetStateAction<boolean>>;
    }
);

const ImageEditorOverlay = (props: IProps) => {
    const [originalWidth, originalHeight] = [props.file?.w, props.file?.h];
    const [scaledWidth, setScaledWidth] = useState(0);
    const [scaledHeight, setScaledHeight] = useState(0);

    const canvasRef = useRef<HTMLCanvasElement | null>(null);
    const parentRef = useRef<HTMLDivElement | null>(null);

    const [fileURL, setFileURL] = useState<string>('');

    const [cropLoading, setCropLoading] = useState<boolean>(false);

    const [isDragging, setIsDragging] = useState(false);
    const [dragStartX, setDragStartX] = useState(0);
    const [dragStartY, setDragStartY] = useState(0);
    const [cropOffsetX, setCropOffsetX] = useState(0);
    const [cropOffsetY, setCropOffsetY] = useState(0);

    const [currentRotationAngle, setCurrentRotationAngle] = useState(0);

    const [currentTab, setCurrentTab] = useState<'transform' | 'colours'>(
        'transform'
    );

    const [brightness, setBrightness] = useState(100);
    const [contrast, setContrast] = useState(100);
    const [blur, setBlur] = useState(0);
    const [saturation, setSaturation] = useState(100);
    const [invert, setInvert] = useState(false);

    useEffect(() => {
        const filterString = `brightness(${brightness}%) contrast(${contrast}%) blur(${blur}px) saturate(${saturation}%) invert(${
            invert ? 1 : 0
        })`;

        canvasRef.current.style.filter = filterString;
    }, [brightness, contrast, blur, saturation, invert]);

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
        resetFilters();
        setCurrentRotationAngle(0);
        console.log(originalWidth, originalHeight);
        const img = new Image();
        const ctx = canvasRef.current?.getContext('2d');
        ctx.imageSmoothingEnabled = false;
        if (!fileURL) {
            const stream = await downloadManager.downloadFile(props.file);
            const fileBlob = await new Response(stream).blob();
            const { converted } = await getRenderableFileURL(
                props.file,
                fileBlob
            );
            img.src = converted[0];
            setFileURL(converted[0]);
        } else {
            img.src = fileURL;
        }
        img.onload = () => {
            const scale = Math.min(
                parentRef.current?.clientWidth / img.width,
                parentRef.current?.clientHeight / img.height
            );
            const width = img.width * scale;
            setScaledWidth(width);
            const height = img.height * scale;
            setScaledHeight(height);
            canvasRef.current.width = width;
            canvasRef.current.height = height;
            // canvasRef.current.style.transition = 'width 0.5s, height 0.5s';
            // canvasRef.current.style.width = `${width}px`;
            // canvasRef.current.style.height = `${height}px`;
            // Apply CSS transition to animate the resizing

            ctx?.drawImage(img, 0, 0, width, height);

            setTimeout(() => {
                canvasRef.current.style.transition = 'none';
            }, 500); // Adjust the time to match your animation duration
        };
    };

    useEffect(() => {
        if (!props.show || !props.file) return;
        loadCanvas();
    }, [props.show, props.file]);

    const theme = useTheme();

    const exportCanvasToBlob = (callback: (blob: Blob) => void) => {
        const canvas = canvasRef.current;
        if (!canvas) return new Blob();

        const mimeType = mime.lookup(props.file.metadata.title);

        canvas.toBlob((blob) => {
            callback(blob);
        }, mimeType);
    };

    const [initialCropOffsetX, setInitialCropOffsetX] = useState(0);
    const [initialCropOffsetY, setInitialCropOffsetY] = useState(0);

    // Update initialCropOffsetX and initialCropOffsetY when dragging starts
    const handleMouseDown = (event: MouseEvent<HTMLDivElement>) => {
        setDragStartX(event.clientX);
        setDragStartY(event.clientY);
        setInitialCropOffsetX(cropOffsetX);
        setInitialCropOffsetY(cropOffsetY);
        setIsDragging(true);
    };

    const handleMouseMove = (event: MouseEvent<HTMLDivElement>) => {
        // Check if dragging is not happening, return early
        if (!isDragging) return;

        // Get the off-screen dimensions
        const offScreenWidth = canvasRef.current.width;
        const offScreenHeight = canvasRef.current.height;

        // Calculate the offset from the drag start position to the current mouse position
        const offsetX = dragStartX - event.clientX;
        const offsetY = dragStartY - event.clientY;

        // Calculate the new crop offset based on the drag offset and the limits of the image dimensions
        const newCropOffsetX = Math.max(
            Math.min(
                initialCropOffsetX + offsetX,
                originalWidth - offScreenWidth
            ),
            0
        );

        const newCropOffsetY = Math.max(
            Math.min(
                initialCropOffsetY + offsetY,
                originalHeight - offScreenHeight
            ),
            0
        );

        // Update the crop offsets
        setCropOffsetX(newCropOffsetX);
        setCropOffsetY(newCropOffsetY);
    };

    const handleMouseUp = () => {
        setIsDragging(false);
        setDragStartX(0);
        setDragStartY(0);
    };

    useEffect(() => {
        const canvas = canvasRef.current;
        const context = canvas?.getContext('2d');

        if (!canvas || !context) return;

        const offScreenCanvas = document.createElement('canvas');
        const offScreenContext = offScreenCanvas.getContext('2d');

        if (!offScreenContext) return;

        const offScreenWidth = scaledWidth;
        const offScreenHeight = scaledHeight;

        offScreenCanvas.width = offScreenWidth;
        offScreenCanvas.height = offScreenHeight;

        offScreenContext.clearRect(0, 0, offScreenWidth, offScreenHeight);

        const img = new Image();
        img.src = fileURL;
        img.onload = () => {
            const sourceX = cropOffsetX;
            const sourceY = cropOffsetY;
            const newWidth = offScreenWidth;
            const newHeight = offScreenHeight;

            offScreenContext.drawImage(
                img,
                sourceX,
                sourceY,
                newWidth,
                newHeight,
                0,
                0,
                newWidth,
                newHeight
            );

            context.clearRect(0, 0, canvas.width, canvas.height);
            context.drawImage(offScreenCanvas, 0, 0);
        };
    }, [cropOffsetX, cropOffsetY]);

    return (
        <>
            {props.show && (
                <>
                    <Backdrop
                        sx={{
                            color: '#fff',
                            zIndex: '999 !important',
                            display: 'flex',
                            width: '100%',
                            justifyContent: 'space-between',
                        }}
                        open>
                        <Box
                            display="inline-block"
                            width="100%"
                            height="100%"
                            overflow="hidden"
                            padding="3rem"
                            boxSizing={'border-box'}>
                            <Box
                                height="100%"
                                width="100%"
                                ref={parentRef}
                                display="flex"
                                alignItems="center"
                                justifyContent="center"
                                onMouseDown={handleMouseDown}
                                onMouseMove={handleMouseMove}
                                onMouseUp={handleMouseUp}>
                                {fileURL === null && <CircularProgress />}
                                <canvas
                                    ref={canvasRef}
                                    // height={originalHeight}
                                    // width={originalWidth}
                                    style={{
                                        maxWidth: '100%',
                                        maxHeight: '1000px',
                                        display:
                                            fileURL === null ? 'none' : 'block',
                                        // transform: `translate(${cropOffsetX}px, ${cropOffsetY}px)`,
                                    }}
                                />
                            </Box>
                        </Box>
                        <Box
                            height="100%"
                            width="30rem"
                            bgcolor={theme.colors.background.elevated}
                            padding="1rem"
                            boxSizing="border-box">
                            <HorizontalFlex justifyContent={'flex-end'}>
                                <IconButton
                                    onClick={() => {
                                        setFileURL(null);
                                        props.onClose();
                                    }}>
                                    <CloseIcon />
                                </IconButton>
                            </HorizontalFlex>
                            <HorizontalFlex gap="0.5rem">
                                <Tabs
                                    value={currentTab}
                                    onChange={(_, value) => {
                                        setCurrentTab(value);
                                    }}>
                                    <Tab label="Transform" value="transform" />
                                    <Tab label="Colours" value="colours" />
                                </Tabs>
                            </HorizontalFlex>
                            <MenuSectionTitle title="Reset" />
                            <MenuItemGroup
                                style={{
                                    marginBottom: '0.5rem',
                                }}>
                                <EnteMenuItem
                                    disabled={cropLoading}
                                    startIcon={<CropOriginalIcon />}
                                    onClick={() => {
                                        loadCanvas();
                                    }}
                                    label={'Restore Original'}
                                />
                            </MenuItemGroup>

                            {currentTab === 'transform' && (
                                <ImageEditorOverlayContext.Provider
                                    value={{
                                        cropLoading,
                                        setCropLoading,
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

                            <MenuSectionTitle title={'Export'} />
                            <MenuItemGroup>
                                <EnteMenuItem
                                    startIcon={<DownloadIcon />}
                                    onClick={() => {
                                        exportCanvasToBlob((blob) => {
                                            // create a link
                                            const a =
                                                document.createElement('a');
                                            a.href = URL.createObjectURL(blob);
                                            a.download =
                                                props.file.metadata.title;
                                            document.body.appendChild(a);
                                            a.click();
                                        });
                                    }}
                                    label={'Download Edited'}
                                />
                            </MenuItemGroup>
                        </Box>
                    </Backdrop>
                </>
            )}
        </>
    );
};

export default ImageEditorOverlay;
