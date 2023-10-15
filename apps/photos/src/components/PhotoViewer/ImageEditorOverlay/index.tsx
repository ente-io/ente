import { Backdrop, Box, IconButton, useTheme } from '@mui/material';
import { useEffect, useRef, useState, MouseEvent } from 'react';

import PhotoSizeSelectLargeIcon from '@mui/icons-material/PhotoSizeSelectLarge';
import { EnteFile } from 'types/file';
import { getRenderableFileURL } from 'utils/file';
import downloadManager from 'services/downloadManager';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import CropOriginalIcon from '@mui/icons-material/CropOriginal';
import CropSquareIcon from '@mui/icons-material/CropSquare';
import Crop169Icon from '@mui/icons-material/Crop169';
import Crop32Icon from '@mui/icons-material/Crop32';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import DownloadIcon from '@mui/icons-material/Download';
import mime from 'mime-types';
interface IProps {
    file: EnteFile;
}

const PRESET_ASPECT_RATIOS = [
    {
        width: 16,
        height: 9,
        icon: <CropSquareIcon />,
    },
    {
        width: 3,
        height: 2,
        icon: <Crop32Icon />,
    },
    {
        width: 16,
        height: 10,
        icon: <Crop169Icon />,
    },
];

const ImageEditorOverlay = (props: IProps) => {
    const [originalWidth, originalHeight] = [props.file.w, props.file.h];
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

    const loadCanvas = async () => {
        console.log(originalWidth, originalHeight);
        const img = new Image();
        const ctx = canvasRef.current?.getContext('2d');
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
            canvasRef.current.style.transition = 'width 0.5s, height 0.5s';
            canvasRef.current.style.width = `${width}px`;
            canvasRef.current.style.height = `${height}px`;
            // Apply CSS transition to animate the resizing

            ctx?.drawImage(img, 0, 0, width, height);

            setTimeout(() => {
                canvasRef.current.style.transition = 'none';
            }, 500); // Adjust the time to match your animation duration
        };
    };

    useEffect(() => {
        loadCanvas();
    }, []);

    const theme = useTheme();

    // Crops the canvas according to originalHeight and originalWidth without compounding
    const cropCanvas = (widthRatio: number, heightRatio: number) => {
        const context = canvasRef.current?.getContext('2d');
        const canvas = canvasRef.current;

        const aspectRatio = widthRatio / heightRatio;

        if (!context || !canvas) return;

        const img = new Image();
        img.src = fileURL;
        img.onload = () => {
            const sourceWidth = img.width;
            const sourceHeight = img.height;

            let sourceX = 0;
            let sourceY = 0;

            if (sourceWidth / sourceHeight > aspectRatio) {
                sourceX = (sourceWidth - sourceHeight * aspectRatio) / 2;
            } else {
                sourceY = (sourceHeight - sourceWidth / aspectRatio) / 2;
            }

            const newWidth = sourceWidth - 2 * sourceX;
            const newHeight = sourceHeight - 2 * sourceY;

            context.clearRect(0, 0, canvas.width, canvas.height);

            setCropLoading(true);
            // Apply CSS transition to animate the resizing
            canvas.style.transition = 'width 0.5s, height 0.5s';
            canvas.style.width = newWidth + 'px';
            canvas.style.height = newHeight + 'px';
            canvas.width = newWidth;
            canvas.height = newHeight;

            context.drawImage(
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

            setTimeout(() => {
                canvas.style.transition = 'none';
                setCropLoading(false);
            }, 500); // Adjust the time to match your animation duration
        };
    };

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
                    <Box display="flex" gap="0.5rem" alignItems="center">
                        <IconButton>
                            <PhotoSizeSelectLargeIcon />
                        </IconButton>
                    </Box>
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
                        <canvas
                            ref={canvasRef}
                            height={originalHeight}
                            width={originalWidth}
                            style={{
                                maxWidth: '100%',
                                maxHeight: '100%',
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
                    <MenuSectionTitle title={'Aspect Ratio'} />
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
                            label={'Original'}
                        />
                        <EnteMenuItem
                            disabled={cropLoading}
                            startIcon={<CropSquareIcon />}
                            onClick={() => {
                                cropCanvas(1, 1);
                            }}
                            label={'Square (1:1)'}
                        />
                    </MenuItemGroup>
                    <MenuItemGroup
                        style={{
                            marginBottom: '1rem',
                        }}>
                        {PRESET_ASPECT_RATIOS.map((ratio, index) => (
                            <EnteMenuItem
                                disabled={cropLoading}
                                key={index}
                                startIcon={ratio.icon}
                                onClick={() => {
                                    cropCanvas(ratio.width, ratio.height);
                                }}
                                label={`${ratio.width}:${ratio.height}`}
                            />
                        ))}
                    </MenuItemGroup>
                    <MenuItemGroup
                        style={{
                            marginBottom: '1rem',
                        }}>
                        {PRESET_ASPECT_RATIOS.map((ratio, index) => (
                            <EnteMenuItem
                                disabled={cropLoading}
                                key={index}
                                startIcon={ratio.icon}
                                onClick={() => {
                                    cropCanvas(ratio.height, ratio.width);
                                }}
                                label={`${ratio.height}:${ratio.width}`}
                            />
                        ))}
                    </MenuItemGroup>
                    <MenuSectionTitle title={'Export'} />
                    <MenuItemGroup>
                        <EnteMenuItem
                            startIcon={<DownloadIcon />}
                            onClick={() => {
                                exportCanvasToBlob((blob) => {
                                    // create a link
                                    const a = document.createElement('a');
                                    a.href = URL.createObjectURL(blob);
                                    a.download = props.file.metadata.title;
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
    );
};

export default ImageEditorOverlay;
