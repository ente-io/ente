import { CropBoxProps } from './';
import type { Ref, Dispatch, SetStateAction, CSSProperties } from 'react';
import { forwardRef } from 'react';

const handleStyle: CSSProperties = {
    position: 'absolute',
    height: '10px',
    width: '10px',
    backgroundColor: 'white',
    border: '1px solid black',
};

const seHandleStyle: CSSProperties = {
    ...handleStyle,
    right: '-5px',
    bottom: '-5px',
    cursor: 'se-resize',
};

interface IProps {
    cropBox: CropBoxProps;
    setIsDragging: Dispatch<SetStateAction<boolean>>;
}

const FreehandCropRegion = forwardRef(
    (props: IProps, ref: Ref<HTMLDivElement>) => {
        return (
            <>
                {/* Top overlay */}
                <div
                    style={{
                        position: 'absolute',
                        top: 0,
                        left: 0,
                        right: 0,
                        height: props.cropBox.y + 'px', // height up to the top of the crop box
                        backgroundColor: 'rgba(0,0,0,0.5)',
                        pointerEvents: 'none',
                    }}></div>

                {/* Bottom overlay */}
                <div
                    style={{
                        position: 'absolute',
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: `calc(100% - ${
                            props.cropBox.y + props.cropBox.height
                        }px)`, // height from the bottom of the crop box to the bottom of the canvas
                        backgroundColor: 'rgba(0,0,0,0.5)',
                        pointerEvents: 'none',
                    }}></div>

                {/* Left overlay */}
                <div
                    style={{
                        position: 'absolute',
                        top: props.cropBox.y + 'px',
                        left: 0,
                        width: props.cropBox.x + 'px', // width up to the left side of the crop box
                        height: props.cropBox.height + 'px', // same height as the crop box
                        backgroundColor: 'rgba(0,0,0,0.5)',
                        pointerEvents: 'none',
                    }}></div>

                {/* Right overlay */}
                <div
                    style={{
                        position: 'absolute',
                        top: props.cropBox.y + 'px',
                        right: 0,
                        width: `calc(100% - ${
                            props.cropBox.x + props.cropBox.width
                        }px)`, // width from the right side of the crop box to the right side of the canvas
                        height: props.cropBox.height + 'px', // same height as the crop box
                        backgroundColor: 'rgba(0,0,0,0.5)',
                        pointerEvents: 'none',
                    }}></div>

                <div
                    style={{
                        display: 'grid',
                        position: 'absolute',
                        left: props.cropBox.x + 'px',
                        top: props.cropBox.y + 'px',
                        width: props.cropBox.width + 'px',
                        height: props.cropBox.height + 'px',
                        border: '1px solid white',
                        gridTemplateColumns: '1fr 1fr 1fr',
                        gridTemplateRows: '1fr 1fr 1fr',
                        gap: '0px',
                        zIndex: 30, // make sure the crop box is above the overlays
                    }}
                    ref={ref}>
                    {Array.from({ length: 9 }).map((_, index) => (
                        <div
                            key={index}
                            style={{
                                border: '1px solid white',
                                boxSizing: 'border-box',
                                pointerEvents: 'none',
                            }}></div>
                    ))}

                    <div
                        style={seHandleStyle}
                        onMouseDown={(e) => {
                            e.preventDefault();
                            props.setIsDragging(true);
                        }}></div>
                </div>
            </>
        );
    }
);

export default FreehandCropRegion;
