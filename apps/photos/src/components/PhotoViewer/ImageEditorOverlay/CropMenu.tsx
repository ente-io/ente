import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { useContext } from 'react';
import { ImageEditorOverlayContext } from './';
import CropSquareIcon from '@mui/icons-material/CropSquare';
import { CropBoxProps } from './';
import type { MutableRefObject } from 'react';

interface IProps {
    previewScale: number;
    cropBoxProps: CropBoxProps;
    cropBoxRef: MutableRefObject<HTMLDivElement>;
}

const CropMenu = (props: IProps) => {
    const {
        canvasRef,
        originalSizeCanvasRef,
        canvasLoading,
        setCanvasLoading,
        setTransformationPerformed,
        setCurrentTab,
    } = useContext(ImageEditorOverlayContext);

    const cropRegionOfCanvas = (
        canvas: HTMLCanvasElement,
        topLeftX: number,
        topLeftY: number,
        bottomRightX: number,
        bottomRightY: number,
        scale: number = 1
    ) => {
        setTransformationPerformed(true);
        const context = canvas.getContext('2d');
        if (!context || !canvas) return;
        context.imageSmoothingEnabled = false;

        const width = (bottomRightX - topLeftX) * scale;
        const height = (bottomRightY - topLeftY) * scale;

        const img = new Image();
        img.src = canvas.toDataURL();
        img.onload = () => {
            context.clearRect(0, 0, canvas.width, canvas.height);

            canvas.width = width;
            canvas.height = height;

            context.drawImage(
                img,
                topLeftX,
                topLeftY,
                width,
                height,
                0,
                0,
                width,
                height
            );
        };
    };

    return (
        <>
            <MenuSectionTitle title={'freehand'} />
            <MenuItemGroup
                style={{
                    marginBottom: '0.5rem',
                }}>
                <EnteMenuItem
                    disabled={canvasLoading}
                    startIcon={<CropSquareIcon />}
                    onClick={() => {
                        if (!props.cropBoxRef.current || !canvasRef.current)
                            return;

                        // get the bounding rectangle of the crop box
                        const cropBoxRect =
                            props.cropBoxRef.current.getBoundingClientRect();
                        // Get the bounding rectangle of the canvas
                        const canvasRect =
                            canvasRef.current.getBoundingClientRect();

                        // calculate the scale of the canvas display relative to its actual dimensions
                        const displayScale =
                            canvasRef.current.width / canvasRect.width;

                        // calculate the coordinates of the crop box relative to the canvas and adjust for any scrolling by adding scroll offsets
                        const x1 =
                            (cropBoxRect.left -
                                canvasRect.left +
                                window.scrollX) *
                            displayScale;
                        const y1 =
                            (cropBoxRect.top -
                                canvasRect.top +
                                window.scrollY) *
                            displayScale;
                        const x2 = x1 + cropBoxRect.width * displayScale;
                        const y2 = y1 + cropBoxRect.height * displayScale;

                        setCanvasLoading(true);
                        cropRegionOfCanvas(canvasRef.current, x1, y1, x2, y2);
                        cropRegionOfCanvas(
                            originalSizeCanvasRef.current,
                            x1 / props.previewScale,
                            y1 / props.previewScale,
                            x2 / props.previewScale,
                            y2 / props.previewScale
                        );
                        setCanvasLoading(false);

                        setCurrentTab('transform');
                    }}
                    label="Apply"
                />
            </MenuItemGroup>
        </>
    );
};

export default CropMenu;
