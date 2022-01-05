import React, { useEffect, useRef, useState } from 'react';
import arcfaceAlignmentService from 'services/machineLearning/arcfaceAlignmentService';
import arcfaceCropService from 'services/machineLearning/arcfaceCropService';
import tfjsFaceDetectionService from 'services/machineLearning/tfjsFaceDetectionService';
import { AlignedFace, FaceCrop } from 'types/machineLearning';
import { getMLSyncConfig } from 'utils/machineLearning';
import {
    getAlignedFaceBox,
    ibExtractFaceImage,
    ibExtractFaceImageUsingTransform,
} from 'utils/machineLearning/faceAlign';
import { ibExtractFaceImageFromCrop } from 'utils/machineLearning/faceCrop';
import { FaceCropsRow, FaceImagesRow, ImageBitmapView } from './ImageViews';

interface MLFileDebugViewProps {
    file: File;
}

function drawFaceDetection(face: AlignedFace, ctx: CanvasRenderingContext2D) {
    const pointSize = Math.ceil(
        Math.max(ctx.canvas.width / 512, face.box.width / 32)
    );

    ctx.save();
    ctx.strokeStyle = 'rgba(255, 0, 0, 0.8)';
    ctx.lineWidth = pointSize;
    ctx.strokeRect(face.box.x, face.box.y, face.box.width, face.box.height);
    ctx.restore();

    ctx.save();
    ctx.strokeStyle = 'rgba(0, 255, 0, 0.8)';
    ctx.lineWidth = Math.round(pointSize * 1.5);
    const alignedBox = getAlignedFaceBox(face);
    ctx.strokeRect(
        alignedBox.x,
        alignedBox.y,
        alignedBox.width,
        alignedBox.height
    );
    ctx.restore();

    ctx.save();
    ctx.fillStyle = 'rgba(0, 0, 255, 0.8)';
    face.landmarks.forEach((l) => {
        ctx.beginPath();
        ctx.arc(l.x, l.y, pointSize, 0, Math.PI * 2, true);
        ctx.fill();
    });
    ctx.restore();
}

export default function MLFileDebugView(props: MLFileDebugViewProps) {
    // const [imageBitmap, setImageBitmap] = useState<ImageBitmap>();
    const [faceCrops, setFaceCrops] = useState<FaceCrop[]>();
    const [facesUsingCrops, setFacesUsingCrops] = useState<ImageBitmap[]>();
    const [facesUsingImage, setFacesUsingImage] = useState<ImageBitmap[]>();
    const [facesUsingTransform, setFacesUsingTransform] =
        useState<ImageBitmap[]>();

    const canvasRef = useRef(null);

    useEffect(() => {
        let didCancel = false;
        const loadFile = async () => {
            // TODO: go through worker for these apis, to not include ml code in main bundle
            const imageBitmap = await createImageBitmap(props.file);
            const detectedFaces = await tfjsFaceDetectionService.detectFaces(
                imageBitmap
            );
            console.log('detectedFaces: ', detectedFaces.length);

            const mlSyncConfig = await getMLSyncConfig();
            const faceCropPromises = detectedFaces.map(async (face) =>
                arcfaceCropService.getFaceCrop(
                    imageBitmap,
                    face,
                    mlSyncConfig.faceCrop
                )
            );

            const faceCrops = await Promise.all(faceCropPromises);
            if (didCancel) return;
            setFaceCrops(faceCrops);

            const alignedFaces =
                arcfaceAlignmentService.getAlignedFaces(detectedFaces);
            console.log('alignedFaces: ', alignedFaces);

            const canvas: HTMLCanvasElement = canvasRef.current;
            canvas.width = imageBitmap.width;
            canvas.height = imageBitmap.height;
            const ctx = canvas.getContext('2d');
            if (didCancel) return;
            ctx.drawImage(imageBitmap, 0, 0);
            alignedFaces.forEach((face) => drawFaceDetection(face, ctx));

            const facesUsingCrops = await Promise.all(
                alignedFaces.map((face, i) => {
                    return ibExtractFaceImageFromCrop(face, 112, faceCrops[i]);
                })
            );
            const facesUsingImage = await Promise.all(
                alignedFaces.map((face) => {
                    return ibExtractFaceImage(imageBitmap, face, 112);
                })
            );
            const facesUsingTransform = await Promise.all(
                alignedFaces.map((face) => {
                    return ibExtractFaceImageUsingTransform(
                        imageBitmap,
                        face,
                        112
                    );
                })
            );

            if (didCancel) return;
            setFacesUsingCrops(facesUsingCrops);
            setFacesUsingImage(facesUsingImage);
            setFacesUsingTransform(facesUsingTransform);
        };

        props.file && loadFile();
        return () => {
            didCancel = true;
        };
    }, [props.file]);

    return (
        <div>
            <p></p>
            {/* <ImageBitmapView image={imageBitmap}></ImageBitmapView> */}
            <canvas
                ref={canvasRef}
                style={{ display: 'inline', width: '100%' }}
            />
            <p></p>
            <div>Face Crops:</div>
            <FaceCropsRow>
                {faceCrops?.map((faceCrop, i) => (
                    <ImageBitmapView
                        key={i}
                        image={faceCrop.image}></ImageBitmapView>
                ))}
            </FaceCropsRow>

            <p></p>

            <div>Face Images using face crops:</div>
            <FaceImagesRow>
                {facesUsingCrops?.map((image, i) => (
                    <ImageBitmapView key={i} image={image}></ImageBitmapView>
                ))}
            </FaceImagesRow>

            <div>Face Images using original image:</div>
            <FaceImagesRow>
                {facesUsingImage?.map((image, i) => (
                    <ImageBitmapView key={i} image={image}></ImageBitmapView>
                ))}
            </FaceImagesRow>

            <div>Face Images using transfrom:</div>
            <FaceImagesRow>
                {facesUsingTransform?.map((image, i) => (
                    <ImageBitmapView key={i} image={image}></ImageBitmapView>
                ))}
            </FaceImagesRow>
        </div>
    );
}
