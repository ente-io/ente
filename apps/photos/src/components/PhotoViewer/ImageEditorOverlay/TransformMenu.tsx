import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { Fragment, useContext } from 'react';
import { ImageEditorOverlayContext } from '.';
import CropSquareIcon from '@mui/icons-material/CropSquare';
import Crop169Icon from '@mui/icons-material/Crop169';
import Crop32Icon from '@mui/icons-material/Crop32';
import RotateLeftIcon from '@mui/icons-material/RotateLeft';
import RotateRightIcon from '@mui/icons-material/RotateRight';
import FlipIcon from '@mui/icons-material/Flip';
import MenuItemDivider from 'components/Menu/MenuItemDivider';

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
        canvasLoading,
        setCanvasLoading,
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

            // setNonFilteredFileURL(canvas.toDataURL());
        };
    };
    const flipCanvas = (
        canvas: HTMLCanvasElement,
        direction: 'vertical' | 'horizontal'
    ) => {
        const context = canvas.getContext('2d');
        if (!context || !canvas) return;
        context.resetTransform();
        context.imageSmoothingEnabled = false;
        const img = new Image();
        img.src = canvas.toDataURL();

        img.onload = () => {
            context.clearRect(0, 0, canvas.width, canvas.height);

            context.save();

            if (direction === 'horizontal') {
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
                    disabled={canvasLoading}
                    startIcon={<CropSquareIcon />}
                    onClick={() => {
                        setCanvasLoading(true);
                        cropCanvas(canvasRef.current, 1, 1);
                        cropCanvas(originalSizeCanvasRef.current, 1, 1);
                        setCanvasLoading(false);
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
                    <Fragment key={index}>
                        <EnteMenuItem
                            disabled={canvasLoading}
                            startIcon={ratio.icon}
                            onClick={() => {
                                setCanvasLoading(true);

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
                                setCanvasLoading(false);
                                setTransformationPerformed(true);
                            }}
                            label={`${ratio.width}:${ratio.height}`}
                        />
                        {index !== PRESET_ASPECT_RATIOS.length - 1 && (
                            <MenuItemDivider />
                        )}
                    </Fragment>
                ))}
            </MenuItemGroup>
            <MenuItemGroup
                style={{
                    marginBottom: '1rem',
                }}>
                {PRESET_ASPECT_RATIOS.map((ratio, index) => (
                    <Fragment key={index}>
                        <EnteMenuItem
                            disabled={canvasLoading}
                            key={index}
                            startIcon={ratio.icon}
                            onClick={() => {
                                setCanvasLoading(true);
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
                                setCanvasLoading(false);
                                setTransformationPerformed(true);
                            }}
                            label={`${ratio.height}:${ratio.width}`}
                        />
                        {index !== PRESET_ASPECT_RATIOS.length - 1 && (
                            <MenuItemDivider />
                        )}
                    </Fragment>
                ))}
            </MenuItemGroup>
            <MenuSectionTitle title={'Rotation'} />
            <MenuItemGroup
                style={{
                    marginBottom: '1rem',
                }}>
                <EnteMenuItem
                    disabled={canvasLoading}
                    startIcon={<RotateLeftIcon />}
                    onClick={() => {
                        setCanvasLoading(true);
                        rotateCanvas(canvasRef.current, -90);
                        rotateCanvas(originalSizeCanvasRef.current, -90);
                        setCanvasLoading(false);
                        setTransformationPerformed(true);
                    }}
                    label="Rotate Left 90˚"
                />
                <MenuItemDivider />
                <EnteMenuItem
                    disabled={canvasLoading}
                    startIcon={<RotateRightIcon />}
                    onClick={() => {
                        setCanvasLoading(true);
                        rotateCanvas(canvasRef.current, 90);
                        rotateCanvas(originalSizeCanvasRef.current, 90);
                        setTransformationPerformed(true);
                        setCanvasLoading(false);
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
                    disabled={canvasLoading}
                    startIcon={<FlipIcon />}
                    onClick={() => {
                        setCanvasLoading(true);
                        flipCanvas(canvasRef.current, 'vertical');
                        flipCanvas(originalSizeCanvasRef.current, 'vertical');
                        setCanvasLoading(false);
                        setTransformationPerformed(true);
                    }}
                    label="Flip Vertically"
                />
                <MenuItemDivider />
                <EnteMenuItem
                    disabled={canvasLoading}
                    startIcon={<FlipIcon />}
                    onClick={() => {
                        setCanvasLoading(true);
                        flipCanvas(canvasRef.current, 'horizontal');
                        flipCanvas(originalSizeCanvasRef.current, 'horizontal');
                        setCanvasLoading(false);
                        setTransformationPerformed(true);
                    }}
                    label="Flip Horizontally"
                />
            </MenuItemGroup>
        </>
    );
};

export default TransformMenu;
