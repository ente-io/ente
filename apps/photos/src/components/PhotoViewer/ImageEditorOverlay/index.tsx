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
    MutableRefObject,
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
        canvasRef: MutableRefObject<HTMLCanvasElement>;
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
    const canvasDecoyParentRef = useRef<HTMLDivElement | null>(null);

    const [fileURL, setFileURL] = useState<string>('');

    const [cropLoading, setCropLoading] = useState<boolean>(false);

    const [currentRotationAngle, setCurrentRotationAngle] = useState(0);

    const [currentTab, setCurrentTab] = useState<'transform' | 'colours'>(
        'transform'
    );

    const [brightness, setBrightness] = useState(100);
    const [contrast, setContrast] = useState(100);
    const [blur, setBlur] = useState(0);
    const [saturation, setSaturation] = useState(100);
    const [invert, setInvert] = useState(false);

    const [originalCanvasDataURL, setOriginalCanvasDataURL] = useState('');

    useEffect(() => {
        if (!canvasRef.current) {
            return;
        }

        const filterString = `brightness(${brightness}%) contrast(${contrast}%) blur(${blur}px) saturate(${saturation}%) invert(${
            invert ? 1 : 0
        })`;

        canvasRef.current.style.filter = filterString;
    }, [brightness, contrast, blur, saturation, invert, canvasRef]);

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
        setCanvasLeft(0);
        setCanvasTop(0);
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

            setOriginalCanvasDataURL(canvasRef.current.toDataURL());

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

    const [isDragging, setIsDragging] = useState(false);
    const [isResizing, setIsResizing] = useState(false);
    const [canvasTop, setCanvasTop] = useState(0);
    const [canvasLeft, setCanvasLeft] = useState(0);

    const [mouseDownX, setMouseDownX] = useState(0);
    const [mouseDownY, setMouseDownY] = useState(0);
    const [originalCanvasWidth, setOriginalCanvasWidth] = useState(0);
    const [originalCanvasHeight, setOriginalCanvasHeight] = useState(0);

    useEffect(() => {
        if (!canvasRef) return;

        canvasRef.current.style.border = isResizing ? '1px solid red' : 'none';
    }, [isResizing, canvasRef]);

    const handleMouseMove = (event: MouseEvent) => {
        if (!isDragging && !isResizing) return;

        const canvasDecoyParent = canvasDecoyParentRef.current;
        if (!canvasDecoyParent || !canvasRef.current) return;

        const context = canvasRef.current?.getContext('2d');
        const canvas = canvasRef.current;
        if (!context || !canvas) return;
        context.imageSmoothingEnabled = false;

        const parentRect = canvasDecoyParent.getBoundingClientRect();
        const canvasRect = canvasRef.current.getBoundingClientRect();

        let newTop = event.clientY - parentRect.top - canvasRect.height / 2;
        let newLeft = event.clientX - parentRect.left - canvasRect.width / 2;

        if (newTop < 0) newTop = 0;
        if (newLeft < 0) newLeft = 0;
        if (newTop + canvasRect.height > parentRect.height)
            newTop = parentRect.height - canvasRect.height;
        if (newLeft + canvasRect.width > parentRect.width)
            newLeft = parentRect.width - canvasRect.width;

        if (isResizing) {
            // Resize
            let newWidth = originalCanvasWidth + event.clientX - mouseDownX;
            let newHeight = originalCanvasHeight + event.clientY - mouseDownY;

            // Adjust the position to keep the bottom right corner fixed
            if (newWidth <= 0) newWidth = 1;
            if (newHeight <= 0) newHeight = 1;

            // Calculate new height based on aspect ratio
            const aspectRatio = originalCanvasWidth / originalCanvasHeight;
            newHeight = newWidth / aspectRatio;

            const newTop = canvasTop;
            const newLeft = canvasLeft;

            setCanvasTop(newTop);
            setCanvasLeft(newLeft);

            canvasRef.current.width = newWidth;
            canvasRef.current.height = newHeight;

            return;
        } else {
            setCanvasTop(newTop);
            setCanvasLeft(newLeft);
        }

        activateSpotlight(newLeft, newTop);
    };

    const activateSpotlight = (newLeft: number, newTop: number) => {
        const context = canvasRef.current?.getContext('2d');
        const canvas = canvasRef.current;
        if (!context || !canvas) return;
        context.imageSmoothingEnabled = false;

        // // Create an image element
        // const img = new Image();
        // img.src = fileURL;
        const img = new Image();
        img.src = originalCanvasDataURL;

        // console.log('scaledHeight', scaledHeight);
        // console.log('canvasHeight', canvas.height);
        // console.log('scaledWidth', scaledWidth);

        // console.log('canvasWidth', canvas.width);

        // Wait for the image to load
        img.onload = () => {
            context.clearRect(0, 0, canvas.width, canvas.height);
            context.save();
            // Define the region of the image to be drawn
            // const sourceX = 0; // X coordinate of the top-left corner of the region
            // const sourceY = 0; // Y coordinate of the top-left corner of the region

            const sourceX = newLeft;
            const sourceY = newTop;

            const sourceWidth = canvas.width; // Width of the region
            const sourceHeight = canvas.height; // Height of the region
            // const sourceWidth = img.width; // Width of the region
            // const sourceHeight = img.height; // Height of the region
            // const sourceWidth = parentRect.width; // Width of the region
            // const sourceHeight = parentRect.height; // Height of the region

            // Draw the region of the image onto the canvas
            context.drawImage(
                img, // The image element
                sourceX,
                sourceY,
                sourceWidth,
                sourceHeight, // Region coordinates and dimensions
                0,
                0,
                sourceWidth,
                sourceHeight
                // scaledWidth,
                // scaledHeight // Destination coordinates and dimensions on the canvas
            );
            context.restore();
        };
    };

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
                                // onMouseDown={handleMouseDown}
                                // onMouseMove={handleMouseMove}
                                // onMouseUp={handleMouseUp}
                            >
                                {fileURL === null && <CircularProgress />}
                                <Box
                                    sx={{
                                        background: `rgb(0, 0, 0, .5) url(${fileURL})`,
                                        height: `${scaledHeight}px`,
                                        width: `${scaledWidth}px`,
                                        backgroundSize: 'cover',
                                        overflow: 'hidden',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        backgroundBlendMode: 'darken',
                                        // backgroundColor: '#808080',
                                        position: 'relative',
                                    }}
                                    onMouseDown={(event: MouseEvent) => {
                                        // if the click was outside of the canvas then return
                                        if (
                                            !canvasRef.current ||
                                            !canvasDecoyParentRef.current
                                        ) {
                                            return;
                                        }

                                        const canvas = canvasRef.current;

                                        const rect =
                                            canvas.getBoundingClientRect();

                                        const x = event.clientX - rect.left;

                                        const y = event.clientY - rect.top;

                                        if (x < 0 || y < 0) return;

                                        if (x > rect.width || y > rect.height)
                                            return;

                                        // if the click was near the bottom right corner then enable resizing
                                        const bottomRightCornerOfCanvas = {
                                            x: rect.width,
                                            y: rect.height,
                                        };

                                        // allow 10px tolerance
                                        const tolerance = 10;
                                        if (
                                            x >
                                                bottomRightCornerOfCanvas.x -
                                                    tolerance &&
                                            x <
                                                bottomRightCornerOfCanvas.x +
                                                    tolerance &&
                                            y >
                                                bottomRightCornerOfCanvas.y -
                                                    tolerance &&
                                            y <
                                                bottomRightCornerOfCanvas.y +
                                                    tolerance
                                        ) {
                                            setIsResizing(true);
                                            setMouseDownX(event.clientX);
                                            setMouseDownY(event.clientY);
                                            setOriginalCanvasHeight(
                                                canvas.height
                                            );
                                            setOriginalCanvasWidth(
                                                canvas.width
                                            );
                                        } else if (
                                            x <
                                                bottomRightCornerOfCanvas.x -
                                                    tolerance ||
                                            y <
                                                bottomRightCornerOfCanvas.y -
                                                    tolerance
                                        ) {
                                            setIsDragging(true);
                                        }
                                    }}
                                    onMouseUp={(event) => {
                                        if (!isDragging && !isResizing) return;
                                        setIsResizing(false);
                                        setIsDragging(false);

                                        if (isResizing) {
                                            const context =
                                                canvasRef.current?.getContext(
                                                    '2d'
                                                );
                                            const canvas = canvasRef.current;
                                            if (!context || !canvas) return;
                                            const canvasDecoyParent =
                                                canvasDecoyParentRef.current;
                                            if (
                                                !canvasDecoyParent ||
                                                !canvasRef.current
                                            )
                                                return;

                                            const parentRect =
                                                canvasDecoyParent.getBoundingClientRect();
                                            const canvasRect =
                                                canvasRef.current.getBoundingClientRect();

                                            const newTop =
                                                event.clientY -
                                                parentRect.top -
                                                canvasRect.height / 2;
                                            const newLeft =
                                                event.clientX -
                                                parentRect.left -
                                                canvasRect.width / 2;
                                            activateSpotlight(newLeft, newTop);
                                        }
                                    }}
                                    onMouseMove={handleMouseMove}
                                    ref={canvasDecoyParentRef}>
                                    <canvas
                                        ref={canvasRef}
                                        // height={originalHeight}
                                        // width={originalWidth}
                                        style={{
                                            objectFit: 'contain',
                                            // maxWidth: '100%',
                                            // maxHeight: '1000px',
                                            display:
                                                fileURL === null
                                                    ? 'none'
                                                    : 'block',
                                            position: 'absolute',
                                            // transform: `translate(${cropOffsetX}px, ${cropOffsetY}px)`,
                                            top: `${canvasTop}px`,
                                            left: `${canvasLeft}px`,
                                        }}
                                    />
                                </Box>
                            </Box>
                        </Box>
                        <Box
                            height="100%"
                            width="30rem"
                            bgcolor={theme.colors.background.elevated}
                            padding="1rem"
                            boxSizing="border-box"
                            sx={{
                                overflowY: 'auto',
                            }}>
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
                                        canvasRef,
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
