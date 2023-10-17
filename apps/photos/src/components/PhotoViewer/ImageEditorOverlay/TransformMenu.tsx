import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { useContext } from 'react';
import { ImageEditorOverlayContext } from '.';
import CropSquareIcon from '@mui/icons-material/CropSquare';
import Crop169Icon from '@mui/icons-material/Crop169';
import Crop32Icon from '@mui/icons-material/Crop32';
import RotateLeftIcon from '@mui/icons-material/RotateLeft';
import RotateRightIcon from '@mui/icons-material/RotateRight';
import FlipIcon from '@mui/icons-material/Flip';

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

const TransformMenu = () => {
    const {
        canvasRef,
        originalSizeCanvasRef,
        cropLoading,
        setCropLoading,
        // setNonFilteredFileURL
        setTransformationPerformed,
    } = useContext(ImageEditorOverlayContext);

    // Crops the canvas according to originalHeight and originalWidth without compounding
    const cropCanvas = (
        canvas: HTMLCanvasElement,
        widthRatio: number,
        heightRatio: number
    ) => {
        const context = canvas.getContext('2d');

        const aspectRatio = widthRatio / heightRatio;

        if (!context || !canvas) return;
        context.imageSmoothingEnabled = false;

        const img = new Image();
        img.src = canvas.toDataURL();
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

            setCropLoading(false);

            // setNonFilteredFileURL(canvas.toDataURL());
        };
    };
    const flipCanvas = (
        canvas: HTMLCanvasElement,
        direction: 'vertical' | 'horizontal'
    ) => {
        const context = canvas.getContext('2d');
        context.imageSmoothingEnabled = false;
        if (!context || !canvas) return;
        const img = new Image();
        // img.src = fileURL;
        img.src = canvas.toDataURL();

        img.onload = () => {
            context.clearRect(0, 0, canvas.width, canvas.height);

            context.save();

            if (direction === 'vertical') {
                context.translate(canvas.width, 0);
                context.scale(-1, 1);
            } else {
                context.translate(0, canvas.height);
                context.scale(1, -1);
            }

            context.drawImage(img, 0, 0, canvas.width, canvas.height);

            context.restore();

            // setNonFilteredFileURL(canvas.toDataURL());
        };
    };

    const rotateCanvas = (canvas: HTMLCanvasElement, angle: number) => {
        const context = canvas?.getContext('2d');
        if (!context || !canvas) return;
        context.imageSmoothingEnabled = false;

        const image = new Image();
        image.src = canvas.toDataURL();

        image.onload = () => {
            context.clearRect(0, 0, canvas.width, canvas.height);

            context.save();

            const radians = (angle * Math.PI) / 180;
            const sin = Math.sin(radians);
            const cos = Math.cos(radians);
            const newWidth =
                Math.abs(image.width * cos) + Math.abs(image.height * sin);
            const newHeight =
                Math.abs(image.width * sin) + Math.abs(image.height * cos);

            canvas.width = newWidth;
            canvas.height = newHeight;

            context.translate(canvas.width / 2, canvas.height / 2);
            context.rotate(radians);

            context.drawImage(
                image,
                -image.width / 2,
                -image.height / 2,
                image.width,
                image.height
            );

            context.restore();
            // setNonFilteredFileURL(canvas.toDataURL());
        };
    };
    return (
        <>
            <MenuSectionTitle title={'Aspect Ratio'} />
            <MenuItemGroup
                style={{
                    marginBottom: '0.5rem',
                }}>
                <EnteMenuItem
                    disabled={cropLoading}
                    startIcon={<CropSquareIcon />}
                    onClick={() => {
                        cropCanvas(canvasRef.current, 1, 1);
                        cropCanvas(originalSizeCanvasRef.current, 1, 1);
                        setTransformationPerformed(true);
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
                            cropCanvas(
                                canvasRef.current,
                                ratio.width,
                                ratio.height
                            );
                            cropCanvas(
                                originalSizeCanvasRef.current,
                                ratio.width,
                                ratio.height
                            );
                            setTransformationPerformed(true);
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
                            cropCanvas(
                                canvasRef.current,
                                ratio.height,
                                ratio.width
                            );
                            cropCanvas(
                                originalSizeCanvasRef.current,
                                ratio.height,
                                ratio.width
                            );
                            setTransformationPerformed(true);
                        }}
                        label={`${ratio.height}:${ratio.width}`}
                    />
                ))}
            </MenuItemGroup>
            <MenuSectionTitle title={'Rotation'} />
            <MenuItemGroup
                style={{
                    marginBottom: '1rem',
                }}>
                <EnteMenuItem
                    disabled={cropLoading}
                    startIcon={<RotateLeftIcon />}
                    onClick={() => {
                        rotateCanvas(canvasRef.current, -90);
                        rotateCanvas(originalSizeCanvasRef.current, -90);
                        setTransformationPerformed(true);
                    }}
                    label="Rotate Left 90˚"
                />
                <EnteMenuItem
                    disabled={cropLoading}
                    startIcon={<RotateRightIcon />}
                    onClick={() => {
                        rotateCanvas(canvasRef.current, 90);
                        rotateCanvas(originalSizeCanvasRef.current, 90);
                        setTransformationPerformed(true);
                    }}
                    label="Rotate Right 90˚"
                />
            </MenuItemGroup>
            <MenuSectionTitle title={'Flip'} />
            <MenuItemGroup
                style={{
                    marginBottom: '1rem',
                }}>
                <EnteMenuItem
                    disabled={cropLoading}
                    startIcon={<FlipIcon />}
                    onClick={() => {
                        flipCanvas(canvasRef.current, 'vertical');
                        flipCanvas(originalSizeCanvasRef.current, 'vertical');
                        setTransformationPerformed(true);
                    }}
                    label="Flip Vertically"
                />
                <EnteMenuItem
                    disabled={cropLoading}
                    startIcon={<FlipIcon />}
                    onClick={() => {
                        flipCanvas(canvasRef.current, 'horizontal');
                        flipCanvas(originalSizeCanvasRef.current, 'horizontal');
                        setTransformationPerformed(true);
                    }}
                    label="Flip Horizontally"
                />
            </MenuItemGroup>
        </>
    );
};

export default TransformMenu;
