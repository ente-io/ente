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
import { t } from 'i18next';
import { logError } from 'utils/sentry';

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
        };
    };

    const createCropHandler =
        (widthRatio: number, heightRatio: number) => () => {
            try {
                setCanvasLoading(true);
                cropCanvas(canvasRef.current, widthRatio, heightRatio);
                cropCanvas(
                    originalSizeCanvasRef.current,
                    widthRatio,
                    heightRatio
                );
                setCanvasLoading(false);
                setTransformationPerformed(true);
            } catch (e) {
                logError(e, 'crop handler failed', {
                    widthRatio,
                    heightRatio,
                });
            }
        };
    const createRotationHandler = (rotation: 'left' | 'right') => () => {
        try {
            setCanvasLoading(true);
            rotateCanvas(canvasRef.current, rotation === 'left' ? -90 : 90);
            rotateCanvas(
                originalSizeCanvasRef.current,
                rotation === 'left' ? -90 : 90
            );
            setCanvasLoading(false);
            setTransformationPerformed(true);
        } catch (e) {
            logError(e, 'rotation handler failed', {
                rotation,
            });
        }
    };

    const createFlipCanvasHandler =
        (direction: 'vertical' | 'horizontal') => () => {
            try {
                setCanvasLoading(true);
                flipCanvas(canvasRef.current, direction);
                flipCanvas(originalSizeCanvasRef.current, direction);
                setCanvasLoading(false);
                setTransformationPerformed(true);
            } catch (e) {
                logError(e, 'flip handler failed', {
                    direction,
                });
            }
        };

    return (
        <>
            <MenuSectionTitle title={t('ASPECT_RATIO')} />
            <MenuItemGroup
                style={{
                    marginBottom: '0.5rem',
                }}>
                <EnteMenuItem
                    disabled={canvasLoading}
                    startIcon={<CropSquareIcon />}
                    onClick={createCropHandler(1, 1)}
                    label={t('SQUARE') + ' (1:1)'}
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
                            onClick={createCropHandler(
                                ratio.width,
                                ratio.height
                            )}
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
                            onClick={createCropHandler(
                                ratio.height,
                                ratio.width
                            )}
                            label={`${ratio.height}:${ratio.width}`}
                        />
                        {index !== PRESET_ASPECT_RATIOS.length - 1 && (
                            <MenuItemDivider />
                        )}
                    </Fragment>
                ))}
            </MenuItemGroup>
            <MenuSectionTitle title={t('ROTATION')} />
            <MenuItemGroup
                style={{
                    marginBottom: '1rem',
                }}>
                <EnteMenuItem
                    disabled={canvasLoading}
                    startIcon={<RotateLeftIcon />}
                    onClick={createRotationHandler('left')}
                    label={t('ROTATE_LEFT') + ' 90˚'}
                />
                <MenuItemDivider />
                <EnteMenuItem
                    disabled={canvasLoading}
                    startIcon={<RotateRightIcon />}
                    onClick={createRotationHandler('right')}
                    label={t('ROTATE_RIGHT') + ' 90˚'}
                />
            </MenuItemGroup>
            <MenuSectionTitle title={t('FLIP')} />
            <MenuItemGroup
                style={{
                    marginBottom: '1rem',
                }}>
                <EnteMenuItem
                    disabled={canvasLoading}
                    startIcon={<FlipIcon />}
                    onClick={createFlipCanvasHandler('vertical')}
                    label={t('FLIP_VERTICALLY')}
                />
                <MenuItemDivider />
                <EnteMenuItem
                    disabled={canvasLoading}
                    startIcon={<FlipIcon />}
                    onClick={createFlipCanvasHandler('horizontal')}
                    label={t('FLIP_HORIZONTALLY')}
                />
            </MenuItemGroup>
        </>
    );
};

export default TransformMenu;
