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
    } = useContext(ImageEditorOverlayContext);

    const cropRegionOfCanvas = (
        canvas: HTMLCanvasElement,
        topLeftX: number,
        topLeftY: number,
        bottomRightX: number,
        bottomRightY: number
    ) => {
        const context = canvas.getContext('2d');
        if (!context || !canvas) return;

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
                        cropRegionOfCanvas();
                    }}
                    label="Apply"
                />
            </MenuItemGroup>
        </>
    );
};

export default CropMenu;
