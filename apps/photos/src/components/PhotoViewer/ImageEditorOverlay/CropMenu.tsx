import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { useState, useContext, useEffect } from 'react';
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
    } = useContext(ImageEditorOverlayContext);

    const [selectedRegionOfPreviewCanvas, setSelectedRegionOfPreviewCanvas] =
        useState({
            topLeftX: 0,
            topLeftY: 0,
            bottomLeftX: 0,
            bottomRightY: 0,
        });

    const cropRegionOfCanvas = (
        canvas: HTMLCanvasElement,
        topLeftX: number,
        topLeftY: number,
        bottomRightX: number,
        bottomRightY: number
    ) => {
        setTransformationPerformed(true);
        const context = canvas.getContext('2d');
        if (!context || !canvas) return;
        context.imageSmoothingEnabled = false;

        const width = bottomRightX - topLeftX;
        const height = bottomRightY - topLeftY;

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

                        // Get the bounding rectangle of the crop box
                        const cropBoxRect =
                            props.cropBoxRef.current.getBoundingClientRect();
                        // Get the bounding rectangle of the canvas
                        const canvasRect =
                            canvasRef.current.getBoundingClientRect();

                        // Calculate the coordinates of the crop box relative to the canvas
                        const x1 = cropBoxRect.left - canvasRect.left;
                        const y1 = cropBoxRect.top - canvasRect.top;
                        const x2 = x1 + cropBoxRect.width;
                        const y2 = y1 + cropBoxRect.height;

                        cropRegionOfCanvas(canvasRef.current, x1, y1, x2, y2);
                    }}
                    label="Apply"
                />
            </MenuItemGroup>
        </>
    );
};

export default CropMenu;
